extends "res://gd/player_skin.gd"
var rear_regions: Dictionary = {}
var walk_split_offset = 0.0
var walk_stride = 0.0
var recoil_distance = 0.0
var atlas: Texture2D
var art_row = 0
var cell_size = Vector2(256, 256)
var directions = ["down", "up", "left", "right"]

func configure(texture: Texture2D, metadata: Dictionary) -> void:
	walk_split_offset = metadata.get("walk_split_offset", 0.0)
	walk_stride = metadata.get("walk_stride", 0.0)
	recoil_distance = metadata.get("recoil_distance", 0.0)
	atlas = texture
	texture_scale = metadata.scale
	directional_anchors = {}
	weapon_cutouts = {}
	flash_cutouts = {}
	mount_rects = {}
	sockets = {"roof": {}}
	frames = SpriteFrames.new()
	directional_frames = frames
	for direction in directions:
		var view: Dictionary = metadata.directions[direction]
		if view.has("rear_region"):
			var rear: Array = view.rear_region
			rear_regions[direction] = Rect2(rear[0], rear[1], rear[2], rear[3])
		var region = Rect2(view.region[0], view.region[1], view.region[2], view.region[3])
		var frame_anchor = Vector2(view.anchor[0], view.anchor[1])
		directional_anchors[direction] = frame_anchor
		anchor = frame_anchor if direction == "down" else anchor
		var point: Array = view.get("socket", view.anchor)
		sockets.roof[direction] = Vector2(point[0], point[1])
		for state in ["idle", "walk", "attack"]:
			var animation: String = state if direction == "down" else direction + "_" + state
			frames.add_animation(animation)
			frames.set_animation_speed(animation, 8)
			for i in 4:
				var frame = AtlasTexture.new()
				frame.atlas = atlas
				frame.region = region
				frames.add_frame(animation, frame)

func cutouts_for(_direction: String, _animation: String, _index: int) -> Array:
	return []

func texture_for(direction: String) -> Texture2D:
	return frames.get_frame_texture("idle" if direction == "down" else direction + "_idle", 0)
