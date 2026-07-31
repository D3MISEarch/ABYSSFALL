extends SceneTree

const ROUTE_GROUP := "visual_foundation_route_host"
const LIGHTING_RIG_NAME := "VisualFoundationV01_LightingRig"
const VFX_ROOT_NAME := "VisualFoundationV01_VFX"
const LIGHT_EPSILON := 0.002

var failures: Array[String] = []


class FixtureBoss extends Node3D:
	var alive := false
	var health := 0


class FixtureCameraDirector extends Node:
	var state: StringName = &"default_gameplay"


class FixtureRoute extends Node3D:
	var game_state := "courtyard"
	var enemies_alive := 0
	var boss: Node3D
	var camera_director: Node


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var previous_scene := current_scene
	var first_route := _build_route("LightBaselineRouteOne")
	root.add_child(first_route)
	current_scene = first_route
	var cinematic := root.get_node_or_null("VisualFoundationCinematicService")
	await _await_route_binding(first_route, cinematic)
	await _test_baseline_stability(first_route, cinematic)
	var first_light_ids := _light_ids(first_route)

	first_route.queue_free()
	await process_frame
	await process_frame
	_expect(cinematic != null and not bool((cinematic.call("snapshot") as Dictionary).get("route_bound", true)), "Route teardown must clear the active cinematic route binding before a replacement binds.")
	_expect(cinematic != null and (cinematic.get("_base_light_energy") as Dictionary).is_empty(), "Route teardown must clear every authored-light baseline before a replacement route binds.")

	var second_route := _build_route("LightBaselineRouteTwo")
	root.add_child(second_route)
	current_scene = second_route
	await _await_route_binding(second_route, cinematic)
	_test_fresh_rebind(second_route, cinematic, first_light_ids)

	second_route.queue_free()
	await process_frame
	await process_frame
	current_scene = previous_scene

	if failures.is_empty():
		print("PASS: Visual Foundation authored light baseline stability")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _build_route(route_name: String) -> FixtureRoute:
	var route := FixtureRoute.new()
	route.name = route_name
	route.add_to_group(ROUTE_GROUP)

	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = Environment.new()
	route.add_child(world_environment)

	var art_pass := Node3D.new()
	art_pass.name = "SunkenCryptsArtPass0"
	route.add_child(art_pass)

	var director := FixtureCameraDirector.new()
	director.name = "IntegratedCameraDirector"
	route.add_child(director)
	route.camera_director = director

	var boss := FixtureBoss.new()
	boss.name = "TheHollowKing"
	boss.position = Vector3(0.0, 0.0, -103.0)
	route.add_child(boss)
	route.boss = boss
	return route


func _await_route_binding(route: FixtureRoute, cinematic: Node) -> void:
	for _attempt in 12:
		if _route_is_bound(route, cinematic):
			await process_frame
			await process_frame
			return
		await create_timer(0.1).timeout
	_expect(false, "The production services must bind the grouped route within the bounded discovery interval.")


func _route_is_bound(route: FixtureRoute, cinematic: Node) -> bool:
	if cinematic == null:
		return false
	var snapshot: Dictionary = cinematic.call("snapshot")
	return (
		bool(snapshot.get("route_bound", false))
		and int(snapshot.get("installed_scene_id", 0)) == route.get_instance_id()
		and route.get_node_or_null(LIGHTING_RIG_NAME) != null
		and route.get_node_or_null(VFX_ROOT_NAME) != null
	)


func _test_baseline_stability(route: FixtureRoute, cinematic: Node) -> void:
	if cinematic == null:
		return
	var rig := route.get_node_or_null(LIGHTING_RIG_NAME) as Node3D
	var lights := _lights_under(rig)
	var original_baselines := _baseline_copy(cinematic)
	_expect(lights.size() == 7 and original_baselines.size() == 7, "The production-representative route must bind exactly seven authored lights and seven original baselines.")

	route.game_state = "boss"
	var boss := route.boss as FixtureBoss
	boss.alive = true
	boss.health = 500
	for _step in 24:
		cinematic.call("_process", 0.1)
	var resolutions_before := int(cinematic.get("_dependency_resolution_count"))

	for index in 30:
		var ordinary_child := Node3D.new()
		ordinary_child.name = "Ordinary%sSpawn_%02d" % ["Enemy" if index % 2 == 0 else "Pickup", index]
		route.add_child(ordinary_child)
	await process_frame
	await process_frame
	for _step in 24:
		cinematic.call("_process", 0.1)

	var baselines_after := _baseline_copy(cinematic)
	var snapshot: Dictionary = cinematic.call("snapshot")
	_expect(int(snapshot.get("cached_authored_lights", 0)) == 7, "Ordinary direct gameplay children must not change the cached authored-light count.")
	_expect(int(cinematic.get("_dependency_resolution_count")) == resolutions_before, "Ordinary enemy and pickup children must not re-resolve presentation dependencies.")
	_expect(_count_direct_children_named(route, LIGHTING_RIG_NAME) == 1, "Ordinary host children must not create a replacement lighting rig.")
	for light in lights:
		var id := light.get_instance_id()
		var baseline := float(original_baselines.get(id, -1.0))
		var expected := baseline * _boss_route_multiplier(light)
		_expect(_approximately_equal(float(baselines_after.get(id, -2.0)), baseline), "%s must retain its original authored baseline after 30 ordinary host-child spawns." % light.name)
		_expect(_approximately_equal(light.light_energy, expected), "%s must remain at authored baseline × boss-route multiplier after ordinary host-child spawns." % light.name)
	print("PROBE: authored_light_baselines_stable=true direct_children=30 cached_lights=%d" % lights.size())


func _test_fresh_rebind(route: FixtureRoute, cinematic: Node, first_light_ids: Dictionary) -> void:
	if cinematic == null:
		return
	var rig := route.get_node_or_null(LIGHTING_RIG_NAME) as Node3D
	var lights := _lights_under(rig)
	var fresh_baselines := _baseline_copy(cinematic)
	_expect(_count_direct_children_named(route, LIGHTING_RIG_NAME) == 1 and _count_direct_children_named(route, VFX_ROOT_NAME) == 1, "A second route must receive exactly one fresh lighting rig and VFX root.")
	_expect(lights.size() == 7 and fresh_baselines.size() == 7, "A replacement route must capture one fresh baseline for each of its seven authored lights.")
	for light in lights:
		var id := light.get_instance_id()
		_expect(not first_light_ids.has(id), "Replacement route lights must not reuse stale first-route instance IDs.")
		_expect(_approximately_equal(float(fresh_baselines.get(id, -1.0)), light.light_energy), "%s must capture its fresh authored baseline exactly once on route-2 binding." % light.name)
	print("PROBE: fresh_route_baselines=true lighting_rigs=1 vfx_roots=1")


func _baseline_copy(cinematic: Node) -> Dictionary:
	return (cinematic.get("_base_light_energy") as Dictionary).duplicate()


func _lights_under(root_node: Node) -> Array[Light3D]:
	var lights: Array[Light3D] = []
	if root_node == null:
		return lights
	for child in root_node.get_children():
		if child is Light3D:
			lights.append(child as Light3D)
		lights.append_array(_lights_under(child))
	return lights


func _light_ids(route: FixtureRoute) -> Dictionary:
	var ids := {}
	for light in _lights_under(route.get_node_or_null(LIGHTING_RIG_NAME)):
		ids[light.get_instance_id()] = true
	return ids


func _boss_route_multiplier(light: Light3D) -> float:
	return 1.18 if light.name.to_lower().contains("throne") else 0.88


func _count_direct_children_named(parent: Node, node_name: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.name == node_name:
			count += 1
	return count


func _approximately_equal(left: float, right: float) -> bool:
	return absf(left - right) <= LIGHT_EPSILON


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	printerr("ASSERTION FAILED: %s" % message)
