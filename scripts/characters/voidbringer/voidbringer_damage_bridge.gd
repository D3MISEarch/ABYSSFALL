class_name VoidbringerDamageBridge
extends RefCounted

const COMPATIBILITY_WEAPON_POWER := 24.0


func base_damage_for_coefficient(coefficient: float) -> int:
	return maxi(0, int(round(COMPATIBILITY_WEAPON_POWER * maxf(coefficient, 0.0))))


func resolve_with_projection(coefficient: float, projection: PlayableCombatProjection) -> Dictionary:
	var base_damage := base_damage_for_coefficient(coefficient)
	if projection == null:
		return {
			"damage": base_damage,
			"critical": false,
			"pre_critical_damage": base_damage,
			"base_damage": base_damage,
			"weapon_power": COMPATIBILITY_WEAPON_POWER,
			"coefficient": maxf(coefficient, 0.0),
		}
	var result := projection.resolve_outgoing_result(base_damage)
	result["weapon_power"] = COMPATIBILITY_WEAPON_POWER
	result["coefficient"] = maxf(coefficient, 0.0)
	return result
