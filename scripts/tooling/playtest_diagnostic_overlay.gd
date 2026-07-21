extends CanvasLayer
class_name PlaytestDiagnosticOverlay

const BUILD_IDENTITY = preload("res://scripts/tooling/build_identity.gd")
const INPUT_PROMPT_PROFILE = preload("res://scripts/ui/input_prompt_profile.gd")
const PLAYTEST_REPORT = preload("res://scripts/tooling/playtest_report.gd")

var panel: PanelContainer
var details: Label
var report_status: Label
var active_input_profile := INPUT_PROMPT_PROFILE.KEYBOARD_MOUSE
var last_report_result: Dictionary = {}


func _ready() -> void:
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	active_input_profile = INPUT_PROMPT_PROFILE.connected_profile()
	_build_ui()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			panel.visible = not panel.visible
			if panel.visible:
				_refresh()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F8:
			_capture_report()
			get_viewport().set_input_as_handled()
			return

	_update_active_profile(event)


func _update_active_profile(event: InputEvent) -> void:
	var detected_profile := INPUT_PROMPT_PROFILE.profile_for_event(event)
	if detected_profile.is_empty() or detected_profile == active_input_profile:
		return
	active_input_profile = detected_profile
	if is_instance_valid(panel) and panel.visible:
		_refresh()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "PlaytestDiagnostics"
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(18.0, 18.0)
	panel.custom_minimum_size = Vector2(560.0, 0.0)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	details = Label.new()
	details.name = "DiagnosticText"
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 16)
	content.add_child(details)

	report_status = Label.new()
	report_status.name = "ReportStatus"
	report_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report_status.add_theme_font_size_override("font_size", 14)
	report_status.text = "F8 saves a timestamped playtest report."
	content.add_child(report_status)


func _controller_lines() -> Array[String]:
	var device_lines: Array[String] = []
	for device_id in Input.get_connected_joypads():
		var joy_name := Input.get_joy_name(device_id)
		var hardware_profile := INPUT_PROMPT_PROFILE.profile_for_joy_name(joy_name)
		device_lines.append("%d: %s [%s]" % [device_id, joy_name, hardware_profile])
	return device_lines


func _refresh() -> void:
	if not is_instance_valid(details):
		return
	var identity := BUILD_IDENTITY.load_current()
	var device_lines := _controller_lines()
	if device_lines.is_empty():
		device_lines.append("none")

	details.text = "PLAYTEST DIAGNOSTICS (F3)\nBuild: %s\nCommit: %s\nBranch: %s\nWorkflow: %s\nActive input profile: %s\nConnected controllers:\n- %s" % [
		BUILD_IDENTITY.display_line(identity),
		str(identity.get("commit", "unknown")),
		str(identity.get("branch", "unknown")),
		str(identity.get("workflow_run", "unknown")),
		active_input_profile,
		"\n- ".join(device_lines),
	]


func _capture_report(filename_stem: String = "") -> Dictionary:
	var identity := BUILD_IDENTITY.load_current()
	var scene_name := "none"
	if is_instance_valid(get_tree().current_scene):
		scene_name = get_tree().current_scene.name
	var report_text := PLAYTEST_REPORT.build_text(
		identity,
		active_input_profile,
		_controller_lines(),
		scene_name,
		Engine.get_frames_per_second()
	)
	last_report_result = PLAYTEST_REPORT.save_text(report_text, filename_stem)
	if is_instance_valid(report_status):
		if bool(last_report_result.get("ok", false)):
			report_status.text = "Report saved: %s" % str(last_report_result.get("absolute_path", ""))
		else:
			report_status.text = "Report failed: %s" % str(last_report_result.get("error", "unknown error"))
	if not panel.visible:
		panel.visible = true
		_refresh()
	return last_report_result


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh()
