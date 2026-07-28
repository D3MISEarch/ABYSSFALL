extends Control
class_name BuildSelectionScreen

signal build_confirmed(build_id: String)
signal back_requested

var summaries: Array[Dictionary] = []
var build_buttons: Array[Button] = []
var selected_index := 0
var details_label: Label
var confirm_button: Button
var status_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_interface()


func configure(new_summaries: Array[Dictionary]) -> void:
	summaries = new_summaries.duplicate(true)
	_rebuild_buttons()
	if not summaries.is_empty():
		_select_index(0)
		call_deferred("focus_initial")


func focus_initial() -> void:
	if not build_buttons.is_empty():
		build_buttons[selected_index].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu_close"):
		back_requested.emit()
		get_viewport().set_input_as_handled()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.006, 0.004, 0.009, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var heading := Label.new()
	heading.text = "SELECT CHARACTER"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 38)
	heading.modulate = Color(0.92, 0.86, 1.0)
	column.add_child(heading)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	column.add_child(body)

	var list_scroll := ScrollContainer.new()
	list_scroll.custom_minimum_size.x = 470.0
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(list_scroll)

	var list_box := VBoxContainer.new()
	list_box.name = "BuildList"
	list_box.custom_minimum_size.x = 450.0
	list_box.add_theme_constant_override("separation", 9)
	list_scroll.add_child(list_box)

	var details_panel := PanelContainer.new()
	details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(details_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 24)
	detail_margin.add_theme_constant_override("margin_right", 24)
	detail_margin.add_theme_constant_override("margin_top", 22)
	detail_margin.add_theme_constant_override("margin_bottom", 22)
	details_panel.add_child(detail_margin)

	details_label = Label.new()
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.add_theme_font_size_override("font_size", 19)
	detail_margin.add_child(details_label)

	confirm_button = Button.new()
	confirm_button.text = "CONTINUE WITH SELECTED CHARACTER"
	confirm_button.custom_minimum_size.y = 52.0
	confirm_button.add_theme_font_size_override("font_size", 18)
	confirm_button.pressed.connect(_confirm)
	column.add_child(confirm_button)

	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size.y = 44.0
	back.pressed.connect(func(): back_requested.emit())
	column.add_child(back)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.modulate = Color(0.48, 0.44, 0.55)
	column.add_child(status_label)


func _rebuild_buttons() -> void:
	build_buttons.clear()
	var list_box := find_child("BuildList", true, false) as VBoxContainer
	if list_box == null:
		return
	for child in list_box.get_children():
		list_box.remove_child(child)
		child.queue_free()
	if summaries.is_empty():
		var empty := Label.new()
		empty.text = "NO VALID CHARACTERS FOUND"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size", 18)
		list_box.add_child(empty)
		confirm_button.disabled = true
		return
	confirm_button.disabled = false
	for index in range(summaries.size()):
		var summary := summaries[index]
		var marker := "  •  ACTIVE" if bool(summary.get("selected", false)) else ""
		var button := Button.new()
		button.custom_minimum_size = Vector2(440.0, 78.0)
		button.focus_mode = Control.FOCUS_ALL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s%s\n%s  •  LEVEL %d" % [
			str(summary.get("build_name", "Unnamed Build")).to_upper(),
			marker,
			str(summary.get("class_name", "Unknown")).to_upper(),
			int(summary.get("level", 1)),
		]
		button.pressed.connect(_on_button_pressed.bind(index))
		button.focus_entered.connect(_select_index.bind(index))
		list_box.add_child(button)
		build_buttons.append(button)


func _select_index(index: int) -> void:
	if summaries.is_empty():
		return
	selected_index = clampi(index, 0, summaries.size() - 1)
	var summary := summaries[selected_index]
	details_label.text = "%s\n\nCLASS\n%s\n\nLEVEL\n%d\n\nEXPERIENCE\n%d\n\nLAST PLAYED\n%s" % [
		str(summary.get("build_name", "Unnamed Build")).to_upper(),
		str(summary.get("class_name", "Unknown")).to_upper(),
		int(summary.get("level", 1)),
		int(summary.get("experience", 0)),
		str(summary.get("last_played_text", "Never")),
	]


func _on_button_pressed(index: int) -> void:
	if index == selected_index:
		_confirm()
	else:
		_select_index(index)


func _confirm() -> void:
	if summaries.is_empty():
		return
	build_confirmed.emit(str(summaries[selected_index].get("build_id", "")))
