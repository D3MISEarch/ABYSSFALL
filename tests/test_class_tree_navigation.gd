extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_framework_authored_neighbors()
	_test_dense_fixture_reaches_every_node()
	_test_invalid_layouts_are_transactional()
	if failures.is_empty():
		print("PASS: Class tree navigation model")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_framework_authored_neighbors() -> void:
	var model := ClassTreeNavigationModel.new()
	_expect(model.configure(ClassTreeLayoutFixtures.framework_nodes()), "Framework navigation layout should configure")
	_expect(model.neighbor(&"proof_origin", &"right") == &"proof_force", "Origin should enter the force route")
	_expect(model.neighbor(&"proof_force", &"down") == &"proof_guard", "Controller should cross between the two early routes")
	_expect(model.neighbor(&"proof_law", &"right") == &"proof_culmination", "Law route should reach the Culmination")
	_expect(model.reachable_from(&"proof_origin").size() == 8, "Every framework node should be controller reachable")


func _test_dense_fixture_reaches_every_node() -> void:
	var nodes := ClassTreeLayoutFixtures.dense_navigation_nodes()
	var model := ClassTreeNavigationModel.new()
	_expect(nodes.size() == 25, "Dense stress fixture should contain exactly 25 nodes")
	_expect(model.configure(nodes), "Dense navigation fixture should configure")
	var reachable := model.reachable_from(&"dense_root")
	_expect(reachable.size() == nodes.size(), "Controller traversal should reach every dense fixture node")
	_expect(reachable.has(&"d_dead_top") and reachable.has(&"d_dead_low"), "Dead-end stress branches must remain reachable")
	_expect(reachable.has(&"dense_culmination"), "Distant Culmination must remain reachable")
	for node_id: StringName in model.all_node_ids():
		for direction: StringName in ClassTreeNavigationModel.DIRECTIONS:
			var neighbor_id := model.neighbor(node_id, direction)
			_expect(neighbor_id == &"" or model.all_node_ids().has(neighbor_id), "Navigation must never target a missing node")


func _test_invalid_layouts_are_transactional() -> void:
	var model := ClassTreeNavigationModel.new()
	_expect(model.configure(ClassTreeLayoutFixtures.framework_nodes()), "Valid seed layout should configure")
	var before := model.reachable_from(&"proof_origin")
	var invalid := ClassTreeLayoutFixtures.framework_nodes()
	invalid.append({"node_id": "proof_origin", "position": Vector2.ZERO, "neighbors": {}})
	_expect(not model.configure(invalid), "Duplicate node IDs should reject navigation configuration")
	_expect(model.reachable_from(&"proof_origin") == before, "Rejected navigation configuration must preserve prior state")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
