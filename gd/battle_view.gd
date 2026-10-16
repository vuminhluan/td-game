extends Node2D
const PowerUpIcons = preload("res://gd/power_up_icons.gd")
const PickupArt = preload("res://gd/weapon_pickup_art.gd")
var pickup_art = PickupArt.new()
const R = preload("res://gd/rules.gd")
const MapSkin = preload("res://gd/map_skin.gd")
const Terrain = preload("res://gd/map_terrain.gd")
@export var map_skin: MapSkin = preload("res://assets/terrain/industrial/map_skin.tres")
var terrain: Node2D
var sim: RefCounted:
	set(value):
		sim = value
		if sim != null:
			player_skin = sim.loadout.body
			sim.enemy_muzzle_distances.clear()
			for kind in enemy_skins:
				sim.enemy_muzzle_distances[kind] = enemy_skins[kind].muzzle_distances()
		if is_instance_valid(terrain):
			terrain.sync(sim, map_skin)
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
	if sim != null:
		player_skin = sim.loadout.body
	terrain.sync(sim, map_skin)

func plate(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(1, 3), rect.size), Color("101719"))
	draw_rect(rect, color)
	draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("7a8586"))
	draw_line(rect.position, rect.position + Vector2(0, rect.size.y), Color("566166"))
	draw_line(rect.end - Vector2(0, rect.size.y), rect.end, Color("182124"))
	draw_line(rect.end - Vector2(rect.size.x, 1), rect.end - Vector2(0, 1), Color("182124"), 2)

func _draw() -> void:
	if sim == null or sim.status == "invalid":
		return
	var player_states: Array = sim.get("players") if sim.get("players") is Array else []
	if player_states.is_empty():
		draw_player(sim.player)
	else:
		for state in player_states:
			draw_player(state.actor, state)
	for actor in sim.enemies:
		draw_actor(actor)
	draw_set_transform(Vector2.ZERO)
	for item in sim.power_ups:
		PowerUpIcons.draw_icon(self, item.kind, item.pos)
	for item in sim.weapon_pickups:
		draw_weapon_pickup(item)
	if sim.power_up_active("base_shield"):
		draw_arc(sim.base_position, 34, 0, TAU, 48, PowerUpIcons.COLORS.base_shield, 2, true)
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

func draw_player(actor: Dictionary, state: Dictionary = {}) -> void:
	if actor.hp <= 0:
		return
	if state.is_empty():
		state = player_state_for(actor)
	var loadout: Resource = state.loadout
	var skin: Resource = loadout.body
	var tint = Color.WHITE
	if state.invulnerable > 0 and sin(sim.elapsed * 20) > 0:
		tint.a = 0.4
	if actor.hurt_clock > 0:
		tint = Color(1.8, 1.4, 1.4, tint.a)
	draw_set_transform(actor.pos, skin.rotation_for(actor.dir))
	var texture: Texture2D = skin.frame_for(actor, sim.elapsed)
	var rect = Rect2(-skin.anchor_for(actor.dir) * skin.texture_scale, texture.get_size() * skin.texture_scale)
	var weapon: Resource = loadout.weapon
	if weapon.layered_art != null:
		var art: Resource = weapon.layered_art
		var gun_texture: Texture2D = art.texture_for(actor.dir)
		var socket_point: Vector2 = skin.socket_for(loadout.socket, actor.dir)
		var progress: float = 1.0 - actor.shot_clock / actor.shot_duration
		var recoil: Vector2 = -R.VECTOR[actor.dir] * art.recoil_distance * sin(progress * PI) if actor.shot_clock > 0 else Vector2.ZERO
		var origin: Vector2 = socket_point + recoil - art.anchor_for(actor.dir) * art.texture_scale
		var rear: Array = [art.rear_regions[actor.dir]] if art.rear_regions.has(actor.dir) else []
		draw_weapon_regions(gun_texture, origin, rear, art.texture_scale, tint)
		draw_clean_body(actor, texture, rect, tint, skin)
		var front: Array = preload("res://gd/sprite_regions.gd").subtract([Rect2(Vector2.ZERO, gun_texture.get_size())], rear)
		draw_weapon_regions(gun_texture, origin, front, art.texture_scale, tint)
		draw_set_transform(Vector2.ZERO)
		draw_player_status(actor, state, skin)
		return
	var animation: String = skin.animation_name_for(actor)
	var index: int = skin.frame_index_for(actor, sim.elapsed)
	draw_body(texture, rect.position, skin.cutouts_for(actor.dir, animation, index), tint, skin)
	var socket: Vector2 = skin.socket_for(loadout.socket, actor.dir)
	var mount: Rect2 = skin.mount_rects[actor.dir]
	draw_rect(Rect2(socket + mount.position, mount.size), Color("77745a") * tint)
	var gun: Texture2D = weapon.frame_for(actor.dir, animation, index)
	var direction: Vector2 = R.VECTOR[actor.dir]
	var lateral = Vector2(-direction.y, direction.x)
	for offset in weapon.barrel_offsets:
		var origin: Vector2 = socket + lateral * offset - weapon.anchors[actor.dir] * weapon.texture_scale
		for region in weapon.regions_for(actor.dir, animation, index):
			draw_texture_rect_region(gun, Rect2(origin + region.position * weapon.texture_scale, region.size * weapon.texture_scale), region, tint)
	draw_set_transform(Vector2.ZERO)
	draw_player_status(actor, state, skin)

func draw_body(texture: Texture2D, origin: Vector2, cutouts: Array, tint: Color, skin: Resource = null) -> void:
	if skin == null:
		skin = player_skin
	var pieces = preload("res://gd/sprite_regions.gd").subtract([Rect2(Vector2.ZERO, texture.get_size())], cutouts)
	for piece in pieces:
		draw_texture_rect_region(texture, Rect2(origin + piece.position * skin.texture_scale, piece.size * skin.texture_scale), piece, tint)

func draw_clean_body(actor: Dictionary, texture: Texture2D, rect: Rect2, tint: Color, skin: Resource = null) -> void:
	if skin == null:
		skin = player_skin
	if not actor.moving or skin.walk_stride == 0:
		draw_texture_rect(texture, rect, false, tint)
		return
	var split: float = skin.anchor_for(actor.dir).y + skin.walk_split_offset
	var dimensions = texture.get_size()
	var stride: float = sin(actor.move_clock * TAU * 4) * skin.walk_stride
	for side in 2:
		var piece = Rect2(side * dimensions.x / 2, split, dimensions.x / 2, dimensions.y - split)
		var offset = Vector2(0, stride * (1 if side == 0 else -1))
		draw_texture_rect_region(texture, Rect2(rect.position + piece.position * skin.texture_scale + offset, piece.size * skin.texture_scale), piece, tint)
	var torso = Rect2(0, 0, dimensions.x, minf(dimensions.y, split + 8))
	draw_texture_rect_region(texture, Rect2(rect.position, torso.size * skin.texture_scale), torso, tint)

func player_state_for(actor: Dictionary) -> Dictionary:
	var states = sim.get("players")
	if states is Array:
		for state in states:
			if is_same(state.actor, actor):
				return state
	return {"actor": actor, "loadout": sim.loadout, "invulnerable": sim.invulnerable,
		"active_power_ups": {}, "label_remaining": 0.0}

func draw_player_status(actor: Dictionary, state: Dictionary, skin: Resource) -> void:
	if state.invulnerable > 0 or state.active_power_ups.get("shield", 0.0) > 0:
		draw_arc(actor.pos, 21, 0, TAU, 24, Color(0.55, 0.86, 0.8, 0.4), 1)
	var states = sim.get("players")
	if not states is Array or states.size() <= 1 or state.get("label_remaining", 0.0) <= 0:
		return
	var player_index: int = states.find(state)
	var label := "P%d" % (player_index + 1)
	var label_color := Color("a8d488") if player_index == 0 else Color("87b9ee")
	var font := ThemeDB.fallback_font
	var height: float = skin.anchor_for(actor.dir).y * skin.texture_scale
	var label_position: Vector2 = actor.pos + Vector2(-font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x / 2.0, -height - 8)
	draw_string_outline(font, label_position, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color("101719"))
	draw_string(font, label_position, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, label_color)

func draw_weapon_regions(texture: Texture2D, origin: Vector2, regions: Array, texture_scale: float, tint: Color) -> void:
	for region in regions:
		draw_texture_rect_region(texture, Rect2(origin + region.position * texture_scale, region.size * texture_scale), region, tint)

func draw_weapon_pickup(item: Dictionary) -> void:
	var texture: Texture2D = pickup_art.texture_for(item.kind, sim.loadout.character_id, sim.catalog)
	if texture == null:
		return
	var point: Vector2 = item.pos
	var rect := pickup_art.rect_for(texture, point)
	draw_circle(point, 20, Color(0.96, 0.70, 0.28, 0.08))
	draw_arc(point, 19, 0, TAU, 40, Color(0.96, 0.70, 0.28, 0.55), 1, true)
	draw_texture_rect(texture, Rect2(rect.position + Vector2(1, 3), rect.size), false, Color(0, 0, 0, 0.65))
	draw_texture_rect(texture, rect, false)
