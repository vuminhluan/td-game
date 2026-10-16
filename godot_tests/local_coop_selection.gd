extends SceneTree
const Catalog = preload("res://gd/character_catalog.gd")
const CoopSelection = preload("res://gd/coop_selection.gd")
var checks = 0
var failures = 0
var deployments: Array = []

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func inject_key(key: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	var preparation = CoopSelection.new()
	preparation.catalog = Catalog.new()
	preparation.size = Vector2(568, 320)
	preparation.deployed.connect(func(configurations: Array, friendly_fire: bool): deployments.append({"configurations": configurations, "friendly_fire": friendly_fire}))
	root.add_child(preparation)
	await process_frame
	await process_frame
	check(preparation.selections.size() == 2 and preparation.configurations().size() == 2, "both players receive compatible independent default loadouts")
	check(not preparation.friendly_fire and preparation.ready_players == [false, false], "friendly fire and readiness default off")
	check(preparation.size.x == 568 and preparation.scroll.size.x <= 568, "minimum desktop width fits both columns without horizontal overflow")
	check(preparation.scroll.get_v_scroll_bar().max_value > preparation.scroll.size.y, "minimum desktop height can scroll to all controls")
	var popup: PopupMenu = preparation.selectors[0][0].get_popup()
	preparation.selectors[0][0].show_popup()
	await process_frame
	await inject_key(KEY_DOWN)
	check(not popup.visible and preparation.cursors == [0, 1], "actual P2 arrow input escapes P1 mouse dropdown and moves only P2 cursor")
	preparation.handle_key(KEY_UP)
	preparation.selectors[1][0].show_popup()
	await process_frame
	var previous_character: String = preparation.selections[0].character_id
	await inject_key(KEY_D)
	check(preparation.selections[0].character_id != previous_character and preparation.selections[1].character_id == previous_character, "actual P1 D input escapes P2 mouse dropdown and changes only P1 character")
	preparation.handle_key(KEY_A)
	preparation.cursors[1] = 3
	preparation.selectors[0][0].show_popup()
	await process_frame
	await inject_key(KEY_SHIFT)
	check(preparation.ready_players == [false, true] and deployments.is_empty(), "actual P2 Shift input confirms P2 readiness through P1 popup")
	preparation.confirm_ready(1)
	preparation.cursors[1] = 0
	var p2_selection: Dictionary = preparation.selections[1].duplicate()
	preparation.handle_key(KEY_D)
	check(preparation.selections[0].character_id != p2_selection.character_id and preparation.selections[1] == p2_selection, "P1 D changes only P1 character")
	check(preparation.configurations().size() == 2, "character change selects compatible body and weapon")
	preparation.handle_key(KEY_S)
	preparation.handle_key(KEY_SPACE)
	check(preparation.cursors == [2, 0] and preparation.ready_players == [false, false], "P1 Space confirms selected row without marking ready early")
	var old_weapon: String = preparation.selections[0].weapon_id
	preparation.handle_key(KEY_D)
	check(preparation.selections[0].weapon_id != old_weapon and preparation.selections[1] == p2_selection, "P1 weapon selection stays independent")
	preparation.handle_key(KEY_S)
	preparation.handle_key(KEY_SPACE)
	check(preparation.ready_players == [true, false] and deployments.is_empty(), "P1 readiness alone never deploys")
	preparation.handle_key(KEY_W)
	check(preparation.ready_players == [true, false], "cursor navigation preserves readiness")
	preparation.handle_key(KEY_A)
	check(preparation.ready_players == [false, false], "changing own equipment invalidates own readiness")
	preparation.handle_key(KEY_S)
	preparation.handle_key(KEY_SPACE)
	preparation.handle_key(KEY_SHIFT)
	check(preparation.ready_players == [true, false] and preparation.cursors[1] == 1, "P2 Shift confirms own row and does not affect P1")
	preparation.handle_key(KEY_DOWN)
	preparation.handle_key(KEY_RIGHT)
	check(preparation.selections[1].weapon_id != p2_selection.weapon_id, "arrow keys change P2 compatible weapon")
	preparation.friendly_fire_button.toggled.emit(true)
	check(preparation.friendly_fire and preparation.ready_players == [false, false], "friendly fire changes invalidate readiness for both players")
	preparation.handle_key(KEY_SPACE)
	preparation.handle_key(KEY_SPACE)
	check(preparation.ready_players == [false, false], "own confirm cancels readiness")
	preparation.handle_key(KEY_SPACE)
	preparation.handle_key(KEY_DOWN)
	preparation.handle_key(KEY_SHIFT)
	check(deployments.size() == 1 and deployments[0].friendly_fire, "both independent ready confirmations deploy exactly once with selected friendly fire")
	check(deployments[0].configurations[0].weapon.id == preparation.selections[0].weapon_id and deployments[0].configurations[1].weapon.id == preparation.selections[1].weapon_id, "deployment carries both chosen resources")
	preparation.handle_key(KEY_SPACE)
	preparation.handle_key(KEY_SHIFT)
	check(deployments.size() == 1, "held or repeated confirms cannot deploy twice")
	preparation.reset_ready()
	check(preparation.ready_players == [false, false] and preparation.friendly_fire, "replay resets both readiness flags and retains options")
	preparation.selectors[0][0].item_selected.emit(0)
	preparation.selectors[1][0].item_selected.emit(0)
	preparation.selectors[0][2].item_selected.emit(0)
	preparation.selectors[1][2].item_selected.emit(0)
	check(preparation.selections[0] == preparation.selections[1], "mouse selectors allow duplicate loadouts")
	preparation.ready_buttons[0].pressed.emit()
	check(preparation.ready_players == [true, false], "mouse P1 ready button acts independently")
	preparation.ready_buttons[1].pressed.emit()
	check(deployments.size() == 2, "mouse P2 ready starts replay only when both ready")
	check(deployments[1].configurations[0] != deployments[1].configurations[1], "duplicate loadouts create separate mutable resources")
	preparation.show_error("Không tìm được vị trí spawn P2 hợp lệ")
	check(preparation.error_label.visible and preparation.error_label.text.contains("P2") and preparation.ready_players == [false, false] and not preparation.deployed_once, "invalid deployment reports error and permits fresh readiness")
	preparation.ready_buttons[0].pressed.emit()
	check(not preparation.error_label.visible and preparation.ready_players == [true, false], "retry clears old deployment error")
	preparation.queue_free()
	await process_frame
	print("LOCAL CO-OP SELECTION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
