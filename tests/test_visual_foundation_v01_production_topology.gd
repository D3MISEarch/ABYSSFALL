extends SceneTree

const BOOT_SCENE_PATH := "res://main.tscn"
const ROUTE_GROUP := "visual_foundation_route_host"
const LIGHTING_RIG_NAME := "VisualFoundationV01_LightingRig"
const VFX_ROOT_NAME := "VisualFoundationV01_VFX"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var previous_scene := current_scene
	# Load after project autoloads have entered the tree, matching a real application boot.
	var boot_scene := load(BOOT_SCENE_PATH) as PackedScene
	var boot := boot_scene.instantiate()
	boot.name = "AbyssFallBoot"
	root.add_child(boot)
	current_scene = boot
	await process_frame
	await process_frame

	boot.call("_launch_gameplay", "void_warlock")
	var first_route := await _await_bound_route(boot)
	_assert_initial_production_binding(boot, first_route)
	var first_route_id := first_route.get_instance_id() if is_instance_valid(first_route) else 0
	# Let the real route's short boot message and item-drop timers finish before teardown.
	await create_timer(2.75).timeout

	if is_instance_valid(first_route) and first_route.has_signal("exit_to_front_end_requested"):
		first_route.emit_signal("exit_to_front_end_requested")
	else:
		_expect(false, "The real gameplay root must expose the production exit-to-front-end signal.")
	await _wait_for_unbind()
	_assert_route_unbound()

	boot.call("_launch_gameplay", "void_warlock")
	var second_route := await _await_bound_route(boot)
	_assert_rebound_route(boot, first_route_id, second_route)
	await create_timer(2.75).timeout

	var vfx := root.get_node_or_null("VisualFoundationVFXService")
	if vfx != null:
		vfx.call("clear_presentation_effects")
	if is_instance_valid(boot):
		boot.queue_free()
	await process_frame
	await process_frame
	_expect(not is_instance_valid(second_route), "Production boot teardown must release the second gameplay route.")
	current_scene = previous_scene

	if failures.is_empty():
		print("PASS: Visual Foundation production topology")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _await_bound_route(boot: Node) -> Node3D:
	for _attempt in 12:
		var route := boot.get("gameplay_root") as Node3D
		var cinematic := root.get_node_or_null("VisualFoundationCinematicService")
		if _route_installation_complete(route, cinematic):
			return route
		await create_timer(0.15).timeout
	return boot.get("gameplay_root") as Node3D


func _route_installation_complete(route: Node3D, cinematic: Node) -> bool:
	if not is_instance_valid(route) or cinematic == null:
		return false
	var art_pass := route.get_node_or_null("SunkenCryptsArtPass0")
	var world_environment := _find_world_environment(route)
	if art_pass == null or world_environment == null:
		return false
	var snapshot: Dictionary = cinematic.call("snapshot")
	return (
		bool(snapshot.get("route_bound", false))
		and int(snapshot.get("installed_scene_id", 0)) == route.get_instance_id()
		and route.get_node_or_null(LIGHTING_RIG_NAME) != null
		and route.get_node_or_null(VFX_ROOT_NAME) != null
		and str(art_pass.get_meta("visual_foundation_material_pass", "")) == "0.1"
		and bool(world_environment.get_meta("visual_foundation_tuned", false))
	)


func _wait_for_unbind() -> void:
	for _attempt in 8:
		var cinematic := root.get_node_or_null("VisualFoundationCinematicService")
		if cinematic != null:
			var snapshot: Dictionary = cinematic.call("snapshot")
			if not bool(snapshot.get("route_bound", false)):
				return
		await process_frame


func _assert_initial_production_binding(boot: Node, route: Node3D) -> void:
	var lighting := root.get_node_or_null("VisualFoundationLightingService")
	var vfx := root.get_node_or_null("VisualFoundationVFXService")
	var cinematic := root.get_node_or_null("VisualFoundationCinematicService")
	_expect(current_scene == boot and boot.name == "AbyssFallBoot", "The real production current_scene must remain the non-Node3D AbyssFallBoot root.")
	_expect(is_instance_valid(route), "boot._launch_gameplay must create the real gameplay route.")
	_expect(get_first_node_in_group(ROUTE_GROUP) == route, "The live gameplay child must provide the visual-foundation route-host group marker.")
	if not is_instance_valid(route):
		return
	var art_pass := route.get_node_or_null("SunkenCryptsArtPass0")
	var world_environment := _find_world_environment(route)
	_expect(route.get_node_or_null(LIGHTING_RIG_NAME) != null, "The group-discovered production route must receive one lighting rig.")
	_expect(route.get_node_or_null(VFX_ROOT_NAME) != null, "The group-discovered production route must receive the shared VFX root.")
	_expect(art_pass != null and str(art_pass.get_meta("visual_foundation_material_pass", "")) == "0.1", "The live art pass must receive material-pass installation metadata.")
	_expect(world_environment != null and bool(world_environment.get_meta("visual_foundation_tuned", false)), "The existing production WorldEnvironment must be tuned in place.")
	if cinematic != null:
		var snapshot: Dictionary = cinematic.call("snapshot")
		_expect(bool(snapshot.get("route_bound", false)), "The cinematic service must bind the group-discovered production route.")
		_expect(int(snapshot.get("cached_authored_lights", 0)) == 7, "The cinematic service must cache the authored lighting rig once at bind time.")
	for service in [lighting, vfx, cinematic]:
		_expect(service != null, "Every production Visual Foundation service must remain available during route binding.")
		if service != null:
			_expect(_service_timer_is_stopped(service), "Visual Foundation route discovery must stop after a successful production bind.")
	print("PROBE: current_scene=AbyssFallBoot route_host=%s lighting_rig=%s vfx_root=%s materials=%s world_environment=%s cinematic_route_bound=%s" % [
		is_instance_valid(route),
		route.get_node_or_null(LIGHTING_RIG_NAME) != null,
		route.get_node_or_null(VFX_ROOT_NAME) != null,
		art_pass != null and str(art_pass.get_meta("visual_foundation_material_pass", "")) == "0.1",
		world_environment != null and bool(world_environment.get_meta("visual_foundation_tuned", false)),
		cinematic != null and bool((cinematic.call("snapshot") as Dictionary).get("route_bound", false)),
	])


func _assert_route_unbound() -> void:
	var lighting := root.get_node_or_null("VisualFoundationLightingService")
	var vfx := root.get_node_or_null("VisualFoundationVFXService")
	var cinematic := root.get_node_or_null("VisualFoundationCinematicService")
	_expect(get_first_node_in_group(ROUTE_GROUP) == null, "Gameplay exit must remove the route-host group member before a relaunch.")
	for service in [lighting, vfx, cinematic]:
		_expect(service != null and not is_instance_valid(service.get("_route_host") if service != cinematic else service.get("_host")), "Every service must clear its bound route reference when the gameplay route exits.")
	if cinematic != null:
		var snapshot: Dictionary = cinematic.call("snapshot")
		_expect(not bool(snapshot.get("route_bound", true)) and int(snapshot.get("installed_scene_id", -1)) == 0, "Cinematic teardown must clear stale route IDs and stop presentation updates.")
	print("PROBE: route_unbound=true discovery_restarts=true")


func _assert_rebound_route(boot: Node, first_route_id: int, second_route: Node3D) -> void:
	var lighting := root.get_node_or_null("VisualFoundationLightingService")
	var vfx := root.get_node_or_null("VisualFoundationVFXService")
	var cinematic := root.get_node_or_null("VisualFoundationCinematicService")
	_expect(current_scene == boot, "Gameplay relaunch must not replace the production AbyssFallBoot current_scene.")
	_expect(is_instance_valid(second_route) and second_route.get_instance_id() != first_route_id, "A gameplay relaunch must create a distinct route instance.")
	if not is_instance_valid(second_route):
		return
	_expect(get_first_node_in_group(ROUTE_GROUP) == second_route, "The newly launched gameplay route must become the sole route-host group member.")
	_expect(second_route.get_node_or_null(LIGHTING_RIG_NAME) != null and second_route.get_node_or_null(VFX_ROOT_NAME) != null, "The replacement route must bind each required presentation root exactly once.")
	_expect(_count_direct_children_named(second_route, LIGHTING_RIG_NAME) == 1 and _count_direct_children_named(second_route, VFX_ROOT_NAME) == 1, "Route re-entry must not duplicate lighting or VFX roots.")
	for service in [lighting, vfx]:
		_expect(service != null and service.get("_route_host") == second_route, "Each non-cinematic service must rebind exactly once to the replacement route.")
	if cinematic != null:
		var snapshot: Dictionary = cinematic.call("snapshot")
		_expect(bool(snapshot.get("route_bound", false)) and int(snapshot.get("installed_scene_id", 0)) == second_route.get_instance_id(), "Cinematic presentation must rebind to the replacement route with a fresh route ID.")
	print("PROBE: route_rebound=true route_id=%d" % second_route.get_instance_id())


func _service_timer_is_stopped(service: Node) -> bool:
	if service.name == "VisualFoundationLightingService":
		var materials := service.get_node_or_null("VisualFoundationMaterials")
		return bool(service.get_node("VisualFoundationLightingInstallTimer").is_stopped()) and materials != null and bool(materials.get_node("VisualFoundationMaterialsInstallTimer").is_stopped())
	if service.name == "VisualFoundationVFXService":
		return bool(service.get_node("VisualFoundationVFXInstallTimer").is_stopped())
	if service.name == "VisualFoundationCinematicService":
		return bool(service.get_node("VisualFoundationCinematicInstallTimer").is_stopped())
	return false


func _find_world_environment(route: Node3D) -> WorldEnvironment:
	for child in route.get_children():
		if child is WorldEnvironment:
			return child as WorldEnvironment
	return null


func _count_direct_children_named(parent: Node, node_name: String) -> int:
	var count := 0
	for child in parent.get_children():
		if child.name == node_name:
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	printerr("ASSERTION FAILED: %s" % message)
