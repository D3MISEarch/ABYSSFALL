extends Node
class_name AshenProcessionController

const RULES = preload("res://scripts/characters/penitent/ashen_procession_rules.gd")
const TRAIL_SCRIPT = preload("res://scripts/characters/penitent/ashen_procession_trail.gd")

var caster: CharacterBody3D
var was_dodging := false
var last_caster_position := Vector3.ZERO
var dodge_start_position := Vector3.ZERO
var active_trail: AshenProcessionTrail


func bind_to(new_caster: CharacterBody3D) -> void:
	caster = new_caster
	process_priority = 70
	last_caster_position = caster.global_position
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(caster):
		_cleanup_trail("caster_missing")
		return
	if caster.get("alive") != null and not bool(caster.get("alive")):
		_cleanup_trail("caster_fallen")
		return

	var is_dodging := float(caster.get("dodge_time")) > 0.0
	if is_dodging and not was_dodging:
		dodge_start_position = last_caster_position
	elif not is_dodging and was_dodging:
		_create_trail(dodge_start_position, caster.global_position)

	last_caster_position = caster.global_position
	was_dodging = is_dodging


func get_snapshot() -> Dictionary:
	return {
		"was_dodging": was_dodging,
		"has_active_trail": is_instance_valid(active_trail) and active_trail.active,
		"trail": active_trail.get_snapshot() if is_instance_valid(active_trail) else {},
	}


func _create_trail(start: Vector3, finish: Vector3) -> void:
	if not RULES.is_valid_trail(start, finish):
		return
	if is_instance_valid(active_trail):
		active_trail.dismiss("replaced")

	var trail := TRAIL_SCRIPT.new() as AshenProcessionTrail
	trail.name = "AshenProcessionTrail"
	trail.configure(caster, start, finish, RULES.TRAIL_LIFETIME)
	trail.completed.connect(_on_trail_completed)
	trail.dismissed.connect(_on_trail_dismissed)

	var scene_root := get_tree().current_scene
	if not is_instance_valid(scene_root):
		scene_root = caster.get_parent()
	if not is_instance_valid(scene_root):
		trail.free()
		return
	scene_root.add_child(trail)
	var midpoint := (start + finish) * 0.5
	midpoint.y = 0.07
	trail.global_position = midpoint
	active_trail = trail
	if caster.has_method("set_combat_active"):
		caster.set_combat_active(true)
	_emit_message("ASHEN PROCESSION — CROSS THE SCRIPTURE TO COMPLETE IT")


func _on_trail_completed(trail: Node) -> void:
	var rite_line := trail as AshenProcessionTrail
	if not is_instance_valid(rite_line):
		return
	if active_trail == rite_line:
		active_trail = null

	var hit_count := 0
	var complete_rite_count := 0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node3D
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		if enemy.get("alive") != null and not bool(enemy.get("alive")):
			continue
		if not RULES.is_enemy_on_rite_line(
			enemy.global_position,
			rite_line.start_position,
			rite_line.finish_position
		):
			continue

		var mark_state := _get_mark_state(enemy)
		var complete_rite := mark_state >= 3
		enemy.take_damage(RULES.get_impact_damage(mark_state))
		hit_count += 1
		if complete_rite:
			complete_rite_count += 1
		rite_line.spawn_impact(enemy.global_position, complete_rite)

		if not complete_rite and is_instance_valid(enemy):
			if enemy.get("alive") == null or bool(enemy.get("alive")):
				_apply_procession_mark(enemy)

	var reward := RULES.get_fervor_reward(hit_count, complete_rite_count)
	if reward > 0.0 and is_instance_valid(caster) and caster.has_method("add_fervor"):
		caster.add_fervor(reward)
	if is_instance_valid(caster) and caster.has_method("set_combat_active"):
		caster.set_combat_active(true)

	if hit_count <= 0:
		_emit_message("ASHEN PROCESSION CLOSES ON EMPTY GROUND")
	elif complete_rite_count > 0:
		_emit_message(
			"ASHEN PROCESSION JUDGES %d VESSELS — %d COMPLETE RITES"
			% [hit_count, complete_rite_count]
		)
	else:
		_emit_message("ASHEN PROCESSION CARVES %d VESSELS" % hit_count)


func _on_trail_dismissed(trail: Node, _reason: String) -> void:
	if active_trail == trail:
		active_trail = null


func _get_mark_state(enemy: Node3D) -> int:
	var mark := enemy.get_node_or_null("RiteMark")
	if not is_instance_valid(mark) or not mark.has_method("get_snapshot"):
		return 0
	var snapshot: Dictionary = mark.get_snapshot()
	return int(snapshot.get("state", 0))


func _apply_procession_mark(enemy: Node3D) -> void:
	if not is_instance_valid(caster) or not caster.has_method("get_or_create_rite_mark"):
		return
	var mark = caster.get_or_create_rite_mark(enemy)
	if is_instance_valid(mark) and mark.has_method("apply_partial"):
		mark.apply_partial(1)


func _emit_message(text: String) -> void:
	if is_instance_valid(caster) and caster.has_signal("ability_message"):
		caster.emit_signal("ability_message", text)


func _cleanup_trail(reason: String) -> void:
	if is_instance_valid(active_trail):
		active_trail.dismiss(reason)
	active_trail = null


func _exit_tree() -> void:
	_cleanup_trail("controller_removed")
