class_name VoidbringerMassBrandImpactResolver
extends RefCounted

var _damage_bridge := VoidbringerDamageBridge.new()


func resolve(
	definition: AbilityDefinition,
	cast_id: StringName,
	carrier_type: StringName,
	carrier: Variant,
	impact_point: Vector3,
	anchor: Dictionary,
	projection: PlayableCombatProjection,
	metadata: Dictionary,
	instability_applied: float,
	entered_breach: bool
) -> VoidbringerImpactResult:
	var target := carrier as Object if carrier is Object else null
	var deals_enemy_damage := carrier_type == VoidbringerAnchorManager.CARRIER_ENEMY and target != null and is_instance_valid(target)
	var damage_result: Dictionary
	if deals_enemy_damage:
		damage_result = _damage_bridge.resolve_definition(definition, projection)
	else:
		damage_result = {
			"base_damage": _damage_bridge.base_damage_for_definition(definition),
			"pre_critical_damage": 0,
			"damage": 0,
			"critical": false,
			"coefficient": 0.0 if definition == null else definition.damage_coefficient,
		}

	var health_before := _read_health(target)
	var damage_return: Variant = null
	var resolved_damage := int(damage_result.get("damage", 0))
	if deals_enemy_damage and target.has_method("take_damage"):
		damage_return = target.call("take_damage", resolved_damage)
	var health_after := _read_health(target)
	var damage_applied := _resolve_applied_damage(
		resolved_damage,
		health_before,
		health_after,
		damage_return,
		deals_enemy_damage and target != null and target.has_method("take_damage")
	)
	var attack_origin: Vector3 = metadata.get("attack_origin", impact_point)
	var travel_direction := impact_point - attack_origin
	if travel_direction.length_squared() <= 0.000001:
		travel_direction = Vector3.DOWN
	else:
		travel_direction = travel_direction.normalized()
	var surface_normal: Vector3 = metadata.get("surface_normal", Vector3.UP)
	if surface_normal.length_squared() <= 0.000001:
		surface_normal = Vector3.UP
	else:
		surface_normal = surface_normal.normalized()
	var target_instance_id := 0
	var target_name := String(carrier_type)
	if target != null and is_instance_valid(target):
		target_instance_id = target.get_instance_id()
		target_name = str(target.get("name")) if _object_has_property(target, &"name") else target.get_class()

	return VoidbringerImpactResult.new({
		"cast_id": cast_id,
		"ability_id": &"" if definition == null else definition.ability_id,
		"attack_origin": attack_origin,
		"travel_direction": travel_direction,
		"impact_point": impact_point,
		"surface_normal": surface_normal,
		"target_instance_id": target_instance_id,
		"target_name": target_name,
		"target_mass_class": StringName(str(metadata.get("target_mass_class", "standard"))),
		"carrier_type": carrier_type,
		"base_damage": int(damage_result.get("base_damage", 0)),
		"pre_critical_damage": int(damage_result.get("pre_critical_damage", 0)),
		"damage": resolved_damage,
		"damage_applied": damage_applied,
		"critical": bool(damage_result.get("critical", false)),
		"fatal": _is_target_fatal(target, health_after),
		"damage_coefficient": float(damage_result.get("coefficient", 0.0)),
		"damage_multiplier": 1.0,
		"impulse_request": {
			"direction": travel_direction,
			"strength": 0.0,
		},
		"surface_profile": StringName(str(metadata.get("surface_profile", "default"))),
		"death_profile": StringName(str(metadata.get("death_profile", "default"))),
		"anchor_id": anchor.get("anchor_id", &""),
		"anchor_mass": float(anchor.get("mass", 0.0)),
		"anchor_mass_stage": anchor.get("mass_stage", &"dormant"),
		"fold_crossing_count": 0,
		"credited_fold_line_ids": [],
		"instability_applied": instability_applied,
		"entered_breach": entered_breach,
		"metadata": metadata.duplicate(true),
	})


func _read_health(target: Object) -> float:
	if target == null or not is_instance_valid(target):
		return -1.0
	if _object_has_property(target, &"health"):
		return float(target.get("health"))
	if _object_has_property(target, &"current_health"):
		return float(target.get("current_health"))
	return -1.0


func _resolve_applied_damage(
	resolved_damage: int,
	health_before: float,
	health_after: float,
	damage_return: Variant,
	damage_method_called: bool
) -> float:
	if health_before >= 0.0 and health_after >= 0.0:
		return maxf(health_before - health_after, 0.0)
	if damage_return is int or damage_return is float:
		return maxf(float(damage_return), 0.0)
	return float(resolved_damage) if damage_method_called else 0.0


func _is_target_fatal(target: Object, health_after: float) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if _object_has_property(target, &"alive") and not bool(target.get("alive")):
		return true
	return health_after >= 0.0 and health_after <= 0.0


func _object_has_property(object: Object, property_name: StringName) -> bool:
	if object == null:
		return false
	for property: Dictionary in object.get_property_list():
		if StringName(str(property.get("name", ""))) == property_name:
			return true
	return false
