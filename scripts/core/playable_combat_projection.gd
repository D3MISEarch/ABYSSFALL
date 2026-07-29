class_name PlayableCombatProjection
extends RefCounted

const CRITICAL_DAMAGE_MULTIPLIER := 1.5

var armor := 0.0
var power := 0.0
var critical_chance := 0.0
var _critical_meter := 0.0


func configure(snapshot: Dictionary) -> void:
	armor = maxf(0.0, float(snapshot.get("armor", 0.0)))
	power = float(snapshot.get("power", 0.0))
	critical_chance = clampf(float(snapshot.get("critical_chance", 0.0)), 0.0, 1.0)
	_critical_meter = clampf(_critical_meter, 0.0, 0.999999)


func peek_pre_critical_damage(base_damage: int) -> int:
	return peek_pre_critical_damage_with_multiplier(base_damage, 1.0)


func peek_pre_critical_damage_with_multiplier(base_damage: int, damage_multiplier: float) -> int:
	if base_damage <= 0:
		return 0
	var projected := maxf(float(base_damage) + power, 0.0)
	return maxi(0, int(round(projected * maxf(damage_multiplier, 0.0))))


func resolve_outgoing_damage(base_damage: int) -> int:
	return int(resolve_outgoing_result(base_damage).get("damage", 0))


func resolve_outgoing_result(base_damage: int) -> Dictionary:
	return resolve_outgoing_result_with_multiplier(base_damage, 1.0)


func resolve_outgoing_result_with_multiplier(base_damage: int, damage_multiplier: float) -> Dictionary:
	var clamped_multiplier := maxf(damage_multiplier, 0.0)
	if base_damage <= 0:
		return {
			"damage": 0,
			"critical": false,
			"pre_critical_damage": 0,
			"base_damage": maxi(base_damage, 0),
			"damage_multiplier": clamped_multiplier,
		}
	var pre_critical := peek_pre_critical_damage_with_multiplier(base_damage, clamped_multiplier)
	_critical_meter += critical_chance
	var critical := false
	var resolved := pre_critical
	if _critical_meter >= 1.0:
		_critical_meter -= 1.0
		critical = true
		resolved = int(round(float(resolved) * CRITICAL_DAMAGE_MULTIPLIER))
	return {
		"damage": resolved,
		"critical": critical,
		"pre_critical_damage": pre_critical,
		"base_damage": base_damage,
		"damage_multiplier": clamped_multiplier,
	}


func resolve_incoming_damage(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	return maxi(1, int(round(float(base_damage) - armor)))


func snapshot() -> Dictionary:
	return {
		"armor": armor,
		"power": power,
		"critical_chance": critical_chance,
	}
