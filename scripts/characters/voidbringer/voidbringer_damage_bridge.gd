class_name VoidbringerDamageBridge
extends RefCounted

const COMPATIBILITY_WEAPON_POWER := 24.0


func base_damage_for_coefficient(coefficient: float) -> int:
	return maxi(0, int(round(COMPATIBILITY_WEAPON_POWER * maxf(coefficient, 0.0))))


func base_damage_for_definition(definition: AbilityDefinition) -> int:
	if definition == null:
		return 0
	return definition.base_damage_for_weapon_power(COMPATIBILITY_WEAPON_POWER)


func resolve_with_projection(coefficient: float, projection: PlayableCombatProjection) -> Dictionary:
	var base_damage := base_damage_for_coefficient(coefficient)
	return _resolve(base_damage, maxf(coefficient, 0.0), &"", projection)


func resolve_definition(definition: AbilityDefinition, projection: PlayableCombatProjection) -> Dictionary:
	if definition == null or not definition.is_valid():
		return _resolve(0, 0.0, &"", projection)
	return _resolve(
		base_damage_for_definition(definition),
		definition.damage_coefficient,
		definition.ability_id,
		projection
	)


func preview_definition(definition: AbilityDefinition, projection: PlayableCombatProjection) -> Dictionary:
	var base_damage := base_damage_for_definition(definition)
	var pre_critical := base_damage if projection == null else projection.peek_pre_critical_damage(base_damage)
	return {
		"ability_id": &"" if definition == null else definition.ability_id,
		"base_damage": base_damage,
		"pre_critical_damage": pre_critical,
		"weapon_power": COMPATIBILITY_WEAPON_POWER,
		"coefficient": 0.0 if definition == null else definition.damage_coefficient,
	}


func _resolve(
	base_damage: int,
	coefficient: float,
	ability_id: StringName,
	projection: PlayableCombatProjection
) -> Dictionary:
	if projection == null:
		return {
			"ability_id": ability_id,
			"damage": base_damage,
			"critical": false,
			"pre_critical_damage": base_damage,
			"base_damage": base_damage,
			"weapon_power": COMPATIBILITY_WEAPON_POWER,
			"coefficient": coefficient,
		}
	var result := projection.resolve_outgoing_result(base_damage)
	result["ability_id"] = ability_id
	result["weapon_power"] = COMPATIBILITY_WEAPON_POWER
	result["coefficient"] = coefficient
	return result
