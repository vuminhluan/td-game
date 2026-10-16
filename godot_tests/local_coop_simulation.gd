extends SceneTree

const Sim = preload("res://gd/simulation.gd")
const Terrain = preload("res://godot_tests/terrain_fixture.gd")
const R = preload("res://gd/rules.gd")
const STANDARD = preload("res://assets/loadouts/standard.tres")
const TWIN = preload("res://assets/loadouts/twin.tres")

var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func fresh() -> RefCounted:
	var sim := Sim.new(STANDARD, null, [STANDARD, TWIN])
	check(sim.status == "ready", "both players deploy on the default map with fallback P2 spawn")
	for row in sim.map:
		for tile in row:
			Terrain.apply(tile, "floor")
	sim.players[0].actor.pos = Vector2(300, 300)
	sim.players[1].actor.pos = Vector2(420, 300)
	sim.pickup_settings.periodic_enabled = false
	sim.start()
	sim.spawn_timer = 999
	return sim

func tick(sim: RefCounted, seconds: float, commands: Array = []) -> void:
	for frame in ceili(seconds * 60):
		sim.update_players(1.0 / 60.0, commands)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	spawn_and_movement()
	weapons_and_pickups()
	damage_and_respawn()
	enemy_targeting()
	print("LOCAL COOP SIMULATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func spawn_and_movement() -> void:
	var sim := Sim.new(STANDARD, null, [STANDARD, TWIN])
	check(sim.players.size() == 2 and sim.player == sim.players[0].actor and sim.loadout == STANDARD, "single player properties alias P1 state")
	check(sim.can_place_player(sim.players[1].actor.pos, 1), "fallback P2 spawn respects map, base and P1 collider")
	check(sim.players[0].label_remaining == 10 and sim.players[1].label_remaining == 10, "deployment labels last ten seconds per player")
	var oversized: Resource = TWIN.duplicate()
	oversized.collider_radius = 2000
	var invalid := Sim.new(STANDARD, null, [STANDARD, oversized])
	check(invalid.status == "invalid" and invalid.message.contains("P2 spawn"), "unplaceable P2 blocks deployment with a player-specific map error")
	sim = fresh()
	var p1: Dictionary = sim.players[0].actor
	var p2: Dictionary = sim.players[1].actor
	sim.update_players(0.04, [{"direction": "left"}, {"direction": "right"}])
	check(p1.pos.x < 300 and p2.pos.x > 420, "independent commands move both players")
	p1.pos = Vector2(300, 300)
	p2.pos = Vector2(328, 300)
	sim.update_players(0.04, [{"direction": "right"}, {}])
	check(p1.pos == Vector2(300, 300) and p2.pos == Vector2(328, 300), "teammate collider blocks movement without pushing")
	var snapshot := var_to_bytes([sim.players, sim.elapsed])
	sim.pause()
	sim.update_players(0.05, [{"direction": "left", "shooting": true}, {"direction": "right", "shooting": true}])
	check(snapshot == var_to_bytes([sim.players, sim.elapsed]), "pause freezes both players and label clocks")
	sim.pause()
	tick(sim, 0.1)
	check(sim.players[0].label_remaining < 10 and sim.players[1].label_remaining < 10, "labels count down in simulation time")
	for row in sim.map:
		for tile in row:
			Terrain.apply(tile, "steel")
	check(sim.find_player_spawn(sim.players[1].spawn_position, 1) == Vector2.INF, "no available spawn reports failure instead of overlapping actors")

func weapons_and_pickups() -> void:
	var sim := fresh()
	for state in sim.players:
		state.actor.cooldown = 0
	sim.activate_power_up("double_shot", 1)
	sim.update_players(0.01, [{"shooting": true}, {"shooting": true}])
	check(sim.shots_fired == 3 and sim.players[0].pending_shots.is_empty() and sim.players[1].pending_shots.size() == 1, "barrel count and delayed volley use each owner's weapon and powers")
	check(sim.bullets[0].owner_id == 1 and sim.bullets[1].owner_id == 2 and sim.bullets[2].owner_id == 2, "projectiles retain stable player ownership")
	check(sim.players[0].actor.cooldown != sim.players[1].actor.cooldown, "weapon cooldowns are independent")
	tick(sim, 0.1)
	check(sim.shots_fired == 5 and sim.players[1].pending_shots.is_empty(), "P2 delayed volley fires both P2 barrels")
	sim.power_ups.append({"pos": sim.players[1].actor.pos, "kind": "shield", "life": 10.0})
	sim.power_ups.append({"pos": sim.players[1].actor.pos, "kind": "base_shield", "life": 10.0})
	sim.weapon_pickups.append({"pos": sim.players[1].actor.pos, "kind": "standard", "life": 10.0})
	sim.collect_power_ups()
	check(not sim.power_up_active("shield", 0) and sim.power_up_active("shield", 1), "personal shield belongs only to its collector")
	check(sim.players[1].loadout.weapon.id == "standard" and sim.players[0].loadout == STANDARD, "weapon pickup changes only collector loadout")
	check(sim.power_up_active("base_shield") and sim.power_up_active("base_shield", 1), "P2 base shield protects shared base")
	var base_hp: int = sim.base_hp
	sim.bullet_collision({"pos": sim.base_position, "friendly": false})
	check(sim.base_hp == base_hp, "shared base absorbs hits from shield collected by P2")
	var timer: float = sim.players[1].active_power_ups.shield
	sim.update_players(0.04, [])
	check(sim.players[1].active_power_ups.shield < timer, "personal timers tick independently")
	sim.players[0].actor.pos = Vector2(60, 20)
	sim.players[1].actor.pos = Vector2(700, 20)
	check(not sim.valid_power_up_cell(Vector2(700, 20)), "P2 blocks periodic item placement")

func damage_and_respawn() -> void:
	var sim := fresh()
	var p1: Dictionary = sim.players[0].actor
	var p2: Dictionary = sim.players[1].actor
	check(not sim.friendly_fire, "friendly fire defaults to disabled")
	check(not sim.bullet_collision({"pos": p2.pos, "friendly": true, "owner_id": 1}), "friendly fire disabled lets projectile pass through teammate")
	check(p2.hp == p2.max_hp, "disabled friendly fire causes no damage")
	sim.friendly_fire = true
	check(not sim.bullet_collision({"pos": p1.pos, "friendly": true, "owner_id": 1}), "projectile never hits its owner")
	check(sim.bullet_collision({"pos": p2.pos, "friendly": true, "owner_id": 1, "damage": 2}), "enabled friendly fire consumes projectile on teammate")
	check(p2.hp == p2.max_hp - 2 and p1.hp == p1.max_hp, "friendly fire applies weapon damage only to teammate")
	sim.hit_player(0)
	check(p1.hp == p1.max_hp - 1, "P2 invulnerability cannot protect P1")
	var p2_hp: int = p2.hp
	sim.hit_player(1)
	check(p2.hp == p2_hp, "P2 damage grants only P2 invulnerability")
	sim.activate_power_up("speed_boost", 1)
	var remaining: float = sim.players[1].active_power_ups.speed_boost
	var old_id: int = p2.id
	p1.pos = sim.players[1].spawn_position
	p2.hp = 1
	sim.players[1].invulnerable = 0
	sim.hit_player(1)
	p2 = sim.players[1].actor
	check(sim.players[1].lives == 2 and p2.hp == TWIN.max_hp and p2.id != old_id and p2.player_id == 2, "respawn replaces only P2 actor and retains stable owner")
	check(sim.players[1].loadout == TWIN and sim.players[1].active_power_ups.speed_boost == remaining, "respawn retains selected loadout and remaining buffs")
	check(p2.pos != p1.pos and sim.can_place_player(p2.pos, 1), "occupied respawn relocates to safe nearby space")
	check(sim.players[1].invulnerable == 3 and sim.players[1].label_remaining == 3, "respawn restores existing protection and three second label")
	sim.players[1].lives = 1
	sim.players[1].actor.hp = 1
	sim.players[1].invulnerable = 0
	sim.hit_player(1)
	check(sim.status == "playing" and sim.players[1].lives == 0 and sim.living_players().size() == 1, "P2 elimination allows P1 to continue")
	var old_position: Vector2 = sim.players[1].actor.pos
	tick(sim, 0.1, [{}, {"direction": "right", "shooting": true}])
	check(sim.players[1].actor.pos == old_position and sim.players[1].actor.hp <= 0, "eliminated players cannot move or fire")
	check(sim.players[1].active_power_ups.speed_boost < remaining, "buff clocks continue after owner elimination")
	sim.power_ups.append({"pos": old_position, "kind": "shield", "life": 10.0})
	sim.collect_power_ups()
	check(not sim.power_up_active("shield", 1) and not sim.power_ups.is_empty(), "eliminated actor cannot collect or consume pickups")
	sim.players[0].lives = 1
	sim.players[0].actor.hp = 1
	sim.players[0].invulnerable = 0
	sim.hit_player(0)
	check(sim.status == "lost", "team loses when every player is eliminated")
	sim = fresh()
	sim.base_hp = 1
	sim.bullet_collision({"pos": sim.base_position, "friendly": false})
	check(sim.status == "lost" and sim.players[0].lives == R.LIVES and sim.players[1].lives == R.LIVES, "base destruction loses shared campaign immediately")
	sim = fresh()
	sim.players[1].lives = 0
	sim.players[1].actor.hp = 0
	sim.to_spawn = 0
	sim.wave = R.WAVE_COUNTS.size()
	sim.update_players(0.01, [])
	check(sim.status == "won", "surviving teammate can finish shared campaign")

func enemy_targeting() -> void:
	var sim := fresh()
	var enemy: Dictionary = sim.make_actor("robot", Vector2(300, 200))
	enemy.cooldown = 0
	sim.players[0].actor.pos = Vector2(300, 360)
	sim.players[1].actor.pos = Vector2(400, 200)
	sim.move_enemy(enemy, 0.01)
	check(enemy.dir == "right" and sim.bullets.back().owner_id == 0, "enemy chooses nearest eligible player across both axes")
	enemy.cooldown = 0
	enemy.shot_clock = 0
	sim.players[1].actor.hp = 0
	sim.players[1].lives = 0
	sim.move_enemy(enemy, 0.01)
	check(enemy.dir == "down", "eliminated nearest player is excluded from enemy targets")
	enemy.cooldown = 0
	enemy.shot_clock = 0
	sim.players[0].actor.pos = Vector2(320, 220)
	sim.move_enemy(enemy, 0.01)
	check(enemy.has("target") and enemy.target == Vector2(300, 220), "players outside aiming constraints do not redirect base path")
	enemy.pos = sim.base_position + Vector2(0, -60)
	enemy.shot_clock = 0
	enemy.cooldown = 0
	sim.players[0].actor.pos = enemy.pos + Vector2(40, 0)
	sim.move_enemy(enemy, 0.01)
	check(enemy.dir == "down", "nearby base attack keeps priority over aligned player")
