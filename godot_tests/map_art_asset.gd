extends SceneTree
const Sim = preload("res://gd/simulation.gd")
const View = preload("res://gd/battle_view.gd")
const R = preload("res://gd/rules.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view = View.new()
	var sim = Sim.new(preload("res://assets/loadouts/standard.tres"))
	view.sim = sim
	root.add_child(view)
	await process_frame
	var skin = view.map_skin
	for kind in ["floor", "brick", "steel", "water", "grass"]:
		var texture: Texture2D = skin.tile_texture(kind)
		var expected_size := Vector2(320, 320) if kind == "floor" else Vector2(80, 80)
		check(texture != null and texture.get_size() == expected_size, kind + " has a normalized texture")
	check(skin.foliage_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "foliage retains alpha")
	check(skin.headquarters_texture.get_image().detect_alpha() != Image.ALPHA_NONE, "base retains alpha")
	check(skin.headquarters_rect.has_point(Vector2.ZERO), "base geometry contains simulation anchor")
	check(skin.damage_texture(3) == null, "intact brick has no cracks")
	check(skin.damage_texture(2) != skin.damage_texture(1), "damage stages are distinct")
	check(skin.base_texture(0) == skin.headquarters_wreck, "destroyed base selects wreck")
	check(view.terrain.show_behind_parent, "ground is behind actors")
	var point := Vector2(4, 1) * R.TILE + Vector2.ONE * 20
	for hp in [2, 1, 0]:
		sim.damage_brick(point)
		view.terrain.sync(sim, skin)
		check(view.terrain.revision == sim.revision, "terrain invalidates after brick damage")
		check(sim.map[1][4].hp == hp, "brick keeps gameplay HP")
	check(sim.map[1][4].kind == "floor", "destroyed brick reveals floor")
	check(skin.tile_texture(sim.map[1][4].kind) == skin.floor_texture, "destroyed brick selects ground")
	sim.base_hp = 0
	view.terrain.sync(sim, skin)
	check(view.terrain.base_hp == 0, "base HP invalidates ground independently")
	var replacement = Sim.new(preload("res://assets/loadouts/standard.tres"))
	view.sim = replacement
	view.terrain.sync(replacement, skin)
	check(view.terrain.sim == replacement and view.terrain.base_hp == R.BASE_HP, "replay rebinds terrain")
	check(replacement.map[1][4].hp == 3, "replay restores brick")
	var other_skin = skin.duplicate()
	view.map_skin = other_skin
	view.terrain.sync(replacement, other_skin)
	check(view.terrain.skin == other_skin, "skin replacement invalidates ground")
	view.queue_free()
	await process_frame
	print("MAP ART: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
