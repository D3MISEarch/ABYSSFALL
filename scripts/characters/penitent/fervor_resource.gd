extends Node
class_name FervorResource

signal value_changed(current_value: float, maximum_value: float)
signal threshold_changed(previous_threshold: int, current_threshold: int)
signal revelation_ready
signal spent(fervor_spent: float, health_cost: int)
signal insufficient(required_fervor: float, current_fervor: float)

const RESOURCE_ID := "fervor"
const DISPLAY_NAME := "Fervor"

const THRESHOLD_DORMANT := 0
const THRESHOLD_KINDLED := 1
const THRESHOLD_ZEALOUS := 2
const THRESHOLD_FANATICAL := 3
const THRESHOLD_REVELATION := 4

var maximum_value := 100.0
var current_value := 25.0
var decay_floor := 25.0
var decay_delay := 8.0
var decay_rate := 4.0

var combat_active := true
var out_of_combat_time := 0.0
var current_threshold := THRESHOLD_KINDLED


func _ready() -> void:
	set_process(true)
	current_threshold = get_threshold(current_value)


func _process(delta: float) -> void:
	advance_decay(delta)


func configure(
	initial_value: float = 25.0,
	new_maximum: float = 100.0,
	new_decay_floor: float = 25.0
) -> void:
	maximum_value = maxf(new_maximum, 1.0)
	decay_floor = clampf(new_decay_floor, 0.0, maximum_value)
	current_value = clampf(initial_value, 0.0, maximum_value)
	current_threshold = get_threshold(current_value)
	out_of_combat_time = 0.0
	value_changed.emit(current_value, maximum_value)
	if current_threshold == THRESHOLD_REVELATION:
		revelation_ready.emit()


func get_snapshot() -> Dictionary:
	return {
		"id": RESOURCE_ID,
		"display_name": DISPLAY_NAME,
		"current": current_value,
		"maximum": maximum_value,
		"normalized": current_value / maxf(maximum_value, 1.0),
		"threshold": current_threshold,
		"combat_active": combat_active,
	}


func set_combat_active(is_active: bool) -> void:
	if combat_active == is_active:
		return
	combat_active = is_active
	out_of_combat_time = 0.0


func add_fervor(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var previous_value := current_value
	_set_value(current_value + amount)
	return current_value - previous_value


func can_spend(amount: float) -> bool:
	return amount >= 0.0 and current_value >= amount


func spend_fervor(amount: float) -> bool:
	if amount < 0.0:
		return false
	if not can_spend(amount):
		insufficient.emit(amount, current_value)
		return false
	_set_value(current_value - amount)
	spent.emit(amount, 0)
	return true


func advance_decay(delta: float) -> void:
	if delta <= 0.0 or combat_active:
		return
	if current_value <= decay_floor:
		out_of_combat_time = 0.0
		return
	out_of_combat_time += delta
	if out_of_combat_time <= decay_delay:
		return
	var decay_delta := delta
	if out_of_combat_time - delta < decay_delay:
		decay_delta = out_of_combat_time - decay_delay
	_set_value(maxf(current_value - decay_rate * decay_delta, decay_floor))


func quote_sacrament_cost(cost: float, current_health: int, maximum_health: int) -> Dictionary:
	var safe_cost := maxf(cost, 0.0)
	var safe_max_health := maxi(maximum_health, 1)
	var available_fervor := minf(current_value, safe_cost)
	var missing_fervor := maxf(safe_cost - available_fervor, 0.0)
	var health_percent := int(ceil(missing_fervor / 2.0))
	var health_cost := int(ceil(float(safe_max_health) * float(health_percent) / 100.0))
	var can_cast := missing_fervor <= 0.0 or current_health - health_cost >= 1

	return {
		"cost": safe_cost,
		"fervor_spent": available_fervor,
		"missing_fervor": missing_fervor,
		"health_percent": health_percent,
		"health_cost": health_cost,
		"remaining_health": current_health - health_cost if can_cast else current_health,
		"can_cast": can_cast,
	}


func commit_sacrament_cost(cost: float, current_health: int, maximum_health: int) -> Dictionary:
	var quote := quote_sacrament_cost(cost, current_health, maximum_health)
	if not bool(quote.get("can_cast", false)):
		insufficient.emit(cost, current_value)
		return quote
	var fervor_spent := float(quote.get("fervor_spent", 0.0))
	var health_cost := int(quote.get("health_cost", 0))
	_set_value(current_value - fervor_spent)
	spent.emit(fervor_spent, health_cost)
	return quote


func get_threshold(value: float) -> int:
	var ratio := clampf(value / maxf(maximum_value, 1.0), 0.0, 1.0)
	if ratio >= 0.999:
		return THRESHOLD_REVELATION
	if ratio >= 0.75:
		return THRESHOLD_FANATICAL
	if ratio >= 0.50:
		return THRESHOLD_ZEALOUS
	if ratio >= 0.25:
		return THRESHOLD_KINDLED
	return THRESHOLD_DORMANT


func _set_value(new_value: float) -> void:
	var previous_threshold := current_threshold
	current_value = clampf(new_value, 0.0, maximum_value)
	current_threshold = get_threshold(current_value)
	value_changed.emit(current_value, maximum_value)
	if current_threshold != previous_threshold:
		threshold_changed.emit(previous_threshold, current_threshold)
	if current_threshold == THRESHOLD_REVELATION and previous_threshold != THRESHOLD_REVELATION:
		revelation_ready.emit()
