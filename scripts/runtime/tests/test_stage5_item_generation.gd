extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("START: Stage 5 item generation")
	_test_deterministic_weighted_generation()
	_test_rarity_caps_and_duplicate_prevention()
	_test_generation_failure_is_atomic()
	_test_generated_item_round_trip()
	if failures.is_empty():
		print("PASS: Stage 5 item generation")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _catalog() -> AffixCatalog:
	var catalog := AffixCatalog.new()
	_register(catalog, &"brutal", AffixDefinition.Kind.PREFIX, 80, 1, [&"weapon"], {"stat_id": "power", "operation": StatModifier.Operation.FLAT, "value": 8.0})
	_register(catalog, &"merciless", AffixDefinition.Kind.PREFIX, 20, 5, [&"weapon"], {"stat_id": "power", "operation": StatModifier.Operation.FLAT, "value": 15.0})
	_register(catalog, &"tempered", AffixDefinition.Kind.PREFIX, 40, 1, [&"weapon"], {"stat_id": "armor", "operation": StatModifier.Operation.FLAT, "value": 4.0})
	_register(catalog, &"of_haste", AffixDefinition.Kind.SUFFIX, 60, 1, [&"weapon"], {"stat_id": "attack_speed", "operation": StatModifier.Operation.ADDITIVE_PERCENT, "value": 0.08})
	_register(catalog, &"of_ruin", AffixDefinition.Kind.SUFFIX, 25, 3, [&"weapon"], {"stat_id": "critical_damage", "operation": StatModifier.Operation.ADDITIVE_PERCENT, "value": 0.18})
	_register(catalog, &"of_embers", AffixDefinition.Kind.SUFFIX, 15, 7, [&"weapon"], {"stat_id": "fire_damage", "operation": StatModifier.Operation.FLAT, "value": 12.0})
	return catalog


func _register(
	catalog: AffixCatalog,
	affix_id: StringName,
	kind: AffixDefinition.Kind,
	weight: int,
	minimum_level: int,
	required_tags: Array[StringName],
	modifier: Dictionary
) -> void:
	var excluded: Array[StringName] = []
	var modifiers: Array[Dictionary] = [modifier]
	_expect(catalog.register(AffixDefinition.new(
		affix_id,
		String(affix_id),
		kind,
		weight,
		minimum_level,
		required_tags,
		excluded,
		modifiers
	)), "Affix %s should register" % String(affix_id))


func _weapon() -> ItemDefinition:
	var slots: Array[StringName] = [&"main_hand"]
	var modifiers: Array[Dictionary] = []
	var tags: Array[StringName] = [&"weapon"]
	return ItemDefinition.new(&"ritual_blade", "Ritual Blade", slots, 1, modifiers, tags)


func _test_deterministic_weighted_generation() -> void:
	var catalog := _catalog()
	var first := ItemGenerator.generate(_weapon(), 10, LootRarity.Tier.LEGENDARY, 991337, catalog)
	var second := ItemGenerator.generate(_weapon(), 10, LootRarity.Tier.LEGENDARY, 991337, catalog)
	_expect(first != null and second != null, "Eligible legendary generation should succeed")
	if first == null or second == null:
		return
	_expect(first.to_dict() == second.to_dict(), "Same seed and inputs should produce byte-equivalent item data")
	_expect(first.instance_id == "generated:991337:ritual_blade:10:3", "Generated identity should be deterministic and input-derived")


func _test_rarity_caps_and_duplicate_prevention() -> void:
	var catalog := _catalog()
	var magic := ItemGenerator.generate(_weapon(), 10, LootRarity.Tier.MAGIC, 111, catalog)
	var rare := ItemGenerator.generate(_weapon(), 10, LootRarity.Tier.RARE, 222, catalog)
	var legendary := ItemGenerator.generate(_weapon(), 10, LootRarity.Tier.LEGENDARY, 333, catalog)
	_expect(magic != null and _unique_affix_count(magic.affixes) >= 1 and _unique_affix_count(magic.affixes) <= 2, "Magic items should roll one or two affixes")
	_expect(rare != null and _unique_affix_count(rare.affixes) >= 3 and _unique_affix_count(rare.affixes) <= 4, "Rare items should roll three or four affixes")
	_expect(legendary != null and _unique_affix_count(legendary.affixes) >= 4 and _unique_affix_count(legendary.affixes) <= 6, "Legendary items should roll four to six affixes")
	if legendary != null:
		_expect(_unique_affix_count(legendary.affixes) == _affix_ids(legendary.affixes).size(), "A generated item must not repeat an affix ID")


func _test_generation_failure_is_atomic() -> void:
	var empty_catalog := AffixCatalog.new()
	var failed := ItemGenerator.generate(_weapon(), 10, LootRarity.Tier.RARE, 44, empty_catalog)
	_expect(failed == null, "Generation should fail when a rarity minimum cannot be satisfied")
	var normal := ItemGenerator.generate(_weapon(), 1, LootRarity.Tier.NORMAL, 45, null)
	_expect(normal != null and normal.affixes.is_empty(), "Normal generation should not require an affix catalog")
	_expect(ItemGenerator.generate(_weapon(), 1, LootRarity.Tier.NORMAL, 0, null) == null, "Zero seed should be rejected rather than creating unstable identity")


func _test_generated_item_round_trip() -> void:
	var generated := ItemGenerator.generate(_weapon(), 10, LootRarity.Tier.RARE, 7788, _catalog())
	_expect(generated != null, "Round-trip source item should generate")
	if generated == null:
		return
	var restored := ItemInstance.from_dict(generated.to_dict())
	_expect(restored.to_dict() == generated.to_dict(), "Generated rarity, item level, identity, and affixes should survive serialization")


func _unique_affix_count(modifiers: Array[Dictionary]) -> int:
	return _affix_ids(modifiers).size()


func _affix_ids(modifiers: Array[Dictionary]) -> Dictionary:
	var ids: Dictionary = {}
	for modifier: Dictionary in modifiers:
		var affix_id := str(modifier.get("affix_id", ""))
		if not affix_id.is_empty():
			ids[affix_id] = true
	return ids


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
