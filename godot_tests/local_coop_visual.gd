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

func capture(name: String) -> Image:
	var image: Image = await rendered_frame()
	var path := "/private/tmp/local-coop-" + name + ".png"
	check(image.save_png(path) == OK, "save local co-op screenshot: " + name)
	check(image.get_size() == root.size, "native screenshot matches viewport size: " + name)
	return image

func check_cameras(game: Control) -> void:
	var viewports: Array = [game.battle_viewport, game.second_viewport]
	var cameras: Array = [game.camera, game.second_camera]
	for index in 2:
		var viewport: SubViewport = viewports[index]
		var view_camera: Camera2D = cameras[index]
		var point: Vector2 = game.sim.players[index].actor.pos
		var expected: Vector2 = Vector2(viewport.size) / 2 + (point - view_camera.position) * view_camera.zoom
		var actual: Vector2 = viewport.canvas_transform * point
		check(actual.distance_to(expected) < 1.1, "P%d actual canvas transform follows its own camera" % (index + 1))
		check(Rect2(Vector2.ZERO, Vector2(viewport.size)).has_point(actual), "P%d stays visible in its own viewport" % (index + 1))
		var visible_world: Vector2 = Vector2(viewport.size) / view_camera.zoom
		var world: Vector2 = game.sim.world_size
		var expected_center := Vector2(world.x / 2 if world.x <= visible_world.x else clampf(point.x, visible_world.x / 2, world.x - visible_world.x / 2), world.y / 2 if world.y <= visible_world.y else clampf(point.y, visible_world.y / 2, world.y - visible_world.y / 2))
		check(view_camera.position.distance_to(expected_center) < 0.01, "P%d camera respects map boundaries" % (index + 1))
	check(not game.battle_viewport.canvas_transform.is_equal_approx(game.second_viewport.canvas_transform), "distant players produce independent rendered camera transforms")

func check_view_content(game: Control, image: Image) -> void:
	for index in 2:
		var rect: Rect2 = game.player_rects[index]
		var colors: Dictionary = {}
		for y in range(int(rect.position.y) + 12, int(rect.end.y) - 12, 10):
			for x in range(int(rect.position.x) + 12, int(rect.end.x) - 12, 10):
				colors[image.get_pixel(x, y).to_rgba32()] = true
		check(colors.size() > 20, "P%d viewport renders map and actor content" % (index + 1))
		check(game.player_huds[index].visible and ("P%d" % (index + 1)) in game.player_huds[index].status_label.text, "P%d has its personal HUD" % (index + 1))

func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	await capture("mode")
	game.choose_mode("coop")
	game.map_preparation.confirm_selection()
	game.coop_preparation.choose_option(game.coop_preparation.option_ids(1, 0).find("tank"), 1, 0)
	game.coop_preparation.choose_option(1, 1, 2)
	game.coop_preparation.confirm_ready(0)
	check(game.coop_preparation.visible and game.sim.players.size() == 1, "first readiness leaves both loadout panels visible")
	await capture("preparation")
	game.coop_preparation.confirm_ready(1)
	check(game.sim.players.size() == 2 and game.sim.status == "playing", "both ready players deploy together")
	check(game.sim.players[0].loadout.character_id == "robot" and game.sim.players[1].loadout.character_id == "tank", "deployed render uses distinct player characters")
	game.sim.players[0].actor.pos = Vector2(340, 440)
	game.sim.players[1].actor.pos = Vector2(460, 440)
	game.sim.players[1].actor.dir = "left"
	game.sim.players[1].active_power_ups.shield = 6.0
	game.update_camera()
	game.refresh_hud()
	game.battle.queue_redraw()
	await capture("actors")
	for entry in [[Vector2i(1280, 720), "landscape"], [Vector2i(720, 1000), "portrait"]]:
		root.size = entry[0]
		await process_frame
		game.sim.status = "playing"
		game.sim.players[0].actor.pos = Vector2(100, 220)
		game.sim.players[1].actor.pos = Vector2(740, 580)
		game.layout()
		game.refresh_hud()
		game.battle.queue_redraw()
		game.queue_redraw()
		var image: Image = await capture(entry[1])
		check(game.player_rects.size() == 2 and not game.player_rects[0].intersects(game.player_rects[1]), "split viewports never overlap: " + entry[1])
		check(game.player_rects[0].position.x < game.player_rects[1].position.x if entry[1] == "landscape" else game.player_rects[0].position.y < game.player_rects[1].position.y, "split orientation matches window: " + entry[1])
		check_cameras(game)
		check_view_content(game, image)
	var invalid_configs: Array = game.coop_preparation.configurations()
	invalid_configs[1].collider_radius = 2000
	game.deploy_coop(invalid_configs, false)
	check(game.sim.status == "invalid" and game.coop_preparation.visible and game.coop_preparation.error_label.visible, "invalid spawn renders a recoverable preparation error")
	await capture("invalid-map")
	game.queue_free()
	await process_frame
	print("LOCAL COOP VISUAL: %d checks, %d failures; 6 screenshots" % [checks, failures])
	quit(1 if failures else 0)
