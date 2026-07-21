class_name LootGenerator
extends RefCounted


static func roll(
	entries: Array,
	seed: int,
	item_catalog: ItemCatalog = null,
	affix_catalog: AffixCatalog = null,
	default_item_level: int = 1
) -> Array[ItemInstance]:
	if seed == 0:
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var drops: Array[ItemInstance] = []
	var entry_index := 0
	for raw_entry: Variant in entries:
		if not raw_entry is Dictionary:
			entry_index += 1
			continue
		var definition_id := StringName(str(raw_entry.get("definition_id", "")))
		if definition_id == &"":
			entry_index += 1
			continue
		var chance := clampf(float(raw_entry.get("chance", 1.0)), 0.0, 1.0)
		if rng.randf() > chance:
			entry_index += 1
			continue

		var generated := bool(raw_entry.get("generated", false))
		if generated:
			var generated_item := _generate_entry(
				raw_entry,
				definition_id,
				entry_index,
				seed,
				rng,
				item_catalog,
				affix_catalog,
				default_item_level
			)
			if generated_item != null:
				drops.append(generated_item)
			entry_index += 1
			continue

		var minimum := maxi(1, int(raw_entry.get("minimum", 1)))
		var maximum := maxi(minimum, int(raw_entry.get("maximum", minimum)))
		var quantity := rng.randi_range(minimum, maximum)
		var item := ItemInstance.new(definition_id, quantity)
		item.item_level = maxi(1, int(raw_entry.get("item_level", default_item_level)))
		item.instance_id = "loot:%s:%s:%s:%s" % [seed, entry_index, String(definition_id), drops.size()]
		drops.append(item)
		entry_index += 1
	return drops


static func _generate_entry(
	entry: Dictionary,
	definition_id: StringName,
	entry_index: int,
	loot_seed: int,
	rng: RandomNumberGenerator,
	item_catalog: ItemCatalog,
	affix_catalog: AffixCatalog,
	default_item_level: int
) -> ItemInstance:
	if item_catalog == null:
		return null
	var definition := item_catalog.get_definition(definition_id)
	if definition == null or definition.max_stack != 1:
		return null
	var rarity_value := int(entry.get("rarity", LootRarity.Tier.MAGIC))
	if not LootRarity.is_valid(rarity_value):
		return null
	var item_level := maxi(1, int(entry.get("item_level", default_item_level)))
	var generation_seed := int(rng.randi())
	if generation_seed == 0:
		generation_seed = loot_seed + entry_index + 1
	return ItemGenerator.generate(definition, item_level, rarity_value, generation_seed, affix_catalog)
