extends "res://scripts/main.gd"

const CHARACTER_FACTORY = preload("res://scripts/core/character_factory.gd")
const FERVOR_SEAL_SCRIPT = preload("res://scripts/ui/fervor_seal.gd")
const INPUT_PROMPT_PROFILE = preload("res://scripts/ui/input_prompt_profile.gd")
const PLAYABLE_PROGRESSION_BRIDGE_SCRIPT = preload("res://scripts/ui/playable_progression_bridge.gd")
const CLASS_TREE_SCREEN_SCRIPT = preload("res://scripts/ui/class_tree_screen.gd")
const GAMEPLAY_PAUSE_BOUNDARY = preload("res://scripts/ui/gameplay_pause_boundary.gd")

var requested_class_id := ""
var selected_class_id := CHARACTER_FACTORY.DEFAULT_CLASS_ID
var penitent_hud_installed := false
var active_prompt_profile := INPUT_PROMPT_PROFILE.KEYBOARD_MOUSE
var progression_bridge: PlayableProgressionBridge
var class_tree_screen: ClassTreeScreen
var class_point_label: Label
var progression_notification_label: Label
var progression_notification_token := 0


func _spawn_player() -> void:
	selected_class_id = _resolve_selected_class_id()
	player = CHARACTER_FACTORY.create_character(selected_class_id)
	if not is_instance_valid(player):
		push_error("Unable to create playable class '%s'." % selected_class_id)
		return

	player.name = str(player.get_class_display_name()).replace(" ", "")
	add_child(player)
	player.global_position = Vector3(0.0, 0.9, 14.0)

	player.health_changed.connect(_on_player_health_changed)
	player.resource_changed.connect(_on_player_resource_changed)
	player.experience_changed.connect(_on_player_experience_changed)
	player.inventory_changed.connect(_refresh_inventory)
	player.ability_message.connect(_on_ability_message)
	player.loot_message.connect(_on_loot_message)
	player.died.connect(_on_player_died)
	if player.has_signal("sigil_capacity_changed"):
		player.connect("sigil_capacity_changed", Callable(self, "set_penitent_sigil_capacity"))

	var health_snapshot: Dictionary = player.get_health_snapshot()
	_on_player_health_changed(
		int(health_snapshot.get("current", 1)),
		int(health_snapshot.get("maximum", 1))
	)

	var resource_snapshot: Dictionary = player.get_resource_snapshot()
	_on_player_resource_changed(
		str(resource_snapshot.get("id", "resource")),
		str(resource_snapshot.get("display_name", "Resource")),
		float(resource_snapshot.get("current", 0.0)),
		float(resource_snapshot.get("maximum", 1.0))
	)

	var progression_snapshot: Dictionary = player.get_progression_snapshot()
	_on_player_experience_changed(
		int(progression_snapshot.get("level", 1)),
		int(progression_snapshot.get("experience", 0)),
		int(progression_snapshot.get("required_experience", 1))
	)

	_refresh_inventory()
	_refresh_skill_tree()
	active_prompt_profile = INPUT_PROMPT_PROFILE.connected_profile()
	_update_class_specific_copy()
	if player.has_method("get_sigil_capacity_snapshot"):
		var sigil_snapshot: Dictionary = player.get_sigil_capacity_snapshot()
		set_penitent_sigil_capacity(
			int(sigil_snapshot.get("active", 0)),
			int(sigil_snapshot.get("maximum", 3))
		)

	_disable_legacy_level_panel()
	_install_progression_hud()
	_initialize_progression_runtime()


func _input(event: InputEvent) -> void:
	var requested_profile := INPUT_PROMPT_PROFILE.profile_for_event(event)
	if requested_profile.is_empty() or requested_profile == active_prompt_profile:
		return
	active_prompt_profile = requested_profile
	_refresh_control_hint()


func _resolve_selected_class_id() -> String:
	if CHARACTER_FACTORY.has_class(requested_class_id):
		return requested_class_id

	var resolved_id := CHARACTER_FACTORY.DEFAULT_CLASS_ID
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--class="):
			continue
		var requested_id := argument.trim_prefix("--class=")
		if CHARACTER_FACTORY.has_class(requested_id):
			resolved_id = requested_id
		else:
			push_warning("Unknown class id '%s'; using Void Warlock." % requested_id)
	return resolved_id


func _on_player_resource_changed(
	_resource_id: String,
	display_name: String,
	current_value: float,
	maximum_value: float
) -> void:
	if is_instance_valid(corruption_meter):
		if corruption_meter.has_method("set_resource"):
			corruption_meter.set_resource(current_value, maximum_value)
		else:
			corruption_meter.set_corruption(current_value, maximum_value)
	if is_instance_valid(corruption_label):
		corruption_label.text = (
			"%s  %d / %d"
			% [display_name.to_upper(), int(current_value), int(maximum_value)]
		)


func _on_player_corruption_changed(current_value: float, maximum_value: float) -> void:
	_on_player_resource_changed("corruption", "Corruption", current_value, maximum_value)


func preview_penitent_sacrament(cost: float = 40.0) -> Dictionary:
	if (
		selected_class_id != "penitent_placeholder"
		or not is_instance_valid(player)
		or not player.has_method("quote_sacrament_cost")
	):
		return {"can_cast": false}
	var quote: Dictionary = player.quote_sacrament_cost(cost)
	if is_instance_valid(corruption_meter) and corruption_meter.has_method("set_cost_preview"):
		corruption_meter.set_cost_preview(
			float(quote.get("fervor_spent", 0.0)),
			int(quote.get("health_percent", 0))
		)
	return quote


func clear_penitent_cost_preview() -> void:
	if is_instance_valid(corruption_meter) and corruption_meter.has_method("clear_cost_preview"):
		corruption_meter.clear_cost_preview()


func set_penitent_sigil_capacity(active_count: int, maximum_count: int = 3) -> void:
	if is_instance_valid(corruption_meter) and corruption_meter.has_method("set_sigil_capacity"):
		corruption_meter.set_sigil_capacity(active_count, maximum_count)


func _on_player_died() -> void:
	game_finished = true
	game_state = "defeat"
	objective_label.text = "THE CRYPTS CLAIMED YOU"
	var fallen_name := "THE WANDERER"
	if is_instance_valid(player) and player.has_method("get_class_display_name"):
		fallen_name = str(player.get_class_display_name()).to_upper()
	_show_message("%s HAS FALLEN\nPress R to restart" % fallen_name, 999.0)


func _on_player_experience_changed(current_level: int, current_xp: int, required_xp: int) -> void:
	super._on_player_experience_changed(current_level, current_xp, required_xp)
	if progression_bridge != null and progression_bridge.is_configured():
		progression_bridge.sync_playable_progress(current_level, current_xp)


func _disable_legacy_level_panel() -> void:
	# The inherited panel remains prototype scaffolding in main.gd. The actual
	# multiclass play path removes it before the first gameplay frame so level
	# gains can never seize focus or pause combat.
	if is_instance_valid(level_up_panel):
		level_up_panel.queue_free()
	level_up_panel = null
	level_choice_buttons.clear()
	current_level_choices.clear()


func _install_progression_hud() -> void:
	if not is_instance_valid(xp_label) or class_point_label != null:
		return
	var canvas := xp_label.get_parent()
	if canvas == null:
		return
	class_point_label = Label.new()
	class_point_label.position = Vector2(335.0, 55.0)
	class_point_label.size = Vector2(260.0, 24.0)
	class_point_label.add_theme_font_size_override("font_size", 14)
	class_point_label.modulate = Color(0.82, 0.62, 1.0)
	class_point_label.text = "CLASS POINTS  0"
	canvas.add_child(class_point_label)

	progression_notification_label = Label.new()
	progression_notification_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	progression_notification_label.position = Vector2(-310.0, 112.0)
	progression_notification_label.size = Vector2(620.0, 38.0)
	progression_notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progression_notification_label.add_theme_font_size_override("font_size", 18)
	progression_notification_label.modulate = Color(0.92, 0.76, 1.0)
	progression_notification_label.visible = false
	canvas.add_child(progression_notification_label)

	if is_instance_valid(skill_panel):
		for child in skill_panel.get_children():
			if child is Label and str(child.text).begins_with("THE THREE FORBIDDEN PATHS"):
				child.text = "CLASS PROGRESSION     —     T / ESC TO CLOSE"
		if is_instance_valid(skill_columns):
			var legacy_scroll := skill_columns.get_parent() as Control
			if legacy_scroll != null:
				legacy_scroll.visible = false
		class_tree_screen = CLASS_TREE_SCREEN_SCRIPT.new() as ClassTreeScreen
		if class_tree_screen == null:
			push_error("Could not create the graphical class-tree screen.")
			return
		class_tree_screen.position = Vector2(35.0, 62.0)
		class_tree_screen.size = Vector2(930.0, 478.0)
		class_tree_screen.purchase_requested.connect(_on_class_tree_node_pressed)
		skill_panel.add_child(class_tree_screen)


func _initialize_progression_runtime() -> void:
	if not is_instance_valid(player) or progression_bridge != null:
		return
	progression_bridge = PLAYABLE_PROGRESSION_BRIDGE_SCRIPT.new()
	progression_bridge.name = "PlayableProgressionBridge"
	progression_bridge.configured.connect(_on_progression_configured)
	progression_bridge.points_awarded.connect(_on_progression_points_awarded)
	progression_bridge.state_changed.connect(_on_progression_state_changed)
	progression_bridge.persistence_failed.connect(_on_progression_persistence_failed)
	add_child(progression_bridge)
	var build_name := "%s Build" % str(player.get_class_display_name())
	if not progression_bridge.configure_persistent(selected_class_id, Persistence, build_name):
		push_error("Could not initialize persistent class progression for %s." % selected_class_id)
		return
	progression_bridge.restore_into_playable(player)
	_refresh_skill_tree()


func _on_progression_configured(point_name: String, available_points: int, _level: int) -> void:
	_update_class_point_label(point_name, available_points)


func _on_progression_points_awarded(level_value: int, amount: int, available_points: int) -> void:
	var point_name := progression_bridge.point_display_name()
	_update_class_point_label(point_name, available_points)
	_show_progression_notification(
		"LEVEL %d     %s +%d     %d AVAILABLE"
		% [level_value, point_name.to_upper(), amount, available_points],
		2.4
	)


func _on_progression_state_changed(available_points: int) -> void:
	if progression_bridge == null:
		return
	_update_class_point_label(progression_bridge.point_display_name(), available_points)
	if is_instance_valid(skill_panel) and skill_panel.visible:
		_refresh_skill_tree()


func _on_progression_persistence_failed(context: String, error: Error) -> void:
	push_error("Class progression persistence failed in %s (error %d)." % [context, error])
	_show_progression_notification("PROGRESSION SAVE FAILED", 2.4)


func _update_class_point_label(point_name: String, available_points: int) -> void:
	if is_instance_valid(class_point_label):
		class_point_label.text = "%s  %d" % [point_name.to_upper(), available_points]


func _show_progression_notification(text: String, duration: float) -> void:
	if not is_instance_valid(progression_notification_label):
		return
	progression_notification_token += 1
	var token := progression_notification_token
	progression_notification_label.text = text
	progression_notification_label.visible = true
	await get_tree().create_timer(duration, true).timeout
	if token == progression_notification_token and is_instance_valid(progression_notification_label):
		progression_notification_label.text = ""
		progression_notification_label.visible = false


func _toggle_inventory() -> void:
	if not is_instance_valid(inventory_panel) or not is_instance_valid(skill_panel):
		return
	skill_panel.visible = false
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible:
		_refresh_inventory()
	_update_pause_state()


func _toggle_skill_tree() -> void:
	if not is_instance_valid(inventory_panel) or not is_instance_valid(skill_panel):
		return
	inventory_panel.visible = false
	skill_panel.visible = not skill_panel.visible
	if skill_panel.visible:
		_refresh_skill_tree()
		if class_tree_screen != null:
			class_tree_screen.call_deferred("focus_initial")
	_update_pause_state()


func _close_side_menus() -> void:
	if is_instance_valid(inventory_panel):
		inventory_panel.visible = false
	if is_instance_valid(skill_panel):
		skill_panel.visible = false
	_update_pause_state()


func _update_pause_state() -> void:
	var should_pause := false
	if is_instance_valid(inventory_panel) and inventory_panel.visible:
		should_pause = true
	if is_instance_valid(skill_panel) and skill_panel.visible:
		should_pause = true
	_prepare_gameplay_pause_boundary()
	get_tree().paused = should_pause


func _prepare_gameplay_pause_boundary() -> void:
	# main.gd remains ALWAYS so it can close menus while paused. The dedicated
	# boundary keeps Canvas UI and persistence/progression plumbing responsive,
	# while every direct gameplay subtree becomes genuinely pausable.
	var always_nodes: Array[Node] = []
	if progression_bridge != null:
		always_nodes.append(progression_bridge)
	GAMEPLAY_PAUSE_BOUNDARY.apply(self, always_nodes)


func _refresh_skill_tree() -> void:
	if class_tree_screen == null:
		return
	if progression_bridge == null or not progression_bridge.is_configured():
		class_tree_screen.show_unavailable("CLASS PROGRESSION IS NOT YET BOUND")
		return
	class_tree_screen.set_tree_snapshot(progression_bridge.tree_snapshot())


func _on_class_tree_node_pressed(node_id: StringName) -> void:
	if progression_bridge == null or node_id == &"":
		return
	var result := progression_bridge.purchase_node(node_id)
	if bool(result.get("success", false)):
		_show_progression_notification(
			"NODE AWAKENED     RANK %d     %d POINTS REMAIN"
			% [int(result.get("rank", 1)), int(result.get("available_points", 0))],
			1.6
		)
	else:
		_show_progression_notification(
			"NODE PURCHASE BLOCKED     %s"
			% str(result.get("reason", &"invalid")).replace("_", " ").to_upper(),
			1.4
		)
	_refresh_skill_tree()


func _update_class_specific_copy() -> void:
	if not is_instance_valid(player):
		return
	var definition: Dictionary = player.get_class_definition()
	var display_name := str(definition.get("display_name", "Unknown"))
	var resource_name := str(definition.get("resource_name", "Resource"))

	for node in find_children("*", "Label", true, false):
		var label := node as Label
		if label == null:
			continue
		if label.text.begins_with("VOID WARLOCK INVENTORY"):
			label.text = "%s INVENTORY     —     I / ESC TO CLOSE" % display_name.to_upper()

	if selected_class_id == "penitent_placeholder":
		_install_penitent_resource_hud()

	_refresh_control_hint(resource_name)


func _refresh_control_hint(resource_name: String = "") -> void:
	if not is_instance_valid(menu_hint_label):
		return
	var resolved_resource := resource_name
	if resolved_resource.is_empty() and is_instance_valid(player):
		var definition: Dictionary = player.get_class_definition()
		resolved_resource = str(definition.get("resource_name", "Resource"))
	menu_hint_label.text = INPUT_PROMPT_PROFILE.build_hint(
		selected_class_id,
		active_prompt_profile,
		resolved_resource
	)


func _install_penitent_resource_hud() -> void:
	if penitent_hud_installed or not is_instance_valid(corruption_meter):
		return
	var canvas: Node = corruption_meter.get_parent()
	if canvas == null:
		return

	corruption_meter.queue_free()
	corruption_meter = FERVOR_SEAL_SCRIPT.new()
	corruption_meter.name = "FervorSeal"
	corruption_meter.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	corruption_meter.position = Vector2(-224.0, -238.0)
	corruption_meter.size = Vector2(196.0, 196.0)
	canvas.add_child(corruption_meter)
	corruption_meter.set_sigil_capacity(0, 3)

	if is_instance_valid(corruption_label):
		corruption_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		corruption_label.position = Vector2(-245.0, -258.0)
		corruption_label.size = Vector2(238.0, 26.0)
		corruption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		corruption_label.modulate = Color(0.82, 0.18, 0.19)

	var resource_snapshot: Dictionary = player.get_resource_snapshot()
	corruption_meter.set_resource(
		float(resource_snapshot.get("current", 0.0)),
		float(resource_snapshot.get("maximum", 100.0))
	)
	if player.has_method("get_sigil_capacity_snapshot"):
		var sigil_snapshot: Dictionary = player.get_sigil_capacity_snapshot()
		corruption_meter.set_sigil_capacity(
			int(sigil_snapshot.get("active", 0)),
			int(sigil_snapshot.get("maximum", 3))
		)
	penitent_hud_installed = true
