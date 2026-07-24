class_name AffixRoller
extends RefCounted


static func roll(
	catalog: AffixCatalog,
	item_tags: Array[StringName],
	item_level: int,
	prefix_count: int,
	suffix_count: int,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if catalog == null or rng == null or item_level < 1:
		return result
	_append_rolls(result, catalog.eligible_definitions(item_tags, item_level, AffixDefinition.Kind.PREFIX), maxi(0, prefix_count), rng)
	_append_rolls(result, catalog.eligible_definitions(item_tags, item_level, AffixDefinition.Kind.SUFFIX), maxi(0, suffix_count), rng)
	return result


static func _append_rolls(
	result: Array[Dictionary],
	pool: Array[AffixDefinition],
	count: int,
	rng: RandomNumberGenerator
) -> void:
	for _roll_index: int in mini(count, pool.size()):
		var selected_index := _weighted_index(pool, rng)
		if selected_index < 0:
			return
		var selected: AffixDefinition = pool[selected_index]
		pool.remove_at(selected_index)
		for raw_modifier: Dictionary in selected.modifiers:
			var modifier := raw_modifier.duplicate(true)
			modifier["affix_id"] = String(selected.affix_id)
			modifier["affix_name"] = selected.display_name
			modifier["affix_kind"] = int(selected.kind)
			result.append(modifier)


static func _weighted_index(pool: Array[AffixDefinition], rng: RandomNumberGenerator) -> int:
	var total_weight := 0
	for definition: AffixDefinition in pool:
		total_weight += maxi(0, definition.weight)
	if total_weight <= 0:
		return -1
	var roll := rng.randi_range(1, total_weight)
	var cursor := 0
	for index: int in pool.size():
		cursor += maxi(0, pool[index].weight)
		if roll <= cursor:
			return index
	return -1
