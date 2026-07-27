extends SceneTree

const CONTROLLER_UI_INPUT_MAP = preload("res://scripts/core/controller_ui_input_map.gd")
const PLAYABLE_AIM_RESOLVER = preload("res://scripts/core/playable_aim_resolver.gd")
const INVENTORY_FOCUS_NAVIGATOR = preload("res://scripts/ui/inventory_focus_navigator.gd")
const CLASS_SELECTION_SCREEN = preload("res://scripts/ui/class_selection_screen.gd")
const VOID_WARLOCK_SCRIPT = preload("res://scripts/characters/void_warlock.gd")
const PENITENT_SCRIPT = preload("res://scripts/characters/penitent_playable.gd")

var failures: Array[String] = []
var confirmed_class := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_controller_ui_bindings()
	_test_character_selection_cross_confirm()
	_test_inventory_focus_navigation()
	_test_inventory_equip_and_unequip(VOID_WARLOCK_SCRIPT, "Void Warlock")
	_test_inventory_equip_and_unequip(PENITENT_SCRIPT, "Penitent")
	_test_controller_facing_retention()
	if failures.is_empty():
		print("PASS: Controller UI and facing regression")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_controller_ui_bindings() -> void:
	CONTROLLER_UI_INPUT_MAP.install_defaults()
	CONTROLLER_UI_INPUT_MAP.install_defaults()
	_expect(_has_joy_button(&"ui_accept", JOY_BUTTON_A), "Cross/A should map to ui_accept")
	_expect(_has_joy_button(&"ui_cancel", JOY_BUTTON_B), "Circle/B should map to ui_cancel")
	_expect(_has_joy_button(&"ui_left", JOY_BUTTON_DPAD_LEFT), "D-pad left should map to ui_left")
	_expect(_has_joy_button(&"ui_right", JOY_BUTTON_DPAD_RIGHT), "D-pad right should map to ui_right")
	_expect(_has_joy_axis(&"ui_left", JOY_AXIS_LEFT_X, -1.0), "Left stick should navigate ui_left")
	_expect(_has_joy_axis(&"ui_down", JOY_AXIS_LEFT_Y, 1.0), "Left stick should navigate ui_down")
	_expect(_joy_event_count(&"ui_accept") == 1, "Repeated installation must not duplicate Cross/A")


func _test_character_selection_cross_confirm() -> void:
	confirmed_class = ""
	var screen := CLASS_SELECTION_SCREEN.new() as ClassSelectionScreen
	screen.class_confirmed.connect(_on_class_confirmed)
	root.add_child(screen)
	var cross := InputEventJoypadButton.new()
	cross.button_index = JOY_BUTTON_A
	cross.pressed = true
	_expect(cross.is_action_pressed("ui_accept"), "Cross/A event should resolve as ui_accept")
	screen._unhandled_input(cross)
	_expect(confirmed_class == "void_warlock", "Cross/A should confirm the unlocked opening class")
	screen.queue_free()


func _test_inventory_focus_navigation() -> void:
	var host := Control.new()
	root.add_child(host)
	var equipment: Array[Button] = []
	var backpack: Array[Button] = []
	for key in ["equipment:Weapon", "equipment:Hood"]:
		var button := _focus_button(key)
		host.add_child(button)
		equipment.append(button)
	for key in ["backpack:0", "backpack:1", "backpack:2"]:
		var button := _focus_button(key)
		host.add_child(button)
		backpack.append(button)
	INVENTORY_FOCUS_NAVIGATOR.wire_columns(equipment, backpack)
	_expect(
		equipment[0].focus_neighbor_right == equipment[0].get_path_to(backpack[0]),
		"Equipment should navigate right into the backpack"
	)
	_expect(
		backpack[1].focus_neighbor_left == backpack[1].get_path_to(equipment[1]),
		"Backpack should navigate left into equipped slots"
	)
	_expect(
		backpack[0].focus_neighbor_bottom == backpack[0].get_path_to(backpack[1]),
		"Backpack vertical navigation should be deterministic"
	)
	_expect(
		INVENTORY_FOCUS_NAVIGATOR.choose_focus(equipment, backpack, "equipment:Hood") == equipment[1],
		"Inventory refresh should restore the preferred equipped-slot focus"
	)
	_expect(
		INVENTORY_FOCUS_NAVIGATOR.choose_focus(equipment, backpack, "missing") == backpack[0],
		"Inventory should initially focus the first backpack item"
	)
	host.queue_free()


func _test_inventory_equip_and_unequip(character_script: Script, label: String) -> void:
	var character = character_script.new()
	var item := {
		"id": "controller_test_weapon",
		"name": "Controller Test Weapon",
		"slot": "Weapon",
		"rarity": "Magic",
		"description": "Regression fixture",
		"stats": {},
	}
	character.backpack.append(item.duplicate(true))
	_expect(character.equip_inventory_index(0), "%s should equip a focused backpack item" % label)
	_expect(not character.equipment["Weapon"].is_empty(), "%s equipment slot should receive the item" % label)
	_expect(character.unequip_slot("Weapon"), "%s should unequip a focused equipment slot" % label)
	_expect(character.equipment["Weapon"].is_empty(), "%s slot should be empty after unequip" % label)
	_expect(character.backpack.size() == 1, "%s unequip should return the item to the backpack" % label)
	character.free()


func _test_controller_facing_retention() -> void:
	var initial := Vector3(0.0, 0.0, -1.0)
	var aimed := PLAYABLE_AIM_RESOLVER.resolve_facing(
		initial,
		Vector3.ZERO,
		Vector2(1.0, 0.0),
		true
	)
	_expect(aimed.is_equal_approx(Vector3(1.0, 0.0, 0.0)), "Right-stick aim should control facing")
	var retained := PLAYABLE_AIM_RESOLVER.resolve_facing(
		aimed,
		Vector3.ZERO,
		Vector2.ZERO,
		true,
		Vector3(-1.0, 0.0, 0.0),
		true
	)
	_expect(retained.is_equal_approx(aimed), "Neutral controller sticks must retain the last facing")
	var moved := PLAYABLE_AIM_RESOLVER.resolve_facing(
		retained,
		Vector3(0.0, 0.0, 1.0),
		Vector2.ZERO,
		true
	)
	_expect(moved.is_equal_approx(Vector3(0.0, 0.0, 1.0)), "Controller movement should update facing when not aiming")
	var mouse_facing := PLAYABLE_AIM_RESOLVER.resolve_facing(
		moved,
		Vector3.ZERO,
		Vector2.ZERO,
		false,
		Vector3(-1.0, 0.0, 0.0),
		true
	)
	_expect(mouse_facing.is_equal_approx(Vector3(-1.0, 0.0, 0.0)), "Mouse authority should continue updating facing")


func _focus_button(key: String) -> Button:
	var button := Button.new()
	button.set_meta("inventory_focus_key", key)
	button.focus_mode = Control.FOCUS_ALL
	return button


func _on_class_confirmed(class_id: String) -> void:
	confirmed_class = class_id


func _joy_event_count(action_name: StringName) -> int:
	var count := 0
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			count += 1
	return count


func _has_joy_button(action_name: StringName, button_index: JoyButton) -> bool:
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button_index:
			return true
	return false


func _has_joy_axis(action_name: StringName, axis: JoyAxis, axis_value: float) -> bool:
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			if motion.axis == axis and is_equal_approx(motion.axis_value, axis_value):
				return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
