extends SceneTree

const RULES = preload("res://scripts/characters/penitent/martyrs_chain_rules.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_target_scoring()
	_test_pull_modes()
	_test_standard_destination()
	_test_anchor_destination()
	_test_damage_and_duration()

	if failures > 0:
		printerr("Martyr's Chain tests failed: %d" % failures)
		quit(1)
		return
	print("Martyr's Chain tests passed.")
	quit(0)


func _test_target_scoring() -> void:
	var unmarked := RULES.score_target(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, -5.0), false)
	var marked := RULES.score_target(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, -5.0), true)
	var behind := RULES.score_target(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, 4.0), true)
	var too_far := RULES.score_target(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, -10.5), true)
	_assert_true(marked > unmarked, "Rite-marked targets receive targeting preference")
	_assert_float(behind, -1.0, "Targets behind the caster are rejected")
	_assert_float(too_far, -1.0, "Targets outside chain range are rejected")


func _test_pull_modes() -> void:
	_assert_equal(RULES.resolve_mode(RULES.TARGET_STANDARD), RULES.MODE_PULL_TARGET, "Standard enemies are dragged to the Penitent")
	_assert_equal(RULES.resolve_mode(RULES.TARGET_BRUTE), RULES.MODE_PULL_CASTER, "Brutes anchor the Penitent")
	_assert_equal(RULES.resolve_mode(RULES.TARGET_BOSS), RULES.MODE_PULL_CASTER, "Bosses anchor the Penitent")


func _test_standard_destination() -> void:
	var destination := RULES.calculate_destination(Vector3.ZERO, Vector3(0.0, 2.0, -8.0), RULES.MODE_PULL_TARGET)
	_assert_vector(destination, Vector3(0.0, 2.0, -1.8), "Standard target stops at melee distance and preserves its height")


func _test_anchor_destination() -> void:
	var destination := RULES.calculate_destination(Vector3.ZERO, Vector3(0.0, 3.0, -8.0), RULES.MODE_PULL_CASTER)
	_assert_vector(destination, Vector3(0.0, 0.0, -5.4), "Caster stops outside the anchor target and preserves caster height")


func _test_damage_and_duration() -> void:
	_assert_equal(RULES.get_impact_damage(RULES.TARGET_STANDARD, false), 7, "Standard chain impact uses base damage")
	_assert_equal(RULES.get_impact_damage(RULES.TARGET_STANDARD, true), 12, "Complete Rite adds impact damage")
	_assert_equal(RULES.get_impact_damage(RULES.TARGET_BOSS, true), 9, "Boss anchor uses reduced base damage plus Rite bonus")
	_assert_true(RULES.get_pull_duration(RULES.TARGET_BOSS) < RULES.get_pull_duration(RULES.TARGET_STANDARD), "Anchor pulls resolve faster than dragged targets")


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


func _assert_vector(actual: Vector3, expected: Vector3, label: String) -> void:
	if actual.is_equal_approx(expected):
		return
	failures += 1
	printerr("FAIL: %s — expected %s, got %s" % [label, str(expected), str(actual)])
