class_name StatModifier
extends RefCounted

enum Operation {
	FLAT,
	ADDITIVE_PERCENT,
	MULTIPLICATIVE_PERCENT,
}

var source_id: String = ""
var stat_id: StringName = &""
var operation: Operation = Operation.FLAT
var value: float = 0.0
var priority: int = 0


func _init(
	p_source_id: String = "",
	p_stat_id: StringName = &"",
	p_operation: Operation = Operation.FLAT,
	p_value: float = 0.0,
	p_priority: int = 0
) -> void:
	source_id = p_source_id
	stat_id = p_stat_id
	operation = p_operation
	value = p_value
	priority = p_priority
