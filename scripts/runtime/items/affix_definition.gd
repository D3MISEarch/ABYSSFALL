class_name AffixDefinition
extends RefCounted

enum Kind {
	PREFIX,
	SUFFIX,
}

var affix_id: StringName = &""
var display_name: String = ""
var kind: Kind = Kind.PREFIX
var weight: int = 1
var minimum_item_level: int = 1
var required_tags: Array[StringName] = []
var excluded_tags: Array[StringName] = []
var modifiers: Array[Dictionary] = []


func _init(
	p_affix_id: StringName = &"",
	p_display_name: String = "",
	p_kind: Kind = Kind.PREFIX,
	p_weight: int = 1,
	p_minimum_item_level: int = 1,
	p_required_tags: Array[StringName] = [],
	p_excluded_tags: Array[StringName] = [],
	p_modifiers: Array[Dictionary] = []
) -> void:
	affix_id = p_affix_id
	display_name = p_display_name
	kind = p_kind
	weight = maxi(0, p_weight)
	minimum_item_level = maxi(1, p_minimum_item_level)
	required_tags = p_required_tags.duplicate()
	excluded_tags = p_excluded_tags.duplicate()
	modifiers = p_modifiers.duplicate(true)


func is_valid() -> bool:
	return affix_id != &"" and weight > 0 and not modifiers.is_empty()


func is_eligible(item_tags: Array[StringName], item_level: int) -> bool:
	if not is_valid() or item_level < minimum_item_level:
		return false
	for required_tag: StringName in required_tags:
		if required_tag not in item_tags:
			return false
	for excluded_tag: StringName in excluded_tags:
		if excluded_tag in item_tags:
			return false
	return true


func duplicate_definition() -> AffixDefinition:
	return AffixDefinition.new(
		affix_id,
		display_name,
		kind,
		weight,
		minimum_item_level,
		required_tags,
		excluded_tags,
		modifiers
	)


func to_read_only_dict() -> Dictionary:
	return {
		"affix_id": String(affix_id),
		"display_name": display_name,
		"kind": int(kind),
		"weight": weight,
		"minimum_item_level": minimum_item_level,
		"required_tags": required_tags.duplicate(),
		"excluded_tags": excluded_tags.duplicate(),
		"modifiers": modifiers.duplicate(true),
	}
