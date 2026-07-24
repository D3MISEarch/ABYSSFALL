class_name ClassTreeDefinition
extends RefCounted

var class_id: String = ""
var schema_id: StringName = &""
var schema_version: int = 1
var point_display_name: String = "Class Points"
var root_node_ids: Array[StringName] = []
var first_level_award: int = 2
var points_per_level: int = 1
var _nodes: Dictionary = {}
var _valid: bool = false


func _init(
	p_class_id: String = "",
	p_schema_id: StringName = &"",
	p_schema_version: int = 1,
	p_point_display_name: String = "Class Points",
	p_root_node_ids: Array[StringName] = [],
	p_nodes: Array[ClassTreeNodeDefinition] = [],
	p_first_level_award: int = 2,
	p_points_per_level: int = 1
) -> void:
	class_id = p_class_id.strip_edges()
	schema_id = p_schema_id
	schema_version = maxi(1, p_schema_version)
	point_display_name = p_point_display_name.strip_edges()
	root_node_ids = p_root_node_ids.duplicate()
	first_level_award = maxi(2, p_first_level_award)
	points_per_level = maxi(0, p_points_per_level)
	for definition: ClassTreeNodeDefinition in p_nodes:
		if definition == null or _nodes.has(definition.node_id):
			_valid = false
			return
		_nodes[definition.node_id] = definition.duplicate_definition()
	_valid = _validate_integrity()


func is_valid() -> bool:
	return _valid


func get_node(node_id: StringName) -> ClassTreeNodeDefinition:
	var stored: ClassTreeNodeDefinition = _nodes.get(node_id)
	return stored.duplicate_definition() if stored != null else null


func has_node(node_id: StringName) -> bool:
	return _nodes.has(node_id)


func all_node_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for raw_id: Variant in _nodes:
		result.append(StringName(str(raw_id)))
	result.sort()
	return result


func point_award_for_level(level: int) -> int:
	return points_per_level if level >= first_level_award else 0


func duplicate_definition() -> ClassTreeDefinition:
	var nodes: Array[ClassTreeNodeDefinition] = []
	for node_id: StringName in all_node_ids():
		nodes.append(get_node(node_id))
	return ClassTreeDefinition.new(
		class_id,
		schema_id,
		schema_version,
		point_display_name,
		root_node_ids,
		nodes,
		first_level_award,
		points_per_level
	)


func _validate_integrity() -> bool:
	if class_id.is_empty() or schema_id == &"" or point_display_name.is_empty() or _nodes.is_empty():
		return false
	if root_node_ids.is_empty():
		return false
	for root_id: StringName in root_node_ids:
		if not _nodes.has(root_id):
			return false
	for node_id: StringName in all_node_ids():
		var node: ClassTreeNodeDefinition = _nodes[node_id]
		if not node.is_valid():
			return false
		for raw_prerequisite: Variant in node.prerequisites:
			var prerequisite_id := StringName(str(raw_prerequisite))
			var prerequisite: ClassTreeNodeDefinition = _nodes.get(prerequisite_id)
			if prerequisite == null or int(node.prerequisites[raw_prerequisite]) > prerequisite.maximum_rank:
				return false
	return not _has_prerequisite_cycle()


func _has_prerequisite_cycle() -> bool:
	var visiting: Dictionary = {}
	var visited: Dictionary = {}
	for node_id: StringName in all_node_ids():
		if _visit_for_cycle(node_id, visiting, visited):
			return true
	return false


func _visit_for_cycle(node_id: StringName, visiting: Dictionary, visited: Dictionary) -> bool:
	if bool(visiting.get(node_id, false)):
		return true
	if bool(visited.get(node_id, false)):
		return false
	visiting[node_id] = true
	var node: ClassTreeNodeDefinition = _nodes[node_id]
	for raw_prerequisite: Variant in node.prerequisites:
		if _visit_for_cycle(StringName(str(raw_prerequisite)), visiting, visited):
			return true
	visiting.erase(node_id)
	visited[node_id] = true
	return false
