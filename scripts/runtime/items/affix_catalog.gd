class_name AffixCatalog
extends RefCounted

var _definitions: Dictionary = {}


func register(definition: AffixDefinition) -> bool:
	if definition == null or not definition.is_valid():
		return false
	if _definitions.has(definition.affix_id):
		return false
	_definitions[definition.affix_id] = definition.duplicate_definition()
	return true


func get_definition(affix_id: StringName) -> AffixDefinition:
	var stored: AffixDefinition = _definitions.get(affix_id)
	return stored.duplicate_definition() if stored != null else null


func eligible_definitions(
	item_tags: Array[StringName],
	item_level: int,
	kind: AffixDefinition.Kind
) -> Array[AffixDefinition]:
	var result: Array[AffixDefinition] = []
	for affix_id: StringName in _definitions:
		var stored: AffixDefinition = _definitions[affix_id]
		if stored.kind == kind and stored.is_eligible(item_tags, item_level):
			result.append(stored.duplicate_definition())
	result.sort_custom(func(a: AffixDefinition, b: AffixDefinition) -> bool: return a.affix_id < b.affix_id)
	return result


func total_weight(
	item_tags: Array[StringName],
	item_level: int,
	kind: AffixDefinition.Kind
) -> int:
	var total := 0
	for definition: AffixDefinition in eligible_definitions(item_tags, item_level, kind):
		total += definition.weight
	return total
