class_name VoidbringerController
extends RefCounted

signal foundation_changed(snapshot: Dictionary)

var anchors := VoidbringerAnchorManager.new()
var fold_lines := VoidbringerFoldLineManager.new()
var instability := VoidbringerInstabilityController.new()
var runtime_session: RuntimeSession
var runtime_character: RuntimeCharacter


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
	_emit_snapshot()


func snapshot() -> Dictionary:
	return {
		"runtime_bound": is_runtime_bound(),
		"build_id": "" if runtime_character == null else runtime_character.build_id,
		"anchors": anchors.active_anchors(),
		"fold_lines": fold_lines.lines(),
		"instability": instability.snapshot(),
	}


func _on_anchor_state_changed(_anchor: Dictionary) -> void:
	_rebuild_fold_lines()
	_emit_snapshot()


func _on_anchor_removed(_anchor_id: StringName, _reason: StringName) -> void:
	_rebuild_fold_lines()
	_emit_snapshot()


func _on_instability_changed(_current: float, _maximum: float) -> void:
	_emit_snapshot()


func _on_breach_started(_duration_seconds: float) -> void:
	_emit_snapshot()


func _on_breach_ended() -> void:
	_emit_snapshot()


func _rebuild_fold_lines() -> void:
	fold_lines.rebuild(anchors.active_anchors())


func _emit_snapshot() -> void:
	foundation_changed.emit(snapshot())
