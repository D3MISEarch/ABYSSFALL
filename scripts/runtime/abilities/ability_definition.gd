class_name AbilityDefinition
extends RefCounted

var ability_id: StringName = &""
var resource_id: StringName = &"resource"
var resource_cost: float = 0.0
var cooldown_seconds: float = 0.0
var slot_type: StringName = &"active"
var maximum_charges: int = 0
var recharge_seconds: float = 0.0
var instability_delta: float = 0.0
var tags: Array[StringName] = []


func _init(
	p_ability_id: StringName = &"",
	p_resource_id: StringName = &"resource",
	p_resource_cost: float = 0.0,
	p_cooldown_seconds: float = 0.0,
	p_slot_type: StringName = &"active",
	p_maximum_charges: int = 0,
	p_recharge_seconds: float = 0.0,
	p_instability_delta: float = 0.0,
	p_tags: Array = []
) -> void:
	ability_id = p_ability_id
	resource_id = p_resource_id
	resource_cost = maxf(0.0, p_resource_cost)
	cooldown_seconds = maxf(0.0, p_cooldown_seconds)
	slot_type = p_slot_type
	maximum_charges = maxi(0, p_maximum_charges)
	recharge_seconds = maxf(0.0, p_recharge_seconds)
	instability_delta = maxf(0.0, p_instability_delta)
	tags.clear()
	for tag: Variant in p_tags:
		tags.append(StringName(str(tag)))


func is_valid() -> bool:
	if ability_id == &"" or resource_id == &"" or slot_type == &"":
		return false
	if maximum_charges > 0 and recharge_seconds <= 0.0:
		return false
	return true


func uses_charges() -> bool:
	return maximum_charges > 0
