extends SceneTree

const RITE_MARK_SCRIPT = preload("res://scripts/characters/penitent/rite_mark_component.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_state_progression()
	_test_completion_and_consumption()
	_test_mark_expiry()
	_test_brand_lifecycle()
	_test_boss_safe_snapshot()

	if failures > 0:
		printerr("Rite Mark tests failed: %d" % failures)
		quit(1)
		return
	print("Rite Mark tests passed.")
	quit(0)


func _test_state_progression() -> void:
	var mark := RITE_MARK_SCRIPT.new() as RiteMarkComponent
	mark.configure(6.0, 8.0)
	_assert_equal(mark.current_state, RiteMarkComponent.STATE_NONE, "New mark starts empty")
	_assert_equal(mark.apply_partial(), RiteMarkComponent.STATE_PARTIAL_ONE, "First strike creates Partial I")
	_assert_float(mark.remaining_duration, 6.0, "Partial I receives base duration")
	_assert_equal(mark.apply_partial(), RiteMarkComponent.STATE_PARTIAL_TWO, "Second strike creates Partial II")
	_assert_equal(mark.apply_partial(), RiteMarkComponent.STATE_COMPLETE, "Third strike completes the Rite")
	_assert_float(mark.remaining_duration, 8.0, "Complete Rite receives complete duration")
	_assert_equal(mark.apply_partial(), RiteMarkComponent.STATE_COMPLETE, "Complete Rite cannot over-stack")
	mark.free()


func _test_completion_and_consumption() -> void:
	var mark := RITE_MARK_SCRIPT.new() as RiteMarkComponent
	mark.configure()
	_assert_true(mark.complete_rite(), "Completing an incomplete mark reports a new completion")
	_assert_true(not mark.complete_rite(), "Refreshing an existing complete Rite is not a new completion")
	_assert_true(mark.consume_rite(), "Complete Rite can be consumed")
	_assert_equal(mark.current_state, RiteMarkComponent.STATE_NONE, "Consumed Rite clears")
	_assert_true(not mark.consume_rite(), "Empty mark cannot be consumed twice")
	mark.free()


func _test_mark_expiry() -> void:
	var mark := RITE_MARK_SCRIPT.new() as RiteMarkComponent
	mark.configure(2.0, 3.0)
	mark.apply_partial()
	mark.advance_time(1.25)
	_assert_float(mark.remaining_duration, 0.75, "Mark duration advances deterministically")
	mark.extend_duration(1.0)
	_assert_float(mark.remaining_duration, 1.75, "Duration extension is applied")
	mark.advance_time(2.0)
	_assert_equal(mark.current_state, RiteMarkComponent.STATE_NONE, "Expired mark clears")
	_assert_float(mark.remaining_duration, 0.0, "Expired mark has no remaining time")
	mark.free()


func _test_brand_lifecycle() -> void:
	var mark := RITE_MARK_SCRIPT.new() as RiteMarkComponent
	mark.configure()
	mark.apply_brand(4.0)
	_assert_true(mark.branded, "Brand activates")
	mark.advance_time(2.5)
	_assert_float(mark.brand_remaining, 1.5, "Brand duration advances independently")
	mark.advance_time(2.0)
	_assert_true(not mark.branded, "Brand expires")
	mark.free()


func _test_boss_safe_snapshot() -> void:
	var mark := RITE_MARK_SCRIPT.new() as RiteMarkComponent
	mark.configure(6.0, 8.0, true)
	mark.apply_partial(99)
	var snapshot := mark.get_snapshot()
	_assert_true(bool(snapshot.get("boss_safe", false)), "Boss mark exposes boss-safe mode")
	_assert_equal(int(snapshot.get("state", -1)), RiteMarkComponent.STATE_COMPLETE, "Boss mark still clamps at Complete")
	mark.free()


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
