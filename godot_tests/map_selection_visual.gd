extends SceneTree

const Sim = preload("res://gd/simulation.gd")
const View = preload("res://gd/battle_view.gd")
const CITY = preload("res://scenes/maps/abandoned_city.tscn")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image.save_png(path) != OK:
		push_error("Unable to capture " + path)
		quit(1)

func run() -> void:
	var simulation := Sim.new(null, CITY)
	var view := View.new()
	view.map_skin = simulation.map_scene.map_skin
	view.sim = simulation
	root.size = simulation.world_size
	root.add_child(view)
	await capture("res://assets/maps/previews/abandoned-city.png")
	view.queue_free()
	await process_frame
	if "--preview-only" in OS.get_cmdline_user_args():
		print("MAP SELECTION VISUAL: city preview captured for reimport")
		quit()
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.size = Vector2i(1280, 1000)
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.choose_mode("single")
	await capture("res://docs/images/map-selection-desktop.png")
	game.map_preparation.select_map(CITY)
	await capture("/private/tmp/map-selection-city.png")
	game.map_preparation.confirm_selection()
	await capture("res://docs/images/character-selection-desktop.png")
	root.size = Vector2i(390, 844)
	await process_frame
	game.layout()
	game.show_map_selection()
	game.layout()
	await capture("res://docs/images/map-selection-mobile.png")
	root.size = Vector2i(1280, 720)
	game.map_preparation.select_map(CITY)
	game.map_preparation.confirm_selection()
	game.layout()
	game.activate()
	game.sim.spawn_timer = 999
	game.sim.power_up_timer = 999
	await capture("res://docs/images/abandoned-city-in-game.png")
	var visible_world: Vector2 = Vector2(game.battle_viewport.size) / game.camera.zoom
	check(visible_world.x >= game.sim.world_size.x - 0.1 and visible_world.y >= game.sim.world_size.y - 0.1, "desktop capture contains the entire city playable map")
	root.size = Vector2i(844, 390)
	await process_frame
	game.layout()
	game.refresh_hud()
	visible_world = Vector2(game.battle_viewport.size) / game.camera.zoom
	check(visible_world.y < game.sim.world_size.y, "landscape phone scrolls along the avenue")
	var first_position: Vector2 = game.camera.position
	game.sim.player.pos = Vector2(game.sim.world_size.x / 2, 40)
	game.update_camera()
	game.battle.queue_redraw()
	check(game.camera.position.y < first_position.y, "landscape camera follows player north along the city avenue")
	await capture("res://docs/images/abandoned-city-mobile.png")
	game.sim.player.pos = game.sim.world_size / 2
	game.update_camera()
	game.battle.queue_redraw()
	await capture("/private/tmp/abandoned-city-mobile-intersection.png")
	game.queue_free()
	await process_frame
	print("MAP SELECTION VISUAL: %d checks, %d failures; city overview, desktop/mobile battle and selection screens captured" % [checks, failures])
	quit(1 if failures else 0)
