extends SceneTree
const Terrain = preload("res://godot_tests/terrain_fixture.gd")
const Sim = preload("res://gd/simulation.gd")
const R = preload("res://gd/rules.gd")
const Settings = preload("res://gd/pickup_settings.gd")
const Map = preload("res://gd/battle_map.gd")
var checks = 0
var failures = 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func fresh() -> RefCounted:
	var sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
	sim.rng.seed = 20261011
	sim.start()
	sim.to_spawn = 99
	sim.spawn_timer = 999
	return sim

func step(sim: RefCounted, seconds: float) -> void:
	for i in ceili(seconds * 60):
		sim.update(1.0 / 60)

func _initialize() -> void:
	var sim = fresh()
	for kind in Settings.POWER_UP_IDS:
		sim.power_ups.append({"kind": kind, "pos": sim.player.pos, "life": 10.0})
	sim.update(0.01)
	check(sim.power_ups.is_empty() and sim.active_power_ups.size() == 5, "player collects all distinct effects")
	step(sim, 1)
	var remaining: float = sim.active_power_ups.shield
	sim.activate_power_up("shield")
	check(sim.active_power_ups.shield == 5 and sim.active_power_ups.double_shot < 5, "same type refreshes without extending other effects")
	var snapshot = var_to_bytes([sim.active_power_ups, sim.power_ups, sim.power_up_timer, sim.pending_shots])
	sim.pause()
	step(sim, 20)
	check(snapshot == var_to_bytes([sim.active_power_ups, sim.power_ups, sim.power_up_timer, sim.pending_shots]), "pause freezes power-up clocks and delayed shots")
	sim.pause()
	for i in 20:
		sim.invulnerable = 0
		sim.hit_player()
		sim.bullet_collision({"pos": sim.base_position, "friendly": false})
	check(sim.player.hp == 5 and sim.base_hp == 20, "both shields absorb unlimited hits")
	check(is_equal_approx(sim.player_shot_cooldown(), 0.2), "rapid fire halves tuned base cooldown")
	var origin: Vector2 = sim.player.pos
	sim.update(0.04, "right")
	check(is_equal_approx(sim.player.pos.x - origin.x, 9.0), "speed boost moves at 225 units per second")
	step(sim, 5.1)
	check(sim.active_power_ups.is_empty() and is_equal_approx(sim.player_shot_cooldown(), 0.4), "expiry restores baseline")
	sim.invulnerable = 0
	sim.hit_player()
	sim.bullet_collision({"pos": sim.base_position, "friendly": false})
	check(sim.player.hp == 4 and sim.base_hp == 19, "shield expiry restores damage to player and base")
	origin = sim.player.pos
	sim.update(0.04, "right")
	check(is_equal_approx(sim.player.pos.x - origin.x, 6.0), "speed restores after expiry")
	sim = fresh()
	sim.activate_power_up("speed_boost")
	sim.activate_power_up("base_shield")
	step(sim, 1)
	remaining = sim.active_power_ups.speed_boost
	sim.player.hp = 1
	sim.hit_player()
	check(sim.lives == 2 and sim.active_power_ups.speed_boost == remaining and sim.power_up_active("base_shield"), "effects survive respawn with remaining duration")
	sim = fresh()
	sim.player.cooldown = 0
	sim.activate_power_up("double_shot")
	sim.fire(sim.player)
	check(sim.bullets.size() == 1 and sim.pending_shots.size() == 1 and is_equal_approx(sim.player.cooldown, 0.48), "double shot rest starts after final bullet")
	sim.pause()
	step(sim, 1)
	check(sim.pending_shots.size() == 1, "pending second bullet pauses")
	sim.pause()
	sim.player.dir = "right"
	step(sim, 0.09)
	check(sim.bullets.size() == 2 and sim.bullets[1].dir == "up", "second bullet preserves trigger direction after turning")
	check(sim.bullets[0].pos.distance_to(sim.bullets[1].pos) > 25, "bullets have visible separation")
	sim = fresh()
	sim.player.cooldown = 0
	sim.activate_power_up("rapid_fire")
	sim.activate_power_up("double_shot")
	for i in 61:
		sim.update(1.0 / 60, "", true)
	check(sim.shots_fired >= 8 and sim.shots_fired <= 10, "rapid fire and double shot compose at doubled trigger rate")
	sim = fresh()
	sim.player.pos = Vector2(180, 105)
	sim.player.cooldown = 0
	sim.player_muzzle_distances = {"up": 65.0}
	sim.activate_power_up("double_shot")
	sim.fire(sim.player)
	step(sim, 0.09)
	check(sim.map[1][4].hp == 1 and sim.bullets.is_empty(), "both bullets independently hit wall along long muzzle")
	sim = fresh()
	sim.player.pos = Vector2(420, 500)
	sim.player.cooldown = 0
	sim.activate_power_up("double_shot")
	sim.enemies.append(sim.make_actor("robot", Vector2(420, 450)))
	sim.fire(sim.player)
	step(sim, 0.25)
	check(sim.kills == 1 and sim.score == 100, "two bullets independently damage and kill enemy")
	sim = fresh()
	sim.power_ups.append({"kind": "shield", "pos": Vector2(60, 20), "life": 10.0})
	sim.enemies.append(sim.make_actor("robot", Vector2(60, 20)))
	sim.update(0.01)
	check(sim.power_ups.is_empty() and sim.active_power_ups.is_empty(), "enemy consumes item without effect")
	sim = fresh()
	sim.power_ups.append({"kind": "shield", "pos": Vector2(60, 20), "life": 0.02})
	sim.update(0.03)
	check(sim.power_ups.is_empty(), "uncollected item expires")
	sim = fresh()
	step(sim, 4.9)
	check(sim.power_ups.is_empty(), "no periodic spawn before interval")
	step(sim, 0.2)
	check(sim.power_ups.size() in [1, 2], "interval spawns one or two items")
	for item in sim.power_ups:
		check(item.pos.distance_to(sim.player.pos) >= R.POWER_UP_SAFE_DISTANCE and item.pos in sim.reachable_power_up_cells(), "random spawn is safe and reachable")
	for i in 30:
		sim.spawn_power_ups()
	check(sim.power_ups.size() == 10, "spawns respect map cap")
	check(not sim.place_power_up(Vector2(100, 20)), "wall drop placement also respects cap")
	sim.power_ups.clear()
	check(not sim.place_power_up(sim.tile_center(sim.player.pos)) and not sim.place_power_up(sim.base_position), "actors and base block item placement")
	check(not sim.place_power_up(Vector2(180, 60)) and not sim.place_power_up(Vector2(140, 180)), "walls and water block items")
	check(sim.place_power_up(Vector2(100, 20)) and not sim.place_power_up(Vector2(100, 20)), "items cannot overlap")
	sim.map[0][1] = Terrain.tile("steel", 5)
	sim.map[0][3] = Terrain.tile("steel", 5)
	sim.map[1][2] = Terrain.tile("steel", 5)
	sim.power_ups.clear()
	check(not sim.place_power_up(Vector2(100, 20)), "isolated floor rejected")
	for row in sim.map:
		for tile in row:
			Terrain.apply(tile, "steel")
	sim.spawn_power_ups()
	check(sim.power_ups.is_empty(), "no valid cells skips spawn safely")
	sim = fresh()
	var steel = Vector2(180, 140)
	check(Map.tile_at(sim.map, steel).hp == R.STEEL_HP, "steel has destruction HP")
	sim.bullet_collision({"pos": steel, "friendly": true})
	check(Map.tile_at(sim.map, steel).hp == R.STEEL_HP, "normal bullets do not damage steel")
	for i in R.STEEL_HP:
		sim.damage_wall(steel, true)
	check(Map.tile_at(sim.map, steel).kind == "floor" and sim.revision == R.STEEL_HP, "authorized damage destroys steel and refreshes terrain")
	var drops = {"brick": 0, "steel": 0}
	for kind in drops:
		for i in 200:
			sim = fresh()
			sim.rng.seed = i + 1
			sim.map[0][2] = Terrain.tile(kind, 1)
			sim.damage_wall(Vector2(100, 20), true)
			drops[kind] += sim.power_ups.size() + sim.weapon_pickups.size()
	check(drops.brick > 50 and drops.brick < 110 and drops.brick == drops.steel, "brick and steel share drop chance and placement")
	var counts = {}
	sim = fresh()
	for kind in Settings.POWER_UP_IDS:
		counts[kind] = 0
	for i in 10000:
		counts[sim.choose_power_up()] += 1
	for kind in counts:
		check(absf(counts[kind] / 10000.0 - 1.0 / Settings.POWER_UP_IDS.size()) < 0.02, "weighted type selection: " + kind)
	check(Sim.new(preload("res://assets/loadouts/standard.tres")).active_power_ups.is_empty() and Sim.new(preload("res://assets/loadouts/standard.tres")).power_ups.is_empty(), "new game clears power-ups")
	print("POWER UPS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
