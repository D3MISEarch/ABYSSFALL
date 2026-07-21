class_name ItemDefinition
extends RefCounted

var definition_id: StringName = &""
var display_name: String = ""
var equipment_slots: Array[StringName] = []
var max_stack: int = 1
var base_modifiers: Array[Dictionary] = []
var tags: Array[StringName] = []


func _init(
	p_definition_id: StringName = &"",
	p_display_name: String = "",
	p_equipment_slots: Array[StringName] = [],
	p_max_stack: int = 1,
	p_base_modifiers: Array[Dictionary] = [],
	p_tags: Array[StringName] = []
) -> void:
	definition_id = p_definition_id
	display_name = p_display_name
	equipment_slots = p_equipment_slots.duplicate()
	max_stack = maxi(1, p_max_stack)
	base_modifiers = p_base_modifiers.duplicate(true)
	tags = p_tags.duplicate()


func is_equipment() -> bool:
	return not equipment_slots.is_empty()


func allows_slot(slot_id: StringName) -> bool:
	return slot_id in equipment_slots


func to_read_only_dict() -> Dictionary:
	return {
		"definition_id": String(definition_id),
		"display_name": display_name,
		"equipment_slots": equipment_slots.duplicate(),
		"max_stack": max_stack,
		"base_modifiers": base_modifiers.duplicate(true),
		"tags": tags.duplicate(),
	}
