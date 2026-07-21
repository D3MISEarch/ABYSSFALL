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
	var build_name := str(identity.get("name", ""))
	var commit := str(identity.get("commit", ""))
	var short_commit := str(identity.get("short_commit", ""))
	var branch := str(identity.get("branch", ""))
	var workflow_run := str(identity.get("workflow_run", ""))
	var built_at_utc := str(identity.get("built_at_utc", ""))

	_assert_true(not build_name.is_empty(), "Build identity includes a name")
	_assert_true(not commit.is_empty(), "Build identity includes a commit")
	_assert_true(not short_commit.is_empty(), "Build identity includes a short commit")
	_assert_true(not branch.is_empty(), "Build identity includes a branch")
	_assert_true(not workflow_run.is_empty(), "Build identity includes a workflow run")
	_assert_true(not built_at_utc.is_empty(), "Build identity includes a build timestamp")
	_assert_true(
		commit == "development" or commit.begins_with(short_commit),
		"Short commit matches the full commit or local development sentinel"
	)

	var display := BUILD_IDENTITY.display_line(identity)
	_assert_true(display.contains(build_name), "Build display includes name")
	_assert_true(display.contains(short_commit), "Build display includes short commit")


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
