extends SceneTree

const FOLD_LINE_MANAGER_SCRIPT = preload("res://scripts/characters/voidbringer/fold_line_manager.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lines: VoidbringerFoldLineManager = FOLD_LINE_MANAGER_SCRIPT.new()
	lines.rebuild([
		{"anchor_id": &"vb.anchor.0001", "position": Vector3(-1.0, 0.0, 0.0), "mass": 20.0},
		{"anchor_id": &"vb.anchor.0002", "position": Vector3(1.0, 0.0, 0.0), "mass": 40.0},
	])
	_expect(is_equal_approx(float(lines.interaction_snapshot().get("line_interaction_radius", 0.0)), 0.25), "Fold Line interaction thickness should expose the locked 0.25 meter default")

	var exact := lines.segment_crossings(Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, 1.0))
	_expect(exact.size() == 1, "A true 3D segment crossing should detect the Fold Line")

	var high_y := lines.segment_crossings(Vector3(0.0, 2.0, -1.0), Vector3(0.0, 2.0, 1.0))
	_expect(high_y.is_empty(), "A projectile far above the Fold Line must not receive a false flattened-XZ crossing")

	var within_line_radius := lines.segment_crossings(Vector3(0.0, 0.20, -1.0), Vector3(0.0, 0.20, 1.0))
	_expect(within_line_radius.size() == 1, "Line interaction thickness should admit a near 3D pass within 0.25 meters")

	var outside_line_radius := lines.segment_crossings(Vector3(0.0, 0.40, -1.0), Vector3(0.0, 0.40, 1.0))
	_expect(outside_line_radius.is_empty(), "Line interaction thickness alone should reject a pass beyond 0.25 meters")

	var combined_radius := lines.segment_crossings(Vector3(0.0, 0.40, -1.0), Vector3(0.0, 0.40, 1.0), 0.20)
	_expect(combined_radius.size() == 1, "Projectile radius should combine with Fold Line thickness for the total interaction threshold")

	lines.configure_interaction_radius(0.10)
	var tuned_out := lines.segment_crossings(Vector3(0.0, 0.20, -1.0), Vector3(0.0, 0.20, 1.0))
	_expect(tuned_out.is_empty(), "The interaction radius should remain explicit and owner-tunable rather than hidden in epsilon")

	if failures.is_empty():
		print("PASS: Voidbringer full-3D Fold Line crossings")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
