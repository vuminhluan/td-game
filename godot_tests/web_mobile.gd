extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.size = Vector2i(2520, 1080)
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.web_viewport_changed([JSON.stringify({"width": 1260, "height": 540, "touch": true, "blocked": false})])
	await process_frame
	game.layout()
	game.sim.start()
	game.refresh_hud()
	check(game.mobile, "Web touch device stays mobile despite large backing viewport")
	check(game.size.is_equal_approx(Vector2(1260, 540)), "Web UI uses CSS pixels rather than physical backing pixels")
	check(game.touch_surface.visible, "touch controls are visible during mobile Web gameplay")
	check(game.touch_rects.size() == 5, "mobile Web has four directions and fire")
	for action in game.touch_rects:
		check(game.safe_rect.encloses(game.touch_rects[action]), "touch button remains inside logical viewport: " + action)
	var direction = InputEventScreenTouch.new()
	direction.index = 0
	direction.position = game.touch_rects.right.get_center()
	direction.pressed = true
	game._input(direction)
	var fire = InputEventScreenTouch.new()
	fire.index = 1
	fire.position = game.touch_rects.fire.get_center()
	fire.pressed = true
	game._input(fire)
	check(game.input_direction() == "right" and "fire" in game.pointers.values(), "scaled Web input supports two simultaneous fingers")
	game.web_viewport_changed([JSON.stringify({"width": 390, "height": 740, "touch": true, "blocked": true})])
	await process_frame
	check(game.sim.status == "paused", "rotating portrait pauses the active match")
	check(game.pointers.is_empty() and game.held_keys.is_empty(), "portrait clears all held input")
	check(not game.touch_surface.visible, "portrait gate hides gameplay controls")
	var pause = InputEventKey.new()
	pause.physical_keycode = KEY_P
	pause.pressed = true
	game._input(pause)
	check(game.sim.status == "paused", "input cannot resume the match behind portrait overlay")
	game.web_viewport_changed([JSON.stringify({"width": 844, "height": 346, "touch": true, "blocked": false})])
	await process_frame
	check(game.sim.status == "paused", "returning landscape waits for explicit resume")
	game.toggle_pause()
	check(game.touch_surface.visible and game.sim.status == "playing", "resume restores mobile controls after rotation")
	game.web_viewport_changed([JSON.stringify({"width": 1280, "height": 720, "touch": false, "blocked": false})])
	await process_frame
	check(not game.mobile and not game.touch_surface.visible, "desktop Web does not display mobile controls")
	game.queue_free()
	await process_frame
	print("WEB MOBILE: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
