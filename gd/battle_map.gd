extends RefCounted
const R = preload("res://gd/rules.gd")

static func create_map() -> Array:
	var grid: Array = []
	for y in R.ROWS:
		var row: Array = []
		for x in R.COLS:
			row.append({"kind": "floor", "hp": 0})
		grid.append(row)
	for x in [4, 12]:
		place(grid, "brick", x, 1, 5)
	for x in [4, 15]:
		for y in [3, 8, 12]:
			place(grid, "steel", x, y, 2, 2)
		for y in [5, 10, 14]:
			place(grid, "grass", x, y, 2)
	for x in [3, 17]:
		for y in [4, 9]:
			place(grid, "water", x, y, 1, 2)
	for x in [1, 19]:
		for y in [4, 8]:
			place(grid, "brick", x, y, 1, 2)
		place(grid, "brick", x, 13)
	place(grid, "brick", 8, 5, 1, 3)
	place(grid, "brick", 7, 5)
	place(grid, "brick", 12, 5, 1, 3)
	place(grid, "brick", 13, 5)
	for x in [8, 12]:
		place(grid, "grass", x, 9)
		place(grid, "brick", x, 10, 1, 2)
	for x in [7, 13]:
		place(grid, "brick", x, 11)
		place(grid, "brick", x, 14)
	for x in [6, 14]:
		place(grid, "brick", x, 16, 1, 2)
	for x in [4, 15]:
		place(grid, "brick", x, 17, 2)
	return grid

static func place(grid: Array, kind: String, x: int, y: int, w: int = 1, h: int = 1) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			grid[j][i] = {"kind": kind, "hp": 3 if kind == "brick" else 0}

static func tile_at(grid: Array, point: Vector2) -> Dictionary:
	var x = floori(point.x / R.TILE)
	var y = floori(point.y / R.TILE)
	if x < 0 or y < 0 or x >= R.COLS or y >= R.ROWS:
		return {}
	return grid[y][x]

static func can_occupy(grid: Array, point: Vector2, radius: float = 13) -> bool:
	for dx in [-radius, radius]:
		for dy in [-radius, radius]:
			var tile = tile_at(grid, point + Vector2(dx, dy))
			if tile.is_empty() or tile.kind in ["brick", "steel", "water"]:
				return false
	return true

# Dijkstra: brick costs 7; steel and water are never traversable.
static func find_path(grid: Array, start: Vector2i, goal: Vector2i) -> Array:
	var frontier: Array = [{"point": start, "cost": 0}]
	var costs = {start: 0}
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
			var tile = tile_at(grid, Vector2(next) * R.TILE)
			if tile.is_empty() or tile.kind in ["steel", "water"]:
				continue
			var cost: int = current.cost + (7 if tile.kind == "brick" else 1)
			if cost < costs.get(next, 1000000):
				costs[next] = cost
				parents[next] = point
				frontier.append({"point": next, "cost": cost})
	return []
