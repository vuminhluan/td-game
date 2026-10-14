extends SceneTree

var artwork: Dictionary = {}
var failed := false

func _initialize() -> void:
	var road := read_source("road_surface")
	var terrain := read_source("terrain")
	var legacy := read_source("objects")
	var cars := read_source("cars")
	var props := read_source("street_props")
	var houses := read_source("houses")
	if road == null or terrain == null or legacy == null or cars == null or props == null or houses == null:
		quit(1)
		return
	road.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	write_art(road, "road_surface", "road_surface", "assets/terrain/abandoned_city/floor.png")
	var side := terrain.get_width() / 2
	var terrain_atlas := Image.create(200, 40, false, Image.FORMAT_RGBA8)
	for index in 4:
		var tile: Image = road.duplicate() if index == 0 else terrain.get_region(Rect2i((index % 2) * side, (index / 2) * side, side, side))
		tile.resize(40, 40, Image.INTERPOLATE_LANCZOS)
		terrain_atlas.blit_rect(tile, Rect2i(0, 0, 40, 40), Vector2i(index * 40, 0))
	var bush := normalized_sprite(legacy, source_region("objects", "bush"), Vector2i(128, 128))
	write_art(bush, "bushes", "objects", "assets/map_objects/vegetation/bushes.png")
	var grass: Image = bush.duplicate()
	grass.resize(40, 40, Image.INTERPOLATE_LANCZOS)
	terrain_atlas.blit_rect(grass, Rect2i(0, 0, 40, 40), Vector2i(160, 0))
	write_art(terrain_atlas, "terrain", "terrain", "assets/maps/city/terrain_atlas.png")
	var pavement := terrain.get_region(Rect2i(0, side, side, side))
	pavement.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	write_art(pavement, "sidewalk", "terrain", "assets/maps/city/sidewalk.png")
	var robot := normalized_sprite(legacy, source_region("objects", "robot"), Vector2i(128, 128))
	write_art(robot, "legacy_robot", "objects", "assets/map_objects/city/abandoned_robot.png")
	var car_atlas := Image.create(256, 192, false, Image.FORMAT_RGBA8)
	var horizontal := Image.create(384, 128, false, Image.FORMAT_RGBA8)
	for index in 2:
		var cell := source_region("cars", "sedan" if index == 0 else "wagon")
		var sprite := normalized_sprite(cars, cell, Vector2i(128, 192))
		car_atlas.blit_rect(sprite, Rect2i(0, 0, 128, 192), Vector2i(index * 128, 0))
		sprite.rotate_90(CLOCKWISE)
		horizontal.blit_rect(sprite, Rect2i(0, 0, 192, 128), Vector2i(index * 192, 0))
	write_art(car_atlas, "cars", "cars", "assets/map_objects/city/cars.png")
	write_art(horizontal, "cars_horizontal", "cars", "assets/map_objects/city/cars_horizontal.png")
	var street_atlas := Image.create(512, 128, false, Image.FORMAT_RGBA8)
	var regions := [source_region("street_props", "signal"), source_region("street_props", "sign"), source_region("street_props", "manhole")]
	var sizes := [Vector2i(256, 128), Vector2i(128, 128), Vector2i(128, 128)]
	for index in 3:
		var sprite := normalized_sprite(props, regions[index], sizes[index])
		street_atlas.blit_rect(sprite, Rect2i(Vector2i.ZERO, sizes[index]), Vector2i(0 if index == 0 else 128 + index * 128, 0))
	write_art(street_atlas, "street_props", "street_props", "assets/map_objects/city/street_props.png")
	var house_atlas := Image.create(480, 160, false, Image.FORMAT_RGBA8)
	for index in 3:
		var sprite := normalized_sprite(houses, source_region("houses", ["intact", "weathered", "ruined"][index]), Vector2i(160, 160))
		house_atlas.blit_rect(sprite, Rect2i(0, 0, 160, 160), Vector2i(index * 160, 0))
	write_art(house_atlas, "houses", "houses", "assets/maps/city/outer_houses.png")
	if failed:
		quit(1)
		return
	var file := FileAccess.open("res://assets/maps/city/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"artwork": artwork, "normalizer": "scripts/build_city_map_art.gd"}, "\t") + "\n")
	quit()

func read_source(role: String) -> Image:
	var path := "res://assets/generated/map/city/%s/source.png" % role
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_error("City art source required: " + path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	var extraction := "res://assets/generated/map/city/%s/extraction.json" % role
	if FileAccess.file_exists(extraction):
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(extraction))
		if image.get_size() != Vector2i(config.source_size[0], config.source_size[1]):
			push_error("Update extraction regions after replacing source dimensions: " + extraction)
			return null
		for region in config.regions.values():
			if not Rect2i(Vector2i.ZERO, image.get_size()).encloses(Rect2i(region[0], region[1], region[2], region[3])):
				push_error("Source extraction region is outside image: " + extraction)
				return null
	return image

func source_region(role: String, key: String) -> Rect2i:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/generated/map/city/%s/extraction.json" % role))
	var region: Array = config.regions[key]
	return Rect2i(region[0], region[1], region[2], region[3])

func normalized_sprite(source: Image, region: Rect2i, size: Vector2i) -> Image:
	if not Rect2i(Vector2i.ZERO, source.get_size()).encloses(region):
		push_error("Source sprite region is outside image bounds: %s" % region)
		failed = true
		return Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	var sprite := source.get_region(region)
	var bounds := visible_bounds(sprite)
	if not bounds.has_area():
		push_error("Source sprite is empty: %s" % region)
		failed = true
		return Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	sprite = sprite.get_region(bounds)
	var available := Vector2(size - Vector2i(16, 16))
	var ratio := minf(available.x / sprite.get_width(), available.y / sprite.get_height())
	var resized := Vector2i(Vector2(sprite.get_size()) * ratio)
	sprite.resize(maxi(resized.x, 1), maxi(resized.y, 1), Image.INTERPOLATE_LANCZOS)
	var result := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	result.blit_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), (size - sprite.get_size()) / 2)
	return result

func visible_bounds(image: Image) -> Rect2i:
	var minimum := image.get_size()
	var maximum := Vector2i.ZERO
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.04:
				minimum = minimum.min(Vector2i(x, y))
				maximum = maximum.max(Vector2i(x + 1, y + 1))
	if minimum.x >= maximum.x or minimum.y >= maximum.y:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum).grow(4).intersection(Rect2i(Vector2i.ZERO, image.get_size()))

func write_art(image: Image, key: String, role: String, runtime: String) -> void:
	var source := "res://assets/generated/map/city/%s/source.png" % role
	var destination := "res://" + runtime
	if image.save_png(destination) != OK:
		push_error("Unable to write " + destination)
		failed = true
		return
	artwork[key] = {"source": source, "source_sha256": FileAccess.get_sha256(source), "runtime": destination, "runtime_sha256": FileAccess.get_sha256(destination)}
	var extraction := "res://assets/generated/map/city/%s/extraction.json" % role
	if FileAccess.file_exists(extraction):
		artwork[key].extraction = extraction
		artwork[key].extraction_sha256 = FileAccess.get_sha256(extraction)
