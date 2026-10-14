extends SceneTree
func _initialize():
	var atlas := Image.create(200, 40, false, Image.FORMAT_RGBA8)
	var kinds := ["brick", "steel", "water", "grass", "floor"]
	for index in kinds.size():
		var image := Image.load_from_file("res://assets/terrain/industrial/%s.png" % kinds[index])
		image.resize(40, 40, Image.INTERPOLATE_LANCZOS)
		atlas.blit_rect(image, Rect2i(0, 0, 40, 40), Vector2i(index * 40, 0))
	atlas.save_png("res://assets/maps/industrial/terrain_atlas.png")
	quit()
