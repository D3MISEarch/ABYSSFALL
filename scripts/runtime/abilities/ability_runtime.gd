class_name AbilityRuntime
extends RefCounted

var ability_id: StringName = &""
var resource_cost: float = 0.0
var cooldown_seconds: float = 0.0
var cooldown_remaining: float = 0.0
var maximum_charges: int = 0
var current_charges: int = 0
var recharge_seconds: float = 0.0
var _recharge_queue: Array[float] = []


func _init(
	p_ability_id: StringName = &"",
	p_cost: float = 0.0,
	p_cooldown: float = 0.0,
	p_maximum_charges: int = 0,
	p_recharge_seconds: float = 0.0
) -> void:
	ability_id = p_ability_id
	resource_cost = maxf(0.0, p_cost)
	cooldown_seconds = maxf(0.0, p_cooldown)
	maximum_charges = maxi(0, p_maximum_charges)
	current_charges = maximum_charges
	recharge_seconds = maxf(0.0, p_recharge_seconds)


func uses_charges() -> bool:
	return maximum_charges > 0


func has_available_charge() -> bool:
	return not uses_charges() or current_charges > 0


func can_cast(resource_pool: ClassResourcePool) -> bool:
	return (
		cooldown_remaining <= 0.0
		and has_available_charge()
		and resource_pool != null
		and resource_pool.can_spend(resource_cost)
	)


func try_cast(resource_pool: ClassResourcePool) -> bool:
	if not can_cast(resource_pool):
		return false
	if not resource_pool.spend(resource_cost):
		return false
	cooldown_remaining = cooldown_seconds
	if uses_charges():
		current_charges = maxi(0, current_charges - 1)
		_recharge_queue.append(recharge_seconds)
	return true


func tick(delta: float) -> void:
	var remaining_delta := maxf(delta, 0.0)
	cooldown_remaining = maxf(0.0, cooldown_remaining - remaining_delta)
	if not uses_charges() or _recharge_queue.is_empty() or remaining_delta <= 0.0:
		return

	while remaining_delta > 0.0 and not _recharge_queue.is_empty():
		var active_timer := float(_recharge_queue[0])
		if remaining_delta < active_timer:
			_recharge_queue[0] = active_timer - remaining_delta
			remaining_delta = 0.0
			continue
		remaining_delta -= active_timer
		_recharge_queue.pop_front()
		current_charges = mini(maximum_charges, current_charges + 1)


func recharge_remaining() -> float:
	if _recharge_queue.is_empty():
		return 0.0
	return float(_recharge_queue[0])


func charge_snapshot() -> Dictionary:
	return {
		"uses_charges": uses_charges(),
		"current": current_charges,
		"maximum": maximum_charges,
		"recharge_remaining": recharge_remaining(),
		"queued_recharges": _recharge_queue.size(),
	}
