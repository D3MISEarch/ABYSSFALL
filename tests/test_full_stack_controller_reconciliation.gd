extends SceneTree

const CONTROLLER_UI_INPUT_MAP = preload("res://scripts/core/controller_ui_input_map.gd")
const PLAYABLE_AIM_RESOLVER = preload("res://scripts/core/playable_aim_resolver.gd")
const INVENTORY_FOCUS_NAVIGATOR = preload("res://scripts/ui/inventory_focus_navigator.gd")
const PROGRESSION_BRIDGE_SCRIPT = preload("res://scripts/ui/playable_progression_bridge.gd")
const INVENTORY_BRIDGE_SCRIPT = preload("res://scripts/ui/playable_inventory_bridge.gd")
const PLAYABLE_ITEM_CATALOG = preload("res://scripts/core/playable_item_catalog.gd")
const VOID_WARLOCK_SCRIPT = preload("res://scripts/characters/void_warlock.gd")
const PENITENT_SCRIPT = preload("res://scripts/characters/penitent_playable.gd")
const FULL_STACK_MAIN_SCRIPT = preload("res://scripts/full_stack_controller_main.gd")
const GAMEPLAY_SCENE = preload("res://gameplay.tscn")

class InventoryLayoutPlayer:
	extends Node

	func get_inventory_snapshot() -> Dictionary:
		var long_item := PLAYABLE_ITEM_CATALOG.item_data(&"wretch_bell")
		long_item["description"] = (
			"A deliberately long inventory description that must wrap inside the backpack "
			+ "column instead of widening the ScrollContainer and hiding its opening words."
		)
		return {
			"equipment": {
				"Weapon": PLAYABLE_ITEM_CATALOG.item_data(&"void_scepter"),
				"Hood": {},
				"Chest": {},
				"Gloves": {},
				"Boots": {},
				"Relic": {},
			},
			"backpack": [long_item],
			"capacity": 12,
		}

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_scene_routes_preserve_full_stack()
	_test_controller_actions_and_start_pause()
	_test_controller_facing_retention()
	await _test_inventory_navigation_scrolls_with_focus()
	_test_real_inventory_layout_wraps_without_horizontal_overflow()
	_test_durable_unequip_transaction()
	_test_both_classes_expose_unequip()
	if failures.is_empty():
		print("PASS: Full-stack controller reconciliation")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_scene_routes_preserve_full_stack() -> void:
	var main_scene_text := FileAccess.get_file_as_string("res://main.tscn")
	var gameplay := GAMEPLAY_SCENE.instantiate()
	_expect(
		main_scene_text.contains("res://scripts/boot.gd"),
		"Main scene should preserve the original full-stack front end"
	)
	_expect(
		str(ProjectSettings.get_setting("autoload/ControllerUiBootstrap", ""))
		== "*res://scripts/controller_ui_bootstrap.gd",
		"Controller UI mappings should install through an early autoload"
	)
	_expect(
		str(gameplay.get_script().resource_path) == "res://scripts/full_stack_controller_main.gd",
		"Gameplay scene should preserve the stacked runtime through the reconciled controller layer"
	)
	gameplay.free()


func _test_controller_actions_and_start_pause() -> void:
	CONTROLLER_UI_INPUT_MAP.install_defaults()
	CONTROLLER_UI_INPUT_MAP.install_defaults()
	var gameplay = FULL_STACK_MAIN_SCRIPT.new()
	gameplay._install_input_map()
	_expect(_has_joy_button(&"ui_accept", JOY_BUTTON_A), "Cross / A should activate focused UI")
	_expect(_has_joy_button(&"ui_cancel", JOY_BUTTON_B), "Circle / B should cancel focused UI")
	_expect(_has_joy_button(&"ui_up", JOY_BUTTON_DPAD_UP), "D-pad up should navigate focused UI")
	_expect(_has_joy_axis(&"ui_down", JOY_AXIS_LEFT_Y, 1.0), "Left stick should navigate focused UI")
	_expect(_has_joy_button(&"menu_close", JOY_BUTTON_START), "Options / Start should open and close the pause menu")
	_expect(_joy_event_count(&"ui_accept") == 1, "Repeated UI-map installation must not duplicate Cross / A")
	gameplay.free()


func _test_controller_facing_retention() -> void:
	var initial := Vector3(0.0, 0.0, -1.0)
	var aimed := PLAYABLE_AIM_RESOLVER.resolve_facing(initial, Vector3.ZERO, Vector2(1.0, 0.0), true)
	_expect(aimed.is_equal_approx(Vector3(1.0, 0.0, 0.0)), "Right-stick aim should control facing")
	var retained := PLAYABLE_AIM_RESOLVER.resolve_facing(
		aimed,
		Vector3.ZERO,
		Vector2.ZERO,
		true,
		Vector3(-1.0, 0.0, 0.0),
		true
	)
	_expect(retained.is_equal_approx(aimed), "Neutral controller sticks should retain the last facing")
	var moved := PLAYABLE_AIM_RESOLVER.resolve_facing(retained, Vector3(0.0, 0.0, 1.0), Vector2.ZERO, true)
	_expect(moved.is_equal_approx(Vector3(0.0, 0.0, 1.0)), "Movement should update controller facing when not aiming")
	var mouse_facing := PLAYABLE_AIM_RESOLVER.resolve_facing(
		moved,
		Vector3.ZERO,
		Vector2.ZERO,
		false,
		Vector3(-1.0, 0.0, 0.0),
		true
	)
	_expect(mouse_facing.is_equal_approx(Vector3(-1.0, 0.0, 0.0)), "Real mouse input should regain aim authority")


func _test_inventory_navigation_scrolls_with_focus() -> void:
	var host := Control.new()
	host.size = Vector2(700.0, 400.0)
	root.add_child(host)
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(320.0, 170.0)
	host.add_child(scroll)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(290.0, 0.0)
	scroll.add_child(column)
	var buttons: Array[Button] = []
	for index in range(9):
		var button := Button.new()
		button.text = "Inventory Item %d" % index
		button.custom_minimum_size = Vector2(280.0, 62.0)
		button.focus_mode = Control.FOCUS_ALL
		button.set_meta("inventory_focus_key", "backpack:%d" % index)
		column.add_child(button)
		buttons.append(button)
	INVENTORY_FOCUS_NAVIGATOR.prepare_scroll(scroll)
	INVENTORY_FOCUS_NAVIGATOR.wire_columns([], buttons)
	await process_frame
	await process_frame
	scroll.scroll_horizontal = 120
	buttons[buttons.size() - 1].grab_focus()
	INVENTORY_FOCUS_NAVIGATOR.reveal(scroll, buttons[buttons.size() - 1])
	await process_frame
	await process_frame
	_expect(scroll.follow_focus, "Inventory ScrollContainer should follow controller focus")
	_expect(scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Inventory must disable horizontal scrolling")
	_expect(scroll.scroll_horizontal == 0, "Controller focus must never shift an inventory column sideways")
	_expect(scroll.scroll_vertical > 0, "Focusing a lower inventory item should scroll it into view")
	_expect(
		buttons[0].focus_neighbor_bottom == buttons[0].get_path_to(buttons[1]),
		"Inventory D-pad navigation should have deterministic vertical neighbors"
	)
	host.free()


func _test_real_inventory_layout_wraps_without_horizontal_overflow() -> void:
	var gameplay = FULL_STACK_MAIN_SCRIPT.new()
	var layout_player := InventoryLayoutPlayer.new()
	gameplay.player = layout_player
	gameplay._build_hud()
	gameplay._refresh_inventory()
	var backpack_scroll := gameplay.inventory_backpack_box.get_parent() as ScrollContainer
	var equipment_scroll := gameplay.inventory_equipment_box.get_parent() as ScrollContainer
	_expect(backpack_scroll != null and equipment_scroll != null, "Real inventory should retain both scroll columns")
	if backpack_scroll != null:
		_expect(backpack_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Backpack should be vertical-only")
		_expect(backpack_scroll.scroll_horizontal == 0, "Backpack should remain pinned to its left edge")
	if equipment_scroll != null:
		_expect(equipment_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Equipment should be vertical-only")
	var backpack_children: Array[Node] = gameplay.inventory_backpack_box.get_children()
	_expect(backpack_children.size() >= 2, "Real inventory fixture should build a heading and item")
	if backpack_children.size() >= 2:
		var heading := backpack_children[0] as Label
		var item_button := backpack_children[1] as Button
		_expect(heading != null and heading.autowrap_mode != TextServer.AUTOWRAP_OFF, "Backpack heading should wrap inside its column")
		_expect(item_button != null and item_button.autowrap_mode != TextServer.AUTOWRAP_OFF, "Item descriptions should wrap inside the backpack")
		if item_button != null:
			_expect(is_zero_approx(item_button.custom_minimum_size.x), "Backpack items must not force a wider horizontal canvas")
	gameplay.free()
	layout_player.free()


func _test_durable_unequip_transaction() -> void:
	var build := BuildData.create_new(ClassIds.VOID_WARLOCK, "Controller Unequip")
	var progression := PROGRESSION_BRIDGE_SCRIPT.new() as PlayableProgressionBridge
	root.add_child(progression)
	_expect(progression.configure_ephemeral(build), "Progression bridge should bind the unequip fixture")
	if not progression.is_configured():
		progression.queue_free()
		return
	var inventory := INVENTORY_BRIDGE_SCRIPT.new() as PlayableInventoryBridge
	root.add_child(inventory)
	_expect(inventory.configure(progression), "Inventory bridge should bind the unequip fixture")
	if not inventory.is_configured():
		inventory.queue_free()
		progression.queue_free()
		return
	var stored := inventory.collect_drop(PLAYABLE_ITEM_CATALOG.item_data(&"void_scepter"))
	_expect(bool(stored.get("success", false)), "Unequip fixture should store a weapon")
	var equipped := inventory.equip_inventory_index(0)
	_expect(bool(equipped.get("success", false)), "Unequip fixture should equip the weapon")
	var equipped_id := str((equipped.get("item", {}) as Dictionary).get("instance_id", ""))
	var unequipped := inventory.unequip_slot("Weapon")
	_expect(bool(unequipped.get("success", false)), "Explicit unequip should succeed")
	var snapshot := inventory.snapshot()
	var equipment: Dictionary = snapshot.get("equipment", {})
	var backpack: Array = snapshot.get("backpack", [])
	_expect((equipment.get("Weapon", {}) as Dictionary).is_empty(), "Unequip should clear the selected equipment slot")
	_expect(backpack.size() == 1, "Unequip should return exactly one item to the backpack")
	if backpack.size() == 1:
		_expect(str((backpack[0] as Dictionary).get("instance_id", "")) == equipped_id, "Unequip should preserve physical item identity")
	inventory.queue_free()
	progression.queue_free()


func _test_both_classes_expose_unequip() -> void:
	for script: Script in [VOID_WARLOCK_SCRIPT, PENITENT_SCRIPT]:
		var character = script.new()
		_expect(character.has_method("unequip_slot"), "Every playable class should expose the shared unequip action")
		character.free()


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


func _joy_event_count(action_name: StringName) -> int:
	var count := 0
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)