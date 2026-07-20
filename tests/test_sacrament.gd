extends SceneTree

const RULES = preload("res://scripts/characters/penitent/sacrament_rules.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_cast_radius()
	_test_eligibility()
	_test_forced_completion_rules()
	_test_damage_profiles()
	_test_blood_scaling_and_boss_safety()
	_test_visual_intensity_cap()
	_test_stagger_profiles()

	if failures > 0:
		printerr("Sacrament tests failed: %d" % failures)
		quit(1)
		return
	print("Sacrament tests passed.")
	quit(0)


func _test_cast_radius() -> void:
	_assert_true(
		RULES.is_in_cast_radius(Vector3.ZERO, Vector3(6.4, 20.0, 0.0)),
		"Vertical offset does not break Sacrament radius"
	)
	_assert_true(
		not RULES.is_in_cast_radius(Vector3.ZERO, Vector3(6.6, 0.0, 0.0)),
		"Target outside Sacrament radius is rejected"
	)


func _test_eligibility() -> void:
	_assert_true(RULES.is_eligible(1, false), "A partial Rite is eligible")
	_assert_true(RULES.is_eligible(3, false), "A Complete Rite is eligible")
	_assert_true(RULES.is_eligible(0, true), "An unmarked enemy inside a seal is eligible")
	_assert_true(not RULES.is_eligible(0, false), "An unmarked unsealed enemy is ignored")


func _test_forced_completion_rules() -> void:
	_assert_true(not RULES.should_force_complete(0), "Empty mark is not force-completed")
	_assert_true(RULES.should_force_complete(1), "Partial I is force-completed")
	_assert_true(RULES.should_force_complete(2), "Partial II is force-completed")
	_assert_true(not RULES.should_force_complete(3), "Complete Rite is already complete")


func _test_damage_profiles() -> void:
	_assert_equal(
		RULES.get_damage(0, false, false, 0, false),
		18,
		"Unmarked target receives base Sacrament damage"
	)
	_assert_equal(
		RULES.get_damage(1, false, false, 0, false),
		30,
		"Partial Rite receives forced-completion damage"
	)
	_assert_equal(
		RULES.get_damage(3, false, false, 0, false),
		42,
		"Complete Rite receives detonation damage"
	)
	_assert_equal(
		RULES.get_damage(3, true, true, 0, false),
		56,
		"Brand and collapsed seal bonuses stack once"
	)


func _test_blood_scaling_and_boss_safety() -> void:
	_assert_equal(
		RULES.get_damage(3, true, true, 10, false),
		67,
		"Ten percent blood payment amplifies judgment"
	)
	_assert_equal(
		RULES.get_damage(3, true, true, 10, true),
		47,
		"Boss-safe reduction applies after blood scaling"
	)
	_assert_equal(
		RULES.get_damage(3, true, true, 99, false),
		78,
		"Blood multiplier caps at twenty percent"
	)


func _test_visual_intensity_cap() -> void:
	_assert_float(RULES.get_visual_intensity(0, 0), 1.0, "Empty visual begins at base intensity")
	_assert_float(RULES.get_visual_intensity(99, 99), 3.2, "Cathedral visual intensity is capped")


func _test_stagger_profiles() -> void:
	_assert_float(RULES.get_stagger_duration(0, false), 0.16, "Unmarked sealed target gets a short stagger")
	_assert_float(RULES.get_stagger_duration(3, false), 0.42, "Complete Rite gets the longest normal stagger")
	_assert_float(RULES.get_stagger_duration(3, true), 0.10, "Boss stagger remains brief")


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
