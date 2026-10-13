extends Node2D
const MapSkin = preload("res://gd/map_skin.gd")
const Overlay = preload("res://gd/map_overlay.gd")
var sim: RefCounted
var skin: MapSkin
var revision := -1
var base_hp := -1
var scene: Node2D
var overlay: Node2D

func sync(value: RefCounted, appearance: MapSkin) -> void:
	if value != sim:
		if is_instance_valid(scene) and scene.get_parent() == self:
			remove_child(scene)
			scene.queue_free()
		scene = null
		if value != null and is_instance_valid(value.map_scene):
			scene = value.map_scene
			if scene.get_parent() != null:
				scene.get_parent().remove_child(scene)
			add_child(scene)
		if is_instance_valid(overlay):
			remove_child(overlay)
			overlay.queue_free()
		overlay = Overlay.new()
		add_child(overlay)
		revision = -1
		base_hp = -1
	if value == sim and appearance == skin and (value == null or (value.revision == revision and value.base_hp == base_hp)):
		return
	sim = value
	skin = appearance
	revision = value.revision if value != null else -1
	base_hp = value.base_hp if value != null else -1
	if sim != null and is_instance_valid(scene):
		var terrain := scene.get_node_or_null(scene.terrain_path) as TileMapLayer
		if terrain != null:
			for cell in terrain.get_used_cells():
				if cell.x < 0 or cell.y < 0 or cell.y >= sim.map.size() or cell.x >= sim.map[cell.y].size():
					continue
				var tile: Dictionary = sim.map[cell.y][cell.x]
				if tile.get("source_id", -1) < 0 or (tile.get("max_hp", 0) > 0 and tile.hp <= 0):
					terrain.erase_cell(cell)
		for object in sim.map_objects:
			if is_instance_valid(object.get("node")):
				object.node.visible = object.active and object.category != "pickup"
	if is_instance_valid(overlay):
		overlay.sim = sim
		overlay.skin = skin
		overlay.queue_redraw()
	queue_redraw()
