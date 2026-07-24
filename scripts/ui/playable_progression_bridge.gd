class_name PlayableProgressionBridge
extends Node

signal configured(point_display_name: String, available_points: int, level: int)
signal points_awarded(level: int, amount: int, available_points: int)
signal state_changed(available_points: int)
signal persistence_failed(context: String, error: Error)

const PROOF_DISPLAY_ORDER: Array[StringName] = [
	&"proof_origin",
	&"proof_force",
	&"proof_guard",
	&"proof_notable",
	&"proof_bridge",
	&"proof_law",
	&"proof_law_guard",
	&"proof_culmination",
]

var persistence_service: PersistenceService
var session: RuntimeSession
var runtime_character: RuntimeCharacter
var active_build: BuildData
var _persistent := false
var _configured := false


func configure_persistent(
	class_id: String,
	service: PersistenceService,
	build_name: String = "AbyssFall Build"
) -> bool:
	if not ClassIds.is_valid(class_id) or service == null:
		return false
	persistence_service = service
	if persistence_service.profile == null and not persistence_service.initialize():
		return false
	var build := _resolve_persistent_build(class_id, build_name)
	if build == null:
		return false
	return _bind_build(build, true)


func configure_ephemeral(build: BuildData) -> bool:
	if build == null:
		return false
	persistence_service = null
	return _bind_build(build, false)


func restore_into_playable(playable: Object) -> bool:
	if not _configured or playable == null or not playable.has_method("restore_persistent_progression"):
		return false
	playable.call(
		"restore_persistent_progression",
		runtime_character.level,
		runtime_character.experience
	)
	return true


func sync_playable_progress(current_level: int, current_experience: int) -> bool:
	if not _configured or current_level < runtime_character.level:
		return false
	runtime_character.level = maxi(1, current_level)
	runtime_character.experience = maxi(0, current_experience)
	var added_points := session.class_progression.reconcile_level_awards(runtime_character.level)
	var persisted := _persist(added_points > 0)
	var available := available_points()
	if added_points > 0:
		points_awarded.emit(runtime_character.level, added_points, available)
	state_changed.emit(available)
	return persisted


func purchase_node(node_id: StringName) -> Dictionary:
	if not _configured:
		return {"success": false, "reason": &"unconfigured"}
	var result := session.purchase_class_tree_node(node_id)
	if bool(result.get("success", false)):
		_persist(true)
		state_changed.emit(available_points())
	return result


func available_points() -> int:
	if not _configured:
		return 0
	return session.class_progression.available_points()


func point_display_name() -> String:
	if not _configured or session.class_progression.definition == null:
		return "Class Points"
	return session.class_progression.definition.point_display_name


func is_configured() -> bool:
	return _configured


func current_level() -> int:
	return runtime_character.level if _configured else 1


func current_experience() -> int:
	return runtime_character.experience if _configured else 0


func tree_snapshot() -> Dictionary:
	if not _configured:
		return {}
	var definition := session.class_progression.definition
	var nodes: Array[Dictionary] = []
	for node_id: StringName in _ordered_node_ids(definition):
		var node := definition.get_node(node_id)
		if node == null:
			continue
		var rank := session.class_progression.allocated_rank(node_id)
		var at_maximum := rank >= node.maximum_rank
		var prerequisites_met := _prerequisites_met(node)
		var excluded := _has_exclusion_conflict(node, definition)
		var next_cost := -1 if at_maximum else node.cost_for_rank(rank + 1)
		var affordable := next_cost > 0 and available_points() >= next_cost
		var can_purchase := not at_maximum and prerequisites_met and not excluded and affordable
		var visual_state := "available"
		if at_maximum:
			visual_state = "max_rank"
		elif excluded:
			visual_state = "excluded"
		elif not prerequisites_met:
			visual_state = "locked"
		elif rank > 0:
			visual_state = "purchased"
		elif not affordable:
			visual_state = "unaffordable"
		nodes.append({
			"node_id": String(node.node_id),
			"display_name": node.display_name,
			"node_type": _node_type_name(node.node_type),
			"rank": rank,
			"maximum_rank": node.maximum_rank,
			"next_cost": next_cost,
			"prerequisites": _prerequisite_text(node, definition),
			"effects": _effect_text(node),
			"visual_state": visual_state,
			"can_purchase": can_purchase,
		})
	return {
		"point_display_name": definition.point_display_name,
		"available_points": available_points(),
		"nodes": nodes,
	}


func flush(context: String = "class_progression_ui") -> Error:
	if not _persistent or persistence_service == null:
		return OK
	return persistence_service.flush_if_dirty(context)


func _exit_tree() -> void:
	flush("class_progression_ui_exit")


func _resolve_persistent_build(class_id: String, build_name: String) -> BuildData:
	if persistence_service.active_build != null and persistence_service.active_build.class_id == class_id:
		return persistence_service.active_build
	for build_id: String in persistence_service.profile.build_ids:
		var candidate := SaveManager.load_build(build_id)
		if candidate == null or candidate.class_id != class_id:
			continue
		if persistence_service.select_build(build_id):
			return persistence_service.active_build
	return persistence_service.create_and_select_build(class_id, build_name)


func _bind_build(build: BuildData, persistent: bool) -> bool:
	if _configured or build == null:
		return false
	var candidate_character := RuntimeCharacter.new()
	candidate_character.configure_from_build(build)
	var candidate_session := RuntimeSession.new()
	add_child(candidate_session)
	if not candidate_session.bind_character(candidate_character):
		remove_child(candidate_session)
		candidate_session.queue_free()
		return false
	active_build = build
	runtime_character = candidate_character
	session = candidate_session
	_persistent = persistent
	_configured = true
	configured.emit(point_display_name(), available_points(), runtime_character.level)
	return true


func _persist(flush_now: bool) -> bool:
	if not _persistent or persistence_service == null:
		return true
	var snapshot := {
		"build_id": runtime_character.build_id,
		"level": runtime_character.level,
		"experience": runtime_character.experience,
		"class_tree_state": session.class_progression.serialize(),
	}
	if not persistence_service.apply_active_build_snapshot(snapshot):
		persistence_failed.emit("apply_class_progression_snapshot", ERR_INVALID_DATA)
		return false
	if not flush_now:
		return true
	var error := persistence_service.flush_if_dirty("class_progression_ui")
	if error != OK:
		persistence_failed.emit("flush_class_progression_snapshot", error)
		return false
	return true


func _ordered_node_ids(definition: ClassTreeDefinition) -> Array[StringName]:
	var result: Array[StringName] = []
	for node_id: StringName in PROOF_DISPLAY_ORDER:
		if definition.has_node(node_id):
			result.append(node_id)
	for node_id: StringName in definition.all_node_ids():
		if not result.has(node_id):
			result.append(node_id)
	return result


func _prerequisites_met(node: ClassTreeNodeDefinition) -> bool:
	for raw_id: Variant in node.prerequisites:
		var required_rank := int(node.prerequisites[raw_id])
		if session.class_progression.allocated_rank(StringName(str(raw_id))) < required_rank:
			return false
	return true


func _has_exclusion_conflict(
	node: ClassTreeNodeDefinition,
	definition: ClassTreeDefinition
) -> bool:
	if node.exclusion_group == &"":
		return false
	for other_id: StringName in definition.all_node_ids():
		if other_id == node.node_id or session.class_progression.allocated_rank(other_id) <= 0:
			continue
		var other := definition.get_node(other_id)
		if other != null and other.exclusion_group == node.exclusion_group:
			return true
	return false


func _prerequisite_text(
	node: ClassTreeNodeDefinition,
	definition: ClassTreeDefinition
) -> String:
	if node.prerequisites.is_empty():
		return "Origin node"
	var parts: Array[String] = []
	for raw_id: Variant in node.prerequisites:
		var prerequisite := definition.get_node(StringName(str(raw_id)))
		var display_name := str(raw_id) if prerequisite == null else prerequisite.display_name
		parts.append("%s Rank %d" % [display_name, int(node.prerequisites[raw_id])])
	parts.sort()
	return ", ".join(PackedStringArray(parts))


func _effect_text(node: ClassTreeNodeDefinition) -> String:
	var parts: Array[String] = []
	for effect: Dictionary in node.effects:
		var stat_name := str(effect.get("stat_id", "stat")).replace("_", " ").capitalize()
		var operation := int(effect.get("operation", StatModifier.Operation.FLAT))
		var value := float(effect.get("value", 0.0))
		if operation == StatModifier.Operation.FLAT:
			var flat_sign := "+" if value >= 0.0 else ""
			parts.append("%s%.1f %s per rank" % [flat_sign, value, stat_name])
		else:
			var percent_value := value * 100.0
			var percent_sign := "+" if percent_value >= 0.0 else ""
			parts.append("%s%.0f%% %s per rank" % [percent_sign, percent_value, stat_name])
	return " • ".join(PackedStringArray(parts))


func _node_type_name(node_type: int) -> String:
	match node_type:
		ClassTreeNodeDefinition.NodeType.ROOT:
			return "Root"
		ClassTreeNodeDefinition.NodeType.MINOR:
			return "Minor"
		ClassTreeNodeDefinition.NodeType.NOTABLE:
			return "Notable"
		ClassTreeNodeDefinition.NodeType.ACTIVE_SKILL:
			return "Active Skill"
		ClassTreeNodeDefinition.NodeType.REFINEMENT:
			return "Refinement"
		ClassTreeNodeDefinition.NodeType.MUTATION:
			return "Mutation"
		ClassTreeNodeDefinition.NodeType.LAW:
			return "Law Node"
		ClassTreeNodeDefinition.NodeType.CULMINATION:
			return "Culmination Node"
		ClassTreeNodeDefinition.NodeType.TRIAL:
			return "Trial"
		ClassTreeNodeDefinition.NodeType.BRIDGE:
			return "Bridge"
		_:
			return "Node"
