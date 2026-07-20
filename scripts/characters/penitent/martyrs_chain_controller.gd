extends Node
class_name MartyrsChainController

const RULES = preload("res://scripts/characters/penitent/martyrs_chain_rules.gd")
const VISUAL_SCRIPT = preload("res://scripts/characters/penitent/martyrs_chain_visual.gd")
const RITUAL_CONTROL_SCRIPT = preload("res://scripts/characters/penitent/ritual_control_component.gd")

const FERVOR_COST := 14.0
const COOLDOWN := 4.2

var caster: CharacterBody3D
var cooldown_remaining := 0.0
var pull_active := false
var pull_mode := ""
var pull_target: Node3D
var pull_start := Vector3.ZERO
var pull_destination := Vector3.ZERO
var pull_duration := 0.30
var pull_elapsed := 0.0
var target_kind := RULES.TARGET_STANDARD
var target_had_complete_rite := false
var target_control: RitualControlComponent
var chain_visual: MartyrsChainVisual
var caster_physics_was_active := true


func bind_to(new_caster: CharacterBody3D) -> void:
	caster = new_caster
	process_priority = 90
	set_process_unhandled_input(true)
	set_physics_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(caster) or not bool(caster.get("alive")) or get_tree().paused:
		return
	var requested_chain := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		requested_chain = (
			key_event.pressed
			and not key_event.echo
			and (key_event.physical_keycode == KEY_C or key_event.keycode == KEY_C)
		)
	elif event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		requested_chain = button_event.pressed and button_event.button_index == JOY_BUTTON_LEFT_STICK
	if not requested_chain:
		return
	_cast_chain()
	get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)
	if not pull_active:
		return
	if not is_instance_valid(caster) or not is_instance_valid(pull_target):
		_finish_pull(false)
		return

	pull_elapsed = minf(pull_elapsed + delta, pull_duration)
	var ratio := clampf(pull_elapsed / maxf(pull_duration, 0.001), 0.0, 1.0)
	var eased := ratio * ratio * (3.0 - 2.0 * ratio)
	var moving_body: Node3D = pull_target if pull_mode == RULES.MODE_PULL_TARGET else caster
	moving_body.global_position = pull_start.lerp(pull_destination, eased)
	if ratio >= 1.0:
		_finish_pull(true)


func get_snapshot() -> Dictionary:
	return {
		"cooldown": cooldown_remaining,
		"pull_active": pull_active,
		"mode": pull_mode,
		"target_kind": target_kind,
		"complete_rite": target_had_complete_rite,
	}


func _cast_chain() -> void:
	if pull_active:
		_emit_message("MARTYR'S CHAIN IS ALREADY DRAWN")
		return
	if cooldown_remaining > 0.0:
		_emit_message("MARTYR'S CHAIN REFORMS IN %.1f" % cooldown_remaining)
		return
	var target := _select_target()
	if not is_instance_valid(target):
		_emit_message("MARTYR'S CHAIN FINDS NO ANCHOR")
		return
	if not caster.has_method("spend_fervor") or not bool(caster.spend_fervor(FERVOR_COST)):
		_emit_message("MARTYR'S CHAIN REQUIRES %d FERVOR" % int(FERVOR_COST))
		return

	pull_target = target
	target_kind = _resolve_target_kind(target)
	pull_mode = RULES.resolve_mode(target_kind)
	target_had_complete_rite = _has_complete_rite(target)
	pull_duration = RULES.get_pull_duration(target_kind)
	pull_elapsed = 0.0
	pull_active = true
	cooldown_remaining = COOLDOWN

	if pull_mode == RULES.MODE_PULL_TARGET:
		pull_start = target.global_position
		pull_destination = RULES.calculate_destination(caster.global_position, target.global_position, pull_mode)
		target_control = _get_or_create_control(target)
		if is_instance_valid(target_control):
			target_control.apply_source(get_instance_id(), 0.0, pull_duration + 0.18, pull_duration + 0.10)
	else:
		pull_start = caster.global_position
		pull_destination = RULES.calculate_destination(caster.global_position, target.global_position, pull_mode)
		caster_physics_was_active = caster.is_physics_processing()
		caster.set_physics_process(false)
		caster.velocity = Vector3.ZERO
		if caster.get("invulnerability_time") != null:
			caster.set(
				"invulnerability_time",
				maxf(float(caster.get("invulnerability_time")), pull_duration + 0.16)
			)

	_spawn_visual(target)
	if caster.has_method("set_combat_active"):
		caster.set_combat_active(true)
	_emit_message(
		"MARTYR'S CHAIN — THE VESSEL IS DRAGGED"
		if pull_mode == RULES.MODE_PULL_TARGET
		else "MARTYR'S CHAIN — THE PENITENT ANSWERS"
	)


func _select_target() -> Node3D:
	var best_target: Node3D
	var best_score := -1.0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node3D
		if not is_instance_valid(enemy):
			continue
		if enemy.get("alive") != null and not bool(enemy.get("alive")):
			continue
		var mark_state := _get_mark_state(enemy)
		var score: float = RULES.score_target(
			caster.global_position,
			Vector3(caster.get("facing")),
			enemy.global_position,
			mark_state > 0
		)
		if score > best_score:
			best_score = score
			best_target = enemy
	return best_target


func _finish_pull(apply_impact: bool) -> void:
	if not pull_active:
		return
	if apply_impact and is_instance_valid(pull_target) and pull_target.has_method("take_damage"):
		var damage := RULES.get_impact_damage(target_kind, target_had_complete_rite)
		pull_target.take_damage(damage)
		if target_had_complete_rite and is_instance_valid(caster) and caster.has_method("add_fervor"):
			caster.add_fervor(3.0)
			_emit_message("THE COMPLETED RITE TIGHTENS THE CHAIN")

	if is_instance_valid(target_control):
		target_control.remove_source(get_instance_id())
	target_control = null
	if pull_mode == RULES.MODE_PULL_CASTER and is_instance_valid(caster) and caster_physics_was_active:
		caster.set_physics_process(true)
	if is_instance_valid(chain_visual):
		chain_visual.dismiss()
	chain_visual = null
	pull_active = false
	pull_target = null
	pull_mode = ""


func _get_or_create_control(enemy: Node3D) -> RitualControlComponent:
	var existing := enemy.get_node_or_null("RitualControl") as RitualControlComponent
	if is_instance_valid(existing):
		return existing
	var control := RITUAL_CONTROL_SCRIPT.new() as RitualControlComponent
	control.name = "RitualControl"
	enemy.add_child(control)
	control.bind_to(enemy)
	return control


func _resolve_target_kind(enemy: Node3D) -> String:
	if enemy.is_in_group("bosses") or enemy.has_signal("phase_changed"):
		return RULES.TARGET_BOSS
	var script := enemy.get_script() as Script
	var script_path := script.resource_path if is_instance_valid(script) else ""
	if script_path.ends_with("crypt_brute.gd") or enemy.name.to_lower().contains("brute"):
		return RULES.TARGET_BRUTE
	return RULES.TARGET_STANDARD


func _get_mark_state(enemy: Node3D) -> int:
	var mark := enemy.get_node_or_null("RiteMark")
	if not is_instance_valid(mark) or not mark.has_method("get_snapshot"):
		return 0
	var snapshot: Dictionary = mark.get_snapshot()
	return int(snapshot.get("state", 0))


func _has_complete_rite(enemy: Node3D) -> bool:
	return _get_mark_state(enemy) >= 3


func _spawn_visual(target: Node3D) -> void:
	var scene_root := get_tree().current_scene
	if not is_instance_valid(scene_root):
		scene_root = caster.get_parent()
	chain_visual = VISUAL_SCRIPT.new() as MartyrsChainVisual
	chain_visual.name = "MartyrsChainVisual"
	scene_root.add_child(chain_visual)
	chain_visual.bind(caster, target, target_had_complete_rite)


func _emit_message(text: String) -> void:
	if is_instance_valid(caster) and caster.has_signal("ability_message"):
		caster.emit_signal("ability_message", text)


func _exit_tree() -> void:
	if pull_active:
		_finish_pull(false)
