class_name AbilityRuntime
extends RefCounted

var ability_id: StringName = &""
var resource_cost: float = 0.0
var cooldown_seconds: float = 0.0
var cooldown_remaining: float = 0.0


func _init(p_ability_id: StringName = &"", p_cost: float = 0.0, p_cooldown: float = 0.0) -> void:
	ability_id = p_ability_id
	resource_cost = maxf(0.0, p_cost)
	cooldown_seconds = maxf(0.0, p_cooldown)


func can_cast(resource_pool: ClassResourcePool) -> bool:
	return cooldown_remaining <= 0.0 and resource_pool != null and resource_pool.can_spend(resource_cost)


func try_cast(resource_pool: ClassResourcePool) -> bool:
	if not can_cast(resource_pool):
		return false
	if not resource_pool.spend(resource_cost):
		return false
	cooldown_remaining = cooldown_seconds
	return true


func tick(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - maxf(delta, 0.0))
