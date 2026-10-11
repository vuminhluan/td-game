extends Node2D
const R = preload("res://gd/rules.gd")
const MapSkin = preload("res://gd/map_skin.gd")
const Terrain = preload("res://gd/map_terrain.gd")
@export var map_skin: MapSkin = preload("res://assets/terrain/industrial_v1/map_skin.tres")
var terrain: Node2D
var sim: RefCounted:
	set(value):
		sim = value
		if sim != null:
			sim.player_muzzle_distances = player_skin.muzzle_distances.duplicate()
			sim.enemy_muzzle_distances.clear()
			for kind in enemy_skins:
				sim.enemy_muzzle_distances[kind] = enemy_skins[kind].muzzle_distances()
@export var player_skin: Resource = preload("res://assets/sprites/player_mech/player_skin.tres")
@export var enemy_skins: Dictionary = {
	"tank": preload("res://assets/sprites/enemy_tank/enemy_skin.tres"),
	"robot": preload("res://assets/sprites/enemy_mech/enemy_skin.tres")
}

func _ready() -> void:
	terrain = Terrain.new()
	terrain.show_behind_parent = true
	add_child(terrain)
	terrain.sync(sim, map_skin)

func _process(_dt: float) -> void:
	terrain.sync(sim, map_skin)

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
	for actor in [sim.player] + sim.enemies:
		draw_actor(actor)
	for y in R.ROWS:
		for x in R.COLS:
			if sim.map[y][x].kind != "grass":
				continue
			draw_set_transform(Vector2(x, y) * R.TILE)
			draw_texture_rect(map_skin.foliage_texture, Rect2(Vector2.ZERO, Vector2.ONE * R.TILE), false)
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
			var bar_y = 23.0
			var skin: Resource = enemy_skins.get(enemy.kind)
			if skin != null:
				var view: Resource = skin.direction_for(enemy.dir)
				var texture: Texture2D = skin.frame_for(enemy, sim.elapsed)
				if view != null and texture != null:
					bar_y = (texture.get_height() - view.anchor.y) * view.texture_scale + 3
			draw_rect(Rect2(enemy.pos + Vector2(-13, bar_y), Vector2(26, 3)), Color("172023"))
			draw_rect(Rect2(enemy.pos + Vector2(-13, bar_y), Vector2(26.0 * enemy.hp / enemy.max_hp, 3)), Color("ed9870"))

func draw_actor(actor: Dictionary) -> void:
	if actor.kind == "player":
		draw_player(actor)
		return
	var skin: Resource = enemy_skins.get(actor.kind)
	if skin != null:
		var view: Resource = skin.direction_for(actor.dir)
		var texture: Texture2D = skin.frame_for(actor, sim.elapsed)
		if view != null and texture != null:
			draw_set_transform(actor.pos)
			var tint = Color(1.8, 1.4, 1.4) if actor.hurt_clock > 0 else Color.WHITE
			draw_texture_rect(texture, Rect2(-view.anchor * view.texture_scale, texture.get_size() * view.texture_scale), false, tint)
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
	draw_set_transform(Vector2.ZERO)
	if sim.invulnerable > 0:
		draw_arc(actor.pos, 21, 0, TAU, 24, Color(0.55, 0.86, 0.8, 0.4), 1)
