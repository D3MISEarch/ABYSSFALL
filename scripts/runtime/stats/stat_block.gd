class_name StatBlock
extends RefCounted

var base_values: Dictionary = {}
var final_values: Dictionary = {}
var modifiers: Array[StatModifier] = []
var _dirty: bool = true


func set_base(stat_id: StringName, value: float) -> void:
	base_values[stat_id] = value
	_dirty = true


func add_modifier(modifier: StatModifier) -> void:
	modifiers.append(modifier)
	_dirty = true


func remove_source(source_id: String) -> void:
	modifiers = modifiers.filter(func(modifier: StatModifier) -> bool:
		return modifier.source_id != source_id
	)
	_dirty = true


func get_value(stat_id: StringName, default_value: float = 0.0) -> float:
	if _dirty:
		_rebuild()
	return float(final_values.get(stat_id, default_value))


func snapshot() -> Dictionary:
	if _dirty:
		_rebuild()
	return final_values.duplicate(true)


func _rebuild() -> void:
	final_values = base_values.duplicate(true)
	var ordered := modifiers.duplicate()
	ordered.sort_custom(func(a: StatModifier, b: StatModifier) -> bool:
		return a.priority < b.priority
	)

	var grouped: Dictionary = {}
	for modifier: StatModifier in ordered:
		if not grouped.has(modifier.stat_id):
			grouped[modifier.stat_id] = []
		grouped[modifier.stat_id].append(modifier)

	for stat_id: StringName in grouped:
		var base: float = float(base_values.get(stat_id, 0.0))
		var flat: float = 0.0
		var additive_percent: float = 0.0
		var multiplier: float = 1.0
		for modifier: StatModifier in grouped[stat_id]:
			match modifier.operation:
				StatModifier.Operation.FLAT:
					flat += modifier.value
				StatModifier.Operation.ADDITIVE_PERCENT:
					additive_percent += modifier.value
				StatModifier.Operation.MULTIPLICATIVE_PERCENT:
					multiplier *= 1.0 + modifier.value
		final_values[stat_id] = (base + flat) * (1.0 + additive_percent) * multiplier

	_dirty = false
