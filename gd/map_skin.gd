extends Resource
@export var floor_texture: Texture2D
@export var floor_tint := Color(0.55, 0.60, 0.62, 1)
@export var brick_texture: Texture2D
@export var steel_texture: Texture2D
@export var water_texture: Texture2D
@export var foliage_texture: Texture2D
@export var brick_damage: Texture2D
@export var brick_critical: Texture2D
@export var headquarters_texture: Texture2D
@export var headquarters_wreck: Texture2D
@export var headquarters_rect := Rect2(-56, -56, 112, 100)

func tile_texture(kind: String) -> Texture2D:
	match kind:
		"brick": return brick_texture
		"steel": return steel_texture
		"water": return water_texture
		"grass": return foliage_texture
	return floor_texture

func damage_texture(hp: int) -> Texture2D:
	if hp == 1:
		return brick_critical
	if hp == 2:
		return brick_damage
	return null

func base_texture(hp: int) -> Texture2D:
	return headquarters_wreck if hp <= 0 else headquarters_texture
