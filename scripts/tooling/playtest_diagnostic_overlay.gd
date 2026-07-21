extends CanvasLayer
class_name PlaytestDiagnosticOverlay

const BUILD_IDENTITY = preload("res://scripts/tooling/build_identity.gd")
const INPUT_PROMPT_PROFILE = preload("res://scripts/ui/input_prompt_profile.gd")

var panel: PanelContainer
var details: Label


func _ready() -> void:
	layer = 1000
	_process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		panel.visible = not panel.visible
		if panel.visible:
			_refresh()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.name = "PlaytestDiagnostics"
	panel.visible = false
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(18.0, 18.0)
	panel.custom_minimum_size = Vector2(520.0, 0.0)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	details = Label.new()
	details.name = "DiagnosticText"
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 16)
	margin.add_child(details)


func _refresh() -> void:
	if not is_instance_valid(details):
		return
	var identity := BUILD_IDENTITY.load_current()
	var joypads := Input.get_connected_joypads()
	var device_lines: Array[String] = []
	for device_id in joypads:
		device_lines.append("%d: %s" % [device_id, Input.get_joy_name(device_id)])
	if device_lines.is_empty():
		device_lines.append("none")

	var profile := INPUT_PROMPT_PROFILE.connected_profile()
	details.text = "PLAYTEST DIAGNOSTICS (F3)\nBuild: %s\nCommit: %s\nBranch: %s\nWorkflow: %s\nInput profile: %s\nConnected controllers:\n- %s" % [
		BUILD_IDENTITY.display_line(identity),
		str(identity.get("commit", "unknown")),
		str(identity.get("branch", "unknown")),
		str(identity.get("workflow_run", "unknown")),
		profile,
		"\n- ".join(device_lines),
	]


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh()
