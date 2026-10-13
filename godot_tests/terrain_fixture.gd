extends RefCounted

const TILE_SET = preload("res://assets/maps/industrial/terrain.tres")
static var templates: Dictionary = {}

static func tile(kind: String, hp: int = -1) -> Dictionary:
	if templates.is_empty():
		for source_index in TILE_SET.get_source_count():
			var source_id := TILE_SET.get_source_id(source_index)
			var source := TILE_SET.get_source(source_id) as TileSetAtlasSource
			if source == null:
				continue
			for tile_index in source.get_tiles_count():
				var coords := source.get_tile_id(tile_index)
				var data := source.get_tile_data(coords, 0)
				var template := {"source_id": source_id, "atlas_coords": coords, "alternative_tile": 0}
				for key in ["kind", "hp", "move_blocked", "bullet_blocked", "destructible", "steel"]:
					template[key] = data.get_custom_data(key)
				template.max_hp = template.hp
				templates[template.kind] = template
	var result: Dictionary = templates[kind].duplicate(true)
	if hp >= 0:
		result.hp = hp
		result.max_hp = hp
	return result

static func apply(cell: Dictionary, kind: String, hp: int = -1) -> void:
	cell.clear()
	cell.merge(tile(kind, hp))
