extends SceneTree

const PROGRESSION_BRIDGE_SCRIPT = preload("res://scripts/ui/playable_progression_bridge.gd")
const CLASS_TREE_SCREEN_SCRIPT = preload("res://scripts/ui/class_tree_screen.gd")
const GAMEPLAY_PAUSE_BOUNDARY = preload("res://scripts/ui/gameplay_pause_boundary.gd")

var failures: Array[String] = []
var purchase_requests := 0
var last_purchase_id: StringName = &""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_graphical_tree_inspection_and_purchase_lock()
	_test_dense_board_focusability()
	_test_real_pause_boundary()
	paused = false
	if failures.is_empty():
		print("PASS: Graphical class tree shell")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_graphical_tree_inspection_and_purchase_lock() -> void:
	purchase_requests = 0
	last_purchase_id = &""
	var build := BuildData.create_new(ClassIds.VOID_WARLOCK, "Graphical Tree Test")
	build.level = 3
	var bridge := PROGRESSION_BRIDGE_SCRIPT.new() as PlayableProgressionBridge
	root.add_child(bridge)
	_expect(bridge.configure_ephemeral(build), "Graphical test bridge should configure")

	var screen := CLASS_TREE_SCREEN_SCRIPT.new() as ClassTreeScreen
	screen.size = Vector2(930.0, 478.0)
	screen.purchase_requested.connect(_on_purchase_requested)
	root.add_child(screen)
	_expect(screen.set_tree_snapshot(bridge.tree_snapshot()), "Graphical tree should accept the framework snapshot")
	_expect(screen.node_count() == 8, "Graphical tree should build all eight framework nodes")
	_expect(screen.selected_node_id() == &"proof_origin", "Graphical tree should select the authored root first")
	_expect(screen.board.is_node_focusable(&"proof_force"), "Locked nodes must remain focusable for inspection")
	_expect(screen.select_node(&"proof_force"), "Controller focus should reach a locked child")
	_expect(screen.selected_node_id() == &"proof_force", "Locked-node inspection should preserve selection")
	_expect(screen.node_title.text == "Applied Force", "Locked-node inspection should populate the detail panel")
	_expect(screen.purchase_button.disabled, "Locked node must not expose an enabled purchase action")

	_expect(screen.select_node(&"proof_origin"), "Controller focus should return to the root")
	screen.request_selected_purchase()
	screen.request_selected_purchase()
	_expect(purchase_requests == 1 and last_purchase_id == &"proof_origin", "Rapid confirmation must emit only one purchase request")
	var purchase := bridge.purchase_node(&"proof_origin")
	_expect(bool(purchase.get("success", false)), "Runtime should accept the requested root purchase")
	_expect(screen.set_tree_snapshot(bridge.tree_snapshot()), "Successful runtime purchase should refresh the graphical tree")
	_expect(screen.select_node(&"proof_force"), "Unlocked child should remain focusable after refresh")
	_expect(not screen.purchase_button.disabled, "Unlocked affordable child should enable purchase")
	screen.request_selected_purchase()
	_expect(purchase_requests == 2 and last_purchase_id == &"proof_force", "Refresh should release the purchase lock for the next node")

	screen.board.zoom_by(10.0)
	_expect(is_equal_approx(screen.board.zoom_value(), ClassTreeBoard.MAX_ZOOM), "Graphical board zoom should clamp at the authored maximum")
	screen.board.zoom_by(-10.0)
	_expect(is_equal_approx(screen.board.zoom_value(), ClassTreeBoard.MIN_ZOOM), "Graphical board zoom should clamp at the authored minimum")
	var pan_before := screen.board.pan_value()
	screen.board.pan_by(Vector2(25.0, -15.0))
	_expect(screen.board.pan_value() == pan_before + Vector2(25.0, -15.0), "Graphical board should preserve explicit pan input")

	screen.queue_free()
	bridge.queue_free()


func _test_dense_board_focusability() -> void:
	var nodes: Array[Dictionary] = []
	for layout: Dictionary in ClassTreeLayoutFixtures.dense_navigation_nodes():
		var node := layout.duplicate(true)
		node.merge({
			"display_name": str(layout.get("node_id", "Dense Node")).replace("_", " ").capitalize(),
			"node_type": "Minor",
			"rank": 0,
			"maximum_rank": 1,
			"next_cost": 1,
			"prerequisites": "Stress fixture",
			"prerequisite_ids": [],
			"effects": "+1 Navigation",
			"visual_state": "locked",
			"can_purchase": false,
		}, true)
		nodes.append(node)
	var board := ClassTreeBoard.new()
	board.size = Vector2(690.0, 408.0)
	root.add_child(board)
	_expect(board.set_tree_snapshot({"nodes": nodes}), "Graphical board should build the 25-node dense fixture")
	_expect(board.node_count() == 25, "Dense graphical fixture should retain all 25 nodes")
	for node_id: StringName in board.navigation.all_node_ids():
		_expect(board.is_node_focusable(node_id), "Every dense fixture node must remain focusable, including dead ends")
	board.queue_free()


func _test_real_pause_boundary() -> void:
	var host := Node.new()
	host.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(host)
	var canvas := CanvasLayer.new()
	var plumbing := Node.new()
	var gameplay := Node.new()
	var enemy := Node.new()
	host.add_child(canvas)
	host.add_child(plumbing)
	host.add_child(gameplay)
	gameplay.add_child(enemy)
	var always_nodes: Array[Node] = [plumbing]
	_expect(GAMEPLAY_PAUSE_BOUNDARY.apply(host, always_nodes), "Pause boundary should apply to the gameplay root")
	paused = true
	_expect(canvas.can_process(), "Canvas UI must remain responsive while the tree is open")
	_expect(plumbing.can_process(), "Explicit persistence/progression plumbing must remain responsive")
	_expect(not gameplay.can_process(), "Direct gameplay children must stop while the tree is open")
	_expect(not enemy.can_process(), "Gameplay descendants must inherit the real paused state")
	paused = false
	host.queue_free()


func _on_purchase_requested(node_id: StringName) -> void:
	purchase_requests += 1
	last_purchase_id = node_id


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
