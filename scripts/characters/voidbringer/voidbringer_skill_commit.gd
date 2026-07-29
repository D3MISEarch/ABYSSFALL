class_name VoidbringerSkillCommit
extends RefCounted

var _data: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	_data = data.duplicate(true)


func snapshot() -> Dictionary:
	return _data.duplicate(true)


func value(key: StringName, default_value: Variant = null) -> Variant:
	return _data.get(key, default_value)


func succeeded() -> bool:
	return bool(_data.get("success", false))


func reason() -> StringName:
	return StringName(str(_data.get("reason", "")))
