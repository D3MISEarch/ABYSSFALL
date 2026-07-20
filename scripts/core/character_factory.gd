extends RefCounted
class_name CharacterFactory

const CHARACTER_CONTRACT = preload("res://scripts/core/character_contract.gd")
const VOID_WARLOCK_SCRIPT = preload("res://scripts/characters/void_warlock.gd")
const PENITENT_SCRIPT = preload("res://scripts/characters/penitent_playable.gd")

const DEFAULT_CLASS_ID := "void_warlock"

const CLASS_REGISTRY := {
	"void_warlock": VOID_WARLOCK_SCRIPT,
	"penitent_placeholder": PENITENT_SCRIPT,
}

const CLASS_SELECTION_ORDER := [
	"void_warlock",
	"penitent_placeholder",
	"unknown_path_1",
	"unknown_path_2",
]

const CLASS_DEFINITIONS := {
	"void_warlock": {
		"id": "void_warlock",
		"display_name": "Void Warlock",
		"title": "Master of the Hungry Rift",
		"resource_id": "corruption",
		"resource_name": "Corruption",
		"tags": ["Ranged", "Control", "Summoning", "Burst"],
		"difficulty": "Moderate",
		"skill_branches": ["Abyss", "Corruption", "Soulbinding"],
		"abilities": ["Void Bolt", "Grasping Rift", "Shadow Step", "Soul Feast"],
		"fantasy": "Command gravity, portals, souls, and a living hunger from beyond reality.",
		"strengths": "Immediate control, ranged pressure, violent burst damage.",
		"risks": "The strongest effects depend on feeding Corruption.",
		"accent": Color(0.52, 0.10, 0.95),
		"secondary_accent": Color(0.30, 0.82, 0.06),
		"locked": false,
	},
	"penitent_placeholder": {
		"id": "penitent_placeholder",
		"display_name": "The Penitent",
		"title": "Saint of the Last Rite",
		"resource_id": "fervor",
		"resource_name": "Fervor",
		"tags": ["Hybrid", "Setup", "Area Control", "Risk/Reward"],
		"difficulty": "High",
		"skill_branches": ["Brands", "Circles", "Sacrifice"],
		"abilities": ["Ritual Blade", "Brand of Ruin", "Seal of Binding", "Martyr's Chain", "Ashen Procession"],
		"fantasy": "Carve laws into flesh and force reality to obey the completed rite.",
		"strengths": "Explosive ritual networks, battlefield control, chain reactions.",
		"risks": "Requires setup and may pay for power with blood.",
		"accent": Color(0.78, 0.035, 0.055),
		"secondary_accent": Color(0.32, 0.90, 0.07),
		"locked": false,
		"prototype": true,
	},
	"unknown_path_1": {
		"id": "unknown_path_1",
		"display_name": "Unknown Path",
		"title": "Something Watches Behind the Chains",
		"resource_name": "Sealed",
		"tags": ["Classified", "Unawakened"],
		"difficulty": "Unknown",
		"skill_branches": ["?", "?", "?"],
		"abilities": ["???", "???", "???", "???"],
		"fantasy": "A chained silhouette answers from a realm not yet opened.",
		"strengths": "Complete a future class-unlock path to reveal this vessel.",
		"risks": "The Abyss has not named the price.",
		"accent": Color(0.22, 0.21, 0.25),
		"secondary_accent": Color(0.38, 0.36, 0.42),
		"locked": true,
		"unlock_hint": "THE THIRD SEAL HAS NOT BEEN FOUND",
	},
	"unknown_path_2": {
		"id": "unknown_path_2",
		"display_name": "Unknown Path",
		"title": "No Transmission Returns",
		"resource_name": "Sealed",
		"tags": ["Classified", "Unawakened"],
		"difficulty": "Unknown",
		"skill_branches": ["?", "?", "?"],
		"abilities": ["???", "???", "???", "???"],
		"fantasy": "Only a broken halo and an empty weapon remain beyond this path.",
		"strengths": "Its unlock requirement will emerge from a later realm.",
		"risks": "Identity erased.",
		"accent": Color(0.17, 0.18, 0.21),
		"secondary_accent": Color(0.28, 0.34, 0.32),
		"locked": true,
		"unlock_hint": "PATH REQUIREMENT UNKNOWN",
	},
}


static func create_character(class_id: String = DEFAULT_CLASS_ID) -> CharacterBody3D:
	var resolved_id := class_id if CLASS_REGISTRY.has(class_id) else DEFAULT_CLASS_ID
	var character_script: Script = CLASS_REGISTRY[resolved_id]
	var character = character_script.new()
	var problems := CHARACTER_CONTRACT.validate_character(character)
	if not problems.is_empty():
		push_error(
			"Character '%s' does not satisfy the playable-character contract: %s"
			% [resolved_id, "; ".join(problems)]
		)
		character.queue_free()
		return null
	return character


static func get_registered_class_ids() -> PackedStringArray:
	return PackedStringArray(CLASS_REGISTRY.keys())


static func get_selection_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for class_id in CLASS_SELECTION_ORDER:
		definitions.append(get_class_definition(class_id))
	return definitions


static func get_class_definition(class_id: String) -> Dictionary:
	if not CLASS_DEFINITIONS.has(class_id):
		return CLASS_DEFINITIONS[DEFAULT_CLASS_ID].duplicate(true)
	return CLASS_DEFINITIONS[class_id].duplicate(true)


static func has_class(class_id: String) -> bool:
	return CLASS_REGISTRY.has(class_id)


static func is_locked(class_id: String) -> bool:
	return bool(get_class_definition(class_id).get("locked", true))
