extends Control
class_name FrontEndScreen

signal continue_requested
signal new_character_requested
signal select_build_requested
signal quit_requested

var continue_button: Button
var new_character_button: Button
var select_button: Button
var settings_button: Button
var quit_button: Button
var build_summary_label: Label
var status_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()
	call_deferred("focus_initial")


func configure(selected_summary: Dictionary, build_count: int) -> void:
	if continue_button == null:
		_build_interface()
	var has_build := not selected_summary.is_empty()
	continue_button.disabled = not has_build
	select_button.disabled = build_count <= 0
	if has_build:
		build_summary_label.text = (
			"CONTINUE\n%s\n%s  •  LEVEL %d\nLAST PLAYED %s"
			% [
				str(selected_summary.get("build_name", "Unnamed Build")).to_upper(),
				str(selected_summary.get("class_name", "Unknown")).to_upper(),
				int(selected_summary.get("level", 1)),
				str(selected_summary.get("last_played_text", "Never")),
			]
		)
	else:
		build_summary_label.text = "NO AWAKENED CHARACTER\nBEGIN A NEW DESCENT"
	call_deferred("focus_initial")


func show_status(message: String, failed: bool = false) -> void:
	if status_label == null:
		return
	status_label.text = message
	status_label.modulate = Color(1.0, 0.30, 0.32) if failed else Color(0.58, 0.92, 0.64)


func focus_initial() -> void:
	if continue_button != null and not continue_button.disabled:
		continue_button.grab_focus()
	elif new_character_button != null:
		new_character_button.grab_focus()


func _build_interface() -> void:
	if continue_button != null:
		return
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.005, 0.004, 0.009, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var glow := ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.position = Vector2(-430.0, -300.0)
	glow.size = Vector2(860.0, 600.0)
	glow.color = Color(0.13, 0.015, 0.19, 0.24)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(620.0, 0.0)
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)

	var title := Label.new()
	title.text = "ABYSSFALL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.modulate = Color(0.91, 0.84, 1.0)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "THE ABYSS REMEMBERS WHAT YOU CARRY"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.modulate = Color(0.48, 0.44, 0.55)
	column.add_child(subtitle)

	build_summary_label = Label.new()
	build_summary_label.custom_minimum_size = Vector2(0.0, 112.0)
	build_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	build_summary_label.add_theme_font_size_override("font_size", 18)
	build_summary_label.modulate = Color(0.78, 0.70, 0.86)
	column.add_child(build_summary_label)

	continue_button = _menu_button("CONTINUE")
	continue_button.pressed.connect(func(): continue_requested.emit())
	column.add_child(continue_button)

	new_character_button = _menu_button("NEW CHARACTER")
	new_character_button.pressed.connect(func(): new_character_requested.emit())
	column.add_child(new_character_button)

	select_button = _menu_button("SELECT CHARACTER")
	select_button.pressed.connect(func(): select_build_requested.emit())
	column.add_child(select_button)

	settings_button = _menu_button("SETTINGS — COMING LATER")
	settings_button.disabled = true
	column.add_child(settings_button)

	quit_button = _menu_button("QUIT")
	quit_button.pressed.connect(func(): quit_requested.emit())
	column.add_child(quit_button)

	status_label = Label.new()
	status_label.custom_minimum_size.y = 26.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	column.add_child(status_label)

	var footer := Label.new()
	footer.text = "ARROWS / LEFT STICK: MOVE     ENTER / A: SELECT"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	footer.modulate = Color(0.42, 0.39, 0.47)
	column.add_child(footer)


func _menu_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0.0, 50.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 18)
	return button
