extends SceneTree

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const ENVIRONMENT_SCRIPT = preload("res://scripts/presentation/voidbringer_environment_reaction.gd")
const SHOWCASE_SCENE = preload("res://scenes/voidbringer_impact_showcase_sandbox.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node3D.new()
	host.name = "EnvironmentReactionTestHost"
	root.add_child(host)
	await process_frame
	_test_component_budget_and_modes(host)
	await _test_showcase_integration(host)
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer bounded environment reaction")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_component_budget_and_modes(host: Node3D) -> void:
	var settings := SETTINGS_SCRIPT.new() as VoidbringerPresentationSettings
	var reaction := ENVIRONMENT_SCRIPT.new() as VoidbringerEnvironmentReaction
	reaction.configure(settings)
	host.add_child(reaction)
	reaction.build_showcase_props()
	var initial := reaction.debug_snapshot()
	_expect(int(initial.get("prop_count", -1)) == 9, "Showcase environment must contain the bounded nine-prop dressing set")
	_expect(int(initial.get("active_prop_count", -1)) == 0, "Environment dressing must begin idle")
	_expect(_count_collision_nodes(reaction) == 0, "Environment dressing must contain zero gameplay collision nodes")
	_expect(_count_physics_nodes(reaction) == 0, "Environment dressing must contain zero rigid or soft physics bodies")

	var impact := {
		"cast_id": &"vb.cast.environment.0001",
		"ability_id": &"vb.skill.null_shard",
		"impact_point": Vector3(0.0, 0.0, -4.0),
		"travel_direction": Vector3(0.0, 0.0, -1.0),
		"critical": false,
		"fatal": false,
		"fold_crossing_count": 1,
	}
	var full_report := reaction.consume_impact(impact)
	var full_count := int(full_report.get("reactive_prop_count", 0))
	_expect(full_count > 0 and full_count <= 6, "Full environment response must react to one through six nearest props")
	_expect(int(reaction.debug_snapshot().get("active_prop_count", 0)) == full_count, "Full response active count must match the committed selection")
	var full_positions_before := _positions_by_id(reaction.debug_snapshot())
	reaction.tick(0.12)
	var full_positions_during := _positions_by_id(reaction.debug_snapshot())
	_expect(full_positions_during != full_positions_before, "Active environment response must visibly move decorative props")
	reaction.tick(1.0)
	var full_finished := reaction.debug_snapshot()
	_expect(int(full_finished.get("active_prop_count", -1)) == 0, "Environment response must complete within its bounded duration")
	_expect(_all_props_at_base(full_finished), "Completed environment response must restore every prop exactly to base")

	settings.configure(&"reduced", true, true)
	var reduced_report := reaction.consume_impact(impact)
	var reduced_count := int(reduced_report.get("reactive_prop_count", 0))
	_expect(reduced_count > 0 and reduced_count <= 3, "Reduced environment response must react to at most three props")
	_expect(reduced_count <= full_count, "Reduced environment response must not exceed full prop count")
	_expect(
		float(reduced_report.get("intensity", 1.0)) < float(full_report.get("intensity", 0.0)),
		"Reduced environment response must lower movement intensity"
	)
	reaction.reset_reactions()
	_expect(int(reaction.debug_snapshot().get("active_prop_count", -1)) == 0, "Environment reset must clear all active reactions")
	_expect(_all_props_at_base(reaction.debug_snapshot()), "Environment reset must restore exact base positions")

	settings.configure(&"disabled", true, true)
	var disabled_report := reaction.consume_impact(impact)
	_expect(disabled_report.is_empty(), "Disabled mode must reject environment response")
	_expect(int(reaction.debug_snapshot().get("active_prop_count", -1)) == 0, "Disabled mode must leave zero reactive props")

	var source := FileAccess.get_file_as_string("res://scripts/presentation/voidbringer_environment_reaction.gd")
	for forbidden in ["RigidBody3D", "StaticBody3D", "CharacterBody3D", "SoftBody3D", "CollisionShape3D", "GPUParticles3D", "Decal"]:
		_expect(not source.contains(forbidden), "Environment reaction must not introduce %s" % forbidden)
	reaction.queue_free()


func _test_showcase_integration(host: Node3D) -> void:
	var showcase := SHOWCASE_SCENE.instantiate() as VoidbringerImpactShowcaseSandbox
	host.add_child(showcase)
	await process_frame
	showcase.simulate_showcase_command(&"toggle_haptics")
	showcase.simulate_showcase_command(&"mode_full")
	showcase.simulate_showcase_command(&"demo_lethal")
	var lethal := showcase.debug_showcase_snapshot()
	var environment := lethal.get("environment", {}) as Dictionary
	_expect(int(environment.get("reaction_count", 0)) >= 1, "Committed showcase impact must trigger the bounded environment owner")
	_expect(int(environment.get("active_prop_count", 0)) > 0, "Lethal showcase impact must visibly react nearby dressing")
	_expect(int(environment.get("active_prop_count", 0)) <= 6, "Showcase environment must obey the full-mode active budget")
	showcase.simulate_command(&"clear")
	var reset_environment := (showcase.debug_showcase_snapshot().get("environment", {}) as Dictionary)
	_expect(int(reset_environment.get("active_prop_count", -1)) == 0, "Showcase reset must clear environment reaction state")
	_expect(_all_props_at_base(reset_environment), "Showcase reset must restore every decorative prop")
	showcase.simulate_showcase_command(&"mode_disabled")
	showcase.simulate_showcase_command(&"demo_lethal")
	var disabled_environment := (showcase.debug_showcase_snapshot().get("environment", {}) as Dictionary)
	_expect(int(disabled_environment.get("active_prop_count", -1)) == 0, "Disabled showcase must issue zero environment reactions")
	showcase.queue_free()
	await process_frame


func _positions_by_id(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for raw_position: Variant in snapshot.get("positions", []) as Array:
		var position := raw_position as Dictionary
		result[String(position.get("prop_id", ""))] = position.get("position", Vector3.ZERO)
	return result


func _all_props_at_base(snapshot: Dictionary) -> bool:
	for raw_position: Variant in snapshot.get("positions", []) as Array:
		var position := raw_position as Dictionary
		if position.get("position", Vector3.ZERO) != position.get("base_position", Vector3.ZERO):
			return false
	return true


func _count_collision_nodes(root_node: Node) -> int:
	var count := 1 if root_node is CollisionObject3D or root_node is CollisionShape3D else 0
	for child: Node in root_node.get_children():
		count += _count_collision_nodes(child)
	return count


func _count_physics_nodes(root_node: Node) -> int:
	var count := 1 if root_node is PhysicsBody3D or root_node is SoftBody3D else 0
	for child: Node in root_node.get_children():
		count += _count_physics_nodes(child)
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
