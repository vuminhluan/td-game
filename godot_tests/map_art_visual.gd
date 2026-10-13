extends SceneTree
const R = preload("res://gd/rules.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(1280, 1000)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.activate()
	game.camera.zoom = Vector2.ONE * 0.75
	game.update_camera()
	game.sim.spawn_timer = 999
	for i in 3:
		var enemy = game.sim.make_actor("tank" if i == 0 else "robot", Vector2(220 + i * 200, 300))
		enemy.dir = ["right", "down", "left"][i]
		game.sim.enemies.append(enemy)
	game.battle.queue_redraw()
	var intact: Image = await frame_image()
	check(intact.save_png("res://docs/images/map-art-in-game.png") == OK, "save map screenshot")
	var brick_point := Vector2(4, 1) * R.TILE + Vector2.ONE * 20
	var screen_point: Vector2 = game.world_to_screen(brick_point)
	var region := Rect2i(Vector2i(screen_point) - Vector2i(14, 14), Vector2i(28, 28))
	var previous := intact.get_region(region).get_data()
	for hp in [2, 1, 0]:
		game.sim.damage_brick(brick_point)
		game.battle.queue_redraw()
		var image: Image = await frame_image()
		var pixels := image.get_region(region).get_data()
		check(pixels != previous, "render changes at brick HP %d" % hp)
		previous = pixels
	game.sim.damage_brick(Vector2(12, 1) * R.TILE + Vector2.ONE * 20)
	game.sim.damage_brick(Vector2(13, 1) * R.TILE + Vector2.ONE * 20)
	game.sim.damage_brick(Vector2(13, 1) * R.TILE + Vector2.ONE * 20)
	game.sim.base_hp = 0
	game.battle.queue_redraw()
	var ruined: Image = await frame_image()
	check(ruined.save_png("res://docs/images/map-art-damage.png") == OK, "save damage screenshot")
	var base_screen: Vector2 = game.world_to_screen(game.sim.base_position)
	var base_region := Rect2i(Vector2i(base_screen) - Vector2i(35, 35), Vector2i(70, 70))
	check(ruined.get_region(base_region).get_data() != intact.get_region(base_region).get_data(), "base destruction changes rendered art")
	game.sim.status = "lost"
	game.activate()
	game.camera.zoom = Vector2.ONE * 0.75
	game.update_camera()
	game.battle.queue_redraw()
	var replay: Image = await frame_image()
	check(replay.get_region(region).get_data() == intact.get_region(region).get_data(), "replay restores visible intact brick")
	check(replay.get_region(base_region).get_data() == intact.get_region(base_region).get_data(), "replay restores visible headquarters")
	game.queue_free()
	await process_frame
	print("MAP VISUAL: brick damage/destruction, base destruction and replay; %d failures" % failures)
	quit(1 if failures else 0)
