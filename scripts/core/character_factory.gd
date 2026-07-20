extends RefCounted
class_name CharacterFactory

const CHARACTER_CONTRACT = preload("res://scripts/core/character_contract.gd")
const VOID_WARLOCK_SCRIPT = preload("res://scripts/characters/void_warlock.gd")
const PENITENT_SCRIPT = preload("res://scripts/characters/penitent_character.gd")

const DEFAULT_CLASS_ID := "void_warlock"

const CLASS_REGISTRY := {
	"void_warlock": VOID_WARLOCK_SCRIPT,
	"penitent_placeholder": PENITENT_SCRIPT,
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


static func has_class(class_id: String) -> bool:
	return CLASS_REGISTRY.has(class_id)
