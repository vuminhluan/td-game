extends RefCounted
const COLORS = {"shield": Color("72e6eb"), "rapid_fire": Color("ffb85c"), "speed_boost": Color("b6ed72"), "double_shot": Color("e5a2fa"), "base_shield": Color("82b5ff")}
const NAMES = {"shield": "Khiên robot", "rapid_fire": "Bắn nhanh", "speed_boost": "Tăng tốc", "double_shot": "Đạn đôi", "base_shield": "Khiên căn cứ"}

static func draw_icon(canvas: CanvasItem, kind: String, point: Vector2, radius: float = 14.0) -> void:
	var color: Color = COLORS[kind]
	canvas.draw_circle(point + Vector2(0, 2), radius + 2, Color("101719"))
	canvas.draw_circle(point, radius, Color("1b3039"))
	canvas.draw_arc(point, radius, 0, TAU, 32, color, 1.5, true)
	var scale = radius / 14.0
	canvas.draw_set_transform(point, 0, Vector2.ONE * scale)
	match kind:
		"shield", "base_shield":
			canvas.draw_polyline(PackedVector2Array([Vector2(-7, -7), Vector2(0, -9), Vector2(7, -7), Vector2(6, 2), Vector2(0, 8), Vector2(-6, 2), Vector2(-7, -7)]), color, 2, true)
			if kind == "base_shield":
				canvas.draw_rect(Rect2(-3, -2, 6, 6), color, false, 1.5)
		"rapid_fire":
			canvas.draw_polyline(PackedVector2Array([Vector2(3, -9), Vector2(-5, 1), Vector2(1, 1), Vector2(-3, 9), Vector2(6, -2), Vector2(0, -2)]), color, 2, true)
		"double_shot":
			for x in [-4, 4]:
				canvas.draw_line(Vector2(x, 7), Vector2(x, -5), color, 3, true)
				canvas.draw_line(Vector2(x - 2, -3), Vector2(x, -7), color, 2, true)
		"speed_boost":
			for x in [-5, 2]:
				canvas.draw_polyline(PackedVector2Array([Vector2(x - 2, -7), Vector2(x + 3, 0), Vector2(x - 2, 7)]), color, 2, true)
	canvas.draw_set_transform(Vector2.ZERO)
