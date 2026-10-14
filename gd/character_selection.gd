extends PanelContainer
const Sim = preload("res://gd/simulation.gd")
const View = preload("res://gd/battle_view.gd")
signal selection_changed(character_id: String, body_id: String, weapon_id: String)
signal deployed
signal map_requested
var catalog: RefCounted
var character_id = "robot"
var body_id = "robot_body"
var weapon_id = "standard"
var weapon_selector: OptionButton
var body_selector: OptionButton
var heading: Label
var info: Label
var cards: Array[Button] = []
var preview: Node2D
var direction = "down"

class Preview extends View:
	var pose = "idle"
	func _ready() -> void:
		pass
	func _process(dt: float) -> void:
		sim.elapsed += dt
		sim.player.moving = pose == "walk"
		sim.player.move_clock += dt
		sim.player.shot_clock = sim.player.shot_duration * (1.0 - fmod(sim.elapsed, 1.0)) if pose == "attack" else 0.0
		queue_redraw()
	func _draw() -> void:
		draw_player(sim.player)

func _ready() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("152124")
	style.border_color = Color("758572")
	style.set_border_width_all(1)
	add_theme_stylebox_override("panel", style)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	heading = Label.new()
	var title = heading
	title.text = "CHUẨN BỊ VÀO TRẬN"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	var map_button := Button.new()
	map_button.text = "← CHỌN BẢN ĐỒ"
	map_button.pressed.connect(func(): map_requested.emit())
	column.add_child(map_button)
	var row = HBoxContainer.new()
	column.add_child(row)
	for id in catalog.data.characters:
		var c: Dictionary = catalog.data.characters[id]
		var card = Button.new()
		card.text = "%s\nHP %d · Tốc độ %d" % [c.name, c.hp, c.speed]
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.toggle_mode = true
		card.pressed.connect(choose_character.bind(id))
		row.add_child(card)
		cards.append(card)
	var body_label = Label.new()
	body_label.text = "1 · Chọn Body"
	column.add_child(body_label)
	body_selector = OptionButton.new()
	body_selector.item_selected.connect(choose_body)
	column.add_child(body_selector)
	var weapon_label = Label.new()
	weapon_label.text = "2 · Chọn vũ khí"
	column.add_child(weapon_label)
	weapon_selector = OptionButton.new()
	weapon_selector.item_selected.connect(choose_weapon)
	column.add_child(weapon_selector)
	var holder = Control.new()
	holder.custom_minimum_size = Vector2(0, 120)
	column.add_child(holder)
	preview = Preview.new()
	preview.scale = Vector2.ONE * 1.7
	holder.add_child(preview)
	holder.resized.connect(func(): preview.position = holder.size / 2)
	var directions = HBoxContainer.new()
	column.add_child(directions)
	for d in ["up", "down", "left", "right"]:
		var button = Button.new()
		button.text = {"up": "↑", "down": "↓", "left": "←", "right": "→"}[d]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): direction = d; update_preview())
		directions.add_child(button)
	var poses = HBoxContainer.new()
	column.add_child(poses)
	for pose in ["idle", "walk", "attack"]:
		var button = Button.new()
		button.text = {"idle": "Đứng", "walk": "Di chuyển", "attack": "Bắn"}[pose]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func(): preview.pose = pose)
		poses.add_child(button)
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(info)
	var start = Button.new()
	start.text = "VÀO TRẬN →"
	start.custom_minimum_size.y = 44
	start.pressed.connect(func(): deployed.emit())
	column.add_child(start)
	choose_character(character_id)

func choose_character(id: String) -> void:
	character_id = id
	var c: Dictionary = catalog.data.characters[id]
	body_id = c.default_body
	weapon_id = c.default_weapon
	body_selector.clear()
	for ref in c.bodies:
		body_selector.add_item(catalog.data.bodies[ref].name)
	weapon_selector.clear()
	for ref in c.weapons:
		weapon_selector.add_item(catalog.data.weapons[ref].name)
	for i in cards.size():
		cards[i].button_pressed = catalog.data.characters.keys()[i] == id
	update_preview()

func choose_body(index: int) -> void:
	body_selector.select(index)
	body_id = catalog.data.characters[character_id].bodies[index]
	update_preview()

func choose_weapon(index: int) -> void:
	weapon_selector.select(index)
	weapon_id = catalog.data.characters[character_id].weapons[index]
	update_preview()

func update_preview() -> void:
	var configuration: Resource = catalog.create(character_id, body_id, weapon_id)
	if configuration == null:
		return
	preview.sim = Sim.new(configuration)
	preview.sim.player.pos = Vector2.ZERO
	preview.sim.player.dir = direction
	var w: Resource = configuration.weapon
	var schedule: Array = w.schedule(false)
	info.text = "%d HP mỗi viên · %d viên/loạt\nLoạt %.2fs · Nghỉ %.2fs\nRapid Fire: nghỉ %.2fs · Double Shot: ×2 viên" % [w.damage, w.burst_times.size() * (1 if w.alternating else w.barrel_offsets.size()), schedule.back().time, w.cooldown, w.cooldown * w.rapid_rest_multiplier]
	selection_changed.emit(character_id, body_id, weapon_id)

func _exit_tree() -> void:
	if preview != null:
		preview.sim = null
