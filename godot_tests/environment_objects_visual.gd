extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func frame_image() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func screen_region(game: Control, world_rect: Rect2) -> Rect2i:
	var start: Vector2 = game.world_to_screen(world_rect.position)
	var end: Vector2 = game.world_to_screen(world_rect.end)
	return Rect2i(Vector2i(start.floor()), Vector2i((end - start).ceil())).intersection(Rect2i(Vector2i.ZERO, root.size))

func capture_layout() -> void:
	root.size = Vector2i(840, 760)
	var overview := preload("res://gd/battle_view.gd").new()
	overview.sim = preload("res://gd/simulation.gd").new()
	root.add_child(overview)
	var image: Image = await frame_image()
	check(image.save_png("res://docs/images/industrial-layout-overview.png") == OK, "save whole layout at gameplay scale")
	overview.queue_free()
	await process_frame
	root.size = Vector2i(720, 360)
	var panels: Array[Control] = []
	for index in 2:
		var panel := Control.new()
		panel.position = Vector2(index * 360, 0)
		panel.size = Vector2(360, 360)
		panel.clip_contents = true
		root.add_child(panel)
		var view := preload("res://gd/battle_view.gd").new()
		view.sim = preload("res://gd/simulation.gd").new()
		view.scale = Vector2.ONE * 3
		view.position = Vector2(0, -1260) if index == 0 else Vector2(-2160, -780)
		panel.add_child(view)
		panels.append(panel)
	image = await frame_image()
	check(image.save_png("res://docs/images/industrial-water-line-detail.png") == OK, "save both inlet and valve assemblies from native renderer")
	for panel in panels:
		panel.queue_free()
	await process_frame

func run() -> void:
	root.size = Vector2i(1280, 1000)
	var game = load("res://scenes/main.tscn").instantiate()
	if game.get_script() == null:
		quit(1)
		return
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.activate()
	game.sim.spawn_timer = 999
	game.sim.pickup_settings.periodic_enabled = false
	game.camera.zoom = Vector2.ONE * 0.75
	game.update_camera()
	var pickup_positions: Array[Vector2] = []
	var weapon_ids: Array = game.catalog.data.weapons.keys()
	for i in weapon_ids.size():
		var point := Vector2(300 + i * 80, 140)
		pickup_positions.append(point)
		check(game.sim.place_pickup(point, "weapon", weapon_ids[i]), "fixture places actual weapon artwork: " + weapon_ids[i])
	game.battle.queue_redraw()
	var image: Image = await frame_image()
	check(image.save_png("res://docs/images/industrial-objects-in-game.png") == OK, "save new artwork in actual game")
	for label in ["WestWaterLine/Pump", "WestWaterLine/Pipe2", "EastWaterLine/Pump", "WestServiceCan"]:
		var node: Node2D = game.sim.map_scene.get_node("Environment/" + label)
		var visual_rect: Rect2 = node.definition.visual_rect
		visual_rect.position += game.sim.map_scene.to_local(node.global_position)
		var region := screen_region(game, visual_rect)
		var original := image.get_region(region).get_data()
		node.visible = false
		var hidden: Image = await frame_image()
		check(original != hidden.get_region(region).get_data(), "generated object visibly composites with terrain: " + label)
		node.visible = true
		image = await frame_image()
	game.sim.weapon_pickups.clear()
	game.battle.queue_redraw()
	var without_pickups: Image = await frame_image()
	for point in pickup_positions:
		var region := screen_region(game, Rect2(point - Vector2(20, 20), Vector2(40, 40)))
		check(image.get_region(region).get_data() != without_pickups.get_region(region).get_data(), "weapon sprite renders at pickup position: " + str(point))
	game.queue_free()
	await process_frame
	await capture_layout()
	print("ENVIRONMENT VISUAL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
