extends SceneTree

const GRASPING_RIFT_SCRIPT = preload("res://scripts/grasping_rift.gd")
const NOVA_PRESENTATION_SCRIPT = preload("res://scripts/hollow_king_nova_presentation.gd")
const DEATH_PRESENTATION_SCRIPT = preload("res://scripts/hollow_king_death_presentation.gd")

var failures: Array[String] = []


class FixtureActor extends Node3D:
	var alive := true
	var health := 500
	var damage_events := 0
	var reward_events := 0


class FixtureCameraDirector extends Node:
	var state: StringName = &"default_gameplay"


class FixtureHost extends Node3D:
	var game_state := "courtyard"
	var enemies_alive := 0
	var boss: Node3D
	var player: Node3D
	var camera_director: Node
	var reward_total := 17
	var damage_total := 23


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var previous_scene := current_scene
	var fixture := _build_fixture()
	root.add_child(fixture)
	current_scene = fixture
	await process_frame
	await process_frame

	var lighting := root.get_node_or_null("VisualFoundationLightingService")
	var vfx := root.get_node_or_null("VisualFoundationVFXService")
	var cinematic := root.get_node_or_null("VisualFoundationCinematicService")
	_expect(lighting != null, "The lighting service must be available through the production autoload path.")
	_expect(vfx != null, "The VFX service must be available through the production autoload path.")
	_expect(cinematic != null, "The cinematic service must be available through the production autoload path.")
	if lighting != null:
		lighting.call("_try_install_into_current_scene")
		var materials := lighting.get_node_or_null("VisualFoundationMaterials")
		if materials != null:
			materials.call("_try_apply_to_current_scene")
	if vfx != null:
		vfx.call("_try_install_into_current_scene")
	if cinematic != null:
		cinematic.call("_try_install_into_current_scene")
	await process_frame

	_test_lighting_and_post_processing(fixture)
	_test_material_workflow(fixture)
	await _test_bounded_vfx_and_reactive_debris(fixture, vfx)
	await _test_cinematic_event_orchestration(fixture, cinematic, vfx)
	_test_authority_boundaries()

	await _teardown_fixture(fixture, previous_scene, vfx, cinematic)
	if vfx != null:
		_expect(int(vfx.call("get_active_effect_count")) == 0, "Route teardown must leave no active visual-foundation effects.")

	if failures.is_empty():
		print("PASS: AbyssFall Visual Foundation v0.1")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _teardown_fixture(fixture: FixtureHost, previous_scene: Node, vfx: Node, cinematic: Node) -> void:
	current_scene = previous_scene
	if cinematic != null:
		cinematic.call("_clear_scene_bindings")
	if vfx != null:
		vfx.call("clear_presentation_effects")
	for node in _descendants(fixture):
		if node is CPUParticles3D:
			(node as CPUParticles3D).emitting = false
	for _frame in 4:
		await process_frame
	if is_instance_valid(fixture):
		fixture.free()
	for _frame in 8:
		await process_frame


func _build_fixture() -> FixtureHost:
	var host := FixtureHost.new()
	host.name = "VisualFoundationFixture"

	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.004, 0.012)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.16, 0.17, 0.23)
	environment.ambient_light_energy = 0.72
	world_environment.environment = environment
	host.add_child(world_environment)

	var moon := DirectionalLight3D.new()
	moon.name = "MoonLight"
	moon.light_energy = 1.12
	host.add_child(moon)

	var route := Node3D.new()
	route.name = "SunkenCryptsArtPass0"
	host.add_child(route)
	_add_fixture_mesh(route, "CryptTile_Fixture")
	_add_fixture_mesh(route, "RestraintMachine_Fixture")
	_add_fixture_mesh(route, "VoidFracture_Fixture")
	_add_fixture_mesh(route, "WetDrain_Fixture")

	var floor := StaticBody3D.new()
	floor.name = "CryptFloor"
	host.add_child(floor)
	_add_fixture_mesh(floor, "CryptFloorMesh")
	for wall_name in ["WestOuterWall", "EastOuterWall", "SouthSeal", "NorthThroneWall"]:
		var wall := StaticBody3D.new()
		wall.name = wall_name
		host.add_child(wall)
		_add_fixture_mesh(wall, "%sMesh" % wall_name)

	var player := FixtureActor.new()
	player.name = "VoidbringerFixture"
	host.add_child(player)
	host.player = player
	var boss := FixtureActor.new()
	boss.name = "HollowKingFixture"
	boss.position = Vector3(0.0, 0.0, -103.0)
	host.add_child(boss)
	host.boss = boss
	var director := FixtureCameraDirector.new()
	director.name = "IntegratedCameraDirector"
	host.add_child(director)
	host.camera_director = director
	return host


func _add_fixture_mesh(parent: Node, mesh_name: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	instance.mesh = mesh
	parent.add_child(instance)
	return instance


func _test_lighting_and_post_processing(host: FixtureHost) -> void:
	var rig := host.get_node_or_null("VisualFoundationV01_LightingRig") as Node3D
	_expect(rig != null, "The real route marker must receive one visual-foundation lighting rig.")
	if rig == null:
		return
	_expect(bool(rig.get_meta("presentation_only", false)), "The lighting rig must declare its presentation-only authority.")
	_expect(str(rig.get_meta("visual_foundation_version", "")) == "0.1", "The lighting rig must expose the v0.1 build identity.")
	var light_count := 0
	var particle_amount := 0
	for node in _descendants(rig):
		if node is Light3D:
			light_count += 1
		if node is CPUParticles3D:
			particle_amount += (node as CPUParticles3D).amount
	_expect(light_count == 7, "The authored rig must remain bounded to five key spots and two restrained fills.")
	_expect(particle_amount <= 138, "Ambient dust must retain its documented route-wide particle budget.")
	var world_environment := host.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_expect(world_environment != null and world_environment.environment != null, "The fixture must retain one authoritative WorldEnvironment.")
	if world_environment != null and world_environment.environment != null:
		_expect(bool(world_environment.get_meta("visual_foundation_tuned", false)), "Post-processing must tune the existing WorldEnvironment rather than create a second one.")
		_expect(world_environment.environment.ambient_light_energy <= 0.60, "The visual pass must reduce flat ambient light while preserving readability.")


func _test_material_workflow(host: FixtureHost) -> void:
	var route := host.get_node_or_null("SunkenCryptsArtPass0")
	_expect(route != null and str(route.get_meta("visual_foundation_material_pass", "")) == "0.1", "The real route must record the shared material pass version.")
	if route == null:
		return
	var expected := {
		"CryptTile_Fixture": "stone",
		"RestraintMachine_Fixture": "rusted_iron",
		"VoidFracture_Fixture": "violet_emissive",
		"WetDrain_Fixture": "wet_stone",
	}
	for mesh_name in expected.keys():
		var mesh := route.get_node_or_null(mesh_name) as MeshInstance3D
		_expect(mesh != null and mesh.material_override != null, "%s must receive a reusable material resource." % mesh_name)
		if mesh != null:
			_expect(str(mesh.get_meta("visual_foundation_material_key", "")) == str(expected[mesh_name]), "%s must map to the intended Meshy-ready material slot." % mesh_name)
	var floor_mesh := host.get_node_or_null("CryptFloor/CryptFloorMesh") as MeshInstance3D
	_expect(floor_mesh != null and str(floor_mesh.get_meta("visual_foundation_material_key", "")) == "wet_stone", "The route floor must receive the selective wet-stone treatment without collision changes.")


func _test_bounded_vfx_and_reactive_debris(host: FixtureHost, vfx: Node) -> void:
	if vfx == null:
		return
	var gameplay_before := _gameplay_snapshot(host)
	vfx.call("spawn_gravity_burst", Vector3(0.0, 0.1, -46.0), 1.2)
	await process_frame
	var active_count := int(vfx.call("get_active_effect_count"))
	_expect(active_count > 0 and active_count <= 18, "A confirmed gravity event must create visible effects without exceeding the global effect budget.")
	var effect_root := host.get_node_or_null("VisualFoundationV01_VFX")
	_expect(effect_root != null and int(effect_root.get_meta("bounded_debris_per_burst", 0)) == 12, "The route VFX root must publish its fragment budget.")
	if effect_root != null:
		for node in _descendants(effect_root):
			_expect(not (node is CollisionObject3D) and not (node is CollisionShape3D), "Visual-foundation dust and debris must never create gameplay collision descendants.")
	_expect(_gameplay_snapshot(host) == gameplay_before, "Lighting, VFX, and debris reactions must be gameplay-equivalent.")


func _test_cinematic_event_orchestration(host: FixtureHost, cinematic: Node, vfx: Node) -> void:
	if cinematic == null or vfx == null:
		return
	var director := host.camera_director as FixtureCameraDirector
	director.state = &"boss_reveal"
	host.game_state = "boss"
	var gameplay_before := _gameplay_snapshot(host)
	cinematic.call("_process", 0.5)
	await process_frame
	var snapshot: Dictionary = cinematic.call("snapshot")
	_expect(bool(snapshot["route_bound"]) and bool(snapshot["lighting_bound"]) and bool(snapshot["world_environment_bound"]), "Cinematic presentation must bind the real route, lighting rig, and existing WorldEnvironment.")
	_expect(StringName(snapshot["last_camera_state"]) == &"boss_reveal", "The orchestration layer must observe the existing camera director reveal without becoming a second camera owner.")

	var before_rift_effects := int(vfx.call("get_active_effect_count"))
	var rift := GRASPING_RIFT_SCRIPT.new() as Node3D
	rift.name = "GraspingRiftFixture"
	rift.set_physics_process(false)
	rift.set_process(false)
	rift.set("collapsed", true)
	host.add_child(rift)
	cinematic.call("_register_presentation_node", rift)
	cinematic.call("_update_event_observers")
	await process_frame
	_expect(int(vfx.call("get_active_effect_count")) >= before_rift_effects, "A confirmed Grasping Rift collapse must feed the bounded environmental reaction pipeline.")

	var nova := NOVA_PRESENTATION_SCRIPT.new()
	nova.name = "NovaPresentationFixture"
	host.boss.add_child(nova)
	cinematic.call("_register_presentation_node", nova)
	nova.set("release_count", 1)
	cinematic.call("_update_event_observers")
	await process_frame

	var death := DEATH_PRESENTATION_SCRIPT.new()
	death.name = "DeathPresentationFixture"
	host.add_child(death)
	cinematic.call("_register_presentation_node", death)
	death.set("transaction_count", 1)
	cinematic.call("_update_event_observers")
	await process_frame
	_expect(int(vfx.call("get_active_effect_count")) <= 18, "Rift, Nova, reveal, and death reactions must share one hard active-effect budget.")
	_expect(_gameplay_snapshot(host) == gameplay_before, "Cinematic lighting and environmental event observation must not mutate gameplay facts.")


func _test_authority_boundaries() -> void:
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	var lighting_source := FileAccess.get_file_as_string("res://scripts/presentation/visual_foundation_lighting.gd")
	var material_source := FileAccess.get_file_as_string("res://scripts/presentation/visual_foundation_materials.gd")
	var vfx_source := FileAccess.get_file_as_string("res://scripts/presentation/visual_foundation_vfx.gd")
	var cinematic_source := FileAccess.get_file_as_string("res://scripts/presentation/visual_foundation_cinematic.gd")
	_expect(project_source.contains("VisualFoundationLightingService") and project_source.contains("VisualFoundationVFXService") and project_source.contains("VisualFoundationCinematicService"), "The combined package must enable all three bounded visual-foundation services.")
	for source in [lighting_source, material_source, vfx_source, cinematic_source]:
		_expect(not source.contains("take_damage(") and not source.contains("move_and_slide(") and not source.contains("add_experience(") and not source.contains("_spawn_item_drop") and not source.contains("Persistence."), "Visual-foundation scripts must not own damage, movement, rewards, drops, or persistence.")
	_expect(not cinematic_source.contains("Camera3D.new") and not cinematic_source.contains("camera.global_transform") and not cinematic_source.contains("camera.fov"), "Cinematic environment orchestration must observe the integrated camera director without creating or mutating a second camera.")
	_expect(vfx_source.contains("MAX_ACTIVE_EFFECTS := 18") and vfx_source.contains("MAX_DEBRIS_PER_BURST := 12"), "The VFX pipeline must keep explicit effect and debris budgets.")


func _descendants(root_node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child: Node in root_node.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result


func _gameplay_snapshot(host: FixtureHost) -> Dictionary:
	return {
		"game_state": host.game_state,
		"enemies_alive": host.enemies_alive,
		"reward_total": host.reward_total,
		"damage_total": host.damage_total,
		"player_position": host.player.global_position,
		"player_alive": bool(host.player.get("alive")),
		"player_health": int(host.player.get("health")),
		"boss_position": host.boss.global_position,
		"boss_alive": bool(host.boss.get("alive")),
		"boss_health": int(host.boss.get("health")),
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
