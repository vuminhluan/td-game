extends Node2D
const SKINS = [preload("res://assets/sprites/enemy_tank/enemy_skin.tres"), preload("res://assets/sprites/enemy_mech/enemy_skin.tres")]

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("172124"))
	for kind_index in 2:
		for row in 4:
			var direction: String = ["down", "up", "left", "right"][row]
			for column in 3:
				var state: String = ["idle", "walk", "attack"][column]
				var sprite = AnimatedSprite2D.new()
				sprite.sprite_frames = SKINS[kind_index].direction_for(direction).frames
				sprite.position = Vector2(105 + kind_index * 620 + column * 195, 190 + row * 190)
				add_child(sprite)
				sprite.play(state)
				if state == "attack":
					var timer = Timer.new()
					timer.wait_time = 1.2
					timer.autostart = true
					timer.timeout.connect(func(): sprite.play(state))
					add_child(timer)
				var label = Label.new()
				label.text = direction.to_upper() + " / " + state
				label.position = sprite.position + Vector2(-70, -90)
				add_child(label)
		var heading = Label.new()
		heading.text = "ENEMY TANK" if kind_index == 0 else "ENEMY BIPED MECH"
		heading.position = Vector2(40 + kind_index * 620, 35)
		heading.add_theme_font_size_override("font_size", 26)
		add_child(heading)
