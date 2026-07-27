extends RefCounted
class_name InventoryFocusNavigator


static func wire_columns(
	equipment_buttons: Array[Button],
	backpack_buttons: Array[Button]
) -> void:
	_wire_vertical(equipment_buttons)
	_wire_vertical(backpack_buttons)
	_wire_cross_column(equipment_buttons, backpack_buttons, true)
	_wire_cross_column(backpack_buttons, equipment_buttons, false)
	var linear: Array[Button] = []
	linear.append_array(equipment_buttons)
	linear.append_array(backpack_buttons)
	for index in range(linear.size()):
		var button := linear[index]
		if index > 0:
			button.focus_previous = button.get_path_to(linear[index - 1])
		if index + 1 < linear.size():
			button.focus_next = button.get_path_to(linear[index + 1])


static func choose_focus(
	equipment_buttons: Array[Button],
	backpack_buttons: Array[Button],
	preferred_key: String
) -> Button:
	var all_buttons: Array[Button] = []
	all_buttons.append_array(equipment_buttons)
	all_buttons.append_array(backpack_buttons)
	for button: Button in all_buttons:
		if str(button.get_meta("inventory_focus_key", "")) == preferred_key:
			return button
	if not backpack_buttons.is_empty():
		return backpack_buttons[0]
	if not equipment_buttons.is_empty():
		return equipment_buttons[0]
	return null


static func prepare_scroll(scroll: ScrollContainer) -> void:
	if not is_instance_valid(scroll):
		return
	# Inventory is a two-column controller surface, not a horizontally panning
	# document. Keep focus-following vertical only so long labels can never push
	# either column sideways and hide the beginning of item descriptions.
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_horizontal = 0


static func reveal(scroll: ScrollContainer, control: Control) -> void:
	if not is_instance_valid(scroll) or not is_instance_valid(control):
		return
	scroll.scroll_horizontal = 0
	scroll.ensure_control_visible(control)
	scroll.scroll_horizontal = 0


static func _wire_vertical(buttons: Array[Button]) -> void:
	for index in range(buttons.size()):
		var button := buttons[index]
		if index > 0:
			button.focus_neighbor_top = button.get_path_to(buttons[index - 1])
		if index + 1 < buttons.size():
			button.focus_neighbor_bottom = button.get_path_to(buttons[index + 1])


static func _wire_cross_column(
	source_buttons: Array[Button],
	target_buttons: Array[Button],
	target_is_right: bool
) -> void:
	if target_buttons.is_empty():
		return
	for index in range(source_buttons.size()):
		var source := source_buttons[index]
		var target := target_buttons[mini(index, target_buttons.size() - 1)]
		var path := source.get_path_to(target)
		if target_is_right:
			source.focus_neighbor_right = path
		else:
			source.focus_neighbor_left = path