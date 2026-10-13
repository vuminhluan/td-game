extends Resource
@export var sockets: Dictionary = {"roof": {"down": Vector2(64, 32), "up": Vector2(64, 37), "right": Vector2(67, 43), "left": Vector2(61, 43)}}
@export var weapon_cutouts: Dictionary = {"down": Rect2(58, 32, 12, 61), "up": Rect2(58, 0, 12, 37), "right": Rect2(67, 37, 51, 12), "left": Rect2(8, 37, 53, 12)}
@export var flash_cutouts: Dictionary = {"down": Rect2(47, 70, 34, 24), "up": Rect2(49, 0, 30, 30), "right": Rect2(94, 28, 32, 32), "left": Rect2(0, 28, 34, 32)}
@export var mount_rects: Dictionary = {"down": Rect2(-3, 0, 6, 16), "up": Rect2(-4, -3, 8, 6), "right": Rect2(-4, -3, 8, 6), "left": Rect2(-4, -3, 8, 6)}
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

func socket_for(socket: String, direction: String) -> Vector2:
	return (sockets[socket][direction] - anchor_for(direction)) * texture_scale

func frame_index_for(player: Dictionary, elapsed: float) -> int:
	var state = animation_for(player)
	var animation = animation_name_for(player)
	var source = frames_for(player.dir)
	var count = source.get_frame_count(animation)
	var index = 0
	if state == "attack":
		var duration: float = player.shot_duration
		index = mini(count - 1, floori((duration - player.shot_clock) / duration * count))
	elif state == "walk":
		index = int(player.move_clock * source.get_animation_speed(animation)) % count
	else:
		index = int(elapsed * source.get_animation_speed(animation)) % count
	return index

func frame_for(player: Dictionary, elapsed: float) -> Texture2D:
	return frames_for(player.dir).get_frame_texture(animation_name_for(player), frame_index_for(player, elapsed))

func cutouts_for(direction: String, animation: String, index: int) -> Array:
	var regions: Array = [weapon_cutouts[direction]]
	if animation.ends_with("attack") and index == 1:
		regions.append(flash_cutouts[direction])
	return regions
