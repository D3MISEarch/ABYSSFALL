class_name PlayableInventoryBridge
extends Node

signal state_changed(snapshot: Dictionary)

const PLAYABLE_ITEM_CATALOG = preload("res://scripts/core/playable_item_catalog.gd")
const PLAYABLE_SLOTS := ["Weapon", "Hood", "Chest", "Gloves", "Boots", "Relic"]

var runtime_bridge: PlayableProgressionBridge
var _configured := false


func configure(bridge: PlayableProgressionBridge) -> bool:
	if _configured or bridge == null or not bridge.is_configured():
		return false
	if bridge.session == null or bridge.session.inventory == null or bridge.session.equipment == null:
		return false
	runtime_bridge = bridge
	_configured = true
	return true


func is_configured() -> bool:
	return _configured


func collect_drop(drop_data: Dictionary) -> Dictionary:
	if not _configured or drop_data.is_empty():
		return {"success": false, "reason": &"unconfigured"}
	var definition_id := StringName(str(drop_data.get("id", "")))
	var definition := runtime_bridge.session.item_catalog.get_definition(definition_id)
	if definition == null:
		return {"success": false, "reason": &"unknown_definition"}
	if definition.max_stack == 1 and runtime_bridge.session.inventory.items.size() >= runtime_bridge.session.inventory.capacity:
		return {"success": false, "reason": &"inventory_full"}
	var item := PLAYABLE_ITEM_CATALOG.create_instance(drop_data, runtime_bridge.session.item_identity)
	if item == null:
		return {"success": false, "reason": &"identity_unavailable"}
	if not runtime_bridge.session.inventory.add_item(item, definition):
		return {"success": false, "reason": &"inventory_rejected"}
	var persisted := runtime_bridge.persist_runtime_snapshot(false, "playable_inventory_pickup")
	var projected := PLAYABLE_ITEM_CATALOG.project_item(item)
	state_changed.emit(snapshot())
	return {
		"success": true,
		"reason": &"stored",
		"persisted": persisted,
		"item": projected,
	}


func equip_inventory_index(index: int) -> Dictionary:
	if not _configured:
		return {"success": false, "reason": &"unconfigured"}
	var inventory := runtime_bridge.session.inventory
	var equipment := runtime_bridge.session.equipment
	if index < 0 or index >= inventory.items.size():
		return {"success": false, "reason": &"invalid_index"}
	var selected: ItemInstance = inventory.items[index]
	var definition := runtime_bridge.session.item_catalog.get_definition(selected.definition_id)
	if definition == null or definition.equipment_slots.size() != 1:
		return {"success": false, "reason": &"invalid_definition"}
	var slot_id: StringName = definition.equipment_slots[0]
	if not equipment.can_equip(slot_id, selected):
		return {"success": false, "reason": &"incompatible_slot"}

	var inventory_before := inventory.serialize()
	var equipment_before := equipment.serialize()
	var removed := inventory.remove_instance(selected.instance_id, selected.quantity)
	if removed == null:
		return {"success": false, "reason": &"remove_failed"}
	var previous: ItemInstance = equipment.equip(slot_id, removed)
	if equipment.equipped.get(slot_id) != removed:
		_restore_transaction(inventory_before, equipment_before)
		return {"success": false, "reason": &"equip_failed"}
	if previous != null:
		var previous_definition := runtime_bridge.session.item_catalog.get_definition(previous.definition_id)
		if previous_definition == null or not inventory.add_item(previous, previous_definition):
			_restore_transaction(inventory_before, equipment_before)
			return {"success": false, "reason": &"swap_return_failed"}

	var persisted := runtime_bridge.persist_runtime_snapshot(false, "playable_inventory_equip")
	var projected := PLAYABLE_ITEM_CATALOG.project_item(removed)
	state_changed.emit(snapshot())
	return {
		"success": true,
		"reason": &"equipped",
		"persisted": persisted,
		"slot": PLAYABLE_ITEM_CATALOG.playable_slot_for_runtime(slot_id),
		"item": projected,
	}


func unequip_slot(playable_slot: String) -> Dictionary:
	if not _configured:
		return {"success": false, "reason": &"unconfigured"}
	var runtime_slot := PLAYABLE_ITEM_CATALOG.runtime_slot_for_playable(playable_slot)
	if runtime_slot == &"":
		return {"success": false, "reason": &"invalid_slot"}
	var inventory := runtime_bridge.session.inventory
	var equipment := runtime_bridge.session.equipment
	var equipped_item: ItemInstance = equipment.equipped.get(runtime_slot)
	if equipped_item == null:
		return {"success": false, "reason": &"empty_slot"}
	var definition := runtime_bridge.session.item_catalog.get_definition(equipped_item.definition_id)
	if definition == null:
		return {"success": false, "reason": &"invalid_definition"}
	if definition.max_stack == 1 and inventory.items.size() >= inventory.capacity:
		return {"success": false, "reason": &"inventory_full"}

	var inventory_before := inventory.serialize()
	var equipment_before := equipment.serialize()
	var removed := equipment.unequip(runtime_slot)
	if removed == null:
		return {"success": false, "reason": &"unequip_failed"}
	if not inventory.add_item(removed, definition):
		_restore_transaction(inventory_before, equipment_before)
		return {"success": false, "reason": &"inventory_return_failed"}

	var persisted := runtime_bridge.persist_runtime_snapshot(false, "playable_inventory_unequip")
	var projected := PLAYABLE_ITEM_CATALOG.project_item(removed)
	state_changed.emit(snapshot())
	return {
		"success": true,
		"reason": &"unequipped",
		"persisted": persisted,
		"slot": playable_slot,
		"item": projected,
	}


func snapshot() -> Dictionary:
	var result_equipment: Dictionary = {}
	for playable_slot: String in PLAYABLE_SLOTS:
		result_equipment[playable_slot] = {}
	if not _configured:
		return {"equipment": result_equipment, "backpack": [], "capacity": 12}
	for raw_slot: Variant in runtime_bridge.session.equipment.equipped:
		var runtime_slot := StringName(str(raw_slot))
		var playable_slot := PLAYABLE_ITEM_CATALOG.playable_slot_for_runtime(runtime_slot)
		if playable_slot.is_empty():
			continue
		var item: ItemInstance = runtime_bridge.session.equipment.equipped.get(raw_slot)
		result_equipment[playable_slot] = PLAYABLE_ITEM_CATALOG.project_item(item)
	var projected_backpack: Array[Dictionary] = []
	for item: ItemInstance in runtime_bridge.session.inventory.items:
		projected_backpack.append(PLAYABLE_ITEM_CATALOG.project_item(item))
	return {
		"equipment": result_equipment,
		"backpack": projected_backpack,
		"capacity": runtime_bridge.session.inventory.capacity,
	}


func flush(context: String = "playable_inventory") -> Error:
	if not _configured or not is_instance_valid(runtime_bridge):
		return OK
	return runtime_bridge.flush(context)


func _exit_tree() -> void:
	flush("playable_inventory_exit")


func _restore_transaction(inventory_snapshot: Array, equipment_snapshot: Dictionary) -> void:
	var inventory_ok := runtime_bridge.session.inventory.restore(inventory_snapshot)
	var equipment_ok := runtime_bridge.session.equipment.restore(equipment_snapshot)
	if not inventory_ok or not equipment_ok:
		push_error("Playable inventory transaction rollback failed.")
