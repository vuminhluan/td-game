extends Resource
@export var directions: Dictionary = {}

func direction_for(direction: String) -> Resource:
	return directions.get(direction)

func muzzle_distances() -> Dictionary:
	var result: Dictionary = {}
	for direction in directions:
		result[direction] = directions[direction].muzzle_distance
	return result

func animation_for(actor: Dictionary) -> String:
	if actor.moving:
		return "walk"
	return "attack" if actor.shot_clock > 0 else "idle"

func frame_for(actor: Dictionary, elapsed: float) -> Texture2D:
	var view = direction_for(actor.dir)
	if view == null or view.frames == null:
		return null
	var animation = animation_for(actor)
	var source: SpriteFrames = view.frames
	var count = source.get_frame_count(animation)
	if count == 0:
		return null
	var index = 0
	if animation == "attack":
		var duration: float = actor.shot_duration
		index = clampi(floori((duration - actor.shot_clock) / duration * count), 0, count - 1)
	else:
		var clock: float = actor.move_clock if animation == "walk" else elapsed
		index = int(clock * source.get_animation_speed(animation)) % count
	return source.get_frame_texture(animation, index)
