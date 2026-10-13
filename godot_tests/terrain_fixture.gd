extends RefCounted

const Map = preload("res://gd/battle_map.gd")
static var templates: Dictionary = {}

static func tile(kind: String, hp: int = -1) -> Dictionary:
	if templates.is_empty():
		for row in Map.create_map():
			for cell in row:
				if not templates.has(cell.kind):
					var template: Dictionary = cell.duplicate(true)
					template.erase("object")
					templates[cell.kind] = template
	var result: Dictionary = templates[kind].duplicate(true)
	if hp >= 0:
		result.hp = hp
		result.max_hp = hp
	return result

static func apply(cell: Dictionary, kind: String, hp: int = -1) -> void:
	cell.clear()
	cell.merge(tile(kind, hp))
