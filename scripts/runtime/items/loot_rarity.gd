class_name LootRarity
extends RefCounted

enum Tier {
	NORMAL,
	MAGIC,
	RARE,
	LEGENDARY,
}


static func rules(tier: Tier) -> Dictionary:
	match tier:
		Tier.NORMAL:
			return {"minimum_affixes": 0, "maximum_affixes": 0, "maximum_prefixes": 0, "maximum_suffixes": 0}
		Tier.MAGIC:
			return {"minimum_affixes": 1, "maximum_affixes": 2, "maximum_prefixes": 1, "maximum_suffixes": 1}
		Tier.RARE:
			return {"minimum_affixes": 3, "maximum_affixes": 4, "maximum_prefixes": 2, "maximum_suffixes": 2}
		Tier.LEGENDARY:
			return {"minimum_affixes": 4, "maximum_affixes": 6, "maximum_prefixes": 3, "maximum_suffixes": 3}
	return rules(Tier.NORMAL)


static func is_valid(tier: int) -> bool:
	return tier >= Tier.NORMAL and tier <= Tier.LEGENDARY


static func weighted_roll(weights: Array, minimum_tier: int, rng: RandomNumberGenerator) -> int:
	if rng == null or not is_valid(minimum_tier):
		return -1
	var normalized: Array[int] = [0, 0, 0, 0]
	for tier: int in range(Tier.NORMAL, Tier.LEGENDARY + 1):
		if tier < minimum_tier:
			continue
		if tier < weights.size():
			normalized[tier] = maxi(0, int(weights[tier]))
	var total := 0
	for weight: int in normalized:
		total += weight
	if total <= 0:
		return -1
	var roll := rng.randi_range(1, total)
	var cursor := 0
	for tier: int in range(Tier.NORMAL, Tier.LEGENDARY + 1):
		cursor += normalized[tier]
		if roll <= cursor:
			return tier
	return -1
