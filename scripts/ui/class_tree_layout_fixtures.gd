class_name ClassTreeLayoutFixtures
extends RefCounted


static func framework_nodes() -> Array[Dictionary]:
	return [
		_node("proof_origin", Vector2(70.0, 205.0), {"right": "proof_force"}),
		_node("proof_force", Vector2(245.0, 100.0), {"left": "proof_origin", "down": "proof_guard", "right": "proof_notable"}),
		_node("proof_guard", Vector2(245.0, 310.0), {"left": "proof_origin", "up": "proof_force", "right": "proof_bridge"}),
		_node("proof_notable", Vector2(425.0, 75.0), {"left": "proof_force", "down": "proof_bridge", "right": "proof_law"}),
		_node("proof_bridge", Vector2(435.0, 225.0), {"left": "proof_guard", "up": "proof_notable", "down": "proof_law_guard", "right": "proof_law"}),
		_node("proof_law", Vector2(625.0, 90.0), {"left": "proof_notable", "down": "proof_law_guard", "right": "proof_culmination"}),
		_node("proof_law_guard", Vector2(625.0, 320.0), {"left": "proof_bridge", "up": "proof_law", "right": "proof_culmination"}),
		_node("proof_culmination", Vector2(825.0, 205.0), {"left": "proof_law"}),
	]


static func framework_map() -> Dictionary:
	var result: Dictionary = {}
	for node: Dictionary in framework_nodes():
		result[str(node["node_id"])] = node.duplicate(true)
	return result


static func dense_navigation_nodes() -> Array[Dictionary]:
	var columns: Array = [
		[["dense_root", 205.0]],
		[["a_top", 70.0], ["a_mid", 205.0], ["a_low", 340.0]],
		[["b_0", 30.0], ["b_1", 140.0], ["b_2", 270.0], ["b_3", 385.0]],
		[["c_0", 0.0], ["c_1", 95.0], ["c_2", 205.0], ["c_3", 315.0], ["c_4", 415.0]],
		[["d_dead_top", -100.0], ["d_0", 55.0], ["d_1", 155.0], ["d_2", 255.0], ["d_3", 355.0], ["d_dead_low", 515.0]],
		[["e_0", 0.0], ["e_1", 100.0], ["e_2", 205.0], ["e_3", 310.0], ["e_4", 415.0]],
		[["dense_culmination", 205.0]],
	]
	var nodes: Array[Dictionary] = []
	for column_index in range(columns.size()):
		var column: Array = columns[column_index]
		var x := float(column_index) * 170.0
		for row_index in range(column.size()):
			var entry: Array = column[row_index]
			var neighbors: Dictionary = {}
			if row_index > 0:
				neighbors["up"] = str(column[row_index - 1][0])
			if row_index + 1 < column.size():
				neighbors["down"] = str(column[row_index + 1][0])
			if column_index > 0:
				neighbors["left"] = _nearest_id(columns[column_index - 1], float(entry[1]))
			if column_index + 1 < columns.size():
				neighbors["right"] = _nearest_id(columns[column_index + 1], float(entry[1]))
			nodes.append(_node(str(entry[0]), Vector2(x, float(entry[1])), neighbors))
	return nodes


static func _nearest_id(column: Array, target_y: float) -> String:
	var best_id := ""
	var best_distance := INF
	for raw_entry: Variant in column:
		var entry: Array = raw_entry
		var distance := absf(float(entry[1]) - target_y)
		if distance < best_distance:
			best_distance = distance
			best_id = str(entry[0])
	return best_id


static func _node(node_id: String, position: Vector2, neighbors: Dictionary) -> Dictionary:
	return {
		"node_id": node_id,
		"position": position,
		"neighbors": neighbors.duplicate(true),
	}
