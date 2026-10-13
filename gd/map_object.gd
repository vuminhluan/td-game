@tool
extends Node2D

const R = preload("res://gd/rules.gd")
const Definition = preload("res://gd/map_object_definition.gd")
@export var definition: Definition:
	set(value):
		if definition != null and definition.changed.is_connected(_definition_changed):
			definition.changed.disconnect(_definition_changed)
		definition = value
		if definition != null:
			definition.changed.connect(_definition_changed)
		notify_property_list_changed()
		_definition_changed()
@export_group("Standalone configuration")
@export_enum("decoration", "fixed", "destructible", "pickup") var category := "decoration"
@export var footprint := Vector2i.ONE
@export var footprint_offset := Vector2i.ZERO
@export var move_blocked := true
@export var bullet_blocked := true
@export var initial_hp := 3
@export var steel := false
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()
@export var visual_rect := Rect2(0, 0, 40, 40):
	set(value):
		visual_rect = value
		queue_redraw()
@export var drop_settings: Resource
@export_enum("power_up", "weapon") var pickup_category := "power_up"
@export var pickup_id := ""

func _validate_property(property: Dictionary) -> void:
	if definition != null and property.name in ["category", "footprint", "footprint_offset", "move_blocked", "bullet_blocked", "initial_hp", "steel", "texture", "visual_rect", "drop_settings", "pickup_category", "pickup_id"]:
		property.usage = property.usage & ~PROPERTY_USAGE_EDITOR

func _definition_changed() -> void:
	queue_redraw()
	if is_inside_tree():
		update_configuration_warnings()

func configuration() -> Object:
	return definition if definition != null else self

func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(definition.validate()) if definition != null else PackedStringArray()

func runtime_data(identifier: int, map_position: Vector2) -> Dictionary:
	var config: Object = configuration()
	var cells: Array[Vector2i] = []
	var footprint_size: Vector2i = config.footprint
	if config.category in ["fixed", "destructible"] and footprint_size.x > 0 and footprint_size.y > 0 and footprint_size.x <= 1024 and footprint_size.y <= 1024 and footprint_size.x * footprint_size.y <= 262144:
		var origin := Vector2i(floori(map_position.x / R.TILE), floori(map_position.y / R.TILE)) + Vector2i(config.footprint_offset)
		for y in footprint_size.y:
			for x in footprint_size.x:
				cells.append(origin + Vector2i(x, y))
	return {"id": identifier, "node": self, "pos": map_position, "category": config.category,
		"definition": definition, "footprint": footprint_size,
		"footprint_cells": cells, "hp": config.initial_hp, "max_hp": config.initial_hp,
		"move_blocked": config.move_blocked and config.category in ["fixed", "destructible"],
		"bullet_blocked": config.bullet_blocked and config.category in ["fixed", "destructible"],
		"destructible": config.category == "destructible", "steel": config.steel, "active": true,
		"drop_settings": config.drop_settings, "pickup_category": config.pickup_category, "pickup_id": config.pickup_id}

func _draw() -> void:
	var config: Object = configuration()
	if config.texture != null:
		draw_texture_rect(config.texture, config.visual_rect, false)
	if Engine.is_editor_hint() and config.category in ["fixed", "destructible"]:
		var origin := Vector2(config.footprint_offset) * R.TILE - Vector2(fposmod(global_position.x, R.TILE), fposmod(global_position.y, R.TILE))
		draw_rect(Rect2(origin, Vector2(config.footprint) * R.TILE), Color(1, 0.65, 0.3, 0.7), false, 2)
