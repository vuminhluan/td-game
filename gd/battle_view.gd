extends Node2D
const R = preload("res://gd/rules.gd")
var sim: RefCounted:
	set(value):
		sim = value
		if sim != null:
			sim.player_muzzle_distances = player_skin.muzzle_distances.duplicate()
@export var player_skin: Resource = preload("res://assets/sprites/player_mech/player_skin.tres")

func plate(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(1, 3), rect.size), Color("101719"))
	draw_rect(rect, color)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("7a8586"))
	draw_line(rect.position, rect.position + Vector2(0, rect.size.y), Color("566166"))
	draw_line(rect.end - Vector2(0, rect.size.y), rect.end, Color("182124"))
	draw_line(rect.end - Vector2(rect.size.x, 1), rect.end - Vector2(0, 1), Color("182124"), 2)

func _draw() -> void:
	if sim == null:
		return
	for y in R.ROWS:
		for x in R.COLS:
			var point = Vector2(x, y) * R.TILE
			var tile: Dictionary = sim.map[y][x]
			draw_set_transform(point)
			plate(Rect2(0, 0, 39, 39), [Color("303a3e"), Color("333d40"), Color("2e393d"), Color("354044")][(x * 7 + y * 3) % 4])
			for bolt in [Vector2(3, 3), Vector2(35, 35)]:
				draw_rect(Rect2(bolt, Vector2(2, 2)), Color("7a8485"))
			match tile.kind:
				"brick":
					for row in 4:
						for column in 2:
							var bx = column * 20
							plate(Rect2(bx + 1, row * 9 + 1, 18, 8), [Color("96513a"), Color("ad6040"), Color("874632")][(row + column) % 3])
					if tile.hp < 3:
						draw_polyline(PackedVector2Array([Vector2(17, 0), Vector2(23, 8), Vector2(16, 17), Vector2(23, 25), Vector2(18, 37)]), Color("251e1a"), 2)
					if tile.hp == 1:
						draw_line(Vector2(2, 11), Vector2(38, 29), Color("251e1a"), 3)
				"steel":
					plate(Rect2(1, 1, 38, 38), Color("778084"))
					plate(Rect2(5, 5, 30, 29), Color("596569"))
					for gy in range(13, 28, 4):
						draw_rect(Rect2(12, gy, 16, 2), Color("283439"))
					for bolt in [Vector2(5, 5), Vector2(32, 5), Vector2(5, 31), Vector2(32, 31)]:
						draw_rect(Rect2(bolt, Vector2(3, 3)), Color("b1b9b6"))
				"water":
					plate(Rect2(0, 0, 40, 40), Color("57676b"))
					draw_rect(Rect2(3, 3, 34, 34), Color("174d66"))
					for wy in range(8, 36, 7):
						draw_line(Vector2(6, wy), Vector2(32, wy - 2), Color("28738c"), 2)
	draw_set_transform(R.BASE - Vector2(50, 55))
	for x in [6, 75]:
		plate(Rect2(x, 31, 19, 56), Color("333f43"))
		for y in range(37, 81, 9):
			plate(Rect2(x + 2, y, 15, 6), Color("647071"))
	plate(Rect2(20, 24, 60, 65), Color("465458"))
	plate(Rect2(26, 13, 48, 64), Color("8b9491"))
	plate(Rect2(31, 16, 38, 22), Color("303f44"))
	for y in range(19, 35, 4):
		draw_rect(Rect2(34, y, 32, 2), Color("637574"))
	plate(Rect2(30, 43, 40, 30), Color("35464a"))
	draw_colored_polygon(PackedVector2Array([Vector2(38,47), Vector2(50,54), Vector2(62,47), Vector2(57,61), Vector2(50,66), Vector2(43,61)]), Color("e37345"))
	plate(Rect2(38, 73, 24, 20), Color("1d2c30"))
	draw_rect(Rect2(42, 77, 16, 3), Color("9ad0a1") if sim.base_hp > 0 else Color("fb6944"))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(R.BASE - Vector2(60, 65), Vector2(120, 105)), Color("8a8055"), false)
	for actor in [sim.player] + sim.enemies:
		draw_actor(actor)
	# Foliage covers actors, while bullets/effects remain visible.
	for y in R.ROWS:
		for x in R.COLS:
			if sim.map[y][x].kind != "grass":
				continue
			draw_set_transform(Vector2(x, y) * R.TILE)
			for i in 55:
				var px = (i * 17 + x * 3) % 40
				var py = (i * 13 + y * 7) % 40
				draw_line(Vector2(px, py), Vector2(px + 3, py - 5), [Color("253d22"), Color("385326"), Color("4a652d"), Color("607b37")][i % 4], 3)
	draw_set_transform(Vector2.ZERO)
	for bullet in sim.bullets:
		draw_circle(bullet.pos, 6, Color(1, 0.6, 0.3, 0.18))
		draw_circle(bullet.pos, 2.5, Color("ffedb6") if bullet.friendly else Color("ff8158"))
	for fx in sim.effects:
		var progress: float = 1 - fx.life / fx.max
		draw_circle(fx.pos, (5 + progress * 23) if fx.kind == "explosion" else (3 + progress * 7), Color(1, 0.63, 0.33, 1 - progress))
		for i in 7:
			var vector = Vector2.from_angle(i * TAU / 7)
			draw_line(fx.pos + vector * progress * 10, fx.pos + vector * (8 + progress * 30), Color(1, 0.87, 0.6, 1 - progress), 2)
	for enemy in sim.enemies:
		if enemy.hp < enemy.max_hp:
			draw_rect(Rect2(enemy.pos + Vector2(-13, 23), Vector2(26, 3)), Color("172023"))
			draw_rect(Rect2(enemy.pos + Vector2(-13, 23), Vector2(26.0 * enemy.hp / enemy.max_hp, 3)), Color("ed9870"))

func draw_actor(actor: Dictionary) -> void:
	if actor.kind == "player":
		draw_player(actor)
		return
	var color = Color("82845d") if actor.kind == "tank" else Color("647478")
	draw_set_transform(actor.pos, R.ANGLE[actor.dir])
	draw_circle(Vector2(0, 4), 21, Color("101619"))
	if actor.kind == "tank":
		for x in [-19, 9]:
			plate(Rect2(x, -16, 10, 34), Color("293435"))
			for y in range(-14, 16, 5):
				draw_rect(Rect2(x + 1, y, 8, 2), Color("627072"))
		plate(Rect2(-10, -13, 20, 28), color)
		plate(Rect2(-7, -9, 14, 16), Color("737e63"))
		plate(Rect2(-3, -24, 6, 20), Color("a1a489"))
	else:
		for x in [-14, 4]:
			plate(Rect2(x, 5, 10, 13), Color("263237"))
			plate(Rect2(x, 9, 10, 7), color)
		plate(Rect2(-14, -13, 28, 23), Color("273337"))
		plate(Rect2(-9, -10, 18, 17), color)
		for x in [-21, 10]:
			plate(Rect2(x, -12, 11, 13), color)
			plate(Rect2(x + 2, 2, 7, 10), Color("3f4c4e"))
		plate(Rect2(-7, -17, 14, 14), Color("7c8583"))
		plate(Rect2(-5, -16, 10, 7), Color("303c3e"))
		draw_rect(Rect2(-4, -11, 8, 3), Color("fb6944"))
		plate(Rect2(9, -23, 5, 28), Color("222f33"))
		draw_rect(Rect2(10, -22, 2, 23), Color("788582"))

func draw_player(actor: Dictionary) -> void:
	if actor.hp <= 0:
		return
	var tint = Color.WHITE
	if sim.invulnerable > 0 and sin(sim.elapsed * 20) > 0:
		tint.a = 0.4
	if actor.hurt_clock > 0:
		tint = Color(1.8, 1.4, 1.4, tint.a)
	draw_set_transform(actor.pos, player_skin.rotation_for(actor.dir))
	var texture: Texture2D = player_skin.frame_for(actor, sim.elapsed)
	var rect = Rect2(-player_skin.anchor_for(actor.dir) * player_skin.texture_scale, texture.get_size() * player_skin.texture_scale)
	draw_texture_rect(texture, rect, false, tint)
	# Walking continues while firing; recoil flash is already rendered at the muzzle by simulation effects.
	draw_set_transform(Vector2.ZERO)
	if sim.invulnerable > 0:
		draw_arc(actor.pos, 21, 0, TAU, 24, Color(0.55, 0.86, 0.8, 0.4), 1)
