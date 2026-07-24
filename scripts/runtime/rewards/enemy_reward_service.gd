class_name EnemyRewardService
extends RefCounted


func grant(
	enemy: EnemyRuntime,
	character: RuntimeCharacter,
	inventory: InventoryContainer,
	catalog: ItemCatalog,
	affix_catalog: AffixCatalog = null,
	identity_service: ItemIdentityService = null
) -> Dictionary:
	var result := {
		"granted": false,
		"experience": 0,
		"levels": 0,
		"loot": [],
		"rejected_loot": [],
	}
	if enemy == null or character == null or inventory == null or catalog == null or identity_service == null:
		return result
	if not enemy.claim_rewards():
		return result

	var experience := enemy.experience_reward
	var levels := character.gain_experience(experience)
	var accepted: Array[Dictionary] = []
	var rejected: Array[Dictionary] = []
	for item: ItemInstance in LootGenerator.roll(
		enemy.loot_entries,
		enemy.loot_seed,
		catalog,
		affix_catalog,
		enemy.level,
		enemy.minimum_loot_rarity,
		identity_service
	):
		var definition := catalog.get_definition(item.definition_id)
		if definition != null and inventory.add_item(item, definition):
			accepted.append(item.to_dict())
		else:
			rejected.append(item.to_dict())

	result["granted"] = true
	result["experience"] = experience
	result["levels"] = levels
	result["loot"] = accepted
	result["rejected_loot"] = rejected
	return result
