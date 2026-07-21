class_name ClassResourcePool
extends RefCounted

var resource_id: StringName = &"resource"
var current: float = 0.0
var maximum: float = 100.0
var regeneration_per_second: float = 0.0


func configure(p_resource_id: StringName, p_maximum: float, p_regeneration: float = 0.0) -> void:
	resource_id = p_resource_id
	maximum = maxf(0.0, p_maximum)
	regeneration_per_second = maxf(0.0, p_regeneration)
	current = clampf(current, 0.0, maximum)


func fill() -> void:
	current = maximum


func can_spend(amount: float) -> bool:
	return amount >= 0.0 and current >= amount


func spend(amount: float) -> bool:
	if not can_spend(amount):
		return false
	current -= amount
	return true


func generate(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var before := current
	current = minf(maximum, current + amount)
	return current - before


func tick(delta: float) -> void:
	generate(regeneration_per_second * maxf(delta, 0.0))
