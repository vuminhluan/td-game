extends SceneTree
const Terrain = preload("res://godot_tests/terrain_fixture.gd")
const Catalog = preload("res://gd/character_catalog.gd")
const Sim = preload("res://gd/simulation.gd")
const R = preload("res://gd/rules.gd")
var checks = 0
var failures = 0
var catalog = Catalog.new()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func fresh(configuration: Resource) -> RefCounted:
	var sim = Sim.new(configuration)
	for row in sim.map:
		for tile in row:
			Terrain.apply(tile, "floor")
	sim.player.pos = Vector2(420, 380)
	sim.player.cooldown = 0
	sim.start()
	sim.to_spawn = 99
	sim.spawn_timer = 999
	sim.power_up_timer = 999
	return sim

func advance(sim: RefCounted, seconds: float, direction: String = "", shooting: bool = false) -> void:
	var remaining = seconds
	while remaining > 0.0000001:
		var dt = minf(0.001, remaining)
		sim.update(dt, direction, shooting)
		remaining -= dt

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check(catalog.errors.is_empty(), "shared config validates")
	var default_sim = Sim.new()
	check(default_sim.loadout.weapon.damage == 3 and default_sim.loadout.max_hp == 5, "standalone simulation uses shared config")
	check(catalog.create("tank", "tank_body", "gatling") == null, "tank rejects Gatling")
	check(catalog.create("robot", "tank_body", "standard") == null, "robot rejects tank body")
	check(catalog.create("missing", "robot_body", "standard") == null, "unknown character rejected")
	for character in catalog.data.characters:
		var c: Dictionary = catalog.data.characters[character]
		for weapon_id in c.weapons:
			var configuration: Resource = catalog.create(character, c.default_body, weapon_id)
			check(configuration != null and configuration.max_hp == c.hp and configuration.move_speed == c.speed, "character stats: " + character)
			var sim = fresh(configuration)
			var start: Vector2 = sim.player.pos
			advance(sim, 0.1, "right")
			check(absf(sim.player.pos.x - start.x - c.speed * 0.1) < 0.002, "movement speed: " + character)
			for direction in R.VECTOR:
				for state in ["idle", "walk", "attack"]:
					sim.player.dir = direction
					sim.player.moving = state == "walk"
					sim.player.shot_clock = sim.player.shot_duration if state == "attack" else 0
					check(configuration.body.frame_for(sim.player, sim.elapsed) != null and configuration.weapon.layered_art.texture_for(direction) != null, "layer artwork: " + character + "/" + weapon_id + "/" + direction + "/" + state)
				check(configuration.body.cutouts_for(direction, "idle", 0).is_empty(), "clean body without runtime cutouts")
				for kind in ["brick", "steel", "enemy"]:
					collision_checks(configuration, direction, kind)
			for doubled in [false, true]:
				for rapid in [false, true]:
					burst_checks(configuration, doubled, rapid)
	invalid_config_checks()
	await ui_checks()
	print("CHARACTER SELECTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func burst_checks(configuration: Resource, doubled: bool, rapid: bool) -> void:
	var sim = fresh(configuration)
	var weapon: Resource = configuration.weapon
	if doubled:
		sim.activate_power_up("double_shot")
	if rapid:
		sim.activate_power_up("rapid_fire")
	var schedule: Array = weapon.schedule(doubled)
	var duration: float = schedule.back().time
	var rest: float = weapon.cooldown * (0.5 if rapid else 1.0)
	var expected = 0
	var origin: Vector2 = sim.player.pos
	sim.fire(sim.player)
	check(is_equal_approx(sim.player.cooldown, duration + rest), "cooldown counts burst plus rest")
	var elapsed = 0.0
	for shot in schedule:
		if shot.time > 0:
			var wait_time: float = shot.time - elapsed
			advance(sim, wait_time - 0.002, "right")
			check(sim.shots_fired == expected and sim.player.pos == origin and sim.player.dir == "up", "no early shot, position and direction locked")
			advance(sim, 0.0021)
			elapsed = shot.time + 0.0001
		expected += shot.barrels.size()
		check(sim.shots_fired == expected, "scheduled volley emitted after release")
		for i in shot.barrels.size():
			var muzzle: Vector2 = configuration.muzzle_vectors("up")[shot.barrels[i]]
			check(sim.effects[sim.effects.size() - shot.barrels.size() + i].pos.is_equal_approx(origin + muzzle), "flash follows actual barrel/side event")
		if not sim.bullets.is_empty():
			check(sim.bullets.back().speed == weapon.bullet_speed and sim.bullets.back().damage == weapon.damage, "projectile uses configured damage and speed")
	check(sim.pending_shots.is_empty(), "unlock after final projectile")
	advance(sim, 0.01, "right")
	check(sim.player.pos.x > origin.x and sim.player.dir == "right", "movement allowed during rest")
	advance(sim, rest - 0.013, "", true)
	check(sim.shots_fired == expected, "hold cannot start before full rest")
	advance(sim, 0.005, "", true)
	check(sim.shots_fired > expected, "holding begins next burst after rest")
	sim = fresh(configuration)
	sim.activate_power_up("double_shot")
	sim.fire(sim.player)
	sim.pause()
	var snapshot = var_to_bytes([sim.player, sim.pending_shots, sim.bullets, sim.effects, sim.elapsed])
	advance(sim, 0.1, "left", true)
	check(snapshot == var_to_bytes([sim.player, sim.pending_shots, sim.bullets, sim.effects, sim.elapsed]), "pause freezes burst and animation")
	sim.pause()
	sim.player.hp = 1
	sim.hit_player()
	check(sim.pending_shots.is_empty() and sim.player.hp == configuration.max_hp, "death cancels burst; respawn restores character HP")
	sim = fresh(configuration)
	sim.activate_power_up("double_shot")
	sim.activate_power_up("rapid_fire")
	sim.fire(sim.player)
	var cooldown: float = sim.player.cooldown
	sim.active_power_ups.clear()
	advance(sim, duration + 0.501)
	var doubled_count = 0
	for shot in weapon.schedule(true):
		doubled_count += shot.barrels.size()
	check(sim.shots_fired == doubled_count, "power-up expiry does not truncate committed burst")
	sim = fresh(configuration)
	sim.fire(sim.player)
	sim.activate_power_up("double_shot")
	advance(sim, weapon.burst_times.back() + 0.01)
	var basic_count = weapon.burst_times.size() * (1 if weapon.alternating else weapon.barrel_offsets.size())
	check(sim.shots_fired == basic_count, "pickup during burst applies to next trigger")
	check(is_equal_approx(cooldown, weapon.schedule(true).back().time + weapon.cooldown / 2), "rest modifier captured at trigger")

func collision_checks(configuration: Resource, direction: String, kind: String) -> void:
	var sim = fresh(configuration)
	sim.player.dir = direction
	var muzzles: Array = configuration.muzzle_vectors(direction)
	var count: int = 1 if configuration.weapon.alternating else muzzles.size()
	var muzzle: Vector2 = sim.player.pos + muzzles[0]
	var tile = Vector2i(muzzle / R.TILE)
	var target: Dictionary = {}
	if kind == "enemy":
		target = sim.make_actor("tank", muzzle)
		target.hp = 100
		sim.enemies.append(target)
	else:
		for point in muzzles:
			var cell = Vector2i((sim.player.pos + point) / R.TILE)
			sim.map[cell.y][cell.x] = Terrain.tile(kind, 100)
	sim.fire(sim.player)
	check(sim.bullets.is_empty(), "every first volley collides at muzzle: " + kind)
	if kind == "enemy":
		check(target.hp == 100 - count * configuration.weapon.damage, "enemy takes configured damage per bullet")
	elif kind == "steel":
		check(sim.map[tile.y][tile.x].hp == 100, "steel blocks without damage")
	else:
		var damage = 0
		for row in sim.map:
			for cell in row:
				if cell.kind == "brick":
					damage += 100 - cell.hp
		check(damage == count * configuration.weapon.damage, "brick takes each projectile damage")

func invalid_config_checks() -> void:
	var bad = Catalog.new()
	bad.data.characters.robot.hp = -1
	bad.data.characters.tank.default_weapon = "gatling"
	bad.data.weapons.standard.times = [0, -1]
	bad.data.weapons.standard.muzzles.robot.up = [["invalid", 0]]
	bad.data.bodies.robot_body.character = "tank"
	bad.validate()
	check(bad.errors.size() >= 5 and bad.create("robot", "robot_body", "standard") == null, "invalid values and references fail closed")
	for field in ["times", "barrels", "muzzles"]:
		bad = Catalog.new()
		bad.data.weapons.missiles[field] = null
		bad.validate()
		check(not bad.errors.is_empty(), "malformed weapon field fails with diagnostic: " + field)
	bad = Catalog.new()
	bad.data.characters.robot.weapon_art.standard = "missing"
	bad.validate()
	check(not bad.errors.is_empty(), "artwork references validated")
	bad = Catalog.new()
	bad.data.weapons.standard.double_mode = "alternating_pairs"
	bad.validate()
	check(not bad.errors.is_empty(), "incompatible firing transformations rejected")
	bad = Catalog.new()
	bad.data.power_ups.double_shot_delay = 0.12
	var tuned: Resource = bad.create("robot", "robot_body", "standard")
	check(is_equal_approx(tuned.weapon.schedule(true).back().time, 0.12), "Double Shot delay comes from config")

func ui_checks() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(game.map_preparation.visible and not game.preparation.visible and game.character_id == "robot", "fresh launch requests a map before character preparation")
	game.map_preparation.confirm_selection()
	check(not game.map_preparation.visible and game.preparation.visible, "map confirmation opens character preparation")
	game.preparation.choose_character("tank")
	check(game.weapon_selector.item_count == 3 and game.sim.player.max_hp == 10, "tank card filters compatible weapons")
	game.preparation.choose_weapon(2)
	check(game.sim.loadout.character_id == "tank" and game.sim.loadout.weapon.id == "missiles", "selection updates simulation and preview")
	game.activate()
	check(not game.preparation.visible and game.sim.status == "playing", "deployment uses selected configuration")
	game.toggle_pause()
	game.select_loadout(0)
	check(game.sim.loadout.weapon.id == "missiles" and not game.preparation.visible, "pause prevents equipment changes")
	game.activate()
	game.sim.status = "lost"
	game.refresh_hud()
	check(game.preparation.visible, "end screen offers selection")
	game.show_map_selection()
	check(game.map_preparation.visible and not game.preparation.visible, "character screen can return to map selection")
	game.map_preparation.confirm_selection()
	game.preparation.choose_character("robot")
	game.preparation.choose_weapon(1)
	game.activate()
	check(game.sim.player.max_hp == 5 and game.sim.loadout.weapon.id == "gatling" and game.sim.pending_shots.is_empty(), "replay changes character and resets burst")
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.character_id == "robot" and game.weapon_id == "standard" and game.sim.status == "ready", "new launch resets choices")
	game.queue_free()
	await process_frame
