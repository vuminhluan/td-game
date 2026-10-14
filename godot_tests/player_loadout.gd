extends SceneTree
const Terrain = preload("res://godot_tests/terrain_fixture.gd")
const Sim = preload("res://gd/simulation.gd")
const R = preload("res://gd/rules.gd")
const LOADOUTS = [preload("res://assets/loadouts/standard.tres"), preload("res://assets/loadouts/twin.tres")]
var checks = 0
var failures = 0

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
	sim.spawn_timer = 999
	return sim

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for configuration in LOADOUTS:
		var weapon: Resource = configuration.weapon
		var count: int = weapon.barrel_offsets.size()
		for direction in R.VECTOR:
			var sim = fresh(configuration)
			sim.player.dir = direction
			var muzzles: Array = configuration.muzzle_vectors(direction)
			sim.fire(sim.player)
			check(sim.bullets.size() == count and sim.shots_fired == count, "one projectile per barrel: " + direction)
			for index in count:
				check(sim.bullets[index].pos.is_equal_approx(sim.player.pos + muzzles[index]), "projectile matches its socket and muzzle")
				check(sim.effects[index].pos == sim.bullets[index].pos, "each flash matches its projectile")
			check(is_equal_approx(sim.player.cooldown, weapon.cooldown), "weapon owns cooldown")
			sim.fire(sim.player)
			check(sim.bullets.size() == count, "cooldown blocks repeated trigger")
			var skin: Resource = configuration.body
			for state in ["idle", "walk", "attack"]:
				sim.player.moving = state == "walk"
				sim.player.shot_clock = sim.player.shot_duration if state == "attack" else 0
				var animation: String = skin.animation_name_for(sim.player)
				var source: SpriteFrames = skin.frames_for(direction)
				for index in source.get_frame_count(animation):
					check(weapon.frame_for(direction, animation, index) != null, "weapon has synchronized direction and animation frame")
					check(Rect2(Vector2.ZERO, Vector2(128, 128)).encloses(weapon.cutout_for(direction, animation, index)), "cutout stays inside atlas frame")
				check(skin.rotation_for(direction) == 0, "whole sprite never rotates")
			for kind in ["brick", "steel"]:
				sim = fresh(configuration)
				sim.player.dir = direction
				sim.player.pos += R.VECTOR[direction] * 3
				var cell = Vector2i(Vector2(420, 380) / R.TILE) + Vector2i(R.VECTOR[direction])
				sim.map[cell.y][cell.x] = Terrain.tile(kind, 5)
				sim.fire(sim.player)
				for frame in 12:
					sim.update(0.01)
				check(sim.bullets.is_empty(), "both barrels stop at close " + kind)
				check(sim.map[cell.y][cell.x].hp == (5 - count if kind == "brick" else 5), "each barrel damages brick once and cannot damage steel")
			sim = fresh(configuration)
			sim.player.dir = direction
			var enemy = sim.make_actor("tank", sim.player.pos + R.VECTOR[direction] * 30)
			sim.enemies.append(enemy)
			sim.fire(sim.player)
			for frame in 3:
				sim.update(0.01)
			check(enemy.hp == 4 - count and sim.bullets.is_empty(), "close enemy receives each barrel without bypass")
			sim = fresh(configuration)
			sim.update(0.02, direction, true)
			check(sim.player.moving and skin.animation_for(sim.player) == "walk" and sim.shots_fired == count, "moving fire keeps walking and all barrels")
			sim.player.cooldown = 0
			sim.update(0.01, "", true)
			check(skin.animation_for(sim.player) == "attack", "stationary trigger plays attack")
		var sim = fresh(configuration)
		sim.activate_power_up("rapid_fire")
		check(is_equal_approx(sim.player_shot_cooldown(), weapon.cooldown / 2), "rapid fire scales selected weapon")
		sim.activate_power_up("double_shot")
		sim.fire(sim.player)
		check(sim.pending_shots.size() == 1 and sim.shots_fired == count, "double shot queues one complete volley")
		sim.pause()
		var snapshot = var_to_bytes([sim.player, sim.pending_shots, sim.bullets, sim.elapsed])
		for frame in 10:
			sim.update(0.05, "right", true)
		check(snapshot == var_to_bytes([sim.player, sim.pending_shots, sim.bullets, sim.elapsed]), "pause freezes selected weapon and pending volley")
		sim.pause()
		for frame in 10:
			sim.update(0.01)
		check(sim.shots_fired == count * 2 and sim.pending_shots.is_empty(), "double shot repeats every barrel")
		sim.player.hp = 1
		sim.hit_player()
		check(sim.loadout == configuration and sim.player.hp == R.PLAYER_HP and sim.player.shot_clock == 0, "respawn retains weapon and resets animation")
	data_checks()
	await independent_barrels()
	await ui_checks()
	print("PLAYER LOADOUT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func data_checks() -> void:
	var configuration: Resource = LOADOUTS[0].duplicate()
	configuration.weapon = configuration.weapon.duplicate()
	configuration.weapon.damage = 3
	configuration.weapon.bullet_speed = 200.0
	configuration.weapon.cooldown = 0.8
	configuration.weapon.muzzle_offsets = configuration.weapon.muzzle_offsets.duplicate()
	configuration.weapon.muzzle_offsets.up = Vector2(0, -24.5)
	var sim = fresh(configuration)
	sim.fire(sim.player)
	check(sim.player.cooldown == 0.8 and sim.bullets[0].damage == 3, "custom weapon supplies damage and cooldown")
	var point: Vector2 = sim.bullets[0].pos
	check(is_equal_approx(sim.player.pos.y - point.y, 33.0), "custom weapon muzzle geometry is used without a view")
	sim.update(0.05)
	check(is_equal_approx(point.y - sim.bullets[0].pos.y, 10.0), "custom projectile speed controls travel and collision substeps")
	var target = sim.make_actor("tank", sim.bullets[0].pos)
	sim.enemies.append(target)
	sim.bullet_collision(sim.bullets[0])
	check(target.hp == 1, "collision applies weapon damage")
	sim = fresh(LOADOUTS[1])
	sim.activate_power_up("double_shot")
	sim.fire(sim.player)
	sim.player.hp = 1
	sim.hit_player()
	check(sim.pending_shots.is_empty() and sim.loadout == LOADOUTS[1], "respawn cancels old actor volley while retaining loadout")
	var regions = preload("res://gd/sprite_regions.gd").subtract([Rect2(0, 0, 128, 128)], [Rect2(58, 32, 12, 61), Rect2(47, 70, 34, 24)])
	var area = 0.0
	for region in regions:
		area += region.get_area()
		check(not region.intersection(Rect2(58, 32, 12, 61)).has_area() and not region.intersection(Rect2(47, 70, 34, 24)).has_area(), "body regions exclude original gun and flash")
	check(is_equal_approx(area, 128 * 128 - 12 * 61 - 34 * 24 + 12 * 23), "body split retains every pixel outside the union of cuts")

func independent_barrels() -> void:
	for direction in R.VECTOR:
		var sim = fresh(LOADOUTS[1])
		var vector: Vector2 = R.VECTOR[direction]
		var lateral = Vector2(-vector.y, vector.x)
		sim.player.dir = direction
		sim.player.pos = Vector2(400, 400) - lateral
		var first: Vector2 = sim.player.pos + sim.loadout.muzzle_vectors(direction)[0]
		var second: Vector2 = sim.player.pos + sim.loadout.muzzle_vectors(direction)[1]
		var wall_cell = Vector2i(first / R.TILE)
		check(wall_cell != Vector2i(second / R.TILE), "test places barrels on separate sides of tile seam")
		sim.map[wall_cell.y][wall_cell.x] = Terrain.tile("steel", 5)
		sim.fire(sim.player)
		check(sim.bullets.size() == 1 and sim.bullets[0].pos == second, "one blocked barrel cannot suppress or teleport the other")

func ui_checks() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.map_preparation.confirm_selection()
	check(game.weapon_selector.visible, "ready screen offers weapon selection")
	game.weapon_selector.select(2)
	game.weapon_selector.item_selected.emit(2)
	check(game.sim.loadout.weapon.id == "twin" and game.battle.player_skin == game.sim.loadout.body, "UI binds selected loadout before battle")
	game.activate()
	check(not game.weapon_selector.visible and game.sim.loadout.weapon.id == "twin", "deployment locks selected weapon")
	game.toggle_pause()
	game.select_loadout(0)
	check(game.selected_loadout == 2 and game.sim.loadout.weapon.id == "twin" and not game.weapon_selector.visible, "pause cannot change weapon")
	game.activate()
	check(game.sim.status == "playing" and game.sim.loadout.weapon.id == "twin", "resume keeps weapon")
	game.sim.status = "lost"
	game.refresh_hud()
	check(game.weapon_selector.visible, "end screen allows changing replay weapon")
	game.activate()
	check(game.sim.loadout.weapon.id == "twin" and game.sim.shots_fired == 0, "replay retains choice and resets combat")
	game.sim.status = "won"
	game.refresh_hud()
	game.weapon_selector.select(0)
	game.weapon_selector.item_selected.emit(0)
	game.activate()
	check(game.sim.loadout.weapon.id == "standard", "replay applies new weapon choice")
	game.queue_free()
	await process_frame
