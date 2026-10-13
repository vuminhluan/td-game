extends Resource
@export var body: Resource
@export var weapon: Resource
@export var character_id = "robot"
@export var display_name = "Robot hai chân"
@export var collider_radius = 14.0
@export var max_hp = 5
@export var move_speed = 150.0
@export var socket = "roof"

func muzzle_vectors(direction: String) -> Array[Vector2]:
	if not weapon.explicit_muzzles.is_empty():
		var explicit: Array[Vector2] = []
		for point in weapon.explicit_muzzles[direction]:
			explicit.append(body.socket_for(socket, direction) + point)
		return explicit
	var vector: Vector2 = preload("res://gd/rules.gd").VECTOR[direction]
	var lateral = Vector2(-vector.y, vector.x)
	var origin: Vector2 = body.socket_for(socket, direction) + weapon.muzzle_offsets[direction]
	var result: Array[Vector2] = []
	for offset in weapon.barrel_offsets:
		result.append(origin + lateral * offset)
	return result
