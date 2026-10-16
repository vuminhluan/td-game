extends CanvasLayer

const PowerUpHUD = preload("res://gd/power_up_hud.gd")
var sim: RefCounted
var player_index := 0
var status_label: Label
var powers: Control

func _ready() -> void:
	status_label = Label.new()
	status_label.position = Vector2(8, 8)
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color("d8efcd") if player_index == 0 else Color("9dddf4"))
	status_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	status_label.add_theme_constant_override("shadow_offset_x", 1)
	status_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(status_label)
	powers = PowerUpHUD.new()
	powers.player_index = player_index
	powers.position = Vector2(6, 48)
	powers.size = Vector2(190, 38)
	add_child(powers)

func refresh(value: RefCounted, enabled: bool) -> void:
	sim = value
	visible = enabled and sim != null and player_index < sim.players.size()
	if not visible:
		return
	var state: Dictionary = sim.players[player_index]
	status_label.text = "P%d · HP %d/%d · Mạng %d\n%s" % [player_index + 1, maxi(0, state.actor.hp), state.actor.max_hp, state.lives, state.loadout.weapon.display_name]
	if state.lives <= 0:
		status_label.text = "P%d · HẾT MẠNG\nĐồng đội tiếp tục bảo vệ căn cứ" % (player_index + 1)
	powers.sim = sim
	powers.queue_redraw()
