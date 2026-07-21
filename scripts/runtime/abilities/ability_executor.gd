class_name AbilityExecutor
extends RefCounted

const REASON_OK: StringName = &"ok"
const REASON_INVALID_ABILITY: StringName = &"invalid_ability"
const REASON_NO_CHARACTER: StringName = &"no_character"
const REASON_LOCKED: StringName = &"ability_locked"
const REASON_RESOURCE_MISMATCH: StringName = &"resource_mismatch"
const REASON_COOLDOWN: StringName = &"cooldown"
const REASON_INSUFFICIENT_RESOURCE: StringName = &"insufficient_resource"

var event_bus: RuntimeEventBus
var _runtimes: Dictionary = {}


func _init(p_event_bus: RuntimeEventBus = null) -> void:
	event_bus = p_event_bus


func execute(character: RuntimeCharacter, definition: AbilityDefinition) -> Dictionary:
	var validation := _validate(character, definition)
	if validation != REASON_OK:
		_emit_rejected(character, definition, validation)
		return _result(false, validation, character, definition)

	var runtime := _runtime_for(character, definition)
	if runtime.cooldown_remaining > 0.0:
		_emit_rejected(character, definition, REASON_COOLDOWN)
		return _result(false, REASON_COOLDOWN, character, definition, runtime.cooldown_remaining)
	if not character.class_resource.can_spend(definition.resource_cost):
		_emit_rejected(character, definition, REASON_INSUFFICIENT_RESOURCE)
		return _result(false, REASON_INSUFFICIENT_RESOURCE, character, definition)
	if not runtime.try_cast(character.class_resource):
		_emit_rejected(character, definition, REASON_INSUFFICIENT_RESOURCE)
		return _result(false, REASON_INSUFFICIENT_RESOURCE, character, definition)

	if event_bus != null:
		event_bus.ability_cast.emit(character.build_id, definition.ability_id)
	return _result(true, REASON_OK, character, definition, runtime.cooldown_remaining)


func tick(delta: float) -> void:
	for runtime: AbilityRuntime in _runtimes.values():
		runtime.tick(delta)


func cooldown_remaining(build_id: String, ability_id: StringName) -> float:
	var key := _runtime_key(build_id, ability_id)
	if not _runtimes.has(key):
		return 0.0
	return float((_runtimes[key] as AbilityRuntime).cooldown_remaining)


func clear_build(build_id: String) -> void:
	var prefix := "%s::" % build_id
	for key: Variant in _runtimes.keys():
		if str(key).begins_with(prefix):
			_runtimes.erase(key)


func _validate(character: RuntimeCharacter, definition: AbilityDefinition) -> StringName:
	if character == null:
		return REASON_NO_CHARACTER
	if definition == null or not definition.is_valid():
		return REASON_INVALID_ABILITY
	if not character.unlocked_abilities.has(definition.ability_id):
		return REASON_LOCKED
	if character.class_resource.resource_id != definition.resource_id:
		return REASON_RESOURCE_MISMATCH
	return REASON_OK


func _runtime_for(character: RuntimeCharacter, definition: AbilityDefinition) -> AbilityRuntime:
	var key := _runtime_key(character.build_id, definition.ability_id)
	if not _runtimes.has(key):
		_runtimes[key] = AbilityRuntime.new(
			definition.ability_id,
			definition.resource_cost,
			definition.cooldown_seconds
		)
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
	remaining: float = 0.0
) -> Dictionary:
	return {
		"success": success,
		"reason": reason,
		"build_id": "" if character == null else character.build_id,
		"ability_id": &"" if definition == null else definition.ability_id,
		"cooldown_remaining": remaining,
	}
