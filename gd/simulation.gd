extends RefCounted
const R = preload("res://gd/rules.gd")
const Map = preload("res://gd/battle_map.gd")

var sequence = 1
var map: Array = Map.create_map()
var player: Dictionary
var enemies: Array = []
var bullets: Array = []
var effects: Array = []
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

func _init() -> void:
	player = make_actor("player", R.BASE - Vector2(0, 2 * R.TILE))

func make_actor(kind: String, point: Vector2) -> Dictionary:
	var hp = R.PLAYER_HP if kind == "player" else (4 if kind == "tank" else 2)
	var actor = {"id": sequence, "pos": point, "kind": kind, "hp": hp, "max_hp": hp,
		"dir": "up" if kind == "player" else "down", "cooldown": 0.7,
		"moving": false, "move_clock": 0.0, "shot_clock": 0.0, "hurt_clock": 0.0,
		"shot_duration": R.SHOT_COOLDOWN if kind == "player" else 4.0 / 12.0}
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
	if actor.cooldown > 0:
		return
	actor.cooldown = R.SHOT_COOLDOWN if actor.kind == "player" else (1.3 if actor.kind == "tank" else 1.7)
	var vector: Vector2 = R.VECTOR[actor.dir]
	var baseline: float = R.PLAYER_MUZZLE_DISTANCE if actor.kind == "player" else 20.0
	var distances: Dictionary = player_muzzle_distances if actor.kind == "player" else enemy_muzzle_distances.get(actor.kind, {})
	var muzzle_distance: float = distances.get(actor.dir, baseline)
	actor.shot_clock = actor.shot_duration
	var bullet = {"id": sequence, "pos": actor.pos + vector * muzzle_distance, "dir": actor.dir, "friendly": actor.kind == "player"}
	var blocked = false
	if muzzle_distance > baseline:
		var distance = baseline
		while distance < muzzle_distance:
			bullet.pos = actor.pos + vector * distance
			if bullet_collision(bullet):
				blocked = true
				break
			distance = minf(muzzle_distance, distance + 2.0)
		if not blocked:
			bullet.pos = actor.pos + vector * muzzle_distance
			blocked = bullet_collision(bullet)
	if not blocked:
		bullets.append(bullet)
	sequence += 1
	shots_fired += 1
	effect(actor.pos + vector * muzzle_distance, "spark")

func effect(point: Vector2, kind: String) -> void:
	var life = 0.13 if kind == "spark" else 0.48
	effects.append({"pos": point, "kind": kind, "life": life, "max": life})

func damage_brick(point: Vector2) -> void:
	var tile = Map.tile_at(map, point)
	if tile.get("kind") != "brick":
		return
	tile.hp -= 1
	revision += 1
	if tile.hp == 0:
		tile.kind = "floor"
		for enemy in enemies:
			enemy.erase("target")
	effect(point, "explosion" if tile.hp == 0 else "spark")

func hit_player() -> void:
	if invulnerable > 0:
		return
	player.hp -= 1
	player.hurt_clock = 0.16
	invulnerable = 0.85
	if player.hp <= 0:
		lives -= 1
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
	invulnerable = maxf(0, invulnerable - dt)
	for fx in effects:
		fx.life -= dt
	effects = effects.filter(func(fx): return fx.life > 0)
	player.cooldown = maxf(0, player.cooldown - dt)
	player.shot_clock = maxf(0, player.shot_clock - dt)
	player.hurt_clock = maxf(0, player.hurt_clock - dt)
	player.moving = false
	if R.VECTOR.has(direction):
		player.dir = direction
		var point: Vector2 = player.pos + R.VECTOR[direction] * R.PLAYER_SPEED * dt
		if Map.can_occupy(map, point) and not in_base(point, 25):
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
	for bullet in bullets.duplicate():
		var dead = false
		var vector: Vector2 = R.VECTOR[bullet.dir]
		var steps = maxi(1, ceili(R.BULLET_SPEED * dt / 5))
		for substep in steps:
			bullet.pos += vector * R.BULLET_SPEED * dt / steps
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
		damage_brick(point)
		return true
	if tile.get("kind") == "steel":
		effect(point, "spark")
		return true
	if bullet.friendly:
		for enemy in enemies:
			if absf(enemy.pos.x - point.x) < 16 and absf(enemy.pos.y - point.y) < 16:
				enemy.hp -= 1
				enemy.hurt_clock = 0.16
				effect(enemy.pos, "explosion" if enemy.hp <= 0 else "spark")
				if enemy.hp <= 0:
					enemies.erase(enemy)
					kills += 1
					score += 250 if enemy.kind == "tank" else 100
				return true
	elif in_base(point, 28):
		base_hp -= 1
		effect(point, "spark")
		if base_hp <= 0:
			status = "lost"
			message = "Căn cứ đã bị phá hủy"
			effect(R.BASE, "explosion")
		return true
	elif absf(point.x - player.pos.x) < 14 and absf(point.y - player.pos.y) < 14:
		hit_player()
		return true
	return false

func move_enemy(enemy: Dictionary, dt: float) -> void:
	if absf(enemy.pos.x - R.BASE.x) < 18 and enemy.pos.y > R.BASE.y - 100:
		enemy.dir = "down"
		fire(enemy)
		return
	var diff: Vector2 = player.pos - enemy.pos
	if (absf(diff.x) < 14 or absf(diff.y) < 14) and diff.length() < 240:
		enemy.dir = ("down" if diff.y > 0 else "up") if absf(diff.x) < 14 else ("right" if diff.x > 0 else "left")
		fire(enemy)
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
