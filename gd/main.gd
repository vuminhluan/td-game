extends Control
const Sim = preload("res://gd/simulation.gd")
const View = preload("res://gd/battle_view.gd")
const PowerUpHUD = preload("res://gd/power_up_hud.gd")
const R = preload("res://gd/rules.gd")
const Map = preload("res://gd/battle_map.gd")
const KEY_DIRECTIONS = {KEY_W: "up", KEY_UP: "up", KEY_D: "right", KEY_RIGHT: "right", KEY_S: "down", KEY_DOWN: "down", KEY_A: "left", KEY_LEFT: "left"}
const Catalog = preload("res://gd/character_catalog.gd")
const Selection = preload("res://gd/character_selection.gd")
const MapSelection = preload("res://gd/map_selection.gd")
const CoopSelection = preload("res://gd/coop_selection.gd")
const PlayerInput = preload("res://gd/player_input.gd")
const PlayerHUD = preload("res://gd/player_status_hud.gd")
const COOP_BINDINGS = [{KEY_W: "up", KEY_D: "right", KEY_S: "down", KEY_A: "left"}, {KEY_UP: "up", KEY_RIGHT: "right", KEY_DOWN: "down", KEY_LEFT: "left"}]
@export var map_scene: PackedScene = preload("res://scenes/maps/industrial_yard.tscn")
@export var available_maps: Array[PackedScene] = [preload("res://scenes/maps/industrial_yard.tscn"), preload("res://scenes/maps/abandoned_city.tscn")]
var catalog = Catalog.new()
var preparation: PanelContainer
var map_preparation: PanelContainer
var preparation_step := "mode"
var play_mode := "single"
var mode_preparation: PanelContainer
var coop_button: Button
var coop_preparation: PanelContainer
var player_inputs: Array = []
var player_huds: Array = []
var second_container: SubViewportContainer
var second_viewport: SubViewport
var second_camera: Camera2D
var player_rects: Array[Rect2] = []
var character_id = "robot"
var body_id = "robot_body"
var weapon_id = "standard"
var selected_loadout = 0
var weapon_selector: OptionButton
var sim: RefCounted
var battle: Node2D
var power_up_hud: Control
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
var web_touch = false
var web_metrics_received = false
var web_local_coop = false
var web_blocked = false
var web_callback: JavaScriptObject
var web_interface: JavaScriptObject
var audio: AudioStreamPlayer
var sound_enabled = false
var last_shots = 0
var last_status = ""
var radar_rect = Rect2()
var battle_container: SubViewportContainer
var battle_viewport: SubViewport
var camera: Camera2D
var touch_surface: TouchSurface
var safe_rect = Rect2()

class TouchSurface extends Control:
	var rects: Dictionary = {}
	var pressed: Array = []
	func _draw() -> void:
		var font = get_theme_default_font()
		for action in rects:
			var rect: Rect2 = rects[action]
			draw_rect(rect, Color("5d4935") if action in pressed else Color("303d3d"))
			draw_rect(rect, Color("657365"), false)
			var caption: String = {"up": "↑", "left": "←", "down": "↓", "right": "→", "fire": "BẮN ◎"}[action]
			var text_size = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
			draw_string(font, rect.get_center() + Vector2(-text_size.x / 2, 7), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("e2d4af"))

func _ready() -> void:
	if not catalog.errors.is_empty():
		var error_label = Label.new()
		error_label.text = "Config nhân vật không hợp lệ:\n" + "\n".join(catalog.errors)
		add_child(error_label)
		set_process(false)
		return
	character_id = catalog.data.default_character
	body_id = catalog.data.characters[character_id].default_body
	weapon_id = catalog.data.characters[character_id].default_weapon
	sim = Sim.new(catalog.create(character_id, body_id, weapon_id), map_scene)
	if OS.has_feature("web"):
		web_interface = JavaScriptBridge.get_interface("RobotDefenseWeb")
		if web_interface != null:
			web_callback = JavaScriptBridge.create_callback(web_viewport_changed)
			web_interface.subscribe(web_callback)
	var theme_resource = Theme.new()
	var ui_font: Font = ThemeDB.fallback_font.duplicate()
	ui_font.fallbacks = [preload("res://assets/fonts/NotoSansSymbols.ttf"), preload("res://assets/fonts/NotoSansSymbols2-Regular.ttf")]
	theme_resource.default_font = ui_font
	theme_resource.default_font_size = 14
	theme = theme_resource
	battle_container = SubViewportContainer.new()
	battle_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_container.stretch = false
	add_child(battle_container)
	battle_viewport = SubViewport.new()
	battle_viewport.disable_3d = true
	battle_viewport.gui_disable_input = true
	battle_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	battle_container.add_child(battle_viewport)
	battle = View.new()
	battle.sim = sim
	battle.map_skin = sim.map_scene.map_skin
	battle_viewport.add_child(battle)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	battle_viewport.add_child(camera)
	second_container = SubViewportContainer.new()
	second_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(second_container)
	second_viewport = SubViewport.new()
	second_viewport.disable_3d = true
	second_viewport.gui_disable_input = true
	second_viewport.world_2d = battle_viewport.world_2d
	second_container.add_child(second_viewport)
	second_camera = Camera2D.new()
	second_camera.position_smoothing_enabled = false
	second_viewport.add_child(second_camera)
	for index in 2:
		player_inputs.append(PlayerInput.new(COOP_BINDINGS[index], KEY_SPACE if index == 0 else KEY_SHIFT))
		var hud = PlayerHUD.new()
		hud.player_index = index
		(battle_viewport if index == 0 else second_viewport).add_child(hud)
		player_huds.append(hud)
	touch_surface = TouchSurface.new()
	touch_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(touch_surface)
	power_up_hud = PowerUpHUD.new()
	power_up_hud.sim = sim
	power_up_hud.mouse_filter = Control.MOUSE_FILTER_PASS
	power_up_hud.size = Vector2(190, 38)
	add_child(power_up_hud)
	for id in ["brand", "sector", "heading", "field", "clock", "message", "stats", "help", "campaign", "enemies", "score", "robot", "base", "radar", "footer", "weapon"]:
		var label = Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Color("c4ceca"))
		add_child(label)
		labels[id] = label
	labels.brand.text = "ROBOT / DEFENSE"
	labels.brand.add_theme_font_size_override("font_size", 23)
	labels.brand.add_theme_color_override("font_color", Color("e98450"))
	labels.sector.text = "BẢN ĐỒ / " + sim.map_scene.display_name.to_upper()
	labels.heading.text = "Giữ vững phòng tuyến."
	labels.heading.add_theme_font_size_override("font_size", 30)
	labels.help.text = "WASD / ↑↓←→: di chuyển    SPACE: bắn    P / ESC: tạm dừng\nGạch: 3 HP · Thép: chặn mọi đạn · Nước: chặn đường · Cây: đi xuyên"
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
	preparation = Selection.new()
	preparation.catalog = catalog
	preparation.character_id = character_id
	preparation.deployed.connect(activate)
	add_child(preparation)
	preparation.visible = false
	preparation.map_requested.connect(show_map_selection)
	weapon_selector = preparation.weapon_selector
	preparation.selection_changed.connect(apply_selection)
	map_preparation = MapSelection.new()
	var scenes: Array[PackedScene] = available_maps.duplicate()
	if map_scene not in scenes:
		scenes.push_front(map_scene)
	map_preparation.set_maps(scenes, map_scene)
	map_preparation.confirmed.connect(choose_map)
	add_child(map_preparation)
	coop_preparation = CoopSelection.new()
	coop_preparation.catalog = catalog
	coop_preparation.deployed.connect(deploy_coop)
	coop_preparation.map_requested.connect(show_map_selection)
	add_child(coop_preparation)
	create_mode_selection()
	resized.connect(layout)
	get_window().focus_exited.connect(focus_lost)
	layout()
	refresh_hud()

func local_coop_available() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return false
	if OS.has_feature("web") or web_metrics_received:
		return web_local_coop
	return not web_touch

func create_mode_selection() -> void:
	mode_preparation = PanelContainer.new()
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color("152124")
	panel.border_color = Color("758572")
	panel.set_border_width_all(1)
	mode_preparation.add_theme_stylebox_override("panel", panel)
	add_child(mode_preparation)
	var margin = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	mode_preparation.add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title = Label.new()
	title.text = "ROBOT DEFENSE · CHỌN CHẾ ĐỘ"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)
	var single_button = make_button("Single Player", choose_mode.bind("single"), column)
	single_button.custom_minimum_size.y = 48
	coop_button = make_button("Local Co-op · 2 người / bàn phím", choose_mode.bind("coop"), column)
	coop_button.custom_minimum_size.y = 48
	var friend_button = make_button("Play with friend · COMING SOON", func(): pass, column)
	friend_button.disabled = true
	friend_button.add_theme_color_override("font_disabled_color", Color("81928d"))
	friend_button.custom_minimum_size.y = 48
	var back_button = Button.new()
	back_button.text = "← CHỌN CHẾ ĐỘ"
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.pressed.connect(show_mode_selection)
	map_preparation.confirm_button.get_parent().add_child(back_button)

func choose_mode(mode: String) -> void:
	if mode not in ["single", "coop"] or (mode == "coop" and not local_coop_available()):
		return
	play_mode = mode
	show_map_selection()
	layout()
	refresh_hud()

func show_mode_selection() -> void:
	clear_inputs()
	preparation_step = "mode"
	refresh_hud()

func deploy_coop(configurations: Array, friendly_fire: bool) -> void:
	if play_mode != "coop" or not local_coop_available() or configurations.size() != 2:
		return
	clear_inputs()
	sim = Sim.new(configurations[0], map_scene, configurations)
	sim.friendly_fire = friendly_fire
	battle.sim = sim
	battle.map_skin = sim.map_scene.map_skin
	power_up_hud.sim = sim
	if sim.status == "invalid":
		coop_preparation.show_error(sim.message)
	else:
		sim.start()
	last_shots = 0
	last_status = ""
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

func display_safe_rect() -> Rect2:
	var full = Rect2(Vector2.ZERO, size)
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return full
	var native: Rect2i = DisplayServer.get_display_safe_area()
	var window_size = Vector2(DisplayServer.window_get_size())
	if native.size.x <= 0 or native.size.y <= 0 or window_size.x <= 0 or window_size.y <= 0:
		return full
	var ratio = size / window_size
	var relative = Vector2(native.position - DisplayServer.window_get_position())
	return full.intersection(Rect2(relative * ratio, Vector2(native.size) * ratio))

func web_viewport_changed(arguments: Array) -> void:
	if arguments.is_empty():
		return
	var metrics = JSON.parse_string(str(arguments[0]))
	if not metrics is Dictionary:
		return
	web_metrics_received = true
	web_local_coop = metrics.get("localCoop", false) == true
	web_touch = metrics.get("touch", false)
	web_blocked = metrics.get("blocked", false)
	var logical_size = Vector2i(maxi(1, roundi(metrics.get("width", 1280))), maxi(1, roundi(metrics.get("height", 720))))
	var window = get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	if window.content_scale_size != logical_size:
		window.content_scale_size = logical_size
	if web_blocked:
		focus_lost()
	if battle != null:
		layout()
		refresh_hud()

func layout() -> void:
	if battle == null:
		return
	safe_rect = display_safe_rect()
	var bounds = safe_rect.grow(-12)
	mobile = web_touch or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or bounds.size.x < 1000 or bounds.size.y < 560
	var portrait = bounds.size.y > bounds.size.x
	var button_width = minf(140, (bounds.size.x - 12) / 2)
	put(labels.brand, Rect2(bounds.position, Vector2(260, 32)))
	labels.brand.add_theme_font_size_override("font_size", 18 if mobile else 23)
	var button_top = bounds.position.y + (38 if portrait else 0)
	put(sound_button, Rect2(bounds.end.x - button_width, button_top, button_width, 32))
	put(pause_button, Rect2(bounds.end.x - 2 * button_width - 8, button_top, button_width, 32))
	labels.sector.visible = not mobile
	labels.heading.visible = not mobile
	put(labels.sector, Rect2(bounds.position.x, bounds.position.y + 36, 360, 24))
	put(labels.heading, Rect2(bounds.position.x + 380, bounds.position.y + 30, 420, 32))
	labels.heading.add_theme_font_size_override("font_size", 23)
	var top = bounds.position.y + (156 if portrait else 102 if mobile else 96)
	var sidebar = 0.0 if mobile else 252.0
	var bottom = 46.0 if not mobile else 8.0
	board_rect = Rect2(Vector2(bounds.position.x, top), Vector2(maxf(1, bounds.size.x - sidebar), maxf(1, bounds.end.y - top - bottom)))
	layout_player_views()
	power_up_hud.position = board_rect.position + Vector2(8, 8)
	power_up_hud.scale = Vector2.ONE * minf(1.0, board_rect.size.x / 220.0)
	put(labels.field, Rect2(board_rect.position.x, top - 26, 230, 24))
	put(labels.clock, Rect2(board_rect.end.x - 52, top - 26, 52, 24))
	put(labels.message, Rect2(board_rect.position.x, board_rect.end.y + 4, board_rect.size.x, 24))
	labels.message.visible = not mobile
	labels.stats.visible = mobile and sim.status in ["playing", "paused"]
	touch_surface.visible = mobile and play_mode == "single" and sim.status == "playing" and not web_blocked
	power_up_hud.visible = play_mode == "single" and sim.status in ["playing", "paused"]
	put(labels.stats, Rect2(bounds.position.x, bounds.position.y + (76 if portrait else 36), bounds.size.x, 36))
	labels.stats.add_theme_font_size_override("font_size", 12)
	for id in ["campaign", "enemies", "score", "robot", "base", "radar"]:
		labels[id].visible = not mobile
	radar_rect = Rect2()
	if not mobile:
		var side = board_rect.end.x + 20
		put(labels.campaign, Rect2(side, top, 220, 54))
		labels.campaign.add_theme_font_size_override("font_size", 20)
		put(labels.enemies, Rect2(side, top + 66, 220, 44))
		put(labels.score, Rect2(side, top + 116, 220, 44))
		put(labels.robot, Rect2(side, top + 166, 220, 48))
		put(labels.base, Rect2(side, top + 230, 220, 48))
		put(labels.radar, Rect2(side, top + 300, 220, 24))
		labels.radar.text = "BẢN ĐỒ CHIẾN THUẬT"
		var radar_height = clampf(board_rect.size.y - 334, 0, 180)
		var aspect = maxf(1, sim.dimensions.x) / maxf(1, sim.dimensions.y)
		var radar_width = minf(210, radar_height * aspect)
		radar_rect = Rect2(side, top + 328, radar_width, radar_width / aspect)
	put(labels.weapon, Rect2(board_rect.position.x + 8, board_rect.position.y + 48, minf(220, board_rect.size.x - 16), 24))
	labels.weapon.add_theme_font_size_override("font_size", 12)
	labels.help.visible = not mobile
	labels.footer.visible = false
	labels.help.text = "WASD / ↑↓←→: di chuyển    SPACE: bắn    P / ESC: tạm dừng"
	put(labels.help, Rect2(bounds.position.x, bounds.end.y - 20, bounds.size.x, 24))
	touch_rects.clear()
	if mobile and play_mode == "single":
		var edge = clampf(minf(bounds.size.y * 0.12, bounds.size.x / 7), 36, 56)
		var origin = Vector2(bounds.position.x + 8, board_rect.end.y - 2 * edge - 12)
		touch_rects.up = Rect2(origin + Vector2(edge + 4, 0), Vector2.ONE * edge)
		touch_rects.left = Rect2(origin + Vector2(0, edge + 4), Vector2.ONE * edge)
		touch_rects.down = Rect2(origin + Vector2(edge + 4, edge + 4), Vector2.ONE * edge)
		touch_rects.right = Rect2(origin + Vector2(2 * (edge + 4), edge + 4), Vector2.ONE * edge)
		touch_rects.fire = Rect2(bounds.end.x - edge * 1.8 - 8, board_rect.end.y - edge * 1.4 - 8, edge * 1.8, edge * 1.4)
	touch_surface.size = size
	touch_surface.rects = touch_rects
	touch_surface.queue_redraw()
	var preparation_size = Vector2(minf(500, bounds.size.x), minf(640, bounds.size.y - 44))
	map_preparation.set_compact(mobile)
	put(preparation, Rect2(bounds.get_center() - preparation_size / 2, preparation_size))
	put(map_preparation, Rect2(bounds.get_center() - preparation_size / 2, preparation_size))
	var coop_size = Vector2(minf(1040, bounds.size.x), minf(660, bounds.size.y))
	put(coop_preparation, Rect2(bounds.get_center() - coop_size / 2, coop_size))
	var mode_size = Vector2(minf(460, bounds.size.x), minf(340, bounds.size.y))
	put(mode_preparation, Rect2(bounds.get_center() - mode_size / 2, mode_size))
	coop_button.visible = local_coop_available()
	var overlay_size = Vector2(minf(430, board_rect.size.x - 12), minf(278, board_rect.size.y - 12))
	put(overlay, Rect2(board_rect.get_center() - overlay_size / 2, overlay_size))
	put(overlay_title, Rect2(8, 12, overlay_size.x - 16, 42))
	overlay_title.add_theme_font_size_override("font_size", 18 if mobile else 28)
	put(overlay_copy, Rect2(16, 62, overlay_size.x - 32, maxf(30, overlay_size.y - 126)))
	put(start_button, Rect2(16, overlay_size.y - 54, overlay_size.x - 32, 40))
	clear_inputs()
	update_camera()
	queue_redraw()

func layout_player_views() -> void:
	player_rects.clear()
	if play_mode == "coop":
		var landscape = size.x >= size.y
		var extent = (board_rect.size.x if landscape else board_rect.size.y) / 2.0 - 2.0
		var first = Rect2(board_rect.position, Vector2(extent, board_rect.size.y) if landscape else Vector2(board_rect.size.x, extent))
		var offset = Vector2(extent + 4, 0) if landscape else Vector2(0, extent + 4)
		player_rects.assign([first, Rect2(first.position + offset, first.size)])
	else:
		player_rects.append(board_rect)
	put(battle_container, player_rects[0])
	battle_viewport.size = Vector2i(player_rects[0].size)
	second_container.visible = play_mode == "coop"
	second_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if play_mode == "coop" else SubViewport.UPDATE_DISABLED
	if play_mode == "coop":
		put(second_container, player_rects[1])
		second_viewport.size = Vector2i(player_rects[1].size)

func update_camera() -> void:
	if camera == null or sim == null or sim.status == "invalid":
		return
	if play_mode == "coop":
		for index in mini(2, sim.players.size()):
			follow_camera(camera if index == 0 else second_camera, battle_viewport if index == 0 else second_viewport, sim.players[index].actor.pos)
		return
	var world = Vector2(sim.dimensions) * R.TILE
	var viewport_size = Vector2(battle_viewport.size)
	var zoom = clampf(viewport_size.y / 600.0, 0.55, 1.25) if mobile else minf(1.25, minf(viewport_size.x / maxf(world.x, 1), viewport_size.y / maxf(world.y, 1)))
	camera.zoom = Vector2.ONE * zoom
	var visible_world = Vector2(battle_viewport.size) / camera.zoom
	var half = visible_world / 2
	var target: Vector2 = sim.player.pos
	camera.position = Vector2(world.x / 2 if world.x <= visible_world.x else clampf(target.x, half.x, world.x - half.x), world.y / 2 if world.y <= visible_world.y else clampf(target.y, half.y, world.y - half.y))
	camera.force_update_scroll()

func follow_camera(view_camera: Camera2D, viewport: SubViewport, target: Vector2) -> void:
	var world = Vector2(sim.dimensions) * R.TILE
	var zoom = clampf(Vector2(viewport.size).y / 520.0, 0.65, 1.25)
	view_camera.zoom = Vector2.ONE * zoom
	var visible_world = Vector2(viewport.size) / zoom
	var half = visible_world / 2
	view_camera.position = Vector2(world.x / 2 if world.x <= visible_world.x else clampf(target.x, half.x, world.x - half.x), world.y / 2 if world.y <= visible_world.y else clampf(target.y, half.y, world.y - half.y))
	view_camera.force_update_scroll()

func screen_to_world(point: Vector2, player_index: int = 0) -> Vector2:
	var view_camera = second_camera if player_index == 1 and play_mode == "coop" else camera
	var viewport = second_viewport if player_index == 1 and play_mode == "coop" else battle_viewport
	var rect: Rect2 = player_rects[player_index] if play_mode == "coop" else board_rect
	return view_camera.position + (point - rect.position - Vector2(viewport.size) / 2) / view_camera.zoom

func world_to_screen(point: Vector2, player_index: int = 0) -> Vector2:
	var view_camera = second_camera if player_index == 1 and play_mode == "coop" else camera
	var viewport = second_viewport if player_index == 1 and play_mode == "coop" else battle_viewport
	var rect: Rect2 = player_rects[player_index] if play_mode == "coop" else board_rect
	return rect.position + Vector2(viewport.size) / 2 + (point - view_camera.position) * view_camera.zoom

func apply_selection(character: String, body: String, weapon: String) -> void:
	if sim.status not in ["ready", "won", "lost"]:
		return
	character_id = character
	body_id = body
	weapon_id = weapon
	selected_loadout = catalog.data.characters[character_id].weapons.find(weapon_id)
	if sim.status == "ready":
		sim = Sim.new(catalog.create(character_id, body_id, weapon_id), map_scene)
		battle.sim = sim
		battle.map_skin = sim.map_scene.map_skin
		power_up_hud.sim = sim
	update_camera()
	refresh_hud()
	battle.queue_redraw()

func select_loadout(index: int) -> void:
	if sim.status not in ["ready", "won", "lost"]:
		weapon_selector.select(selected_loadout)
		return
	preparation.choose_weapon(index)
	weapon_selector.select(index)

func activate() -> void:
	if play_mode == "coop" and sim.status != "paused":
		return
	clear_inputs()
	if sim.status == "ready":
		sim.start()
	elif sim.status == "paused":
		sim.pause()
	else:
		sim = Sim.new(catalog.create(character_id, body_id, weapon_id), map_scene)
		battle.sim = sim
		battle.map_skin = sim.map_scene.map_skin
		power_up_hud.sim = sim
		sim.start()
		last_shots = 0
	update_camera()
	refresh_hud()

func choose_map(scene: PackedScene) -> void:
	map_scene = scene
	sim = Sim.new(catalog.create(character_id, body_id, weapon_id), map_scene)
	battle.sim = sim
	battle.map_skin = sim.map_scene.map_skin
	labels.sector.text = "BẢN ĐỒ / " + sim.map_scene.display_name.to_upper()
	power_up_hud.sim = sim
	preparation_step = "character"
	map_preparation.visible = false
	preparation.visible = play_mode == "single"
	coop_preparation.show_error("")
	coop_preparation.visible = play_mode == "coop"
	update_camera()
	refresh_hud()
	battle.queue_redraw()

func show_map_selection() -> void:
	preparation_step = "map"
	map_preparation.select_map(map_scene)
	map_preparation.visible = true
	preparation.visible = false
	coop_preparation.visible = false
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
	for source in player_inputs:
		source.clear()

func focus_lost() -> void:
	if sim == null:
		return
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
	if sim == null:
		return
	if web_blocked:
		clear_inputs()
		return
	if event is InputEventKey:
		if event.echo:
			return
		var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if play_mode == "coop" and coop_preparation.visible:
			if event.pressed:
				coop_preparation.handle_key(key)
			get_viewport().set_input_as_handled()
			return
		if play_mode == "coop":
			for source in player_inputs:
				source.handle_key(key, event.pressed)
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
	if play_mode == "coop":
		sim.update_players(dt, player_inputs.map(func(source): return source.command()))
	else:
		sim.update(dt, input_direction(), keyboard_fire or "fire" in pointers.values())
	if sound_enabled and sim.shots_fired > last_shots:
		audio.play()
	last_shots = sim.shots_fired
	update_camera()
	refresh_hud()
	battle.queue_redraw()
	power_up_hud.queue_redraw()
	touch_surface.pressed = pointers.values()
	touch_surface.queue_redraw()
	queue_redraw()

func refresh_hud() -> void:
	if labels.is_empty():
		return
	for hud in player_huds:
		hud.refresh(sim, play_mode == "coop" and sim.status in ["playing", "paused", "won", "lost"])
	if coop_button != null:
		coop_button.visible = local_coop_available()
	var base_percent = roundi(100.0 * maxi(0, sim.base_hp) / R.BASE_HP)
	labels.weapon.text = "VŨ KHÍ: " + sim.loadout.weapon.display_name
	if sim.status == "invalid":
		labels.message.text = "Map không hợp lệ: " + "; ".join(sim.validation_errors)
		labels.message.visible = play_mode == "single"
		labels.message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		labels.message.position = board_rect.position + Vector2(8, 80)
		labels.message.size = board_rect.size - Vector2(16, 88)
		preparation.visible = false
		coop_preparation.visible = play_mode == "coop" and preparation_step == "character"
		map_preparation.visible = preparation_step == "map"
		mode_preparation.visible = preparation_step == "mode"
		overlay.visible = false
		pause_button.disabled = true
		return
	labels.clock.text = "%02d:%02d" % [floori(sim.elapsed / 60), int(sim.elapsed) % 60]
	labels.field.text = {"ready": "● CHỜ TRIỂN KHAI", "playing": "● ĐANG GIAO TRANH", "paused": "● TẠM DỪNG", "won": "● HOÀN THÀNH", "lost": "● THẤT THỦ"}[sim.status]
	labels.message.text = sim.message
	labels.campaign.text = "CHIẾN DỊCH\n%02d / 05" % maxi(1, sim.wave)
	labels.enemies.text = "ĐỊCH CÒN LẠI\n%02d" % (sim.to_spawn + sim.enemies.size() if sim.status != "ready" else 5)
	labels.score.text = "ĐIỂM CHIẾN ĐẤU\n%05d" % sim.score
	labels.robot.text = "%s\n× %d    •    Giáp %d%%" % [sim.loadout.display_name, sim.lives, roundi(100.0 * maxi(0, sim.player.hp) / sim.player.max_hp)]
	labels.base.text = "TRẠNG THÁI CĂN CỨ\n%d%%  /  %s" % [base_percent, "AN TOÀN" if base_percent > 50 else "NGUY CẤP"]
	labels.stats.text = "Đợt %d/5   •   Địch %d   •   Điểm %d\nRobot ×%d   •   Giáp %d%%   •   Căn cứ %d%%" % [maxi(1, sim.wave), sim.to_spawn + sim.enemies.size(), sim.score, sim.lives, roundi(100.0 * maxi(0, sim.player.hp) / sim.player.max_hp), base_percent]
	pause_button.disabled = sim.status not in ["playing", "paused"]
	pause_button.visible = sim.status in ["playing", "paused"]
	pause_button.text = "TIẾP TỤC [P]" if sim.status == "paused" else "TẠM DỪNG [P]"
	touch_surface.visible = mobile and play_mode == "single" and sim.status == "playing" and not web_blocked
	power_up_hud.visible = play_mode == "single" and sim.status in ["playing", "paused"]
	labels.stats.visible = mobile and sim.status in ["playing", "paused"]
	weapon_selector.visible = sim.status in ["ready", "won", "lost"]
	weapon_selector.disabled = not weapon_selector.visible
	preparation.visible = sim.status in ["ready", "won", "lost"]
	preparation.visible = preparation.visible and preparation_step == "character" and play_mode == "single"
	map_preparation.visible = sim.status in ["ready", "won", "lost"] and preparation_step == "map"
	mode_preparation.visible = preparation_step == "mode"
	coop_preparation.visible = play_mode == "coop" and preparation_step == "character" and sim.status in ["ready", "won", "lost"]
	if play_mode == "coop":
		labels.weapon.visible = false
		labels.robot.visible = false
		labels.stats.text = "Đợt %d/5 · Địch %d · Điểm %d · Căn cứ %d%%" % [maxi(1, sim.wave), sim.to_spawn + sim.enemies.size(), sim.score, base_percent]
		labels.help.text = "P1: WASD + SPACE    P2: ↑↓←→ + SHIFT    P / ESC: tạm dừng"
	else:
		labels.weapon.visible = true
	coop_preparation.heading.text = ("THẮNG TRẬN · %d ĐIỂM" % sim.score) if sim.status == "won" else ("THUA TRẬN · %d ĐIỂM" % sim.score) if sim.status == "lost" else "LOCAL CO-OP · CHUẨN BỊ"
	preparation.heading.text = "THẮNG TRẬN · CHỌN LẠI" if sim.status == "won" else "THUA TRẬN · CHỌN LẠI" if sim.status == "lost" else "CHUẨN BỊ VÀO TRẬN"
	overlay.visible = sim.status == "paused"
	if sim.status != last_status:
		last_status = sim.status
		if sim.status in ["won", "lost"]:
			coop_preparation.reset_ready()
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
				start_button.text = "CHƠI LẠI"

func _draw() -> void:
	if sim == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("11181b"))
	draw_line(Vector2(safe_rect.position.x + 12, board_rect.position.y - 30), Vector2(safe_rect.end.x - 12, board_rect.position.y - 30), Color("3f4c46"))
	draw_rect(board_rect.grow(2), Color("7b8067"), false, 2)
	if radar_rect.has_area() and sim.status != "invalid":
		draw_rect(radar_rect, Color("152023"))
		var colors = {"brick": Color("a86242"), "steel": Color("768487"), "water": Color("316b83"), "grass": Color("536c37")}
		var world = Vector2(sim.dimensions) * R.TILE
		var radar_scale = radar_rect.size / world
		for y in sim.dimensions.y:
			for x in sim.dimensions.x:
				var tile: Dictionary = sim.map[y][x]
				var color: Color = colors.get(tile.kind, Color.TRANSPARENT)
				if Map.move_blocked(tile) and (tile.has("object") or color == Color.TRANSPARENT):
					color = Color("8a8070")
				if color.a > 0:
					draw_rect(Rect2(radar_rect.position + (Vector2(x, y) * R.TILE + Vector2.ONE * 4) * radar_scale, Vector2.ONE * (R.TILE - 8) * radar_scale), color)
		draw_rect(Rect2(radar_rect.position + (sim.base_position - Vector2(24, 24)) * radar_scale, Vector2(48, 48) * radar_scale), Color("8dc6b8"))
		for state in sim.players:
			if state.actor.hp > 0:
				draw_circle(radar_rect.position + state.actor.pos * radar_scale, 3, Color("bae393") if state.id == 1 else Color("9dddf4"))
		for enemy in sim.enemies:
			draw_circle(radar_rect.position + enemy.pos * radar_scale, 3, Color("f47e56"))
		var side = radar_rect.position.x
		if play_mode == "single":
			draw_rect(Rect2(side, labels.robot.position.y + 52, 210, 6), Color("283439"))
			draw_rect(Rect2(side, labels.robot.position.y + 52, 210.0 * maxi(0, sim.player.hp) / sim.player.max_hp, 6), Color("e98450"))
		draw_rect(Rect2(side, labels.base.position.y + 52, 210, 6), Color("283439"))
		draw_rect(Rect2(side, labels.base.position.y + 52, 210.0 * maxi(0, sim.base_hp) / R.BASE_HP, 6), Color("8dc6b8"))

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
