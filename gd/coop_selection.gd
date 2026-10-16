extends PanelContainer
const Selection = preload("res://gd/character_selection.gd")
const Sim = preload("res://gd/simulation.gd")
signal deployed(configurations: Array, friendly_fire: bool)
signal map_requested
var catalog: RefCounted
var selections: Array = []
var ready_players: Array[bool] = [false, false]
var friendly_fire = false
var cursors: Array[int] = [0, 0]
var selectors: Array = [[], []]
var rows: Array = [[], []]
var previews: Array = []
var ready_buttons: Array[Button] = []
var player_headings: Array[Label] = []
var scroll: ScrollContainer
var friendly_fire_button: CheckButton
var heading: Label
var error_label: Label
var deployed_once = false

func _ready() -> void:
	var panel = StyleBoxFlat.new()
	panel.bg_color = Color("152124")
	panel.border_color = Color("758572")
	panel.set_border_width_all(1)
	add_theme_stylebox_override("panel", panel)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	scroll.add_child(margin)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	heading = Label.new()
	heading.text = "LOCAL CO-OP · CHUẨN BỊ"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", 18)
	column.add_child(heading)
	var map_button = Button.new()
	map_button.text = "← CHỌN BẢN ĐỒ"
	map_button.focus_mode = Control.FOCUS_NONE
	map_button.pressed.connect(func(): map_requested.emit())
	column.add_child(map_button)
	friendly_fire_button = CheckButton.new()
	friendly_fire_button.text = "Friendly fire · Sát thương đồng đội"
	friendly_fire_button.focus_mode = Control.FOCUS_NONE
	friendly_fire_button.toggled.connect(set_friendly_fire)
	column.add_child(friendly_fire_button)
	error_label = Label.new()
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.modulate = Color("ffac9b")
	error_label.visible = false
	column.add_child(error_label)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	column.add_child(grid)
	for player_index in 2:
		var character: String = catalog.data.default_character
		var definition: Dictionary = catalog.data.characters[character]
		selections.append({"character_id": character, "body_id": definition.default_body, "weapon_id": definition.default_weapon})
		build_player_panel(grid, player_index)
		refresh_player(player_index)
	var instructions = Label.new()
	instructions.text = "Cả hai Sẵn sàng để vào trận. Có thể chọn loadout giống nhau."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(instructions)

func build_player_panel(grid: GridContainer, player_index: int) -> void:
	var panel = VBoxContainer.new()
	panel.custom_minimum_size.x = 216
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 5)
	grid.add_child(panel)
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)
	player_headings.append(title)
	var controls = Label.new()
	controls.text = "W/S: hàng · A/D: đổi\nSpace: xác nhận" if player_index == 0 else "↑/↓: hàng · ←/→: đổi\nShift: xác nhận"
	controls.add_theme_font_size_override("font_size", 13)
	panel.add_child(controls)
	var holder = Control.new()
	holder.custom_minimum_size.y = 80
	panel.add_child(holder)
	var preview = Selection.Preview.new()
	preview.scale = Vector2.ONE * 1.3
	holder.add_child(preview)
	holder.resized.connect(func(): preview.position = holder.size / 2)
	previews.append(preview)
	for row_index in 4:
		var row = PanelContainer.new()
		panel.add_child(row)
		rows[player_index].append(row)
		var content = VBoxContainer.new()
		row.add_child(content)
		if row_index < 3:
			var label = Label.new()
			label.text = ["Nhân vật", "Body", "Vũ khí"][row_index]
			label.add_theme_font_size_override("font_size", 13)
			content.add_child(label)
			var selector = OptionButton.new()
			selector.fit_to_longest_item = false
			selector.focus_mode = Control.FOCUS_NONE
			selector.item_selected.connect(choose_option.bind(player_index, row_index))
			selector.get_popup().window_input.connect(handle_popup_input.bind(selector.get_popup()))
			content.add_child(selector)
			selectors[player_index].append(selector)
		else:
			var button = Button.new()
			button.focus_mode = Control.FOCUS_NONE
			button.custom_minimum_size.y = 36
			button.pressed.connect(confirm_ready.bind(player_index))
			content.add_child(button)
			ready_buttons.append(button)

func handle_popup_input(event: InputEvent, popup: PopupMenu) -> void:
	if not event is InputEventKey:
		return
	var key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SHIFT]:
		return
	popup.set_input_as_handled()
	if event.pressed and not event.echo:
		popup.hide()
		handle_key(key)

func option_ids(player_index: int, row_index: int) -> Array:
	if row_index == 0:
		return catalog.data.characters.keys()
	var character: Dictionary = catalog.data.characters[selections[player_index].character_id]
	return character.bodies if row_index == 1 else character.weapons

func choose_option(option_index: int, player_index: int, row_index: int) -> void:
	var ids = option_ids(player_index, row_index)
	if option_index < 0 or option_index >= ids.size():
		return
	var selection: Dictionary = selections[player_index]
	var field: String = ["character_id", "body_id", "weapon_id"][row_index]
	if selection[field] == ids[option_index]:
		return
	selection[field] = ids[option_index]
	if row_index == 0:
		var definition: Dictionary = catalog.data.characters[selection.character_id]
		selection.body_id = definition.default_body
		selection.weapon_id = definition.default_weapon
	ready_players[player_index] = false
	cursors[player_index] = row_index
	refresh_player(player_index)

func refresh_player(player_index: int) -> void:
	var selection: Dictionary = selections[player_index]
	for row_index in 3:
		var selector: OptionButton = selectors[player_index][row_index]
		selector.clear()
		var ids = option_ids(player_index, row_index)
		var section: String = ["characters", "bodies", "weapons"][row_index]
		var field: String = ["character_id", "body_id", "weapon_id"][row_index]
		for id in ids:
			selector.add_item(catalog.data[section][id].name)
		selector.select(ids.find(selection[field]))
	var configuration: Resource = catalog.create(selection.character_id, selection.body_id, selection.weapon_id)
	if configuration != null:
		previews[player_index].sim = Sim.new(configuration)
		previews[player_index].sim.player.pos = Vector2.ZERO
		previews[player_index].sim.player.dir = "down"
	refresh_readiness()

func refresh_readiness() -> void:
	for player_index in ready_buttons.size():
		var color = Color("68d9ed") if player_index == 0 else Color("ffca71")
		player_headings[player_index].text = "P%d · %s" % [player_index + 1, "SẴN SÀNG" if ready_players[player_index] else "CHỌN LOADOUT"]
		player_headings[player_index].modulate = color
		ready_buttons[player_index].text = "✓ SẴN SÀNG · Hủy" if ready_players[player_index] else "SẴN SÀNG"
		for row_index in 4:
			var style = StyleBoxFlat.new()
			style.bg_color = Color("213238")
			style.border_color = color
			style.set_border_width_all(2 if cursors[player_index] == row_index else 0)
			style.set_content_margin_all(4)
			rows[player_index][row_index].add_theme_stylebox_override("panel", style)

func handle_key(key: int) -> void:
	if deployed_once:
		return
	var player_index = 0 if key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE] else 1
	var keys: Array = [KEY_W, KEY_S, KEY_A, KEY_D, KEY_SPACE] if player_index == 0 else [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SHIFT]
	if not key in keys:
		return
	var row_index: int = cursors[player_index]
	if key == keys[0] or key == keys[1]:
		cursors[player_index] = posmod(row_index + (-1 if key == keys[0] else 1), 4)
	elif key == keys[2] or key == keys[3]:
		if row_index < 3:
			var ids = option_ids(player_index, row_index)
			var field: String = ["character_id", "body_id", "weapon_id"][row_index]
			var index = ids.find(selections[player_index][field])
			choose_option(posmod(index + (-1 if key == keys[2] else 1), ids.size()), player_index, row_index)
	elif ready_players[player_index] or row_index == 3:
		confirm_ready(player_index)
	else:
		cursors[player_index] = row_index + 1
	refresh_readiness()
	scroll.ensure_control_visible(rows[player_index][cursors[player_index]])

func confirm_ready(player_index: int) -> void:
	if deployed_once:
		return
	error_label.visible = false
	ready_players[player_index] = not ready_players[player_index]
	cursors[player_index] = 3
	refresh_readiness()
	if ready_players[0] and ready_players[1]:
		var selected = configurations()
		if selected.size() == 2:
			deployed_once = true
			deployed.emit(selected, friendly_fire)

func set_friendly_fire(enabled: bool) -> void:
	if friendly_fire == enabled:
		return
	friendly_fire = enabled
	friendly_fire_button.set_pressed_no_signal(enabled)
	reset_ready()

func reset_ready() -> void:
	ready_players.assign([false, false])
	deployed_once = false
	refresh_readiness()

func configurations() -> Array:
	var result: Array = []
	for selection in selections:
		var configuration: Resource = catalog.create(selection.character_id, selection.body_id, selection.weapon_id)
		if configuration == null:
			return []
		result.append(configuration)
	return result

func show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = not message.is_empty()
	reset_ready()
	scroll.scroll_vertical = 0

func _exit_tree() -> void:
	for preview in previews:
		preview.sim = null
