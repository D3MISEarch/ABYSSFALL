class_name LootGenerator
extends RefCounted


static func roll(entries: Array, seed: int) -> Array[ItemInstance]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var drops: Array[ItemInstance] = []
	for raw_entry: Variant in entries:
		if not raw_entry is Dictionary:
			continue
		var definition_id := StringName(str(raw_entry.get("definition_id", "")))
		if definition_id == &"":
			continue
		var chance := clampf(float(raw_entry.get("chance", 1.0)), 0.0, 1.0)
		if rng.randf() > chance:
			continue
		var minimum := maxi(1, int(raw_entry.get("minimum", 1)))
		var maximum := maxi(minimum, int(raw_entry.get("maximum", minimum)))
		var quantity := rng.randi_range(minimum, maximum)
		var item := ItemInstance.new(definition_id, quantity)
		item.instance_id = "%s:%s:%s" % [seed, String(definition_id), drops.size()]
		drops.append(item)
	return drops
