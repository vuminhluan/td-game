@tool
class_name MapObjectDefinition
extends Resource

@export var object_id := ""
@export var display_name := ""
@export var tags: Array[String] = []
@export var texture: Texture2D:
	set(value):
		texture = value
		emit_changed()
@export var visual_rect := Rect2(0, 0, 40, 40):
	set(value):
		visual_rect = value
		emit_changed()
@export_enum("decoration", "fixed", "destructible", "pickup") var category := "decoration":
	set(value):
		category = value
		emit_changed()
@export var flip_h := false:
	set(value):
		flip_h = value
		emit_changed()
@export var connections: Dictionary = {}
@export var footprint := Vector2i.ONE:
	set(value):
		footprint = value
		emit_changed()
@export var footprint_offset := Vector2i.ZERO:
	set(value):
		footprint_offset = value
		emit_changed()
@export var move_blocked := false
@export var bullet_blocked := false
@export var initial_hp := 3
@export var steel := false
@export var drop_settings: Resource
@export_enum("power_up", "weapon") var pickup_category := "power_up"
@export var pickup_id := ""

func connection_point(connection: String) -> Vector2:
	var point: Vector2 = connections.get(connection, Vector2.INF)
	if flip_h:
		point.x = visual_rect.get_center().x * 2 - point.x
	return point

func validate() -> Array[String]:
	var errors: Array[String] = []
	if object_id.strip_edges().is_empty():
		errors.append("Object definition requires an object_id.")
	if display_name.strip_edges().is_empty():
		errors.append("Object %s requires a display name." % object_id)
	if category not in ["decoration", "fixed", "destructible", "pickup"]:
		errors.append("Object %s has an invalid category." % object_id)
	if category in ["fixed", "destructible"] and (footprint.x <= 0 or footprint.y <= 0 or footprint.x > 1024 or footprint.y > 1024 or footprint.x * footprint.y > 262144):
		errors.append("Object %s requires a bounded positive footprint." % object_id)
	if category == "destructible" and initial_hp <= 0:
		errors.append("Object %s requires positive destruction HP." % object_id)
	if texture == null:
		errors.append("Object %s requires artwork." % object_id)
	if not visual_rect.position.is_finite() or not visual_rect.size.is_finite() or visual_rect.size.x <= 0 or visual_rect.size.y <= 0:
		errors.append("Object %s requires a positive finite visual rectangle." % object_id)
	for connection in connections:
		if not connections[connection] is Vector2 or not connections[connection].is_finite():
			errors.append("Object %s connection '%s' requires a finite point." % [object_id, connection])
	return errors
