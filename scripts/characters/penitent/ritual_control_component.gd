extends Node
class_name RitualControlComponent

var host: Node
var original_move_speed := 0.0
var source_effects: Dictionary = {}
var physics_disabled_by_binding := false


func bind_to(target: Node) -> void:
	host = target
	var speed_value = target.get("move_speed")
	original_move_speed = float(speed_value) if speed_value != null else 0.0
	process_priority = 100


func apply_source(
	source_id: int,
	movement_multiplier: float,
	control_duration: float,
	bind_duration: float
) -> void:
	var now := Time.get_ticks_msec() * 0.001
	source_effects[source_id] = {
		"movement_multiplier": clampf(movement_multiplier, 0.0, 1.0),
		"expires_at": now + maxf(control_duration, 0.0),
		"bind_until": now + maxf(bind_duration, 0.0),
	}
	_apply_current_state(now)


func remove_source(source_id: int) -> void:
	source_effects.erase(source_id)
	_apply_current_state(Time.get_ticks_msec() * 0.001)


func get_snapshot() -> Dictionary:
	var now := Time.get_ticks_msec() * 0.001
	_prune_expired(now)
	var state := _resolve_state(now)
	return {
		"sources": source_effects.size(),
		"movement_multiplier": float(state.get("movement_multiplier", 1.0)),
		"bound": bool(state.get("bound", false)),
	}


func _physics_process(_delta: float) -> void:
	_apply_current_state(Time.get_ticks_msec() * 0.001)


func _exit_tree() -> void:
	_restore_host()


func _apply_current_state(now: float) -> void:
	if not is_instance_valid(host):
		return
	_prune_expired(now)
	var state := _resolve_state(now)
	var multiplier := float(state.get("movement_multiplier", 1.0))
	var is_bound := bool(state.get("bound", false))
	if host.get("move_speed") != null:
		host.set("move_speed", original_move_speed * multiplier)
	if is_bound and host.is_physics_processing():
		host.set_physics_process(false)
		physics_disabled_by_binding = true
	elif not is_bound and physics_disabled_by_binding:
		host.set_physics_process(true)
		physics_disabled_by_binding = false


func _resolve_state(now: float) -> Dictionary:
	var multiplier := 1.0
	var is_bound := false
	for effect_value in source_effects.values():
		var effect: Dictionary = effect_value
		multiplier = minf(multiplier, float(effect.get("movement_multiplier", 1.0)))
		if float(effect.get("bind_until", 0.0)) > now:
			is_bound = true
	return {
		"movement_multiplier": 0.0 if is_bound else multiplier,
		"bound": is_bound,
	}


func _prune_expired(now: float) -> void:
	for key in source_effects.keys():
		var effect: Dictionary = source_effects[key]
		if float(effect.get("expires_at", 0.0)) <= now:
			source_effects.erase(key)


func _restore_host() -> void:
	if not is_instance_valid(host):
		return
	if host.get("move_speed") != null:
		host.set("move_speed", original_move_speed)
	if physics_disabled_by_binding:
		host.set_physics_process(true)
		physics_disabled_by_binding = false
