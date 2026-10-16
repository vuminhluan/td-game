@tool
extends Marker2D

@export_enum("base", "enemy", "player", "player_two") var role := "enemy":
	set(value):
		role = value
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color := Color("e78654")
	if role == "base":
		color = Color("68d5dc")
	elif role == "player":
		color = Color("a8d488")
	elif role == "player_two":
		color = Color("87b9ee")
	draw_circle(Vector2.ZERO, 14, color, false, 2)
	draw_line(Vector2(-20, 0), Vector2(20, 0), color, 2)
	draw_line(Vector2(0, -20), Vector2(0, 20), color, 2)
	var label: String = {"base": "B", "enemy": "E", "player": "P1", "player_two": "P2"}.get(role, "?")
	draw_string(ThemeDB.fallback_font, Vector2(17, -10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
