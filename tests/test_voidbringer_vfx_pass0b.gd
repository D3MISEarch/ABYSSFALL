extends SceneTree

const VOID_BOLT_SCRIPT = preload("res://scripts/void_bolt.gd")
const GRASPING_RIFT_SCRIPT = preload("res://scripts/grasping_rift.gd")
const SHADOW_STEP_VFX_SCRIPT = preload("res://scripts/shadow_step_vfx.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var host := Node3D.new()
	host.name = "VoidbringerVfxTestHost"
	root.add_child(host)
	await process_frame
	await _test_void_bolt(host)
	await _test_grasping_rift(host)
	await _test_shadow_step(host)
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer Art Pass 0B VFX contract")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_void_bolt(host: Node3D) -> void:
	var source := Node3D.new()
	source.name = "BoltSource"
	host.add_child(source)
	var bolt := VOID_BOLT_SCRIPT.new()
	bolt.setup(Vector3(1.0, 0.0, 0.0), 22.0, 18, source, 2.1, 9)
	host.add_child(bolt)
	await process_frame
	_expect(is_equal_approx(bolt.move_speed, 22.0), "Void Bolt speed must remain unchanged")
	_expect(bolt.damage == 18, "Void Bolt damage must remain unchanged")
	_expect(is_equal_approx(bolt.splash_radius, 2.1), "Void Bolt splash radius should preserve setup input")
	_expect(bolt.splash_damage == 9, "Void Bolt splash damage should preserve setup input")
	_expect(bolt.get_node_or_null("VoidBoltVisual/PaleGravitationalCore") != null, "Void Bolt should have a pale gravitational core")
	_expect(bolt.get_node_or_null("VoidBoltVisual/CompressedVoidShell") != null, "Void Bolt should have a compressed dark shell")
	_expect(bolt.get_node_or_null("VoidBoltVisual/FracturedShell") != null, "Void Bolt should have a fractured shell hierarchy")
	_expect(bolt.get_node_or_null("VoidBoltVisual/WarpedWake") != null, "Void Bolt should have a warped wake")
	var splash_tell := bolt.get_node_or_null("VoidBoltVisual/ExplosiveBoltTell") as MeshInstance3D
	_expect(splash_tell != null and splash_tell.visible, "Explosive Void Bolt should expose its splash tell")
	_expect(_count_collision_objects(bolt) == 0, "Void Bolt VFX descendants must not add collision objects")
	_expect(_count_collision_shapes(bolt) == 1, "Void Bolt should retain exactly one projectile collision shape")
	bolt.queue_free()
	source.queue_free()
	await process_frame


func _test_grasping_rift(host: Node3D) -> void:
	var source := Node3D.new()
	source.name = "RiftSource"
	host.add_child(source)
	var rift := GRASPING_RIFT_SCRIPT.new()
	rift.setup(source, 6.0, 2.2, 7.4, 30, 1.0)
	host.add_child(rift)
	await process_frame
	_expect(is_equal_approx(rift.pull_radius, 6.0), "Rift radius must remain unchanged")
	_expect(is_equal_approx(rift.pull_duration, 2.2), "Rift duration must remain unchanged")
	_expect(is_equal_approx(rift.pull_strength, 7.4), "Rift pull strength must remain unchanged")
	_expect(rift.collapse_damage == 30, "Rift collapse damage must remain unchanged")
	_expect(rift.get_node_or_null("GraspingRiftVisual/GravitationalLens") != null, "Rift should have a dark gravitational lens")
	_expect(rift.get_node_or_null("GraspingRiftVisual/OuterVoidFracture") != null, "Rift should have a restrained violet fracture edge")
	_expect(rift.get_node_or_null("GraspingRiftVisual/GravitationalWhiteEdge") != null, "Rift should have a pale compression edge")
	_expect(rift.get_node_or_null("GraspingRiftVisual/InwardFractureSpokes") != null, "Rift should communicate inward movement")
	var debris_root := rift.get_node_or_null("GraspingRiftVisual/OrbitingDebris") as Node3D
	_expect(debris_root != null and debris_root.get_child_count() >= 18, "Rift should contain deterministic orbiting debris")
	var first_shard: MeshInstance3D
	if debris_root != null and debris_root.get_child_count() > 0:
		first_shard = debris_root.get_child(0) as MeshInstance3D
	var starting_radius := 0.0
	if first_shard != null:
		starting_radius = Vector2(first_shard.position.x, first_shard.position.z).length()
	rift.elapsed = 1.1
	rift._update_orbit_debris(0.5)
	if first_shard != null:
		var progressed_radius := Vector2(first_shard.position.x, first_shard.position.z).length()
		_expect(progressed_radius < starting_radius, "Rift debris should visibly accelerate inward during the pull")
	_expect(_count_collision_objects(rift) == 0, "Rift VFX must remain visual-only")
	rift.queue_free()
	source.queue_free()
	await process_frame


func _test_shadow_step(host: Node3D) -> void:
	var source := Node3D.new()
	source.name = "ShadowStepSource"
	host.add_child(source)
	var effect = SHADOW_STEP_VFX_SCRIPT.new()
	host.add_child(effect)
	await process_frame
	effect.setup(source, Vector3.ZERO, Vector3(1.0, 0.0, 0.0), 0.16)
	_expect(effect.get_node_or_null("ShadowStepDeparture") != null, "Shadow Step should create a departure distortion")
	_expect(effect.get_node_or_null("ShadowStepDeparture/ShadowStepDirectionStreak") != null, "Shadow Step should show travel direction")
	source.global_position = Vector3(1.0, 0.0, 0.0)
	effect._process(0.05)
	var trail_root := effect.get_node_or_null("ShadowStepAfterimageTrail") as Node3D
	_expect(trail_root != null and trail_root.get_child_count() >= 1, "Shadow Step should leave a stretched afterimage trail")
	source.global_position = Vector3(3.0, 0.0, 0.0)
	effect._process(0.20)
	_expect(effect.get_node_or_null("ShadowStepArrival") != null, "Shadow Step should create an arrival distortion")
	_expect(_count_collision_objects(effect) == 0, "Shadow Step VFX must remain visual-only")
	effect.queue_free()
	source.queue_free()
	await process_frame


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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
