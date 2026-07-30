class_name VoidbringerPresentationSettings
extends RefCounted

const MODE_FULL: StringName = &"full"
const MODE_REDUCED: StringName = &"reduced"
const MODE_DISABLED: StringName = &"disabled"

var mode: StringName = MODE_FULL
var master_enabled := true
var haptics_enabled := true


func configure(
	new_mode: StringName = MODE_FULL,
	new_master_enabled: bool = true,
	new_haptics_enabled: bool = true
) -> void:
	mode = new_mode if is_valid_mode(new_mode) else MODE_FULL
	master_enabled = new_master_enabled
	haptics_enabled = new_haptics_enabled


func effective_mode() -> StringName:
	if not master_enabled:
		return MODE_DISABLED
	return mode


func transform_scale() -> float:
	match effective_mode():
		MODE_REDUCED:
			return 0.55
		MODE_DISABLED:
			return 0.0
		_:
			return 1.0


func light_scale() -> float:
	match effective_mode():
		MODE_REDUCED:
			return 0.50
		MODE_DISABLED:
			return 0.0
		_:
			return 1.0


func fracture_detail_scale() -> float:
	match effective_mode():
		MODE_REDUCED:
			return 0.60
		MODE_DISABLED:
			return 0.0
		_:
			return 1.0


func audio_scale() -> float:
	match effective_mode():
		MODE_REDUCED:
			return 0.45
		MODE_DISABLED:
			return 0.0
		_:
			return 1.0


func rumble_scale() -> float:
	if not master_enabled or not haptics_enabled:
		return 0.0
	match mode:
		MODE_REDUCED:
			return 0.35
		MODE_DISABLED:
			return 0.0
		_:
			return 0.65


func snapshot() -> Dictionary:
	return {
		"mode": mode,
		"effective_mode": effective_mode(),
		"master_enabled": master_enabled,
		"haptics_enabled": haptics_enabled,
		"transform_scale": transform_scale(),
		"light_scale": light_scale(),
		"fracture_detail_scale": fracture_detail_scale(),
		"audio_scale": audio_scale(),
		"rumble_scale": rumble_scale(),
	}


static func is_valid_mode(value: StringName) -> bool:
	return value in [MODE_FULL, MODE_REDUCED, MODE_DISABLED]
