class_name ClassTreeCatalog
extends RefCounted

var _definitions: Dictionary = {}


func register(definition: ClassTreeDefinition) -> bool:
	if definition == null or not definition.is_valid() or _definitions.has(definition.class_id):
		return false
	_definitions[definition.class_id] = definition.duplicate_definition()
	return true


func get_definition(class_id: String) -> ClassTreeDefinition:
	var stored: ClassTreeDefinition = _definitions.get(class_id.strip_edges())
	return stored.duplicate_definition() if stored != null else null


func has_definition(class_id: String) -> bool:
	return _definitions.has(class_id.strip_edges())


func register_framework_proofs() -> bool:
	var registered_void := register(_build_framework_proof(ClassIds.VOID_WARLOCK, "Void Points"))
	var registered_penitent := register(_build_framework_proof(ClassIds.PENITENT, "Class Points"))
	return registered_void and registered_penitent


func _build_framework_proof(class_id: String, point_name: String) -> ClassTreeDefinition:
	var nodes: Array[ClassTreeNodeDefinition] = [
		ClassTreeNodeDefinition.new(
			&"proof_origin",
			ClassTreeNodeDefinition.NodeType.ROOT,
			"Core Identity",
			1,
			[1],
			{},
			&"",
			[_stat_effect(&"armor", StatModifier.Operation.FLAT, 2.0)]
		),
		ClassTreeNodeDefinition.new(
			&"proof_force",
			ClassTreeNodeDefinition.NodeType.MINOR,
			"Applied Force",
			2,
			[1, 1],
			{"proof_origin": 1},
			&"",
			[_stat_effect(&"power", StatModifier.Operation.FLAT, 4.0)]
		),
		ClassTreeNodeDefinition.new(
			&"proof_guard",
			ClassTreeNodeDefinition.NodeType.MINOR,
			"Hardened Form",
			2,
			[1, 1],
			{"proof_origin": 1},
			&"",
			[_stat_effect(&"armor", StatModifier.Operation.FLAT, 3.0)]
		),
		ClassTreeNodeDefinition.new(
			&"proof_notable",
			ClassTreeNodeDefinition.NodeType.NOTABLE,
			"Controlled Rupture",
			1,
			[1],
			{"proof_force": 1},
			&"",
			[_stat_effect(&"critical_chance", StatModifier.Operation.ADDITIVE_PERCENT, 0.05)]
		),
		ClassTreeNodeDefinition.new(
			&"proof_bridge",
			ClassTreeNodeDefinition.NodeType.BRIDGE,
			"Cross-Path Stabilizer",
			1,
			[1],
			{"proof_force": 1, "proof_guard": 1},
			&"",
			[_stat_effect(&"armor", StatModifier.Operation.FLAT, 5.0)]
		),
		ClassTreeNodeDefinition.new(
			&"proof_law",
			ClassTreeNodeDefinition.NodeType.LAW,
			"Law of Violent Compression",
			1,
			[2],
			{"proof_notable": 1},
			&"proof_major_law",
			[
				_stat_effect(&"power", StatModifier.Operation.ADDITIVE_PERCENT, 0.20),
				_stat_effect(&"armor", StatModifier.Operation.FLAT, -4.0),
			]
		),
		ClassTreeNodeDefinition.new(
			&"proof_law_guard",
			ClassTreeNodeDefinition.NodeType.LAW,
			"Law of Anchored Defiance",
			1,
			[2],
			{"proof_guard": 1},
			&"proof_major_law",
			[
				_stat_effect(&"armor", StatModifier.Operation.ADDITIVE_PERCENT, 0.20),
				_stat_effect(&"power", StatModifier.Operation.FLAT, -4.0),
			]
		),
		ClassTreeNodeDefinition.new(
			&"proof_culmination",
			ClassTreeNodeDefinition.NodeType.CULMINATION,
			"Framework Culmination",
			1,
			[2],
			{"proof_bridge": 1, "proof_law": 1},
			&"",
			[_stat_effect(&"power", StatModifier.Operation.MULTIPLICATIVE_PERCENT, 0.10)]
		),
	]
	return ClassTreeDefinition.new(
		class_id,
		&"framework_proof_v1",
		1,
		point_name,
		[&"proof_origin"],
		nodes,
		2,
		1
	)


func _stat_effect(stat_id: StringName, operation: int, value: float, priority: int = 20) -> Dictionary:
	return {
		"effect_type": "stat_modifier",
		"stat_id": String(stat_id),
		"operation": int(operation),
		"value": value,
		"priority": priority,
	}
