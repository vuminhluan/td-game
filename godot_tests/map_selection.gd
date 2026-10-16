extends SceneTree

const Main = preload("res://gd/main.gd")
const Map = preload("res://gd/battle_map.gd")
const Sim = preload("res://gd/simulation.gd")
const CITY = preload("res://scenes/maps/abandoned_city.tscn")
const INDUSTRIAL = preload("res://scenes/maps/industrial_yard.tscn")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var simulation := Sim.new(null, CITY)
	check(simulation.status == "ready" and simulation.validation_errors.is_empty(), "abandoned city is a valid authored defense map")
	check(simulation.dimensions == Vector2i(21, 19) and simulation.map_scene.map_id == "abandoned_city_day", "city scene owns independent map dimensions and identity")
	check(simulation.map_objects.size() <= 24, "city scenery remains sparse enough for movement")
	check(simulation.enemy_spawns.size() == 3, "city preserves three defense entry routes")
	for spawn in simulation.enemy_spawns:
		var cell := Vector2i(Vector2(spawn) / 40)
		check(not Map.find_path(simulation.map, cell, simulation.base_goal).is_empty(), "every city spawn reaches the base: " + str(cell))
	test_source_fingerprints()
	test_city_layout(simulation)
	test_city_objects(simulation)
	var industrial_scene := INDUSTRIAL.instantiate()
	check(simulation.map_scene.map_skin != industrial_scene.map_skin, "city and industrial themes use separate map-skin resources")
	industrial_scene.free()
	simulation.map_scene.free()
	await test_selection_flow()
	print("MAP SELECTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_source_fingerprints() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/city/manifest.json"))
	for role in ["cars", "street_props", "road_surface", "houses", "bushes"]:
		check(manifest.artwork.has(role), "city manifest records separate artwork role: " + role)
	for role in manifest.artwork:
		var entry: Dictionary = manifest.artwork[role]
		if entry.has("source") and entry.has("source_sha256"):
			check(FileAccess.file_exists(entry.source) and entry.source_sha256 == FileAccess.get_sha256(entry.source), "source fingerprint is reproducible: " + role)
		if entry.has("runtime") and entry.has("runtime_sha256"):
			check(FileAccess.file_exists(entry.runtime) and entry.runtime_sha256 == FileAccess.get_sha256(entry.runtime), "runtime fingerprint matches exported art: " + role)
		if entry.has("extraction"):
			check(entry.has("extraction_sha256") and FileAccess.file_exists(entry.extraction) and entry.extraction_sha256 == FileAccess.get_sha256(entry.extraction), "sprite extraction metadata is fingerprinted: " + role)
	if manifest.artwork.has("cars") and manifest.artwork.has("bushes"):
		check(manifest.artwork.cars.runtime != manifest.artwork.bushes.runtime, "cars and reusable bushes have separate sprite sheets")

func test_city_layout(simulation: RefCounted) -> void:
	var scene: Node2D = simulation.map_scene
	var road := scene.get_node_or_null("RoadLayout")
	check(road != null, "city uses a reusable authored road-layout node")
	if road != null:
		check(road.lane_count == 6 and road.road_rect.size.x == 480, "avenue contains three lanes in each direction")
		check(road.intersection_rect.position.y > 0 and road.intersection_rect.end.y < simulation.world_size.y and road.intersection_rect.position.x == 0 and road.intersection_rect.end.x == simulation.world_size.x, "cross street connects both sides near the city center")
		for lane in road.lane_count:
			var point := Vector2(road.road_rect.position.x + (lane + 0.5) * road.road_rect.size.x / road.lane_count, 60)
			check(Map.can_occupy(simulation.map, point), "all six lane entries are independently traversable: " + str(lane))
		for y in simulation.map.size():
			for x in simulation.map[y].size():
				var tile: Dictionary = simulation.map[y][x]
				var point := (Vector2(x, y) + Vector2.ONE * 0.5) * 40
				if road.road_rect.has_point(point) or road.intersection_rect.has_point(point):
					check(not tile.move_blocked and not tile.bullet_blocked, "road and markings never block movement or fire: " + str(Vector2i(x, y)))
	var has_destructible := false
	var has_foliage := false
	for row in simulation.map:
		for tile in row:
			has_destructible = has_destructible or tile.destructible
			has_foliage = has_foliage or tile.kind == "grass"
	check(not has_destructible and not has_foliage, "city excludes destructible brick terrain and bush overlays")

func test_city_objects(simulation: RefCounted) -> void:
	var definitions: Dictionary = {}
	var car_variants: Dictionary = {}
	var car_orientations: Dictionary = {}
	var car_count := 0
	var signal_count := 0
	var manhole_count := 0
	var house_count := 0
	for object in simulation.map_objects:
		var definition: Resource = object.definition
		var identifier: String = definition.object_id
		definitions[identifier] = definition
		check(identifier not in ["city_bush", "city_abandoned_robot"], "city omits bush and abandoned-robot placements")
		check(not object.destructible, "city object cannot be destroyed: " + identifier)
		if identifier.begins_with("city_house_"):
			house_count += 1
			check(object.category == "fixed" and object.move_blocked, "city facade is a solid authored edge object")
			test_sprite_crop(definition, false)
			var road: Node = simulation.map_scene.get_node("RoadLayout")
			for cell in object.footprint_cells:
				var point := (Vector2(cell) + Vector2.ONE * 0.5) * 40
				check(not road.road_rect.has_point(point) and not road.intersection_rect.has_point(point), "house stays beside both streets: " + str(cell))
			continue
		test_sprite_crop(definition)
		if identifier.begins_with("city_abandoned_car") or identifier.begins_with("city_abandoned_wagon"):
			car_count += 1
			car_variants["wagon" if identifier.begins_with("city_abandoned_wagon") else "car"] = true
			car_orientations["horizontal" if identifier.ends_with("_horizontal") else "vertical"] = true
			check(object.footprint.x > object.footprint.y if identifier.ends_with("_horizontal") else object.footprint.y > object.footprint.x, "vehicle footprint matches baked sprite orientation: " + identifier)
			test_car_readability(definition)
			test_movement_only_obstacle(simulation, object)
		elif identifier == "city_fallen_signal":
			signal_count += 1
			test_movement_only_obstacle(simulation, object)
		elif identifier == "city_manhole":
			manhole_count += 1
			var point: Vector2 = object.pos + Vector2.ONE * 20
			check(object.category == "decoration" and not object.move_blocked and not object.bullet_blocked, "manholes permit movement and fire")
			check(Map.can_occupy(simulation.map, point) and not simulation.bullet_collision({"pos": point, "friendly": true}), "manhole remains traversable and permits actual projectile collision checks")
	check(car_count >= 2 and car_count <= 6 and car_variants.size() == 2 and car_orientations.size() == 2, "two complete car models appear sparsely in both orientations")
	check(signal_count >= 1 and signal_count <= 2, "city has one or two fallen signals")
	check(manhole_count > 0, "city keeps passable street lids")
	check(house_count >= 4 and definitions.has("city_house_intact") and definitions.has("city_house_weathered") and definitions.has("city_house_ruined"), "both city edges contain intact, weathered and ruined houses")
	var bush: Resource = load("res://assets/map_objects/city/city_bush.tres")
	check(bush != null and bush.texture.atlas.resource_path == "res://assets/map_objects/vegetation/bushes.png", "bush definition stays reusable outside city on its own atlas")
	if bush == null:
		return
	test_sprite_crop(bush)
	for identifier in definitions:
		if identifier.begins_with("city_abandoned_car") or identifier.begins_with("city_abandoned_wagon"):
			check(definitions[identifier].texture.atlas.resource_path != bush.texture.atlas.resource_path, "car atlas cannot include bush sprites: " + identifier)

func test_sprite_crop(definition: Resource, require_gutter: bool = true) -> void:
	var image: Image = definition.texture.get_image()
	var visible_rect := image.get_used_rect()
	check(image.detect_alpha() != Image.ALPHA_NONE and visible_rect.has_area(), "sprite has visible art and transparent edges: " + definition.object_id)
	if require_gutter:
		check(visible_rect.position.x > 0 and visible_rect.position.y > 0 and visible_rect.end.x < image.get_width() and visible_rect.end.y < image.get_height(), "sprite is complete inside transparent crop gutters: " + definition.object_id)

func test_car_readability(definition: Resource) -> void:
	var image: Image = definition.texture.get_image()
	var minimum := image.get_size()
	var maximum := Vector2i.ZERO
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.1:
				minimum = minimum.min(Vector2i(x, y))
				maximum = maximum.max(Vector2i(x + 1, y + 1))
	var visible_size := Vector2(maximum - minimum) / Vector2(image.get_size())
	check(maxf(visible_size.x, visible_size.y) >= 0.75, "car body fills its sprite frame instead of shrinking around alpha noise: " + definition.object_id)

func test_movement_only_obstacle(simulation: RefCounted, object: Dictionary) -> void:
	check(object.category == "fixed" and object.hp == 0 and object.move_blocked and not object.bullet_blocked, "abandoned cars and fallen signals only block movement")
	for cell in object.footprint_cells:
		var point := (Vector2(cell) + Vector2.ONE * 0.5) * 40
		var tile := Map.tile_at(simulation.map, point)
		check(Map.move_blocked(tile) and not Map.bullet_blocked(tile) and not Map.can_occupy(simulation.map, point), "every obstacle footprint blocks actors while permitting shots: " + str(cell))
		check(not simulation.bullet_collision({"pos": point, "friendly": true}), "actual projectile collision passes through fixed street obstacle")
		simulation.damage_wall(point)
		check(object.active and object.hp == 0 and not Map.can_breach(tile), "street obstacle remains fixed after damage and cannot be breached")

func test_selection_flow() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.choose_mode("single")
	check(game.map_preparation.visible and not game.preparation.visible, "fresh game opens the map picker before character selection")
	check(game.map_preparation.map_scenes.size() == 2 and game.map_scene == INDUSTRIAL, "picker lists both maps and begins on the established industrial map")
	check(game.map_preparation.preview.texture != null and game.map_preparation.preview.texture.get_width() > 0, "each map selection provides a designer-authored preview")
	game.map_preparation.select_map(CITY)
	check(game.map_preparation.preview.texture != null, "city selection has a native gameplay overview image")
	game.map_preparation.confirm_selection()
	check(game.map_scene == CITY and game.sim.map_scene.map_id == "abandoned_city_day", "map choice creates simulation and updates map theme")
	check(game.preparation.visible and not game.map_preparation.visible, "character selector only opens after map confirmation")
	for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 768)]:
		root.size = viewport_size
		await process_frame
		game.layout()
		var visible_world: Vector2 = Vector2(game.battle_viewport.size) / game.camera.zoom
		check(visible_world.x >= game.sim.world_size.x - 0.1 and visible_world.y >= game.sim.world_size.y - 0.1, "selected city fits desktop viewport: " + str(viewport_size))
	root.size = Vector2i(1280, 720)
	await process_frame
	game.layout()
	game.preparation.choose_character("tank")
	check(game.sim.map_scene.map_id == "abandoned_city_day" and game.sim.loadout.character_id == "tank", "character changes preserve the selected map")
	game.activate()
	check(game.sim.status == "playing" and game.sim.map_scene.map_id == "abandoned_city_day", "deployment starts on the chosen city map")
	game.sim.status = "lost"
	game.refresh_hud()
	game.show_map_selection()
	game.map_preparation.select_map(INDUSTRIAL)
	game.map_preparation.confirm_selection()
	check(game.sim.map_scene.map_id == "industrial_yard" and game.preparation.visible, "changing map returns to the character step")
	game.preparation.choose_character("robot")
	game.activate()
	check(game.sim.status == "playing" and game.sim.map_scene.map_id == "industrial_yard", "replay follows the most recently chosen map")
	game.queue_free()
	await process_frame
