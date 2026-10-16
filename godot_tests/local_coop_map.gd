extends SceneTree

const Marker = preload("res://gd/map_marker.gd")
const Map = preload("res://gd/battle_map.gd")
const INDUSTRIAL = preload("res://scenes/maps/industrial_yard.tscn")
const CITY = preload("res://scenes/maps/abandoned_city.tscn")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func has_error(runtime: Dictionary, text: String) -> bool:
	for error in runtime.errors:
		if text in error:
			return true
	return false

func add_marker(scene: Node2D, point: Vector2) -> Marker2D:
	var marker := Marker.new()
	marker.role = "player_two"
	marker.position = point
	scene.add_child(marker)
	return marker

func valid_spawn(runtime: Dictionary) -> Vector2:
	for y in runtime.grid.size():
		for x in runtime.grid[y].size():
			var point := (Vector2(x, y) + Vector2.ONE * 0.5) * 40
			if Map.can_occupy(runtime.grid, point) and point.distance_to(runtime.base_position) > 60 and point.distance_to(runtime.player_position) >= 40:
				return point
	return Vector2.INF

func run() -> void:
	for source in [INDUSTRIAL, CITY]:
		var scene: Node2D = source.instantiate()
		var initial: Dictionary = scene.build_runtime()
		check(initial.errors.is_empty(), "existing map validates without an optional P2 marker")
		check(initial.player_two_position == Vector2.INF, "absent P2 marker explicitly requests simulation fallback")
		var point := valid_spawn(initial)
		check(point != Vector2.INF, "authored map has valid space for a P2 marker")
		var marker := add_marker(scene, point)
		var runtime: Dictionary = scene.build_runtime()
		check(runtime.errors.is_empty() and runtime.player_two_position == point, "valid P2 marker becomes runtime spawn")
		check(runtime.player_position == initial.player_position, "P2 marker leaves the single-player spawn unchanged")
		var duplicate := add_marker(scene, point + Vector2(40, 0))
		check(has_error(scene.build_runtime(), "at most one player_two marker"), "duplicate P2 markers are rejected")
		duplicate.free()
		marker.position = initial.player_position + Vector2(20, 20)
		check(has_error(scene.build_runtime(), "overlaps the player spawn"), "diagonal P2 collider overlap with P1 is rejected")
		marker.position = initial.base_position
		check(has_error(scene.build_runtime(), "overlaps the base gameplay area"), "P2 marker cannot overlap the base")
		marker.position = Vector2(-40, 100)
		check(has_error(scene.build_runtime(), "player_two marker") and has_error(scene.build_runtime(), "traversable space"), "P2 marker cannot lie outside the map")
		marker.position = point
		marker.role = "unrecognized"
		check(has_error(scene.build_runtime(), "invalid role"), "unrecognized marker roles stay invalid")
		marker.role = "player_two"
		scene.dimensions = Vector2i.ZERO
		runtime = scene.build_runtime()
		check(not runtime.errors.is_empty() and runtime.player_two_position == Vector2.INF, "invalid map dimensions still provide a safe optional P2 spawn value")
		scene.free()
	var blocked_scene: Node2D = INDUSTRIAL.instantiate()
	var blocked_runtime: Dictionary = blocked_scene.build_runtime()
	var blocked := Vector2.INF
	for y in blocked_runtime.grid.size():
		for x in blocked_runtime.grid[y].size():
			if Map.move_blocked(blocked_runtime.grid[y][x]):
				blocked = (Vector2(x, y) + Vector2.ONE * 0.5) * 40
				break
		if blocked != Vector2.INF:
			break
	check(blocked != Vector2.INF, "industrial map includes blocked terrain for spawn validation")
	add_marker(blocked_scene, blocked)
	check(has_error(blocked_scene.build_runtime(), "player_two marker"), "P2 marker cannot occupy blocked terrain or object footprints")
	blocked_scene.free()
	print("LOCAL COOP MAP: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
