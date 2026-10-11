extends Node2D
const R = preload("res://gd/rules.gd")
const MapSkin = preload("res://gd/map_skin.gd")
var sim: RefCounted
var skin: MapSkin
var revision := -1
var base_hp := -1

func sync(value: RefCounted, appearance: MapSkin) -> void:
	if value != sim or appearance != skin or (value != null and (value.revision != revision or value.base_hp != base_hp)):
		sim = value
		skin = appearance
		revision = value.revision if value != null else -1
		base_hp = value.base_hp if value != null else -1
		queue_redraw()

func _draw() -> void:
	if sim == null or skin == null:
		return
	draw_texture_rect(skin.floor_texture, Rect2(0, 0, R.WIDTH, R.HEIGHT), true, skin.floor_tint)
	for y in R.ROWS:
		for x in R.COLS:
			var rect := Rect2(Vector2(x, y) * R.TILE, Vector2.ONE * R.TILE)
			var tile: Dictionary = sim.map[y][x]
			if tile.kind in ["floor", "grass"]:
				continue
			draw_texture_rect(skin.tile_texture(tile.kind), rect, false)
			if tile.kind == "brick":
				var damage: Texture2D = skin.damage_texture(tile.hp)
				if damage != null:
					draw_texture_rect(damage, rect, false)
			elif tile.kind == "water":
				draw_water_edges(x, y, rect)
	var base_rect := Rect2(R.BASE + skin.headquarters_rect.position, skin.headquarters_rect.size)
	draw_texture_rect(skin.base_texture(base_hp), base_rect, false)
	var bar := Rect2(R.BASE + Vector2(-22, 38), Vector2(44, 4))
	draw_rect(bar.grow(1), Color("101719"))
	var health_color := Color("8dc6b8") if base_hp > R.BASE_HP / 2 else Color("e98450")
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(float(base_hp) / R.BASE_HP, 0, 1), bar.size.y)), health_color)

func draw_water_edges(x: int, y: int, rect: Rect2) -> void:
	var directions := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var corners := [rect.position, rect.position + Vector2(R.TILE, 0), rect.end, rect.position + Vector2(0, R.TILE)]
	for i in 4:
		var neighbor: Vector2i = Vector2i(x, y) + directions[i]
		if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= R.COLS or neighbor.y >= R.ROWS or sim.map[neighbor.y][neighbor.x].kind != "water":
			draw_line(corners[i], corners[(i + 1) % 4], Color("6c7973"), 2)
