extends Control
class_name GameplayPauseMenu

signal resume_requested
signal save_continue_requested
signal save_exit_requested

var resume_button: Button
var save_continue_button: Button
var save_exit_button: Button
var status_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	visible = false


func open_menu() -> void:
	visible = true
	show_status("")
	call_deferred("focus_initial")


func close_menu() -> void:
	visible = false


func focus_initial() -> void:
	if resume_button != null:
		resume_button.grab_focus()


func set_busy(busy: bool) -> void:
	resume_button.disabled = busy
	save_continue_button.disabled = busy
	save_exit_button.disabled = busy


func show_status(message: String, failed: bool = false) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.30, 0.32) if failed else Color(0.58, 0.92, 0.64)


func _build_interface() -> void:
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.78)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500.0, 430.0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var heading := Label.new()
	heading.text = "DESCENT PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 34)
	column.add_child(heading)

	resume_button = _button("RESUME")
	resume_button.pressed.connect(func(): resume_requested.emit())
	column.add_child(resume_button)

	save_continue_button = _button("SAVE & CONTINUE")
	save_continue_button.pressed.connect(func(): save_continue_requested.emit())
	column.add_child(save_continue_button)

	save_exit_button = _button("SAVE & EXIT TO MENU")
	save_exit_button.pressed.connect(func(): save_exit_requested.emit())
	column.add_child(save_exit_button)

	var settings := _button("SETTINGS — COMING LATER")
	settings.disabled = true
	column.add_child(settings)

	status_label = Label.new()
	status_label.custom_minimum_size.y = 30.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	column.add_child(status_label)

	var footer := Label.new()
	footer.text = "ESC / START: RESUME     ENTER / A: SELECT"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.modulate = Color(0.46, 0.43, 0.50)
	column.add_child(footer)


func _button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 50.0
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	return button
