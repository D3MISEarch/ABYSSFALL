extends RefCounted
class_name CharacterContract

const REQUIRED_SIGNALS := [
	"health_changed",
	"resource_changed",
	"experience_changed",
	"level_up_requested",
	"inventory_changed",
	"skill_tree_changed",
	"died",
	"ability_message",
	"loot_message",
]

const REQUIRED_METHODS := [
	"get_class_id",
	"get_class_display_name",
	"get_class_definition",
	"get_resource_snapshot",
	"add_class_resource",
	"spend_class_resource",
	"add_experience",
	"get_inventory_snapshot",
	"equip_inventory_index",
	"get_skill_tree_snapshot",
	"take_damage",
]


static func validate_character(character: Object) -> PackedStringArray:
	var problems := PackedStringArray()
	if character == null:
		problems.append("Character instance is null.")
		return problems

	for signal_name in REQUIRED_SIGNALS:
		if not character.has_signal(signal_name):
			problems.append("Missing signal: %s" % signal_name)

	for method_name in REQUIRED_METHODS:
		if not character.has_method(method_name):
			problems.append("Missing method: %s" % method_name)

	if not (character is CharacterBody3D):
		problems.append("Playable character must inherit CharacterBody3D.")

	return problems


static func is_valid_character(character: Object) -> bool:
	return validate_character(character).is_empty()
