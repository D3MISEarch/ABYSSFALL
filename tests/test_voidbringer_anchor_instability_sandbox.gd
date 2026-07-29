extends SceneTree

const ANCHOR_MANAGER_SCRIPT = preload("res://scripts/characters/voidbringer/anchor_manager.gd")
const FOLD_LINE_MANAGER_SCRIPT = preload("res://scripts/characters/voidbringer/fold_line_manager.gd")
const INSTABILITY_CONTROLLER_SCRIPT = preload("res://scripts/characters/voidbringer/instability_controller.gd")
const VOIDBRINGER_CONTROLLER_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_controller.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_anchor_caps_durations_stages_and_cleanup()
	_test_fold_line_geometry_is_deterministic_and_non_colliding()
	_test_instability_delay_decay_and_base_breach()
	_test_composed_controller_cleanup()
	if failures.is_empty():
		print("PASS: Voidbringer anchor and Instability sandbox")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_anchor_caps_durations_stages_and_cleanup() -> void:
	var manager = ANCHOR_MANAGER_SCRIPT.new()
	manager.configure(1)
	_expect(manager.capacity() == 2, "Levels 1-4 should allow two anchors")
	_expect(manager.place_anchor(&"self", null, Vector3.ZERO, 10.0).is_empty(), "Self anchors should remain unavailable in this slice")
	_expect(manager.place_anchor(&"enemy", null, Vector3.ZERO, 10.0).is_empty(), "Enemy Anchors should reject missing carriers")
	_expect(manager.place_anchor(&"corpse", null, Vector3.ZERO, 10.0).is_empty(), "Corpse Anchors should reject missing carriers")

	var enemy := Node3D.new()
	root.add_child(enemy)
	enemy.global_position = Vector3(-2.0, 0.0, 0.0)
	var corpse := Node3D.new()
	root.add_child(corpse)
	corpse.global_position = Vector3(0.0, 0.0, 2.0)
	var enemy_anchor: Dictionary = manager.place_anchor(&"enemy", enemy, enemy.global_position, -12.0)
	var terrain_anchor: Dictionary = manager.place_anchor(&"terrain", null, Vector3(2.0, 0.0, 0.0), 35.0)
	_expect(float(enemy_anchor.get("remaining_seconds", 0.0)) == 12.0, "Enemy anchors should last twelve seconds")
	_expect(float(terrain_anchor.get("remaining_seconds", 0.0)) == 18.0, "Terrain anchors should last eighteen seconds")
	_expect(float(enemy_anchor.get("mass", -1.0)) == 0.0, "Anchor Mass should clamp at zero")
	_expect(enemy_anchor.get("mass_stage", &"") == &"dormant", "Mass 0-34 should be Dormant")
	_expect(terrain_anchor.get("mass_stage", &"") == &"dense", "Mass 35-69 should be Dense")

	var corpse_anchor: Dictionary = manager.place_anchor(&"corpse", corpse, corpse.global_position, 70.0)
	_expect(manager.active_count() == 2, "Placing beyond capacity should retain the bounded cap")
	_expect(not manager.has_anchor(enemy_anchor.get("anchor_id", &"")), "Capacity replacement should remove the oldest anchor deterministically")
	_expect(float(corpse_anchor.get("remaining_seconds", 0.0)) == 8.0, "Corpse anchors should last eight seconds")
	_expect(corpse_anchor.get("mass_stage", &"") == &"critical", "Mass 70-100 should be Critical")
	var saturated: Dictionary = manager.add_mass(corpse_anchor.get("anchor_id", &""), 80.0)
	_expect(float(saturated.get("mass", 0.0)) == 100.0, "Anchor Mass should clamp at one hundred")

	manager.configure(5)
	_expect(manager.capacity() == 3, "Level five onward should allow three anchors")
	var third_anchor: Dictionary = manager.place_anchor(&"enemy", enemy, enemy.global_position, 10.0)
	_expect(not third_anchor.is_empty() and manager.active_count() == 3, "Higher-level capacity should admit a third anchor")

	manager.tick(8.1)
	_expect(not manager.has_anchor(corpse_anchor.get("anchor_id", &"")), "Corpse anchors should expire deterministically")
	corpse.free()
	enemy.free()
	manager.tick(0.1)
	_expect(not manager.has_anchor(third_anchor.get("anchor_id", &"")), "Invalid carrier references should clean up their anchors")
	manager.clear()
	_expect(manager.active_count() == 0, "Anchor teardown should leave no transient registry entries")


func _test_fold_line_geometry_is_deterministic_and_non_colliding() -> void:
	var lines = FOLD_LINE_MANAGER_SCRIPT.new()
	var anchors := [
		{"anchor_id": &"vb.anchor.0002", "position": Vector3(1.0, 0.0, 0.0), "mass": 40.0},
		{"anchor_id": &"vb.anchor.0001", "position": Vector3(-1.0, 0.0, 0.0), "mass": 20.0},
		{"anchor_id": &"vb.anchor.0003", "position": Vector3(0.0, 0.0, 2.0), "mass": 80.0},
	]
	var rebuilt: Array[Dictionary] = lines.rebuild(anchors)
	_expect(rebuilt.size() == 3, "Three anchors should expose three deterministic Fold Lines")
	_expect(str(rebuilt[0].get("line_id", "")) == "vb.fold_line.vb.anchor.0001--vb.anchor.0002", "Fold Line IDs should use sorted anchor IDs")
	for line: Dictionary in rebuilt:
		_expect(not bool(line.get("has_gameplay_collision", true)), "Fold Lines should never add gameplay collision")
	_expect(lines.lines_for_anchor(&"vb.anchor.0001").size() == 2, "Anchor line queries should return every connected segment")
	var crossings := lines.segment_crossings(Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, 1.0))
	_expect(not crossings.is_empty(), "Segment queries should detect movement crossing a Fold Line")
	lines.rebuild(anchors.slice(0, 2))
	_expect(lines.line_count() == 1, "Removing an anchor should remove its Fold Lines on rebuild")
	lines.clear()
	_expect(lines.line_count() == 0, "Fold Line teardown should be bounded and complete")


func _test_instability_delay_decay_and_base_breach() -> void:
	var controller = INSTABILITY_CONTROLLER_SCRIPT.new()
	var breach_starts := [0]
	var breach_ends := [0]
	controller.breach_started.connect(
		func(_duration: float) -> void:
			breach_starts[0] += 1
	)
	controller.breach_ended.connect(
		func() -> void:
			breach_ends[0] += 1
	)
	_expect(controller.commit_spatial_ability(30.0) == 30.0, "Successful spatial commits should add Instability")
	controller.tick(4.0)
	_expect(is_equal_approx(controller.current, 30.0), "Instability should not decay during the four-second delay")
	controller.tick(1.0)
	_expect(is_equal_approx(controller.current, 25.0), "Instability should decay at five per second after the delay")
	controller.commit_spatial_ability(75.0)
	_expect(controller.in_breach, "Reaching one hundred Instability should automatically enter Breach")
	_expect(breach_starts[0] == 1, "Breach entry should emit exactly once")
	_expect(controller.commit_spatial_ability(20.0) == 0.0, "Base Breach should ignore new Instability until it drains")
	_expect(is_equal_approx(controller.anchor_influence_multiplier(), 1.30), "Base Breach should increase anchor influence by thirty percent")
	controller.tick(4.0)
	_expect(is_equal_approx(controller.current, 50.0), "Breach should drain Instability linearly across eight seconds")
	_expect(is_equal_approx(controller.breach_remaining, 4.0), "Breach should retain four seconds at its midpoint")
	controller.tick(4.0)
	_expect(not controller.in_breach and is_equal_approx(controller.current, 0.0), "Base Breach should exit cleanly at zero Instability after eight seconds")
	_expect(breach_ends[0] == 1, "Natural Breach completion should emit exactly once")
	_expect(is_equal_approx(controller.anchor_influence_multiplier(), 1.0), "Anchor influence should return to baseline after Breach")
	controller.commit_spatial_ability(100.0)
	_expect(breach_starts[0] == 2, "A later Breach should emit a new start event")
	controller.clear()
	_expect(breach_ends[0] == 2, "Forced teardown should emit Breach end exactly once")


func _test_composed_controller_cleanup() -> void:
	var controller = VOIDBRINGER_CONTROLLER_SCRIPT.new()
	controller.configure(5)
	controller.place_anchor(&"terrain", null, Vector3(-2.0, 0.0, 0.0), 40.0)
	controller.place_anchor(&"terrain", null, Vector3(2.0, 0.0, 0.0), 70.0)
	var snapshot: Dictionary = controller.snapshot()
	_expect((snapshot.get("anchors", []) as Array).size() == 2, "The class-local controller should expose authoritative anchors")
	_expect((snapshot.get("fold_lines", []) as Array).size() == 1, "The controller should rebuild Fold Lines from active anchors")
	controller.commit_spatial_ability(100.0)
	_expect(bool((controller.snapshot().get("instability", {}) as Dictionary).get("in_breach", false)), "The controller should expose the authoritative Breach state")
	controller.clear()
	snapshot = controller.snapshot()
	_expect((snapshot.get("anchors", []) as Array).is_empty(), "Controller teardown should clear anchors")
	_expect((snapshot.get("fold_lines", []) as Array).is_empty(), "Controller teardown should clear Fold Lines")
	_expect(not bool((snapshot.get("instability", {}) as Dictionary).get("in_breach", true)), "Controller teardown should clear Breach state")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
