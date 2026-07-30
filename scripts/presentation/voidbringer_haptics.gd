class_name VoidbringerHaptics
extends RefCounted

signal rumble_started(snapshot: Dictionary)
signal rumble_stopped(device_id: int)

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")

var settings: VoidbringerPresentationSettings
var device_id := 0
var active := false
var start_call_count := 0
var stop_call_count := 0
var last_request: Dictionary = {}

var _start_callback := Callable()
var _stop_callback := Callable()


func _init(
	presentation_settings: VoidbringerPresentationSettings = null,
	start_callback: Callable = Callable(),
	stop_callback: Callable = Callable()
) -> void:
	settings = presentation_settings
	if settings == null:
		settings = SETTINGS_SCRIPT.new()
	_start_callback = start_callback if start_callback.is_valid() else Callable(self, "_start_real")
	_stop_callback = stop_callback if stop_callback.is_valid() else Callable(self, "_stop_real")


func configure_device(new_device_id: int) -> void:
	device_id = maxi(new_device_id, 0)


func play_impact(result: Variant) -> bool:
	var impact := _impact_snapshot(result)
	if impact.is_empty() or not bool(impact.get("damage_applied", true)):
		return false
	var base_strength := 0.58
	if bool(impact.get("fatal", false)):
		base_strength = 1.0
	elif bool(impact.get("critical", false)):
		base_strength = 0.82
	base_strength += minf(float(impact.get("fold_crossing_count", 0)) * 0.06, 0.18)
	var duration := 0.18 if bool(impact.get("fatal", false)) else (0.12 if bool(impact.get("critical", false)) else 0.08)
	return _play(&"impact", base_strength, duration)


func play_breach(entered_breach: bool) -> bool:
	if not entered_breach:
		return false
	return _play(&"breach", 0.88, 0.20)


func play_anchor_commit(entered_breach: bool = false) -> bool:
	if entered_breach:
		return play_breach(true)
	return _play(&"anchor_commit", 0.36, 0.06)


func clear() -> void:
	if active:
		_stop_callback.call(device_id)
		stop_call_count += 1
		rumble_stopped.emit(device_id)
	active = false
	last_request.clear()


func debug_snapshot() -> Dictionary:
	return {
		"device_id": device_id,
		"active": active,
		"start_call_count": start_call_count,
		"stop_call_count": stop_call_count,
		"last_request": last_request.duplicate(true),
		"settings": settings.snapshot(),
	}


func _play(profile_id: StringName, base_strength: float, duration: float) -> bool:
	var mode_scale := settings.rumble_scale()
	if mode_scale <= 0.0:
		return false
	var strong_magnitude := clampf(base_strength * mode_scale, 0.0, 1.0)
	var weak_magnitude := clampf(strong_magnitude * 0.55, 0.0, 1.0)
	if strong_magnitude <= 0.0 and weak_magnitude <= 0.0:
		return false
	var bounded_duration := clampf(duration, 0.01, 0.40)
	_start_callback.call(device_id, weak_magnitude, strong_magnitude, bounded_duration)
	start_call_count += 1
	active = true
	last_request = {
		"profile_id": profile_id,
		"device_id": device_id,
		"weak_magnitude": weak_magnitude,
		"strong_magnitude": strong_magnitude,
		"duration": bounded_duration,
		"mode": settings.effective_mode(),
	}
	rumble_started.emit(last_request.duplicate(true))
	return true


func _impact_snapshot(result: Variant) -> Dictionary:
	if result is Dictionary:
		return (result as Dictionary).duplicate(true)
	if result != null and result.has_method("snapshot"):
		return result.snapshot()
	return {}


func _start_real(
	requested_device_id: int,
	weak_magnitude: float,
	strong_magnitude: float,
	duration: float
) -> void:
	Input.start_joy_vibration(
		requested_device_id,
		clampf(weak_magnitude, 0.0, 1.0),
		clampf(strong_magnitude, 0.0, 1.0),
		maxf(duration, 0.01)
	)


func _stop_real(requested_device_id: int) -> void:
	Input.stop_joy_vibration(requested_device_id)
