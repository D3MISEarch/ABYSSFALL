extends "res://scripts/main.gd"

const CHARACTER_FACTORY = preload("res://scripts/core/character_factory.gd")
const FERVOR_SEAL_SCRIPT = preload("res://scripts/ui/fervor_seal.gd")

var requested_class_id := ""
var selected_class_id := CHARACTER_FACTORY.DEFAULT_CLASS_ID
var penitent_hud_installed := false


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
	player.level_up_requested.connect(_on_level_up_requested)
	player.inventory_changed.connect(_refresh_inventory)
	player.skill_tree_changed.connect(_refresh_skill_tree)
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
	_update_class_specific_copy()
	if player.has_method("get_sigil_capacity_snapshot"):
		var sigil_snapshot: Dictionary = player.get_sigil_capacity_snapshot()
		set_penitent_sigil_capacity(
			int(sigil_snapshot.get("active", 0)),
			int(sigil_snapshot.get("maximum", 3))
		)


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


func _refresh_skill_tree() -> void:
	if not is_instance_valid(player) or skill_columns == null:
		return
	_clear_container(skill_columns)
	var snapshot: Dictionary = player.get_skill_tree_snapshot()
	var progress: Dictionary = snapshot.get("progress", {})
	var branches: Dictionary = snapshot.get("branches", {})
	var branch_order: Array = snapshot.get("branch_order", branches.keys())

	for branch_index in range(branch_order.size()):
		var branch_name := str(branch_order[branch_index])
		var branch_box := VBoxContainer.new()
		branch_box.custom_minimum_size = Vector2(285.0, 450.0)
		skill_columns.add_child(branch_box)

		var branch_title := Label.new()
		branch_title.text = branch_name.to_upper()
		branch_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		branch_title.add_theme_font_size_override("font_size", 26)
		branch_title.modulate = _branch_color(branch_index, branch_name)
		branch_box.add_child(branch_title)

		var current_tier := int(progress.get(branch_name, 0))
		var skills: Array = branches.get(branch_name, [])
		for skill_index in range(skills.size()):
			var skill: Dictionary = skills[skill_index]
			var node_label := Label.new()
			node_label.custom_minimum_size = Vector2(275.0, 62.0)
			node_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var prefix := (
				"✓"
				if skill_index < current_tier
				else ("▶" if skill_index == current_tier else "◇")
			)
			node_label.text = (
				"%s  T%d  %s\n%s"
				% [
					prefix,
					skill_index + 1,
					str(skill.get("name", "Unknown")),
					str(skill.get("description", "")),
				]
			)
			if skill_index < current_tier:
				node_label.modulate = _branch_color(branch_index, branch_name).lightened(0.18)
			elif skill_index == current_tier:
				node_label.modulate = Color(1.0, 0.93, 0.68)
			else:
				node_label.modulate = Color(0.36, 0.34, 0.42)
			branch_box.add_child(node_label)


func _branch_color(branch_index: int, branch_name: String) -> Color:
	if branch_name == "Corruption":
		return Color(0.48, 0.88, 0.08)
	var palette := [
		Color(0.70, 0.12, 0.18),
		Color(0.92, 0.30, 0.12),
		Color(0.36, 0.86, 0.08),
	]
	return palette[branch_index % palette.size()]


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

	if is_instance_valid(menu_hint_label):
		if selected_class_id == "void_warlock":
			menu_hint_label.text = "I / Y: INVENTORY   T / X: SKILL TREE   E / B: INTERACT   LMB / RB: VOID BOLT   RMB / Q / LB: RIFT   SPACE / A: SHADOW STEP"
		else:
			menu_hint_label.text = "PENITENT   LMB / RB: RITUAL BLADE   F / R3: BRAND (12)   RMB / Q / LB: SEAL (18)   SPACE / A: ASHEN PROCESSION   RESOURCE: %s" % resource_name.to_upper()


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
