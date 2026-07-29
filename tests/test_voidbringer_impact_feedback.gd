extends SceneTree

const VOID_BOLT_SCRIPT = preload("res://scripts/void_bolt.gd")
const SKELETON_SCRIPT = preload("res://scripts/skeleton.gd")
const BONE_ARCHER_SCRIPT = preload("res://scripts/bone_archer.gd")
const CRYPT_BRUTE_SCRIPT = preload("res://scripts/crypt_brute.gd")
const HOLLOW_KING_SCRIPT = preload("res://scripts/hollow_king.gd")
const SOUL_PICKUP_SCRIPT = preload("res://scripts/soul_pickup.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const CORRUPTION_METER_SCRIPT = preload("res://scripts/corruption_meter.gd")
const IMPACT_FEEDBACK_SCRIPT = preload("res://scripts/impact_feedback.gd")

const FEEDBACK_CLEANUP_BOUND_SECONDS := 0.70

var failures: Array[String] = []
var observed_death_count := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var host := Node3D.new()
	host.name = "VoidbringerImpactFeedbackTestHost"
	root.add_child(host)
	await process_frame
	await _test_void_bolt_collision_and_contact(host)
	await _test_phase_locked_primary_still_splashes(host)
	await _test_presentation_boundary_and_profiles(host)
	await _test_interrupted_contact_restoration(host)
	await _test_lethal_feedback_cleanup(host)
	await _test_soul_and_corruption_payoff(host)
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer impact and Corruption payoff")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_void_bolt_collision_and_contact(host: Node3D) -> void:
	var source := Node3D.new()
	source.name = "VoidBoltSource"
	host.add_child(source)
	var invariant_bolt: Variant = _make_bolt(host, source, 2.1, 9)
	await process_frame
	_expect(invariant_bolt.collision_layer == 8, "Void Bolt collision layer must remain 8")
	_expect(invariant_bolt.collision_mask == 4, "Void Bolt collision mask must remain 4")
	_expect(is_equal_approx(invariant_bolt.move_speed, 22.0), "Void Bolt speed must remain pinned at 22.0")
	_expect(invariant_bolt.damage == 18, "Void Bolt primary damage must remain pinned at 18")
	_expect(is_equal_approx(invariant_bolt.splash_radius, 2.1), "Void Bolt splash radius must remain pinned at 2.1")
	_expect(invariant_bolt.splash_damage == 9, "Void Bolt splash damage must remain pinned at 9")
	_expect(_count_collision_shapes(invariant_bolt) == 1, "Void Bolt must keep exactly one gameplay collision shape")
	var visual_root := invariant_bolt.get_node_or_null("VoidBoltVisual") as Node3D
	_expect(visual_root != null, "Void Bolt must retain a decorative visual root")
	_expect(
		_count_collision_objects(visual_root) == 0 and _count_collision_shapes(visual_root) == 0,
		"Void Bolt decorative VFX descendants must contain zero collision objects"
	)
	_expect(
		invariant_bolt.get_node_or_null("VoidBoltVisual/PrimaryContactFrame") != null,
		"Void Bolt must expose a readable primary contact frame"
	)
	_expect(
		invariant_bolt.get_node_or_null("VoidBoltVisual/SecondarySplashContactFrame") != null,
		"Void Bolt must expose a distinct secondary splash contact frame"
	)
	var known_collision_body := StaticBody3D.new()
	known_collision_body.name = "KnownNonDecorativeCollisionBody"
	var known_shape := CollisionShape3D.new()
	known_shape.shape = SphereShape3D.new()
	known_collision_body.add_child(known_shape)
	host.add_child(known_collision_body)
	_expect(
		_count_collision_objects(host) >= 1,
		"Collision counter must detect a known collision body outside the decorative subtree"
	)
	invariant_bolt.queue_free()

	var primary: Variant = await _spawn_enemy(host, SKELETON_SCRIPT, "PrimaryTarget", Vector3.ZERO)
	var secondary_low: Variant = await _spawn_enemy(host, BONE_ARCHER_SCRIPT, "SecondaryLow", Vector3(1.2, 0.0, 0.0))
	var secondary_high: Variant = await _spawn_enemy(host, SKELETON_SCRIPT, "SecondaryHigh", Vector3(-1.5, 9.0, 0.0))
	var outside_splash: Variant = await _spawn_enemy(host, SKELETON_SCRIPT, "OutsideSplash", Vector3(2.15, 14.0, 0.0))
	var primary_health := int(primary.get("health"))
	var low_health := int(secondary_low.get("health"))
	var high_health := int(secondary_high.get("health"))
	var outside_health := int(outside_splash.get("health"))
	var contact_bolt: Variant = _make_bolt(host, source, 2.1, 9)
	contact_bolt.global_position = Vector3.ZERO
	contact_bolt._on_body_entered(primary)
	_expect(int(primary.get("health")) == primary_health - 18, "Primary contact must apply damage exactly once")
	_expect(int(secondary_low.get("health")) == low_health - 9, "Valid secondary target must receive splash once")
	_expect(int(secondary_high.get("health")) == high_health - 9, "Flattened-Y splash behavior must remain unchanged")
	_expect(int(outside_splash.get("health")) == outside_health, "Outside horizontal splash target must remain untouched")
	contact_bolt._on_body_entered(primary)
	_expect(int(primary.get("health")) == primary_health - 18, "Repeated primary contact must not apply damage twice")
	_expect(int(secondary_low.get("health")) == low_health - 9, "Each valid secondary target may be hit at most once")
	_expect(int(secondary_high.get("health")) == high_health - 9, "High-Y secondary target may be hit at most once")
	_expect(
		int(primary.get("health")) != primary_health - 27,
		"Splash must exclude the primary target"
	)
	await process_frame


func _test_phase_locked_primary_still_splashes(host: Node3D) -> void:
	var source := Node3D.new()
	source.name = "PhaseLockSplashSource"
	host.add_child(source)
	var primary: Variant = await _spawn_enemy(
		host, HOLLOW_KING_SCRIPT, "PhaseLockedHollowKing", Vector3(20.0, 0.0, 0.0)
	)
	var secondary: Variant = await _spawn_enemy(
		host, SKELETON_SCRIPT, "PhaseLockSplashSecondary", Vector3(21.2, 0.0, 0.0)
	)
	primary.set("phase_lock", true)
	var primary_health := int(primary.get("health"))
	var secondary_health := int(secondary.get("health"))
	var contact_bolt: Variant = _make_bolt(host, source, 2.1, 9)
	contact_bolt.global_position = primary.global_position
	contact_bolt._on_body_entered(primary)
	_expect(
		int(primary.get("health")) == primary_health,
		"Phase-locked Hollow King must preserve its authoritative health gate"
	)
	_expect(
		int(secondary.get("health")) == secondary_health - 9,
		"Confirmed primary contact must still resolve valid splash targets while the primary health gate blocks damage"
	)
	contact_bolt._on_body_entered(primary)
	_expect(
		int(secondary.get("health")) == secondary_health - 9,
		"Phase-lock splash regression must preserve once-only impact behavior"
	)
	await process_frame


func _test_presentation_boundary_and_profiles(host: Node3D) -> void:
	var light: Variant = await _spawn_enemy(host, SKELETON_SCRIPT, "LightReactionTarget", Vector3(6.0, 0.0, 0.0))
	var heavy: Variant = await _spawn_enemy(host, CRYPT_BRUTE_SCRIPT, "HeavyReactionTarget", Vector3(-6.0, 0.0, 0.0))
	var light_visual: Node3D = light.get("visual_root")
	var heavy_visual: Node3D = heavy.get("visual_root")
	var light_health := int(light.get("health"))
	var heavy_health := int(heavy.get("health"))
	var light_position: Vector3 = light.global_position
	var heavy_position: Vector3 = heavy.global_position
	var light_collision := _collision_snapshot(light)
	var heavy_collision := _collision_snapshot(heavy)
	var light_visual_position := light_visual.position
	var light_visual_scale := light_visual.scale
	var heavy_visual_scale := heavy_visual.scale

	light.present_void_bolt_impact(Vector3.FORWARD, true, false)
	heavy.present_void_bolt_impact(Vector3.FORWARD, true, false)
	var light_feedback := light_visual.get_node_or_null("VoidbringerImpactFeedback")
	var heavy_feedback := heavy_visual.get_node_or_null("VoidbringerImpactFeedback")
	_expect(light_feedback != null and heavy_feedback != null, "Presentation entry points must create decorative feedback")
	if light_feedback != null:
		light_feedback._process(0.08)
	if heavy_feedback != null:
		heavy_feedback._process(0.08)
	_expect(int(light.get("health")) == light_health, "Presentation entry point cannot apply light-enemy damage")
	_expect(int(heavy.get("health")) == heavy_health, "Presentation entry point cannot apply heavy-enemy damage")
	_expect(_vector_equal(light.global_position, light_position), "Presentation cannot move authoritative light enemy bodies")
	_expect(_vector_equal(heavy.global_position, heavy_position), "Presentation cannot move authoritative heavy enemy bodies")
	_expect(_collision_snapshot(light) == light_collision, "Presentation cannot alter light collision state")
	_expect(_collision_snapshot(heavy) == heavy_collision, "Presentation cannot alter heavy collision state")
	_expect(
		not _vector_equal(light_visual.position, light_visual_position)
			or not _vector_equal(light_visual.scale, light_visual_scale),
		"Decorative light recoil must actually run rather than becoming a no-op"
	)
	_expect(
		not _vector_equal(heavy_visual.scale, heavy_visual_scale),
		"Decorative heavy compression must actually run rather than becoming a no-op"
	)

	var light_profile_a := IMPACT_FEEDBACK_SCRIPT.reaction_profile(&"light", true)
	var light_profile_b := IMPACT_FEEDBACK_SCRIPT.reaction_profile(&"light", true)
	var heavy_profile_a := IMPACT_FEEDBACK_SCRIPT.reaction_profile(&"heavy", true)
	var heavy_profile_b := IMPACT_FEEDBACK_SCRIPT.reaction_profile(&"heavy", true)
	var light_trace_a := IMPACT_FEEDBACK_SCRIPT.reaction_sample(light_profile_a, 0.45)
	var light_trace_b := IMPACT_FEEDBACK_SCRIPT.reaction_sample(light_profile_b, 0.45)
	var heavy_trace_a := IMPACT_FEEDBACK_SCRIPT.reaction_sample(heavy_profile_a, 0.45)
	var heavy_trace_b := IMPACT_FEEDBACK_SCRIPT.reaction_sample(heavy_profile_b, 0.45)
	_expect(light_profile_a == light_profile_b and light_trace_a == light_trace_b, "Repeated light reactions must be deterministic")
	_expect(heavy_profile_a == heavy_profile_b and heavy_trace_a == heavy_trace_b, "Repeated heavy reactions must be deterministic")
	_expect(light_trace_a != heavy_trace_a, "Light and heavy reaction traces must differ")
	_expect(
		_count_collision_objects(light_visual) == 0 and _count_collision_objects(heavy_visual) == 0,
		"Feedback descendants must remain collision-free"
	)


func _test_interrupted_contact_restoration(host: Node3D) -> void:
	var enemy: Variant = await _spawn_enemy(host, SKELETON_SCRIPT, "InterruptedReactionTarget", Vector3(11.0, 0.0, 0.0))
	var visual_root: Node3D = enemy.get("visual_root")
	var original_position: Vector3 = visual_root.position
	var original_scale: Vector3 = visual_root.scale
	var original_rotation: Vector3 = visual_root.rotation_degrees
	var enemy_position: Vector3 = enemy.global_position
	var collision_before := _collision_snapshot(enemy)
	var health_before := int(enemy.health)

	enemy.present_void_bolt_impact(Vector3.FORWARD, true, false)
	var canceled_feedback := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	_expect(canceled_feedback != null, "Primary contact should create interruptible impact feedback.")
	if canceled_feedback != null:
		canceled_feedback._process(0.08)
	_expect(
		visual_root.position != original_position
			or visual_root.scale != original_scale
			or visual_root.rotation_degrees != original_rotation,
		"Contact feedback should visibly deform the decorative visual root before interruption."
	)

	enemy.present_void_bolt_impact(Vector3.RIGHT, true, false)
	var replacement_feedback := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	_expect(
		_count_nodes_named(visual_root, "VoidbringerImpactFeedback") == 1,
		"Interrupted contact must leave exactly one active feedback child."
	)
	_expect(
		replacement_feedback != null and replacement_feedback != canceled_feedback,
		"Interrupted contact must replace the canceled feedback instance."
	)
	if replacement_feedback != null:
		replacement_feedback._process(0.06)
	var replacement_position: Vector3 = visual_root.position
	var replacement_scale: Vector3 = visual_root.scale
	var replacement_rotation: Vector3 = visual_root.rotation_degrees
	if canceled_feedback != null:
		canceled_feedback._process(0.24)
	_expect(visual_root.position == replacement_position, "Canceled feedback must not write position after replacement begins.")
	_expect(visual_root.scale == replacement_scale, "Canceled feedback must not write scale after replacement begins.")
	_expect(visual_root.rotation_degrees == replacement_rotation, "Canceled feedback must not write rotation after replacement begins.")

	for direction in [Vector3.LEFT, Vector3.BACK, Vector3.RIGHT]:
		enemy.present_void_bolt_impact(direction, true, false)
		_expect(
			_count_nodes_named(visual_root, "VoidbringerImpactFeedback") == 1,
			"Repeated interruptions must keep one active feedback child."
		)
		var active_feedback := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
		_expect(active_feedback != null, "Repeated interruptions must preserve a replacement feedback instance.")
		if active_feedback != null:
			active_feedback._process(0.06)

	var final_feedback := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	_expect(final_feedback != null, "Final interrupted contact should remain available for cleanup.")
	if final_feedback != null:
		final_feedback._process(1.0)
	await process_frame
	_expect(
		_count_nodes_named(visual_root, "VoidbringerImpactFeedback") == 0,
		"Completed replacement feedback should clean itself up."
	)
	_expect(visual_root.position == original_position, "Interrupted contact feedback must restore the exact original visual position.")
	_expect(visual_root.scale == original_scale, "Interrupted contact feedback must restore the exact original visual scale.")
	_expect(visual_root.rotation_degrees == original_rotation, "Interrupted contact feedback must restore the exact original visual rotation.")
	_expect(enemy.global_position == enemy_position, "Interrupted presentation feedback must not move the authoritative enemy body.")
	_expect(_collision_snapshot(enemy) == collision_before, "Interrupted presentation feedback must not alter collision state.")
	_expect(int(enemy.health) == health_before, "Interrupted presentation feedback must not alter enemy health.")


func _test_lethal_feedback_cleanup(host: Node3D) -> void:
	var lethal_target: Variant = await _spawn_enemy(host, SKELETON_SCRIPT, "LethalTarget", Vector3(0.0, 0.0, 5.0))
	lethal_target.set("health", 18)
	observed_death_count = 0
	lethal_target.died.connect(_on_test_enemy_died)
	lethal_target.take_damage(18)
	lethal_target.take_damage(18)
	_expect(observed_death_count == 1, "Lethal hit must emit death exactly once")
	_expect(not bool(lethal_target.get("alive")), "Post-death damage calls must remain ignored")
	_expect(
		_count_nodes_named(host, "VoidbringerDeathConsequence") >= 1,
		"Lethal hit must create a bounded decorative death consequence"
	)
	await create_timer(FEEDBACK_CLEANUP_BOUND_SECONDS).timeout
	_expect(
		_count_nodes_named(host, "VoidbringerDeathConsequence") == 0,
		"Transient feedback must clean up within the named bounded duration"
	)


func _test_soul_and_corruption_payoff(host: Node3D) -> void:
	var player := PLAYER_SCRIPT.new()
	player.name = "SoulCollectionPlayer"
	var canvas := CanvasLayer.new()
	host.add_child(canvas)
	var meter := CORRUPTION_METER_SCRIPT.new()
	canvas.add_child(meter)
	await process_frame

	var normal_soul := SOUL_PICKUP_SCRIPT.new()
	normal_soul.setup(player, 13.0, false)
	var normal_corruption_before := float(player.get("corruption"))
	var normal_xp_before := int(player.get("experience"))
	normal_soul._deliver_once()
	_expect(
		is_equal_approx(float(player.get("corruption")) - normal_corruption_before, 13.0),
		"Normal soul collection must grant exactly 13.0 Corruption once"
	)
	_expect(int(player.get("experience")) - normal_xp_before == 4, "Normal soul collection must grant exactly 4 XP once")
	normal_soul._deliver_once()
	_expect(
		is_equal_approx(float(player.get("corruption")) - normal_corruption_before, 13.0),
		"Repeated normal collection must not grant additional Corruption"
	)
	_expect(int(player.get("experience")) - normal_xp_before == 4, "Repeated normal collection must not grant additional XP")

	var rare_soul := SOUL_PICKUP_SCRIPT.new()
	rare_soul.setup(player, 28.0, true)
	var rare_corruption_before := float(player.get("corruption"))
	var rare_xp_before := int(player.get("experience"))
	rare_soul._deliver_once()
	_expect(
		is_equal_approx(float(player.get("corruption")) - rare_corruption_before, 28.0),
		"Rare soul collection must grant exactly 28.0 Corruption once"
	)
	_expect(int(player.get("experience")) - rare_xp_before == 8, "Rare soul collection must grant exactly 8 XP once")
	rare_soul._deliver_once()
	_expect(
		is_equal_approx(float(player.get("corruption")) - rare_corruption_before, 28.0),
		"Repeated rare collection must not grant additional Corruption"
	)
	_expect(int(player.get("experience")) - rare_xp_before == 8, "Repeated rare collection must not grant additional XP")

	var observed_delta := 13.0
	meter.set_corruption(float(player.get("corruption")), float(player.get("max_corruption")))
	meter.present_observed_gain(observed_delta)
	_expect(
		is_equal_approx(meter.last_observed_gain, observed_delta),
		"Corruption presentation must preserve the actual observed resource delta"
	)
	var corruption_before_presentation := float(player.get("corruption"))
	meter.present_observed_gain(28.0)
	_expect(
		is_equal_approx(float(player.get("corruption")), corruption_before_presentation),
		"Corruption presentation cannot mutate player resource state"
	)
	_expect(meter.get_node_or_null("ObservedGainLabel") != null, "Corruption meter must expose a brief observed-gain payoff")
	normal_soul.free()
	rare_soul.free()
	player.free()


func _make_bolt(host: Node3D, source: Node3D, splash_radius: float, splash_damage: int):
	var bolt := VOID_BOLT_SCRIPT.new()
	bolt.setup(Vector3.FORWARD, 22.0, 18, source, splash_radius, splash_damage)
	host.add_child(bolt)
	return bolt


func _spawn_enemy(host: Node3D, enemy_script: Script, enemy_name: String, position_value: Vector3):
	var enemy := enemy_script.new() as Node3D
	enemy.name = enemy_name
	enemy.position = position_value
	host.add_child(enemy)
	await process_frame
	_expect(enemy.is_in_group("enemies"), "%s fixture must join the enemies group" % enemy_name)
	return enemy


func _collision_snapshot(node: CollisionObject3D) -> Dictionary:
	var shapes: Array[Dictionary] = []
	_collect_collision_shapes(node, shapes)
	return {
		"layer": node.collision_layer,
		"mask": node.collision_mask,
		"shapes": shapes
	}


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


func _vector_equal(left: Vector3, right: Vector3) -> bool:
	return (
		is_equal_approx(left.x, right.x)
		and is_equal_approx(left.y, right.y)
		and is_equal_approx(left.z, right.z)
	)


func _on_test_enemy_died(_enemy: Node) -> void:
	observed_death_count += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
