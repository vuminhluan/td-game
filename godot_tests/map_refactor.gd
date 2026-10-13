extends SceneTree

const Sim = preload("res://gd/simulation.gd")
const Map = preload("res://gd/battle_map.gd")
const Settings = preload("res://gd/pickup_settings.gd")
const Marker = preload("res://gd/map_marker.gd")
const MapObject = preload("res://gd/map_object.gd")
const Catalog = preload("res://gd/character_catalog.gd")

var checks := 0
var failures := 0
var catalog := Catalog.new()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func fixture(size: Vector2i = Vector2i(12, 10)) -> Node2D:
	var definition: Node2D = load("res://gd/map_definition.gd").new()
	definition.name = "TestMap"
	definition.dimensions = size
	definition.pickup_settings = Settings.new()
	definition.pickup_settings.periodic_enabled = false
	var layer := TileMapLayer.new()
	layer.name = "Terrain"
	layer.tile_set = make_tileset()
	definition.add_child(layer)
	for y in size.y:
		for x in size.x:
			layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)
	add_marker(definition, "Base", "base", Vector2(260, 300))
	add_marker(definition, "Player", "player", Vector2(260, 220))
	add_marker(definition, "EnemyA", "enemy", Vector2(60, 20))
	add_marker(definition, "EnemyB", "enemy", Vector2(420, 20))
	return definition

func make_tileset() -> TileSet:
	var result := TileSet.new()
	result.tile_size = Vector2i(40, 40)
	var fields := {"kind": TYPE_STRING, "move_blocked": TYPE_BOOL, "bullet_blocked": TYPE_BOOL, "destructible": TYPE_BOOL, "hp": TYPE_INT, "steel": TYPE_BOOL}
	for field in fields:
		result.add_custom_data_layer()
		var index := result.get_custom_data_layers_count() - 1
		result.set_custom_data_layer_name(index, field)
		result.set_custom_data_layer_type(index, fields[field])
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(Image.create(160, 40, false, Image.FORMAT_RGBA8))
	source.texture_region_size = Vector2i(40, 40)
	result.add_source(source, 0)
	for x in 4:
		source.create_tile(Vector2i(x, 0))
		var data := source.get_tile_data(Vector2i(x, 0), 0)
		data.set_custom_data("kind", ["floor", "glass", "barrier", "ghost_barrier"][x])
		data.set_custom_data("move_blocked", x in [2, 3])
		data.set_custom_data("bullet_blocked", x in [1, 2])
		data.set_custom_data("destructible", x in [2, 3])
		data.set_custom_data("hp", 2 if x in [2, 3] else 0)
		data.set_custom_data("steel", false)
	return result

func add_marker(definition: Node2D, label: String, role: String, point: Vector2) -> Node2D:
	var marker := Marker.new()
	marker.name = label
	marker.role = role
	marker.position = point
	definition.add_child(marker)
	return marker

func add_object(definition: Node2D, label: String, category: String, point: Vector2) -> Node2D:
	var object := MapObject.new()
	object.name = label
	object.category = category
	if category == "pickup":
		object.pickup_id = "shield"
	object.position = point
	definition.add_child(object)
	return object

func assign_owner(node: Node, definition: Node) -> void:
	for child in node.get_children():
		child.owner = definition
		assign_owner(child, definition)

func packed(definition: Node2D) -> PackedScene:
	assign_owner(definition, definition)
	var result := PackedScene.new()
	check(result.pack(definition) == OK, "authored map fixture packs successfully")
	definition.free()
	return result

func fresh(scene: PackedScene, loadout: Resource = null) -> RefCounted:
	var sim := Sim.new(loadout, scene)
	sim.rng.seed = 20261013
	sim.start()
	sim.to_spawn = 99
	sim.spawn_timer = 999
	return sim

func step(sim: RefCounted, seconds: float) -> void:
	for i in ceili(seconds * 60):
		sim.update(1.0 / 60)

func release(sim: RefCounted) -> void:
	if is_instance_valid(sim.map_scene):
		sim.map_scene.free()

func test_authored_layout() -> void:
	var definition := fixture(Vector2i(15, 11))
	definition.get_node("Base").position = Vector2(340, 380)
	definition.get_node("Player").position = Vector2(340, 260)
	definition.get_node("EnemyB").position = Vector2(540, 20)
	var sim := fresh(packed(definition))
	check(sim.validation_errors.is_empty(), "valid authored map starts without validation errors")
	check(sim.dimensions == Vector2i(15, 11) and sim.world_size == Vector2(600, 440), "scene dimensions determine runtime bounds")
	check(sim.map.size() == 11 and sim.map[0].size() == 15, "scene dimensions determine simulation grid")
	check(sim.base_position == Vector2(340, 380) and sim.player.pos == Vector2(340, 260), "moving authored markers moves base and player")
	check(sim.enemy_spawns == [Vector2(60, 20), Vector2(540, 20)], "runtime spawn positions come from authored markers")
	check(sim.bullet_collision({"pos": Vector2(600, 20), "friendly": true}), "projectiles stop at authored map boundary")
	check(not sim.bullet_collision({"pos": Vector2(580, 20), "friendly": true}), "projectiles can enter expanded map area")
	var hp: int = sim.base_hp
	sim.bullet_collision({"pos": sim.base_position, "friendly": false})
	check(sim.base_hp == hp - 1, "base damage uses authored base position")
	sim.player.hp = 1
	sim.invulnerable = 0
	sim.hit_player()
	check(sim.player.pos == Vector2(340, 260), "respawn uses authored player marker")
	sim.enemies.clear()
	sim.to_spawn = preload("res://gd/rules.gd").WAVE_COUNTS[sim.wave - 1]
	var actual: Array = []
	for i in 4:
		sim.spawn_timer = 0
		sim.update(0.01)
		actual.append(sim.enemies.back().pos)
		sim.enemies.clear()
	check(actual[0].distance_to(sim.enemy_spawns[0]) < 2 and actual[1].distance_to(sim.enemy_spawns[1]) < 2 and actual[2].distance_to(sim.enemy_spawns[0]) < 2 and actual[3].distance_to(sim.enemy_spawns[1]) < 2, "waves distribute spawns round robin across authored markers")
	release(sim)
	definition = fixture()
	definition.get_node("Player").free()
	sim = fresh(packed(definition))
	check(sim.validation_errors.is_empty(), "missing optional player marker remains valid")
	check(Map.can_occupy(sim.map, sim.player.pos) and sim.player.pos.distance_to(sim.base_position) <= 120 and not sim.in_base(sim.player.pos, 33), "player fallback finds nearby playable floor outside base")
	release(sim)
	definition = fixture()
	definition.get_node("Base").position = Vector2(240, 320)
	sim = fresh(packed(definition))
	check(sim.validation_errors.is_empty(), "base placed between tile centers remains a playable authored map")
	sim.player.pos = Vector2(420, 380)
	sim.to_spawn = 0
	sim.enemies.append(sim.make_actor("robot", (Vector2(sim.base_goal) + Vector2.ONE * 0.5) * 40))
	step(sim, 45)
	check(sim.status == "lost" and sim.base_hp == 0, "enemy can destroy base placed between tile centers")
	release(sim)

func test_validation() -> void:
	for required in ["Base", "EnemyA"]:
		var definition := fixture()
		definition.get_node(required).free()
		if required == "EnemyA":
			definition.get_node("EnemyB").free()
		var sim := Sim.new(null, packed(definition))
		check(not sim.validation_errors.is_empty(), "missing mandatory marker rejected: " + required)
		sim.start()
		check(sim.status != "playing", "invalid map cannot start: " + required)
		release(sim)
	var definition := fixture()
	add_marker(definition, "SecondBase", "base", Vector2(340, 300))
	var sim := Sim.new(null, packed(definition))
	check(not sim.validation_errors.is_empty(), "multiple bases rejected")
	release(sim)
	definition = fixture()
	definition.dimensions = Vector2i.ZERO
	sim = Sim.new(null, packed(definition))
	check(not sim.validation_errors.is_empty(), "nonpositive map dimensions rejected")
	release(sim)
	definition = fixture()
	definition.get_node("EnemyA").position = Vector2(-20, 20)
	sim = Sim.new(null, packed(definition))
	check(not sim.validation_errors.is_empty(), "spawn outside map bounds rejected")
	release(sim)
	definition = fixture()
	var invalid := add_object(definition, "Outside", "fixed", Vector2(440, 360))
	invalid.footprint = Vector2i(2, 2)
	sim = Sim.new(null, packed(definition))
	check(not sim.validation_errors.is_empty(), "object footprint extending outside map rejected")
	release(sim)
	definition = fixture()
	add_object(definition, "First", "fixed", Vector2(100, 100))
	add_object(definition, "Second", "destructible", Vector2(100, 100))
	sim = Sim.new(null, packed(definition))
	check(not sim.validation_errors.is_empty(), "overlapping gameplay object footprints rejected")
	release(sim)
	definition = fixture()
	definition.pickup_settings.power_up_limit = 1
	add_object(definition, "PickupA", "pickup", Vector2(20, 100))
	add_object(definition, "PickupB", "pickup", Vector2(100, 100))
	sim = Sim.new(null, packed(definition))
	check(not sim.validation_errors.is_empty(), "authored power ups exceeding shared cap rejected")
	release(sim)
	for property in ["drop_chance", "weapon_chance", "periodic_interval", "lifetime", "power_up_limit"]:
		var settings := Settings.new()
		settings.set(property, -1)
		check(not settings.validate(catalog).is_empty(), "invalid pickup setting rejected: " + property)
	var settings := Settings.new()
	settings.power_up_weights = {"shield": -1}
	check(not settings.validate(catalog).is_empty(), "negative pickup weights rejected")
	settings = Settings.new()
	settings.power_up_pool.assign(["missing_item"])
	check(not settings.validate(catalog).is_empty(), "unknown pool item rejected")
	settings = Settings.new()
	settings.lifetime_overrides = {"shield": 0}
	check(not settings.validate(catalog).is_empty(), "nonpositive per item lifetime rejected")
	definition = fixture()
	definition.pickup_settings = null
	sim = Sim.new(null, packed(definition))
	check(sim.status == "invalid" and not sim.validation_errors.is_empty(), "missing pickup settings reports invalid map without crashing")
	release(sim)
	definition = fixture()
	definition.get_node("Terrain").tile_set.tile_size = Vector2i(32, 32)
	sim = Sim.new(null, packed(definition))
	check(sim.status == "invalid", "terrain using another gameplay tile size rejected")
	release(sim)
	definition = fixture()
	add_object(definition, "BlockedPlayer", "fixed", Vector2(260, 220))
	sim = Sim.new(null, packed(definition))
	check(sim.status == "invalid", "player spawn overlapping gameplay obstacle rejected")
	release(sim)
	definition = fixture()
	add_object(definition, "Wall", "fixed", Vector2(100, 100))
	add_object(definition, "EdgePickup", "pickup", Vector2(79, 100))
	sim = Sim.new(null, packed(definition))
	check(sim.status == "invalid", "pickup whose placement radius overlaps adjacent obstacle rejected")
	release(sim)
	definition = fixture()
	add_object(definition, "BaseCornerPickup", "pickup", Vector2(290, 330))
	sim = Sim.new(null, packed(definition))
	check(sim.status == "invalid", "pickup diagonally overlapping square base exclusion rejected")
	release(sim)
	definition = fixture()
	var huge := add_object(definition, "HugeFootprint", "fixed", Vector2(100, 100))
	huge.footprint = Vector2i(1000000, 1000000)
	sim = Sim.new(null, packed(definition))
	check(sim.status == "invalid" and not sim.validation_errors.is_empty(), "oversized footprint reports invalid map before allocating all cells")
	release(sim)
	for wrong_root in [Node2D.new(), Node.new(), MapObject.new()]:
		var wrong_scene := PackedScene.new()
		check(wrong_scene.pack(wrong_root) == OK, "incorrect map root fixture packs successfully")
		wrong_root.free()
		sim = Sim.new(null, wrong_scene)
		check(sim.status == "invalid" and not sim.validation_errors.is_empty(), "scene without MapDefinition reports invalid map without crashing")
		release(sim)

func test_objects_and_terrain() -> void:
	var definition := fixture()
	var obstacle := add_object(definition, "Machine", "destructible", Vector2(100, 100))
	obstacle.footprint = Vector2i(2, 2)
	obstacle.initial_hp = 2
	obstacle.visual_rect = Rect2(-80, -80, 240, 240)
	obstacle.drop_settings = Settings.new()
	obstacle.drop_settings.drop_enabled = false
	var decor := add_object(definition, "Pipe", "decoration", Vector2(20, 100))
	decor.footprint = Vector2i(8, 8)
	decor.visual_rect = Rect2(-100, -100, 300, 300)
	definition.get_node("Terrain").set_cell(Vector2i(5, 2), 0, Vector2i(1, 0))
	definition.get_node("Terrain").set_cell(Vector2i(6, 2), 0, Vector2i(2, 0))
	var sim := fresh(packed(definition))
	check(sim.validation_errors.is_empty(), "valid multi cell object and free placed decoration accepted")
	for point in [Vector2(100, 100), Vector2(140, 100), Vector2(100, 140), Vector2(140, 140)]:
		check(not Map.can_occupy(sim.map, point), "multi cell footprint blocks movement at " + str(point))
	check(Map.can_occupy(sim.map, Vector2(60, 100)), "large visual rectangle does not expand gameplay footprint")
	check(Map.can_occupy(sim.map, Vector2(20, 100)) and not sim.bullet_collision({"pos": Vector2(20, 100), "friendly": true}), "decoration participates in neither movement nor bullet collision")
	check(not Map.find_path(sim.map, Vector2i(0, 2), Vector2i(1, 2)).is_empty(), "decoration leaves navigation traversable")
	sim.damage_wall(Vector2(100, 100))
	check(not Map.can_occupy(sim.map, Vector2(140, 140)), "first hit leaves whole obstacle intact")
	sim.damage_wall(Vector2(140, 140))
	for point in [Vector2(100, 100), Vector2(140, 100), Vector2(100, 140), Vector2(140, 140)]:
		check(Map.can_occupy(sim.map, point), "shared HP destruction clears all footprint cells at " + str(point))
	check(sim.power_ups.is_empty() and sim.weapon_pickups.is_empty(), "obstacle drop disable override respected")
	check(Map.can_occupy(sim.map, Vector2(220, 100)) and sim.bullet_collision({"pos": Vector2(220, 100), "friendly": true}), "custom glass tile applies independent movement and bullet flags")
	check(not Map.can_occupy(sim.map, Vector2(260, 100)), "custom tile blocks movement through metadata")
	sim.damage_wall(Vector2(260, 100))
	sim.damage_wall(Vector2(260, 100))
	check(Map.can_occupy(sim.map, Vector2(260, 100)), "custom tile HP and destruction come from metadata")
	release(sim)
	definition = fixture()
	definition.pickup_settings.drop_chance = 1
	definition.pickup_settings.weapon_chance = 1
	definition.pickup_settings.weapon_pool.assign(["standard"])
	obstacle = add_object(definition, "RandomCrate", "destructible", Vector2(100, 100))
	obstacle.initial_hp = 1
	sim = fresh(packed(definition))
	sim.damage_wall(Vector2(100, 100))
	check(sim.weapon_pickups.size() == 1 and sim.weapon_pickups[0].kind == "standard" and sim.power_ups.is_empty(), "default destructible object uses map random drop rules")
	release(sim)
	definition = fixture()
	definition.pickup_settings.drop_enabled = false
	obstacle = add_object(definition, "ExplicitCrate", "destructible", Vector2(100, 100))
	obstacle.initial_hp = 1
	obstacle.pickup_category = "weapon"
	obstacle.pickup_id = "gatling"
	obstacle.drop_settings = Settings.new()
	obstacle.drop_settings.drop_chance = 1
	obstacle.drop_settings.lifetime = 6
	sim = fresh(packed(definition), catalog.create("tank", "tank_body", "standard"))
	sim.damage_wall(Vector2(100, 100))
	check(sim.weapon_pickups.size() == 1 and sim.weapon_pickups[0].kind == "gatling" and is_equal_approx(sim.weapon_pickups[0].life, 6), "object override can enable fixed incompatible weapon drop and lifetime")
	release(sim)
	definition = fixture()
	definition.get_node("Terrain").set_cell(Vector2i(2, 2), 0, Vector2i(3, 0))
	sim = fresh(packed(definition))
	var corridor: Array = [[sim.map[2][1], sim.map[2][2], sim.map[2][3]]]
	check(Map.find_path(corridor, Vector2i(0, 0), Vector2i(2, 0)).is_empty(), "pathfinding cannot breach movement barrier that ordinary bullets pass through")
	release(sim)
	definition = fixture()
	definition.pickup_settings.drop_enabled = false
	var glass_data: TileData = definition.get_node("Terrain").tile_set.get_source(0).get_tile_data(Vector2i(1, 0), 0)
	glass_data.set_custom_data("destructible", true)
	glass_data.set_custom_data("hp", 2)
	definition.get_node("Terrain").set_cell(Vector2i(2, 2), 0, Vector2i(1, 0))
	var transparent_object := add_object(definition, "FixedTransparent", "fixed", Vector2(100, 100))
	transparent_object.move_blocked = false
	transparent_object.bullet_blocked = false
	transparent_object.initial_hp = 9
	sim = fresh(packed(definition))
	check(sim.validation_errors.is_empty(), "fixed bullet transparent object over walkable destructible tile accepted")
	sim.bullet_collision({"pos": Vector2(100, 100), "friendly": true})
	check(sim.map[2][2].hp == 1 and sim.map[2][2].object.hp == 9 and sim.map[2][2].object.active, "bullet damages underlying tile while fixed transparent object retains HP")
	sim.bullet_collision({"pos": Vector2(100, 100), "friendly": true})
	check(sim.map[2][2].hp == 0 and sim.map[2][2].object.hp == 9 and sim.map[2][2].object.active, "underlying tile destruction leaves fixed transparent object intact")
	check(not sim.bullet_collision({"pos": Vector2(100, 100), "friendly": true}), "destroyed underlay and transparent object leave projectile path open")
	release(sim)

func test_pickups() -> void:
	var definition := fixture()
	definition.pickup_settings.lifetime_overrides = {"shield": 7.0, "twin": 9.0}
	add_object(definition, "AuthoredShield", "pickup", Vector2(20, 100))
	var weapon := add_object(definition, "AuthoredWeapon", "pickup", Vector2(100, 100))
	weapon.pickup_category = "weapon"
	weapon.pickup_id = "twin"
	var scene := packed(definition)
	var selected := catalog.create("robot", "robot_body", "standard")
	var sim := fresh(scene, selected)
	var independent := fresh(scene, selected)
	sim.pickup_settings.drop_chance = 0.1
	check(is_equal_approx(independent.pickup_settings.drop_chance, 0.4), "simulation settings edits remain isolated from other sessions")
	sim.pickup_settings.drop_chance = 0.4
	release(independent)
	check(sim.power_ups.size() == 1 and is_equal_approx(sim.power_ups[0].life, 7), "authored power up uses per ID lifetime")
	check(sim.weapon_pickups.size() == 1 and is_equal_approx(sim.weapon_pickups[0].life, 9), "authored weapon uses per ID lifetime")
	sim.power_ups.clear()
	sim.weapon_pickups.clear()
	check(sim.place_pickup(Vector2(20, 20), "power_up", "rapid_fire") and is_equal_approx(sim.power_ups[0].life, 20), "all other pickups default to 20 second lifetime")
	sim.power_ups.clear()
	var settings: Resource = sim.pickup_settings
	settings.power_up_limit = 2
	check(sim.place_pickup(Vector2(20, 20), "power_up", "shield") and sim.place_pickup(Vector2(100, 20), "power_up", "shield") and not sim.place_pickup(Vector2(180, 20), "power_up", "shield"), "all power up placement shares configured simultaneous cap")
	check(sim.place_pickup(Vector2(180, 20), "weapon", "twin") and sim.place_pickup(Vector2(220, 20), "weapon", "standard"), "weapon placement remains available at power up cap")
	sim.power_ups.clear()
	sim.weapon_pickups.clear()
	settings.power_up_limit = 10
	settings.drop_chance = 0.4
	settings.weapon_chance = 0.7
	var drops := 0
	var weapons := 0
	for i in 1600:
		sim.power_ups.clear()
		sim.weapon_pickups.clear()
		sim.drop_pickup(Vector2(20, 20))
		drops += sim.power_ups.size() + sim.weapon_pickups.size()
		weapons += sim.weapon_pickups.size()
	check(drops > 560 and drops < 720, "seeded sample reflects 40 percent obstacle drop probability")
	check(weapons > drops * 0.64 and weapons < drops * 0.76, "seeded sample reflects 70 percent weapon category probability")
	sim.power_ups.clear()
	sim.weapon_pickups.clear()
	settings.drop_chance = 1
	settings.weapon_chance = 1
	settings.weapon_pool.assign(["gatling", "standard"])
	release(sim)
	sim = fresh(scene, catalog.create("tank", "tank_body", "standard"))
	sim.pickup_settings.drop_chance = 1
	sim.pickup_settings.weapon_chance = 1
	sim.pickup_settings.weapon_pool.assign(["gatling", "standard"])
	sim.power_ups.clear()
	sim.weapon_pickups.clear()
	var compatible_only := true
	for i in 100:
		sim.weapon_pickups.clear()
		sim.drop_pickup(Vector2(20, 20))
		compatible_only = compatible_only and sim.weapon_pickups.size() == 1 and sim.weapon_pickups[0].kind == "standard"
	check(compatible_only, "random weapon drops filter pool against active character compatibility")
	sim.weapon_pickups.clear()
	sim.drop_pickup(Vector2(20, 20), null, "weapon", "gatling")
	check(sim.weapon_pickups.size() == 1 and sim.weapon_pickups[0].kind == "gatling", "explicit incompatible weapon remains on map")
	sim.player.pos = Vector2(20, 20)
	sim.collect_power_ups()
	check(sim.weapon_pickups.size() == 1 and sim.loadout.weapon.id == "standard", "incompatible character cannot collect explicit weapon")
	release(sim)
	sim = fresh(scene, selected)
	sim.player.pos = Vector2(100, 100)
	sim.pending_shots.append({"actor": sim.player.duplicate(), "delay": 0.2, "barrels": [0]})
	sim.collect_power_ups()
	check(sim.weapon_pickups.is_empty() and sim.loadout.weapon.id == "twin", "compatible authored weapon immediately replaces active weapon")
	check(sim.pending_shots.is_empty(), "weapon replacement clears volley scheduled by previous weapon")
	check(selected.weapon.id == "standard", "weapon replacement does not mutate pregame loadout")
	sim.player.hp = 1
	sim.invulnerable = 0
	sim.hit_player()
	check(sim.loadout.weapon.id == "twin", "acquired weapon survives player respawn")
	release(sim)
	sim = fresh(scene, selected)
	check(sim.loadout.weapon.id == "standard", "new session restores selected pregame weapon")
	release(sim)

func test_periodic_settings() -> void:
	var definition := fixture()
	definition.pickup_settings.periodic_enabled = true
	definition.pickup_settings.periodic_interval = 0.5
	definition.pickup_settings.periodic_min = 3
	definition.pickup_settings.periodic_max = 3
	definition.pickup_settings.power_up_limit = 4
	definition.pickup_settings.power_up_pool.assign(["shield"])
	var sim := fresh(packed(definition))
	step(sim, 0.4)
	check(sim.power_ups.is_empty(), "configured periodic interval delays spawn")
	step(sim, 0.15)
	check(sim.power_ups.size() == 3 and sim.power_ups.all(func(item): return item.kind == "shield"), "periodic count and configured pool determine spawned items")
	check(sim.weapon_pickups.is_empty(), "periodic spawning produces power ups only")
	step(sim, 0.5)
	check(sim.power_ups.size() == 4, "periodic spawn clamps to shared cap")
	sim.power_ups.pop_back()
	step(sim, 0.5)
	check(sim.power_ups.size() == 4, "next periodic attempt fills space freed under shared cap")
	sim.pickup_settings.periodic_enabled = false
	sim.power_ups.clear()
	step(sim, 1)
	check(sim.power_ups.is_empty(), "disabled periodic generation stops new pickups")
	sim.pickup_settings.power_up_pool.assign(["shield", "rapid_fire"])
	sim.pickup_settings.power_up_weights = {"shield": 1, "rapid_fire": 3}
	var shield_count := 0
	for i in 4000:
		shield_count += int(sim.choose_power_up() == "shield")
	check(shield_count > 900 and shield_count < 1100, "configured weights apply to random pool selection")
	sim.pickup_settings.power_up_weights.clear()
	shield_count = 0
	for i in 4000:
		shield_count += int(sim.choose_power_up() == "shield")
	check(shield_count > 1850 and shield_count < 2150, "unspecified weights choose configured pool uniformly")
	sim.place_pickup(Vector2(20, 20), "power_up", "shield")
	sim.place_pickup(Vector2(100, 20), "weapon", "standard")
	sim.power_ups[0].life = 0.01
	sim.weapon_pickups[0].life = 0.01
	sim.pause()
	step(sim, 1)
	check(sim.power_ups.size() == 1 and sim.weapon_pickups.size() == 1, "pause freezes lifetime of both pickup categories")
	sim.pause()
	step(sim, 0.05)
	check(sim.power_ups.is_empty() and sim.weapon_pickups.is_empty(), "both uncollected pickup categories expire")
	release(sim)

func _initialize() -> void:
	test_authored_layout()
	test_validation()
	test_objects_and_terrain()
	test_pickups()
	test_periodic_settings()
	print("MAP REFACTOR: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
