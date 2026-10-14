extends SceneTree

const Sim = preload("res://gd/simulation.gd")
const Map = preload("res://gd/battle_map.gd")
const Definition = preload("res://gd/map_definition.gd")
const Marker = preload("res://gd/map_marker.gd")
const Settings = preload("res://gd/pickup_settings.gd")
const Art = preload("res://gd/weapon_pickup_art.gd")
const Catalog = preload("res://gd/character_catalog.gd")
const OBJECT_CATALOG = preload("res://assets/map_objects/catalog.tres")
var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func map_with_object(role: String, map_id: String = "city_prototype") -> PackedScene:
	var map := Definition.new()
	map.map_id = map_id
	map.dimensions = Vector2i(12, 10)
	map.pickup_settings = Settings.new()
	map.pickup_settings.periodic_enabled = false
	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = TileSet.new()
	terrain.tile_set.tile_size = Vector2i(40, 40)
	map.add_child(terrain)
	terrain.owner = map
	for role_data in [["base", Vector2(260, 300)], ["player", Vector2(260, 220)], ["enemy", Vector2(60, 20)]]:
		var marker := Marker.new()
		marker.role = role_data[0]
		marker.position = role_data[1]
		map.add_child(marker)
		marker.owner = map
	var object: Node2D = load("res://scenes/objects/industrial/%s.tscn" % role).instantiate()
	object.position = Vector2(80, 80)
	map.add_child(object)
	object.owner = map
	var scene := PackedScene.new()
	check(scene.pack(map) == OK, "object scene can be authored into a different map: " + role)
	map.free()
	return scene

func test_catalog_and_collision() -> void:
	check(OBJECT_CATALOG.validate().is_empty() and OBJECT_CATALOG.objects.size() >= 7, "all reusable object definitions validate")
	for role in ["machinery", "pipes", "robot_wreck", "drink_can", "single_pipe", "water_pump", "water_pump_right"]:
		var definition: Resource = OBJECT_CATALOG.find("industrial_" + role)
		check(definition != null and definition == load("res://assets/map_objects/industrial/%s.tres" % role), "catalog references the same editable resource used by scenes: " + role)
		var texture: AtlasTexture = definition.texture
		check(texture.atlas.get_image().detect_alpha() != Image.ALPHA_NONE, "generated artwork retains native alpha: " + role)
		check(Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region) and texture.region.has_area(), "sprite region is inside source PNG: " + role)
		check(is_equal_approx(definition.visual_rect.size.aspect(), texture.get_size().aspect()), "artwork preserves aspect ratio: " + role)
		var sim := Sim.new(null, map_with_object(role))
		check(sim.status == "ready" and sim.validation_errors.is_empty(), "industrial object is allowed on a city map: " + role)
		var object: Dictionary = sim.map_objects[0]
		var point: Vector2 = object.pos + Vector2(20, 20)
		var should_block_movement: bool = role != "drink_can"
		var should_block_bullets: bool = role in ["machinery", "robot_wreck", "water_pump", "water_pump_right"]
		check(Map.can_occupy(sim.map, point) != should_block_movement, "movement flag applies independently: " + role)
		check(sim.bullet_collision({"pos": point, "friendly": true, "damage": 1000}) == should_block_bullets, "bullet flag applies independently: " + role)
		for cell in object.footprint_cells:
			sim.damage_wall((Vector2(cell) + Vector2.ONE * 0.5) * 40, true)
		check(object.active and object.hp == 0 and sim.revision == 0, "permanent object cannot be destroyed even by authorized steel damage: " + role)
		check(not Map.find_path(sim.map, Vector2i(1, 0), sim.base_goal).is_empty(), "placing object retains a route to base: " + role)
		check(definition.initial_hp == 0, "runtime damage never modifies shared catalog definition: " + role)
		if role == "drink_can":
			check(object.footprint_cells.is_empty(), "floor litter does not participate in navigation footprint")
		else:
			check(object.footprint_cells.size() == definition.footprint.x * definition.footprint.y, "configured footprint covers every expected cell: " + role)

func test_sample_edges() -> void:
	var sim := Sim.new()
	check(sim.validation_errors.is_empty(), "redesigned sample retains valid map configuration")
	var traversable := 0
	for row in sim.map:
		for tile in row:
			traversable += int(not Map.move_blocked(tile))
	check(sim.map.all(func(row): return row.all(func(tile): return tile.kind != "grass")), "factory scene has no painted foliage")
	check(float(traversable) / (sim.dimensions.x * sim.dimensions.y) >= 0.8, "most of factory floor remains open for gameplay")
	for object in sim.map_objects:
		check(not Rect2(160, 200, 520, 400).has_point(object.pos), "environment objects stay outside central combat area")
	for side in ["West", "East"]:
		var group: Node2D = sim.map_scene.get_node("Environment/" + side + "WaterLine")
		var pump: Node2D = group.get_node("Pump")
		var previous: Node2D = null
		for child in group.get_children():
			if not child.name.begins_with("Pipe"):
				continue
			check(child.definition.category == "fixed" and not child.definition.bullet_blocked and child.definition.move_blocked, "single pipes retain independent movement/bullet flags")
			var cell := Vector2i(child.global_position / 40)
			check(cell.x in [0, sim.dimensions.x - 1], "vertical pipe stays immediately alongside map boundary")
			if previous != null:
				check((previous.global_position + previous.definition.connection_point("end")).is_equal_approx(child.global_position + child.definition.connection_point("start")), "pipe modules connect end to end without gaps")
			previous = child
		check(previous != null and (previous.global_position + previous.definition.connection_point("end")).is_equal_approx(pump.global_position + pump.definition.connection_point("inlet")), "continuous pipe line terminates at pump inlet: " + side)
		check(pump.definition.move_blocked and pump.definition.bullet_blocked and pump.definition.category == "fixed", "water motor remains a permanent solid obstacle")
	var grass := preload("res://godot_tests/terrain_fixture.gd").tile("grass")
	check(grass.kind == "grass" and not Map.move_blocked(grass), "unused grass tile remains available for other maps")
	check(load("res://assets/terrain/industrial/grass.png") != null, "foliage artwork is retained")
	for spawn in sim.enemy_spawns:
		check(not Map.find_path(sim.map, Vector2i(spawn / 40), sim.base_goal).is_empty(), "all sample spawn lanes still reach the base")
	check(Map.can_occupy(sim.map, sim.player_spawn, sim.loadout.collider_radius), "player spawn stays free")

func test_weapon_art() -> void:
	var catalog := Catalog.new()
	var art := Art.new()
	for character_id in catalog.data.characters:
		var character: Dictionary = catalog.data.characters[character_id]
		for weapon_id in character.weapons:
			var texture: AtlasTexture = art.texture_for(weapon_id, character_id, catalog)
			var loadout: Resource = catalog.create(character_id, character.default_body, weapon_id)
			var original: Texture2D = loadout.weapon.layered_art.texture_for("right")
			var visible := original.get_image().get_used_rect()
			check(texture != null and texture.atlas == loadout.weapon.layered_art.atlas, "pickup reuses equipped weapon atlas: %s/%s" % [character_id, weapon_id])
			check(texture.get_image().get_data() == original.get_image().get_region(visible).get_data(), "pickup pixels exactly match the equipped gun: %s/%s" % [character_id, weapon_id])
			check(texture == art.texture_for(weapon_id, character_id, catalog), "pickup artwork is cached per weapon art: %s/%s" % [character_id, weapon_id])
			var rect := art.rect_for(texture, Vector2(100, 100))
			check(rect.size.x <= 36.01 and rect.size.y <= 28.01 and rect.get_center().is_equal_approx(Vector2(100, 100)), "pickup artwork fits its marker without distortion")
	var incompatible := art.texture_for("gatling", "tank", catalog)
	check(incompatible != null and incompatible == art.texture_for("gatling", "robot", catalog), "incompatible weapon still displays its actual supported-character artwork")
	check(art.texture_for("unknown_weapon", "robot", catalog) == null, "unknown IDs cannot produce misleading placeholder artwork")

func _initialize() -> void:
	test_catalog_and_collision()
	test_sample_edges()
	test_weapon_art()
	print("ENVIRONMENT OBJECTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
