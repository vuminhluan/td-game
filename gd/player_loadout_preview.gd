extends Node2D
const View = preload("res://gd/battle_view.gd")
const Sim = preload("res://gd/simulation.gd")
const LOADOUTS = [preload("res://assets/loadouts/standard.tres"), preload("res://assets/loadouts/twin.tres")]
var previews: Array = []

class ActorView extends View:
	func _ready() -> void:
		pass

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_player(sim.player)

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("172124"))
	for row in 4:
		var direction: String = ["down", "up", "left", "right"][row]
		for column in 6:
			var configuration: Resource = LOADOUTS[column / 3]
			var state: String = ["idle", "walk", "attack"][column % 3]
			var view = ActorView.new()
			view.sim = Sim.new(configuration)
			view.sim.player.pos = Vector2.ZERO
			view.sim.player.dir = direction
			view.position = Vector2(115 + column * 210, 160 + row * 200)
			view.scale = Vector2.ONE * 2.0
			add_child(view)
			previews.append({"view": view, "state": state})
			var label = Label.new()
			label.text = direction.to_upper() + " / " + state.to_upper()
			label.position = Vector2(35 + column * 210, 88 + row * 200)
			label.add_theme_font_size_override("font_size", 17)
			add_child(label)
	for column in 2:
		var heading = Label.new()
		heading.text = LOADOUTS[column].weapon.display_name + " — đứng / đi / bắn"
		heading.position = Vector2(35 + column * 630, 20)
		heading.add_theme_font_size_override("font_size", 24)
		add_child(heading)

func _process(dt: float) -> void:
	for preview in previews:
		var sim: RefCounted = preview.view.sim
		sim.elapsed += dt
		sim.player.moving = preview.state == "walk"
		sim.player.move_clock += dt
		sim.player.shot_clock = sim.player.shot_duration * (1.0 - fmod(sim.elapsed, 1.0)) if preview.state == "attack" else 0.0
