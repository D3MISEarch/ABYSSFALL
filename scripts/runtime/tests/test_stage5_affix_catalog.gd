extends SceneTree

const AFFIX_DEFINITION_SCRIPT := preload("res://scripts/runtime/items/affix_definition.gd")
const AFFIX_CATALOG_SCRIPT := preload("res://scripts/runtime/items/affix_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("START: Stage 5 affix catalog")
	_test_registration_and_defensive_copy()
	_test_tag_and_level_eligibility()
	_test_weight_totals_are_deterministic()
	if failures.is_empty():
		print("PASS: Stage 5 affix catalog")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _make_affix(
	id: StringName,
	kind: int,
	weight: int,
	minimum_level: int,
	required_tags: Array[StringName],
	excluded_tags: Array[StringName]
) -> Variant:
	var modifiers: Array[Dictionary] = [{
		"stat_id": "damage",
		"operation": 0,
		"value": 5.0,
		"priority": 10,
	}]
	return AFFIX_DEFINITION_SCRIPT.new(
		id,
		String(id),
		kind,
		weight,
		minimum_level,
		required_tags,
		excluded_tags,
		modifiers
	)


func _test_registration_and_defensive_copy() -> void:
	var catalog: Variant = AFFIX_CATALOG_SCRIPT.new()
	var affix: Variant = _make_affix(&"brutal", 0, 100, 1, [&"weapon"], [])
	_expect(bool(catalog.register(affix)), "Catalog should register a valid affix")
	_expect(not bool(catalog.register(affix)), "Catalog should reject duplicate affix IDs")
	var returned: Variant = catalog.get_definition(&"brutal")
	_expect(returned != null, "Registered affix should be retrievable")
	_expect(returned != affix, "Catalog should return a defensive copy")
	_expect(returned.to_read_only_dict() == affix.to_read_only_dict(), "Defensive copy should preserve affix values")
	returned.weight = 1
	_expect(catalog.get_definition(&"brutal").weight == 100, "Mutating a returned copy must not alter catalog state")


func _test_tag_and_level_eligibility() -> void:
	var catalog: Variant = AFFIX_CATALOG_SCRIPT.new()
	catalog.register(_make_affix(&"brutal", 0, 100, 1, [&"weapon"], [&"caster"]))
	catalog.register(_make_affix(&"arcane", 0, 50, 5, [&"weapon", &"caster"], []))
	catalog.register(_make_affix(&"of_guarding", 1, 75, 1, [&"armor"], []))
	var weapon_tags: Array[StringName] = [&"weapon"]
	var low_level: Array = catalog.eligible_definitions(weapon_tags, 1, 0)
	_expect(low_level.size() == 1 and low_level[0].affix_id == &"brutal", "Weapon tags should admit only the matching low-level prefix")
	var caster_tags: Array[StringName] = [&"weapon", &"caster"]
	var caster_level_five: Array = catalog.eligible_definitions(caster_tags, 5, 0)
	_expect(caster_level_five.size() == 1 and caster_level_five[0].affix_id == &"arcane", "Excluded tags and minimum level should filter candidates")
	var armor_tags: Array[StringName] = [&"armor"]
	_expect(catalog.eligible_definitions(armor_tags, 1, 1).size() == 1, "Suffix queries should remain separate from prefixes")


func _test_weight_totals_are_deterministic() -> void:
	var catalog: Variant = AFFIX_CATALOG_SCRIPT.new()
	catalog.register(_make_affix(&"heavy", 0, 25, 1, [&"weapon"], []))
	catalog.register(_make_affix(&"sharp", 0, 75, 1, [&"weapon"], []))
	catalog.register(_make_affix(&"late", 0, 500, 10, [&"weapon"], []))
	var tags: Array[StringName] = [&"weapon"]
	_expect(catalog.total_weight(tags, 1, 0) == 100, "Total weight should include only eligible definitions")
	var candidates: Array = catalog.eligible_definitions(tags, 1, 0)
	_expect(candidates.size() == 2 and candidates[0].affix_id == &"heavy" and candidates[1].affix_id == &"sharp", "Eligible definitions should use stable ID ordering")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
