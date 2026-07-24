class_name PlayableItemCatalog
extends RefCounted

const ITEM_POOL := [
	{
		"id": "void_scepter",
		"name": "Void-Touched Scepter",
		"slot": "Weapon",
		"rarity": "Magic",
		"description": "A fractured focus that sharpens every bolt.",
		"stats": {"bolt_damage": 4, "bolt_speed": 1.5},
		"weight": 15.0,
	},
	{
		"id": "cryptfang_wand",
		"name": "Cryptfang Wand",
		"slot": "Weapon",
		"rarity": "Rare",
		"description": "Carved from a predator that hunted beneath the tombs.",
		"stats": {"bolt_damage": 5, "fire_interval_reduction": 0.018},
		"weight": 11.0,
	},
	{
		"id": "bonebound_grimoire",
		"name": "Bonebound Grimoire",
		"slot": "Weapon",
		"rarity": "Epic",
		"description": "Its pages are stitched from those who refused to speak.",
		"stats": {"bolt_damage": 7, "item_drop_bonus": 0.08},
		"weight": 6.0,
	},
	{
		"id": "whisper_cowl",
		"name": "Cowl of Whispered Veins",
		"slot": "Hood",
		"rarity": "Rare",
		"description": "Wet voices coil around the wearer's thoughts.",
		"stats": {"max_corruption": 18.0, "corruption_gain_multiplier": 0.08},
		"weight": 11.0,
	},
	{
		"id": "graven_crown",
		"name": "Graven Crown",
		"slot": "Hood",
		"rarity": "Epic",
		"description": "A dead monarch's thoughts still twitch inside the metal.",
		"stats": {"max_corruption": 22.0, "rift_damage": 7},
		"weight": 6.0,
	},
	{
		"id": "hunger_carapace",
		"name": "Carapace of Hunger",
		"slot": "Chest",
		"rarity": "Rare",
		"description": "A living shell that drinks pain before blood.",
		"stats": {"max_health": 22},
		"weight": 11.0,
	},
	{
		"id": "ossuary_mantle",
		"name": "Ossuary Mantle",
		"slot": "Chest",
		"rarity": "Epic",
		"description": "Layered grave-plates tighten when enemies draw near.",
		"stats": {"max_health": 28, "max_corruption": 8.0},
		"weight": 6.0,
	},
	{
		"id": "gravegrip_wraps",
		"name": "Gravegrip Wraps",
		"slot": "Gloves",
		"rarity": "Magic",
		"description": "Finger-bones twitch with impatient spellcraft.",
		"stats": {"fire_interval_reduction": 0.026, "bolt_damage": 1},
		"weight": 14.0,
	},
	{
		"id": "tendonweave_grips",
		"name": "Tendonweave Grips",
		"slot": "Gloves",
		"rarity": "Rare",
		"description": "Warm tendons pull the fingers into faster sigils.",
		"stats": {"fire_interval_reduction": 0.032, "corruption_gain_multiplier": 0.06},
		"weight": 9.0,
	},
	{
		"id": "riftwalker_greaves",
		"name": "Riftwalker Greaves",
		"slot": "Boots",
		"rarity": "Magic",
		"description": "Every step briefly forgets the laws of distance.",
		"stats": {"move_speed": 0.75, "max_health": 6},
		"weight": 14.0,
	},
	{
		"id": "gravewind_treads",
		"name": "Gravewind Treads",
		"slot": "Boots",
		"rarity": "Epic",
		"description": "Cold air screams through their hollow soles.",
		"stats": {"move_speed": 1.05, "max_corruption": 12.0},
		"weight": 6.0,
	},
	{
		"id": "maw_starved",
		"name": "Maw of the Starved",
		"slot": "Relic",
		"rarity": "Legendary",
		"description": "It hungers beside you. Feed it, and the Rift bites harder.",
		"stats": {"corruption_gain_multiplier": 0.24, "rift_damage": 10},
		"weight": 3.0,
	},
	{
		"id": "voidheart",
		"name": "Voidheart Amulet",
		"slot": "Relic",
		"rarity": "Epic",
		"description": "A cold pulse answers every stolen soul.",
		"stats": {"rift_radius": 0.85, "soul_heal": 1, "max_corruption": 10.0},
		"weight": 6.0,
	},
	{
		"id": "wretch_bell",
		"name": "Wretch Bell",
		"slot": "Relic",
		"rarity": "Epic",
		"description": "It rings without moving whenever a soul is torn loose.",
		"stats": {"item_drop_bonus": 0.10, "corruption_gain_multiplier": 0.10},
		"weight": 5.0,
	},
]

const HIDDEN_RELIC_ITEM := {
	"id": "reliquary_sunken_teeth",
	"name": "Reliquary of Sunken Teeth",
	"slot": "Relic",
	"rarity": "Epic",
	"description": "The crypt chews every soul before surrendering it.",
	"stats": {"soul_heal": 2, "max_health": 14, "max_corruption": 10.0},
	"weight": 0.0,
}

const HOLLOW_KING_REWARD := {
	"id": "crown_hollow_king",
	"name": "Crown of the Hollow King",
	"slot": "Hood",
	"rarity": "Legendary",
	"description": "The throne is empty. Its appetite is not.",
	"stats": {"max_corruption": 25.0, "corruption_gain_multiplier": 0.15, "rift_damage": 12},
	"weight": 0.0,
}

const PLAYABLE_TO_RUNTIME_SLOT := {
	"Weapon": &"main_hand",
	"Hood": &"head",
	"Chest": &"chest",
	"Gloves": &"gloves",
	"Boots": &"boots",
	"Relic": &"amulet",
}

const RUNTIME_TO_PLAYABLE_SLOT := {
	&"main_hand": "Weapon",
	&"head": "Hood",
	&"chest": "Chest",
	&"gloves": "Gloves",
	&"boots": "Boots",
	&"amulet": "Relic",
}


static func all_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in ITEM_POOL:
		result.append(definition.duplicate(true))
	result.append(HIDDEN_RELIC_ITEM.duplicate(true))
	result.append(HOLLOW_KING_REWARD.duplicate(true))
	return result


static func item_data(definition_id: StringName) -> Dictionary:
	var requested := String(definition_id)
	for definition: Dictionary in all_definitions():
		if str(definition.get("id", "")) == requested:
			return definition.duplicate(true)
	return {}


static func register_runtime_definitions(catalog: ItemCatalog) -> bool:
	if catalog == null:
		return false
	for data: Dictionary in all_definitions():
		var definition_id := StringName(str(data.get("id", "")))
		var runtime_slot := runtime_slot_for_playable(str(data.get("slot", "")))
		if definition_id == &"" or runtime_slot == &"":
			return false
		if catalog.has_definition(definition_id):
			continue
		var slots: Array[StringName] = [runtime_slot]
		var modifiers: Array[Dictionary] = []
		var stats: Dictionary = data.get("stats", {})
		var stat_ids := stats.keys()
		stat_ids.sort()
		for raw_stat_id: Variant in stat_ids:
			modifiers.append({
				"stat_id": str(raw_stat_id),
				"operation": StatModifier.Operation.FLAT,
				"value": float(stats.get(raw_stat_id, 0.0)),
				"priority": 10,
			})
		var tags: Array[StringName] = [&"playable_prototype"]
		var definition := ItemDefinition.new(
			definition_id,
			str(data.get("name", definition_id)),
			slots,
			1,
			modifiers,
			tags
		)
		if not catalog.register(definition):
			return false
	return true


static func create_instance(drop_data: Dictionary, identity_service: ItemIdentityService) -> ItemInstance:
	if identity_service == null:
		return null
	var definition_id := StringName(str(drop_data.get("id", "")))
	var definition := item_data(definition_id)
	if definition.is_empty():
		return null
	var instance_id := identity_service.mint()
	if instance_id.is_empty():
		return null
	var item := ItemInstance.new(definition_id, 1)
	item.instance_id = instance_id
	item.rarity = rarity_tier(str(definition.get("rarity", "Common")))
	item.item_level = 1
	item.generation_seed = 0
	var affixes: Array[Dictionary] = []
	item.affixes = affixes
	item.durability = 1.0
	return item


static func project_item(item: ItemInstance) -> Dictionary:
	if item == null:
		return {}
	var result := item_data(item.definition_id)
	if result.is_empty():
		return {}
	result["instance_id"] = item.instance_id
	result["definition_id"] = String(item.definition_id)
	result["quantity"] = item.quantity
	result["item_level"] = item.item_level
	result["generation_seed"] = item.generation_seed
	result["durability"] = item.durability
	return result


static func runtime_slot_for_playable(playable_slot: String) -> StringName:
	return PLAYABLE_TO_RUNTIME_SLOT.get(playable_slot, &"")


static func playable_slot_for_runtime(runtime_slot: StringName) -> String:
	return str(RUNTIME_TO_PLAYABLE_SLOT.get(runtime_slot, ""))


static func rarity_tier(rarity_name: String) -> int:
	match rarity_name:
		"Magic":
			return LootRarity.Tier.MAGIC
		"Rare":
			return LootRarity.Tier.RARE
		"Epic", "Legendary", "Mythic":
			return LootRarity.Tier.LEGENDARY
		_:
			return LootRarity.Tier.NORMAL
