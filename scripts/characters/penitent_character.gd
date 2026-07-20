extends "res://scripts/characters/penitent_placeholder.gd"
class_name PenitentCharacter

const FERVOR_RESOURCE_SCRIPT = preload("res://scripts/characters/penitent/fervor_resource.gd")

var fervor_component: FervorResource


func _ready() -> void:
	fervor_component = FERVOR_RESOURCE_SCRIPT.new()
	fervor_component.name = "FervorResource"
	add_child(fervor_component)
	fervor_component.value_changed.connect(_on_fervor_value_changed)
	fervor_component.revelation_ready.connect(_on_revelation_ready)
	fervor_component.configure(fervor, max_fervor)
	super._ready()


func get_health_snapshot() -> Dictionary:
	return {
		"current": health,
		"maximum": max_health,
		"alive": alive,
	}


func get_resource_snapshot() -> Dictionary:
	if is_instance_valid(fervor_component):
		return fervor_component.get_snapshot()
	return super.get_resource_snapshot()


func get_progression_snapshot() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"required_experience": experience_required,
		"pending_level_ups": pending_level_ups,
	}


func add_class_resource(amount: float) -> void:
	add_fervor(amount)


func spend_class_resource(amount: float) -> bool:
	return spend_fervor(amount)


func add_fervor(amount: float) -> void:
	if not alive or amount <= 0.0:
		return
	if is_instance_valid(fervor_component):
		fervor_component.add_fervor(amount)
	else:
		super.add_fervor(amount)


func spend_fervor(amount: float) -> bool:
	if is_instance_valid(fervor_component):
		return fervor_component.spend_fervor(amount)
	return super.spend_fervor(amount)


func set_combat_active(is_active: bool) -> void:
	if is_instance_valid(fervor_component):
		fervor_component.set_combat_active(is_active)


func quote_sacrament_cost(cost: float) -> Dictionary:
	if not is_instance_valid(fervor_component):
		return {"can_cast": false}
	return fervor_component.quote_sacrament_cost(cost, health, max_health)


func commit_sacrament_cost(cost: float) -> Dictionary:
	if not is_instance_valid(fervor_component):
		return {"can_cast": false}
	var quote := fervor_component.commit_sacrament_cost(cost, health, max_health)
	if not bool(quote.get("can_cast", false)):
		return quote
	var health_cost := int(quote.get("health_cost", 0))
	if health_cost > 0:
		health = maxi(health - health_cost, 1)
		health_changed.emit(health, max_health)
	return quote


func _on_fervor_value_changed(current_value: float, maximum_value: float) -> void:
	fervor = current_value
	max_fervor = maximum_value
	resource_changed.emit(RESOURCE_ID, RESOURCE_DISPLAY_NAME, current_value, maximum_value)


func _on_revelation_ready() -> void:
	ability_message.emit("REVELATION READY — THE LAST RITE AWAITS")
