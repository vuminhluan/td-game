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
	game.activate()
	game.sim.spawn_timer = 999
	game.sim.enemies.clear()
	for kind_index in 2:
		for dir_index in 4:
			var enemy = game.sim.make_actor("tank" if kind_index == 0 else "robot", Vector2(260 + dir_index * 140, 320 + kind_index * 180))
			enemy.dir = ["down", "up", "left", "right"][dir_index]
			enemy.hp -= 1
			game.sim.enemies.append(enemy)
	game.battle.queue_redraw()
	await capture("res://docs/images/enemy-sprites-in-game.png")
	game.queue_free()
	await process_frame
	var preview = load("res://scenes/enemy_sprite_preview.tscn").instantiate()
	root.add_child(preview)
	await capture("res://docs/images/enemy-sprites-four-directions.png")
	preview.queue_free()
	await process_frame
	print("ENEMY VISUAL: eight in-game views and 24 animation board captured")
	quit()
