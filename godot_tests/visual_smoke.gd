extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error = root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Screenshot failed: " + path)
		quit(1)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.size = Vector2i(1280, 1000)
	root.add_child(game)
	await capture("/private/tmp/robot-defense-ready.png")
	game.map_preparation.confirm_selection()
	game.activate()
	for i in 180:
		game.sim.update(1.0 / 60, "up", true)
	game.set_process(false)
	game.refresh_hud()
	game.battle.queue_redraw()
	await capture("/private/tmp/robot-defense-desktop.png")
	game.toggle_pause()
	await capture("/private/tmp/robot-defense-paused.png")
	root.size = Vector2i(375, 667)
	await process_frame
	game.layout()
	game.sim.pause()
	game.refresh_hud()
	await capture("/private/tmp/robot-defense-mobile.png")
	root.size = Vector2i(320, 568)
	await process_frame
	game.layout()
	game.sim.status = "lost"
	game.refresh_hud()
	await capture("/private/tmp/robot-defense-small.png")
	game.queue_free()
	await process_frame
	print("VISUAL SMOKE: 5 screenshots captured")
	quit()
