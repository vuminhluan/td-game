extends RefCounted
const Loadout = preload("res://gd/player_loadout.gd")
const Weapon = preload("res://gd/player_weapon.gd")
const Art = preload("res://gd/character_art.gd")
const CONFIG_PATH = "res://config/player_characters.json"
var artwork: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/characters/manifest.json"))
var data: Dictionary = {}
var errors: Array[String] = []

func _init(path: String = CONFIG_PATH) -> void:
	var parser = JSON.new()
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append(path + ": không đọc được config")
		return
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		errors.append(path + ": JSON không hợp lệ ở dòng %d" % parser.get_error_line())
		return
	data = parser.data
	validate()

func positive(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value > 0

func validate() -> void:
	for section in ["characters", "bodies", "weapons", "power_ups"]:
		if not data.get(section) is Dictionary or data[section].is_empty():
			errors.append(section + ": cần object không rỗng")
	if not errors.is_empty():
		return
	if not data.characters.has(data.get("default_character", "")):
		errors.append("default_character: ID không tồn tại")
	for id in data.weapons:
		if id.is_empty():
			errors.append("weapons: ID không được rỗng")
		var w = data.weapons[id]
		if not w is Dictionary:
			errors.append("weapons." + id + ": cần object")
			continue
		if not w.get("name") is String or w.get("name", "").strip_edges().is_empty():
			errors.append("weapons.%s.name: cần tên" % id)
		if not w.get("firing_mode") in ["parallel", "alternating"] or not w.get("double_mode") in ["repeat_volley", "uniform_duration", "alternating_pairs"]:
			errors.append("weapons.%s: firing_mode/double_mode không hợp lệ" % id)
		if w.get("double_mode") == "alternating_pairs" and w.get("firing_mode") != "alternating":
			errors.append("weapons.%s.double_mode: alternating_pairs cần firing_mode alternating" % id)
		if w.get("firing_mode") == "alternating" and (not w.get("times") is Array or not w.get("barrels") is Array or w.times.size() != 2 or w.barrels.size() != 2 or w.get("double_mode") != "alternating_pairs"):
			errors.append("weapons.%s: alternating cần hai bên, hai thời điểm và alternating_pairs" % id)
		for key in ["damage", "bullet_speed", "rest"]:
			if not positive(w.get(key)) or (key == "damage" and float(w[key]) != int(w[key])):
				errors.append("weapons.%s.%s: cần số dương%s" % [id, key, " nguyên" if key == "damage" else ""])
		for key in ["times"]:
			var times = w.get(key)
			if not times is Array or times.is_empty():
				errors.append("weapons.%s.%s: cần chuỗi thời điểm" % [id, key])
				continue
			var previous = -1.0
			for t in times:
				if not (t is int or t is float) or not is_finite(float(t)) or t < 0 or t <= previous:
					errors.append("weapons.%s.%s: thời điểm phải tăng, bắt đầu từ 0" % [id, key])
					break
				previous = t
			if times[0] != 0:
				errors.append("weapons.%s.%s: viên đầu phải tại 0" % [id, key])
		if not w.get("barrels") is Array or w.barrels.is_empty():
			errors.append("weapons.%s.barrels: cần danh sách nòng" % id)
		else:
			for offset in w.barrels:
				if not (offset is float or offset is int) or not is_finite(float(offset)):
					errors.append("weapons.%s.barrels: offset không hợp lệ" % id)
		if not w.get("muzzles") is Dictionary:
			errors.append("weapons.%s.muzzles: cần bốn hướng" % id)
			continue
		var barrel_count: int = w.barrels.size() if w.get("barrels") is Array else 0
		for character in w.muzzles:
			if not data.characters.has(character) or not w.muzzles[character] is Dictionary:
				errors.append("weapons.%s.muzzles.%s: nhân vật không hợp lệ" % [id, character])
				continue
			for direction in ["up", "down", "left", "right"]:
				var points = w.muzzles[character].get(direction)
				if not points is Array or points.size() != barrel_count:
					errors.append("weapons.%s.muzzles.%s.%s: số nòng không khớp" % [id, character, direction])
					continue
				for point in points:
					if not point is Array or point.size() != 2 or not (point[0] is float or point[0] is int) or not (point[1] is float or point[1] is int) or not is_finite(float(point[0])) or not is_finite(float(point[1])):
						errors.append("weapons.%s.muzzles.%s.%s: tọa độ không hợp lệ" % [id, character, direction])

	for id in data.bodies:
		if id.is_empty():
			errors.append("bodies: ID không được rỗng")
		var b = data.bodies[id]
		if b is Dictionary and (not b.get("name") is String or b.get("name", "").strip_edges().is_empty()):
			errors.append("bodies.%s.name: cần tên" % id)
		if not b is Dictionary or not data.characters.has(b.get("character", "")) or not artwork.layers.has(b.get("art_id", "")):
			errors.append("bodies.%s: nhân vật/art_id không hợp lệ" % id)
	for id in data.characters:
		if id.is_empty():
			errors.append("characters: ID không được rỗng")
		var c = data.characters[id]
		if not c is Dictionary:
			errors.append("characters.%s: cần object" % id)
			continue
		if not c.get("name") is String or c.get("name", "").strip_edges().is_empty():
			errors.append("characters.%s.name: cần tên" % id)
		if not positive(c.get("collider_radius")):
			errors.append("characters.%s.collider_radius: cần số dương" % id)
		if not c.get("weapon_art") is Dictionary:
			errors.append("characters.%s.weapon_art: cần liên kết artwork" % id)
		for key in ["hp", "speed"]:
			if not positive(c.get(key)) or (key == "hp" and float(c[key]) != int(c[key])):
				errors.append("characters.%s.%s: cần số dương" % [id, key])
		for key in ["bodies", "weapons"]:
			var ids = c.get(key)
			if not ids is Array or ids.is_empty():
				errors.append("characters.%s.%s: cần danh sách ID" % [id, key])
				continue
			if not c.get("default_body" if key == "bodies" else "default_weapon") in ids:
				errors.append("characters.%s.%s: mặc định không tương thích" % [id, key])
			for ref in ids:
				if ids.count(ref) > 1:
					errors.append("characters.%s.%s: ID trùng" % [id, key])
				if not ref is String:
					errors.append("characters.%s.%s: ID phải là chuỗi" % [id, key])
					continue
				if not data[key].has(ref) or not data[key][ref] is Dictionary or (key == "bodies" and data.bodies[ref].get("character") != id):
					errors.append("characters.%s.%s.%s: ID không tương thích" % [id, key, ref])
		if c.get("weapons") is Array:
			for ref in c.weapons:
				if not data.weapons.get(ref) is Dictionary:
					continue
				if not data.weapons[ref].get("muzzles", {}) is Dictionary or not data.weapons[ref].get("muzzles", {}).has(id):
					errors.append("characters.%s.weapons.%s: thiếu geometry" % [id, ref])
				if c.get("weapon_art") is Dictionary and not artwork.layers.has(c.weapon_art.get(ref, "")):
					errors.append("characters.%s.weapon_art.%s: resource không tồn tại" % [id, ref])
	for key in ["rapid_fire_rest_multiplier", "double_shot_delay"]:
		if not positive(data.power_ups.get(key)):
			errors.append("power_ups.%s: cần số dương" % key)

func create(character_id: String, body_id: String, weapon_id: String) -> Resource:
	if not errors.is_empty() or not data.characters.has(character_id):
		return null
	var c: Dictionary = data.characters[character_id]
	if not body_id in c.bodies or not weapon_id in c.weapons:
		return null
	var texture = load("res://assets/sprites/characters/layers.png") as Texture2D
	if texture == null:
		return null
	var body = Art.new()
	body.configure(texture, artwork.layers[data.bodies[body_id].art_id])
	var w: Dictionary = data.weapons[weapon_id]
	var weapon = Weapon.new()
	weapon.id = weapon_id
	weapon.display_name = w.name
	weapon.damage = int(w.damage)
	weapon.cooldown = w.rest
	weapon.bullet_speed = w.bullet_speed
	weapon.burst_times = w.times.duplicate()
	var delay: float = data.power_ups.double_shot_delay
	weapon.double_times = []
	if w.double_mode == "uniform_duration":
		for i in w.times.size() * 2:
			weapon.double_times.append(float(w.times.back()) * i / (w.times.size() * 2 - 1))
	elif w.double_mode == "alternating_pairs":
		weapon.double_times = [0.0, delay, w.times[1] + delay, w.times[1] + delay * 2]
	else:
		for time in w.times:
			weapon.double_times.append(float(time))
			weapon.double_times.append(float(time) + delay)
	weapon.rapid_rest_multiplier = data.power_ups.rapid_fire_rest_multiplier
	weapon.alternating = w.firing_mode == "alternating"
	weapon.barrel_offsets.assign(w.barrels)
	weapon.layered_art = Art.new()
	weapon.layered_art.configure(texture, artwork.layers[c.weapon_art[weapon_id]])
	for direction in w.muzzles[character_id]:
		var points: Array = []
		var socket: Vector2 = body.socket_for("roof", direction)
		for point in w.muzzles[character_id][direction]:
			points.append(Vector2(point[0], point[1]) - socket)
		weapon.explicit_muzzles[direction] = points

	var result = Loadout.new()
	result.body = body
	result.weapon = weapon
	result.character_id = character_id
	result.body_id = body_id
	result.display_name = c.name
	result.collider_radius = c.collider_radius
	result.max_hp = int(c.hp)
	result.move_speed = c.speed
	return result
