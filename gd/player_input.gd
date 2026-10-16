extends RefCounted

var directions: Dictionary
var fire_key: int
var held: Array = []
var shooting := false

func _init(bindings: Dictionary = {}, trigger: int = KEY_SPACE) -> void:
	directions = bindings
	fire_key = trigger

func handle_key(key: int, pressed: bool) -> void:
	if key == fire_key:
		shooting = pressed
	if directions.has(key):
		held.erase(key)
		if pressed:
			held.append(key)

func command() -> Dictionary:
	return {"direction": directions[held.back()] if not held.is_empty() else "", "shooting": shooting}

func clear() -> void:
	held.clear()
	shooting = false
