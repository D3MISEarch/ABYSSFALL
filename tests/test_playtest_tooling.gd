extends SceneTree

const BUILD_IDENTITY = preload("res://scripts/tooling/build_identity.gd")
const OVERLAY_SCRIPT = preload("res://scripts/tooling/playtest_diagnostic_overlay.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_build_identity()
	await _test_overlay_toggle_and_content()
	if failures > 0:
		printerr("Playtest tooling tests failed: %d" % failures)
		quit(1)
		return
	print("Playtest tooling tests passed.")
	quit(0)


func _test_build_identity() -> void:
	var identity := BUILD_IDENTITY.load_current()
	_assert_equal(identity.get("short_commit", ""), "dev", "Development build identity loads")
	var display := BUILD_IDENTITY.display_line(identity)
	_assert_true(display.contains("AbyssFall developer build"), "Build display includes name")
	_assert_true(display.contains("dev"), "Build display includes short commit")


func _test_overlay_toggle_and_content() -> void:
	var overlay := OVERLAY_SCRIPT.new() as PlaytestDiagnosticOverlay
	root.add_child(overlay)
	await process_frame
	var panel := overlay.get_node_or_null("PlaytestDiagnostics") as PanelContainer
	_assert_true(is_instance_valid(panel), "Overlay creates its diagnostics panel")
	if not is_instance_valid(panel):
		overlay.queue_free()
		return
	_assert_true(not panel.visible, "Diagnostics start hidden")

	var event := InputEventKey.new()
	event.keycode = KEY_F3
	event.pressed = true
	overlay._unhandled_input(event)
	_assert_true(panel.visible, "F3 opens diagnostics")
	var label := panel.find_child("DiagnosticText", true, false) as Label
	_assert_true(is_instance_valid(label), "Diagnostics create readable text")
	if is_instance_valid(label):
		_assert_true(label.text.contains("Commit:"), "Diagnostics expose commit identity")
		_assert_true(label.text.contains("Input profile:"), "Diagnostics expose input profile")
		_assert_true(label.text.contains("Connected controllers:"), "Diagnostics expose controller names")

	overlay._unhandled_input(event)
	_assert_true(not panel.visible, "F3 closes diagnostics")
	overlay.queue_free()


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
