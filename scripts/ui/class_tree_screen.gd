class_name ClassTreeScreen
extends Control

signal purchase_requested(node_id: StringName)

const BOARD_SCRIPT = preload("res://scripts/ui/class_tree_board.gd")

var board: ClassTreeBoard
var points_label: Label
var node_title: Label
var node_meta: Label
var node_effects: Label
var node_prerequisites: Label
var node_state: Label
var purchase_button: Button
var zoom_label: Label
var _snapshot: Dictionary = {}
var _nodes: Dictionary = {}
var _selected_id: StringName = &""
var _purchase_locked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func set_tree_snapshot(snapshot: Dictionary) -> bool:
	var raw_nodes: Variant = snapshot.get("nodes", [])
	if not raw_nodes is Array:
		_set_detail_message("CLASS PROGRESSION DATA IS INVALID")
		return false
	var candidate_nodes: Dictionary = {}
	for raw_node: Variant in raw_nodes:
		if not raw_node is Dictionary:
			_set_detail_message("CLASS PROGRESSION DATA IS INVALID")
			return false
		var node_id := StringName(str(raw_node.get("node_id", "")))
		if node_id == &"" or candidate_nodes.has(node_id):
			_set_detail_message("CLASS PROGRESSION DATA IS INVALID")
			return false
		candidate_nodes[node_id] = raw_node.duplicate(true)
	if not board.set_tree_snapshot(snapshot):
		_set_detail_message("CLASS TREE LAYOUT COULD NOT BE BUILT")
		return false

	_snapshot = snapshot.duplicate(true)
	_nodes = candidate_nodes
	var projection: Dictionary = snapshot.get("combat_projection", {})
	points_label.text = "%s: %d     ARMOR %.0f     POWER %.1f     CRIT %.1f%%" % [
		str(snapshot.get("point_display_name", "Class Points")).to_upper(),
		int(snapshot.get("available_points", 0)),
		float(projection.get("armor", 0.0)),
		float(projection.get("power", 0.0)),
		float(projection.get("critical_chance", 0.0)) * 100.0,
	]
	_purchase_locked = false
	if _selected_id == &"" or not _nodes.has(_selected_id):
		_selected_id = board.selected_node_id()
	else:
		board.focus_node(_selected_id)
	_refresh_details()
	return true


func show_unavailable(message: String) -> void:
	_snapshot = {}
	_nodes.clear()
	_selected_id = &""
	_purchase_locked = false
	if board != null:
		board.clear_tree()
	points_label.text = message
	_set_detail_message("UNBOUND")


func focus_initial() -> void:
	board.focus_initial()
	_selected_id = board.selected_node_id()
	_refresh_details()


func select_node(node_id: StringName) -> bool:
	return board.focus_node(node_id)


func request_selected_purchase() -> void:
	_request_purchase()


func node_count() -> int:
	return board.node_count()


func selected_node_id() -> StringName:
	return _selected_id


func reset_purchase_lock() -> void:
	_purchase_locked = false
	_refresh_details()


func _build_ui() -> void:
	points_label = Label.new()
	points_label.position = Vector2(8.0, 0.0)
	points_label.size = Vector2(920.0, 28.0)
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_label.add_theme_font_size_override("font_size", 16)
	points_label.modulate = Color(0.90, 0.78, 1.0)
	add_child(points_label)

	board = BOARD_SCRIPT.new() as ClassTreeBoard
	board.position = Vector2(0.0, 32.0)
	board.size = Vector2(690.0, 408.0)
	board.node_selected.connect(_on_node_selected)
	board.node_activated.connect(_on_node_activated)
	board.view_changed.connect(_on_view_changed)
	add_child(board)

	var detail_back := ColorRect.new()
	detail_back.position = Vector2(700.0, 32.0)
	detail_back.size = Vector2(230.0, 408.0)
	detail_back.color = Color(0.028, 0.014, 0.044, 0.98)
	add_child(detail_back)

	node_title = Label.new()
	node_title.position = Vector2(12.0, 12.0)
	node_title.size = Vector2(206.0, 56.0)
	node_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node_title.add_theme_font_size_override("font_size", 19)
	detail_back.add_child(node_title)

	node_meta = Label.new()
	node_meta.position = Vector2(12.0, 72.0)
	node_meta.size = Vector2(206.0, 44.0)
	node_meta.add_theme_font_size_override("font_size", 13)
	detail_back.add_child(node_meta)

	node_effects = Label.new()
	node_effects.position = Vector2(12.0, 120.0)
	node_effects.size = Vector2(206.0, 92.0)
	node_effects.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_back.add_child(node_effects)

	node_prerequisites = Label.new()
	node_prerequisites.position = Vector2(12.0, 218.0)
	node_prerequisites.size = Vector2(206.0, 72.0)
	node_prerequisites.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_back.add_child(node_prerequisites)

	node_state = Label.new()
	node_state.position = Vector2(12.0, 294.0)
	node_state.size = Vector2(206.0, 28.0)
	node_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node_state.add_theme_font_size_override("font_size", 13)
	detail_back.add_child(node_state)

	purchase_button = Button.new()
	purchase_button.position = Vector2(12.0, 326.0)
	purchase_button.size = Vector2(206.0, 38.0)
	purchase_button.text = "PURCHASE RANK"
	purchase_button.pressed.connect(_request_purchase)
	detail_back.add_child(purchase_button)

	var reset_button := Button.new()
	reset_button.position = Vector2(12.0, 370.0)
	reset_button.size = Vector2(98.0, 28.0)
	reset_button.text = "CENTER"
	reset_button.pressed.connect(board.reset_view)
	detail_back.add_child(reset_button)

	zoom_label = Label.new()
	zoom_label.position = Vector2(116.0, 373.0)
	zoom_label.size = Vector2(102.0, 24.0)
	zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	zoom_label.text = "ZOOM 85%"
	detail_back.add_child(zoom_label)

	var hint := Label.new()
	hint.position = Vector2(0.0, 444.0)
	hint.size = Vector2(930.0, 30.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "MOUSE WHEEL / SHOULDERS: ZOOM     MIDDLE DRAG / RIGHT STICK: PAN     A / CLICK: SELECT OR PURCHASE"
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate = Color(0.62, 0.58, 0.70)
	add_child(hint)

	_set_detail_message("CLASS PROGRESSION IS NOT YET BOUND")


func _on_node_selected(node_id: StringName) -> void:
	_selected_id = node_id
	_refresh_details()


func _on_node_activated(node_id: StringName) -> void:
	_selected_id = node_id
	_refresh_details()
	if bool(_nodes.get(node_id, {}).get("can_purchase", false)):
		_request_purchase()


func _request_purchase() -> void:
	if _purchase_locked or _selected_id == &"":
		return
	var node: Dictionary = _nodes.get(_selected_id, {})
	if not bool(node.get("can_purchase", false)):
		return
	_purchase_locked = true
	purchase_button.disabled = true
	purchase_requested.emit(_selected_id)


func _refresh_details() -> void:
	var node: Dictionary = _nodes.get(_selected_id, {})
	if node.is_empty():
		_set_detail_message("SELECT A NODE")
		return
	var rank := int(node.get("rank", 0))
	var maximum_rank := int(node.get("maximum_rank", 1))
	var next_cost := int(node.get("next_cost", -1))
	node_title.text = str(node.get("display_name", "Unknown Node"))
	node_meta.text = "%s\nRANK %d / %d" % [str(node.get("node_type", "Node")).to_upper(), rank, maximum_rank]
	node_effects.text = "EFFECT\n%s" % str(node.get("effects", "No authored effect"))
	node_prerequisites.text = "REQUIRES\n%s" % str(node.get("prerequisites", "None"))
	var state := str(node.get("visual_state", "locked"))
	node_state.text = state.replace("_", " ").to_upper()
	node_state.modulate = _state_color(state)
	purchase_button.text = "MAXIMUM RANK" if next_cost < 0 else "PURCHASE — %d POINT%s" % [next_cost, "" if next_cost == 1 else "S"]
	purchase_button.disabled = _purchase_locked or not bool(node.get("can_purchase", false))


func _set_detail_message(message: String) -> void:
	node_title.text = message
	node_meta.text = ""
	node_effects.text = ""
	node_prerequisites.text = ""
	node_state.text = ""
	purchase_button.text = "PURCHASE RANK"
	purchase_button.disabled = true


func _on_view_changed(zoom: float) -> void:
	if zoom_label != null:
		zoom_label.text = "ZOOM %d%%" % int(round(zoom * 100.0))


func _state_color(state: String) -> Color:
	match state:
		"max_rank":
			return Color(0.54, 1.0, 0.35)
		"purchased":
			return Color(0.80, 0.58, 1.0)
		"available":
			return Color(1.0, 0.90, 0.55)
		"excluded":
			return Color(0.82, 0.16, 0.22)
		"unaffordable":
			return Color(0.74, 0.44, 0.30)
		_:
			return Color(0.55, 0.52, 0.62)
