extends "res://scripts/multiclass_main.gd"

const CONTROLLER_UI_INPUT_MAP = preload("res://scripts/core/controller_ui_input_map.gd")
const INVENTORY_FOCUS_NAVIGATOR = preload("res://scripts/ui/inventory_focus_navigator.gd")

var inventory_focus_key := ""


func _install_input_map() -> void:
	super._install_input_map()
	CONTROLLER_UI_INPUT_MAP.install_defaults()


func _process(delta: float) -> void:
	if _side_menu_visible() and Input.is_action_just_pressed("ui_cancel"):
		_close_side_menus()
		return
	super._process(delta)


func _toggle_inventory() -> void:
	if pause_menu != null and pause_menu.visible:
		return
	if not is_instance_valid(inventory_panel) or not is_instance_valid(skill_panel):
		return
	skill_panel.visible = false
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible:
		_refresh_inventory()
	_update_pause_state()


func _refresh_inventory() -> void:
	if (
		not is_instance_valid(player)
		or inventory_equipment_box == null
		or inventory_backpack_box == null
	):
		return
	_capture_inventory_focus()
	_clear_container(inventory_equipment_box)
	_clear_container(inventory_backpack_box)
	inventory_item_buttons.clear()

	var snapshot: Dictionary = player.get_inventory_snapshot()
	var equipped: Dictionary = snapshot.get("equipment", {})
	var backpack: Array = snapshot.get("backpack", [])
	var equipment_buttons: Array[Button] = []
	var backpack_buttons: Array[Button] = []
	var equipment_scroll := inventory_equipment_box.get_parent() as ScrollContainer
	var backpack_scroll := inventory_backpack_box.get_parent() as ScrollContainer
	INVENTORY_FOCUS_NAVIGATOR.prepare_scroll(equipment_scroll)
	INVENTORY_FOCUS_NAVIGATOR.prepare_scroll(backpack_scroll)
	inventory_equipment_box.custom_minimum_size.x = 0.0
	inventory_equipment_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_backpack_box.custom_minimum_size.x = 0.0
	inventory_backpack_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title := Label.new()
	title.text = "EQUIPPED RELICS"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	inventory_equipment_box.add_child(title)

	var summary_lines: Array[String] = []
	for slot in EQUIPMENT_SLOTS:
		var item: Dictionary = equipped.get(slot, {})
		var slot_button := Button.new()
		var focus_key := "equipment:%s" % slot
		slot_button.set_meta("inventory_focus_key", focus_key)
		slot_button.focus_mode = Control.FOCUS_ALL
		slot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_button.custom_minimum_size = Vector2(0.0, 54.0)
		slot_button.focus_entered.connect(
			_on_inventory_focus_entered.bind(slot_button, focus_key, equipment_scroll)
		)
		if item.is_empty():
			slot_button.text = "%s\n  — Empty —" % slot
			slot_button.modulate = Color(0.62, 0.60, 0.68)
			slot_button.disabled = true
			summary_lines.append("%s: Empty" % slot)
		else:
			var rarity: String = str(item.get("rarity", "Common"))
			slot_button.custom_minimum_size = Vector2(0.0, 96.0)
			slot_button.text = (
				"%s  •  %s\n%s\n%s\nCROSS / A / CLICK: UNEQUIP"
				% [
					slot,
					rarity,
					str(item.get("name", "Unknown Item")),
					_format_item_stats(item),
				]
			)
			slot_button.modulate = _rarity_color(rarity)
			slot_button.pressed.connect(_on_inventory_slot_pressed.bind(slot))
			equipment_buttons.append(slot_button)
			summary_lines.append("%s: %s" % [slot, str(item.get("name", "Unknown"))])
		inventory_equipment_box.add_child(slot_button)

	equipment_summary_label.text = "  |  ".join(PackedStringArray(summary_lines))

	var pack_title := Label.new()
	pack_title.text = (
		"BACKPACK  %d / %d   — CROSS / A / CLICK AN ITEM TO EQUIP"
		% [backpack.size(), int(snapshot.get("capacity", 12))]
	)
	pack_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pack_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_title.custom_minimum_size.y = 50.0
	pack_title.add_theme_font_size_override("font_size", 22)
	inventory_backpack_box.add_child(pack_title)

	if backpack.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No unequipped items. Elite Reavers and shattered generators can drop gear."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_label.custom_minimum_size = Vector2(0.0, 70.0)
		empty_label.modulate = Color(0.70, 0.67, 0.76)
		inventory_backpack_box.add_child(empty_label)
	else:
		for index in range(backpack.size()):
			var item: Dictionary = backpack[index]
			var button := Button.new()
			var focus_key := "backpack:%d" % index
			button.set_meta("inventory_focus_key", focus_key)
			button.focus_mode = Control.FOCUS_ALL
			button.custom_minimum_size = Vector2(0.0, 110.0)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.text = (
				"%s  •  %s  •  %s\n%s\n%s"
				% [
					str(item.get("rarity", "Common")),
					str(item.get("slot", "Relic")),
					str(item.get("name", "Unknown Item")),
					str(item.get("description", "")),
					_format_item_stats(item),
				]
			)
			button.modulate = _rarity_color(str(item.get("rarity", "Common")))
			button.focus_entered.connect(
				_on_inventory_focus_entered.bind(button, focus_key, backpack_scroll)
			)
			button.pressed.connect(_on_inventory_item_pressed.bind(index))
			inventory_backpack_box.add_child(button)
			backpack_buttons.append(button)

	INVENTORY_FOCUS_NAVIGATOR.wire_columns(equipment_buttons, backpack_buttons)
	inventory_item_buttons.append_array(equipment_buttons)
	inventory_item_buttons.append_array(backpack_buttons)
	var focus_target: Button = INVENTORY_FOCUS_NAVIGATOR.choose_focus(
		equipment_buttons,
		backpack_buttons,
		inventory_focus_key
	)
	if focus_target != null and inventory_panel != null and inventory_panel.visible:
		call_deferred("_focus_inventory_button", focus_target)


func _capture_inventory_focus() -> void:
	if not is_inside_tree():
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null and focus_owner.has_meta("inventory_focus_key"):
		inventory_focus_key = str(focus_owner.get_meta("inventory_focus_key", ""))


func _on_inventory_focus_entered(
	button: Control,
	focus_key: String,
	scroll: ScrollContainer
) -> void:
	inventory_focus_key = focus_key
	call_deferred("_reveal_inventory_control", scroll, button)


func _focus_inventory_button(button: Button) -> void:
	if not is_instance_valid(inventory_panel) or not inventory_panel.visible:
		return
	if is_instance_valid(button) and not button.disabled:
		button.grab_focus()


func _reveal_inventory_control(scroll: ScrollContainer, control: Control) -> void:
	INVENTORY_FOCUS_NAVIGATOR.reveal(scroll, control)


func _on_inventory_item_pressed(index: int) -> void:
	if not is_instance_valid(player):
		return
	var snapshot: Dictionary = player.get_inventory_snapshot()
	var backpack: Array = snapshot.get("backpack", [])
	if index < 0 or index >= backpack.size():
		return
	var item: Dictionary = backpack[index]
	inventory_focus_key = "equipment:%s" % str(item.get("slot", "Relic"))
	player.equip_inventory_index(index)


func _on_inventory_slot_pressed(slot: String) -> void:
	if not is_instance_valid(player) or not player.has_method("unequip_slot"):
		return
	var snapshot: Dictionary = player.get_inventory_snapshot()
	var backpack: Array = snapshot.get("backpack", [])
	inventory_focus_key = "backpack:%d" % backpack.size()
	player.call("unequip_slot", slot)


func _side_menu_visible() -> bool:
	return (
		(is_instance_valid(inventory_panel) and inventory_panel.visible)
		or (is_instance_valid(skill_panel) and skill_panel.visible)
	)