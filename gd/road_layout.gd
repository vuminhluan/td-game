@tool
extends Node2D

@export var road_rect := Rect2(180, 0, 480, 760):
	set(value):
		road_rect = value
		queue_redraw()
@export var intersection_rect := Rect2(0, 300, 840, 160):
	set(value):
		intersection_rect = value
		queue_redraw()
@export_range(2, 12, 2) var lane_count := 6:
	set(value):
		lane_count = value
		queue_redraw()
@export var sidewalk_width := 60.0:
	set(value):
		sidewalk_width = value
		queue_redraw()
@export var sidewalk_texture: Texture2D:
	set(value):
		sidewalk_texture = value
		queue_redraw()
@export var marking_color := Color("c4bca1"):
	set(value):
		marking_color = value
		queue_redraw()
@export var center_color := Color("c99c48"):
	set(value):
		center_color = value
		queue_redraw()
@export var curb_color := Color("aaa390"):
	set(value):
		curb_color = value
		queue_redraw()

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	if lane_count < 2 or road_rect.size.x <= 0 or road_rect.size.y <= 0:
		return
	var north := Rect2(intersection_rect.position.x, road_rect.position.y, intersection_rect.size.x, intersection_rect.position.y - road_rect.position.y)
	var south := Rect2(intersection_rect.position.x, intersection_rect.end.y, intersection_rect.size.x, road_rect.end.y - intersection_rect.end.y)
	for block in [north, south]:
		for side in 2:
			var left := intersection_rect.position.x if side == 0 else road_rect.end.x
			var right := road_rect.position.x if side == 0 else intersection_rect.end.x
			_draw_sidewalk(Rect2(left, block.position.y, right - left, block.size.y))
			var curb_x := road_rect.position.x if side == 0 else road_rect.end.x
			draw_line(Vector2(curb_x, block.position.y), Vector2(curb_x, block.end.y), curb_color, 4)
			var corner_left := road_rect.position.x - sidewalk_width if side == 0 else road_rect.end.x
			var corner_right := road_rect.position.x if side == 0 else road_rect.end.x + sidewalk_width
			var corner_y: float = block.end.y if block == north else block.position.y
			draw_line(Vector2(intersection_rect.position.x if side == 0 else corner_right, corner_y), Vector2(corner_left if side == 0 else intersection_rect.end.x, corner_y), curb_color, 4)
		for lane in range(1, lane_count):
			var x := road_rect.position.x + road_rect.size.x * lane / lane_count
			if lane == lane_count / 2:
				for offset in [-3.0, 3.0]:
					draw_line(Vector2(x + offset, block.position.y), Vector2(x + offset, block.end.y), center_color, 2)
			else:
				for y in range(int(block.position.y) + 12, int(block.end.y) - 12, 58):
					draw_line(Vector2(x, y), Vector2(x, minf(y + 28, block.end.y - 12)), marking_color, 3)
		var crossing_y: float = north.end.y - 34 if block == north else south.position.y + 12
		for x in range(int(road_rect.position.x) + 12, int(road_rect.end.x) - 12, 22):
			draw_rect(Rect2(x, crossing_y, 10, 22), marking_color)
	for side in 2:
		var crossing_x := road_rect.position.x - 34 if side == 0 else road_rect.end.x + 12
		for y in range(int(intersection_rect.position.y) + 12, int(intersection_rect.end.y) - 12, 22):
			draw_rect(Rect2(crossing_x, y, 22, 10), marking_color)
		var start_x := intersection_rect.position.x if side == 0 else road_rect.end.x + 40
		var end_x := road_rect.position.x - 40 if side == 0 else intersection_rect.end.x
		for offset in [-3.0, 3.0]:
			draw_line(Vector2(start_x, intersection_rect.get_center().y + offset), Vector2(end_x, intersection_rect.get_center().y + offset), center_color, 2)

func _draw_sidewalk(rect: Rect2) -> void:
	if rect.size.x <= 0 or rect.size.y <= 0:
		return
	draw_rect(rect, Color("777468"))
	if sidewalk_texture == null:
		return
	for y in range(int(rect.position.y), int(rect.end.y), 60):
		for x in range(int(rect.position.x), int(rect.end.x), 60):
			var size := Vector2(minf(60, rect.end.x - x), minf(60, rect.end.y - y))
			var region := Rect2(Vector2.ZERO, sidewalk_texture.get_size() * size / 60)
			draw_texture_rect_region(sidewalk_texture, Rect2(Vector2(x, y), size), region, Color(0.86, 0.83, 0.74))
