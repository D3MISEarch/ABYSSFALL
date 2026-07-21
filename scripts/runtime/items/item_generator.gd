class_name ItemGenerator
extends RefCounted


static func generate(
	definition: ItemDefinition,
	item_level: int,
	rarity: LootRarity.Tier,
	seed: int,
	affix_catalog: AffixCatalog
) -> ItemInstance:
	if definition == null or definition.definition_id == &"" or item_level < 1 or seed == 0:
		return null
	if not LootRarity.is_valid(int(rarity)):
		return null
	if rarity != LootRarity.Tier.NORMAL and affix_catalog == null:
		return null

	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var item := ItemInstance.new(definition.definition_id, 1)
	item.instance_id = "generated:%s:%s:%s:%s" % [seed, String(definition.definition_id), item_level, int(rarity)]
	item.rarity = int(rarity)
	item.item_level = item_level

	var ruleset: Dictionary = LootRarity.rules(rarity)
	var minimum_affixes := int(ruleset.get("minimum_affixes", 0))
	var maximum_affixes := int(ruleset.get("maximum_affixes", 0))
	if maximum_affixes <= 0:
		return item

	var prefixes := affix_catalog.eligible_definitions(definition.tags, item_level, AffixDefinition.Kind.PREFIX)
	var suffixes := affix_catalog.eligible_definitions(definition.tags, item_level, AffixDefinition.Kind.SUFFIX)
	var maximum_prefixes := mini(int(ruleset.get("maximum_prefixes", 0)), prefixes.size())
	var maximum_suffixes := mini(int(ruleset.get("maximum_suffixes", 0)), suffixes.size())
	var available_total := maximum_prefixes + maximum_suffixes
	if available_total < minimum_affixes:
		return null

	var target_affixes := rng.randi_range(minimum_affixes, mini(maximum_affixes, available_total))
	var allocations: Array[Vector2i] = []
	for prefix_count: int in range(maximum_prefixes + 1):
		var suffix_count := target_affixes - prefix_count
		if suffix_count >= 0 and suffix_count <= maximum_suffixes:
			allocations.append(Vector2i(prefix_count, suffix_count))
	if allocations.is_empty():
		return null
	var allocation: Vector2i = allocations[rng.randi_range(0, allocations.size() - 1)]
	item.affixes = AffixRoller.roll(
		affix_catalog,
		definition.tags,
		item_level,
		allocation.x,
		allocation.y,
		rng
	)
	if _unique_affix_count(item.affixes) != target_affixes:
		return null
	return item


static func _unique_affix_count(modifiers: Array[Dictionary]) -> int:
	var ids: Dictionary = {}
	for modifier: Dictionary in modifiers:
		var affix_id := str(modifier.get("affix_id", ""))
		if not affix_id.is_empty():
			ids[affix_id] = true
	return ids.size()
