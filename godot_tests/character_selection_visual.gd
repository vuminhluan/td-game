extends SceneTree
const Catalog = preload("res://gd/character_catalog.gd")
const Sim = preload("res://gd/simulation.gd")
const View = preload("res://gd/battle_view.gd")
var catalog = Catalog.new()

class ActorView extends View:
	var body_only = false
	func _ready() -> void:
		pass
	func _process(_dt: float) -> void:
		pass
	func _draw() -> void:
		if body_only:
			draw_set_transform(sim.player.pos)
			var skin: Resource = sim.loadout.body
			var texture: Texture2D = skin.frame_for(sim.player, sim.elapsed)
			var rect = Rect2(-skin.anchor_for(sim.player.dir) * skin.texture_scale, texture.get_size() * skin.texture_scale)
			draw_clean_body(sim.player, texture, rect, Color.WHITE)
		else:
			draw_player(sim.player)
			if sim.player.shot_clock > 0:
				for muzzle in sim.loadout.muzzle_vectors(sim.player.dir):
					draw_circle(muzzle, 1, Color("70ffe3"))
			for effect in sim.effects:
				draw_circle(effect.pos, 3, Color("ffda81"))

func _initialize() -> void:
	call_deferred("run")

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Capture failed: " + path)
		quit(1)

func run() -> void:
	root.size = Vector2i(1280, 1000)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.map_preparation.confirm_selection()
	await capture("res://docs/images/character-selection-desktop.png")
	game.preparation.choose_character("tank")
	game.preparation.choose_weapon(2)
	await capture("/private/tmp/character-selection-tank.png")
	root.size = Vector2i(390, 844)
	await process_frame
	game.layout()
	await capture("res://docs/images/character-selection-mobile.png")
	root.size = Vector2i(320, 568)
	await process_frame
	game.layout()
	await capture("/private/tmp/character-selection-small.png")
	root.size = Vector2i(1280, 1000)
	game.layout()
	game.activate()
	game.sim.player.cooldown = 0
	game.sim.fire(game.sim.player)
	game.refresh_hud()
	game.battle.queue_redraw()
	await capture("res://docs/images/character-selection-battle.png")
	game.queue_free()
	await process_frame
	var sheet = Node2D.new()
	root.add_child(sheet)
	var row = 0
	var views: Array = []
	for character in catalog.data.characters:
		var c: Dictionary = catalog.data.characters[character]
		for weapon_id in ["body"] + c.weapons:
			var title = Label.new()
			title.text = character + " / " + weapon_id
			title.position = Vector2(10, 20 + row * 104)
			sheet.add_child(title)
			for d in 4:
				for state in 3:
					var view = ActorView.new()
					view.sim = Sim.new(catalog.create(character, c.default_body, c.default_weapon if weapon_id == "body" else weapon_id))
					view.body_only = weapon_id == "body"
					view.sim.player.pos = Vector2.ZERO
					view.sim.player.dir = ["down", "up", "left", "right"][d]
					view.sim.player.moving = state == 1
					view.sim.player.move_clock = 0.06
					view.sim.player.shot_clock = view.sim.player.shot_duration * 0.5 if state == 2 else 0.0
					view.scale = Vector2.ONE * 1.25
					view.position = Vector2(190 + (d * 3 + state) * 90, 52 + row * 104)
					sheet.add_child(view)
					views.append(view)
			row += 1
	await capture("res://docs/images/character-selection-layers.png")
	for frame in 4:
		for view in views:
			view.sim.player.move_clock = frame / 16.0
			if view.sim.player.shot_clock > 0:
				view.sim.player.shot_clock = view.sim.player.shot_duration * (1.0 - frame / 4.0)
			view.queue_redraw()
		await capture("/private/tmp/character-layers-frame-%d.png" % frame)
	sheet.queue_free()
	await process_frame
	print("CHARACTER VISUAL: desktop/mobile/small/battle, clean bodies and all 7 loadouts in 4 directions × 3 states × 4 transition frames")
	quit()
