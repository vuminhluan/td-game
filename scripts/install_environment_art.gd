extends SceneTree

const Definition = preload("res://gd/map_object_definition.gd")
const Catalog = preload("res://gd/map_object_catalog.gd")
const OBJECTS = {
	"machinery": {"name": "Máy nén nhà xưởng", "category": "fixed", "footprint": Vector2i(3, 2), "frame": Rect2(0, 0, 120, 80), "blocks_bullets": true},
	"pipes": {"name": "Cụm ống nước thấp", "category": "fixed", "footprint": Vector2i(4, 1), "frame": Rect2(0, -4, 160, 48), "blocks_bullets": false},
	"robot_wreck": {"name": "Robot bỏ hoang", "category": "fixed", "footprint": Vector2i(2, 2), "frame": Rect2(0, 0, 80, 80), "blocks_bullets": true},
	"drink_can": {"name": "Lon nước cũ", "category": "decoration", "footprint": Vector2i.ONE, "frame": Rect2(-9, -9, 18, 18), "blocks_bullets": false}
}

func visible_bounds(image: Image) -> Rect2i:
	var minimum := image.get_size()
	var maximum := Vector2i.ZERO
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.1:
				minimum = minimum.min(Vector2i(x, y))
				maximum = maximum.max(Vector2i(x + 1, y + 1))
	return Rect2i(minimum, maximum - minimum).grow(2).intersection(Rect2i(Vector2i.ZERO, image.get_size()))

func _initialize() -> void:
	var catalog: Resource = ResourceLoader.load("res://assets/map_objects/catalog.tres", "", ResourceLoader.CACHE_MODE_IGNORE) if FileAccess.file_exists("res://assets/map_objects/catalog.tres") else Catalog.new()
	var manifest := {"provider": "built-in imagegen", "style": "aged_factory", "objects": {}}
	for role in OBJECTS:
		var config: Dictionary = OBJECTS[role]
		var path := "res://assets/map_objects/industrial/%s.png" % role
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK or image.detect_alpha() == Image.ALPHA_NONE:
			push_error(role + ": artwork must retain generated alpha")
			quit(1)
			return
		var region := visible_bounds(image)
		var texture := AtlasTexture.new()
		texture.atlas = load(path)
		texture.region = region
		texture.filter_clip = true
		var resource_path := "res://assets/map_objects/industrial/%s.tres" % role
		var exists := FileAccess.file_exists(resource_path)
		var definition: Resource = ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_IGNORE) if exists else Definition.new()
		if not definition is Definition:
			push_error("Expected MapObjectDefinition: " + resource_path)
			quit(1)
			return
		if not exists:
			var frame: Rect2 = config.frame
			var source_size := Vector2(region.size)
			var size := source_size * minf(frame.size.x / source_size.x, frame.size.y / source_size.y)
			definition.object_id = "industrial_" + role
			definition.display_name = config.name
			definition.tags.assign(["industrial", role])
			definition.visual_rect = Rect2(frame.get_center() - size / 2, size)
			definition.category = config.category
			definition.footprint = config.footprint
			definition.move_blocked = config.category == "fixed"
			definition.bullet_blocked = config.blocks_bullets
			definition.initial_hp = 0
		definition.texture = texture
		if ResourceSaver.save(definition, resource_path, ResourceSaver.FLAG_CHANGE_PATH) != OK:
			push_error("Unable to save " + resource_path)
			quit(1)
			return
		var saved: Resource = ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		var replaced := false
		for index in catalog.objects.size():
			if catalog.objects[index].resource_path == resource_path:
				catalog.objects[index] = saved
				replaced = true
				break
		if not replaced:
			catalog.objects.append(saved)
		var source_role: String = "machinery" if role == "machinery" else ("wreck" if role == "robot_wreck" else ("can" if role == "drink_can" else role))
		manifest.objects[role] = {"runtime_texture": path, "definition": resource_path, "source": "assets/generated/map/industrial/objects/%s/source.png" % source_role,
			"prompt": "assets/generated/map/industrial/objects/%s/prompt.txt" % source_role, "sha256": FileAccess.get_sha256(path),
			"source_region": [region.position.x, region.position.y, region.size.x, region.size.y]}
		print(role, " ", region, " -> ", definition.visual_rect)
	if ResourceSaver.save(catalog, "res://assets/map_objects/catalog.tres") != OK:
		quit(1)
		return
	var file := FileAccess.open("res://assets/map_objects/industrial/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	quit()
