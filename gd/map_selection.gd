extends PanelContainer

signal confirmed(map_scene: PackedScene)

var map_scenes: Array[PackedScene] = []
var selected_scene: PackedScene
var buttons: Array[Button] = []
var map_options: BoxContainer
var heading: Label
var description: Label
var preview: TextureRect
var confirm_button: Button

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("152124")
	style.border_color = Color("758572")
	style.set_border_width_all(1)
	add_theme_stylebox_override("panel", style)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	heading = Label.new()
	heading.text = "1 · CHỌN BẢN ĐỒ"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.custom_minimum_size.y = 48
	heading.add_theme_font_size_override("font_size", 20)
	column.add_child(heading)
	map_options = BoxContainer.new()
	map_options.add_theme_constant_override("separation", 10)
	map_options.vertical = get_viewport_rect().size.x < 520
	column.add_child(map_options)
	for scene in map_scenes:
		var map = scene.instantiate()
		var button := Button.new()
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 70)
		button.text = map.display_name
		button.pressed.connect(select_map.bind(scene))
		map_options.add_child(button)
		buttons.append(button)
		map.free()
	preview = TextureRect.new()
	preview.custom_minimum_size = Vector2(0, 190)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(preview)
	description = Label.new()
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 54
	column.add_child(description)
	confirm_button = Button.new()
	confirm_button.text = "TIẾP TỤC CHỌN NHÂN VẬT →"
	confirm_button.custom_minimum_size.y = 44
	confirm_button.pressed.connect(confirm_selection)
	column.add_child(confirm_button)
	if not map_scenes.is_empty():
		select_map(selected_scene if selected_scene in map_scenes else map_scenes[0])

func set_maps(scenes: Array[PackedScene], selection: PackedScene) -> void:
	map_scenes = scenes.duplicate()
	selected_scene = selection

func set_compact(compact: bool) -> void:
	if is_instance_valid(map_options):
		map_options.vertical = compact

func select_map(scene: PackedScene) -> void:
	if scene not in map_scenes:
		return
	selected_scene = scene
	var map = scene.instantiate()
	for index in buttons.size():
		buttons[index].button_pressed = map_scenes[index] == scene
	heading.text = "1 · CHỌN BẢN ĐỒ — " + map.display_name.to_upper()
	description.text = map.display_description
	preview.texture = map.preview_texture
	map.free()

func confirm_selection() -> void:
	if selected_scene != null:
		confirmed.emit(selected_scene)
