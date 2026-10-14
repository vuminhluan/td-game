extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Could not capture " + path)
		quit(1)

func run() -> void:
	root.size = Vector2i(1280, 1000)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.map_preparation.confirm_selection()
	await capture("/private/tmp/player-loadout-desktop.png")
	game.weapon_selector.select(1)
	game.select_loadout(1)
	game.activate()
	game.sim.player.cooldown = 0
	game.sim.update(0.01, "up", true)
	game.refresh_hud()
	game.battle.queue_redraw()
	await capture("/private/tmp/player-loadout-twin-battle.png")
	root.size = Vector2i(390, 844)
	game.sim.status = "lost"
	game.refresh_hud()
	game.layout()
	await capture("/private/tmp/player-loadout-mobile.png")
	game.queue_free()
	await process_frame
	root.size = Vector2i(1280, 1000)
	var preview = load("res://gd/player_loadout_preview.gd").new()
	root.add_child(preview)
	await process_frame
	preview.set_process(false)
	await capture("res://docs/images/player-loadout-directions.png")
	for entry in preview.previews:
		if entry.state == "attack":
			entry.view.sim.player.shot_clock = entry.view.sim.player.shot_duration * 0.65
		entry.view.queue_redraw()
	await capture("/private/tmp/player-loadout-flashes.png")
	preview.set_process(true)
	for frame in 90:
		await process_frame
	preview.set_process(false)
	await capture("/private/tmp/player-loadout-animation.png")
	preview.queue_free()
	await process_frame
	print("PLAYER LOADOUT VISUAL: desktop, mobile, battle and 24 animation views captured")
	quit()
