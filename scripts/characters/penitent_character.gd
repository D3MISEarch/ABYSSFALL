extends "res://scripts/characters/penitent_placeholder.gd"
class_name PenitentCharacter

const FERVOR_RESOURCE_SCRIPT = preload("res://scripts/characters/penitent/fervor_resource.gd")
const RITE_MARK_SCRIPT = preload("res://scripts/characters/penitent/rite_mark_component.gd")
const RITE_MARK_MARKER_SCRIPT = preload("res://scripts/characters/penitent/rite_mark_marker.gd")

var fervor_component: FervorResource
var ritual_blade_combo_step := 0
var ritual_blade_combo_time := 0.0


func _ready() -> void:
	fervor_component = FERVOR_RESOURCE_SCRIPT.new()
	fervor_component.name = "FervorResource"
	add_child(fervor_component)
	fervor_component.value_changed.connect(_on_fervor_value_changed)
	fervor_component.revelation_ready.connect(_on_revelation_ready)
	fervor_component.configure(fervor, max_fervor)
	super._ready()


func _physics_process(delta: float) -> void:
	ritual_blade_combo_time = maxf(ritual_blade_combo_time - delta, 0.0)
	if ritual_blade_combo_time <= 0.0:
		ritual_blade_combo_step = 0
	super._physics_process(delta)


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


func apply_brand_to_target(target: Node3D, duration: float = 10.0) -> Dictionary:
	var mark := get_or_create_rite_mark(target)
	if not is_instance_valid(mark):
		return {}
	mark.apply_brand(duration)
	return mark.get_snapshot()


func get_rite_mark_snapshot(target: Node3D) -> Dictionary:
	if not is_instance_valid(target):
		return {}
	var mark := target.get_node_or_null("RiteMark") as RiteMarkComponent
	return mark.get_snapshot() if is_instance_valid(mark) else {}


func get_or_create_rite_mark(target: Node3D) -> RiteMarkComponent:
	if not is_instance_valid(target):
		return null
	var existing := target.get_node_or_null("RiteMark") as RiteMarkComponent
	if is_instance_valid(existing):
		return existing

	var mark := RITE_MARK_SCRIPT.new() as RiteMarkComponent
	mark.name = "RiteMark"
	target.add_child(mark)
	var is_boss := target.has_signal("phase_changed") or target.name == "TheHollowKing"
	mark.configure(6.0, 8.0, is_boss)

	var marker := RITE_MARK_MARKER_SCRIPT.new() as RiteMarkMarker
	marker.name = "RiteMarkMarker"
	target.add_child(marker)
	marker.bind(mark, 3.4 if is_boss else 1.9)
	return mark


func _debug_ritual_blade() -> void:
	ritual_blade_combo_step = ritual_blade_combo_step % 3 + 1
	ritual_blade_combo_time = 1.05
	var hit_count := 0
	var completed_count := 0
	var strike_center := global_position + facing * 1.25
	var damage := 18 if ritual_blade_combo_step == 3 else (12 if ritual_blade_combo_step == 2 else 10)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var offset: Vector3 = enemy.global_position - strike_center
		offset.y = 0.0
		if offset.length() > 1.55:
			continue
		enemy.take_damage(damage)
		hit_count += 1
		var mark := get_or_create_rite_mark(enemy)
		if not is_instance_valid(mark):
			continue
		var became_complete := false
		if ritual_blade_combo_step == 3:
			became_complete = mark.complete_rite()
		else:
			var previous_state := mark.current_state
			mark.apply_partial(1)
			became_complete = (
				previous_state != RiteMarkComponent.STATE_COMPLETE
				and mark.current_state == RiteMarkComponent.STATE_COMPLETE
			)
		if became_complete:
			completed_count += 1

	if completed_count > 0:
		add_fervor(minf(float(completed_count) * 6.0, 18.0))
		ability_message.emit("RITE COMPLETE" if completed_count == 1 else "%d RITES COMPLETE" % completed_count)
	elif hit_count > 0 and ritual_blade_combo_step == 3:
		ability_message.emit("THE FINISHER CARVES NO NEW CONFESSION")

	if is_instance_valid(visual_root):
		var tween := create_tween()
		var attack_scale := Vector3(1.24, 0.86, 1.24) if ritual_blade_combo_step == 3 else Vector3(1.14, 0.92, 1.14)
		tween.tween_property(visual_root, "scale", attack_scale, 0.055)
		tween.tween_property(visual_root, "scale", Vector3.ONE, 0.13)


func _on_fervor_value_changed(current_value: float, maximum_value: float) -> void:
	fervor = current_value
	max_fervor = maximum_value
	resource_changed.emit(RESOURCE_ID, RESOURCE_DISPLAY_NAME, current_value, maximum_value)


func _on_revelation_ready() -> void:
	ability_message.emit("REVELATION READY — THE LAST RITE AWAITS")
