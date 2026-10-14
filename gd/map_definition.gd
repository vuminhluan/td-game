@tool
extends Node2D

const R = preload("res://gd/rules.gd")
const Map = preload("res://gd/battle_map.gd")
const MapMarker = preload("res://gd/map_marker.gd")
const MapObject = preload("res://gd/map_object.gd")
const Settings = preload("res://gd/pickup_settings.gd")
const Catalog = preload("res://gd/character_catalog.gd")
const MapSkin = preload("res://gd/map_skin.gd")
const DEFAULT_SETTINGS = preload("res://assets/maps/default_pickups.tres")
const DEFAULT_MAP_SKIN = preload("res://assets/terrain/industrial_v1/map_skin.tres")
@export var map_id := "industrial_yard"
@export var display_name := "Xưởng công nghiệp"
@export_multiline var display_description := ""
@export var preview_texture: Texture2D
@export var map_skin: MapSkin = DEFAULT_MAP_SKIN
@export var supported_modes: Array[String] = ["defense"]
@export var dimensions := Vector2i(21, 19):
	set(value):
		dimensions = value
		_update_floor()
		if is_inside_tree():
			update_configuration_warnings()
@export var terrain_path := NodePath("Terrain")
@export var pickup_settings: Resource = DEFAULT_SETTINGS

func _ready() -> void:
	_update_floor()

func _update_floor() -> void:
	var floor_sprite := get_node_or_null("Floor") as Sprite2D
	if floor_sprite != null:
		floor_sprite.region_rect = Rect2(Vector2.ZERO, Vector2(dimensions) * R.TILE)

func _get_configuration_warnings() -> PackedStringArray:
	return PackedStringArray(build_runtime().errors)

func build_runtime(catalog: RefCounted = null) -> Dictionary:
	var errors: Array[String] = []
	if catalog == null:
		catalog = Catalog.new()
	var settings: Resource = pickup_settings.duplicate(true) if pickup_settings is Settings else DEFAULT_SETTINGS.duplicate(true)
	if not pickup_settings is Settings:
		errors.append("Map %s: pickup_settings must be a PickupSettings resource." % map_id)
	errors.append_array(settings.validate(catalog))
	if map_id.strip_edges().is_empty():
		errors.append("Map requires a nonempty map_id.")
	if "defense" not in supported_modes:
		errors.append("Map %s does not support the selected defense mode." % map_id)
	if position != Vector2.ZERO or rotation != 0 or scale != Vector2.ONE:
		errors.append("Map root transform must use the world origin and unit scale.")
	var grid: Array = []
	if dimensions.x <= 0 or dimensions.y <= 0 or dimensions.x > 1024 or dimensions.y > 1024 or dimensions.x * dimensions.y > 262144:
		errors.append("Map %s: dimensions must be positive, at most 1024 per axis and 262144 cells total." % map_id)
		return {"grid": [], "dimensions": dimensions, "base_position": Vector2.ZERO,
			"player_position": Vector2.ZERO, "base_goal": Vector2i.ZERO, "enemy_spawns": [],
			"objects": [], "settings": settings, "errors": errors, "scene": self}
	for y in maxi(dimensions.y, 0):
		var row: Array = []
		for x in maxi(dimensions.x, 0):
			row.append({"kind": "floor", "hp": 0, "max_hp": 0, "move_blocked": false,
				"bullet_blocked": false, "destructible": false, "steel": false, "cell": Vector2i(x, y)})
		grid.append(row)
	var terrain := get_node_or_null(terrain_path) as TileMapLayer
	if terrain == null or terrain.tile_set == null:
		errors.append("Map %s: terrain_path must reference a TileMapLayer with a TileSet." % map_id)
	else:
		if terrain.tile_set.tile_size != Vector2i(R.TILE, R.TILE):
			errors.append("Map %s: TileSet tile size must be 40 × 40." % map_id)
		var terrain_transform: Transform2D = global_transform.affine_inverse() * terrain.global_transform
		if not terrain_transform.origin.is_zero_approx() or not terrain_transform.get_scale().is_equal_approx(Vector2.ONE) or not is_zero_approx(terrain_transform.get_rotation()):
			errors.append("Map %s: terrain transform must match the map origin and grid." % map_id)
		for cell in terrain.get_used_cells():
			if not _inside(cell):
				errors.append("Terrain cell %s is outside map dimensions." % cell)
				continue
			var data := terrain.get_cell_tile_data(cell)
			if data == null:
				errors.append("Terrain cell %s has no TileData." % cell)
				continue
			var tile: Dictionary = grid[cell.y][cell.x]
			for key in ["kind", "move_blocked", "bullet_blocked", "destructible", "hp"]:
				if not data.has_custom_data(key):
					errors.append("Terrain cell %s is missing custom data '%s'." % [cell, key])
				else:
					var value = data.get_custom_data(key)
					var expected_type := TYPE_STRING if key == "kind" else (TYPE_INT if key == "hp" else TYPE_BOOL)
					if typeof(value) != expected_type:
						errors.append("Terrain cell %s custom data '%s' has an invalid type." % [cell, key])
					else:
						tile[key] = value
			if data.has_custom_data("steel"):
				if typeof(data.get_custom_data("steel")) != TYPE_BOOL:
					errors.append("Terrain cell %s custom data 'steel' must be boolean." % cell)
				else:
					tile.steel = data.get_custom_data("steel")
			if tile.kind.is_empty():
				errors.append("Terrain cell %s requires a nonempty visual kind." % cell)
			tile.max_hp = tile.hp
			tile.source_id = terrain.get_cell_source_id(cell)
			tile.atlas_coords = terrain.get_cell_atlas_coords(cell)
			tile.alternative_tile = terrain.get_cell_alternative_tile(cell)
			if tile.hp < 0:
				errors.append("Terrain cell %s HP must be nonnegative." % cell)
			if tile.destructible and tile.hp <= 0:
				errors.append("Destructible terrain cell %s requires positive HP." % cell)
	var objects: Array = []
	var markers := {"base": [], "enemy": [], "player": [], "invalid": []}
	_collect(self, objects, markers)
	var occupied: Dictionary = {}
	var power_up_count := 0
	for object in objects:
		var node = object.node
		if object.definition != null:
			for error in object.definition.validate():
				errors.append("Object %s: %s" % [node.name, error])
		if object.category in ["fixed", "destructible"] and (object.footprint.x <= 0 or object.footprint.y <= 0 or object.footprint.x > 1024 or object.footprint.y > 1024 or object.footprint.x * object.footprint.y > 262144):
			errors.append("Object %s requires a positive footprint, at most 1024 per axis and 262144 cells total." % node.name)
		if object.destructible and object.hp <= 0:
			errors.append("Object %s requires positive HP." % node.name)
		if object.category not in ["decoration", "fixed", "destructible", "pickup"]:
			errors.append("Object %s has invalid category '%s'." % [node.name, object.category])
		var relative_transform: Transform2D = global_transform.affine_inverse() * node.global_transform
		if object.category in ["fixed", "destructible"] and (not is_zero_approx(relative_transform.get_rotation()) or not relative_transform.get_scale().is_equal_approx(Vector2.ONE)):
			errors.append("Object %s: gameplay footprint requires no rotation and unit scale." % node.name)
		if object.drop_settings != null:
			if object.drop_settings is Settings:
				object.drop_settings = object.drop_settings.duplicate(true)
				for error in object.drop_settings.validate(catalog):
					errors.append("Object %s: %s" % [node.name, error])
			else:
				errors.append("Object %s: drop_settings must be a PickupSettings resource." % node.name)
				object.drop_settings = null
		if object.category == "pickup":
			if object.pickup_id.is_empty():
				errors.append("Pickup %s requires an item ID." % node.name)
			if object.pickup_category == "power_up":
				power_up_count += 1
		if object.category in ["pickup", "destructible"]:
			if object.pickup_category not in ["power_up", "weapon"]:
				errors.append("Object %s has invalid pickup category." % node.name)
			elif not object.pickup_id.is_empty():
				var valid: bool = object.pickup_id in Settings.POWER_UP_IDS if object.pickup_category == "power_up" else catalog.data.weapons.has(object.pickup_id)
				if not valid:
					errors.append("Object %s has invalid pickup ID '%s'." % [node.name, object.pickup_id])
		for cell in object.footprint_cells:
			if not _inside(cell):
				errors.append("Object %s footprint cell %s is outside the map." % [node.name, cell])
				continue
			if occupied.has(cell):
				errors.append("Object %s overlaps %s at %s." % [node.name, occupied[cell], cell])
			if Map.move_blocked(grid[cell.y][cell.x]):
				errors.append("Object %s overlaps blocked terrain at %s." % [node.name, cell])
			occupied[cell] = node.name
			grid[cell.y][cell.x].object = object
	var pickup_positions: Dictionary = {}
	for object in objects:
		if object.category != "pickup":
			continue
		if not Map.can_occupy(grid, object.pos, 13):
			errors.append("Pickup %s must be inside traversable terrain and outside obstacle footprints." % object.node.name)
		if pickup_positions.has(object.pos):
			errors.append("Pickup %s overlaps another pickup at %s." % [object.node.name, object.pos])
		pickup_positions[object.pos] = true
	if power_up_count > settings.power_up_limit:
		errors.append("Map has %d placed power-ups, exceeding limit %d." % [power_up_count, settings.power_up_limit])
	if markers.base.size() != 1:
		errors.append("Defense map requires exactly one base marker; found %d." % markers.base.size())
	if markers.enemy.is_empty():
		errors.append("Defense map requires at least one enemy spawn marker.")
	if markers.player.size() > 1:
		errors.append("Map supports at most one player marker.")
	for invalid in markers.invalid:
		errors.append("Map marker has invalid role '%s'." % invalid)
	for role in ["base", "enemy", "player"]:
		for point in markers[role]:
			if not Map.can_occupy(grid, point, 28 if role == "base" else 13):
				errors.append("%s marker at %s must have traversable space inside the map." % [role, point])
	var base_position: Vector2 = markers.base[0] if markers.base.size() == 1 else Vector2.ZERO
	for role in ["player", "enemy"]:
		for point in markers[role]:
			if markers.base.size() == 1 and point.distance_to(base_position) <= 41:
				errors.append("%s marker at %s overlaps the base gameplay area." % [role, point])
	for object in objects:
		if object.category == "pickup" and markers.base.size() == 1 and absf(object.pos.x - base_position.x) < 33 and absf(object.pos.y - base_position.y) < 33:
			errors.append("Pickup %s overlaps the base gameplay area." % object.node.name)
	var player_position: Vector2 = markers.player[0] if markers.player.size() == 1 else _nearest_position(grid, base_position, 60)
	if markers.player.is_empty() and player_position == Vector2.INF:
		errors.append("Map has no valid player spawn near the base.")
	var approach := _nearest_position(grid, base_position + Vector2(0, -R.TILE), 0, base_position)
	var base_goal := Vector2i.ZERO if approach == Vector2.INF else Vector2i(floori(approach.x / R.TILE), floori(approach.y / R.TILE))
	if approach == Vector2.INF:
		errors.append("Map has no traversable approach position near the base.")
	else:
		for point in markers.enemy:
			var start := Vector2i(floori(point.x / R.TILE), floori(point.y / R.TILE))
			if start != base_goal and Map.find_path(grid, start, base_goal).is_empty():
				errors.append("Enemy spawn at %s cannot reach the base approach." % point)
	return {"grid": grid, "dimensions": dimensions, "base_position": base_position,
		"player_position": player_position, "base_goal": base_goal, "enemy_spawns": markers.enemy,
		"objects": objects, "settings": settings, "errors": errors, "scene": self}

func _collect(parent: Node, objects: Array, markers: Dictionary) -> void:
	for child in parent.get_children():
		if child is MapMarker:
			if child.role in ["base", "enemy", "player"]:
				markers[child.role].append(to_local(child.global_position))
			else:
				markers["invalid"].append(child.role)
		elif child is MapObject:
			objects.append(child.runtime_data(objects.size(), to_local(child.global_position)))
		else:
			_collect(child, objects, markers)

func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < dimensions.x and cell.y < dimensions.y

func _nearest_position(grid: Array, origin: Vector2, minimum_distance: float, excluded_base: Vector2 = Vector2.INF) -> Vector2:
	var best := Vector2.INF
	var distance := INF
	for y in grid.size():
		for x in grid[y].size():
			var point := (Vector2(x, y) + Vector2.ONE * 0.5) * R.TILE
			if excluded_base != Vector2.INF and absf(point.x - excluded_base.x) < 25 and absf(point.y - excluded_base.y) < 25:
				continue
			var delta := point.distance_squared_to(origin)
			if delta >= minimum_distance * minimum_distance and delta < distance and Map.can_occupy(grid, point):
				best = point
				distance = delta
	return best
