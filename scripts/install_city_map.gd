extends SceneTree

const Definition = preload("res://gd/map_object_definition.gd")
const ObjectNode = preload("res://gd/map_object.gd")
const MapNode = preload("res://gd/map_definition.gd")
const Marker = preload("res://gd/map_marker.gd")
const MapSkin = preload("res://gd/map_skin.gd")
const RoadLayout = preload("res://gd/road_layout.gd")
const TERRAINS = ["floor", "brick", "steel", "water", "grass"]
var definitions: Dictionary = {}

func _initialize() -> void:
	if not save_resource(build_tile_set(), "res://assets/maps/city/terrain.tres") or not save_resource(build_skin(), "res://assets/terrain/abandoned_city/map_skin.tres"):
		quit(1)
		return
	if not build_object_resources() or not build_city_scene():
		quit(1)
		return
	write_manifest()
	quit()

func build_tile_set() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(40, 40)
	for layer in [["kind", TYPE_STRING], ["move_blocked", TYPE_BOOL], ["bullet_blocked", TYPE_BOOL], ["destructible", TYPE_BOOL], ["hp", TYPE_INT], ["steel", TYPE_BOOL]]:
		var index := tiles.get_custom_data_layers_count()
		tiles.add_custom_data_layer()
		tiles.set_custom_data_layer_name(index, layer[0])
		tiles.set_custom_data_layer_type(index, layer[1])
	var source := TileSetAtlasSource.new()
	source.texture = load("res://assets/maps/city/terrain_atlas.png")
	source.texture_region_size = Vector2i(40, 40)
	tiles.add_source(source, 0)
	for index in TERRAINS.size():
		var coords := Vector2i(index, 0)
		source.create_tile(coords)
		var data := source.get_tile_data(coords, 0)
		data.set_custom_data("kind", TERRAINS[index])
		data.set_custom_data("move_blocked", index in [1, 2, 3])
		data.set_custom_data("bullet_blocked", index in [1, 2])
		data.set_custom_data("destructible", index in [1, 2])
		data.set_custom_data("hp", 3 if index == 1 else 5 if index == 2 else 0)
		data.set_custom_data("steel", index == 2)
		if index == 4:
			data.z_index = 1
	return tiles

func atlas_region(path: String, region: Rect2) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = load(path)
	result.region = region
	result.filter_clip = true
	return result

func build_skin() -> MapSkin:
	var skin := MapSkin.new()
	skin.floor_texture = load("res://assets/terrain/abandoned_city/floor.png")
	for entry in [["brick_texture", 1], ["steel_texture", 2], ["water_texture", 3], ["foliage_texture", 4]]:
		skin.set(entry[0], atlas_region("res://assets/maps/city/terrain_atlas.png", Rect2(entry[1] * 40, 0, 40, 40)))
	skin.brick_damage = load("res://assets/terrain/industrial_v1/brick_damage.svg")
	skin.brick_critical = load("res://assets/terrain/industrial_v1/brick_critical.svg")
	skin.headquarters_texture = load("res://assets/terrain/industrial_v1/headquarters.png")
	skin.headquarters_wreck = load("res://assets/terrain/industrial_v1/headquarters_wreck.png")
	return skin

func object_specs() -> Array:
	return [
		{"tag": "abandoned_car", "id": "city_abandoned_car", "name": "Xe sedan gỉ sét", "art": "city/cars.png", "region": Rect2(0, 0, 128, 192), "footprint": Vector2i(2, 3), "fixed": true, "bullets": false},
		{"tag": "abandoned_wagon", "id": "city_abandoned_wagon", "name": "Xe wagon bỏ hoang", "art": "city/cars.png", "region": Rect2(128, 0, 128, 192), "footprint": Vector2i(2, 3), "fixed": true, "bullets": false},
		{"tag": "abandoned_car_horizontal", "id": "city_abandoned_car_horizontal", "name": "Xe sedan nằm ngang", "art": "city/cars_horizontal.png", "region": Rect2(0, 0, 192, 128), "footprint": Vector2i(3, 2), "fixed": true, "bullets": false},
		{"tag": "abandoned_wagon_horizontal", "id": "city_abandoned_wagon_horizontal", "name": "Xe wagon nằm ngang", "art": "city/cars_horizontal.png", "region": Rect2(192, 0, 192, 128), "footprint": Vector2i(3, 2), "fixed": true, "bullets": false},
		{"tag": "fallen_signal", "id": "city_fallen_signal", "name": "Đèn giao thông đổ", "art": "city/street_props.png", "region": Rect2(0, 0, 256, 128), "footprint": Vector2i(4, 2), "fixed": true, "bullets": false},
		{"tag": "street_sign", "id": "city_street_sign", "name": "Biển báo cũ", "art": "city/street_props.png", "region": Rect2(256, 0, 128, 128), "footprint": Vector2i.ONE, "fixed": false, "bullets": false},
		{"tag": "manhole", "id": "city_manhole", "name": "Nắp cống", "art": "city/street_props.png", "region": Rect2(384, 0, 128, 128), "footprint": Vector2i.ONE, "fixed": false, "bullets": false},
		{"tag": "city_bush", "id": "city_bush", "name": "Bụi cỏ", "art": "vegetation/bushes.png", "region": Rect2(0, 0, 128, 128), "footprint": Vector2i.ONE, "fixed": false, "bullets": false},
		{"tag": "abandoned_robot", "id": "city_abandoned_robot", "name": "Robot bỏ hoang", "art": "city/abandoned_robot.png", "region": Rect2(0, 0, 128, 128), "footprint": Vector2i(2, 2), "fixed": true, "bullets": true},
		{"tag": "house_intact", "id": "city_house_intact", "name": "Nhà cũ nguyên vẹn", "art": "../maps/city/outer_houses.png", "region": Rect2(0, 0, 160, 160), "footprint": Vector2i(3, 3), "fixed": true, "bullets": true},
		{"tag": "house_weathered", "id": "city_house_weathered", "name": "Nhà bám rêu", "art": "../maps/city/outer_houses.png", "region": Rect2(160, 0, 160, 160), "footprint": Vector2i(3, 3), "fixed": true, "bullets": true},
		{"tag": "house_ruined", "id": "city_house_ruined", "name": "Nhà vỡ mái", "art": "../maps/city/outer_houses.png", "region": Rect2(320, 0, 160, 160), "footprint": Vector2i(3, 3), "fixed": true, "bullets": true}
	]

func build_object_resources() -> bool:
	var catalog: Resource = ResourceLoader.load("res://assets/map_objects/catalog.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	for item in object_specs():
		var definition := Definition.new()
		definition.object_id = item.id
		definition.display_name = item.name
		definition.tags.assign(["vegetation" if item.tag == "city_bush" else "city", item.tag])
		definition.texture = atlas_region(("res://assets/map_objects/" + item.art).simplify_path(), item.region)
		definition.category = "fixed" if item.fixed else "decoration"
		definition.footprint = item.footprint
		definition.move_blocked = item.fixed
		definition.bullet_blocked = item.bullets
		definition.initial_hp = 0
		var size := Vector2(item.footprint) * 40 - Vector2(4, 4)
		if item.tag == "city_bush":
			size = Vector2(58, 58)
		elif item.tag in ["manhole", "street_sign"]:
			size = Vector2(34, 34)
		definition.visual_rect = Rect2(Vector2(item.footprint) * 20 - size / 2, size)
		var path := "res://assets/map_objects/city/%s.tres" % item.tag
		if not save_resource(definition, path):
			return false
		var saved: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		definitions[item.tag] = saved
		var object_scene := ObjectNode.new()
		object_scene.name = item.tag
		object_scene.definition = saved
		if item.tag == "city_bush":
			object_scene.z_index = 1
		if not save_scene(object_scene, "res://scenes/objects/city/%s.tscn" % item.tag):
			return false
		var existing := false
		for entry_index in catalog.objects.size():
			if catalog.objects[entry_index].object_id == item.id:
				catalog.objects[entry_index] = saved
				existing = true
				break
		if not existing:
			catalog.objects.append(saved)
	return save_resource(catalog, "res://assets/map_objects/catalog.tres")

func build_city_scene() -> bool:
	var root := MapNode.new()
	root.name = "AbandonedCityDay"
	root.map_id = "abandoned_city_day"
	root.display_name = "Thành phố bỏ hoang"
	root.display_description = "Ban ngày · đại lộ sáu làn, ngã tư vắng, xe gỉ sét và nhà đổ nát."
	root.dimensions = Vector2i(21, 19)
	root.map_skin = ResourceLoader.load("res://assets/terrain/abandoned_city/map_skin.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	root.preview_texture = load("res://assets/maps/previews/abandoned-city.png")
	var ground := Sprite2D.new()
	ground.name = "Floor"
	ground.texture = load("res://assets/terrain/abandoned_city/floor.png")
	ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	ground.centered = false
	ground.region_enabled = true
	ground.region_rect = Rect2(0, 0, 840, 760)
	add_owned(root, ground)
	var road := RoadLayout.new()
	road.name = "RoadLayout"
	road.sidewalk_texture = load("res://assets/maps/city/sidewalk.png")
	add_owned(root, road)
	var layer := TileMapLayer.new()
	layer.name = "Terrain"
	layer.tile_set = ResourceLoader.load("res://assets/maps/city/terrain.tres", "", ResourceLoader.CACHE_MODE_IGNORE)
	add_owned(root, layer)
	var placements := {
		"abandoned_car": [Vector2i(6, 2)], "abandoned_wagon": [Vector2i(14, 3)],
		"abandoned_car_horizontal": [Vector2i(5, 13)], "abandoned_wagon_horizontal": [Vector2i(14, 16)],
		"fallen_signal": [Vector2i(5, 6), Vector2i(12, 12)],
		"manhole": [Vector2i(8, 4), Vector2i(12, 8), Vector2i(9, 11), Vector2i(11, 15)],
		"street_sign": [Vector2i(3, 6), Vector2i(17, 12)],
		"house_intact": [Vector2i(0, 0), Vector2i(18, 12), Vector2i(0, 16)],
		"house_weathered": [Vector2i(18, 0), Vector2i(0, 12), Vector2i(18, 16)],
		"house_ruined": [Vector2i(0, 4), Vector2i(18, 4)]
	}
	for role in placements:
		for cell in placements[role]:
			var object: Node2D = load("res://scenes/objects/city/%s.tscn" % role).instantiate()
			object.name = "%s_%02d" % [role, root.get_child_count()]
			object.position = Vector2(cell * 40)
			add_owned(root, object)
	add_marker(root, "Headquarters", "base", Vector2(420, 700))
	add_marker(root, "PlayerSpawn", "player", Vector2(420, 620))
	for index in 3:
		add_marker(root, "EnemySpawn%d" % index, "enemy", Vector2(260 + index * 160, 20))
	var runtime: Dictionary = root.build_runtime()
	if not runtime.errors.is_empty():
		for error in runtime.errors:
			push_error(error)
		root.free()
		return false
	return save_scene(root, "res://scenes/maps/abandoned_city.tscn")

func add_owned(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = parent

func add_marker(parent: Node, node_name: String, role: String, point: Vector2) -> void:
	var marker := Marker.new()
	marker.name = node_name
	marker.role = role
	marker.position = point
	add_owned(parent, marker)

func save_resource(resource: Resource, path: String) -> bool:
	var status := ResourceSaver.save(resource, path)
	if status != OK:
		push_error("Unable to save " + path + ": " + error_string(status))
	return status == OK

func save_scene(scene_root: Node, path: String) -> bool:
	var packed := PackedScene.new()
	var status := packed.pack(scene_root)
	if status == OK:
		status = ResourceSaver.save(packed, path)
	scene_root.free()
	if status != OK:
		push_error("Unable to save " + path + ": " + error_string(status))
	return status == OK

func write_manifest() -> void:
	var manifest := {"display_name": "Thành phố bỏ hoang", "style": "bright_day_abandoned_city", "objects": {}, "source_directory": "assets/generated/map/city/"}
	for item in object_specs():
		var artwork_path: String = ("res://assets/map_objects/" + item.art).simplify_path()
		manifest.objects[item.tag] = {"definition": "res://assets/map_objects/city/%s.tres" % item.tag, "scene": "res://scenes/objects/city/%s.tscn" % item.tag, "artwork": artwork_path, "sha256": FileAccess.get_sha256(artwork_path)}
	var file := FileAccess.open("res://assets/map_objects/city/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
