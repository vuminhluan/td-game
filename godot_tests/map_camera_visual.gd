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

func rendered_frame() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func camera_checks(game: Control, target: Vector2) -> void:
	game.sim.player.pos = target
	game.update_camera()
	game.battle.queue_redraw()
	game.queue_redraw()
	await rendered_frame()
	var world: Vector2 = Vector2(game.sim.dimensions) * 40
	var view: Vector2 = Vector2(game.battle_viewport.size) / game.camera.zoom
	var center: Vector2 = game.camera.position
	check(is_equal_approx(center.x, world.x / 2) if world.x <= view.x else center.x >= view.x / 2 - 0.001 and center.x <= world.x - view.x / 2 + 0.001, "rendered horizontal bounds")
	check(is_equal_approx(center.y, world.y / 2) if world.y <= view.y else center.y >= view.y / 2 - 0.001 and center.y <= world.y - view.y / 2 + 0.001, "rendered vertical bounds")
	var screen: Vector2 = game.world_to_screen(target)
	var actual: Vector2 = game.board_rect.position + game.battle_viewport.canvas_transform * target
	check(actual.distance_to(screen) < 1.1, "rendered Camera2D matches world_to_screen")
	check(game.screen_to_world(screen).is_equal_approx(target), "rendered screen/world round trip")
	if world.x > view.x and target.x > view.x / 2 and target.x < world.x - view.x / 2:
		check(is_equal_approx(center.x, target.x), "camera follows player horizontally")
	if world.y > view.y and target.y > view.y / 2 and target.y < world.y - view.y / 2:
		check(is_equal_approx(center.y, target.y), "camera follows player vertically")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if not ("sim" in game) or game.sim == null:
		check(false, "main scene initializes simulation")
		game.queue_free()
		quit(1)
		return
	game.activate()
	game.set_process(false)
	game.sim.spawn_timer = 999
	game.sim.power_up_timer = 999
	var spawn: Vector2 = game.sim.player.pos
	game.sim.weapon_pickups.append({"pos": spawn + Vector2(160, -80), "kind": "gatling", "life": 20.0})
	game.sim.enemies.append(game.sim.make_actor("tank", spawn + Vector2(-180, -180)))
	for entry in [[Vector2i(1280, 720), "desktop"], [Vector2i(844, 390), "mobile"], [Vector2i(568, 320), "small"], [Vector2i(375, 667), "portrait"]]:
		root.size = entry[0]
		await process_frame
		game.layout()
		game.refresh_hud()
		var world: Vector2 = Vector2(game.sim.dimensions) * 40
		for point in [Vector2(40, 40), world / 2, world - Vector2(40, 40), spawn]:
			await camera_checks(game, point)
		var image: Image = await rendered_frame()
		check(image.get_size() == root.size, "native capture matches viewport size")
		var colors: Dictionary = {}
		for y in range(int(game.board_rect.position.y) + 8, int(game.board_rect.end.y) - 8, 12):
			for x in range(int(game.board_rect.position.x) + 8, int(game.board_rect.end.x) - 8, 12):
				colors[image.get_pixel(x, y).to_rgba32()] = true
		check(colors.size() > 12, "native viewport renders terrain and actors")
		var path: String = "/private/tmp/map-camera-" + entry[1] + ".png"
		check(image.save_png(path) == OK, "save camera screenshot: " + path)
	game.queue_free()
	await process_frame
	print("MAP CAMERA VISUAL: %d checks, %d failures; 4 screenshots" % [checks, failures])
	quit(1 if failures else 0)
