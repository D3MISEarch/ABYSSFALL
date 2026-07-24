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


func resolve_outgoing_damage(base_damage: int) -> int:
	if base_damage <= 0:
		return 0
	var resolved := maxi(0, int(round(float(base_damage) + power)))
	_critical_meter += critical_chance
	if _critical_meter >= 1.0:
		_critical_meter -= 1.0
		resolved = int(round(float(resolved) * CRITICAL_DAMAGE_MULTIPLIER))
	return resolved


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
