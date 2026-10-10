extends Control
const Sim = preload("res://gd/simulation.gd")
const View = preload("res://gd/battle_view.gd")
const R = preload("res://gd/rules.gd")
const KEY_DIRECTIONS = {KEY_W: "up", KEY_UP: "up", KEY_D: "right", KEY_RIGHT: "right", KEY_S: "down", KEY_DOWN: "down", KEY_A: "left", KEY_LEFT: "left"}
var sim = Sim.new()
var battle: Node2D
var labels: Dictionary = {}
var start_button: Button
var pause_button: Button
var sound_button: Button
var overlay: Panel
var overlay_title: Label
var overlay_copy: Label
var held_keys: Array = []
var pointers: Dictionary = {}
var keyboard_fire = false
var board_rect = Rect2()
var touch_rects: Dictionary = {}
var mobile = false
var audio: AudioStreamPlayer
var sound_enabled = false
var last_shots = 0
var last_status = ""
var radar_rect = Rect2()

func _ready() -> void:
	var theme_resource = Theme.new()
	theme_resource.default_font_size = 14
	theme = theme_resource
	battle = View.new()
	battle.sim = sim
	add_child(battle)
	for id in ["brand", "sector", "heading", "field", "clock", "message", "stats", "help", "campaign", "enemies", "score", "robot", "base", "radar", "footer"]:
		var label = Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Color("c4ceca"))
		add_child(label)
		labels[id] = label
	labels.brand.text = "ROBOT / DEFENSE"
	labels.brand.add_theme_font_size_override("font_size", 23)
	labels.brand.add_theme_color_override("font_color", Color("e98450"))
	labels.sector.text = "KHU VỰC 07 / KHU CÔNG NGHIỆP"
	labels.heading.text = "Giữ vững phòng tuyến."
	labels.heading.add_theme_font_size_override("font_size", 30)
	labels.help.text = "WASD / ↑↓←→: di chuyển    SPACE: bắn    P / ESC: tạm dừng\nGạch: 3 phát · Thép: bất hoại · Nước: chặn đường · Cây: đi xuyên"
	labels.footer.text = "ROBOT DEFENSE / GODOT     •     MỘT ROBOT. MỘT CĂN CỨ. GIỮ ĐẾN CÙNG."
	pause_button = make_button("TẠM DỪNG [P]", toggle_pause)
	sound_button = make_button("ÂM THANH: TẮT", toggle_sound)
	overlay = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.085, 0.095, 0.96)
	style.border_color = Color("56635a")
	style.set_border_width_all(1)
	overlay.add_theme_stylebox_override("panel", style)
	add_child(overlay)
	overlay_title = Label.new()
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 28)
	overlay.add_child(overlay_title)
	overlay_copy = Label.new()
	overlay_copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay.add_child(overlay_copy)
	start_button = make_button("TRIỂN KHAI ROBOT →", activate, overlay)
	audio = AudioStreamPlayer.new()
	add_child(audio)
	audio.stream = shot_sound()
	audio.volume_db = -24
	resized.connect(layout)
	get_window().focus_exited.connect(focus_lost)
	layout()
	refresh_hud()

func make_button(text: String, callback: Callable, parent: Node = self) -> Button:
	var button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	var style = StyleBoxFlat.new()
	style.bg_color = Color("303d3d")
	style.border_color = Color("657365")
	style.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", style)
	var hover = style.duplicate()
	hover.bg_color = Color("5d4935")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	parent.add_child(button)
	button.pressed.connect(callback)
	return button

func put(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func layout() -> void:
	if battle == null:
		return
	mobile = size.x < 850
	var margin = 12.0 if mobile else 28.0
	put(labels.brand, Rect2(margin, 10, 260, 34))
	put(sound_button, Rect2(size.x - margin - 140, 52 if mobile else 16, 140, 32))
	put(pause_button, Rect2(margin if mobile else size.x - margin - 296, 52 if mobile else 16, 140, 32))
	put(labels.sector, Rect2(margin, 96 if mobile else 76, size.x - 2 * margin, 24))
	put(labels.heading, Rect2(margin, 120 if mobile else 100, size.x - 2 * margin, 42))
	labels.heading.add_theme_font_size_override("font_size", 24 if mobile else 30)
	var top = 240.0 if mobile else 176.0
	var available = Vector2(size.x - margin * 2 - (0 if mobile else 280), size.y - top - (154 if mobile else 104))
	var factor = maxf(0.05, minf(available.x / R.WIDTH, available.y / R.HEIGHT))
	var dimensions = Vector2(R.WIDTH, R.HEIGHT) * factor
	board_rect = Rect2(Vector2(margin + (available.x - dimensions.x) / 2, top), dimensions)
	battle.position = board_rect.position
	battle.scale = Vector2.ONE * factor
	put(labels.field, Rect2(board_rect.position.x, top - 28, 230, 24))
	put(labels.clock, Rect2(board_rect.end.x - 52, top - 28, 52, 24))
	put(labels.message, Rect2(margin, board_rect.end.y + 6, size.x - margin * 2, 24))
	labels.stats.visible = mobile
	put(labels.stats, Rect2(margin, 166, size.x - 2 * margin, 50))
	labels.stats.add_theme_font_size_override("font_size", 13)
	for id in ["campaign", "enemies", "score", "robot", "base", "radar"]:
		labels[id].visible = not mobile
	radar_rect = Rect2()
	if not mobile:
		var side = size.x - margin - 252
		var compact = size.y < 900
		put(labels.campaign, Rect2(side, top, 252, 80))
		labels.campaign.add_theme_font_size_override("font_size", 25)
		put(labels.enemies, Rect2(side, top + (80 if compact else 94), 252, 50))
		put(labels.score, Rect2(side, top + (130 if compact else 158), 252, 50))
		put(labels.robot, Rect2(side, top + (180 if compact else 222), 252, 72))
		put(labels.base, Rect2(side, top + (268 if compact else 328), 252, 60))
		put(labels.radar, Rect2(side, top + (348 if compact else 412), 252, 24))
		labels.radar.text = "BẢN ĐỒ CHIẾN THUẬT"
		var radar_top = top + (376 if compact else 446)
		var radar_scale = clampf((size.y - 84 - radar_top) / 190.0, 0, 1)
		radar_rect = Rect2(side, radar_top, 210 * radar_scale, 190 * radar_scale)
	labels.help.visible = not mobile
	labels.footer.visible = not mobile
	put(labels.help, Rect2(margin, size.y - 76, size.x - 2 * margin, 48))
	put(labels.footer, Rect2(margin, size.y - 28, size.x - 2 * margin, 24))
	touch_rects.clear()
	if mobile:
		var y = board_rect.end.y + 38
		var edge = 44.0
		var x = margin + 10
		touch_rects.up = Rect2(x + edge + 4, y, edge, edge)
		touch_rects.left = Rect2(x, y + edge + 4, edge, edge)
		touch_rects.down = Rect2(x + edge + 4, y + edge + 4, edge, edge)
		touch_rects.right = Rect2(x + 2 * (edge + 4), y + edge + 4, edge, edge)
		touch_rects.fire = Rect2(size.x - margin - 98, y + 20, 98, 68)
	var overlay_width = minf(430, board_rect.size.x - 12)
	var overlay_height = minf(238, board_rect.size.y - 12)
	put(overlay, Rect2(board_rect.get_center() - Vector2(overlay_width, overlay_height) / 2, Vector2(overlay_width, overlay_height)))
	put(overlay_title, Rect2(8, 16, overlay_width - 16, 42))
	overlay_title.add_theme_font_size_override("font_size", (16 if overlay_width < 240 else 22) if mobile else 28)
	overlay_copy.add_theme_font_size_override("font_size", 12 if overlay_width < 240 else 14)
	put(overlay_copy, Rect2(16, 62, overlay_width - 32, maxf(40, overlay_height - 130)))
	put(start_button, Rect2(16, overlay_height - 54, overlay_width - 32, 40))
	clear_inputs()
	queue_redraw()

func activate() -> void:
	clear_inputs()
	if sim.status == "ready":
		sim.start()
	elif sim.status == "paused":
		sim.pause()
	else:
		sim = Sim.new()
		battle.sim = sim
		sim.start()
		last_shots = 0
	refresh_hud()

func toggle_pause() -> void:
	sim.pause()
	clear_inputs()
	refresh_hud()

func toggle_sound() -> void:
	sound_enabled = not sound_enabled
	sound_button.text = "ÂM THANH: " + ("BẬT" if sound_enabled else "TẮT")

func clear_inputs() -> void:
	held_keys.clear()
	pointers.clear()
	keyboard_fire = false

func focus_lost() -> void:
	clear_inputs()
	if sim.status == "playing":
		sim.pause()
	refresh_hud()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT] and is_node_ready():
		focus_lost()

func pointer_action(point: Vector2) -> String:
	for action in touch_rects:
		if touch_rects[action].has_point(point):
			return action
	return ""

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.echo:
			return
		var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if key in [KEY_P, KEY_ESCAPE] and event.pressed:
			toggle_pause()
		elif key == KEY_SPACE:
			keyboard_fire = event.pressed
		elif KEY_DIRECTIONS.has(key):
			held_keys.erase(key)
			if event.pressed:
				held_keys.append(key)
	elif event is InputEventScreenTouch:
		if event.pressed:
			pointers[event.index] = pointer_action(event.position)
		else:
			pointers.erase(event.index)
	elif event is InputEventScreenDrag:
		if pointers.has(event.index):
			pointers[event.index] = pointer_action(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.pressed:
			pointers[-1] = pointer_action(event.position)
		else:
			pointers.erase(-1)

func input_direction() -> String:
	var direction = KEY_DIRECTIONS[held_keys.back()] if not held_keys.is_empty() else ""
	for action in pointers.values():
		if R.VECTOR.has(action):
			direction = action
	return direction

func _process(dt: float) -> void:
	sim.update(dt, input_direction(), keyboard_fire or "fire" in pointers.values())
	if sound_enabled and sim.shots_fired > last_shots:
		audio.play()
	last_shots = sim.shots_fired
	refresh_hud()
	battle.queue_redraw()
	queue_redraw()

func refresh_hud() -> void:
	if labels.is_empty():
		return
	var base_percent = maxi(0, sim.base_hp) * 5
	labels.clock.text = "%02d:%02d" % [floori(sim.elapsed / 60), int(sim.elapsed) % 60]
	labels.field.text = {"ready": "● CHỜ TRIỂN KHAI", "playing": "● ĐANG GIAO TRANH", "paused": "● TẠM DỪNG", "won": "● HOÀN THÀNH", "lost": "● THẤT THỦ"}[sim.status]
	labels.message.text = sim.message
	labels.campaign.text = "CHIẾN DỊCH\n%02d / 05" % maxi(1, sim.wave)
	labels.enemies.text = "ĐỊCH CÒN LẠI\n%02d" % (sim.to_spawn + sim.enemies.size() if sim.status != "ready" else 5)
	labels.score.text = "ĐIỂM CHIẾN ĐẤU\n%05d" % sim.score
	labels.robot.text = "ROBOT CỦA BẠN / ATK–01\n× %d robot    •    Giáp %d%%" % [sim.lives, maxi(0, sim.player.hp) * 20]
	labels.base.text = "TRẠNG THÁI CĂN CỨ\n%d%%  /  %s" % [base_percent, "AN TOÀN" if base_percent > 50 else "NGUY CẤP"]
	labels.stats.text = "Đợt %d/5   •   Địch %d   •   Điểm %d\nRobot ×%d   •   Giáp %d%%   •   Căn cứ %d%%" % [maxi(1, sim.wave), sim.to_spawn + sim.enemies.size(), sim.score, sim.lives, maxi(0, sim.player.hp) * 20, base_percent]
	pause_button.disabled = sim.status not in ["playing", "paused"]
	pause_button.text = "TIẾP TỤC [P]" if sim.status == "paused" else "TẠM DỪNG [P]"
	overlay.visible = sim.status != "playing"
	if sim.status != last_status:
		last_status = sim.status
		match sim.status:
			"ready":
				overlay_title.text = "Căn cứ cần bạn."
				overlay_copy.text = "Điều khiển robot, ngăn chặn 5 đợt tấn công.\nĐừng để kẻ địch phá hủy căn cứ."
				start_button.text = "TRIỂN KHAI ROBOT →"
			"paused":
				overlay_title.text = "Chờ lệnh của bạn."
				overlay_copy.text = "Chiến trường đã tạm dừng.\nTiếp tục khi bạn sẵn sàng."
				start_button.text = "TIẾP TỤC →"
			"won", "lost":
				overlay_title.text = "Căn cứ đứng vững." if sim.status == "won" else "Phòng tuyến đã vỡ."
				overlay_copy.text = "%s.\nTiêu diệt %d kẻ địch · %d điểm." % [sim.message, sim.kills, sim.score]
				start_button.text = "CHƠI LẠI ↻"

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("11181b"))
	draw_line(Vector2(12, 92 if mobile else 62), Vector2(size.x - 12, 92 if mobile else 62), Color("3f4c46"))
	draw_rect(board_rect.grow(2), Color("7b8067"), false, 2)
	var font = ThemeDB.fallback_font
	for action in touch_rects:
		var rect: Rect2 = touch_rects[action]
		draw_rect(rect, Color("5d4935") if action in pointers.values() else Color("303d3d"))
		draw_rect(rect, Color("657365"), false)
		var caption: String = {"up": "↑", "left": "←", "down": "↓", "right": "→", "fire": "BẮN ◎"}[action]
		var text_size = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		draw_string(font, rect.get_center() + Vector2(-text_size.x / 2, 7), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("e2d4af"))
	if radar_rect.has_area():
		draw_rect(radar_rect, Color("152023"))
		var colors = {"brick": Color("a86242"), "steel": Color("768487"), "water": Color("316b83"), "grass": Color("536c37")}
		var radar_scale = radar_rect.size.x / 210.0
		for y in R.ROWS:
			for x in R.COLS:
				var kind: String = sim.map[y][x].kind
				if colors.has(kind):
					draw_rect(Rect2(radar_rect.position + Vector2(x * 10 + 1, y * 10 + 1) * radar_scale, Vector2(8, 8) * radar_scale), colors[kind])
		draw_rect(Rect2(radar_rect.position + (R.BASE / 4 - Vector2(6, 6)) * radar_scale, Vector2(12, 12) * radar_scale), Color("8dc6b8"))
		draw_circle(radar_rect.position + sim.player.pos / 4 * radar_scale, 3 * radar_scale, Color("bae393"))
		for enemy in sim.enemies:
			draw_circle(radar_rect.position + enemy.pos / 4 * radar_scale, 3 * radar_scale, Color("f47e56"))
		var side = radar_rect.position.x
		draw_rect(Rect2(side, labels.robot.position.y + 80, 210, 6), Color("283439"))
		draw_rect(Rect2(side, labels.robot.position.y + 80, 210.0 * maxi(0, sim.player.hp) / R.PLAYER_HP, 6), Color("e98450"))
		draw_rect(Rect2(side, labels.base.position.y + 66, 210, 6), Color("283439"))
		draw_rect(Rect2(side, labels.base.position.y + 66, 210.0 * maxi(0, sim.base_hp) / R.BASE_HP, 6), Color("8dc6b8"))

func shot_sound() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data = PackedByteArray()
	data.resize(1764 * 2)
	var phase = 0.0
	for i in 1764:
		var t = float(i) / 1764
		phase += lerpf(150, 40, t) / 22050
		var value = int((1 if fmod(phase, 1) < 0.5 else -1) * (1 - t) * 10000)
		data.encode_s16(i * 2, value)
	wav.data = data
	return wav

func _exit_tree() -> void:
	if is_instance_valid(audio):
		audio.stop()
		audio.stream = null
