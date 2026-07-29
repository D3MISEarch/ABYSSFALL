class_name AbilityExecutor
extends RefCounted

const REASON_OK: StringName = &"ok"
const REASON_INVALID_ABILITY: StringName = &"invalid_ability"
const REASON_NO_CHARACTER: StringName = &"no_character"
const REASON_LOCKED: StringName = &"ability_locked"
const REASON_NOT_EQUIPPED: StringName = &"ability_not_equipped"
const REASON_RESOURCE_MISMATCH: StringName = &"resource_mismatch"
const REASON_COOLDOWN: StringName = &"cooldown"
const REASON_NO_CHARGES: StringName = &"no_charges"
const REASON_INSUFFICIENT_RESOURCE: StringName = &"insufficient_resource"

var event_bus: RuntimeEventBus
var _runtimes: Dictionary = {}


func _init(p_event_bus: RuntimeEventBus = null) -> void:
	event_bus = p_event_bus


func execute(
	character: RuntimeCharacter,
	definition: AbilityDefinition,
	equipped_ability_ids: Variant = null
) -> Dictionary:
	return commit(character, definition, equipped_ability_ids, true)


func preflight(
	character: RuntimeCharacter,
	definition: AbilityDefinition,
	equipped_ability_ids: Variant = null,
	emit_rejection: bool = false
) -> Dictionary:
	var check := _preflight(character, definition, equipped_ability_ids)
	var reason: StringName = check.get("reason", REASON_INVALID_ABILITY)
	var runtime := check.get("runtime", null) as AbilityRuntime
	if reason != REASON_OK and emit_rejection:
		_emit_rejected(character, definition, reason)
	return _result(reason == REASON_OK, reason, character, definition, runtime)


func commit(
	character: RuntimeCharacter,
	definition: AbilityDefinition,
	equipped_ability_ids: Variant = null,
	emit_cast_event: bool = true
) -> Dictionary:
	var check := _preflight(character, definition, equipped_ability_ids)
	var reason: StringName = check.get("reason", REASON_INVALID_ABILITY)
	var runtime := check.get("runtime", null) as AbilityRuntime
	if reason != REASON_OK:
		_emit_rejected(character, definition, reason)
		return _result(false, reason, character, definition, runtime)
	if runtime == null or not runtime.try_cast(character.class_resource):
		_emit_rejected(character, definition, REASON_INSUFFICIENT_RESOURCE)
		return _result(false, REASON_INSUFFICIENT_RESOURCE, character, definition, runtime)
	if emit_cast_event:
		emit_committed_cast(character, definition)
	return _result(true, REASON_OK, character, definition, runtime)


func emit_committed_cast(character: RuntimeCharacter, definition: AbilityDefinition) -> void:
	if event_bus == null or character == null or definition == null:
		return
	event_bus.ability_cast.emit(character.build_id, definition.ability_id)


func emit_rejection(character: RuntimeCharacter, definition: AbilityDefinition, reason: StringName) -> void:
	_emit_rejected(character, definition, reason)


func tick(delta: float) -> void:
	for runtime: AbilityRuntime in _runtimes.values():
		runtime.tick(delta)


func cooldown_remaining(build_id: String, ability_id: StringName) -> float:
	var runtime := _existing_runtime(build_id, ability_id)
	return 0.0 if runtime == null else runtime.cooldown_remaining


func charges_remaining(build_id: String, ability_id: StringName) -> int:
	var runtime := _existing_runtime(build_id, ability_id)
	return 0 if runtime == null else runtime.current_charges


func charge_snapshot(build_id: String, ability_id: StringName) -> Dictionary:
	var runtime := _existing_runtime(build_id, ability_id)
	return {} if runtime == null else runtime.charge_snapshot()


func clear_build(build_id: String) -> void:
	var prefix := "%s::" % build_id
	for key: Variant in _runtimes.keys():
		if str(key).begins_with(prefix):
			_runtimes.erase(key)


func _preflight(
	character: RuntimeCharacter,
	definition: AbilityDefinition,
	equipped_ability_ids: Variant = null
) -> Dictionary:
	var validation := _validate(character, definition, equipped_ability_ids)
	if validation != REASON_OK:
		return {"reason": validation, "runtime": null}
	var runtime := _runtime_for(character, definition)
	if runtime.cooldown_remaining > 0.0:
		return {"reason": REASON_COOLDOWN, "runtime": runtime}
	if not runtime.has_available_charge():
		return {"reason": REASON_NO_CHARGES, "runtime": runtime}
	if not character.class_resource.can_spend(definition.resource_cost):
		return {"reason": REASON_INSUFFICIENT_RESOURCE, "runtime": runtime}
	return {"reason": REASON_OK, "runtime": runtime}


func _validate(
	character: RuntimeCharacter,
	definition: AbilityDefinition,
	equipped_ability_ids: Variant = null
) -> StringName:
	if character == null:
		return REASON_NO_CHARACTER
	if definition == null or not definition.is_valid():
		return REASON_INVALID_ABILITY
	if not character.unlocked_abilities.has(definition.ability_id):
		return REASON_LOCKED
	if equipped_ability_ids != null:
		if not equipped_ability_ids is Array or not _contains_ability_id(equipped_ability_ids, definition.ability_id):
			return REASON_NOT_EQUIPPED
	if character.class_resource.resource_id != definition.resource_id:
		return REASON_RESOURCE_MISMATCH
	return REASON_OK


func _contains_ability_id(raw_ids: Array, ability_id: StringName) -> bool:
	for raw_id: Variant in raw_ids:
		if StringName(str(raw_id)) == ability_id:
			return true
	return false


func _runtime_for(character: RuntimeCharacter, definition: AbilityDefinition) -> AbilityRuntime:
	var key := _runtime_key(character.build_id, definition.ability_id)
	if not _runtimes.has(key):
		_runtimes[key] = AbilityRuntime.new(
			definition.ability_id,
			definition.resource_cost,
			definition.cooldown_seconds,
			definition.maximum_charges,
			definition.recharge_seconds
		)
	return _runtimes[key] as AbilityRuntime


func _existing_runtime(build_id: String, ability_id: StringName) -> AbilityRuntime:
	var key := _runtime_key(build_id, ability_id)
	if not _runtimes.has(key):
		return null
	return _runtimes[key] as AbilityRuntime


func _runtime_key(build_id: String, ability_id: StringName) -> String:
	return "%s::%s" % [build_id, String(ability_id)]


func _emit_rejected(character: RuntimeCharacter, definition: AbilityDefinition, reason: StringName) -> void:
	if event_bus == null:
		return
	var build_id := "" if character == null else character.build_id
	var ability_id: StringName = &"" if definition == null else definition.ability_id
	event_bus.ability_rejected.emit(build_id, ability_id, reason)


func _result(
	success: bool,
	reason: StringName,
	character: RuntimeCharacter,
	definition: AbilityDefinition,
	runtime: AbilityRuntime = null
) -> Dictionary:
	var charge_state: Dictionary = {} if runtime == null else runtime.charge_snapshot()
	return {
		"success": success,
		"reason": reason,
		"build_id": "" if character == null else character.build_id,
		"ability_id": &"" if definition == null else definition.ability_id,
		"cooldown_remaining": 0.0 if runtime == null else runtime.cooldown_remaining,
		"uses_charges": bool(charge_state.get("uses_charges", false)),
		"charges_remaining": int(charge_state.get("current", 0)),
		"maximum_charges": int(charge_state.get("maximum", 0)),
		"recharge_remaining": float(charge_state.get("recharge_remaining", 0.0)),
	}
