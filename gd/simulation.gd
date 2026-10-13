extends RefCounted
const R = preload("res://gd/rules.gd")
const Map = preload("res://gd/battle_map.gd")

var loadout: Resource
var sequence = 1
var map: Array = Map.create_map()
var player: Dictionary
var enemies: Array = []
var bullets: Array = []
var effects: Array = []
var power_ups: Array = []
var active_power_ups: Dictionary = {}
var power_up_timer = R.POWER_UP_INTERVAL
var pending_shots: Array = []
var rng = RandomNumberGenerator.new()
var status = "ready"
var base_hp = R.BASE_HP
var lives = R.LIVES
var wave = 0
var score = 0
var kills = 0
var elapsed = 0.0
var to_spawn = 0
var spawn_timer = 0.0
var wave_timer = 0.0
var invulnerable = 0.0
var revision = 0
var shots_fired = 0
var player_muzzle_distances: Dictionary = {}
var enemy_muzzle_distances: Dictionary = {}
var message = "Phòng tuyến cuối cùng"

func _init(configuration: Resource = null) -> void:
	if configuration == null:
		var catalog = preload("res://gd/character_catalog.gd").new()
		var character: String = catalog.data.default_character
		var c: Dictionary = catalog.data.characters[character]
		configuration = catalog.create(character, c.default_body, c.default_weapon)
	loadout = configuration
	for direction in R.VECTOR:
		player_muzzle_distances[direction] = loadout.muzzle_vectors(direction)[0].dot(R.VECTOR[direction])
	rng.randomize()
	player = make_actor("player", R.BASE - Vector2(0, 2 * R.TILE))

func make_actor(kind: String, point: Vector2) -> Dictionary:
	var hp = loadout.max_hp if kind == "player" else (4 if kind == "tank" else 2)
	var actor = {"id": sequence, "pos": point, "kind": kind, "hp": hp, "max_hp": hp,
		"dir": "up" if kind == "player" else "down", "cooldown": 0.7,
		"moving": false, "move_clock": 0.0, "shot_clock": 0.0, "hurt_clock": 0.0,
		"shot_duration": loadout.weapon.shot_duration if kind == "player" else 4.0 / 12.0}
	sequence += 1
	return actor

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
	if not pending_shots.is_empty():
		return
	var schedule: Array = loadout.weapon.schedule(power_up_active("double_shot"))
	actor.cooldown = schedule.back().time + player_shot_cooldown()
	for shot in schedule:
		if shot.time == 0:
			emit_player_volley(actor, shot.barrels)
		else:
			pending_shots.append({"actor": actor.duplicate(), "delay": shot.time, "barrels": shot.barrels})
	if not pending_shots.is_empty():
		actor.moving = false

func emit_player_volley(actor: Dictionary, barrels: Array) -> void:
	var vector: Vector2 = R.VECTOR[actor.dir]
	var muzzles: Array = loadout.muzzle_vectors(actor.dir)
	for barrel in barrels:
		var muzzle: Vector2 = muzzles[barrel]
		var baseline: float = muzzles[0].dot(vector)
		var distance: float = player_muzzle_distances.get(actor.dir, baseline)
		muzzle += vector * (distance - baseline)
		emit_projectile(actor, muzzle, loadout.weapon.damage, loadout.weapon.bullet_speed)
	player.shot_clock = player.shot_duration

func emit_bullet(actor: Dictionary) -> void:
	if actor.kind == "player":
		emit_player_volley(actor, range(loadout.weapon.barrel_offsets.size()))
	else:
		var distance: float = enemy_muzzle_distances.get(actor.kind, {}).get(actor.dir, 20.0)
		emit_projectile(actor, R.VECTOR[actor.dir] * distance)

func emit_projectile(actor: Dictionary, muzzle: Vector2, damage: int = 1, speed: float = R.BULLET_SPEED) -> void:
	var vector: Vector2 = R.VECTOR[actor.dir]
	var baseline: float = 0.0 if actor.kind == "player" else 20.0
	var muzzle_distance = muzzle.dot(vector)
	var lateral = muzzle - vector * muzzle_distance
	actor.shot_clock = actor.shot_duration
	var bullet = {"id": sequence, "pos": actor.pos + muzzle, "dir": actor.dir, "friendly": actor.kind == "player", "damage": damage, "speed": speed}
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
	if tile.get("kind") not in ["brick", "steel"] or (tile.kind == "steel" and not can_damage_steel):
		return
	tile.hp -= 1
	revision += 1
	if tile.hp == 0:
		tile.kind = "floor"
		for enemy in enemies:
			enemy.erase("target")
		if rng.randf() < R.WALL_DROP_CHANCE:
			place_power_up(tile_center(point))
	effect(point, "explosion" if tile.hp == 0 else "spark")

func hit_player() -> void:
	if invulnerable > 0 or power_up_active("shield"):
		return
	player.hp -= 1
	player.hurt_clock = 0.16
	invulnerable = 0.85
	if player.hp <= 0:
		lives -= 1
		pending_shots.clear()
		effect(player.pos, "explosion")
		if lives <= 0:
			status = "lost"
			message = "Robot đã bị vô hiệu hóa"
			return
		player = make_actor("player", R.BASE - Vector2(0, 2 * R.TILE))
		invulnerable = 3.0

func in_base(point: Vector2, radius: float) -> bool:
	return absf(point.x - R.BASE.x) < radius and absf(point.y - R.BASE.y) < radius

func update(delta: float, direction: String = "", shooting: bool = false) -> void:
	if status != "playing":
		return
	var dt = minf(delta, 0.05)
	elapsed += dt
	update_power_ups(dt)
	var lock_remaining = 0.0
	for shot in pending_shots:
		lock_remaining = maxf(lock_remaining, shot.delay)
	for shot in pending_shots.duplicate():
		shot.delay -= dt
		if shot.delay <= 0:
			if shot.actor.id == player.id and player.hp > 0:
				emit_player_volley(shot.actor, shot.barrels)
			pending_shots.erase(shot)
	invulnerable = maxf(0, invulnerable - dt)
	for fx in effects:
		fx.life -= dt
	effects = effects.filter(func(fx): return fx.life > 0)
	player.cooldown = maxf(0, player.cooldown - dt)
	player.shot_clock = maxf(0, player.shot_clock - dt)
	player.hurt_clock = maxf(0, player.hurt_clock - dt)
	player.moving = false
	var move_dt = maxf(0.0, dt - lock_remaining)
	if R.VECTOR.has(direction) and pending_shots.is_empty() and move_dt > 0:
		player.dir = direction
		var point: Vector2 = player.pos + R.VECTOR[direction] * loadout.move_speed * (R.SPEED_BOOST_MULTIPLIER if power_up_active("speed_boost") else 1.0) * move_dt
		if Map.can_occupy(map, point, loadout.collider_radius) and not in_base(point, 25):
			player.pos = point
			player.moving = true
	player.move_clock = player.move_clock + dt if player.moving else 0.0
	if shooting:
		fire(player)
	if to_spawn > 0:
		spawn_timer -= dt
		if spawn_timer <= 0:
			var lane: int = [1, 10, 19][(R.WAVE_COUNTS[wave - 1] - to_spawn) % 3]
			var point = Vector2((lane + 0.5) * R.TILE, R.TILE / 2.0)
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


func bullet_collision(bullet: Dictionary) -> bool:
	var point: Vector2 = bullet.pos
	if point.x < 0 or point.y < 0 or point.x >= R.WIDTH or point.y >= R.HEIGHT:
		return true
	var tile = Map.tile_at(map, point)
	if tile.get("kind") == "brick":
		for hit in bullet.get("damage", 1):
			damage_brick(point)
		return true
	if tile.get("kind") == "steel":
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
			effect(R.BASE, "explosion")
		return true
	elif absf(point.x - player.pos.x) < loadout.collider_radius and absf(point.y - player.pos.y) < loadout.collider_radius:
		hit_player()
		return true
	return false

func move_enemy(enemy: Dictionary, dt: float) -> void:
	if enemy.shot_clock > 0:
		return
	if absf(enemy.pos.x - R.BASE.x) < 18 and enemy.pos.y > R.BASE.y - 100:
		enemy.dir = "down"
		fire(enemy)
		return
	var diff: Vector2 = player.pos - enemy.pos
	if enemy.cooldown <= 0 and (absf(diff.x) < 14 or absf(diff.y) < 14) and diff.length() < 240:
		enemy.dir = ("down" if diff.y > 0 else "up") if absf(diff.x) < 14 else ("right" if diff.x > 0 else "left")
		fire(enemy)
		return
	if not enemy.has("target"):
		var start = Vector2i(floori(enemy.pos.x / R.TILE), floori(enemy.pos.y / R.TILE))
		var center = (Vector2(start) + Vector2(0.5, 0.5)) * R.TILE
		if enemy.pos.distance_to(center) > 1:
			enemy.target = center
		else:
			var path = Map.find_path(map, start, Vector2i(10, 16))
			if not path.is_empty():
				enemy.target = (Vector2(path[0]) + Vector2(0.5, 0.5)) * R.TILE
	if not enemy.has("target"):
		return
	var diff_target: Vector2 = enemy.target - enemy.pos
	enemy.dir = ("right" if diff_target.x > 0 else "left") if absf(diff_target.x) > 0.5 else ("down" if diff_target.y > 0 else "up")
	if Map.tile_at(map, enemy.target).get("kind") == "brick":
		fire(enemy)
		return
	var step = (40 if enemy.kind == "tank" else 54 + wave * 3) * dt
	if diff_target.length() <= step:
		enemy.pos = enemy.target
		enemy.erase("target")
	else:
		enemy.pos += R.VECTOR[enemy.dir] * step

func power_up_active(kind: String) -> bool:
	return active_power_ups.get(kind, 0.0) > 0

func activate_power_up(kind: String) -> void:
	if R.POWER_UP_WEIGHTS.has(kind):
		active_power_ups[kind] = R.POWER_UP_DURATION

func player_shot_cooldown() -> float:
	return loadout.weapon.cooldown * (loadout.weapon.rapid_rest_multiplier if power_up_active("rapid_fire") else 1.0)

func tile_center(point: Vector2) -> Vector2:
	return (Vector2(Vector2i(point / R.TILE)) + Vector2(0.5, 0.5)) * R.TILE

func reachable_power_up_cells() -> Array:
	var start = Vector2i(player.pos / R.TILE)
	var frontier: Array = [start]
	var seen = {start: true}
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
	for actor in [player] + enemies:
		if absf(actor.pos.x - point.x) < R.TILE / 2.0 + 16 and absf(actor.pos.y - point.y) < R.TILE / 2.0 + 16:
			return false
	return not power_ups.any(func(item): return item.pos == point)

func choose_power_up() -> String:
	var total = 0
	for weight in R.POWER_UP_WEIGHTS.values():
		total += weight
	var roll = rng.randi_range(1, total)
	for kind in R.POWER_UP_WEIGHTS:
		roll -= R.POWER_UP_WEIGHTS[kind]
		if roll <= 0:
			return kind
	return "shield"

func place_power_up(point: Vector2, reachable: Array = []) -> bool:
	if power_ups.size() >= R.POWER_UP_LIMIT or not valid_power_up_cell(point):
		return false
	var cells = reachable_power_up_cells() if reachable.is_empty() else reachable
	if point not in cells:
		return false
	power_ups.append({"pos": point, "kind": choose_power_up(), "life": R.POWER_UP_LIFETIME})
	return true

func spawn_power_ups() -> void:
	if power_ups.size() >= R.POWER_UP_LIMIT:
		return
	var reachable = reachable_power_up_cells()
	var cells = reachable.duplicate()
	var count = mini(rng.randi_range(1, 2), R.POWER_UP_LIMIT - power_ups.size())
	for i in count:
		while not cells.is_empty():
			var index = rng.randi_range(0, cells.size() - 1)
			var point: Vector2 = cells[index]
			cells.remove_at(index)
			if point.distance_to(player.pos) >= R.POWER_UP_SAFE_DISTANCE and place_power_up(point, reachable):
				break

func update_power_ups(dt: float) -> void:
	for kind in active_power_ups.keys():
		active_power_ups[kind] -= dt
		if active_power_ups[kind] <= 0:
			active_power_ups.erase(kind)
	for item in power_ups:
		item.life -= dt
	power_ups = power_ups.filter(func(item): return item.life > 0)
	power_up_timer -= dt
	if power_up_timer <= 0:
		power_up_timer += R.POWER_UP_INTERVAL
		spawn_power_ups()

func collect_power_ups() -> void:
	for item in power_ups.duplicate():
		if player.pos.distance_to(item.pos) <= R.POWER_UP_PICKUP_RADIUS:
			activate_power_up(item.kind)
			power_ups.erase(item)
		elif enemies.any(func(enemy): return enemy.pos.distance_to(item.pos) <= R.POWER_UP_PICKUP_RADIUS):
			power_ups.erase(item)
