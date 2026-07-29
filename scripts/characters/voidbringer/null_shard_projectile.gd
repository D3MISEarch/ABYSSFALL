class_name VoidbringerNullShardProjectile
extends RefCounted

signal fold_crossing_committed(snapshot: Dictionary)
signal impact_committed(result: VoidbringerImpactResult)
signal projectile_ended(projectile_id: StringName, reason: StringName)

const BASE_SPEED := 22.0
const DEFAULT_LIFETIME := 1.8
const PROJECTILE_RADIUS := 0.28
const FOLD_SPEED_MULTIPLIER := 1.25
const FOLD_DAMAGE_MULTIPLIER := 1.12
const FOLD_ENDPOINT_MASS := 2.0
const MAXIMUM_FOLD_CROSSINGS := 3

var projectile_id: StringName = &""
var cast_id: StringName = &""
var origin := Vector3.ZERO
var previous_position := Vector3.ZERO
var position := Vector3.ZERO
var direction := Vector3.FORWARD
var speed := BASE_SPEED
var lifetime_remaining := DEFAULT_LIFETIME
var damage_multiplier := 1.0
var crossing_count := 0
var credited_fold_line_ids: Dictionary = {}
var contact_committed := false
var active := false
var end_reason: StringName = &""
var impact_result: VoidbringerImpactResult
var instability_applied := 0.0
var entered_breach := false
var in_breach_at_launch := false
var anchor_influence_multiplier_at_launch := 1.0

var _controller_ref: WeakRef
var _definition: AbilityDefinition
var _projection: PlayableCombatProjection
var _damage_bridge := VoidbringerDamageBridge.new()
var _launch_metadata: Dictionary = {}
var _launch_state_committed := false


func _init(
	p_projectile_id: StringName,
	p_cast_id: StringName,
	p_origin: Vector3,
	p_direction: Vector3,
	definition: AbilityDefinition,
	controller: VoidbringerController,
	projection: PlayableCombatProjection = null,
	launch_metadata: Dictionary = {}
) -> void:
	projectile_id = p_projectile_id
	cast_id = p_cast_id
	origin = p_origin
	previous_position = p_origin
	position = p_origin
	direction = p_direction.normalized()
	_definition = _copy_definition(definition)
	_controller_ref = weakref(controller) if controller != null else null
	_projection = projection
	_launch_metadata = launch_metadata.duplicate(true)
	active = projectile_id != &"" and cast_id != &"" and direction.length_squared() > 0.0 and _definition != null


func commit_launch_state(
	p_instability_applied: float,
	p_entered_breach: bool,
	p_in_breach_at_launch: bool
) -> void:
	if _launch_state_committed:
		return
	_launch_state_committed = true
	instability_applied = maxf(p_instability_applied, 0.0)
	entered_breach = p_entered_breach
	in_breach_at_launch = p_in_breach_at_launch
	var controller := _controller()
	if controller != null:
		anchor_influence_multiplier_at_launch = controller.instability.anchor_influence_multiplier()
	_launch_metadata["instability_applied"] = instability_applied
	_launch_metadata["entered_breach"] = entered_breach
	_launch_metadata["in_breach_at_launch"] = in_breach_at_launch
	_launch_metadata["anchor_influence_multiplier_at_launch"] = anchor_influence_multiplier_at_launch


func tick(delta: float) -> Dictionary:
	if not active:
		return snapshot()
	var step := maxf(delta, 0.0)
	if step <= 0.0:
		return snapshot()
	previous_position = position
	position += direction * speed * step
	_process_fold_crossings(previous_position, position)
	lifetime_remaining = maxf(lifetime_remaining - step, 0.0)
	if lifetime_remaining <= 0.0:
		invalidate(&"missed")
	return snapshot()


func commit_contact(
	target: Object,
	impact_point: Vector3,
	surface_normal: Vector3 = Vector3.UP,
	target_mass_class: StringName = &"standard",
	surface_profile: StringName = &"default",
	death_profile: StringName = &"default"
) -> Dictionary:
	if not active or contact_committed or not _target_is_logically_alive(target):
		return {}
	contact_committed = true
	active = false
	end_reason = &"contact"

	var damage_result := _damage_bridge.resolve_definition_with_multiplier(
		_definition,
		damage_multiplier,
		_projection
	)
	var resolved_damage := int(damage_result.get("damage", 0))
	var health_before := _read_health(target)
	var damage_return: Variant = null
	var damage_method_called := target.has_method("take_damage")
	if damage_method_called:
		damage_return = target.call("take_damage", resolved_damage)
	var health_after := _read_health(target)
	var damage_applied := _resolve_applied_damage(
		resolved_damage,
		health_before,
		health_after,
		damage_return,
		damage_method_called
	)
	var fatal := _is_target_fatal(target, health_after)
	var normalized_normal := surface_normal.normalized() if surface_normal.length_squared() > 0.0 else Vector3.UP
	var result_data := {
		"projectile_id": projectile_id,
		"cast_id": cast_id,
		"ability_id": _definition.ability_id,
		"attack_origin": origin,
		"travel_direction": direction,
		"impact_point": impact_point,
		"surface_normal": normalized_normal,
		"target_instance_id": target.get_instance_id(),
		"target_name": str(target.get("name")) if _object_has_property(target, &"name") else target.get_class(),
		"target_mass_class": target_mass_class,
		"base_damage": int(damage_result.get("base_damage", 0)),
		"pre_critical_damage": int(damage_result.get("pre_critical_damage", 0)),
		"damage": resolved_damage,
		"damage_applied": damage_applied,
		"critical": bool(damage_result.get("critical", false)),
		"fatal": fatal,
		"damage_coefficient": float(damage_result.get("coefficient", 0.0)),
		"damage_multiplier": damage_multiplier,
		"impulse_request": {
			"direction": direction,
			"strength": 0.0,
		},
		"surface_profile": surface_profile,
		"death_profile": death_profile,
		"fold_crossing_count": crossing_count,
		"credited_fold_line_ids": _credited_line_ids(),
		"instability_applied": instability_applied,
		"entered_breach": entered_breach,
		"in_breach_at_launch": in_breach_at_launch,
		"anchor_influence_multiplier_at_launch": anchor_influence_multiplier_at_launch,
		"launch_metadata": _launch_metadata.duplicate(true),
	}
	impact_result = VoidbringerImpactResult.new(result_data)
	impact_committed.emit(impact_result)
	projectile_ended.emit(projectile_id, end_reason)
	return impact_result.snapshot()


func invalidate(reason: StringName = &"teardown") -> void:
	if not active:
		return
	active = false
	end_reason = reason
	projectile_ended.emit(projectile_id, end_reason)


func snapshot() -> Dictionary:
	return {
		"projectile_id": projectile_id,
		"cast_id": cast_id,
		"ability_id": &"" if _definition == null else _definition.ability_id,
		"origin": origin,
		"previous_position": previous_position,
		"position": position,
		"direction": direction,
		"speed": speed,
		"lifetime_remaining": lifetime_remaining,
		"projectile_radius": PROJECTILE_RADIUS,
		"damage_multiplier": damage_multiplier,
		"crossing_count": crossing_count,
		"credited_fold_line_ids": _credited_line_ids(),
		"contact_committed": contact_committed,
		"active": active,
		"end_reason": end_reason,
		"instability_applied": instability_applied,
		"entered_breach": entered_breach,
		"in_breach_at_launch": in_breach_at_launch,
		"anchor_influence_multiplier_at_launch": anchor_influence_multiplier_at_launch,
		"impact": {} if impact_result == null else impact_result.snapshot(),
	}


func _process_fold_crossings(from: Vector3, to: Vector3) -> void:
	if crossing_count >= MAXIMUM_FOLD_CROSSINGS:
		return
	var controller := _controller()
	if controller == null:
		return
	var crossings := controller.fold_lines.segment_crossings(from, to, PROJECTILE_RADIUS)
	crossings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("line_id", "")) < str(b.get("line_id", ""))
	)
	for line: Dictionary in crossings:
		if crossing_count >= MAXIMUM_FOLD_CROSSINGS:
			break
		var line_id := StringName(str(line.get("line_id", "")))
		if line_id == &"" or credited_fold_line_ids.has(line_id):
			continue
		var anchor_a_id := StringName(str(line.get("anchor_a_id", "")))
		var anchor_b_id := StringName(str(line.get("anchor_b_id", "")))
		if not controller.anchors.has_anchor(anchor_a_id) or not controller.anchors.has_anchor(anchor_b_id):
			continue
		credited_fold_line_ids[line_id] = true
		crossing_count += 1
		speed *= FOLD_SPEED_MULTIPLIER
		damage_multiplier *= FOLD_DAMAGE_MULTIPLIER
		controller.add_anchor_mass(anchor_a_id, FOLD_ENDPOINT_MASS)
		controller.add_anchor_mass(anchor_b_id, FOLD_ENDPOINT_MASS)
		fold_crossing_committed.emit({
			"projectile_id": projectile_id,
			"cast_id": cast_id,
			"line_id": line_id,
			"anchor_a_id": anchor_a_id,
			"anchor_b_id": anchor_b_id,
			"crossing_count": crossing_count,
			"speed": speed,
			"damage_multiplier": damage_multiplier,
			"mass_added_to_each_anchor": FOLD_ENDPOINT_MASS,
		})


func _controller() -> VoidbringerController:
	if _controller_ref == null:
		return null
	var value: Object = _controller_ref.get_ref()
	return value as VoidbringerController if value is VoidbringerController else null


func _credited_line_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for raw_id: Variant in credited_fold_line_ids.keys():
		result.append(StringName(str(raw_id)))
	result.sort_custom(func(a: StringName, b: StringName) -> bool:
		return String(a) < String(b)
	)
	return result


func _copy_definition(source: AbilityDefinition) -> AbilityDefinition:
	if source == null or not source.is_valid():
		return null
	return AbilityDefinition.new(
		source.ability_id,
		source.resource_id,
		source.resource_cost,
		source.cooldown_seconds,
		source.slot_type,
		source.maximum_charges,
		source.recharge_seconds,
		source.instability_delta,
		source.tags,
		source.damage_coefficient
	)


func _target_is_logically_alive(target: Object) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if _object_has_property(target, &"alive"):
		return bool(target.get("alive"))
	return true


func _read_health(target: Object) -> float:
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
