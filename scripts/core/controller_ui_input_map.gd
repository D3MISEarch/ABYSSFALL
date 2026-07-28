extends RefCounted
class_name ControllerUiInputMap


static func install_defaults() -> void:
	_replace_joypad_bindings(&"ui_accept", [JOY_BUTTON_A], [])
	_replace_joypad_bindings(&"ui_cancel", [JOY_BUTTON_B], [])
	_replace_joypad_bindings(
		&"ui_left",
		[JOY_BUTTON_DPAD_LEFT],
		[{"axis": JOY_AXIS_LEFT_X, "value": -1.0}]
	)
	_replace_joypad_bindings(
		&"ui_right",
		[JOY_BUTTON_DPAD_RIGHT],
		[{"axis": JOY_AXIS_LEFT_X, "value": 1.0}]
	)
	_replace_joypad_bindings(
		&"ui_up",
		[JOY_BUTTON_DPAD_UP],
		[{"axis": JOY_AXIS_LEFT_Y, "value": -1.0}]
	)
	_replace_joypad_bindings(
		&"ui_down",
		[JOY_BUTTON_DPAD_DOWN],
		[{"axis": JOY_AXIS_LEFT_Y, "value": 1.0}]
	)


static func _replace_joypad_bindings(
	action_name: StringName,
	buttons: Array,
	axes: Array
) -> void:
	_ensure_action(action_name)
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			InputMap.action_erase_event(action_name, event)
	for raw_button: Variant in buttons:
		var button_event := InputEventJoypadButton.new()
		button_event.button_index = int(raw_button)
		InputMap.action_add_event(action_name, button_event)
	for raw_axis: Variant in axes:
		if not raw_axis is Dictionary:
			continue
		var axis_binding := raw_axis as Dictionary
		var axis_event := InputEventJoypadMotion.new()
		axis_event.axis = int(axis_binding.get("axis", JOY_AXIS_LEFT_X))
		axis_event.axis_value = float(axis_binding.get("value", 0.0))
		InputMap.action_add_event(action_name, axis_event)


static func _ensure_action(action_name: StringName) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)
