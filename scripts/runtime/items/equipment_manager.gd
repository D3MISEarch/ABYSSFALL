class_name EquipmentManager
extends RefCounted

const VALID_SLOTS: Array[StringName] = [
	&"head", &"chest", &"gloves", &"boots", &"belt", &"amulet",
	&"ring_left", &"ring_right", &"main_hand", &"off_hand",
]
const TWO_HANDED_TAG := &"two_handed"

signal equipment_changed(slot_id: StringName, equipped: ItemInstance, unequipped: ItemInstance)

var equipped: Dictionary = {}
var item_catalog: ItemCatalog
var stat_block: StatBlock


func configure(p_item_catalog: ItemCatalog, p_stat_block: StatBlock) -> void:
	item_catalog = p_item_catalog
	stat_block = p_stat_block
	rebuild_stat_modifiers()


func can_equip(slot_id: StringName, item: ItemInstance, allowed_slots: Array[StringName] = []) -> bool:
	return _can_equip_in_state(slot_id, item, equipped, allowed_slots)


func equip(slot_id: StringName, item: ItemInstance, allowed_slots: Array[StringName] = []) -> ItemInstance:
	if not can_equip(slot_id, item, allowed_slots):
		return null
	var previous: ItemInstance = equipped.get(slot_id)
	if previous != null:
		_remove_item_modifiers(previous)
	equipped[slot_id] = item
	_apply_item_modifiers(item)
	equipment_changed.emit(slot_id, item, previous)
	return previous


func unequip(slot_id: StringName) -> ItemInstance:
	if not equipped.has(slot_id):
		return null
	var previous: ItemInstance = equipped[slot_id]
	_remove_item_modifiers(previous)
	equipped.erase(slot_id)
	equipment_changed.emit(slot_id, null, previous)
	return previous


func restore(serialized_equipment: Dictionary) -> bool:
	var restored: Dictionary = {}
	for raw_slot: Variant in serialized_equipment:
		var slot_id := StringName(str(raw_slot))
		if slot_id not in VALID_SLOTS:
			return false
		var raw_item: Variant = serialized_equipment[raw_slot]
		if not raw_item is Dictionary:
			return false
		var item := ItemInstance.from_dict(raw_item)
		if not _can_equip_in_state(slot_id, item, restored):
			return false
		restored[slot_id] = item
	equipped = restored
	rebuild_stat_modifiers()
	return true


func rebuild_stat_modifiers() -> void:
	if stat_block == null:
		return
	for slot_id: StringName in VALID_SLOTS:
		stat_block.remove_source(_slot_source(slot_id))
	for slot_id: StringName in equipped:
		_apply_item_modifiers(equipped[slot_id], slot_id)


func serialize() -> Dictionary:
	var result: Dictionary = {}
	var slots := equipped.keys()
	slots.sort()
	for slot_id: StringName in slots:
		var item: ItemInstance = equipped[slot_id]
		result[String(slot_id)] = item.to_dict()
	return result


func _can_equip_in_state(
	slot_id: StringName,
	item: ItemInstance,
	state: Dictionary,
	allowed_slots: Array[StringName] = []
) -> bool:
	if slot_id not in VALID_SLOTS or item == null or item.quantity != 1:
		return false
	if item.instance_id.is_empty():
		return false

	var resolved_slots := allowed_slots
	var definition: ItemDefinition = null
	if item_catalog != null:
		definition = item_catalog.get_definition(item.definition_id)
		if definition == null:
			return false
		resolved_slots = definition.equipment_slots
	if slot_id not in resolved_slots:
		return false

	for existing_slot: Variant in state:
		var existing: ItemInstance = state.get(existing_slot)
		if existing != null and existing.instance_id == item.instance_id:
			return false

	if definition != null and TWO_HANDED_TAG in definition.tags:
		if slot_id != &"main_hand":
			return false
		if state.get(&"off_hand") != null:
			return false

	if slot_id == &"off_hand":
		var main_hand: ItemInstance = state.get(&"main_hand")
		if main_hand != null and _item_has_tag(main_hand, TWO_HANDED_TAG):
			return false
	return true


func _item_has_tag(item: ItemInstance, tag: StringName) -> bool:
	if item_catalog == null or item == null:
		return false
	var definition := item_catalog.get_definition(item.definition_id)
	return definition != null and tag in definition.tags


func _apply_item_modifiers(item: ItemInstance, slot_override: StringName = &"") -> void:
	if stat_block == null or item_catalog == null or item == null:
		return
	var definition: ItemDefinition = item_catalog.get_definition(item.definition_id)
	if definition == null:
		return
	var slot_id := slot_override if slot_override != &"" else _find_slot_for_item(item)
	if slot_id == &"":
		return
	var source_id := _slot_source(slot_id)
	var all_modifiers: Array[Dictionary] = definition.base_modifiers.duplicate(true)
	all_modifiers.append_array(item.affixes)
	for data: Dictionary in all_modifiers:
		var stat_id := StringName(str(data.get("stat_id", "")))
		if stat_id == &"":
			continue
		stat_block.add_modifier(StatModifier.new(
			source_id,
			stat_id,
			int(data.get("operation", StatModifier.Operation.FLAT)),
			float(data.get("value", 0.0)),
			int(data.get("priority", 10))
		))


func _remove_item_modifiers(item: ItemInstance) -> void:
	if stat_block == null or item == null:
		return
	var slot_id := _find_slot_for_item(item)
	if slot_id != &"":
		stat_block.remove_source(_slot_source(slot_id))


func _find_slot_for_item(item: ItemInstance) -> StringName:
	for slot_id: StringName in equipped:
		if equipped[slot_id] == item:
			return slot_id
	return &""


func _slot_source(slot_id: StringName) -> String:
	return "equipment:%s" % String(slot_id)
