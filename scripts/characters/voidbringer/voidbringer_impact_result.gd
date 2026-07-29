class_name VoidbringerImpactResult
extends RefCounted

var _data: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	_data = data.duplicate(true)


func snapshot() -> Dictionary:
	return _data.duplicate(true)


func value(key: StringName, default_value: Variant = null) -> Variant:
	return _data.get(key, default_value)


func is_fatal() -> bool:
	return bool(_data.get("fatal", false))


func damage() -> int:
	return int(_data.get("damage", 0))
