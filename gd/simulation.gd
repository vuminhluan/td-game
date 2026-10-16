extends RefCounted
const R = preload("res://gd/rules.gd")
const Map = preload("res://gd/battle_map.gd")
const PickupConfig = preload("res://gd/pickup_settings.gd")
const MapDefinition = preload("res://gd/map_definition.gd")

var players: Array = []
var friendly_fire := false
var loadout: Resource:
	get:
		return players[0].loadout
	set(value):
		players[0].loadout = value
var sequence = 1
const DEFAULT_MAP = preload("res://scenes/maps/industrial_yard.tscn")
var catalog = preload("res://gd/character_catalog.gd").new()
var map: Array = []
var map_scene: Node2D
var dimensions := Vector2i.ZERO
var world_size := Vector2.ZERO
var base_position := Vector2.ZERO
var base_goal := Vector2i.ZERO
var player_spawn := Vector2.ZERO
var enemy_spawns: Array = []
var map_objects: Array = []
var validation_errors: Array = []
var pickup_settings: Resource
var weapon_pickups: Array = []
var player: Dictionary:
	get:
		return players[0].actor
	set(value):
		players[0].actor = value
var enemies: Array = []
var bullets: Array = []
var effects: Array = []
var power_ups: Array = []
var active_power_ups: Dictionary:
	get:
		return players[0].active_power_ups
	set(value):
		players[0].active_power_ups = value
var power_up_timer = 5.0
var pending_shots: Array:
	get:
		return players[0].pending_shots
	set(value):
		players[0].pending_shots = value
var rng = RandomNumberGenerator.new()
var status = "ready"
var base_hp = R.BASE_HP
var lives: int:
	get:
		return players[0].lives
	set(value):
		players[0].lives = value
var wave = 0
var score = 0
var kills = 0
var elapsed = 0.0
var to_spawn = 0
var spawn_timer = 0.0
var wave_timer = 0.0
var invulnerable: float:
	get:
		return players[0].invulnerable
	set(value):
		players[0].invulnerable = value
var revision = 0
var shots_fired = 0
var player_muzzle_distances: Dictionary:
	get:
		return players[0].muzzle_distances
	set(value):
		players[0].muzzle_distances = value
var enemy_muzzle_distances: Dictionary = {}
var message = "Phòng tuyến cuối cùng"

func _init(configuration: Resource = null, scene: PackedScene = null, configurations: Array = []) -> void:
	if configuration == null:
		var character: String = catalog.data.default_character
		var c: Dictionary = catalog.data.characters[character]
		configuration = catalog.create(character, c.default_body, c.default_weapon)
	var selected: Array = configurations if not configurations.is_empty() else [configuration]
	for index in selected.size():
		players.append({"id": index + 1, "actor": {}, "loadout": selected[index], "lives": R.LIVES,
			"invulnerable": 0.0, "active_power_ups": {}, "pending_shots": [],
			"muzzle_distances": {}, "spawn_position": Vector2.ZERO, "label_remaining": 10.0})
	rng.randomize()
	var instance: Node = (DEFAULT_MAP if scene == null else scene).instantiate()
	if not instance is MapDefinition:
		validation_errors.append("Scene map phải có root Node2D dùng gd/map_definition.gd")
		instance.free()
		pickup_settings = PickupConfig.new()
		for index in players.size():
			players[index].actor = make_actor("player", Vector2.ZERO, index)
			refresh_player_muzzles(index)
		invalidate_map()
		return
	map_scene = instance
	var runtime: Dictionary = map_scene.build_runtime(catalog)
	validation_errors = runtime.errors
	map = runtime.grid
	dimensions = runtime.dimensions
	world_size = Vector2(dimensions) * R.TILE
	base_position = runtime.base_position
	base_goal = runtime.base_goal
	player_spawn = runtime.player_position
	enemy_spawns = runtime.enemy_spawns
	map_objects = runtime.objects
	pickup_settings = runtime.settings
	if not pickup_settings is PickupConfig:
		validation_errors.append("Map yêu cầu PickupSettings hợp lệ")
		pickup_settings = PickupConfig.new()
	power_up_timer = pickup_settings.periodic_interval
	for index in players.size():
		var state: Dictionary = players[index]
		var requested: Vector2 = player_spawn if index == 0 else runtime.get("player_two_position", Vector2.INF)
		var point: Vector2 = requested if requested.is_finite() else find_player_spawn(player_spawn, index)
		state.spawn_position = point
		state.actor = make_actor("player", point, index)
		refresh_player_muzzles(index)
		if not point.is_finite() or not can_place_player(point, index):
			validation_errors.append("P%d spawn: không đủ khoảng trống cho character đã chọn" % (index + 1))
	if validation_errors.is_empty():
		for object in map_objects:
			if object.category == "pickup":
				if place_pickup(object.pos, object.pickup_category, object.pickup_id):
					object.active = false
				else:
					validation_errors.append("%s: không thể đặt pickup tại %s" % [object.node.name, object.pos])
	if not validation_errors.is_empty():
		invalidate_map()

func invalidate_map() -> void:
	status = "invalid"
	message = "Map không hợp lệ:\n" + "\n".join(validation_errors)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(map_scene) and not map_scene.is_inside_tree():
		map_scene.free()

func refresh_player_muzzles(player_index: int = 0) -> void:
	var state: Dictionary = players[player_index]
	state.muzzle_distances.clear()
	for direction in R.VECTOR:
		state.muzzle_distances[direction] = state.loadout.muzzle_vectors(direction)[0].dot(R.VECTOR[direction])

func compatible_weapons(player_index: int = 0) -> Array:
	return catalog.data.characters[players[player_index].loadout.character_id].weapons

func equip_weapon(id: String, player_index: int = 0) -> bool:
	if id not in compatible_weapons(player_index):
		return false
	var state: Dictionary = players[player_index]
	var equipped: Resource = state.loadout
	var body_id: String = equipped.body_id if "body_id" in equipped else catalog.data.characters[equipped.character_id].default_body
	var replacement: Resource = catalog.create(equipped.character_id, body_id, id)
	if replacement == null:
		return false
	state.loadout = replacement
	state.pending_shots.clear()
	state.actor.shot_duration = replacement.weapon.shot_duration
	state.actor.shot_clock = 0.0
	state.actor.cooldown = 0.0
	refresh_player_muzzles(player_index)
	return true

func make_actor(kind: String, point: Vector2, player_index: int = 0) -> Dictionary:
	var equipped: Resource = players[player_index].loadout
	var hp = equipped.max_hp if kind == "player" else (4 if kind == "tank" else 2)
	var actor = {"id": sequence, "pos": point, "kind": kind, "hp": hp, "max_hp": hp,
		"dir": "up" if kind == "player" else "down", "cooldown": 0.7,
		"moving": false, "move_clock": 0.0, "shot_clock": 0.0, "hurt_clock": 0.0,
		"shot_duration": equipped.weapon.shot_duration if kind == "player" else 4.0 / 12.0}
	if kind == "player":
		actor.player_id = players[player_index].id
	sequence += 1
	return actor

func player_index_for(actor: Dictionary) -> int:
	return int(actor.get("player_id", 1)) - 1

func living_players() -> Array:
	return players.filter(func(state): return not state.actor.is_empty() and state.actor.hp > 0 and state.lives > 0)

func can_place_player(point: Vector2, player_index: int) -> bool:
	if not point.is_finite() or not Map.can_occupy(map, point, players[player_index].loadout.collider_radius) or in_base(point, 25):
		return false
	for other in living_players():
		if other.id == players[player_index].id:
			continue
		var clearance: float = other.loadout.collider_radius + players[player_index].loadout.collider_radius
		if absf(point.x - other.actor.pos.x) < clearance and absf(point.y - other.actor.pos.y) < clearance:
			return false
	return true

func find_player_spawn(origin: Vector2, player_index: int) -> Vector2:
	if can_place_player(origin, player_index):
		return origin
	var start := Vector2i(origin / R.TILE)
	var frontier: Array = [start]
	var seen: Dictionary = {start: true}
	var cursor := 0
	while cursor < frontier.size():
		var cell: Vector2i = frontier[cursor]
		cursor += 1
		var point := (Vector2(cell) + Vector2(0.5, 0.5)) * R.TILE
		if can_place_player(point, player_index):
			return point
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			var next_point := (Vector2(next) + Vector2(0.5, 0.5)) * R.TILE
			if not seen.has(next) and Map.can_occupy(map, next_point, players[player_index].loadout.collider_radius) and not in_base(next_point, 25):
				seen[next] = true
				frontier.append(next)
	return Vector2.INF

func start() -> void:
	if status == "ready":
		status = "playing"
		next_wave()

func pause() -> void:
	if status == "playing":
		status = "paused"
	elif status == "paused":
		status = "playing"

func next_wave() -> void:
	wave += 1
	to_spawn = R.WAVE_COUNTS[wave - 1]
	spawn_timer = 0.8
	message = "Đợt %d — Bảo vệ căn cứ" % wave

func fire(actor: Dictionary) -> void:
	if actor.cooldown > 0 or actor.hp <= 0:
		return
	if actor.kind != "player":
		actor.cooldown = 1.3 if actor.kind == "tank" else 1.7
		emit_bullet(actor)
		return
	var index := player_index_for(actor)
	var state: Dictionary = players[index]
	if not state.pending_shots.is_empty() or state.actor.id != actor.id or state.lives <= 0:
		return
	var schedule: Array = state.loadout.weapon.schedule(power_up_active("double_shot", index))
	actor.cooldown = schedule.back().time + player_shot_cooldown(index)
	for shot in schedule:
		if shot.time == 0:
			emit_player_volley(actor, shot.barrels)
		else:
			state.pending_shots.append({"actor": actor.duplicate(), "delay": shot.time, "barrels": shot.barrels})
	if not state.pending_shots.is_empty():
		actor.moving = false

func emit_player_volley(actor: Dictionary, barrels: Array) -> void:
	var state: Dictionary = players[player_index_for(actor)]
	var vector: Vector2 = R.VECTOR[actor.dir]
	var muzzles: Array = state.loadout.muzzle_vectors(actor.dir)
	for barrel in barrels:
		var muzzle: Vector2 = muzzles[barrel]
		var baseline: float = muzzles[0].dot(vector)
		var distance: float = state.muzzle_distances.get(actor.dir, baseline)
		muzzle += vector * (distance - baseline)
		emit_projectile(actor, muzzle, state.loadout.weapon.damage, state.loadout.weapon.bullet_speed)
	state.actor.shot_clock = state.actor.shot_duration

func emit_bullet(actor: Dictionary) -> void:
	if actor.kind == "player":
		var equipped: Resource = players[player_index_for(actor)].loadout
		emit_player_volley(actor, range(equipped.weapon.barrel_offsets.size()))
	else:
		var distance: float = enemy_muzzle_distances.get(actor.kind, {}).get(actor.dir, 20.0)
		emit_projectile(actor, R.VECTOR[actor.dir] * distance)

func emit_projectile(actor: Dictionary, muzzle: Vector2, damage: int = 1, speed: float = R.BULLET_SPEED) -> void:
	var vector: Vector2 = R.VECTOR[actor.dir]
	var baseline: float = 0.0 if actor.kind == "player" else 20.0
	var muzzle_distance = muzzle.dot(vector)
	var lateral = muzzle - vector * muzzle_distance
	actor.shot_clock = actor.shot_duration
	var bullet = {"id": sequence, "pos": actor.pos + muzzle, "dir": actor.dir, "friendly": actor.kind == "player", "owner_id": actor.get("player_id", 0), "damage": damage, "speed": speed}
	var blocked = false
	if muzzle_distance > baseline:
		var distance = baseline
		while distance < muzzle_distance:
			bullet.pos = actor.pos + lateral + vector * distance
			if bullet_collision(bullet):
				blocked = true
				break
			distance = minf(muzzle_distance, distance + 2.0)
	if not blocked:
		bullet.pos = actor.pos + muzzle
		blocked = bullet_collision(bullet)
	if not blocked:
		bullets.append(bullet)
	sequence += 1
	shots_fired += 1
	effect(actor.pos + muzzle, "spark")

func effect(point: Vector2, kind: String) -> void:
	var life = 0.13 if kind == "spark" else 0.48
	effects.append({"pos": point, "kind": kind, "life": life, "max": life})

func damage_brick(point: Vector2) -> void:
	damage_wall(point)

func damage_wall(point: Vector2, can_damage_steel: bool = false) -> void:
	var tile = Map.tile_at(map, point)
	if tile.is_empty() or not Map.destructible(tile):
		return
	var target: Dictionary = Map.damage_target(tile)
	if target.get("steel", false) and not can_damage_steel:
		return
	target.hp -= 1
	revision += 1
	if target.hp <= 0:
		if target == tile:
			tile.kind = "floor"
			tile.move_blocked = false
			tile.bullet_blocked = false
			tile.destructible = false
		else:
			target.active = false
		for enemy in enemies:
			enemy.erase("target")
		drop_pickup(tile_center(point), target.get("drop_settings"), target.get("pickup_category", ""), target.get("pickup_id", ""))
	effect(point, "explosion" if target.hp <= 0 else "spark")

func hit_player(player_index: int = 0, damage: int = 1) -> void:
	var state: Dictionary = players[player_index]
	if state.actor.hp <= 0 or state.lives <= 0 or state.invulnerable > 0 or power_up_active("shield", player_index):
		return
	state.actor.hp -= damage
	state.actor.hurt_clock = 0.16
	state.invulnerable = 0.85
	if state.actor.hp <= 0:
		state.lives -= 1
		state.pending_shots.clear()
		state.actor.moving = false
		effect(state.actor.pos, "explosion")
		if players.all(func(candidate): return candidate.lives <= 0):
			status = "lost"
			message = "Robot đã bị vô hiệu hóa"
			return
		if state.lives > 0:
			respawn_player(player_index)

func respawn_player(player_index: int) -> void:
	var state: Dictionary = players[player_index]
	var point := find_player_spawn(state.spawn_position, player_index)
	if not point.is_finite():
		return
	state.actor = make_actor("player", point, player_index)
	state.invulnerable = 3.0
	state.label_remaining = 3.0

func in_base(point: Vector2, radius: float) -> bool:
	return absf(point.x - base_position.x) < radius and absf(point.y - base_position.y) < radius

func update(delta: float, direction: String = "", shooting: bool = false) -> void:
	update_players(delta, [{"direction": direction, "shooting": shooting}])

func update_players(delta: float, commands: Array) -> void:
	if status != "playing":
		return
	var dt = minf(delta, 0.05)
	elapsed += dt
	update_power_ups(dt)
	for index in players.size():
		update_player(index, dt, commands[index] if index < commands.size() else {})
	for fx in effects:
		fx.life -= dt
	effects = effects.filter(func(fx): return fx.life > 0)
	if to_spawn > 0:
		spawn_timer -= dt
		if spawn_timer <= 0:
			var spawn_index: int = (R.WAVE_COUNTS[wave - 1] - to_spawn) % enemy_spawns.size()
			var point: Vector2 = enemy_spawns[spawn_index]
			if not enemies.any(func(e): return e.pos.distance_to(point) < 35):
				enemies.append(make_actor("tank" if wave > 1 and to_spawn % 3 == 0 else "robot", point))
				to_spawn -= 1
			spawn_timer = R.SPAWN_DELAY
	for enemy in enemies:
		enemy.cooldown = maxf(0, enemy.cooldown - dt)
		enemy.shot_clock = maxf(0, enemy.shot_clock - dt)
		enemy.hurt_clock = maxf(0, enemy.hurt_clock - dt)
		var previous_position: Vector2 = enemy.pos
		move_enemy(enemy, dt)
		enemy.moving = not enemy.pos.is_equal_approx(previous_position)
		enemy.move_clock = enemy.move_clock + dt if enemy.moving else 0.0
	collect_power_ups()
	for bullet in bullets.duplicate():
		var dead = false
		var vector: Vector2 = R.VECTOR[bullet.dir]
		var steps = maxi(1, ceili(bullet.get("speed", R.BULLET_SPEED) * dt / 5))
		for substep in steps:
			bullet.pos += vector * bullet.get("speed", R.BULLET_SPEED) * dt / steps
			dead = bullet_collision(bullet)
			if dead:
				break
		if dead:
			bullets.erase(bullet)
		if status != "playing":
			break
	if status != "playing":
		return
	if to_spawn == 0 and enemies.is_empty():
		if wave == R.WAVE_COUNTS.size():
			status = "won"
			message = "Phòng tuyến được giữ vững"
		else:
			wave_timer += dt
			message = "Đợt tiếp theo sau %d giây" % ceili(R.WAVE_DELAY - wave_timer)
			if wave_timer >= R.WAVE_DELAY:
				wave_timer = 0
				next_wave()


func update_player(player_index: int, dt: float, command: Dictionary) -> void:
	var state: Dictionary = players[player_index]
	state.label_remaining = maxf(0.0, state.label_remaining - dt)
	state.invulnerable = maxf(0.0, state.invulnerable - dt)
	if state.actor.hp <= 0:
		if state.lives > 0:
			respawn_player(player_index)
		return
	var actor: Dictionary = state.actor
	var lock_remaining := 0.0
	for shot in state.pending_shots:
		lock_remaining = maxf(lock_remaining, shot.delay)
	for shot in state.pending_shots.duplicate():
		shot.delay -= dt
		if shot.delay <= 0:
			if shot.actor.id == actor.id:
				emit_player_volley(shot.actor, shot.barrels)
			state.pending_shots.erase(shot)
	actor.cooldown = maxf(0.0, actor.cooldown - dt)
	actor.shot_clock = maxf(0.0, actor.shot_clock - dt)
	actor.hurt_clock = maxf(0.0, actor.hurt_clock - dt)
	actor.moving = false
	var direction: String = command.get("direction", "")
	var move_dt := maxf(0.0, dt - lock_remaining)
	if R.VECTOR.has(direction) and state.pending_shots.is_empty() and move_dt > 0:
		actor.dir = direction
		var point: Vector2 = actor.pos + R.VECTOR[direction] * state.loadout.move_speed * (R.SPEED_BOOST_MULTIPLIER if power_up_active("speed_boost", player_index) else 1.0) * move_dt
		if can_place_player(point, player_index):
			actor.pos = point
			actor.moving = true
	actor.move_clock = actor.move_clock + dt if actor.moving else 0.0
	if command.get("shooting", false):
		fire(actor)


func bullet_collision(bullet: Dictionary) -> bool:
	var point: Vector2 = bullet.pos
	if point.x < 0 or point.y < 0 or point.x >= world_size.x or point.y >= world_size.y:
		return true
	var tile = Map.tile_at(map, point)
	if Map.bullet_blocked(tile):
		for hit in bullet.get("damage", 1):
			damage_wall(point)
		effect(point, "spark")
		return true
	if bullet.friendly:
		for enemy in enemies:
			if absf(enemy.pos.x - point.x) < 16 and absf(enemy.pos.y - point.y) < 16:
				enemy.hp -= bullet.get("damage", 1)
				enemy.hurt_clock = 0.16
				effect(enemy.pos, "explosion" if enemy.hp <= 0 else "spark")
				if enemy.hp <= 0:
					enemies.erase(enemy)
					kills += 1
					score += 250 if enemy.kind == "tank" else 100
				return true
	elif in_base(point, 28):
		if not power_up_active("base_shield"):
			base_hp -= 1
		effect(point, "spark")
		if base_hp <= 0:
			status = "lost"
			message = "Căn cứ đã bị phá hủy"
			effect(base_position, "explosion")
		return true
	if not bullet.friendly or friendly_fire:
		for state in living_players():
			if bullet.friendly and bullet.get("owner_id", 1) == state.id:
				continue
			if absf(point.x - state.actor.pos.x) < state.loadout.collider_radius and absf(point.y - state.actor.pos.y) < state.loadout.collider_radius:
				hit_player(state.id - 1, bullet.get("damage", 1))
				return true
	return false

func move_enemy(enemy: Dictionary, dt: float) -> void:
	if enemy.shot_clock > 0:
		return
	var base_diff: Vector2 = base_position - enemy.pos
	if (absf(base_diff.x) < 28 or absf(base_diff.y) < 28) and base_diff.length() < 100:
		enemy.dir = ("down" if base_diff.y > 0 else "up") if absf(base_diff.x) < 28 else ("right" if base_diff.x > 0 else "left")
		fire(enemy)
		return
	var target_diff := Vector2.INF
	for state in living_players():
		var diff: Vector2 = state.actor.pos - enemy.pos
		if (absf(diff.x) < 14 or absf(diff.y) < 14) and diff.length() < 240 and diff.length_squared() < target_diff.length_squared():
			target_diff = diff
	if enemy.cooldown <= 0 and target_diff.is_finite():
		enemy.dir = ("down" if target_diff.y > 0 else "up") if absf(target_diff.x) < 14 else ("right" if target_diff.x > 0 else "left")
		fire(enemy)
		return
	if not enemy.has("target"):
		var start = Vector2i(floori(enemy.pos.x / R.TILE), floori(enemy.pos.y / R.TILE))
		var center = (Vector2(start) + Vector2(0.5, 0.5)) * R.TILE
		if enemy.pos.distance_to(center) > 1:
			enemy.target = center
		else:
			var path = Map.find_path(map, start, base_goal)
			if not path.is_empty():
				enemy.target = (Vector2(path[0]) + Vector2(0.5, 0.5)) * R.TILE
	if not enemy.has("target"):
		return
	var diff_target: Vector2 = enemy.target - enemy.pos
	enemy.dir = ("right" if diff_target.x > 0 else "left") if absf(diff_target.x) > 0.5 else ("down" if diff_target.y > 0 else "up")
	if Map.move_blocked(Map.tile_at(map, enemy.target)) and Map.destructible(Map.tile_at(map, enemy.target)):
		fire(enemy)
		return
	var step = (40 if enemy.kind == "tank" else 54 + wave * 3) * dt
	if diff_target.length() <= step:
		enemy.pos = enemy.target
		enemy.erase("target")
	else:
		enemy.pos += R.VECTOR[enemy.dir] * step

func power_up_active(kind: String, player_index: int = 0) -> bool:
	if kind == "base_shield":
		return players.any(func(state): return state.active_power_ups.get(kind, 0.0) > 0)
	return players[player_index].active_power_ups.get(kind, 0.0) > 0

func activate_power_up(kind: String, player_index: int = 0) -> void:
	if kind in PickupConfig.POWER_UP_IDS:
		players[player_index].active_power_ups[kind] = R.POWER_UP_DURATION

func player_shot_cooldown(player_index: int = 0) -> float:
	var weapon: Resource = players[player_index].loadout.weapon
	return weapon.cooldown * (weapon.rapid_rest_multiplier if power_up_active("rapid_fire", player_index) else 1.0)

func tile_center(point: Vector2) -> Vector2:
	return (Vector2(Vector2i(point / R.TILE)) + Vector2(0.5, 0.5)) * R.TILE

func reachable_power_up_cells() -> Array:
	var frontier: Array = []
	var seen: Dictionary = {}
	for state in living_players():
		var start := Vector2i(state.actor.pos / R.TILE)
		if not seen.has(start):
			frontier.append(start)
			seen[start] = true
	var cells: Array = []
	var index = 0
	while index < frontier.size():
		var cell: Vector2i = frontier[index]
		index += 1
		cells.append((Vector2(cell) + Vector2(0.5, 0.5)) * R.TILE)
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cell + direction
			var point = (Vector2(next) + Vector2(0.5, 0.5)) * R.TILE
			if not seen.has(next) and Map.can_occupy(map, point) and not in_base(point, 33):
				seen[next] = true
				frontier.append(next)
	return cells

func valid_power_up_cell(point: Vector2) -> bool:
	if not Map.can_occupy(map, point) or in_base(point, 33):
		return false
	for actor in living_players().map(func(state): return state.actor) + enemies:
		if absf(actor.pos.x - point.x) < R.TILE / 2.0 + 16 and absf(actor.pos.y - point.y) < R.TILE / 2.0 + 16:
			return false
	return not (power_ups + weapon_pickups).any(func(item): return item.pos == point)

func choose_power_up() -> String:
	return pickup_settings.choose("power_up", rng)

func place_pickup(point: Vector2, category: String, kind: String, settings: Resource = null, require_reachable: bool = false) -> bool:
	if settings == null:
		settings = pickup_settings
	if category not in ["power_up", "weapon"] or kind.is_empty():
		return false
	if (category == "power_up" and kind not in PickupConfig.POWER_UP_IDS) or (category == "weapon" and not catalog.data.weapons.has(kind)):
		return false
	if category == "power_up" and power_ups.size() >= pickup_settings.power_up_limit:
		return false
	if not Map.can_occupy(map, point) or in_base(point, 33):
		return false
	if power_ups.any(func(item): return item.pos.is_equal_approx(point)) or weapon_pickups.any(func(item): return item.pos.is_equal_approx(point)):
		return false
	if require_reachable and (not valid_power_up_cell(point) or point not in reachable_power_up_cells()):
		return false
	var collection: Array = power_ups if category == "power_up" else weapon_pickups
	collection.append({"pos": point, "kind": kind, "life": settings.lifetime_for(kind)})
	return true

func drop_pickup(point: Vector2, settings: Resource = null, category: String = "", kind: String = "") -> void:
	if settings == null:
		settings = pickup_settings
	if not settings.drop_enabled or rng.randf() >= settings.drop_chance:
		return
	if kind.is_empty():
		category = "weapon" if rng.randf() < settings.weapon_chance else "power_up"
		var compatible: Array = []
		for state in living_players():
			for weapon in compatible_weapons(state.id - 1):
				if weapon not in compatible:
					compatible.append(weapon)
		kind = settings.choose(category, rng, compatible)
	place_pickup(point, category, kind, settings)

func place_power_up(point: Vector2, reachable: Array = []) -> bool:
	if not valid_power_up_cell(point):
		return false
	var cells = reachable_power_up_cells() if reachable.is_empty() else reachable
	if point not in cells:
		return false
	return place_pickup(point, "power_up", choose_power_up())

func spawn_power_ups() -> void:
	if power_ups.size() >= pickup_settings.power_up_limit:
		return
	var reachable = reachable_power_up_cells()
	var cells = reachable.duplicate()
	var count = mini(rng.randi_range(pickup_settings.periodic_min, pickup_settings.periodic_max), pickup_settings.power_up_limit - power_ups.size())
	for i in count:
		while not cells.is_empty():
			var index = rng.randi_range(0, cells.size() - 1)
			var point: Vector2 = cells[index]
			cells.remove_at(index)
			if living_players().all(func(state): return point.distance_to(state.actor.pos) >= R.POWER_UP_SAFE_DISTANCE) and place_power_up(point, reachable):
				break

func update_power_ups(dt: float) -> void:
	for state in players:
		for kind in state.active_power_ups.keys():
			state.active_power_ups[kind] -= dt
			if state.active_power_ups[kind] <= 0:
				state.active_power_ups.erase(kind)
	for item in power_ups + weapon_pickups:
		item.life -= dt
	power_ups = power_ups.filter(func(item): return item.life > 0)
	weapon_pickups = weapon_pickups.filter(func(item): return item.life > 0)
	if not pickup_settings.periodic_enabled:
		return
	power_up_timer -= dt
	if power_up_timer <= 0:
		power_up_timer += pickup_settings.periodic_interval
		spawn_power_ups()

func collect_power_ups() -> void:
	for item in power_ups.duplicate():
		var collected := false
		for state in living_players():
			if state.actor.pos.distance_to(item.pos) <= R.POWER_UP_PICKUP_RADIUS:
				activate_power_up(item.kind, state.id - 1)
				power_ups.erase(item)
				collected = true
				break
		if not collected and enemies.any(func(enemy): return enemy.pos.distance_to(item.pos) <= R.POWER_UP_PICKUP_RADIUS):
			power_ups.erase(item)
	for item in weapon_pickups.duplicate():
		for state in living_players():
			if state.actor.pos.distance_to(item.pos) <= R.POWER_UP_PICKUP_RADIUS and equip_weapon(item.kind, state.id - 1):
				weapon_pickups.erase(item)
				break
