extends Control
const R = preload("res://gd/rules.gd")
const Icons = preload("res://gd/power_up_icons.gd")
var sim: RefCounted
var player_index := 0

func _draw() -> void:
	if sim == null:
		return
	var index = 0
	for kind in preload("res://gd/pickup_settings.gd").POWER_UP_IDS:
		if not sim.power_up_active(kind, player_index):
			continue
		var point = Vector2(19 + index * 38, 19)
		Icons.draw_icon(self, kind, point, 13)
		draw_arc(point, 17, -PI / 2, -PI / 2 + TAU * clampf(remaining(kind) / R.POWER_UP_DURATION, 0, 1), 48, Icons.COLORS[kind], 2.5, true)
		index += 1

func _get_tooltip(at_position: Vector2) -> String:
	if sim == null:
		return ""
	var index = floori(at_position.x / 38.0)
	var active: Array = []
	for kind in preload("res://gd/pickup_settings.gd").POWER_UP_IDS:
		if sim.power_up_active(kind, player_index):
			active.append(kind)
	if index < 0 or index >= active.size():
		return ""
	var kind: String = active[index]
	return "%s · %.1f giây" % [Icons.NAMES[kind], remaining(kind)]

func remaining(kind: String) -> float:
	if kind == "base_shield":
		var duration = 0.0
		for state in sim.players:
			duration = maxf(duration, state.active_power_ups.get(kind, 0.0))
		return duration
	return sim.players[player_index].active_power_ups.get(kind, 0.0)
