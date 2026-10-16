extends SceneTree
const Main = preload("res://gd/main.gd")
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

func key(game: Control, code: int, pressed: bool = true) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	game._input(event)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(game.mode_preparation.visible and not game.map_preparation.visible, "launch asks for play mode")
	check(game.coop_button.visible, "native keyboard desktop offers local co-op")
	var mode_column = game.coop_button.get_parent()
	check(mode_column.get_child(mode_column.get_child_count() - 1).disabled, "Play with friend remains disabled")
	game.web_touch = true
	root.size = Vector2i(320, 568)
	await process_frame
	game.layout()
	check(game.safe_rect.encloses(game.mode_preparation.get_rect()), "mode menu fits narrow mobile viewport")
	check(not game.coop_button.visible, "touch devices hide local co-op independently of window size")
	game.choose_mode("coop")
	check(game.play_mode == "single", "touch device cannot enter co-op through callback")
	game.web_touch = false
	root.size = Vector2i(1280, 720)
	await process_frame
	game.layout()
	game.choose_mode("coop")
	check(game.play_mode == "coop" and game.map_preparation.visible and not game.coop_preparation.visible, "co-op selects map before loadouts")
	game.map_preparation.select_map(CITY)
	game.map_preparation.confirm_selection()
	check(game.coop_preparation.visible and not game.preparation.visible, "co-op has independent two-player preparation")
	game.coop_preparation.choose_option(1, 1, 0)
	game.coop_preparation.set_friendly_fire(true)
	for press in 4:
		key(game, KEY_SPACE)
	check(game.sim.status == "ready" and game.coop_preparation.ready_players == [true, false], "P1 ready never starts alone")
	game.activate()
	check(game.sim.status == "ready", "single-player deploy action cannot bypass co-op readiness")
	for press in 4:
		key(game, KEY_SHIFT)
	check(game.sim.status == "playing" and game.sim.players.size() == 2, "P2 independent confirmation starts co-op")
	check(game.sim.friendly_fire and game.sim.players[1].loadout.character_id == "tank", "deployment carries P2 loadout and friendly-fire option")
	check(game.sim.map_scene.map_id == "abandoned_city_day", "both players deploy on selected map")
	check(not game.coop_preparation.visible and game.second_container.visible, "deployed game shows two views")
	check(game.battle_viewport.world_2d == game.second_viewport.world_2d, "both cameras observe the same simulation world")
	check(game.player_huds[0].visible and game.player_huds[1].visible and not game.power_up_hud.visible, "each viewport owns its personal HUD")
	check("P1" in game.player_huds[0].status_label.text and "P2" in game.player_huds[1].status_label.text, "personal HUDs identify the correct players")
	check(game.player_inputs.all(func(source): return source.command().direction == "" and not source.shooting), "deployment confirmations do not leak into combat input")
	game.sim.players[0].actor.pos = Vector2(300, 380)
	game.sim.players[1].actor.pos = Vector2(540, 380)
	key(game, KEY_D)
	key(game, KEY_LEFT)
	check(game.player_inputs[0].command().direction == "right" and game.player_inputs[1].command().direction == "left", "WASD and arrows drive separate players")
	var before1: Vector2 = game.sim.players[0].actor.pos
	var before2: Vector2 = game.sim.players[1].actor.pos
	game._process(0.05)
	check(game.sim.players[0].actor.pos.x > before1.x and game.sim.players[1].actor.pos.x < before2.x, "both independent commands reach simulation in the same frame")
	key(game, KEY_SPACE)
	check(game.player_inputs[0].shooting and not game.player_inputs[1].shooting, "Space fires only P1")
	key(game, KEY_SHIFT)
	check(game.player_inputs[1].shooting, "Shift fires P2 simultaneously")
	key(game, KEY_D, false)
	check(game.player_inputs[0].held.is_empty() and game.player_inputs[1].command().direction == "left", "releasing one player's key preserves teammate input")
	game.focus_lost()
	check(game.sim.status == "paused" and game.player_inputs.all(func(source): return source.held.is_empty() and not source.shooting), "focus loss pauses shared match and clears both players")
	var time: float = game.sim.elapsed
	game._process(0.05)
	check(game.sim.elapsed == time, "pause freezes simulation for both players")
	game.activate()
	check(game.sim.status == "playing" and game.sim.players.size() == 2, "resume keeps co-op state")
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(720, 1000), Vector2i(568, 320)]:
		root.size = dimensions
		await process_frame
		game.layout()
		var first: Rect2 = game.player_rects[0]
		var second: Rect2 = game.player_rects[1]
		check(game.board_rect.encloses(first) and game.board_rect.encloses(second) and not first.intersects(second), "split viewports fit battlefield without overlap: " + str(dimensions))
		check(second.position.x > first.position.x if dimensions.x >= dimensions.y else second.position.y > first.position.y, "split orientation follows window aspect: " + str(dimensions))
		check(not game.touch_surface.visible, "small keyboard windows never show co-op touch controls")
		for index in 2:
			var camera: Camera2D = game.camera if index == 0 else game.second_camera
			var viewport: SubViewport = game.battle_viewport if index == 0 else game.second_viewport
			var state: Dictionary = game.sim.players[index]
			for point in [Vector2.ZERO, game.sim.world_size]:
				state.actor.pos = point
				game.update_camera()
				var screen: Vector2 = game.world_to_screen(point, index)
				check(game.screen_to_world(screen, index).distance_to(point) < 0.01, "per-player coordinate conversion round trips")
				var visible_world = Vector2(viewport.size) / camera.zoom
				var world: Vector2 = game.sim.world_size
				check(is_equal_approx(camera.position.x, world.x / 2) if visible_world.x >= world.x else camera.position.x >= visible_world.x / 2 - 0.01 and camera.position.x <= world.x - visible_world.x / 2 + 0.01, "co-op horizontal camera clamp")
				check(is_equal_approx(camera.position.y, world.y / 2) if visible_world.y >= world.y else camera.position.y >= visible_world.y / 2 - 0.01 and camera.position.y <= world.y - visible_world.y / 2 + 0.01, "co-op vertical camera clamp")
	game.sim.status = "lost"
	game.refresh_hud()
	check(game.coop_preparation.visible and game.coop_preparation.ready_players == [false, false] and "THUA TRẬN" in game.coop_preparation.heading.text, "defeat returns both players to unready loadouts with result")
	game.coop_preparation.confirm_ready(0)
	check(game.sim.status == "lost", "replay still waits for both players")
	game.coop_preparation.confirm_ready(1)
	check(game.sim.status == "playing" and game.sim.players.size() == 2 and game.sim.friendly_fire, "replay retains mode, map, both loadouts and friendly-fire")
	game.sim.status = "won"
	game.refresh_hud()
	check(game.coop_preparation.visible and game.coop_preparation.ready_players == [false, false] and "THẮNG TRẬN" in game.coop_preparation.heading.text, "victory also resets independent readiness with result")
	var invalid_configs: Array = game.coop_preparation.configurations()
	invalid_configs[1].collider_radius = 2000
	game.deploy_coop(invalid_configs, false)
	check(game.sim.status == "invalid" and game.coop_preparation.visible and game.coop_preparation.error_label.visible, "unplaceable P2 shows clear deployment error with map navigation")
	check(game.coop_preparation.ready_players == [false, false], "invalid deployment requires fresh confirmations")
	game.show_map_selection()
	game.map_preparation.confirm_selection()
	check(game.sim.status == "ready" and not game.coop_preparation.error_label.visible, "reselecting a map clears stale deployment error")
	game.show_map_selection()
	game.show_mode_selection()
	game.choose_mode("single")
	game.map_preparation.confirm_selection()
	game.activate()
	check(game.sim.players.size() == 1 and not game.second_container.visible and game.sim.status == "playing", "switching back to single-player restores one viewport and actor")
	game.queue_free()
	await process_frame
	print("LOCAL CO-OP INTEGRATION: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
