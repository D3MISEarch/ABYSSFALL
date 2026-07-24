class_name ClassTreeNavigationModel
extends RefCounted

const DIRECTIONS: Array[StringName] = [&"left", &"right", &"up", &"down"]

var _positions: Dictionary = {}
var _neighbors: Dictionary = {}


func configure(nodes: Array) -> bool:
	var candidate_positions: Dictionary = {}
	var candidate_neighbors: Dictionary = {}
	for raw_node: Variant in nodes:
		if not raw_node is Dictionary:
			return false
		var node_id := StringName(str(raw_node.get("node_id", "")).strip_edges())
		var position_value: Variant = raw_node.get("position", null)
		if node_id == &"" or candidate_positions.has(node_id) or not position_value is Vector2:
			return false
		candidate_positions[node_id] = position_value
		var raw_neighbors: Variant = raw_node.get("neighbors", {})
		if not raw_neighbors is Dictionary:
			return false
		candidate_neighbors[node_id] = raw_neighbors.duplicate(true)

	if candidate_positions.is_empty():
		return false
	for node_id: StringName in candidate_neighbors:
		var authored: Dictionary = candidate_neighbors[node_id]
		for direction: StringName in DIRECTIONS:
			var neighbor_id := StringName(str(authored.get(String(direction), "")))
			if neighbor_id == &"":
				continue
			if neighbor_id == node_id or not candidate_positions.has(neighbor_id):
				return false

	_positions = candidate_positions
	_neighbors = candidate_neighbors
	return true


func neighbor(node_id: StringName, direction: StringName) -> StringName:
	if not _positions.has(node_id) or not DIRECTIONS.has(direction):
		return &""
	var authored: Dictionary = _neighbors.get(node_id, {})
	var explicit := StringName(str(authored.get(String(direction), "")))
	if explicit != &"":
		return explicit
	return _spatial_neighbor(node_id, direction)


func all_node_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for raw_id: Variant in _positions:
		result.append(StringName(str(raw_id)))
	result.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return result


func position_of(node_id: StringName) -> Vector2:
	return _positions.get(node_id, Vector2.ZERO)


func reachable_from(start_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if not _positions.has(start_id):
		return result
	var queue: Array[StringName] = [start_id]
	var visited: Dictionary = {}
	visited[start_id] = true
	while not queue.is_empty():
		var current: StringName = queue.pop_front()
		result.append(current)
		for direction: StringName in DIRECTIONS:
			var next_id := neighbor(current, direction)
			if next_id == &"" or visited.has(next_id):
				continue
			visited[next_id] = true
			queue.append(next_id)
	return result


func _spatial_neighbor(node_id: StringName, direction: StringName) -> StringName:
	var origin: Vector2 = _positions[node_id]
	var direction_vector := _direction_vector(direction)
	var best_id: StringName = &""
	var best_score := INF
	for raw_id: Variant in _positions:
		var candidate_id := StringName(str(raw_id))
		if candidate_id == node_id:
			continue
		var delta: Vector2 = _positions[candidate_id] - origin
		var forward := delta.dot(direction_vector)
		if forward <= 0.001:
			continue
		var perpendicular := absf(delta.cross(direction_vector))
		var score := forward + perpendicular * 2.5
		if score < best_score or (is_equal_approx(score, best_score) and String(candidate_id) < String(best_id)):
			best_score = score
			best_id = candidate_id
	return best_id


func _direction_vector(direction: StringName) -> Vector2:
	match direction:
		&"left":
			return Vector2.LEFT
		&"right":
			return Vector2.RIGHT
		&"up":
			return Vector2.UP
		&"down":
			return Vector2.DOWN
		_:
			return Vector2.ZERO
