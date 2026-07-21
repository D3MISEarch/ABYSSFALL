class_name AbilityDefinition
extends RefCounted

var ability_id: StringName = &""
var resource_id: StringName = &"resource"
var resource_cost: float = 0.0
var cooldown_seconds: float = 0.0


func _init(
	p_ability_id: StringName = &"",
	p_resource_id: StringName = &"resource",
	p_resource_cost: float = 0.0,
	p_cooldown_seconds: float = 0.0
) -> void:
	ability_id = p_ability_id
	resource_id = p_resource_id
	resource_cost = maxf(0.0, p_resource_cost)
	cooldown_seconds = maxf(0.0, p_cooldown_seconds)


func is_valid() -> bool:
	return ability_id != &"" and resource_id != &""
