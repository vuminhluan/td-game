extends Node2D
const R = preload("res://gd/rules.gd")
const MapSkin = preload("res://gd/map_skin.gd")
var sim: RefCounted
var skin: MapSkin

func _draw() -> void:
	if sim == null or skin == null:
		return
	for y in sim.map.size():
		for x in sim.map[y].size():
			var tile: Dictionary = sim.map[y][x]
			var rect := Rect2(Vector2(x, y) * R.TILE, Vector2.ONE * R.TILE)
			if tile.kind == "brick" and tile.hp > 0:
				var damage := skin.damage_texture(tile.hp)
				if damage != null:
					draw_texture_rect(damage, rect, false)
			elif tile.kind == "water":
				_draw_water_edges(x, y, rect)
	var base_rect := Rect2(sim.base_position + skin.headquarters_rect.position, skin.headquarters_rect.size)
	var texture := skin.base_texture(sim.base_hp)
	if texture != null:
		draw_texture_rect(texture, base_rect, false)
	var bar := Rect2(sim.base_position + Vector2(-22, 38), Vector2(44, 4))
	draw_rect(bar.grow(1), Color("101719"))
	var health_color := Color("8dc6b8") if sim.base_hp > R.BASE_HP / 2 else Color("e98450")
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(float(sim.base_hp) / R.BASE_HP, 0, 1), bar.size.y)), health_color)

func _draw_water_edges(x: int, y: int, rect: Rect2) -> void:
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var corners := [rect.position, rect.position + Vector2(R.TILE, 0), rect.end, rect.position + Vector2(0, R.TILE)]
	for i in 4:
		var neighbor: Vector2i = Vector2i(x, y) + directions[i]
		if neighbor.x < 0 or neighbor.y < 0 or neighbor.y >= sim.map.size() or neighbor.x >= sim.map[neighbor.y].size() or sim.map[neighbor.y][neighbor.x].kind != "water":
			draw_line(corners[i], corners[(i + 1) % 4], Color("6c7973"), 2)
