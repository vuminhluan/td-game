extends RefCounted
const R = preload("res://gd/rules.gd")

static func create_map(scene: PackedScene = null) -> Array:
	var source: PackedScene = scene if scene != null else load("res://scenes/maps/industrial_yard.tscn")
	var instance = source.instantiate()
	var result: Dictionary = instance.build_runtime()
	var grid: Array = result.grid
	for object in result.objects:
		object.erase("node")
	instance.free()
	return grid

static func tile_at(grid: Array, point: Vector2) -> Dictionary:
	var x := floori(point.x / R.TILE)
	var y := floori(point.y / R.TILE)
	if y < 0 or y >= grid.size() or x < 0 or x >= grid[y].size():
		return {}
	return grid[y][x]

static func move_blocked(tile: Dictionary) -> bool:
	var object: Dictionary = tile.get("object", {})
	return tile.get("move_blocked", false) or (object.get("active", false) and object.get("move_blocked", false))

static func bullet_blocked(tile: Dictionary) -> bool:
	var object: Dictionary = tile.get("object", {})
	return tile.get("bullet_blocked", false) or (object.get("active", false) and object.get("bullet_blocked", false))

static func damage_target(tile: Dictionary) -> Dictionary:
	var object: Dictionary = tile.get("object", {})
	if object.get("active", false) and object.get("bullet_blocked", false):
		return object
	return tile

static func destructible(tile: Dictionary) -> bool:
	return damage_target(tile).get("destructible", false)

static func can_breach(tile: Dictionary) -> bool:
	if not move_blocked(tile):
		return false
	if tile.get("move_blocked", false) and not _shootable_obstacle(tile):
		return false
	var object: Dictionary = tile.get("object", {})
	if object.get("active", false) and object.get("move_blocked", false) and not _shootable_obstacle(object):
		return false
	return _shootable_obstacle(damage_target(tile))

static func _shootable_obstacle(obstacle: Dictionary) -> bool:
	return obstacle.get("destructible", false) and obstacle.get("bullet_blocked", false) and not obstacle.get("steel", false)

static func can_occupy(grid: Array, point: Vector2, radius: float = 13) -> bool:
	var start := Vector2i(floori((point.x - radius) / R.TILE), floori((point.y - radius) / R.TILE))
	var end := Vector2i(floori((point.x + radius) / R.TILE), floori((point.y + radius) / R.TILE))
	for y in range(start.y, end.y + 1):
		for x in range(start.x, end.x + 1):
			var tile := tile_at(grid, Vector2(x, y) * R.TILE)
			if tile.is_empty() or move_blocked(tile):
				return false
	return true

static func find_path(grid: Array, start: Vector2i, goal: Vector2i) -> Array:
	var frontier: Array = [{"point": start, "cost": 0}]
	var costs := {start: 0}
	var parents: Dictionary = {}
	while not frontier.is_empty():
		frontier.sort_custom(func(a, b): return a.cost < b.cost)
		var current: Dictionary = frontier.pop_front()
		var point: Vector2i = current.point
		if current.cost != costs.get(point):
			continue
		if point == goal:
			var path: Array = []
			while point != start:
				path.push_front(point)
				point = parents[point]
			return path
		for direction in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			var next: Vector2i = point + direction
			var tile := tile_at(grid, Vector2(next) * R.TILE)
			if tile.is_empty() or (move_blocked(tile) and not can_breach(tile)):
				continue
			var cost: int = current.cost + (7 if move_blocked(tile) else 1)
			if cost < costs.get(next, 1000000):
				costs[next] = cost
				parents[next] = point
				frontier.append({"point": next, "cost": cost})
	return []
