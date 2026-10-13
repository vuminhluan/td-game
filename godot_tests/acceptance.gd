extends SceneTree
const Sim = preload("res://gd/simulation.gd")
const Map = preload("res://gd/battle_map.gd")
const R = preload("res://gd/rules.gd")
var checks = 0
var failures = 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)

func step(sim: RefCounted, seconds: float) -> void:
	for i in ceili(seconds * 60):
		sim.update(1.0 / 60)

func bullet(sim: RefCounted, point: Vector2, friendly: bool = false, direction: String = "down") -> void:
	sim.bullets.append({"id": 10000, "pos": point, "dir": direction, "friendly": friendly})

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
	var brick = Vector2(180, 60)
	check(not Map.can_occupy(sim.map, brick), "brick blocks actors")
	for hp in [2, 1, 0]:
		sim.damage_brick(brick)
		check(sim.map[1][4].hp == hp, "brick loses one HP per hit")
	check(sim.map[1][4].kind == "floor" and Map.can_occupy(sim.map, brick), "three hits open brick path")
	check(Map.can_occupy(sim.map, Vector2(180, 220)), "grass is traversable")
	check(not Map.can_occupy(sim.map, Vector2(140, 180)), "water blocks actors")
	check(not Map.can_occupy(sim.map, Vector2(180, 140)), "steel blocks actors")
	check(not Map.can_occupy(sim.map, Vector2(1, 1)), "boundaries block actors")
	for lane in [1, 10, 19]:
		var previous = Vector2i(lane, 0)
		var path = Map.find_path(sim.map, previous, Vector2i(10, 16))
		check(not path.is_empty() and path.back() == Vector2i(10, 16), "spawn lane reaches base")
		for point in path:
			check(absi(point.x - previous.x) + absi(point.y - previous.y) == 1, "path uses cardinal moves")
			check(sim.map[point.y][point.x].kind not in ["water", "steel"], "path avoids impassable terrain")
			previous = point
	var grid = Map.create_map()
	grid[0][1] = {"kind": "brick", "hp": 3}
	grid[1][0] = {"kind": "steel", "hp": 0}
	check(Vector2i(1, 0) in Map.find_path(grid, Vector2i.ZERO, Vector2i(2, 0)), "path breaches brick when necessary")
	sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
	sim.start()
	step(sim, 1)
	sim.pause()
	var snapshot = var_to_bytes([sim.player, sim.enemies, sim.bullets, sim.effects, sim.elapsed, sim.spawn_timer])
	step(sim, 10)
	check(snapshot == var_to_bytes([sim.player, sim.enemies, sim.bullets, sim.effects, sim.elapsed, sim.spawn_timer]), "pause freezes all state")
	sim.pause()
	step(sim, 1)
	check(sim.elapsed > 1.9, "resume advances time")
	sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
	sim.start()
	var original: Vector2 = sim.player.pos
	sim.update(0.05, "right")
	check(sim.player.pos.x > original.x and sim.player.pos.y == original.y, "movement stays on one axis")
	sim.player.pos = R.BASE - Vector2(0, 26)
	sim.update(0.05, "down")
	check(sim.player.pos == R.BASE - Vector2(0, 26), "player cannot enter base")
	for friendly in [true, false]:
		sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
		sim.start()
		bullet(sim, R.BASE - Vector2(0, 30), friendly)
		sim.update(0.05)
		check(sim.base_hp == R.BASE_HP - (0 if friendly else 1), "only enemy shots damage base")
	sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
	sim.start()
	bullet(sim, Vector2(140, 158), true)
	sim.update(0.05)
	check(sim.bullets.size() == 1, "bullets traverse water")
	sim.bullets.clear()
	bullet(sim, Vector2(180, 118), true)
	sim.update(0.05)
	check(sim.bullets.is_empty(), "steel absorbs bullets")
	for kind in ["robot", "tank"]:
		sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
		sim.start()
		sim.to_spawn = 99
		sim.spawn_timer = 999
		var enemy = sim.make_actor(kind, Vector2(420, 300))
		sim.enemies.append(enemy)
		for hit in enemy.max_hp:
			bullet(sim, enemy.pos + Vector2(0, 19), true, "up")
			sim.update(0.02)
		check(sim.enemies.is_empty() and sim.kills == 1, "enemy dies after armor depleted")
		check(sim.score == (250 if kind == "tank" else 100), "kill awards correct score")
	sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
	sim.start()
	sim.player.pos = Vector2(20, 740)
	step(sim, 180)
	check(sim.status == "lost" and sim.base_hp == 0, "undefended base is destroyed by enemy AI")
	var ids = {sim.player.id: true}
	for enemy in sim.enemies:
		check(not ids.has(enemy.id), "actor IDs remain unique")
		ids[enemy.id] = true
	sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
	sim.start()
	for wave in range(1, 6):
		check(sim.wave == wave, "wave advances in order")
		sim.to_spawn = 0
		sim.enemies.clear()
		step(sim, 5.1)
	check(sim.status == "won", "clearing five waves wins")
	var fresh = Sim.new(preload("res://assets/loadouts/standard.tres"))
	check(fresh.status == "ready" and fresh.score == 0 and fresh.base_hp == 20 and fresh.map[1][4].hp == 3, "restart resets state and terrain")
	sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
	sim.start()
	sim.to_spawn = 99
	sim.spawn_timer = 999
	for life in [3, 2, 1]:
		sim.player.hp = 1
		sim.invulnerable = 0
		bullet(sim, sim.player.pos - Vector2(0, 15))
		sim.update(0.02)
		check(sim.lives == life - 1, "destroying robot consumes one life")
		if life > 1:
			check(sim.invulnerable == 3 and sim.player.hp == 5, "respawn grants full armor and three seconds immunity")
			bullet(sim, sim.player.pos - Vector2(0, 15))
			sim.update(0.02)
			check(sim.player.hp == 5, "respawn immunity rejects damage")
	check(sim.status == "lost", "losing third robot ends game")
	await ui_checks()
	print("ACCEPTANCE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func key(game: Control, code: int, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	game._input(event)

func touch(game: Control, index: int, point: Vector2, pressed: bool) -> void:
	var event = InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	game._input(event)

func ui_checks() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.start_button.pressed.emit()
	check(game.sim.status == "playing" and not game.overlay.visible, "start button deploys robot")
	key(game, KEY_W, true)
	key(game, KEY_D, true)
	check(game.input_direction() == "right", "most recent key wins")
	key(game, KEY_D, false)
	check(game.input_direction() == "up", "release restores previous direction")
	key(game, KEY_SPACE, true)
	check(game.keyboard_fire, "space holds fire")
	key(game, KEY_P, true)
	check(game.sim.status == "paused" and game.held_keys.is_empty() and not game.keyboard_fire, "pause clears input")
	game.start_button.pressed.emit()
	check(game.sim.status == "playing", "overlay button resumes")
	game.focus_lost()
	check(game.sim.status == "paused", "focus loss pauses game")
	game.activate()
	game.sim.status = "lost"
	game.sim.score = 500
	game.activate()
	check(game.sim.status == "playing" and game.sim.score == 0 and game.sim.wave == 1, "replay starts clean campaign")
	for dimensions in [Vector2i(320, 568), Vector2i(375, 667), Vector2i(414, 896), Vector2i(768, 1024), Vector2i(1280, 720), Vector2i(1280, 1000)]:
		root.size = dimensions
		await process_frame
		game.layout()
		check(game.board_rect.position.x >= 0 and game.board_rect.end.x <= dimensions.x, "battlefield fits viewport")
		check(game.board_rect.end.y <= dimensions.y, "battlefield fits viewport height")
		if game.radar_rect.has_area():
			check(game.radar_rect.end.y <= dimensions.y - 76, "radar fits short desktop viewport")
		if game.mobile:
			for rect in game.touch_rects.values():
				check(rect.position.x >= 0 and rect.end.x <= dimensions.x and rect.end.y <= dimensions.y, "touch controls fit viewport")
			if dimensions.x == 375:
				game.sim.status = "paused"
				game.refresh_hud()
				var tap = InputEventScreenTouch.new()
				tap.index = 7
				tap.position = game.overlay.position + game.start_button.position + game.start_button.size / 2
				tap.pressed = true
				Input.parse_input_event(tap)
				await process_frame
				tap = tap.duplicate()
				tap.pressed = false
				Input.parse_input_event(tap)
				await process_frame
				check(game.sim.status == "playing", "native GUI receives touch tap on resume button")
			var up: Vector2 = game.touch_rects.up.get_center()
			var fire: Vector2 = game.touch_rects.fire.get_center()
			touch(game, 0, up, true)
			touch(game, 1, fire, true)
			check(game.input_direction() == "up" and "fire" in game.pointers.values(), "multitouch moves and fires together")
			touch(game, 1, fire, false)
			check(game.input_direction() == "up" and "fire" not in game.pointers.values(), "releasing fire preserves movement touch")
			touch(game, 0, up, false)
			check(game.input_direction() == "", "releasing touch stops movement")
	game.toggle_sound()
	check(game.sound_enabled and game.audio.stream != null, "sound toggle enables synthesized audio")
	game.audio.stop()
	await process_frame
	game.free()
	await process_frame
