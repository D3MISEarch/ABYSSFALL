class_name ClassTreeNodeDefinition
extends RefCounted

enum NodeType {
	ROOT,
	MINOR,
	NOTABLE,
	ACTIVE_SKILL,
	REFINEMENT,
	MUTATION,
	LAW,
	CULMINATION,
	TRIAL,
	BRIDGE,
}

var node_id: StringName = &""
var node_type: NodeType = NodeType.MINOR
var display_name: String = ""
var maximum_rank: int = 1
var rank_costs: Array[int] = []
var prerequisites: Dictionary = {}
var exclusion_group: StringName = &""
var effects: Array[Dictionary] = []


func _init(
	p_node_id: StringName = &"",
	p_node_type: NodeType = NodeType.MINOR,
	p_display_name: String = "",
	p_maximum_rank: int = 1,
	p_rank_costs: Array[int] = [],
	p_prerequisites: Dictionary = {},
	p_exclusion_group: StringName = &"",
	p_effects: Array[Dictionary] = []
) -> void:
	node_id = p_node_id
	node_type = p_node_type
	display_name = p_display_name
	maximum_rank = maxi(1, p_maximum_rank)
	rank_costs = p_rank_costs.duplicate()
	prerequisites = p_prerequisites.duplicate(true)
	exclusion_group = p_exclusion_group
	effects = p_effects.duplicate(true)


func is_valid() -> bool:
	if node_id == &"" or display_name.strip_edges().is_empty():
		return false
	if rank_costs.size() != maximum_rank:
		return false
	for cost: int in rank_costs:
		if cost <= 0:
			return false
	for raw_prerequisite: Variant in prerequisites:
		var prerequisite_id := StringName(str(raw_prerequisite))
		var required_rank := int(prerequisites[raw_prerequisite])
		if prerequisite_id == &"" or prerequisite_id == node_id or required_rank <= 0:
			return false
	for effect: Dictionary in effects:
		if not _effect_is_valid(effect):
			return false
	return true


func cost_for_rank(rank: int) -> int:
	if rank < 1 or rank > maximum_rank:
		return -1
	return rank_costs[rank - 1]


func total_cost_for_rank(rank: int) -> int:
	if rank < 0 or rank > maximum_rank:
		return -1
	var total := 0
	for index in range(rank):
		total += rank_costs[index]
	return total


func duplicate_definition() -> ClassTreeNodeDefinition:
	return ClassTreeNodeDefinition.new(
		node_id,
		node_type,
		display_name,
		maximum_rank,
		rank_costs,
		prerequisites,
		exclusion_group,
		effects
	)


func _effect_is_valid(effect: Dictionary) -> bool:
	if str(effect.get("effect_type", "")) != "stat_modifier":
		return false
	if StringName(str(effect.get("stat_id", ""))) == &"":
		return false
	var operation := int(effect.get("operation", -1))
	if operation < StatModifier.Operation.FLAT or operation > StatModifier.Operation.MULTIPLICATIVE_PERCENT:
		return false
	var value: Variant = effect.get("value", null)
	return value is int or value is float
