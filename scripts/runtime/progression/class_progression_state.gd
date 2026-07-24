class_name ClassProgressionState
extends RefCounted

signal award_applied(source_id: String, amount: int, available_points: int)
signal node_purchased(node_id: StringName, rank: int, cost: int, available_points: int)

const SCHEMA_VERSION := 1

var definition: ClassTreeDefinition
var award_ledger: Dictionary = {}
var allocations: Dictionary = {}
var stat_block: StatBlock


func configure(p_definition: ClassTreeDefinition) -> bool:
	if p_definition == null or not p_definition.is_valid():
		return false
	definition = p_definition.duplicate_definition()
	return true


func attach_stat_block(p_stat_block: StatBlock) -> bool:
	if definition == null or p_stat_block == null:
		return false
	stat_block = p_stat_block
	rebuild_effects()
	return true


func restore(snapshot: Dictionary, current_level: int = -1) -> bool:
	if definition == null:
		return false
	if snapshot.is_empty():
		award_ledger = {}
		allocations = {}
		if stat_block != null:
			rebuild_effects()
		return true
	if _positive_integer_value(snapshot.get("schema_version", null)) != SCHEMA_VERSION:
		return false
	if StringName(str(snapshot.get("definition_schema_id", ""))) != definition.schema_id:
		return false
	if _positive_integer_value(snapshot.get("definition_schema_version", null)) != definition.schema_version:
		return false

	var raw_awards: Variant = snapshot.get("award_ledger", {})
	var raw_allocations: Variant = snapshot.get("allocations", {})
	if not raw_awards is Dictionary or not raw_allocations is Dictionary:
		return false

	var candidate_awards: Dictionary = {}
	for raw_source: Variant in raw_awards:
		var stored_source_id := str(raw_source)
		var source_id := stored_source_id.strip_edges()
		var amount := _positive_integer_value(raw_awards[raw_source])
		if source_id.is_empty() or source_id != stored_source_id or candidate_awards.has(source_id):
			return false
		if amount <= 0 or not _award_source_is_valid(source_id, amount, current_level):
			return false
		candidate_awards[source_id] = amount

	var candidate_allocations: Dictionary = {}
	for raw_node_id: Variant in raw_allocations:
		var stored_node_id := str(raw_node_id)
		var node_id := StringName(stored_node_id)
		var rank := _positive_integer_value(raw_allocations[raw_node_id])
		var node := definition.get_node(node_id)
		if stored_node_id.is_empty() or stored_node_id != stored_node_id.strip_edges():
			return false
		if candidate_allocations.has(stored_node_id) or node == null or rank <= 0 or rank > node.maximum_rank:
			return false
		candidate_allocations[stored_node_id] = rank

	if not _allocations_are_valid(candidate_allocations):
		return false
	if _total_allocation_cost(candidate_allocations) > _total_awarded(candidate_awards):
		return false

	award_ledger = candidate_awards
	allocations = candidate_allocations
	if stat_block != null:
		rebuild_effects()
	return true


func reconcile_level_awards(current_level: int) -> int:
	if definition == null:
		return 0
	var total_added := 0
	for reached_level in range(definition.first_level_award, maxi(definition.first_level_award, current_level + 1)):
		var amount := definition.point_award_for_level(reached_level)
		if amount <= 0:
			continue
		var source_id := "level:%d" % reached_level
		if award(source_id, amount):
			total_added += amount
	return total_added


func award(source_id: String, amount: int) -> bool:
	var normalized := source_id.strip_edges()
	if normalized.is_empty() or amount <= 0 or award_ledger.has(normalized):
		return false
	award_ledger[normalized] = amount
	award_applied.emit(normalized, amount, available_points())
	return true


func purchase_rank(node_id: StringName) -> Dictionary:
	if definition == null:
		return _failure(&"unconfigured")
	var node := definition.get_node(node_id)
	if node == null:
		return _failure(&"unknown_node")
	var current_rank := int(allocations.get(String(node_id), 0))
	if current_rank >= node.maximum_rank:
		return _failure(&"maximum_rank")
	if not _prerequisites_met(node, allocations):
		return _failure(&"missing_prerequisite")
	if _exclusion_conflicts(node, allocations):
		return _failure(&"mutually_exclusive")
	var next_rank := current_rank + 1
	var cost := node.cost_for_rank(next_rank)
	if cost <= 0 or available_points() < cost:
		return _failure(&"insufficient_points")

	var candidate := allocations.duplicate(true)
	candidate[String(node_id)] = next_rank
	if not _allocations_are_valid(candidate):
		return _failure(&"invalid_allocation")
	allocations = candidate
	if stat_block != null:
		rebuild_effects()
	node_purchased.emit(node_id, next_rank, cost, available_points())
	return {
		"success": true,
		"reason": &"",
		"node_id": node_id,
		"rank": next_rank,
		"cost": cost,
		"available_points": available_points(),
	}


func available_points() -> int:
	return _total_awarded(award_ledger) - _total_allocation_cost(allocations)


func allocated_rank(node_id: StringName) -> int:
	return int(allocations.get(String(node_id), 0))


func serialize() -> Dictionary:
	var serialized_awards: Dictionary = {}
	var award_ids := award_ledger.keys()
	award_ids.sort()
	for source_id: Variant in award_ids:
		serialized_awards[str(source_id)] = int(award_ledger[source_id])
	var serialized_allocations: Dictionary = {}
	var node_ids := allocations.keys()
	node_ids.sort()
	for node_id: Variant in node_ids:
		var rank := int(allocations[node_id])
		if rank > 0:
			serialized_allocations[str(node_id)] = rank
	return {
		"schema_version": SCHEMA_VERSION,
		"definition_schema_id": String(definition.schema_id),
		"definition_schema_version": definition.schema_version,
		"award_ledger": serialized_awards,
		"allocations": serialized_allocations,
	}


func preview_refund(node_id: StringName, ranks: int = 1) -> Dictionary:
	var current_rank := allocated_rank(node_id)
	if ranks <= 0 or current_rank <= 0 or ranks > current_rank:
		return _failure(&"invalid_refund")
	var candidate := allocations.duplicate(true)
	var resulting_rank := current_rank - ranks
	if resulting_rank == 0:
		candidate.erase(String(node_id))
	else:
		candidate[String(node_id)] = resulting_rank
	if not _allocations_are_valid(candidate):
		return _failure(&"dependent_allocation")
	return {
		"success": true,
		"reason": &"",
		"node_id": node_id,
		"resulting_rank": resulting_rank,
		"refunded_points": _total_allocation_cost(allocations) - _total_allocation_cost(candidate),
	}


func rebuild_effects() -> void:
	if definition == null or stat_block == null:
		return
	_clear_definition_sources()
	for node_id: StringName in definition.all_node_ids():
		var purchased_rank := allocated_rank(node_id)
		if purchased_rank <= 0:
			continue
		var node := definition.get_node(node_id)
		for rank in range(1, purchased_rank + 1):
			for effect_index in range(node.effects.size()):
				var effect: Dictionary = node.effects[effect_index]
				if str(effect.get("effect_type", "")) != "stat_modifier":
					continue
				stat_block.add_modifier(StatModifier.new(
					_effect_source(node_id, rank, effect_index),
					StringName(str(effect.get("stat_id", ""))),
					int(effect.get("operation", StatModifier.Operation.FLAT)),
					float(effect.get("value", 0.0)),
					int(effect.get("priority", 20))
				))


func _allocations_are_valid(candidate: Dictionary) -> bool:
	var exclusion_owners: Dictionary = {}
	for raw_node_id: Variant in candidate:
		var node_id := StringName(str(raw_node_id))
		var node := definition.get_node(node_id)
		var rank := int(candidate[raw_node_id])
		if node == null or rank <= 0 or rank > node.maximum_rank:
			return false
		if not _prerequisites_met(node, candidate):
			return false
		if node.exclusion_group != &"":
			if exclusion_owners.has(node.exclusion_group):
				return false
			exclusion_owners[node.exclusion_group] = node_id
	return true


func _prerequisites_met(node: ClassTreeNodeDefinition, candidate: Dictionary) -> bool:
	for raw_prerequisite: Variant in node.prerequisites:
		var prerequisite_id := str(raw_prerequisite)
		if int(candidate.get(prerequisite_id, 0)) < int(node.prerequisites[raw_prerequisite]):
			return false
	return true


func _exclusion_conflicts(node: ClassTreeNodeDefinition, candidate: Dictionary) -> bool:
	if node.exclusion_group == &"":
		return false
	for raw_node_id: Variant in candidate:
		if int(candidate[raw_node_id]) <= 0:
			continue
		var allocated_node := definition.get_node(StringName(str(raw_node_id)))
		if allocated_node != null and allocated_node.node_id != node.node_id and allocated_node.exclusion_group == node.exclusion_group:
			return true
	return false


func _award_source_is_valid(source_id: String, amount: int, current_level: int) -> bool:
	if not source_id.begins_with("level:"):
		return true
	var level_text := source_id.trim_prefix("level:")
	if level_text.is_empty() or not level_text.is_valid_int():
		return false
	var reached_level := int(level_text)
	if source_id != "level:%d" % reached_level:
		return false
	if reached_level < definition.first_level_award:
		return false
	if current_level >= 0 and reached_level > current_level:
		return false
	return amount == definition.point_award_for_level(reached_level) and amount > 0


func _positive_integer_value(value: Variant) -> int:
	if not (value is int or value is float):
		return -1
	var parsed := int(value)
	if parsed <= 0 or float(value) != float(parsed):
		return -1
	return parsed


func _total_awarded(ledger: Dictionary) -> int:
	var total := 0
	for raw_source: Variant in ledger:
		total += int(ledger[raw_source])
	return total


func _total_allocation_cost(candidate: Dictionary) -> int:
	var total := 0
	for raw_node_id: Variant in candidate:
		var node := definition.get_node(StringName(str(raw_node_id)))
		if node == null:
			return 2147483647
		var cost := node.total_cost_for_rank(int(candidate[raw_node_id]))
		if cost < 0:
			return 2147483647
		total += cost
	return total


func _clear_definition_sources() -> void:
	for node_id: StringName in definition.all_node_ids():
		var node := definition.get_node(node_id)
		for rank in range(1, node.maximum_rank + 1):
			for effect_index in range(node.effects.size()):
				stat_block.remove_source(_effect_source(node_id, rank, effect_index))


func _effect_source(node_id: StringName, rank: int, effect_index: int) -> String:
	return "class_tree:%s:%d:%d" % [String(node_id), rank, effect_index]


func _failure(reason: StringName) -> Dictionary:
	return {"success": false, "reason": reason}
