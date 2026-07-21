class_name ItemCatalog
extends RefCounted

var _definitions: Dictionary = {}


func register(definition: ItemDefinition) -> bool:
	if definition == null or definition.definition_id == &"":
		return false
	if _definitions.has(definition.definition_id):
		return false
	_definitions[definition.definition_id] = definition
	return true


func get_definition(definition_id: StringName) -> ItemDefinition:
	return _definitions.get(definition_id)


func has_definition(definition_id: StringName) -> bool:
	return _definitions.has(definition_id)


func all_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for definition_id: StringName in _definitions:
		result.append(definition_id)
	result.sort()
	return result


func size() -> int:
	return _definitions.size()
