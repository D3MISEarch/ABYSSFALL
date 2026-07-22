class_name ItemInstance
extends RefCounted

var instance_id: String = ""
var definition_id: StringName = &""
var quantity: int = 1
var rarity: int = LootRarity.Tier.NORMAL
var item_level: int = 1
var generation_seed: int = 0
var affixes: Array[Dictionary] = []
var durability: float = 1.0


func _init(p_definition_id: StringName = &"", p_quantity: int = 1) -> void:
	instance_id = "%s-%s" % [Time.get_unix_time_from_system(), randi()]
	definition_id = p_definition_id
	quantity = maxi(1, p_quantity)


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": String(definition_id),
		"quantity": quantity,
		"rarity": rarity,
		"item_level": item_level,
		"generation_seed": generation_seed,
		"affixes": affixes.duplicate(true),
		"durability": durability,
	}


static func from_dict(data: Dictionary) -> ItemInstance:
	var item := ItemInstance.new(StringName(str(data.get("definition_id", ""))), int(data.get("quantity", 1)))
	item.instance_id = str(data.get("instance_id", item.instance_id))
	var serialized_rarity := int(data.get("rarity", LootRarity.Tier.NORMAL))
	item.rarity = serialized_rarity if LootRarity.is_valid(serialized_rarity) else LootRarity.Tier.NORMAL
	item.item_level = maxi(1, int(data.get("item_level", 1)))
	item.generation_seed = int(data.get("generation_seed", 0))
	var restored_affixes: Array[Dictionary] = []
	var serialized_affixes: Variant = data.get("affixes", [])
	if serialized_affixes is Array:
		for raw_affix: Variant in serialized_affixes:
			if raw_affix is Dictionary:
				restored_affixes.append(raw_affix.duplicate(true))
	item.affixes = restored_affixes
	item.durability = clampf(float(data.get("durability", 1.0)), 0.0, 1.0)
	return item
