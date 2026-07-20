extends SceneTree

const FERVOR_RESOURCE_SCRIPT = preload("res://scripts/characters/penitent/fervor_resource.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_clamping_and_thresholds()
	_test_spending_and_insufficient_cost()
	_test_out_of_combat_decay()
	_test_sacrament_health_substitution()
	_test_sacrament_cannot_kill()

	if failures > 0:
		printerr("Fervor tests failed: %d" % failures)
		quit(1)
		return

	print("Fervor tests passed.")
	quit(0)


func _test_clamping_and_thresholds() -> void:
	var resource := FERVOR_RESOURCE_SCRIPT.new()
	resource.configure(0.0, 100.0)
	_assert_equal(resource.current_threshold, resource.THRESHOLD_DORMANT, "0 is Dormant")

	resource.add_fervor(25.0)
	_assert_float(resource.current_value, 25.0, "Fervor reaches 25")
	_assert_equal(resource.current_threshold, resource.THRESHOLD_KINDLED, "25 is Kindled")

	resource.add_fervor(25.0)
	_assert_equal(resource.current_threshold, resource.THRESHOLD_ZEALOUS, "50 is Zealous")

	resource.add_fervor(25.0)
	_assert_equal(resource.current_threshold, resource.THRESHOLD_FANATICAL, "75 is Fanatical")

	resource.add_fervor(1000.0)
	_assert_float(resource.current_value, 100.0, "Fervor clamps at maximum")
	_assert_equal(resource.current_threshold, resource.THRESHOLD_REVELATION, "100 is Revelation")
	resource.free()


func _test_spending_and_insufficient_cost() -> void:
	var resource := FERVOR_RESOURCE_SCRIPT.new()
	resource.configure(100.0, 100.0)
	_assert_true(resource.spend_fervor(40.0), "Affordable Fervor cost succeeds")
	_assert_float(resource.current_value, 60.0, "Affordable cost is deducted")
	_assert_true(not resource.spend_fervor(80.0), "Unaffordable Fervor cost fails")
	_assert_float(resource.current_value, 60.0, "Failed cost does not change Fervor")
	resource.free()


func _test_out_of_combat_decay() -> void:
	var resource := FERVOR_RESOURCE_SCRIPT.new()
	resource.configure(80.0, 100.0, 25.0)
	resource.set_combat_active(false)
	resource.advance_decay(8.0)
	_assert_float(resource.current_value, 80.0, "Fervor does not decay during grace period")
	resource.advance_decay(1.0)
	_assert_float(resource.current_value, 76.0, "Fervor decays at four per second")
	resource.advance_decay(30.0)
	_assert_float(resource.current_value, 25.0, "Fervor decay stops at floor")
	resource.free()


func _test_sacrament_health_substitution() -> void:
	var resource := FERVOR_RESOURCE_SCRIPT.new()
	resource.configure(25.0, 100.0)
	var quote: Dictionary = resource.quote_sacrament_cost(40.0, 100, 100)
	_assert_true(bool(quote.get("can_cast", false)), "Sacrament can use health substitution")
	_assert_float(float(quote.get("fervor_spent", 0.0)), 25.0, "Sacrament spends available Fervor")
	_assert_float(float(quote.get("missing_fervor", 0.0)), 15.0, "Sacrament reports missing Fervor")
	_assert_equal(int(quote.get("health_percent", 0)), 8, "Every missing two Fervor costs one percent health")
	_assert_equal(int(quote.get("health_cost", 0)), 8, "Health payment uses maximum health")
	_assert_equal(int(quote.get("remaining_health", 0)), 92, "Health preview is correct")

	var committed: Dictionary = resource.commit_sacrament_cost(40.0, 100, 100)
	_assert_true(bool(committed.get("can_cast", false)), "Sacrament commit succeeds")
	_assert_float(resource.current_value, 0.0, "Sacrament consumes available Fervor")
	resource.free()


func _test_sacrament_cannot_kill() -> void:
	var resource := FERVOR_RESOURCE_SCRIPT.new()
	resource.configure(0.0, 100.0)
	var quote: Dictionary = resource.quote_sacrament_cost(40.0, 10, 100)
	_assert_true(not bool(quote.get("can_cast", true)), "Health substitution cannot reduce player below one health")
	var committed: Dictionary = resource.commit_sacrament_cost(40.0, 10, 100)
	_assert_true(not bool(committed.get("can_cast", true)), "Unsafe Sacrament commit is rejected")
	_assert_float(resource.current_value, 0.0, "Rejected Sacrament does not change Fervor")
	resource.free()


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
