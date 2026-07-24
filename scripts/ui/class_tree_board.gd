class_name ClassTreeBoard
extends Control

signal node_selected(node_id: StringName)
signal node_activated(node_id: StringName)
signal view_changed(zoom: float)

const NODE_SIZE := Vector2(154.0, 72.0)
const MIN_ZOOM := 0.55
const MAX_ZOOM := 1.35
const ZOOM_STEP := 0.10

var navigation := ClassTreeNavigationModel.new()
var _nodes: Dictionary = {}
var _buttons: Dictionary = {}
var _connections: Array[Dictionary] = []
var _selected_id: StringName = &""
var _zoom := 0.85
var _pan := Vector2(30.0, 30.0)
var _dragging := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	set_process(true)


func set_tree_snapshot(snapshot: Dictionary) -> bool:
	var raw_nodes: Variant = snapshot.get("nodes", [])
	if not raw_nodes is Array:
		return false
	var navigation_nodes: Array = []
	var candidate_nodes: Dictionary = {}
	for raw_node: Variant in raw_nodes:
		if not raw_node is Dictionary:
			return false
		var node_id := StringName(str(raw_node.get("node_id", "")))
		if node_id == &"" or candidate_nodes.has(node_id):
			return false
		var position_value: Variant = raw_node.get("position", null)
		var neighbors_value: Variant = raw_node.get("neighbors", {})
		if not position_value is Vector2 or not neighbors_value is Dictionary:
			return false
		candidate_nodes[node_id] = raw_node.duplicate(true)
		navigation_nodes.append({
			"node_id": String(node_id),
			"position": position_value,
			"neighbors": neighbors_value.duplicate(true),
		})
	var candidate_navigation := ClassTreeNavigationModel.new()
	if not candidate_navigation.configure(navigation_nodes):
		return false

	_clear_buttons()
	navigation = candidate_navigation
	_nodes = candidate_nodes
	_build_connections()
	_build_buttons()
	_wire_focus_neighbors()
	if not _nodes.has(_selected_id):
		_selected_id = _initial_node_id()
	_refresh_button_copy()
	call_deferred("reset_view")
	queue_redraw()
	return true


func clear_tree() -> void:
	_clear_buttons()
	navigation = ClassTreeNavigationModel.new()
	_nodes.clear()
	_selected_id = &""
	queue_redraw()


func node_count() -> int:
	return _nodes.size()


func selected_node_id() -> StringName:
	return _selected_id


func selected_node() -> Dictionary:
	var stored: Variant = _nodes.get(_selected_id, {})
	return stored.duplicate(true) if stored is Dictionary else {}


func focus_initial() -> void:
	if _selected_id == &"":
		_selected_id = _initial_node_id()
	focus_node(_selected_id)


func focus_node(node_id: StringName) -> bool:
	var button: Button = _buttons.get(node_id)
	if button == null:
		return false
	_select_node(node_id)
	button.grab_focus()
	return true


func is_node_focusable(node_id: StringName) -> bool:
	var button: Button = _buttons.get(node_id)
	return button != null and button.focus_mode == Control.FOCUS_ALL and not button.disabled


func activate_selected() -> bool:
	if _selected_id == &"" or not _buttons.has(_selected_id):
		return false
	node_activated.emit(_selected_id)
	return true


func reset_view() -> void:
	_zoom = 0.85
	var ids := navigation.all_node_ids()
	if ids.is_empty():
		_pan = size * 0.5
		_update_view()
		return
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for node_id: StringName in ids:
		var point := navigation.position_of(node_id)
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	var viewport_size := size if size.x > 1.0 and size.y > 1.0 else Vector2(680.0, 410.0)
	_pan = viewport_size * 0.5 - ((minimum + maximum) * 0.5) * _zoom
	_update_view()


func zoom_by(amount: float) -> void:
	_zoom_around(size * 0.5, amount)


func pan_by(offset: Vector2) -> void:
	_pan += offset
	_update_view()


func zoom_value() -> float:
	return _zoom


func pan_value() -> Vector2:
	return _pan


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var pan_input := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if pan_input.length_squared() > 0.04:
		_pan -= pan_input * 330.0 * delta
		_update_view()
	if Input.is_action_just_pressed("attack"):
		_zoom_around(size * 0.5, ZOOM_STEP)
	elif Input.is_action_just_pressed("rift"):
		_zoom_around(size * 0.5, -ZOOM_STEP)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			_zoom_around(mouse_event.position, ZOOM_STEP)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			_zoom_around(mouse_event.position, -ZOOM_STEP)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mouse_event.pressed
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_pan += motion.relative
		_update_view()
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.007, 0.022, 0.96), true)
	for connection: Dictionary in _connections:
		var source_id := StringName(str(connection.get("source", "")))
		var target_id := StringName(str(connection.get("target", "")))
		if source_id == &"" or target_id == &"":
			continue
		var target: Dictionary = _nodes.get(target_id, {})
		var state := str(target.get("visual_state", "locked"))
		var line_color := _state_color(state)
		line_color.a = 0.62
		draw_line(
			_world_to_view(navigation.position_of(source_id)),
			_world_to_view(navigation.position_of(target_id)),
			line_color,
			maxf(1.5, 3.0 * _zoom),
			true
		)


func _build_connections() -> void:
	_connections.clear()
	for raw_id: Variant in _nodes:
		var target_id := StringName(str(raw_id))
		var node: Dictionary = _nodes[target_id]
		var prerequisites: Variant = node.get("prerequisite_ids", [])
		if not prerequisites is Array:
			continue
		for raw_source: Variant in prerequisites:
			var source_id := StringName(str(raw_source))
			if _nodes.has(source_id):
				_connections.append({"source": source_id, "target": target_id})


func _build_buttons() -> void:
	for node_id: StringName in navigation.all_node_ids():
		var button := Button.new()
		button.name = "TreeNode_%s" % String(node_id).replace("-", "_")
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.size = NODE_SIZE
		button.custom_minimum_size = NODE_SIZE
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.pressed.connect(_on_button_pressed.bind(node_id))
		button.focus_entered.connect(_select_node.bind(node_id))
		button.mouse_entered.connect(_select_node.bind(node_id))
		add_child(button)
		_buttons[node_id] = button
	_update_view()


func _wire_focus_neighbors() -> void:
	for node_id: StringName in navigation.all_node_ids():
		var button: Button = _buttons.get(node_id)
		if button == null:
			continue
		for direction: StringName in ClassTreeNavigationModel.DIRECTIONS:
			var neighbor_id := navigation.neighbor(node_id, direction)
			var neighbor_button: Button = _buttons.get(neighbor_id)
			if neighbor_button == null:
				continue
			var path := button.get_path_to(neighbor_button)
			match direction:
				&"left":
					button.focus_neighbor_left = path
				&"right":
					button.focus_neighbor_right = path
				&"up":
					button.focus_neighbor_top = path
				&"down":
					button.focus_neighbor_bottom = path


func _clear_buttons() -> void:
	for raw_button: Variant in _buttons.values():
		var button := raw_button as Button
		if button != null:
			remove_child(button)
			button.queue_free()
	_buttons.clear()
	_connections.clear()


func _select_node(node_id: StringName) -> void:
	if not _nodes.has(node_id):
		return
	var changed := _selected_id != node_id
	_selected_id = node_id
	if changed:
		_refresh_button_copy()
		node_selected.emit(node_id)


func _on_button_pressed(node_id: StringName) -> void:
	_select_node(node_id)
	node_activated.emit(node_id)


func _refresh_button_copy() -> void:
	for raw_id: Variant in _buttons:
		var node_id := StringName(str(raw_id))
		var button: Button = _buttons[node_id]
		var node: Dictionary = _nodes.get(node_id, {})
		var rank := int(node.get("rank", 0))
		var maximum_rank := int(node.get("maximum_rank", 1))
		var prefix := "▶ " if node_id == _selected_id else ""
		button.text = "%s%s\n%s  %d/%d" % [
			prefix,
			str(node.get("display_name", "Unknown")),
			str(node.get("node_type", "Node")).to_upper(),
			rank,
			maximum_rank,
		]
		button.modulate = _state_color(str(node.get("visual_state", "locked")))
		button.tooltip_text = "%s\n%s\nRequires: %s" % [
			str(node.get("display_name", "Unknown")),
			str(node.get("effects", "")),
			str(node.get("prerequisites", "None")),
		]


func _update_view() -> void:
	for raw_id: Variant in _buttons:
		var node_id := StringName(str(raw_id))
		var button: Button = _buttons[node_id]
		button.scale = Vector2.ONE * _zoom
		button.position = _world_to_view(navigation.position_of(node_id)) - NODE_SIZE * _zoom * 0.5
	queue_redraw()
	view_changed.emit(_zoom)


func _zoom_around(view_point: Vector2, amount: float) -> void:
	var previous_zoom := _zoom
	var next_zoom := clampf(_zoom + amount, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(previous_zoom, next_zoom):
		return
	var world_point := (view_point - _pan) / previous_zoom
	_zoom = next_zoom
	_pan = view_point - world_point * _zoom
	_update_view()


func _world_to_view(world_point: Vector2) -> Vector2:
	return _pan + world_point * _zoom


func _initial_node_id() -> StringName:
	if _nodes.has(&"proof_origin"):
		return &"proof_origin"
	var ids := navigation.all_node_ids()
	return ids[0] if not ids.is_empty() else &""


func _state_color(state: String) -> Color:
	match state:
		"max_rank":
			return Color(0.54, 1.0, 0.35)
		"purchased":
			return Color(0.80, 0.58, 1.0)
		"available":
			return Color(1.0, 0.90, 0.55)
		"unaffordable":
			return Color(0.74, 0.44, 0.30)
		"excluded":
			return Color(0.82, 0.16, 0.22)
		_:
			return Color(0.42, 0.40, 0.50)
