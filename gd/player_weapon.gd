extends Resource
@export var id = "standard"
@export var explicit_muzzles: Dictionary = {}
@export var burst_times: Array = [0.0]
@export var double_times: Array = [0.0, 0.08]
@export var alternating = false
@export var rapid_rest_multiplier = 0.5
@export var layered_art: Resource
@export var display_name = "Súng thường"
@export var cooldown = 0.4
@export var damage = 1
@export var bullet_speed = 410.0
@export var shot_duration = 0.23
@export var texture_scale = 0.5
@export var anchors: Dictionary = {"down": Vector2(64, 32), "up": Vector2(64, 37), "right": Vector2(67, 43), "left": Vector2(61, 43)}
@export var flash_cutouts: Dictionary = {"down": Rect2(47, 70, 34, 24), "up": Rect2(49, 0, 30, 30), "right": Rect2(94, 28, 32, 32), "left": Rect2(0, 28, 34, 32)}
@export var frames: SpriteFrames
@export var directional_frames: SpriteFrames
@export var cutouts: Dictionary = {}
@export var muzzle_offsets: Dictionary = {}
@export var barrel_offsets: Array[float] = [0.0]

func cutout_for(direction: String, _animation: String, _index: int) -> Rect2:
	return cutouts[direction]

func regions_for(direction: String, animation: String, index: int) -> Array:
	var regions: Array = [cutouts[direction]]
	if animation.ends_with("attack") and index == 1:
		regions.append_array(preload("res://gd/sprite_regions.gd").subtract([flash_cutouts[direction]], regions))
	return regions

func frame_for(direction: String, animation: String, index: int) -> Texture2D:
	var source = frames if direction == "down" else directional_frames
	return source.get_frame_texture(animation, index)

func schedule(doubled: bool) -> Array:
	var result: Array = []
	var times: Array = double_times if doubled else burst_times
	for i in times.size():
		var barrels: Array = [int(i / 2) if doubled else i] if alternating else range(barrel_offsets.size())
		result.append({"time": float(times[i]), "barrels": barrels})
	return result
