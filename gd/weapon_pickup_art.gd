extends RefCounted

const TEXTURE = preload("res://assets/sprites/characters/layers.png")
const MANIFEST_PATH = "res://assets/sprites/characters/manifest.json"
var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
var textures: Dictionary = {}

func texture_for(weapon_id: String, character_id: String, catalog: RefCounted) -> Texture2D:
	var artwork_id: String = catalog.data.characters.get(character_id, {}).get("weapon_art", {}).get(weapon_id, "")
	if artwork_id.is_empty():
		for character in catalog.data.characters.values():
			if character.weapon_art.has(weapon_id):
				artwork_id = character.weapon_art[weapon_id]
				break
	if artwork_id.is_empty() or not metadata.layers.has(artwork_id):
		return null
	if textures.has(artwork_id):
		return textures[artwork_id]
	var region: Array = metadata.layers[artwork_id].directions.right.region
	var source_rect := Rect2i(region[0], region[1], region[2], region[3])
	var visible_rect := TEXTURE.get_image().get_region(source_rect).get_used_rect()
	if not visible_rect.has_area():
		return null
	var texture := AtlasTexture.new()
	texture.atlas = TEXTURE
	texture.region = Rect2(source_rect.position + visible_rect.position, visible_rect.size)
	texture.filter_clip = true
	textures[artwork_id] = texture
	return texture

func rect_for(texture: Texture2D, point: Vector2, maximum_size := Vector2(36, 28)) -> Rect2:
	var source_size := texture.get_size()
	var ratio := minf(maximum_size.x / source_size.x, maximum_size.y / source_size.y)
	var size := source_size * ratio
	return Rect2(point - size / 2, size)
