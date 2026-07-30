extends SceneTree

const IMPACT_FEEDBACK_SCRIPT = preload("res://scripts/impact_feedback.gd")
const SKELETON_SCRIPT = preload("res://scripts/skeleton.gd")
const BONE_ARCHER_SCRIPT = preload("res://scripts/bone_archer.gd")
const CRYPT_BRUTE_SCRIPT = preload("res://scripts/crypt_brute.gd")
const HOLLOW_KING_SCRIPT = preload("res://scripts/hollow_king.gd")

const ENEMY_SOURCES := [
	"res://scripts/skeleton.gd",
	"res://scripts/bone_archer.gd",
	"res://scripts/crypt_brute.gd",
	"res://scripts/hollow_king.gd",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node3D.new()
	host.name = "SingleOwnerFractureTestHost"
	root.add_child(host)
	await process_frame
	_test_enemy_source_ownership()
	await _test_contact_restart_and_restoration(host)
	await _test_contact_to_fatal_transition(host)
	await _test_all_enemy_fatal_entry_points(host)
	await _test_owned_action_pulse(host)
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer combat physics and showcase feedback")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_enemy_source_ownership() -> void:
	for path in ENEMY_SOURCES:
		var source := FileAccess.get_file_as_string(path)
		_expect(not source.is_empty(), "%s must remain readable to the ownership audit" % path)
		_expect(
			not source.contains("tween_property(visual_root"),
			"%s must not tween visual_root outside ImpactFeedback" % path
		)
		var die_body := _function_body(source, "func _die()")
		_expect(not die_body.is_empty(), "%s must expose a gameplay-owned _die path" % path)
		_expect(
			die_body.contains("IMPACT_FEEDBACK_SCRIPT.play_fatal"),
			"%s must request its fatal presentation from ImpactFeedback" % path
		)
		_expect(
			not die_body.contains("create_tween")
			and not die_body.contains("visual_root.scale")
			and not die_body.contains("visual_root.rotation"),
			"%s _die must own gameplay death but no death-time visual_root transforms" % path
		)


func _test_contact_restart_and_restoration(host: Node3D) -> void:
	var enemy = await _spawn_enemy(host, SKELETON_SCRIPT, "ContactRestartEnemy")
	var visual_root: Node3D = enemy.visual_root
	var body_position: Vector3 = enemy.global_position
	var collision_layer: int = enemy.collision_layer
	var collision_mask: int = enemy.collision_mask
	var health_before := int(enemy.health)
	var base_position := visual_root.position
	var base_scale := visual_root.scale
	var base_rotation := visual_root.rotation_degrees

	enemy.present_void_bolt_impact(Vector3.FORWARD, true, false)
	var owner := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	_expect(owner != null, "Nonfatal contact must create the single transform owner")
	if owner == null:
		return
	owner._process(0.08)
	_expect(
		visual_root.position != base_position
		or visual_root.scale != base_scale
		or visual_root.rotation_degrees != base_rotation,
		"Nonfatal contact must visibly deform the presentation root"
	)

	for direction in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		enemy.present_void_bolt_impact(direction, true, false)
		var restarted := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
		_expect(restarted == owner, "Repeated contact must restart one owner rather than add a writer")
		_expect(
			_count_nodes_named(visual_root, "VoidbringerImpactFeedback") == 1,
			"Repeated contact must keep exactly one active feedback node"
		)
		if restarted != null:
			_expect(
				is_zero_approx(float(restarted.debug_snapshot().get("elapsed", -1.0))),
				"Contact restart must reset the deterministic reaction timeline"
			)
			restarted._process(0.05)

	owner._process(1.0)
	await process_frame
	_expect(visual_root.position == base_position, "Completed contact must restore exact base position")
	_expect(visual_root.scale == base_scale, "Completed contact must restore exact base scale")
	_expect(visual_root.rotation_degrees == base_rotation, "Completed contact must restore exact base rotation")
	_expect(enemy.global_position == body_position, "Presentation must not move the authoritative body")
	_expect(enemy.collision_layer == collision_layer, "Presentation must not alter collision layer")
	_expect(enemy.collision_mask == collision_mask, "Presentation must not alter collision mask")
	_expect(int(enemy.health) == health_before, "Presentation must not alter authoritative health")
	_expect(
		_count_nodes_named(visual_root, "VoidbringerImpactFeedback") == 0,
		"Completed nonfatal owner must clean itself up"
	)
	enemy.queue_free()
	await process_frame


func _test_contact_to_fatal_transition(host: Node3D) -> void:
	var enemy = await _spawn_enemy(host, SKELETON_SCRIPT, "ContactToFatalEnemy")
	var visual_root: Node3D = enemy.visual_root
	var base_scale := visual_root.scale
	var died_count := [0]
	enemy.died.connect(func(_enemy: Node) -> void: died_count[0] += 1)
	enemy.present_void_bolt_impact(Vector3.FORWARD, true, false)
	var owner := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	_expect(owner != null, "Contact-to-fatal fixture must begin with one contact owner")
	if owner == null:
		enemy.queue_free()
		return
	owner._process(0.08)
	var contact_scale := visual_root.scale
	_expect(contact_scale != base_scale, "Fatal transition must begin from a visibly active contact")

	enemy.health = 1
	enemy.take_damage(1)
	var fatal_owner := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	_expect(fatal_owner == owner, "Lethal damage must transition the active contact owner in place")
	_expect(visual_root.scale == contact_scale, "Contact-to-fatal transition must not restore or snap to base")
	_expect(died_count[0] == 1, "Gameplay death must emit exactly once")
	_expect(not enemy.alive, "Gameplay death state must commit before presentation completes")
	_expect(enemy.collision_layer == 0 and enemy.collision_mask == 0, "Gameplay death must disable collision immediately")
	if fatal_owner == null:
		return
	_expect(fatal_owner.is_fatal_active(), "Transitioned owner must report a fatal profile")
	_expect(
		fatal_owner.get_node_or_null("ProceduralFracture") != null,
		"Fatal owner must expose the procedural Fracture profile"
	)
	fatal_owner._process(0.10)
	var elapsed_before_duplicate := float(fatal_owner.debug_snapshot().get("elapsed", -1.0))
	var scale_before_followup := visual_root.scale
	enemy.present_void_bolt_impact(Vector3.RIGHT, true, true)
	enemy.present_void_bolt_impact(Vector3.LEFT, true, true)
	enemy.present_void_bolt_impact(Vector3.BACK, true, false)
	_expect(
		visual_root.get_node_or_null("VoidbringerImpactFeedback") == fatal_owner,
		"Fatal and nonfatal follow-ups must preserve the existing fatal owner"
	)
	_expect(
		is_equal_approx(float(fatal_owner.debug_snapshot().get("elapsed", -2.0)), elapsed_before_duplicate),
		"Duplicate fatal requests must not restart the fatal timeline"
	)
	_expect(visual_root.scale == scale_before_followup, "Follow-up contact must not snap fatal scale")
	_expect(
		_count_nodes_named(fatal_owner, "FatalPrimaryContact") == 1,
		"Repeated lethal contact may add only one fatal contact accent"
	)
	fatal_owner._process(2.0)
	await process_frame
	_expect(
		not is_instance_valid(enemy) or enemy.is_queued_for_deletion(),
		"Fatal owner must queue its cleanup owner exactly once"
	)
	_expect(
		_count_nodes_named(host, "VoidbringerImpactFeedback") == 0,
		"Fatal owner must leave no stale feedback nodes"
	)


func _test_all_enemy_fatal_entry_points(host: Node3D) -> void:
	var cases := [
		{"script": SKELETON_SCRIPT, "name": "SkeletonFatal"},
		{"script": BONE_ARCHER_SCRIPT, "name": "ArcherFatal"},
		{"script": CRYPT_BRUTE_SCRIPT, "name": "BruteFatal"},
		{"script": HOLLOW_KING_SCRIPT, "name": "BossFatal"},
	]
	for case in cases:
		var enemy = await _spawn_enemy(host, case["script"], case["name"])
		var visual_root: Node3D = enemy.visual_root
		enemy.health = 1
		enemy.take_damage(1)
		var owner := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
		_expect(owner != null and owner.is_fatal_active(), "%s must enter its fatal profile" % case["name"])
		_expect(
			_count_nodes_named(visual_root, "VoidbringerImpactFeedback") == 1,
			"%s must have one fatal transform owner" % case["name"]
		)
		if owner != null:
			owner._process(2.0)
		await process_frame
		_expect(
			not is_instance_valid(enemy) or enemy.is_queued_for_deletion(),
			"%s fatal profile must complete bounded cleanup" % case["name"]
		)


func _test_owned_action_pulse(host: Node3D) -> void:
	var owner := Node3D.new()
	owner.name = "ActionPulseOwner"
	host.add_child(owner)
	var visual_root := Node3D.new()
	visual_root.name = "ActionPulseVisual"
	visual_root.position = Vector3(0.25, -0.10, 0.40)
	visual_root.scale = Vector3(1.2, 0.9, 1.1)
	visual_root.rotation_degrees = Vector3(0.0, 14.0, -3.0)
	owner.add_child(visual_root)
	var base_position := visual_root.position
	var base_scale := visual_root.scale
	var base_rotation := visual_root.rotation_degrees
	var feedback := IMPACT_FEEDBACK_SCRIPT.play_pulse(visual_root, &"attack_heavy")
	_expect(feedback != null, "Owned action pulse must create the transform owner")
	if feedback != null:
		feedback._process(0.10)
		_expect(visual_root.scale != base_scale, "Owned action pulse must visibly animate")
		feedback._process(1.0)
	await process_frame
	_expect(visual_root.position == base_position, "Action pulse must restore exact base position")
	_expect(visual_root.scale == base_scale, "Action pulse must restore exact base scale")
	_expect(visual_root.rotation_degrees == base_rotation, "Action pulse must restore exact base rotation")
	_expect(
		_count_nodes_named(visual_root, "VoidbringerImpactFeedback") == 0,
		"Completed action pulse must leave no stale owner"
	)
	owner.queue_free()
	await process_frame


func _spawn_enemy(host: Node3D, script: Script, enemy_name: String):
	var enemy = script.new()
	enemy.name = enemy_name
	host.add_child(enemy)
	await process_frame
	return enemy


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	if start < 0:
		return ""
	var next_function := source.find("\nfunc ", start + signature.length())
	if next_function < 0:
		return source.substr(start)
	return source.substr(start, next_function - start)


func _count_nodes_named(root_node: Node, node_name: String) -> int:
	var count := 1 if root_node.name == node_name else 0
	for child: Node in root_node.get_children():
		count += _count_nodes_named(child, node_name)
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
