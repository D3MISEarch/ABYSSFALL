extends SceneTree

const PROFILE = preload("res://scripts/ui/input_prompt_profile.gd")

var failures := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_assert_equal(PROFILE.profile_for_joy_name("DualSense Wireless Controller"), PROFILE.PLAYSTATION, "DualSense resolves to PlayStation prompts")
	_assert_equal(PROFILE.profile_for_joy_name("Sony Interactive Entertainment Wireless Controller"), PROFILE.PLAYSTATION, "Sony controller resolves to PlayStation prompts")
	_assert_equal(PROFILE.profile_for_joy_name("Xbox Wireless Controller"), PROFILE.XBOX, "Xbox controller keeps Xbox prompts")

	var penitent_ps := PROFILE.build_hint("penitent_placeholder", PROFILE.PLAYSTATION, "Fervor")
	_assert_true(penitent_ps.contains("R1: BLADE"), "PlayStation Penitent hint uses R1")
	_assert_true(penitent_ps.contains("CROSS: DODGE"), "PlayStation Penitent hint uses Cross")
	_assert_true(not penitent_ps.contains("RB:"), "PlayStation hint does not leak Xbox attack labels")

	var warlock_keyboard := PROFILE.build_hint("void_warlock", PROFILE.KEYBOARD_MOUSE, "Corruption")
	_assert_true(warlock_keyboard.contains("LMB: VOID BOLT"), "Keyboard Warlock hint keeps mouse attack")

	if failures > 0:
		printerr("Input prompt profile tests failed: %d" % failures)
		quit(1)
		return
	print("Input prompt profile tests passed.")
	quit(0)


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
