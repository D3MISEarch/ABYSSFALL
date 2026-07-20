extends SceneTree

const FERVOR_SEAL_SCRIPT = preload("res://scripts/ui/fervor_seal.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var seal := FERVOR_SEAL_SCRIPT.new()
	root.add_child(seal)
	seal.set_resource(0.0, 100.0)
	_assert_equal(int(seal.get_state_snapshot().get("threshold", -1)), 0, "0 Fervor is Dormant")

	seal.set_resource(25.0, 100.0)
	_assert_equal(int(seal.get_state_snapshot().get("threshold", -1)), 1, "25 Fervor is Kindled")

	seal.set_resource(50.0, 100.0)
	_assert_equal(int(seal.get_state_snapshot().get("threshold", -1)), 2, "50 Fervor is Zealous")

	seal.set_resource(75.0, 100.0)
	_assert_equal(int(seal.get_state_snapshot().get("threshold", -1)), 3, "75 Fervor is Fanatical")

	seal.set_resource(100.0, 100.0)
	_assert_equal(int(seal.get_state_snapshot().get("threshold", -1)), 4, "100 Fervor is Revelation")

	seal.set_cost_preview(40.0, 8)
	var cost_snapshot: Dictionary = seal.get_state_snapshot()
	_assert_float(float(cost_snapshot.get("preview_fervor_cost", 0.0)), 40.0, "Fervor cost preview is stored")
	_assert_equal(int(cost_snapshot.get("preview_health_percent", 0)), 8, "Health preview is stored")

	seal.set_sigil_capacity(2, 3)
	var sigil_snapshot: Dictionary = seal.get_state_snapshot()
	_assert_equal(int(sigil_snapshot.get("active_sigils", -1)), 2, "Active sigil count is stored")
	_assert_equal(int(sigil_snapshot.get("maximum_sigils", -1)), 3, "Maximum sigil count is stored")

	seal.clear_cost_preview()
	_assert_equal(int(seal.get_state_snapshot().get("preview_health_percent", -1)), 0, "Cost preview clears")
	seal.queue_free()

	if failures > 0:
		printerr("Fervor seal tests failed: %d" % failures)
		quit(1)
		return
	print("Fervor seal tests passed.")
	quit(0)


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
