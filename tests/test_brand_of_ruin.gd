extends SceneTree

const RULES = preload("res://scripts/characters/penitent/brand_of_ruin_rules.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_target_scoring()
	_test_range_and_facing_rejection()
	_test_echo_damage()
	_test_echo_radius()

	if failures > 0:
		printerr("Brand of Ruin tests failed: %d" % failures)
		quit(1)
		return
	print("Brand of Ruin tests passed.")
	quit(0)


func _test_target_scoring() -> void:
	var near_front := RULES.score_target(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, -3.0))
	var far_front := RULES.score_target(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, -7.0))
	_assert_true(near_front > far_front, "Closer forward target receives higher score")


func _test_range_and_facing_rejection() -> void:
	var behind := RULES.score_target(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, 3.0))
	var out_of_range := RULES.score_target(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, -9.0))
	_assert_float(behind, -1.0, "Targets behind the Penitent are rejected")
	_assert_float(out_of_range, -1.0, "Targets outside Brand range are rejected")


func _test_echo_damage() -> void:
	_assert_equal(RULES.calculate_echo_damage(10), 4, "Ten ritual damage echoes for four")
	_assert_equal(RULES.calculate_echo_damage(18), 8, "Finisher damage echoes at forty-two percent")
	_assert_equal(RULES.calculate_echo_damage(0), 1, "Echo damage never resolves below one")


func _test_echo_radius() -> void:
	_assert_true(RULES.can_echo_between(Vector3.ZERO, Vector3(4.7, 5.0, 0.0)), "Vertical offset is ignored inside echo radius")
	_assert_true(not RULES.can_echo_between(Vector3.ZERO, Vector3(5.0, 0.0, 0.0)), "Targets outside echo radius are excluded")


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
