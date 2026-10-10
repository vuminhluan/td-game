extends Node2D
const SKIN = preload("res://assets/sprites/player_mech/player_skin.tres")
var actors: Array = []

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("172124"))
	for row in 4:
		var direction: String = ["down", "up", "left", "right"][row]
		var source: SpriteFrames = SKIN.frames_for(direction)
		for column in 3:
			var state: String = ["idle", "walk", "attack"][column]
			var animation = state if direction == "down" else direction + "_" + state
			var sprite = AnimatedSprite2D.new()
			sprite.sprite_frames = source
			sprite.position = Vector2(230 + column * 400, 230 + row * 195)
			sprite.scale = Vector2.ONE * 1.4
			add_child(sprite)
			sprite.play(animation)
			if state == "attack":
				var timer = Timer.new()
				timer.wait_time = 1.2
				timer.autostart = true
				timer.timeout.connect(func(): sprite.play(animation))
				add_child(timer)
			actors.append(sprite)
			var label = Label.new()
			label.text = direction.to_upper() + " / " + state.to_upper()
			label.position = Vector2(145 + column * 400, 125 + row * 195)
			label.add_theme_font_size_override("font_size", 20)
			add_child(label)
	var heading = Label.new()
	heading.text = "PLAYER MECH — 4 góc nhìn riêng / 56 frame\nĐứng • Đi • Bắn — robot giữ thẳng, không xoay hình."
	heading.position = Vector2(70, 35)
	heading.add_theme_font_size_override("font_size", 24)
	add_child(heading)
