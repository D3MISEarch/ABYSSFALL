extends SceneTree

const HOLLOW_KING_SCRIPT = preload("res://scripts/hollow_king.gd")
const ENEMY_BOLT_SCRIPT = preload("res://scripts/enemy_bolt.gd")

var failures: Array[String] = []


class NovaTarget extends Node3D:
	var health := 250
	var damage_events := 0


	func take_damage(amount: int) -> void:
		health -= amount
		damage_events += 1


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var previous_scene := current_scene
	var host := Node3D.new()
	host.name = "HollowKingNovaPresentationTestHost"
	root.add_child(host)
	current_scene = host
	await process_frame
	await _test_frozen_nova_values_and_mode_equivalence(host)
	await _test_intent_release_and_bounds(host)
	await _test_cancellation_and_teardown(host)
	_test_authority_and_presentation_boundaries()
	current_scene = previous_scene
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Hollow King readable Nova intent and payoff")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_frozen_nova_values_and_mode_equivalence(host: Node3D) -> void:
	var snapshots: Dictionary = {}
	for presentation_mode in [&"enabled", &"reduced", &"disabled"]:
		var fixture: Dictionary = await _spawn_fixture(host, presentation_mode, 2)
		var boss = fixture["boss"]
		var target: NovaTarget = fixture["target"]
		var presentation: HollowKingNovaPresentation = fixture["presentation"]
		_expect(is_equal_approx(boss.nova_timer, 4.2), "Hollow King must retain the initial 4.2-second Nova timer (observed %.4f)." % boss.nova_timer)
		boss.nova_timer = 0.0
		boss._physics_process(0.01)
		var bolts := _find_bolts(host)
		_expect(bolts.size() == 10, "%s mode must preserve the phase-two ten-bolt Nova." % presentation_mode)
		_expect(_bolts_match_contract(bolts, 10.8, 11), "%s mode must preserve phase-two Nova speed and bolt damage." % presentation_mode)
		_expect(target.damage_events == 1 and target.health == 234, "%s mode must preserve the phase-two 4.4-radius direct Nova hit for 16 damage once." % presentation_mode)
		_expect(is_equal_approx(boss.nova_timer, 5.2), "%s mode must preserve the phase-two 5.2-second cadence reset." % presentation_mode)
		snapshots[presentation_mode] = _gameplay_snapshot(boss, target, bolts)
		var presentation_snapshot: Dictionary = presentation.snapshot()
		if presentation_mode == &"enabled":
			_expect(presentation_snapshot["transactions"] == 1 and presentation_snapshot["aftermath_sets"] == 1, "One confirmed phase-two Nova must create one enabled aftermath transaction.")
		elif presentation_mode == &"reduced":
			_expect(presentation_snapshot["transactions"] == 1 and presentation_snapshot["motes"] == 2 and presentation_snapshot["local_lights"] == 0, "Reduced mode must retain a bounded warning/aftermath while lowering clutter and light.")
		else:
			_expect(presentation_snapshot["transactions"] == 0 and presentation_snapshot["effect_child_count"] == 0, "Disabled mode must create no presentation transaction.")
		await _cleanup_fixture(host, fixture)
	_expect(snapshots[&"enabled"] == snapshots[&"reduced"] and snapshots[&"enabled"] == snapshots[&"disabled"], "Enabled, reduced, and disabled presentation modes must have identical authoritative Nova gameplay snapshots.")

	var phase_three_fixture: Dictionary = await _spawn_fixture(host, &"enabled", 3)
	var phase_three_boss = phase_three_fixture["boss"]
	var phase_three_target: NovaTarget = phase_three_fixture["target"]
	phase_three_boss.nova_timer = 0.0
	phase_three_boss._physics_process(0.01)
	var phase_three_bolts := _find_bolts(host)
	_expect(phase_three_bolts.size() == 14, "Hollow King must preserve the phase-three fourteen-bolt Nova.")
	_expect(_bolts_match_contract(phase_three_bolts, 11.8, 13), "Hollow King must preserve phase-three Nova speed and bolt damage.")
	_expect(phase_three_target.damage_events == 1 and phase_three_target.health == 231, "Phase-three direct Nova contact must remain 19 damage once inside the authoritative radius.")
	_expect(is_equal_approx(phase_three_boss.nova_timer, 3.7), "Hollow King must preserve the phase-three 3.7-second cadence reset.")
	await _cleanup_fixture(host, phase_three_fixture)


func _test_intent_release_and_bounds(host: Node3D) -> void:
	var fixture: Dictionary = await _spawn_fixture(host, &"enabled", 2)
	var boss = fixture["boss"]
	var presentation: HollowKingNovaPresentation = fixture["presentation"]
	var visual_transform: Transform3D = boss.visual_root.transform
	var armor_color: Color = boss.armor_material.albedo_color
	var core_energy: float = boss.core_material.emission_energy_multiplier
	boss.nova_timer = 0.94
	boss._physics_process(0.10)
	var anticipation: Dictionary = presentation.snapshot()
	_expect(anticipation["state"] == &"anticipation" and anticipation["active_transactions"] == 1, "Existing Nova countdown must begin one boss-local anticipation transaction.")
	_expect(anticipation["danger_boundaries"] == 1 and is_equal_approx(float(anticipation["authoritative_radius"]), 4.4), "Danger boundary must consume the owner-provided 4.4 Nova radius.")
	_expect(_count_collision_objects(presentation) == 0 and _count_collision_shapes(presentation) == 0, "Nova presentation descendants must contain no gameplay collision objects or shapes.")
	boss._physics_process(0.46)
	var imminent: Dictionary = presentation.snapshot()
	_expect(imminent["state"] == &"imminent" and imminent["imminent_effect_sets"] == 1, "Imminent detonation must be visually distinct before the existing authoritative release.")
	boss._physics_process(0.40)
	var released: Dictionary = presentation.snapshot()
	_expect(released["state"] == &"aftermath" and released["releases"] == 1 and released["aftermath_sets"] == 1, "Confirmed Nova release must create one bounded aftermath.")
	presentation.observe_confirmed_nova_release(4.4, 2)
	_expect(presentation.snapshot()["releases"] == 1, "Duplicate release callbacks must not duplicate Nova presentation.")
	_expect(_within_maxima(released), "One Nova aftermath must stay inside every explicit presentation bound.")
	presentation.tick(0.25)
	presentation.tick(0.50)
	var cleaned: Dictionary = presentation.snapshot()
	_expect(cleaned["active_transactions"] == 0 and cleaned["effect_child_count"] == 0, "Aftermath cleanup must remove temporary Nova nodes deterministically.")
	_expect(boss.visual_root.transform == visual_transform and boss.armor_material.albedo_color == armor_color and is_equal_approx(boss.core_material.emission_energy_multiplier, core_energy), "Nova presentation must restore boss transform and materials exactly by never mutating them.")

	for cycle in range(3):
		presentation.observe_nova_countdown(0.90, 4.4, 2)
		presentation.observe_nova_countdown(0.30, 4.4, 2)
		presentation.observe_confirmed_nova_release(4.4, 2)
		_expect(_within_maxima(presentation.snapshot()), "Replay cycle %d must remain bounded." % cycle)
		presentation.tick(1.0)
		_expect(presentation.snapshot()["effect_child_count"] == 0, "Replay cycle %d must leave no stale effect children." % cycle)
	await _cleanup_fixture(host, fixture)


func _test_cancellation_and_teardown(host: Node3D) -> void:
	var phase_fixture: Dictionary = await _spawn_fixture(host, &"enabled", 2)
	var phase_boss = phase_fixture["boss"]
	var phase_presentation: HollowKingNovaPresentation = phase_fixture["presentation"]
	phase_presentation.observe_nova_countdown(0.80, 4.4, 2)
	phase_boss._begin_phase_transition()
	_expect(_presentation_is_clear(phase_presentation), "Existing phase transition must clear Nova presentation without changing attack ownership.")
	await _cleanup_fixture(host, phase_fixture)

	var death_fixture: Dictionary = await _spawn_fixture(host, &"enabled", 2)
	var death_boss = death_fixture["boss"]
	var death_presentation: HollowKingNovaPresentation = death_fixture["presentation"]
	death_presentation.observe_nova_countdown(0.80, 4.4, 2)
	death_boss._die()
	_expect(_presentation_is_clear(death_presentation), "Existing boss death must clear Nova presentation before its death tween.")
	await _cleanup_fixture(host, death_fixture)

	var invalid_fixture: Dictionary = await _spawn_fixture(host, &"enabled", 2)
	var invalid_boss = invalid_fixture["boss"]
	var invalid_target: NovaTarget = invalid_fixture["target"]
	var invalid_presentation: HollowKingNovaPresentation = invalid_fixture["presentation"]
	invalid_presentation.observe_nova_countdown(0.80, 4.4, 2)
	invalid_target.queue_free()
	await process_frame
	invalid_boss._physics_process(0.01)
	_expect(_presentation_is_clear(invalid_presentation), "Existing invalid-target guard must clear Nova presentation safely.")
	await _cleanup_fixture(host, invalid_fixture)

	var teardown_fixture: Dictionary = await _spawn_fixture(host, &"enabled", 2)
	var teardown_boss = teardown_fixture["boss"]
	var teardown_presentation: HollowKingNovaPresentation = teardown_fixture["presentation"]
	teardown_presentation.observe_nova_countdown(0.80, 4.4, 2)
	teardown_boss.queue_free()
	await process_frame
	_expect(_count_nodes_named(host, "HollowKingNovaPresentationRoot") == 0, "Scene teardown must leave no stale Nova presentation root.")
	await _cleanup_fixture(host, teardown_fixture)


func _test_authority_and_presentation_boundaries() -> void:
	var boss_source := FileAccess.get_file_as_string("res://scripts/hollow_king.gd")
	var bolt_source := FileAccess.get_file_as_string("res://scripts/enemy_bolt.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var presentation_source := FileAccess.get_file_as_string("res://scripts/hollow_king_nova_presentation.gd")
	_expect(
		boss_source.contains("var nova_timer := 4.2")
			and boss_source.contains("var count := 10 if phase == 2 else 14")
			and boss_source.contains("_spawn_bolt(direction, 8.8 + float(phase), 7 + phase * 2")
			and boss_source.contains("nova_timer = 5.2 if phase == 2 else 3.7")
			and boss_source.contains("const NOVA_PROXIMITY_RADIUS := 4.4"),
		"Hollow King must retain the frozen Nova cadence, spread, speed, bolt damage, and proximity-radius values."
	)
	_expect(
		_count_text(_function_section(boss_source, "func _cast_nova", "func _spawn_bolt"), "target.take_damage(") == 1
			and _count_text(_function_section(boss_source, "func _cast_nova", "func _spawn_bolt"), "_spawn_bolt(") == 1,
		"Hollow King must remain the sole Nova release and direct-contact damage caller."
	)
	_expect(
		bolt_source.contains("global_position += direction * move_speed * delta")
			and bolt_source.contains("body.take_damage(damage)")
			and bolt_source.contains("func _impact()"),
		"EnemyBolt must remain the sole owner of Nova projectile travel, collision, damage, and projectile cleanup."
	)
	_expect(
		main_source.contains("boss.died.connect(_on_boss_died)")
			and main_source.contains("player.add_experience(350)")
			and main_source.contains("_spawn_item_drop(drop_position, HOLLOW_KING_REWARD)"),
		"main.gd must remain the Hollow King encounter, reward, and progression owner."
	)
	for forbidden in ["take_damage(", "_spawn_bolt(", "move_and_slide(", "nova_timer =", "phase =", "_die(", "add_experience(", "Persistence"]:
		_expect(not presentation_source.contains(forbidden), "Nova presentation must not own gameplay behavior: %s" % forbidden)
	_expect(not presentation_source.contains("CollisionObject3D") and not presentation_source.contains("CollisionShape3D"), "Nova presentation source must not introduce gameplay collision types.")
	_expect(not presentation_source.contains("Input."), "Headless and no-controller Nova presentation paths must not query controller state.")


func _spawn_fixture(host: Node3D, presentation_mode: StringName, phase_value: int) -> Dictionary:
	var world := Node3D.new()
	world.name = "HollowKingNovaFixtureWorld"
	host.add_child(world)
	var target := NovaTarget.new()
	target.name = "NovaTarget"
	target.position = Vector3(3.0, 0.0, 0.0)
	world.add_child(target)
	var boss = HOLLOW_KING_SCRIPT.new()
	boss.name = "HollowKingNovaFixture"
	boss.target = target
	boss.phase = phase_value
	world.add_child(boss)
	boss.set_physics_process(false)
	await process_frame
	var presentation: HollowKingNovaPresentation = boss.nova_presentation
	presentation.set_process(false)
	presentation.set_mode(presentation_mode)
	return {"world": world, "boss": boss, "target": target, "presentation": presentation}


func _cleanup_fixture(host: Node3D, fixture: Dictionary) -> void:
	await _cleanup_bolts(host)
	var world: Node = fixture.get("world") as Node
	if is_instance_valid(world):
		world.queue_free()
	await process_frame


func _cleanup_bolts(host: Node3D) -> void:
	for bolt in _find_bolts(host):
		bolt.queue_free()
	await process_frame


func _find_bolts(host: Node3D) -> Array:
	var bolts: Array = []
	for child: Node in host.get_children():
		if child.get_script() == ENEMY_BOLT_SCRIPT:
			bolts.append(child)
	return bolts


func _bolts_match_contract(bolts: Array, expected_speed: float, expected_damage: int) -> bool:
	for bolt in bolts:
		if not is_equal_approx(float(bolt.move_speed), expected_speed) or int(bolt.damage) != expected_damage:
			return false
	return not bolts.is_empty()


func _gameplay_snapshot(boss, target: NovaTarget, bolts: Array) -> Dictionary:
	var speeds: Array[float] = []
	var damages: Array[int] = []
	for bolt in bolts:
		speeds.append(float(bolt.move_speed))
		damages.append(int(bolt.damage))
	return {
		"phase": boss.phase,
		"nova_timer": boss.nova_timer,
		"target_health": target.health,
		"target_damage_events": target.damage_events,
		"bolt_count": bolts.size(),
		"speeds": speeds,
		"damages": damages,
	}


func _within_maxima(snapshot: Dictionary) -> bool:
	var maxima: Dictionary = snapshot["maxima"]
	return (
		int(snapshot["active_transactions"]) <= int(maxima["active_transactions"])
		and int(snapshot["danger_boundaries"]) <= int(maxima["danger_boundaries"])
		and int(snapshot["imminent_effect_sets"]) <= int(maxima["imminent_effect_sets"])
		and int(snapshot["aftermath_sets"]) <= int(maxima["aftermath_sets"])
		and int(snapshot["motes"]) <= int(maxima["motes"])
		and int(snapshot["residue_nodes"]) <= int(maxima["residue_nodes"])
		and int(snapshot["local_lights"]) <= int(maxima["local_lights"])
		and int(snapshot["audio_players"]) <= int(maxima["audio_players"])
		and int(snapshot["camera_impulses"]) <= int(maxima["camera_impulses"])
	)


func _presentation_is_clear(presentation: HollowKingNovaPresentation) -> bool:
	var snapshot := presentation.snapshot()
	return snapshot["active_transactions"] == 0 and snapshot["effect_child_count"] == 0 and snapshot["danger_boundaries"] == 0 and snapshot["aftermath_sets"] == 0


func _count_collision_objects(node: Node) -> int:
	var count := 1 if node is CollisionObject3D else 0
	for child: Node in node.get_children():
		count += _count_collision_objects(child)
	return count


func _count_collision_shapes(node: Node) -> int:
	var count := 1 if node is CollisionShape3D else 0
	for child: Node in node.get_children():
		count += _count_collision_shapes(child)
	return count


func _count_nodes_named(node: Node, node_name: String) -> int:
	var count := 1 if node.name == node_name else 0
	for child: Node in node.get_children():
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
