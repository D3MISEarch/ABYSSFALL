class_name VoidbringerController
extends RefCounted

signal foundation_changed(snapshot: Dictionary)
signal skill_committed(commit: VoidbringerSkillCommit)
signal skill_rejected(commit: VoidbringerSkillCommit)

var anchors := VoidbringerAnchorManager.new()
var fold_lines := VoidbringerFoldLineManager.new()
var instability := VoidbringerInstabilityController.new()
var runtime_session: RuntimeSession
var runtime_character: RuntimeCharacter
var last_skill_commit: VoidbringerSkillCommit

var _next_cast_serial := 1
var _transaction_depth := 0
var _snapshot_dirty := false


func _init() -> void:
	anchors.anchor_created.connect(_on_anchor_state_changed)
	anchors.anchor_updated.connect(_on_anchor_state_changed)
	anchors.anchor_removed.connect(_on_anchor_removed)
	instability.instability_changed.connect(_on_instability_changed)
	instability.breach_started.connect(_on_breach_started)
	instability.breach_ended.connect(_on_breach_ended)


func configure(owner_level: int) -> void:
	anchors.configure(owner_level, false)
	_rebuild_fold_lines()
	_emit_snapshot()


func bind_runtime(session: RuntimeSession, character: RuntimeCharacter) -> bool:
	if session == null or character == null or session.character != character:
		return false
	runtime_session = session
	runtime_character = character
	configure(character.level)
	return true


func is_runtime_bound() -> bool:
	return runtime_session != null and runtime_character != null and runtime_session.character == runtime_character


func execute_ability(definition: AbilityDefinition, equipped_ability_ids: Variant = null) -> Dictionary:
	if not is_runtime_bound():
		return {
			"success": false,
			"reason": &"runtime_unbound",
			"ability_id": &"" if definition == null else definition.ability_id,
		}
	return runtime_session.execute_ability(definition, equipped_ability_ids)


func execute_mass_brand_command(
	definition: AbilityDefinition,
	carrier_type: StringName,
	carrier: Variant,
	position: Vector3,
	mass: float = 0.0,
	metadata: Dictionary = {},
	equipped_ability_ids: Variant = null
) -> Dictionary:
	if not is_runtime_bound():
		return _reject_skill(definition, &"runtime_unbound")
	if definition == null or definition.ability_id != VoidbringerAbilityCatalog.MASS_BRAND:
		if runtime_session != null:
			runtime_session.ability_executor.emit_rejection(runtime_character, definition, &"invalid_ability")
		return _reject_skill(definition, &"invalid_ability")

	var placement_reason := anchors.validate_placement(carrier_type, carrier)
	if placement_reason != VoidbringerAnchorManager.PLACEMENT_OK:
		runtime_session.ability_executor.emit_rejection(runtime_character, definition, placement_reason)
		return _reject_skill(definition, placement_reason)

	var preflight := runtime_session.ability_executor.preflight(
		runtime_character,
		definition,
		equipped_ability_ids,
		true
	)
	if not bool(preflight.get("success", false)):
		return _reject_skill(definition, StringName(str(preflight.get("reason", "rejected"))), preflight)

	placement_reason = anchors.validate_placement(carrier_type, carrier)
	if placement_reason != VoidbringerAnchorManager.PLACEMENT_OK:
		runtime_session.ability_executor.emit_rejection(runtime_character, definition, placement_reason)
		return _reject_skill(definition, placement_reason, preflight)

	_begin_transaction()
	var ability_result := runtime_session.ability_executor.commit(
		runtime_character,
		definition,
		equipped_ability_ids,
		false
	)
	if not bool(ability_result.get("success", false)):
		_end_transaction(false)
		return _reject_skill(
			definition,
			StringName(str(ability_result.get("reason", "rejected"))),
			ability_result
		)

	var placement := anchors.place_anchor_transaction(carrier_type, carrier, position, mass, metadata)
	if placement.is_empty():
		_end_transaction(true)
		push_error("Mass Brand placement invariant failed after a successful no-callback revalidation")
		return _reject_skill(definition, &"placement_invariant_failed", ability_result)

	var was_in_breach := instability.in_breach
	var instability_applied := instability.commit_spatial_ability(definition.instability_delta)
	var entered_breach := not was_in_breach and instability.in_breach
	var cast_id := StringName("vb.cast.%06d" % _next_cast_serial)
	_next_cast_serial += 1
	var anchor: Dictionary = placement.get("anchor", {})
	var result_data := {
		"success": true,
		"reason": &"ok",
		"cast_id": cast_id,
		"ability_id": definition.ability_id,
		"build_id": runtime_character.build_id,
		"carrier_type": carrier_type,
		"anchor": anchor.duplicate(true),
		"removed_anchor_events": (placement.get("removed_events", []) as Array).duplicate(true),
		"instability_applied": instability_applied,
		"entered_breach": entered_breach,
		"ability_runtime": ability_result.duplicate(true),
		"foundation_snapshot": snapshot(),
	}

	runtime_session.ability_executor.emit_committed_cast(runtime_character, definition)
	anchors.emit_placement_events(placement)
	_end_transaction(true)
	last_skill_commit = VoidbringerSkillCommit.new(result_data)
	skill_committed.emit(last_skill_commit)
	return last_skill_commit.snapshot()


func place_anchor(
	carrier_type: StringName,
	carrier: Variant,
	position: Vector3,
	mass: float = 0.0,
	metadata: Dictionary = {}
) -> Dictionary:
	return anchors.place_anchor(carrier_type, carrier, position, mass, metadata)


func add_anchor_mass(anchor_id: StringName, amount: float) -> Dictionary:
	return anchors.add_mass(anchor_id, amount)


func commit_spatial_ability(instability_delta: float) -> float:
	return instability.commit_spatial_ability(instability_delta)


func tick(delta: float) -> void:
	anchors.tick(delta)
	instability.tick(delta)
	_rebuild_fold_lines()


func clear() -> void:
	anchors.clear(&"teardown")
	fold_lines.clear()
	instability.clear()
	last_skill_commit = null
	_emit_snapshot()


func snapshot() -> Dictionary:
	return {
		"runtime_bound": is_runtime_bound(),
		"build_id": "" if runtime_character == null else runtime_character.build_id,
		"anchors": anchors.active_anchors(),
		"fold_lines": fold_lines.lines(),
		"instability": instability.snapshot(),
	}


func _reject_skill(
	definition: AbilityDefinition,
	reason: StringName,
	ability_runtime: Dictionary = {}
) -> Dictionary:
	var data := {
		"success": false,
		"reason": reason,
		"cast_id": &"",
		"ability_id": &"" if definition == null else definition.ability_id,
		"build_id": "" if runtime_character == null else runtime_character.build_id,
		"anchor": {},
		"removed_anchor_events": [],
		"instability_applied": 0.0,
		"entered_breach": false,
		"ability_runtime": ability_runtime.duplicate(true),
		"foundation_snapshot": snapshot(),
	}
	last_skill_commit = VoidbringerSkillCommit.new(data)
	skill_rejected.emit(last_skill_commit)
	return last_skill_commit.snapshot()


func _begin_transaction() -> void:
	_transaction_depth += 1


func _end_transaction(force_snapshot: bool) -> void:
	_transaction_depth = maxi(0, _transaction_depth - 1)
	if _transaction_depth > 0:
		return
	if force_snapshot or _snapshot_dirty:
		_snapshot_dirty = false
		_emit_snapshot()


func _request_snapshot() -> void:
	if _transaction_depth > 0:
		_snapshot_dirty = true
		return
	_emit_snapshot()


func _on_anchor_state_changed(_anchor: Dictionary) -> void:
	_rebuild_fold_lines()
	_request_snapshot()


func _on_anchor_removed(_anchor_id: StringName, _reason: StringName) -> void:
	_rebuild_fold_lines()
	_request_snapshot()


func _on_instability_changed(_current: float, _maximum: float) -> void:
	_request_snapshot()


func _on_breach_started(_duration_seconds: float) -> void:
	_request_snapshot()


func _on_breach_ended() -> void:
	_request_snapshot()


func _rebuild_fold_lines() -> void:
	fold_lines.rebuild(anchors.active_anchors())


func _emit_snapshot() -> void:
	foundation_changed.emit(snapshot())
