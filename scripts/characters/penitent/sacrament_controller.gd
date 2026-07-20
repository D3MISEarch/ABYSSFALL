extends Node
class_name SacramentController

const RULES = preload("res://scripts/characters/penitent/sacrament_rules.gd")
const VISUAL_SCRIPT = preload("res://scripts/characters/penitent/sacrament_visual.gd")

var caster: CharacterBody3D
var cooldown_remaining := 0.0


func bind_to(new_caster: CharacterBody3D) -> void:
	caster = new_caster
	process_priority = 95
	set_process(true)
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(caster) or not bool(caster.get("alive")) or get_tree().paused:
		return
	var requested_sacrament := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		requested_sacrament = (
			key_event.pressed
			and not key_event.echo
			and (key_event.physical_keycode == KEY_V or key_event.keycode == KEY_V)
		)
	elif event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		requested_sacrament = (
			button_event.pressed
			and button_event.button_index == JOY_BUTTON_DPAD_DOWN
		)
	if not requested_sacrament:
		return
	_cast_sacrament()
	get_viewport().set_input_as_handled()


func get_snapshot() -> Dictionary:
	return {
		"cooldown": cooldown_remaining,
		"cost": RULES.FERVOR_COST,
		"radius": RULES.CAST_RADIUS,
	}


func _cast_sacrament() -> void:
	if cooldown_remaining > 0.0:
		_emit_message("SACRAMENT REFORMS IN %.1f" % cooldown_remaining)
		return

	var sigils := _get_relevant_sigils()
	var targets := _collect_targets(sigils)
	if targets.is_empty() and sigils.is_empty():
		_emit_message("SACRAMENT FINDS NO RITE TO COMPLETE")
		return
	if not caster.has_method("quote_sacrament_cost") or not caster.has_method("commit_sacrament_cost"):
		_emit_message("SACRAMENT HAS NO PRICE BINDING")
		return

	var quote: Dictionary = caster.quote_sacrament_cost(RULES.FERVOR_COST)
	if not bool(quote.get("can_cast", false)):
		_emit_message("THE BODY CANNOT SURVIVE SACRAMENT")
		return
	var committed: Dictionary = caster.commit_sacrament_cost(RULES.FERVOR_COST)
	if not bool(committed.get("can_cast", false)):
		_emit_message("SACRAMENT PAYMENT FAILED")
		return

	var health_percent_paid := int(committed.get("health_percent", 0))
	var health_cost := int(committed.get("health_cost", 0))
	var fervor_spent := float(committed.get("fervor_spent", 0.0))
	var completed_rites := 0
	for target_data in targets:
		if int(target_data.get("mark_state", 0)) > 0:
			completed_rites += 1

	var visual := _spawn_visual(
		RULES.get_visual_intensity(health_percent_paid, completed_rites)
	)
	for sigil in sigils:
		if not is_instance_valid(sigil):
			continue
		if is_instance_valid(visual):
			visual.spawn_sigil_collapse(
				sigil.global_position,
				float(sigil.get("radius")) if sigil.get("radius") != null else 3.4
			)
		if sigil.has_method("dismiss"):
			sigil.dismiss("sacrament")

	var struck_count := 0
	var consumed_count := 0
	var forced_count := 0
	for target_data in targets:
		var enemy := target_data.get("enemy") as Node3D
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		if enemy.get("alive") != null and not bool(enemy.get("alive")):
			continue

		var mark_state := int(target_data.get("mark_state", 0))
		var branded := bool(target_data.get("branded", false))
		var inside_sigil := bool(target_data.get("inside_sigil", false))
		var boss_safe := bool(target_data.get("boss_safe", false))
		var mark := enemy.get_node_or_null("RiteMark")
		if RULES.should_force_complete(mark_state) and is_instance_valid(mark):
			if mark.has_method("complete_rite"):
				mark.complete_rite()
				forced_count += 1

		var damage := RULES.get_damage(
			mark_state,
			branded,
			inside_sigil,
			health_percent_paid,
			boss_safe
		)
		enemy.take_damage(damage)
		struck_count += 1
		if is_instance_valid(visual):
			visual.spawn_judgment(enemy.global_position, mark_state > 0, branded)

		if mark_state > 0 and is_instance_valid(mark) and mark.has_method("consume_rite"):
			if bool(mark.consume_rite()):
				consumed_count += 1
		elif mark_state <= 0 and inside_sigil:
			_apply_partial_mark(enemy)

	cooldown_remaining = RULES.COOLDOWN
	if caster.has_method("set_combat_active"):
		caster.set_combat_active(true)
	_emit_sacrament_result(
		struck_count,
		forced_count,
		consumed_count,
		fervor_spent,
		health_cost,
		health_percent_paid
	)


func _collect_targets(sigils: Array[Node]) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node3D
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		if enemy.get("alive") != null and not bool(enemy.get("alive")):
			continue

		var mark_state := 0
		var branded := false
		var boss_safe := false
		var mark := enemy.get_node_or_null("RiteMark")
		if is_instance_valid(mark) and mark.has_method("get_snapshot"):
			var snapshot: Dictionary = mark.get_snapshot()
			mark_state = int(snapshot.get("state", 0))
			branded = bool(snapshot.get("branded", false))
			boss_safe = bool(snapshot.get("boss_safe", false))

		var inside_sigil := _is_inside_any_sigil(enemy.global_position, sigils)
		var in_cast_radius := RULES.is_in_cast_radius(
			caster.global_position,
			enemy.global_position
		)
		if not (in_cast_radius or inside_sigil):
			continue
		if not RULES.is_eligible(mark_state, inside_sigil):
			continue
		targets.append(
			{
				"enemy": enemy,
				"mark_state": mark_state,
				"branded": branded,
				"inside_sigil": inside_sigil,
				"boss_safe": boss_safe,
			}
		)
	return targets


func _get_relevant_sigils() -> Array[Node]:
	var result: Array[Node] = []
	if not is_instance_valid(caster):
		return result
	var roster = caster.get("sigil_roster")
	if roster == null or not roster.has_method("get_active_sigils"):
		return result
	for candidate in roster.get_active_sigils():
		var sigil := candidate as Node3D
		if not is_instance_valid(sigil):
			continue
		var radius := float(sigil.get("radius")) if sigil.get("radius") != null else 3.4
		if RULES.is_in_cast_radius(
			caster.global_position,
			sigil.global_position,
			RULES.CAST_RADIUS + radius
		):
			result.append(sigil)
	return result


func _is_inside_any_sigil(position_value: Vector3, sigils: Array[Node]) -> bool:
	for candidate in sigils:
		var sigil := candidate as Node3D
		if not is_instance_valid(sigil):
			continue
		var radius := float(sigil.get("radius")) if sigil.get("radius") != null else 3.4
		var offset := position_value - sigil.global_position
		offset.y = 0.0
		if offset.length() <= radius:
			return true
	return false


func _apply_partial_mark(enemy: Node3D) -> void:
	if not is_instance_valid(caster) or not caster.has_method("get_or_create_rite_mark"):
		return
	if not is_instance_valid(enemy):
		return
	if enemy.get("alive") != null and not bool(enemy.get("alive")):
		return
	var mark = caster.get_or_create_rite_mark(enemy)
	if is_instance_valid(mark) and mark.has_method("apply_partial"):
		mark.apply_partial(1)


func _spawn_visual(visual_intensity: float) -> SacramentVisual:
	var scene_root := get_tree().current_scene
	if not is_instance_valid(scene_root):
		scene_root = caster.get_parent()
	if not is_instance_valid(scene_root):
		return null
	var visual := VISUAL_SCRIPT.new() as SacramentVisual
	visual.name = "SacramentVisual"
	visual.configure(visual_intensity)
	scene_root.add_child(visual)
	visual.global_position = caster.global_position
	visual.global_position.y = 0.07
	return visual


func _emit_sacrament_result(
	struck_count: int,
	forced_count: int,
	consumed_count: int,
	fervor_spent: float,
	health_cost: int,
	health_percent_paid: int
) -> void:
	var payment := "%d FERVOR" % int(round(fervor_spent))
	if health_cost > 0:
		payment += " + %d BLOOD (%d%%)" % [health_cost, health_percent_paid]
	_emit_message(
		"SACRAMENT — %d JUDGED, %d FORCED, %d RITES CONSUMED — %s"
		% [struck_count, forced_count, consumed_count, payment]
	)


func _emit_message(text: String) -> void:
	if is_instance_valid(caster) and caster.has_signal("ability_message"):
		caster.emit_signal("ability_message", text)
