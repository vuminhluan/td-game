extends Resource
@export var frames: SpriteFrames
@export var directional_frames: SpriteFrames
@export var texture_scale = 0.5
@export var anchor = Vector2(64, 50)
@export var forward = Vector2.DOWN
@export var directional_anchors: Dictionary = {}
@export var muzzle_distances: Dictionary = {"down": 15.0, "up": 15.0, "right": 15.0, "left": 15.0}

func rotation_for(direction: String) -> float:
	if directional_frames != null:
		return 0.0
	return forward.angle_to(preload("res://gd/rules.gd").VECTOR[direction])

func anchor_for(direction: String) -> Vector2:
	return directional_anchors.get(direction, anchor)

func frames_for(direction: String) -> SpriteFrames:
	return frames if direction == "down" or directional_frames == null else directional_frames

func animation_name_for(player: Dictionary) -> String:
	var state = animation_for(player)
	return state if player.dir == "down" or directional_frames == null else player.dir + "_" + state

func animation_for(player: Dictionary) -> String:
	if player.moving:
		return "walk"
	return "attack" if player.shot_clock > 0 else "idle"

func frame_for(player: Dictionary, elapsed: float) -> Texture2D:
	var state = animation_for(player)
	var animation = animation_name_for(player)
	var source = frames_for(player.dir)
	var count = source.get_frame_count(animation)
	var index = 0
	if state == "attack":
		var duration: float = preload("res://gd/rules.gd").SHOT_COOLDOWN
		index = mini(count - 1, floori((duration - player.shot_clock) / duration * count))
	elif state == "walk":
		index = int(player.move_clock * source.get_animation_speed(animation)) % count
	else:
		index = int(elapsed * source.get_animation_speed(animation)) % count
	return source.get_frame_texture(animation, index)
