class_name VoidbringerCameraImpact
extends Node

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")

var settings: VoidbringerPresentationSettings
var camera: Camera3D
var _base_position := Vector3.ZERO
var _base_rotation := Vector3.ZERO
var _elapsed := 0.0
var _duration := 0.0
var _magnitude := 0.0
var _active := false
var _impulse_serial := 0


func configure(presentation_settings: VoidbringerPresentationSettings, target_camera: Camera3D = null) -> void:
	settings = presentation_settings
	if settings == null:
		settings = SETTINGS_SCRIPT.new()
	bind_camera(target_camera)


func bind_camera(target_camera: Camera3D = null) -> void:
	cancel_and_restore()
	camera = target_camera
	if not is_instance_valid(camera) and is_inside_tree():
		var viewport := get_viewport()
		if viewport != null:
			camera = viewport.get_camera_3d()
	if is_instance_valid(camera):
		_capture_base()


func play_impact(impact: Dictionary) -> Dictionary:
	if settings == null:
		return {}
	var mode := settings.effective_mode()
	if mode == SETTINGS_SCRIPT.MODE_DISABLED:
		cancel_and_restore()
		return {}
	if not is_instance_valid(camera):
		bind_camera()
	if not is_instance_valid(camera):
		return {}
	_restore_base()
	_capture_base()
	var fatal := bool(impact.get("fatal", false))
	var critical := bool(impact.get("critical", false))
	var full := mode == SETTINGS_SCRIPT.MODE_FULL
	_magnitude = 0.22 if full else 0.075
	_duration = 0.34 if full else 0.20
	if critical:
		_magnitude *= 1.18
		_duration += 0.04
	if fatal:
		_magnitude *= 1.55
		_duration += 0.10
	_elapsed = 0.0
	_active = true
	_impulse_serial += 1
	return debug_snapshot()


func tick(delta: float) -> void:
	if not _active:
		return
	if not is_instance_valid(camera):
		_active = false
		return
	_elapsed += maxf(delta, 0.0)
	var progress := clampf(_elapsed / maxf(_duration, 0.001), 0.0, 1.0)
	var envelope := pow(1.0 - progress, 2.1)
	var oscillation := sin(progress * PI * 6.0 + float(_impulse_serial) * 0.73)
	var lateral := cos(progress * PI * 5.0 + float(_impulse_serial) * 0.41)
	camera.position = _base_position + Vector3(
		lateral * _magnitude * 0.42,
		oscillation * _magnitude * 0.28,
		-absf(oscillation) * _magnitude * 0.20
	) * envelope
	camera.rotation_degrees = _base_rotation + Vector3(
		oscillation * _magnitude * 2.8,
		lateral * _magnitude * 2.2,
		lateral * _magnitude * 3.6
	) * envelope
	if progress >= 1.0:
		cancel_and_restore()


func cancel_and_restore() -> void:
	if is_instance_valid(camera):
		_restore_base()
	_active = false
	_elapsed = 0.0
	_duration = 0.0
	_magnitude = 0.0


func clear() -> void:
	cancel_and_restore()


func debug_snapshot() -> Dictionary:
	return {
		"active": _active,
		"elapsed": _elapsed,
		"duration": _duration,
		"magnitude": _magnitude,
		"impulse_serial": _impulse_serial,
		"camera_bound": is_instance_valid(camera),
		"base_position": _base_position,
		"base_rotation": _base_rotation,
		"current_position": Vector3.ZERO if not is_instance_valid(camera) else camera.position,
		"current_rotation": Vector3.ZERO if not is_instance_valid(camera) else camera.rotation_degrees,
	}


func _capture_base() -> void:
	if not is_instance_valid(camera):
		return
	_base_position = camera.position
	_base_rotation = camera.rotation_degrees


func _restore_base() -> void:
	if not is_instance_valid(camera):
		return
	camera.position = _base_position
	camera.rotation_degrees = _base_rotation
