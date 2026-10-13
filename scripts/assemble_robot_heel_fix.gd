extends SceneTree

func _initialize() -> void:
	var source = Image.load_from_file("res://assets/generated/sprites/characters/body-weapons/up-heels/reference.png")
	var edited = Image.load_from_file("res://assets/generated/sprites/characters/body-weapons/up-heels/generated.png")
	if source == null or edited == null or source.get_size() != edited.get_size():
		push_error("Robot heel source sizes do not match")
		quit(1)
		return
	var region = Rect2i(209, 145, 209, 92)
	source.blit_rect(edited, region, region.position)
	for path in ["res://assets/sprites/characters/layers.png", "res://assets/generated/sprites/characters/body-weapons/source.png"]:
		if source.save_png(path) != OK:
			push_error("Cannot save heel assembly: " + path)
			quit(1)
			return
	print("Robot UP heels assembled; all pixels outside edit region preserved")
	quit()
