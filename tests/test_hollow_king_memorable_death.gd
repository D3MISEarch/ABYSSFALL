extends SceneTree

const HOLLOW_KING_SCRIPT = preload("res://scripts/hollow_king.gd")

var failures: Array[String] = []
var observed_death_signals := 0


class DeathTarget extends Node3D:
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
	host.name = "HollowKingMemorableDeathTestHost"
	root.add_child(host)
	current_scene = host
	await process_frame
	await _test_once_only_authoritative_handoff(host)
	await _test_visual_lifecycle_and_cleanup(host)
	await _test_presentation_mode_equivalence(host)
	await _test_scene_teardown(host)
	_test_authority_and_presentation_boundaries()
	current_scene = previous_scene
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Hollow King memorable death and reward handoff")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_once_only_authoritative_handoff(host: Node3D) -> void:
	var fixture: Dictionary = await _spawn_fixture(host, &"enabled")
	var boss = fixture["boss"]
	var target: DeathTarget = fixture["target"]
	var death_presentation: HollowKingDeathPresentation = fixture["presentation"]
	observed_death_signals = 0
	boss.died.connect(_on_boss_died)
	boss.nova_presentation.observe_nova_countdown(0.80, 4.4, 2)
	boss.take_damage(boss.health)
	var death_snapshot := death_presentation.snapshot()
	_expect(not boss.alive and boss.health == 0 and boss.collision_layer == 0 and boss.collision_mask == 0, "A lethal authoritative hit must leave Hollow King dead with collision disabled.")
	_expect(observed_death_signals == 1, "The authoritative boss death signal must emit exactly once.")
	_expect(death_snapshot["transactions"] == 1 and death_snapshot["active_transactions"] == 1, "One confirmed death must create one presentation transaction.")
	_expect(_presentation_is_clear(boss.nova_presentation), "Authoritative death must clear active Nova presentation before its handoff.")
	_expect(target.health == 250 and target.damage_events == 0, "A death presentation transaction must not damage or otherwise mutate a target.")
	boss._die()
	_expect(observed_death_signals == 1 and death_presentation.snapshot()["transactions"] == 1, "Duplicate death callbacks must not duplicate the signal, rewards handoff, or presentation.")
	_expect(not death_presentation.observe_confirmed_death(boss.global_position, boss.chest_core.global_position), "A consumed confirmed-death observer must reject duplicate presentation callbacks.")
	_expect(_within_maxima(death_snapshot), "A confirmed death must remain inside every explicit visual maximum.")
	_expect(_count_collision_objects(death_presentation) == 0 and _count_collision_shapes(death_presentation) == 0, "Death presentation descendants must contain no gameplay collision objects or shapes.")
	await _cleanup_fixture(fixture)


func _test_visual_lifecycle_and_cleanup(host: Node3D) -> void:
	var fixture: Dictionary = await _spawn_fixture(host, &"enabled")
	var boss = fixture["boss"]
	var death_presentation: HollowKingDeathPresentation = fixture["presentation"]
	var visual_transform: Transform3D = boss.visual_root.transform
	var armor_color: Color = boss.armor_material.albedo_color
	var core_energy: float = boss.core_material.emission_energy_multiplier
	_expect(death_presentation.observe_confirmed_death(boss.global_position, boss.chest_core.global_position), "A first confirmed death fact must begin the local visual observer.")
	death_presentation.tick(0.10)
	_expect(death_presentation.snapshot()["state"] == &"inward_collapse", "The effect must begin with the short inward gravitational collapse.")
	death_presentation.tick(0.10)
	var suspended := death_presentation.snapshot()
	_expect(suspended["state"] == &"fragment_suspension" and suspended["fragments"] == 6 and suspended["motes"] == 6, "Enabled mode must suspend its fixed, bounded fragment and mote counts around the chest core.")
	death_presentation.tick(0.24)
	var payoff := death_presentation.snapshot()
	_expect(payoff["state"] == &"final_payoff" and payoff["core_singularities"] == 1 and payoff["local_lights"] == 1, "The restrained violet-white final payoff must use one core and one local light.")
	death_presentation.tick(0.20)
	var aftermath := death_presentation.snapshot()
	_expect(aftermath["state"] == &"arena_aftermath" and aftermath["residue_scars"] == 1, "The short aftermath must create one bounded arena scar only after the final payoff.")
	_expect(_within_maxima(aftermath), "Collapse, payoff, and aftermath must stay within every explicit visual maximum.")
	death_presentation.tick(0.42)
	var cleaned := death_presentation.snapshot()
	_expect(cleaned["active_transactions"] == 0 and cleaned["effect_child_count"] == 0, "The complete visual sequence must deterministically clean every temporary node.")
	_expect(boss.visual_root.transform == visual_transform and boss.armor_material.albedo_color == armor_color and is_equal_approx(boss.core_material.emission_energy_multiplier, core_energy), "Presentation must not drift the authoritative boss transform or materials.")
	for cycle in range(3):
		death_presentation.reset_for_replay()
		_expect(death_presentation.observe_confirmed_death(boss.global_position, boss.chest_core.global_position), "Replay cycle %d must accept one fresh confirmed death after reset." % cycle)
		death_presentation.tick(1.10)
		_expect(death_presentation.snapshot()["effect_child_count"] == 0, "Replay cycle %d must leave no stale fragments, motes, core, light, or scar." % cycle)
	death_presentation.reset_for_replay()
	death_presentation.observe_confirmed_death(boss.global_position, boss.chest_core.global_position)
	death_presentation.tick(0.12)
	death_presentation.clear()
	_expect(death_presentation.snapshot()["effect_child_count"] == 0, "Interruption must restore the presentation to a clean state without lingering nodes.")
	_expect(boss.visual_root.transform == visual_transform and boss.armor_material.albedo_color == armor_color, "Interruption must not alter the authoritative body or target presentation state.")
	await _cleanup_fixture(fixture)


func _test_presentation_mode_equivalence(host: Node3D) -> void:
	var snapshots: Dictionary = {}
	for presentation_mode in [&"enabled", &"reduced", &"disabled"]:
		var fixture: Dictionary = await _spawn_fixture(host, presentation_mode)
		var boss = fixture["boss"]
		var target: DeathTarget = fixture["target"]
		var death_presentation: HollowKingDeathPresentation = fixture["presentation"]
		boss.take_damage(boss.health)
		snapshots[presentation_mode] = _gameplay_snapshot(boss, target)
		var visual_snapshot := death_presentation.snapshot()
		if presentation_mode == &"enabled":
			_expect(visual_snapshot["transactions"] == 1 and visual_snapshot["fragments"] == 6, "Enabled mode must retain the complete bounded presentation.")
		elif presentation_mode == &"reduced":
			_expect(visual_snapshot["transactions"] == 1 and visual_snapshot["fragments"] == 3 and visual_snapshot["motes"] == 2, "Reduced mode must keep the confirmed transaction with lower visual density.")
		else:
			_expect(visual_snapshot["transactions"] == 0 and visual_snapshot["effect_child_count"] == 0, "Disabled mode must create no visual transaction.")
		await _cleanup_fixture(fixture)
	_expect(snapshots[&"enabled"] == snapshots[&"reduced"] and snapshots[&"enabled"] == snapshots[&"disabled"], "Enabled, reduced, disabled, headless, and no-controller presentation paths must preserve the same authoritative death gameplay snapshot.")


func _test_scene_teardown(host: Node3D) -> void:
	var previous_scene := current_scene
	var teardown_scene := Node3D.new()
	teardown_scene.name = "HollowKingDeathMenuReturnScene"
	root.add_child(teardown_scene)
	current_scene = teardown_scene
	var fixture: Dictionary = await _spawn_fixture(teardown_scene, &"enabled")
	var boss = fixture["boss"]
	var death_presentation: HollowKingDeathPresentation = fixture["presentation"]
	boss._die()
	_expect(death_presentation.get_parent() == teardown_scene, "A confirmed death helper must move only to its current scene so its short aftermath can outlive the owner teardown.")
	teardown_scene.queue_free()
	current_scene = previous_scene
	await process_frame
	_expect(not is_instance_valid(death_presentation), "Scene teardown or menu return must free the local death helper and every temporary effect.")
	_expect(_count_nodes_named(host, "HollowKingDeathPresentation") == 0, "Menu return must leave no stale death presentation helper in the previous scene.")


func _test_authority_and_presentation_boundaries() -> void:
	var boss_source := FileAccess.get_file_as_string("res://scripts/hollow_king.gd")
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var bolt_source := FileAccess.get_file_as_string("res://scripts/enemy_bolt.gd")
	var presentation_source := FileAccess.get_file_as_string("res://scripts/hollow_king_death_presentation.gd")
	var death_section := _function_section(boss_source, "func _die", "func _hit_flash")
	_expect(_count_text(death_section, "died.emit(self)") == 1 and death_section.contains("if not alive:"), "Hollow King must retain exactly one guarded authoritative death signal emission.")
	_expect(main_source.contains("boss.died.connect(_on_boss_died)") and main_source.contains("player.add_experience(350)") and main_source.contains("_spawn_item_drop(drop_position, HOLLOW_KING_REWARD)") and main_source.contains("_open_gate(\"boss_lock\")") and main_source.contains("_complete_level()"), "main.gd must remain the synchronous reward, XP, loot, checkpoint, progression, and victory-flow owner.")
	_expect(bolt_source.contains("body.take_damage(damage)") and bolt_source.contains("func _impact()"), "Existing projectile ownership must remain unchanged.")
	for forbidden in ["take_damage(", "died.emit", "add_experience(", "_spawn_item_drop", "_open_gate(", "_complete_level(", "Persistence", "move_and_slide(", "_cast_", "_spawn_bolt(", "summon", "phase =", "Input."]:
		_expect(not presentation_source.contains(forbidden), "Death presentation must not own gameplay, reward, persistence, input, attack, summon, or phase behavior: %s" % forbidden)
	_expect(not presentation_source.contains("CollisionObject3D") and not presentation_source.contains("CollisionShape3D"), "Death presentation source must not introduce gameplay collision descendants.")
	_expect(_count_text(presentation_source, "func _process") == 1 and _count_text(presentation_source, "func observe_confirmed_death") == 1, "The boss-local helper must expose one bounded presentation lifecycle only.")


func _spawn_fixture(host: Node3D, presentation_mode: StringName) -> Dictionary:
	var world := Node3D.new()
	world.name = "HollowKingMemorableDeathFixtureWorld"
	host.add_child(world)
	var target := DeathTarget.new()
	target.name = "DeathTarget"
	target.position = Vector3(3.0, 0.0, 0.0)
	world.add_child(target)
	var boss = HOLLOW_KING_SCRIPT.new()
	boss.name = "HollowKingMemorableDeathFixture"
	boss.target = target
	world.add_child(boss)
	boss.set_physics_process(false)
	await process_frame
	var death_presentation: HollowKingDeathPresentation = boss.death_presentation
	death_presentation.set_process(false)
	death_presentation.set_mode(presentation_mode)
	return {"world": world, "boss": boss, "target": target, "presentation": death_presentation}


func _cleanup_fixture(fixture: Dictionary) -> void:
	var presentation: HollowKingDeathPresentation = fixture.get("presentation") as HollowKingDeathPresentation
	if is_instance_valid(presentation):
		presentation.clear()
		presentation.queue_free()
	var world: Node = fixture.get("world") as Node
	if is_instance_valid(world):
		world.queue_free()
	await process_frame


func _gameplay_snapshot(boss, target: DeathTarget) -> Dictionary:
	return {
		"alive": boss.alive,
		"health": boss.health,
		"phase": boss.phase,
		"collision_layer": boss.collision_layer,
		"collision_mask": boss.collision_mask,
		"target_health": target.health,
		"target_damage_events": target.damage_events,
	}


func _within_maxima(snapshot: Dictionary) -> bool:
	var maxima: Dictionary = snapshot["maxima"]
	return (
		int(snapshot["active_transactions"]) <= int(maxima["death_transactions"])
		and int(snapshot["core_singularities"]) <= int(maxima["core_singularities"])
		and int(snapshot["residue_scars"]) <= int(maxima["residue_scars"])
		and int(snapshot["local_lights"]) <= int(maxima["local_lights"])
		and int(snapshot["audio_players"]) <= int(maxima["audio_players"])
		and int(snapshot["camera_impulses"]) <= int(maxima["camera_impulses"])
		and int(snapshot["haptic_events"]) <= int(maxima["haptic_events"])
		and int(snapshot["fragments"]) <= int(maxima["fragments"])
		and int(snapshot["motes"]) <= int(maxima["motes"])
	)


func _presentation_is_clear(presentation: HollowKingNovaPresentation) -> bool:
	var snapshot := presentation.snapshot()
	return snapshot["active_transactions"] == 0 and snapshot["effect_child_count"] == 0


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


func _on_boss_died(_dead_boss: Node) -> void:
	observed_death_signals += 1
