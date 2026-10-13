class_name PickupSettings
extends Resource

const POWER_UP_IDS = ["shield", "rapid_fire", "speed_boost", "double_shot", "base_shield"]
@export var drop_enabled := true
@export_range(0, 1) var drop_chance := 0.4
@export_range(0, 1) var weapon_chance := 0.7
@export var periodic_enabled := true
@export var periodic_interval := 5.0
@export var periodic_min := 1
@export var periodic_max := 2
@export var power_up_limit := 10
@export var lifetime := 20.0
@export var power_up_pool: Array[String] = ["shield", "rapid_fire", "speed_boost", "double_shot", "base_shield"]
@export var weapon_pool: Array[String] = []
@export var power_up_weights: Dictionary = {}
@export var weapon_weights: Dictionary = {}
@export var lifetime_overrides: Dictionary = {}

func validate(catalog: RefCounted) -> Array[String]:
	var errors: Array[String] = []
	for property in ["drop_chance", "weapon_chance"]:
		var value: float = get(property)
		if not is_finite(value) or value < 0 or value > 1:
			errors.append("pickup.%s: cần xác suất 0–1" % property)
	for property in ["periodic_interval", "lifetime"]:
		var value: float = get(property)
		if not is_finite(value) or value <= 0:
			errors.append("pickup.%s: cần số dương hữu hạn" % property)
	if periodic_min < 0 or periodic_max < periodic_min or periodic_max > 1000:
		errors.append("pickup.periodic_min/max: cần 0 ≤ min ≤ max ≤ 1000")
	if power_up_limit < 0:
		errors.append("pickup.power_up_limit: cần số không âm")
	for category in ["power_up", "weapon"]:
		var pool: Array = get(category + "_pool")
		var weights: Dictionary = get(category + "_weights")
		var valid_ids: Array = POWER_UP_IDS if category == "power_up" else catalog.data.weapons.keys()
		if category == "power_up" and pool.is_empty():
			errors.append("pickup.power_up_pool: không được rỗng")
		for id in pool:
			if id not in valid_ids or pool.count(id) > 1:
				errors.append("pickup.%s_pool: ID không hợp lệ/trùng: %s" % [category, id])
		var total := 0.0
		var effective_pool: Array = valid_ids if category == "weapon" and pool.is_empty() else pool
		for id in weights:
			var weight = weights[id]
			if id not in effective_pool or not (weight is int or weight is float) or not is_finite(float(weight)) or weight < 0:
				errors.append("pickup.%s_weights.%s: trọng số không hợp lệ" % [category, id])
		for id in effective_pool:
			var weight = weights.get(id, 1.0)
			if weight is int or weight is float:
				total += maxf(0, float(weight))
		if not effective_pool.is_empty() and total <= 0:
			errors.append("pickup.%s_weights: tổng trọng số phải dương" % category)
	for id in lifetime_overrides:
		var value = lifetime_overrides[id]
		if id not in POWER_UP_IDS and not catalog.data.weapons.has(id):
			errors.append("pickup.lifetime_overrides: ID không hợp lệ: " + str(id))
		if not (value is float or value is int) or not is_finite(float(value)) or value <= 0:
			errors.append("pickup.lifetime_overrides.%s: cần số dương hữu hạn" % id)
	return errors

func choose(category: String, rng: RandomNumberGenerator, compatible: Array = []) -> String:
	var pool: Array = power_up_pool.duplicate() if category == "power_up" else (compatible.duplicate() if weapon_pool.is_empty() else weapon_pool.filter(func(id): return id in compatible))
	var weights: Dictionary = power_up_weights if category == "power_up" else weapon_weights
	var total := 0.0
	for id in pool:
		total += float(weights.get(id, 1.0))
	if total <= 0:
		return ""
	var roll := rng.randf() * total
	for id in pool:
		roll -= float(weights.get(id, 1.0))
		if roll < 0:
			return id
	return pool.back()

func lifetime_for(id: String) -> float:
	return float(lifetime_overrides.get(id, lifetime))
