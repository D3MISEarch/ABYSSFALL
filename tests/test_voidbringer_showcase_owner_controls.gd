extends SceneTree

const SHOWCASE_SCENE = preload("res://scenes/voidbringer_impact_showcase_sandbox.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var showcase := SHOWCASE_SCENE.instantiate() as VoidbringerImpactShowcaseSandbox
	root.add_child(showcase)
	await process_frame

	_test_owner_mode_controls(showcase)
	_test_owner_hud_and_camera(showcase)
	_test_readable_full_impact(showcase)
	_test_disabled_remains_presentation_only(showcase)

	showcase.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer showcase owner controls and visibility")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_owner_mode_controls(showcase: VoidbringerImpactShowcaseSandbox) -> void:
	_send_key(showcase, KEY_8)
	_expect(showcase.presentation_settings.effective_mode() == &"reduced", "Number-row 8 must select Reduced mode")
	_send_key(showcase, KEY_9)
	_expect(showcase.presentation_settings.effective_mode() == &"disabled", "Number-row 9 must select Disabled mode")
	_send_key(showcase, KEY_7)
	_expect(showcase.presentation_settings.effective_mode() == &"full", "Number-row 7 must select Full mode")
	_send_button(showcase, JOY_BUTTON_DPAD_UP)
	_expect(showcase.presentation_settings.effective_mode() == &"reduced", "D-pad Up must select Reduced mode")
	_send_button(showcase, JOY_BUTTON_DPAD_RIGHT)
	_expect(showcase.presentation_settings.effective_mode() == &"disabled", "D-pad Right must select Disabled mode")
	_send_button(showcase, JOY_BUTTON_DPAD_LEFT)
	_expect(showcase.presentation_settings.effective_mode() == &"full", "D-pad Left must select Full mode")


func _test_owner_hud_and_camera(showcase: VoidbringerImpactShowcaseSandbox) -> void:
	var label := showcase.showcase_label
	_expect(is_instance_valid(label), "Showcase must expose an owner-facing presentation HUD")
	if is_instance_valid(label):
		_expect(is_equal_approx(label.anchor_left, 1.0) and is_equal_approx(label.anchor_right, 1.0), "Showcase HUD must anchor to the viewport right edge")
		_expect(label.offset_left < 0.0 and label.offset_right < 0.0, "Showcase HUD offsets must remain inside the right edge")
		_expect(label.text.contains("7 FULL") and label.text.contains("9 DISABLED"), "Showcase HUD must advertise practical number-row controls")
	var camera := showcase.get_viewport().get_camera_3d()
	_expect(is_instance_valid(camera), "Showcase must have a current camera")
	if is_instance_valid(camera):
		_expect(camera.fov <= 60.0, "Showcase camera must be framed closely enough to judge impact")


func _test_readable_full_impact(showcase: VoidbringerImpactShowcaseSandbox) -> void:
	_send_key(showcase, KEY_7)
	_send_key(showcase, KEY_Z)
	var elapsed := 0.0
	while elapsed < 1.5 and showcase.enemy_fixture.health == showcase.enemy_fixture.maximum_health:
		showcase.simulate_seconds(0.02, 0.02)
		elapsed += 0.02
	_expect(showcase.enemy_fixture.health == 80, "Owner combo shortcut must still commit the expected 20 damage")
	_expect(not showcase.contact_flashes.is_empty(), "Full impact must leave a visible flash long enough for owner judgment")
	if not showcase.contact_flashes.is_empty():
		var entry: Dictionary = showcase.contact_flashes.back()
		var flash_root := entry.get("node") as Node3D
		_expect(is_instance_valid(flash_root), "Full impact flash root must remain valid")
		if is_instance_valid(flash_root):
			_expect(flash_root.get_node_or_null("ShowcaseImpactShockRing") != null, "Full impact must include the readable shock ring")
			_expect(flash_root.get_node_or_null("ShowcaseImpactHalo") != null, "Full impact must include the readable impact halo")
			_expect(flash_root.get_node_or_null("ShowcaseImpactLight") != null, "Full impact must include a bounded impact light")
		_expect(float(entry.get("duration", 0.0)) >= 0.40, "Full impact flash must persist long enough to be seen")
	var audio := showcase.impact_audio.debug_snapshot()
	var last_audio := audio.get("last_audio_report", {}) as Dictionary
	_expect(StringName(str(last_audio.get("profile_id", ""))) == &"impact", "Full combo contact must route a real impact audio profile")


func _test_disabled_remains_presentation_only(showcase: VoidbringerImpactShowcaseSandbox) -> void:
	_send_key(showcase, KEY_9)
	_send_key(showcase, KEY_Z)
	var elapsed := 0.0
	while elapsed < 1.5 and showcase.enemy_fixture.health == showcase.enemy_fixture.maximum_health:
		showcase.simulate_seconds(0.02, 0.02)
		elapsed += 0.02
	_expect(showcase.enemy_fixture.health == 80, "Disabled presentation must preserve the exact combo damage")
	_expect(showcase.contact_flashes.is_empty(), "Disabled presentation must create zero showcase impact flashes")
	_expect(int(showcase.impact_audio.debug_snapshot().get("active_voice_count", -1)) == 0, "Disabled presentation must create zero active audio voices")


func _send_key(showcase: VoidbringerImpactShowcaseSandbox, keycode: int) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = keycode
	showcase._unhandled_input(event)


func _send_button(showcase: VoidbringerImpactShowcaseSandbox, button_index: int) -> void:
	var event := InputEventJoypadButton.new()
	event.pressed = true
	event.button_index = button_index
	showcase._unhandled_input(event)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
