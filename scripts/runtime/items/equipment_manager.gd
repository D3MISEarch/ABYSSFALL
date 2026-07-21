class_name EquipmentManager
extends RefCounted

const VALID_SLOTS: Array[StringName] = [
	&"head", &"chest", &"gloves", &"boots", &"belt", &"amulet",
	&"ring_left", &"ring_right", &"main_hand", &"off_hand",
]

signal equipment_changed(slot_id: StringName, equipped: ItemInstance, unequipped: ItemInstance)

var equipped: Dictionary = {}


func can_equip(slot_id: StringName, item: ItemInstance, allowed_slots: Array[StringName]) -> bool:
	return slot_id in VALID_SLOTS and item != null and slot_id in allowed_slots


func equip(slot_id: StringName, item: ItemInstance, allowed_slots: Array[StringName]) -> ItemInstance:
	if not can_equip(slot_id, item, allowed_slots):
		return null
	var previous: ItemInstance = equipped.get(slot_id)
	equipped[slot_id] = item
	equipment_changed.emit(slot_id, item, previous)
	return previous


func unequip(slot_id: StringName) -> ItemInstance:
	if not equipped.has(slot_id):
		return null
	var previous: ItemInstance = equipped[slot_id]
	equipped.erase(slot_id)
	equipment_changed.emit(slot_id, null, previous)
	return previous


func serialize() -> Dictionary:
	var result: Dictionary = {}
	for slot_id in equipped:
		var item: ItemInstance = equipped[slot_id]
		result[String(slot_id)] = item.to_dict()
	return result
