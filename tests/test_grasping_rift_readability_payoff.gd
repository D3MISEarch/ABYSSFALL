extends SceneTree

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const RIFT_SCRIPT = preload("res://scripts/grasping_rift.gd")
const SKELETON_SCRIPT = preload("res://scripts/skeleton.gd")
const BONE_ARCHER_SCRIPT = preload("res://scripts/bone_archer.gd")
const CRYPT_BRUTE_SCRIPT = preload("res://scripts/crypt_brute.gd")

const RIFT_MARKER_ROOT := "RiftTargetPresentation"
const RIFT_CLEANUP_BOUND_SECONDS := 2.55

var failures: Array[String] = []


class TestGenerator extends Node3D:
	var health := 90
	var damage_events := 0


	func take_damage(amount: int) -> void:
		health -= amount
		damage_events += 1


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_ensure_player_input_actions()
	var previous_scene := current_scene
	var host := Node3D.new()
	host.name = "GraspingRiftReadabilityPayoffHost"
	root.add_child(host)
	current_scene = host
	await process_frame
	await _test_player_owned_rift_contract(host)
	await _test_rift_presentation_profiles_and_boundary(host)
	await _test_marker_lifecycle_and_overlap(host)
	await _test_large_delta_collapse_and_cleanup(host)
	_test_rift_scan_ownership_contract()
	_test_catacomb_grouping_payoff_contract()
	current_scene = previous_scene
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Grasping Rift readability and grouping payoff")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_player_owned_rift_contract(host: Node3D) -> void:
	var player: Variant = await _spawn_player(host, "RiftOwnerFixture", Vector3(20.0, 0.0, 20.0))
	_pin_baseline_rift_inputs(player)
	_expect(
		is_equal_approx(player.rift_cost, 40.0) and is_equal_approx(player.rift_cooldown_duration, 4.5),
		"Player-owned Rift cost and cooldown must remain pinned."
	)
	_expect(
		is_equal_approx(player.rift_radius, 6.0)
			and is_equal_approx(player.rift_duration, 2.2)
			and is_equal_approx(player.rift_pull_strength, 7.4)
			and player.rift_damage == 30,
		"Neutral skill and equipment inputs must derive the exact baseline Rift values."
	)
	_expect(not player.dual_rift and _rift_equipment_is_neutral(player), "Baseline fixture must neutralize every Rift contributor.")

	player.skill_rift_radius_bonus = 1.1
	player.equipment["Relic"] = {"stats": {"rift_radius": 0.4}}
	player._recalculate_stats(false)
	_expect(is_equal_approx(player.rift_radius, 7.5), "Player must apply skill radius before equipment radius contribution.")
	_pin_baseline_rift_inputs(player)
	player.skill_rift_duration_bonus = 0.65
	player._recalculate_stats(false)
	_expect(is_equal_approx(player.rift_duration, 2.85), "Player must own Rift duration derivation.")
	_pin_baseline_rift_inputs(player)
	player.skill_rift_pull_multiplier = 1.22
	player._recalculate_stats(false)
	_expect(is_equal_approx(player.rift_pull_strength, 9.028), "Player must own Rift pull multiplier derivation.")
	_pin_baseline_rift_inputs(player)
	player.skill_rift_damage_bonus = 14
	player.equipment["Relic"] = {"stats": {"rift_damage": 5}}
	player._recalculate_stats(false)
	_expect(player.rift_damage == 49, "Player must apply skill damage before equipment damage contribution.")
	_pin_baseline_rift_inputs(player)

	player.facing = Vector3.FORWARD
	player.corruption = 100.0
	var corruption_before: float = player.corruption
	player._try_cast_grasping_rift()
	await process_frame
	var single_rifts := _find_rifts(host)
	_expect(single_rifts.size() == 1, "Single-Rift cast must create exactly one Rift through the player path.")
	_expect(is_equal_approx(player.corruption, corruption_before - 40.0), "Single-Rift cast must spend Corruption exactly once.")
	_expect(is_equal_approx(player.rift_cooldown, 4.5), "Single-Rift cast must start the player-owned cooldown exactly once.")
	if single_rifts.size() == 1:
		var single_rift = single_rifts[0]
		_expect(
			_vector_equal(single_rift.global_position, Vector3(20.0, 0.08, 14.0)),
			"Default player targeting must place the Rift six metres forward at Y 0.08."
		)
		_expect(
			is_equal_approx(single_rift.pull_radius, 6.0)
				and is_equal_approx(single_rift.pull_duration, 2.2)
				and is_equal_approx(single_rift.pull_strength, 7.4)
				and single_rift.collapse_damage == 30,
			"Rift setup must receive player-derived baseline values without presentation formulas."
		)
	await _remove_rifts(host)

	player.rift_cooldown = 0.0
	player.corruption = 100.0
	player.dual_rift = true
	corruption_before = player.corruption
	player._try_cast_grasping_rift()
	await process_frame
	var dual_rifts := _find_rifts(host)
	_expect(dual_rifts.size() == 2, "Dual-Rift state must create exactly two player-owned Rifts.")
	_expect(is_equal_approx(player.corruption, corruption_before - 40.0), "Dual-Rift cast must still spend once.")
	_expect(is_equal_approx(player.rift_cooldown, 4.5), "Dual-Rift cast must still start one cooldown.")
	var expected_dual_damage: int = player._resolve_outgoing_damage(int(round(float(player.rift_damage) * 0.78)))
	for dual_rift in dual_rifts:
		_expect(
			is_equal_approx(dual_rift.pull_radius, 4.92)
				and dual_rift.collapse_damage == expected_dual_damage,
			"Dual Rift must preserve player-owned size and rounded outgoing-damage resolution."
		)
	_expect(
		_dual_rifts_have_offsets(dual_rifts, Vector3(20.0, 0.08, 14.0)),
		"Dual Rift placement must keep the authoritative +/-1.9 perpendicular offsets."
	)
	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	_expect(
		player_source.contains("facing * 6.0")
			and player_source.contains("offset.length() > 8.5")
			and player_source.contains("offset.length() < 2.0")
			and player_source.contains("target_position.y = 0.08"),
		"Player targeting must retain default, maximum, minimum, and flattened-Y placement rules."
	)
	_expect(
		_count_text(player_source, "spend_corruption(rift_cost)") == 1
			and _count_text(player_source, "rift_cooldown = rift_cooldown_duration") == 1
			and player_source.contains("_resolve_outgoing_damage(int(round(float(rift_damage) * damage_multiplier)))"),
		"Player must remain the single owner of Rift cost, cooldown, and outgoing-damage resolution."
	)
	await _remove_rifts(host)
	player.queue_free()
	await process_frame


func _test_rift_presentation_profiles_and_boundary(host: Node3D) -> void:
	var world := Node3D.new()
	world.name = "RiftPresentationWorld"
	host.add_child(world)
	var light: Variant = await _spawn_enemy(world, SKELETON_SCRIPT, "LightRiftTarget", Vector3(2.0, 0.0, 0.0))
	var archer: Variant = await _spawn_enemy(world, BONE_ARCHER_SCRIPT, "ArcherRiftTarget", Vector3(3.2, 0.0, 0.0))
	var brute: Variant = await _spawn_enemy(world, CRYPT_BRUTE_SCRIPT, "BruteRiftTarget", Vector3(4.4, 0.0, 0.0))
	var high_target: Variant = await _spawn_enemy(world, SKELETON_SCRIPT, "HighYRiftTarget", Vector3(6.0, 8.0, 0.0))
	var outside_target: Variant = await _spawn_enemy(world, SKELETON_SCRIPT, "OutsideRiftTarget", Vector3(6.01, 0.0, 0.0))
	var snapshots := {
		light.get_instance_id(): _enemy_snapshot(light),
		archer.get_instance_id(): _enemy_snapshot(archer),
		brute.get_instance_id(): _enemy_snapshot(brute),
		high_target.get_instance_id(): _enemy_snapshot(high_target),
		outside_target.get_instance_id(): _enemy_snapshot(outside_target)
	}
	var archer_timer_before: float = archer.attack_timer
	var rift: Variant = await _spawn_rift(host, Vector3.ZERO)
	_expect(rift.presentation_phase == &"setup", "Rift presentation must start in setup/arming state.")
	rift._physics_process(0.10)
	_expect(rift.pull_scan_count == 1, "One active Rift update must use one existing enemy-group pull scan.")
	_expect(rift.presentation_phase == &"setup", "Rift stays in setup/arming during the existing setup interval.")
	_expect(rift.affected_targets.size() == 4, "Flattened-Y boundary target must be marked while horizontal out-of-range target is excluded.")
	_expect(is_equal_approx(archer.attack_timer, archer_timer_before), "Rift presentation must not alter Bone Archer attack timing.")
	_expect(
		_entry_profile(rift, light) == &"light_streak"
			and _entry_profile(rift, archer) == &"archer_tether"
			and _entry_profile(rift, brute) == &"brute_restraint",
		"Light, ranged, and heavy enemies must use distinct Rift-only presentation profiles."
	)
	_expect(
		_marker_has_child(rift, light, "RiftLightInwardStreak")
			and _marker_has_child(rift, archer, "RiftArcherTether")
			and _marker_has_child(rift, brute, "RiftBruteRestraint"),
		"Profile differences must be visible through Rift-owned decorative geometry."
	)
	_expect(
		_count_collision_objects(rift.target_presentation_root) == 0
			and _count_collision_shapes(rift.target_presentation_root) == 0,
		"Rift target presentation must add no collision objects or shapes."
	)
	_expect(
		_marker_is_rift_owned(rift, light)
			and _marker_is_rift_owned(rift, archer)
			and _marker_is_rift_owned(rift, brute),
		"Target markers must stay under the Rift-owned world-space root, never enemy visual roots."
	)
	_expect(_enemy_snapshot(light) == snapshots[light.get_instance_id()], "Light target presentation must not alter body, collision, health, or visual transform.")
	_expect(_enemy_snapshot(archer) == snapshots[archer.get_instance_id()], "Archer target presentation must not alter body, collision, health, or visual transform.")
	_expect(_enemy_snapshot(brute) == snapshots[brute.get_instance_id()], "Brute target presentation must not alter body, collision, health, or visual transform.")
	_expect(_enemy_snapshot(high_target) == snapshots[high_target.get_instance_id()], "Flattened-Y target presentation must remain decorative only.")
	_expect(_enemy_snapshot(outside_target) == snapshots[outside_target.get_instance_id()], "Out-of-range target must remain untouched.")

	rift._physics_process(0.20)
	_expect(rift.presentation_phase == &"active_pull", "Rift presentation must enter active pull from existing elapsed time.")
	rift._physics_process(1.60)
	_expect(rift.presentation_phase == &"imminent_collapse", "Rift presentation must enter imminent collapse before the existing pull ends.")
	_expect(rift.pull_scan_count == 3, "Presentation must continue to reuse exactly one pull scan per active Rift update.")
	await _remove_rifts(host)
	world.queue_free()
	await process_frame


func _test_marker_lifecycle_and_overlap(host: Node3D) -> void:
	var world := Node3D.new()
	world.name = "RiftMarkerLifecycleWorld"
	host.add_child(world)
	var target: Variant = await _spawn_enemy(world, SKELETON_SCRIPT, "OverlapRiftTarget", Vector3(2.0, 0.0, 0.0))
	var first_rift: Variant = await _spawn_rift(host, Vector3.ZERO)
	var second_rift: Variant = await _spawn_rift(host, Vector3(4.0, 0.0, 0.0))
	first_rift._physics_process(0.10)
	second_rift._physics_process(0.10)
	_expect(first_rift.affected_targets.size() == 1 and second_rift.affected_targets.size() == 1, "Overlapping Rifts must retain independent local target entries.")
	first_rift._collapse()
	_expect(first_rift.affected_targets.is_empty(), "Collapsed Rift must synchronously clear its own target markers.")
	_expect(second_rift.affected_targets.size() == 1, "One Rift cleanup must not remove the overlapping Rift marker.")

	target.global_position = Vector3(10.1, 0.0, 0.0)
	second_rift._pull_targets(0.0)
	_expect(second_rift.affected_targets.is_empty(), "Target leaving the horizontal radius must remove the owning marker in the reused pull scan.")
	target.global_position = Vector3(3.0, 0.0, 0.0)
	second_rift._pull_targets(0.0)
	_expect(second_rift.affected_targets.size() == 1, "A valid re-entry must create a clean replacement marker.")
	target.take_damage(int(target.health))
	second_rift._pull_targets(0.0)
	_expect(second_rift.affected_targets.is_empty(), "Authoritative alive/death state must remove markers before death tweens finish.")

	var invalid_target: Variant = await _spawn_enemy(world, SKELETON_SCRIPT, "InvalidRiftTarget", Vector3(3.5, 0.0, 0.0))
	var third_rift: Variant = await _spawn_rift(host, Vector3.ZERO)
	third_rift._physics_process(0.10)
	_expect(third_rift.affected_targets.size() == 1, "Valid target must create a marker before invalidation.")
	invalid_target.queue_free()
	await process_frame
	third_rift._validate_target_presentations(0.0)
	_expect(third_rift.affected_targets.is_empty(), "Invalid target references must be removed by the bounded local validation path.")
	third_rift.queue_free()
	await process_frame
	_expect(_count_nodes_named(host, RIFT_MARKER_ROOT) == 2, "Removing one Rift must not clear other live Rift roots.")
	await _remove_rifts(host)
	_expect(_count_nodes_named(host, RIFT_MARKER_ROOT) == 0, "Rift teardown must leave no stale presentation roots.")
	world.queue_free()
	await process_frame


func _test_large_delta_collapse_and_cleanup(host: Node3D) -> void:
	var world := Node3D.new()
	world.name = "RiftLargeDeltaWorld"
	host.add_child(world)
	var target: Variant = await _spawn_enemy(world, SKELETON_SCRIPT, "LargeDeltaRiftTarget", Vector3(2.0, 0.0, 0.0))
	var generator := TestGenerator.new()
	generator.name = "LargeDeltaGenerator"
	generator.position = Vector3(3.0, 0.0, 0.0)
	world.add_child(generator)
	generator.add_to_group("generators")
	var rift: Variant = await _spawn_rift(host, Vector3.ZERO)
	var target_health_before: int = target.health
	rift._physics_process(RIFT_CLEANUP_BOUND_SECONDS + 0.10)
	_expect(rift.collapsed, "Large delta crossing the pull duration must collapse the Rift once.")
	_expect(rift.presentation_phase == &"cleanup", "Large delta crossing cleanup must enter presentation cleanup immediately.")
	_expect(target.health == target_health_before - 30, "Large-delta collapse must apply enemy damage once.")
	_expect(generator.health == 72 and generator.damage_events == 1, "Large-delta collapse must apply pinned generator damage once.")
	var collapsed_target_health: int = target.health
	rift._physics_process(0.10)
	_expect(target.health == collapsed_target_health and generator.damage_events == 1, "Collapsed Rift must never repeat damage after a large delta.")
	_expect(rift.affected_targets.is_empty(), "Large-delta cleanup must synchronously clear local marker references.")
	await process_frame
	_expect(not is_instance_valid(rift), "Rift must be freed after its existing duration plus cleanup delay.")
	world.queue_free()
	await process_frame


func _test_rift_scan_ownership_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/grasping_rift.gd")
	var pull_section := _function_section(source, "func _pull_targets", "func _collapse")
	var validation_section := _function_section(source, "func _validate_target_presentations", "func _clear_target_presentations")
	_expect(
		_count_text(pull_section, "get_nodes_in_group(\"enemies\")") == 1
			and pull_section.contains("_update_target_presentation")
			and validation_section.find("get_nodes_in_group") == -1,
		"Rift target presentation must reuse the existing pull scan and use only O(k) local validation after pull."
	)
	_expect(
		source.contains("offset.y = 0.0")
			and source.contains("enemy.apply_rift_pull(global_position, pull_strength * strength_scale)")
			and source.contains("enemy.take_damage(collapse_damage)")
			and source.contains("generator.take_damage(18)"),
		"Rift must preserve flattened-Y pull, collapse, and generator-damage gameplay contracts."
	)


func _test_catacomb_grouping_payoff_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var wave_section := _function_section(source, "func _spawn_catacomb_second_wave", "func _start_trap_hall")
	for expected_call in [
		"_spawn_enemy(\"brute\", Vector3(0.0, 0.0, -47.0), 0.15, true)",
		"_spawn_enemy(\"archer\", Vector3(-6.0, 0.0, -47.0))",
		"_spawn_enemy(\"archer\", Vector3(6.0, 0.0, -47.0))",
		"for x in [-4.0, 0.0, 4.0]:",
		"_spawn_enemy(\"reaver\", Vector3(x, 0.0, -43.0), 0.28)"
	]:
		_expect(wave_section.contains(expected_call), "Catacombs second wave must retain approved grouping call: %s" % expected_call)
	_expect(
		wave_section.contains("game_state = \"catacombs_wave_2\"")
			and wave_section.contains("catacomb_wave = 2")
			and wave_section.contains("_show_message(\"THE OSSUARY OPENS\", 1.15)"),
		"Catacombs second wave must preserve sequence, reward-driving state, and non-position encounter behavior."
	)


func _spawn_player(host: Node3D, player_name: String, position_value: Vector3):
	var player := PLAYER_SCRIPT.new()
	player.name = player_name
	player.position = position_value
	player.set_physics_process(false)
	host.add_child(player)
	player.set_physics_process(false)
	await process_frame
	return player


func _spawn_enemy(host: Node3D, enemy_script: Script, enemy_name: String, position_value: Vector3):
	var enemy := enemy_script.new() as Node3D
	enemy.name = enemy_name
	enemy.position = position_value
	host.add_child(enemy)
	enemy.set_physics_process(false)
	await process_frame
	_expect(enemy.is_in_group("enemies"), "%s fixture must join the enemies group." % enemy_name)
	return enemy


func _spawn_rift(host: Node3D, position_value: Vector3):
	var rift := RIFT_SCRIPT.new()
	rift.setup(host)
	rift.position = position_value
	host.add_child(rift)
	rift.set_physics_process(false)
	await process_frame
	return rift


func _pin_baseline_rift_inputs(player) -> void:
	player.skill_rift_radius_bonus = 0.0
	player.skill_rift_duration_bonus = 0.0
	player.skill_rift_pull_multiplier = 1.0
	player.skill_rift_damage_bonus = 0
	player.dual_rift = false
	for slot in player.EQUIPMENT_SLOTS:
		player.equipment[slot] = {}
	player._recalculate_stats(false)


func _rift_equipment_is_neutral(player) -> bool:
	for slot in player.EQUIPMENT_SLOTS:
		var item: Dictionary = player.equipment[slot]
		if not item.is_empty():
			var stats: Dictionary = item.get("stats", {})
			if not is_equal_approx(float(stats.get("rift_radius", 0.0)), 0.0) or int(stats.get("rift_damage", 0)) != 0:
				return false
	return true


func _find_rifts(host: Node3D) -> Array:
	var rifts: Array = []
	for child in host.get_children():
		if child.get_script() == RIFT_SCRIPT:
			rifts.append(child)
	return rifts


func _remove_rifts(host: Node3D) -> void:
	for rift in _find_rifts(host):
		rift.queue_free()
	await process_frame


func _dual_rifts_have_offsets(rifts: Array, center: Vector3) -> bool:
	if rifts.size() != 2:
		return false
	var offsets: Array[float] = []
	for rift in rifts:
		if not is_equal_approx(rift.global_position.z, center.z) or not is_equal_approx(rift.global_position.y, center.y):
			return false
		offsets.append(rift.global_position.x - center.x)
	offsets.sort()
	return is_equal_approx(offsets[0], -1.9) and is_equal_approx(offsets[1], 1.9)


func _entry_profile(rift, target: Node3D) -> StringName:
	var entry: Dictionary = rift.affected_targets.get(target.get_instance_id(), {})
	return entry.get("profile", &"")


func _marker_has_child(rift, target: Node3D, child_name: String) -> bool:
	var entry: Dictionary = rift.affected_targets.get(target.get_instance_id(), {})
	var marker: Node3D = entry.get("marker") as Node3D
	return is_instance_valid(marker) and marker.get_node_or_null(child_name) != null


func _marker_is_rift_owned(rift, target: Node3D) -> bool:
	var entry: Dictionary = rift.affected_targets.get(target.get_instance_id(), {})
	var marker: Node3D = entry.get("marker") as Node3D
	var target_visual: Node3D = target.get("visual_root")
	return is_instance_valid(marker) and marker.get_parent() == rift.target_presentation_root and marker.get_parent() != target_visual


func _enemy_snapshot(enemy) -> Dictionary:
	var visual_root: Node3D = enemy.get("visual_root")
	return {
		"position": enemy.global_position,
		"health": enemy.health,
		"collision": _collision_snapshot(enemy),
		"visual_position": visual_root.position,
		"visual_scale": visual_root.scale,
		"visual_rotation": visual_root.rotation_degrees
	}


func _collision_snapshot(node: CollisionObject3D) -> Dictionary:
	var shapes: Array[Dictionary] = []
	_collect_collision_shapes(node, shapes)
	return {"layer": node.collision_layer, "mask": node.collision_mask, "shapes": shapes}


func _collect_collision_shapes(node: Node, shapes: Array[Dictionary]) -> void:
	for child: Node in node.get_children():
		if child is CollisionShape3D:
			shapes.append({"shape": str(child.shape), "disabled": child.disabled})
		_collect_collision_shapes(child, shapes)


func _count_collision_objects(root_node: Node) -> int:
	var count := 0
	for child: Node in root_node.get_children():
		if child is CollisionObject3D:
			count += 1
		count += _count_collision_objects(child)
	return count


func _count_collision_shapes(root_node: Node) -> int:
	var count := 0
	for child: Node in root_node.get_children():
		if child is CollisionShape3D:
			count += 1
		count += _count_collision_shapes(child)
	return count


func _count_nodes_named(root_node: Node, node_name: String) -> int:
	var count := 1 if root_node.name == node_name else 0
	for child: Node in root_node.get_children():
		count += _count_nodes_named(child, node_name)
	return count


func _function_section(source: String, start_marker: String, end_marker: String) -> String:
	var start := source.find(start_marker)
	if start == -1:
		return ""
	var end := source.find(end_marker, start + start_marker.length())
	return source.substr(start) if end == -1 else source.substr(start, end - start)


func _count_text(source: String, needle: String) -> int:
	var count := 0
	var search_from := 0
	while true:
		var found := source.find(needle, search_from)
		if found == -1:
			return count
		count += 1
		search_from = found + needle.length()
	return count


func _ensure_player_input_actions() -> void:
	for action_name in [
		"move_left",
		"move_right",
		"move_forward",
		"move_back",
		"aim_left",
		"aim_right",
		"aim_up",
		"aim_down",
		"dodge",
		"attack",
		"rift"
	]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)


func _vector_equal(left: Vector3, right: Vector3) -> bool:
	return is_equal_approx(left.x, right.x) and is_equal_approx(left.y, right.y) and is_equal_approx(left.z, right.z)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
