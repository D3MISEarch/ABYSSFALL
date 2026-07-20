extends Control
class_name ClassSelectionScreen

signal class_confirmed(class_id: String)

const CHARACTER_FACTORY = preload("res://scripts/core/character_factory.gd")

var definitions: Array[Dictionary] = []
var card_buttons: Array[Button] = []
var selected_index := 0

var name_label: Label
var title_label: Label
var fantasy_label: Label
var resource_label: Label
var tags_label: Label
var difficulty_label: Label
var abilities_label: Label
var branches_label: Label
var strengths_label: Label
var risks_label: Label
var unlock_label: Label
var confirm_button: Button
var footer_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	definitions = CHARACTER_FACTORY.get_selection_definitions()
	_build_interface()
	_select_index(0)
	call_deferred("_focus_selected_card")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_left"):
		_select_index(_wrap_index(selected_index - 1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_select_index(_wrap_index(selected_index + 1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_confirm_selection()
		get_viewport().set_input_as_handled()


func select_class_id(class_id: String) -> void:
	for index in range(definitions.size()):
		if str(definitions[index].get("id", "")) == class_id:
			_select_index(index)
			return


func get_selected_definition() -> Dictionary:
	if definitions.is_empty():
		return {}
	return definitions[selected_index].duplicate(true)


func _build_interface() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.006, 0.004, 0.009, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var upper_glow := ColorRect.new()
	upper_glow.set_anchors_preset(Control.PRESET_TOP_WIDE)
	upper_glow.offset_bottom = 190.0
	upper_glow.color = Color(0.10, 0.018, 0.14, 0.30)
	upper_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(upper_glow)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var main_column := VBoxContainer.new()
	main_column.add_theme_constant_override("separation", 14)
	margin.add_child(main_column)

	var heading := Label.new()
	heading.text = "CHOOSE YOUR DESCENT"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 36)
	heading.modulate = Color(0.92, 0.86, 1.0)
	main_column.add_child(heading)

	var subheading := Label.new()
	subheading.text = "THE ABYSS REMEMBERS EVERY VESSEL"
	subheading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subheading.add_theme_font_size_override("font_size", 15)
	subheading.modulate = Color(0.50, 0.46, 0.58)
	main_column.add_child(subheading)

	var card_scroll := ScrollContainer.new()
	card_scroll.custom_minimum_size = Vector2(0.0, 235.0)
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	card_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_column.add_child(card_scroll)

	var card_row := HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 14)
	card_scroll.add_child(card_row)

	for index in range(definitions.size()):
		var definition := definitions[index]
		var card := Button.new()
		card.custom_minimum_size = Vector2(250.0, 215.0)
		card.focus_mode = Control.FOCUS_ALL
		card.text = _card_text(definition)
		card.alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_theme_font_size_override("font_size", 18)
		card.pressed.connect(_on_card_pressed.bind(index))
		card.focus_entered.connect(_on_card_focused.bind(index))
		card_row.add_child(card)
		card_buttons.append(card)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.13, 0.08, 0.16), 0.92))
	main_column.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 24)
	detail_margin.add_theme_constant_override("margin_right", 24)
	detail_margin.add_theme_constant_override("margin_top", 18)
	detail_margin.add_theme_constant_override("margin_bottom", 18)
	detail_panel.add_child(detail_margin)

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 7)
	detail_margin.add_child(details)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 31)
	details.add_child(name_label)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.modulate = Color(0.72, 0.67, 0.78)
	details.add_child(title_label)

	fantasy_label = _wrapping_label(17)
	fantasy_label.custom_minimum_size.y = 50.0
	details.add_child(fantasy_label)

	var detail_columns := HBoxContainer.new()
	detail_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_columns.add_theme_constant_override("separation", 28)
	details.add_child(detail_columns)

	var identity_column := VBoxContainer.new()
	identity_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_columns.add_child(identity_column)
	resource_label = _wrapping_label(16)
	identity_column.add_child(resource_label)
	difficulty_label = _wrapping_label(16)
	identity_column.add_child(difficulty_label)
	tags_label = _wrapping_label(16)
	identity_column.add_child(tags_label)
	branches_label = _wrapping_label(16)
	identity_column.add_child(branches_label)

	var kit_column := VBoxContainer.new()
	kit_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_columns.add_child(kit_column)
	abilities_label = _wrapping_label(16)
	kit_column.add_child(abilities_label)
	strengths_label = _wrapping_label(16)
	kit_column.add_child(strengths_label)
	risks_label = _wrapping_label(16)
	kit_column.add_child(risks_label)

	unlock_label = Label.new()
	unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unlock_label.add_theme_font_size_override("font_size", 18)
	unlock_label.modulate = Color(0.70, 0.16, 0.20)
	details.add_child(unlock_label)

	confirm_button = Button.new()
	confirm_button.custom_minimum_size = Vector2(0.0, 54.0)
	confirm_button.add_theme_font_size_override("font_size", 21)
	confirm_button.pressed.connect(_confirm_selection)
	main_column.add_child(confirm_button)

	footer_label = Label.new()
	footer_label.text = "← / → OR LEFT STICK: SELECT     ENTER / A: CONFIRM"
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_label.add_theme_font_size_override("font_size", 13)
	footer_label.modulate = Color(0.47, 0.44, 0.52)
	main_column.add_child(footer_label)


func _select_index(index: int) -> void:
	if definitions.is_empty():
		return
	selected_index = clampi(index, 0, definitions.size() - 1)
	var definition := definitions[selected_index]
	var accent: Color = definition.get("accent", Color(0.6, 0.2, 0.8))
	var secondary: Color = definition.get("secondary_accent", accent.lightened(0.2))
	var locked := bool(definition.get("locked", true))

	for card_index in range(card_buttons.size()):
		var card := card_buttons[card_index]
		var card_definition := definitions[card_index]
		var card_accent: Color = card_definition.get("accent", Color(0.2, 0.2, 0.2))
		var selected := card_index == selected_index
		card.add_theme_stylebox_override(
			"normal",
			_card_style(card_accent, selected, bool(card_definition.get("locked", true)))
		)
		card.add_theme_stylebox_override("hover", _card_style(card_accent.lightened(0.08), true, false))
		card.add_theme_stylebox_override("focus", _card_style(card_accent.lightened(0.14), true, false))
		card.modulate = Color.WHITE if selected else Color(0.66, 0.65, 0.70)

	name_label.text = str(definition.get("display_name", "Unknown")).to_upper()
	name_label.modulate = accent.lightened(0.20)
	title_label.text = str(definition.get("title", ""))
	title_label.modulate = secondary.lightened(0.10)
	fantasy_label.text = str(definition.get("fantasy", ""))
	resource_label.text = "RESOURCE\n%s" % str(definition.get("resource_name", "Unknown")).to_upper()
	difficulty_label.text = "DIFFICULTY\n%s" % str(definition.get("difficulty", "Unknown")).to_upper()
	tags_label.text = "COMBAT IDENTITY\n%s" % "  •  ".join(PackedStringArray(definition.get("tags", [])))
	branches_label.text = "SKILL PATHS\n%s" % "  •  ".join(PackedStringArray(definition.get("skill_branches", [])))
	abilities_label.text = "STARTING KIT\n%s" % "\n".join(PackedStringArray(definition.get("abilities", [])))
	strengths_label.text = "STRENGTHS\n%s" % str(definition.get("strengths", "Unknown"))
	risks_label.text = "RISKS\n%s" % str(definition.get("risks", "Unknown"))
	unlock_label.text = str(definition.get("unlock_hint", "")) if locked else ""
	confirm_button.disabled = locked
	confirm_button.text = "PATH SEALED" if locked else "ENTER THE ABYSS AS %s" % name_label.text
	confirm_button.add_theme_stylebox_override("normal", _confirm_style(accent, locked))
	confirm_button.add_theme_stylebox_override("hover", _confirm_style(accent.lightened(0.10), locked))

	_focus_selected_card()


func _confirm_selection() -> void:
	if definitions.is_empty():
		return
	var definition := definitions[selected_index]
	if bool(definition.get("locked", true)):
		return
	var class_id := str(definition.get("id", CHARACTER_FACTORY.DEFAULT_CLASS_ID))
	class_confirmed.emit(class_id)


func _on_card_pressed(index: int) -> void:
	if index == selected_index and not bool(definitions[index].get("locked", true)):
		_confirm_selection()
		return
	_select_index(index)


func _on_card_focused(index: int) -> void:
	if index != selected_index:
		_select_index(index)


func _focus_selected_card() -> void:
	if selected_index >= 0 and selected_index < card_buttons.size():
		card_buttons[selected_index].grab_focus()


func _wrap_index(index: int) -> int:
	if definitions.is_empty():
		return 0
	return posmod(index, definitions.size())


func _card_text(definition: Dictionary) -> String:
	var locked := bool(definition.get("locked", true))
	var name := str(definition.get("display_name", "Unknown")).to_upper()
	var title := str(definition.get("title", ""))
	var resource := str(definition.get("resource_name", ""))
	if locked:
		return "⛓\n%s\n\n%s\n\n[ SEALED ]" % [name, title]
	return "%s\n\n%s\n\nRESOURCE: %s" % [name, title, resource.to_upper()]


func _wrapping_label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = Color(0.80, 0.77, 0.84)
	return label


func _panel_style(border_color: Color, opacity: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.010, 0.020, opacity)
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _card_style(accent: Color, selected: bool, locked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base := Color(0.022, 0.015, 0.028, 0.98)
	if selected:
		base = Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 0.98)
	if locked:
		base = base.darkened(0.18)
	style.bg_color = base
	style.border_color = accent if selected else accent.darkened(0.45)
	style.set_border_width_all(3 if selected else 1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	return style


func _confirm_style(accent: Color, locked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.055, 0.95) if locked else Color(accent.r * 0.32, accent.g * 0.32, accent.b * 0.32, 0.96)
	style.border_color = Color(0.26, 0.24, 0.28) if locked else accent.lightened(0.18)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style
