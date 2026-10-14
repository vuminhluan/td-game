extends SceneTree
const R = preload("res://gd/rules.gd")
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func capture(game: Control, path: String) -> void:
	game.refresh_hud()
	game.battle.queue_redraw()
	game.power_up_hud.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(path) != OK:
		failures += 1

func run() -> void:
	root.size = Vector2i(1280, 1000)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.map_preparation.confirm_selection()
	game.activate()
	var index = 0
	for kind in preload("res://gd/pickup_settings.gd").POWER_UP_IDS:
		game.sim.active_power_ups[kind] = 5.0 - index * 0.75
		game.sim.power_ups.append({"kind": kind, "pos": Vector2(260 + index * 80, 380), "life": 10.0})
		index += 1
	await capture(game, "res://docs/images/power-ups-desktop.png")
	game.toggle_pause()
	await capture(game, "/private/tmp/power-ups-paused.png")
	root.size = Vector2i(320, 568)
	await process_frame
	game.layout()
	game.sim.pause()
	await capture(game, "/private/tmp/power-ups-mobile.png")
	var hud_end: Vector2 = game.power_up_hud.position + game.power_up_hud.size * game.power_up_hud.scale
	if hud_end.x > game.board_rect.end.x or hud_end.y > game.board_rect.end.y:
		failures += 1
	if game.power_up_hud._get_tooltip(Vector2(19, 19)) != "Khiên robot · 5.0 giây":
		failures += 1
	game.sim.status = "lost"
	game.activate()
	if game.power_up_hud.sim != game.sim or not game.sim.active_power_ups.is_empty():
		failures += 1
	game.queue_free()
	await process_frame
	print("POWER UP VISUAL: 3 screenshots, %d failures" % failures)
	quit(1 if failures else 0)
