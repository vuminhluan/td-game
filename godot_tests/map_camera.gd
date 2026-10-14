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
	check(ProjectSettings.get_setting("display/window/handheld/orientation") == DisplayServer.SCREEN_LANDSCAPE, "handheld project setting locks landscape")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if not ("sim" in game) or game.sim == null:
		check(false, "main scene initializes simulation")
		game.queue_free()
		quit(1)
		return
	game.set_process(false)
	game.map_preparation.confirm_selection()
	game.sim.status = "playing"
	game.refresh_hud()
	for viewport_size in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 768), Vector2i(844, 390), Vector2i(932, 430), Vector2i(568, 320), Vector2i(375, 667)]:
		root.size = viewport_size
		await process_frame
		game.layout()
		check(game.safe_rect.encloses(game.board_rect), "battle viewport stays in safe region: %s" % viewport_size)
		check(Vector2(game.battle_viewport.size).is_equal_approx(game.board_rect.size.floor()), "viewport uses screen pixels: %s" % viewport_size)
		var original_dimensions: Vector2i = game.sim.dimensions
		var original_position: Vector2 = game.sim.player.pos
		for dimensions in [Vector2i(80, 60), Vector2i(5, 4)]:
			game.sim.dimensions = dimensions
			var world = Vector2(dimensions) * 40
			for point in [Vector2.ZERO, world / 2, world, Vector2(-100, world.y + 100)]:
				game.sim.player.pos = point
				game.update_camera()
				var view: Vector2 = Vector2(game.battle_viewport.size) / game.camera.zoom
				var center: Vector2 = game.camera.position
				if not game.mobile:
					check(view.x + 0.001 >= world.x and view.y + 0.001 >= world.y, "desktop fits complete authored map: %s / %s" % [dimensions, viewport_size])
				check(is_equal_approx(center.x, world.x / 2) if world.x <= view.x else center.x >= view.x / 2 - 0.001 and center.x <= world.x - view.x / 2 + 0.001, "horizontal camera bounds: %s / %s" % [dimensions, viewport_size])
				check(is_equal_approx(center.y, world.y / 2) if world.y <= view.y else center.y >= view.y / 2 - 0.001 and center.y <= world.y - view.y / 2 + 0.001, "vertical camera bounds: %s / %s" % [dimensions, viewport_size])
				var screen: Vector2 = game.world_to_screen(point)
				check(game.screen_to_world(screen).is_equal_approx(point), "screen/world round trip")
				var rendered: Vector2 = game.board_rect.position + game.battle_viewport.canvas_transform * point
				check(rendered.distance_to(screen) < 1.1, "coordinate conversion matches actual Camera2D canvas transform")
		game.sim.dimensions = original_dimensions
		game.sim.player.pos = original_position
		game.update_camera()
		if game.mobile and viewport_size.x > viewport_size.y:
			var world_height: float = original_dimensions.y * 40
			var view_height: float = game.battle_viewport.size.y / game.camera.zoom.y
			if world_height > view_height:
				game.sim.player.pos.y = view_height / 2
				game.update_camera()
				var northern_center: float = game.camera.position.y
				game.sim.player.pos.y = world_height - view_height / 2
				game.update_camera()
				check(game.camera.position.y > northern_center + 1, "landscape follows player along street: %s" % viewport_size)
				game.sim.player.pos = original_position
				game.update_camera()
		for action in game.touch_rects:
			var rect: Rect2 = game.touch_rects[action]
			check(game.safe_rect.encloses(rect), "touch control within safe region: " + action)
			check(game.pointer_action(rect.get_center()) == action, "screen input hits fixed control: " + action)
		if game.mobile:
			var move_event = InputEventScreenTouch.new()
			move_event.index = 0
			move_event.position = game.touch_rects.right.get_center()
			move_event.pressed = true
			game._input(move_event)
			var fire_event = InputEventScreenTouch.new()
			fire_event.index = 1
			fire_event.position = game.touch_rects.fire.get_center()
			fire_event.pressed = true
			game._input(fire_event)
			check(game.input_direction() == "right" and "fire" in game.pointers.values(), "two fingers independently move and fire")
			move_event.pressed = false
			game._input(move_event)
			check(game.input_direction() == "" and "fire" in game.pointers.values(), "releasing direction keeps fire held")
			fire_event.pressed = false
			game._input(fire_event)
			check(game.pointers.is_empty(), "releasing both clears touches")
	game.queue_free()
	await process_frame
	await custom_map_checks()
	print("MAP CAMERA: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func custom_map_checks() -> void:
	var definition = load("res://scenes/maps/industrial_yard.tscn").instantiate()
	definition.map_id = "camera_custom_map"
	definition.dimensions = Vector2i(29, 25)
	var chosen = PackedScene.new()
	check(chosen.pack(definition) == OK, "pack alternate authored map")
	definition.free()
	var game = load("res://scenes/main.tscn").instantiate()
	game.map_scene = chosen
	root.size = Vector2i(1280, 720)
	root.add_child(game)
	await process_frame
	if not ("sim" in game) or game.sim == null:
		check(false, "main scene initializes simulation")
		game.queue_free()
		quit(1)
		return
	game.set_process(false)
	game.map_preparation.confirm_selection()
	check(game.sim.map_scene.map_id == "camera_custom_map" and game.sim.dimensions == Vector2i(29, 25), "main creates explicitly selected map")
	game.apply_selection("robot", "robot_body", "gatling")
	check(game.sim.map_scene.map_id == "camera_custom_map" and game.sim.dimensions == Vector2i(29, 25), "loadout change retains selected map")
	check(game.sim.loadout.weapon.id == "gatling", "loadout change applies on selected map")
	game.activate()
	check(game.sim.status == "playing", "custom map deployment passes validation")
	game.sim.status = "lost"
	game.activate()
	check(game.sim.map_scene.map_id == "camera_custom_map" and game.sim.dimensions == Vector2i(29, 25), "replay retains selected map")
	check(game.sim.loadout.weapon.id == "gatling" and game.sim.status == "playing", "replay retains selected loadout and deploys")
	game.queue_free()
	await process_frame
