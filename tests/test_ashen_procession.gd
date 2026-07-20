extends SceneTree

const RULES = preload("res://scripts/characters/penitent/ashen_procession_rules.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_line_distance_ignores_height()
	_test_trail_arming()
	_test_crossing_detection()
	_test_enemy_line_inclusion()
	_test_trail_length_gate()
	_test_damage_profiles()
	_test_fervor_reward()

	if failures > 0:
		printerr("Ashen Procession tests failed: %d" % failures)
		quit(1)
		return
	print("Ashen Procession tests passed.")
	quit(0)


func _test_line_distance_ignores_height() -> void:
	var distance := RULES.point_segment_distance(
		Vector3(0.5, 12.0, 0.0),
		Vector3(-1.0, 0.0, 0.0),
		Vector3(1.0, 0.0, 0.0)
	)
	_assert_float(distance, 0.0, "Ground-line distance ignores vertical offset")


func _test_trail_arming() -> void:
	var start := Vector3(-1.4, 0.0, 0.0)
	var finish := Vector3(1.4, 0.0, 0.0)
	_assert_true(
		not RULES.should_arm(Vector3(1.4, 0.0, 0.0), start, finish),
		"Trail does not arm while the Penitent remains on an endpoint"
	)
	_assert_true(
		RULES.should_arm(Vector3(0.0, 0.0, 1.1), start, finish),
		"Trail arms after the Penitent leaves the scripture"
	)


func _test_crossing_detection() -> void:
	var start := Vector3(0.0, 0.0, -1.5)
	var finish := Vector3(0.0, 0.0, 1.5)
	_assert_true(
		RULES.did_cross(Vector3(-1.2, 0.0, 0.0), Vector3(1.2, 0.0, 0.0), start, finish),
		"Fast movement crossing the line completes the rite"
	)
	_assert_true(
		RULES.did_cross(Vector3(0.9, 0.0, 0.2), Vector3(0.3, 0.0, 0.2), start, finish),
		"Entering the line radius completes the rite"
	)
	_assert_true(
		not RULES.did_cross(Vector3(1.3, 0.0, -1.0), Vector3(1.3, 0.0, 1.0), start, finish),
		"Parallel movement outside the line does not complete the rite"
	)


func _test_enemy_line_inclusion() -> void:
	var start := Vector3(-2.0, 0.0, 0.0)
	var finish := Vector3(2.0, 0.0, 0.0)
	_assert_true(
		RULES.is_enemy_on_rite_line(Vector3(0.0, 5.0, 0.60), start, finish),
		"Enemy inside the ritual width is struck"
	)
	_assert_true(
		not RULES.is_enemy_on_rite_line(Vector3(0.0, 0.0, 0.90), start, finish),
		"Enemy outside the ritual width is spared"
	)


func _test_trail_length_gate() -> void:
	_assert_true(
		RULES.is_valid_trail(Vector3.ZERO, Vector3(0.0, 0.0, 2.7)),
		"Normal dodge distance creates a trail"
	)
	_assert_true(
		not RULES.is_valid_trail(Vector3.ZERO, Vector3(0.0, 0.0, 0.6)),
		"Tiny movement does not create ritual clutter"
	)


func _test_damage_profiles() -> void:
	_assert_equal(RULES.get_impact_damage(0), 16, "Unmarked target receives base procession damage")
	_assert_equal(RULES.get_impact_damage(1), 21, "Partial Rite target receives amplified damage")
	_assert_equal(RULES.get_impact_damage(3), 28, "Complete Rite target receives judgment damage")


func _test_fervor_reward() -> void:
	_assert_float(RULES.get_fervor_reward(0, 0), 0.0, "Empty crossing cannot be farmed for Fervor")
	_assert_float(RULES.get_fervor_reward(2, 1), 10.0, "Hits and Complete Rites increase the reward")
	_assert_float(RULES.get_fervor_reward(20, 20), 16.0, "Horde reward remains capped")


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		return
	failures += 1
	printerr("FAIL: %s" % label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual == expected:
		return
	failures += 1
	printerr("FAIL: %s — expected %s, got %s" % [label, str(expected), str(actual)])


func _assert_float(actual: float, expected: float, label: String) -> void:
	if is_equal_approx(actual, expected):
		return
	failures += 1
	printerr("FAIL: %s — expected %.3f, got %.3f" % [label, expected, actual])
