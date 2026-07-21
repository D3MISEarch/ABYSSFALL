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
