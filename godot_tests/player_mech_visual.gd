extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Screenshot failed: " + path)
		quit(1)

func run() -> void:
	root.size = Vector2i(1280, 1000)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.map_preparation.confirm_selection()
	game.activate()
	game.sim.spawn_timer = 999
	for direction in ["down", "up", "left", "right"]:
		game.sim.bullets.clear()
		game.sim.effects.clear()
		game.sim.player.pos = Vector2(420, 380)
		game.sim.player.cooldown = 0
		game.sim.update(0.02, direction, true)
		game.refresh_hud()
		game.battle.queue_redraw()
		await capture("/private/tmp/robot-defense-player-" + direction + ".png")
	game.queue_free()
	await process_frame
	var preview = load("res://scenes/player_mech_preview.tscn").instantiate()
	root.add_child(preview)
	await capture("res://docs/images/player-mech-four-directions.png")
	preview.queue_free()
	await process_frame
	print("PLAYER MECH VISUAL: four main-game directions and 12-animation board captured")
	quit()
