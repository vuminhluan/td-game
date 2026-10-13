@tool
class_name MapObjectCatalog
extends Resource

const Definition = preload("res://gd/map_object_definition.gd")

@export var objects: Array[Definition] = []

func validate() -> Array[String]:
	var errors: Array[String] = []
	var ids: Dictionary = {}
	for definition in objects:
		if definition == null:
			errors.append("Object catalog contains an empty entry.")
			continue
		errors.append_array(definition.validate())
		if ids.has(definition.object_id):
			errors.append("Object catalog has duplicate ID: " + definition.object_id)
		ids[definition.object_id] = true
	return errors

func find(object_id: String) -> Definition:
	for definition in objects:
		if definition != null and definition.object_id == object_id:
			return definition
	return null
