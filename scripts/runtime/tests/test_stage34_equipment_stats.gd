extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("START: Stage 3-4 equipment stat integration")
	_test_equip_replace_unequip()
	_test_restore_and_validation()
	if failures.is_empty():
		print("PASS: Stage 3-4 equipment stat integration")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_equip_replace_unequip() -> void:
	var catalog := ItemCatalog.new()
	var blade := ItemDefinition.new(
		&"ritual_blade",
		"Ritual Blade",
		[&"main_hand"],
		1,
		[{"stat_id": "power", "operation": StatModifier.Operation.FLAT, "value": 20.0}]
	)
	var relic := ItemDefinition.new(
		&"faithbreaker",
		"Faithbreaker",
		[&"main_hand"],
		1,
		[{"stat_id": "power", "operation": StatModifier.Operation.ADDITIVE_PERCENT, "value": 0.25}]
	)
	_expect(catalog.register_definition(blade), "Blade definition should register")
	_expect(catalog.register_definition(relic), "Relic definition should register")
	var stats := StatBlock.new()
	stats.set_base(&"power", 100.0)
	var equipment := EquipmentManager.new()
	equipment.configure(catalog, stats)
	var blade_item := ItemInstance.new(&"ritual_blade")
	blade_item.affixes.append({"stat_id": "power", "operation": StatModifier.Operation.FLAT, "value": 5.0})
	_expect(equipment.can_equip(&"main_hand", blade_item), "Catalog slot should allow blade")
	equipment.equip(&"main_hand", blade_item)
	_expect(is_equal_approx(stats.get_value(&"power"), 125.0), "Definition and affix modifiers should apply")
	var relic_item := ItemInstance.new(&"faithbreaker")
	var replaced := equipment.equip(&"main_hand", relic_item)
	_expect(replaced == blade_item, "Replacing equipment should return previous item")
	_expect(is_equal_approx(stats.get_value(&"power"), 125.0), "Replacement should remove old source before applying new source")
	var removed := equipment.unequip(&"main_hand")
	_expect(removed == relic_item, "Unequip should return equipped item")
	_expect(is_equal_approx(stats.get_value(&"power"), 100.0), "Unequip should remove equipment modifiers")


func _test_restore_and_validation() -> void:
	var catalog := ItemCatalog.new()
	catalog.register_definition(ItemDefinition.new(
		&"ashen_hood",
		"Ashen Hood",
		[&"head"],
		1,
		[{"stat_id": "armor", "operation": StatModifier.Operation.FLAT, "value": 12.0}]
	))
	var stats := StatBlock.new()
	stats.set_base(&"armor", 3.0)
	var equipment := EquipmentManager.new()
	equipment.configure(catalog, stats)
	var item := ItemInstance.new(&"ashen_hood")
	var serialized := {"head": item.to_dict()}
	_expect(equipment.restore(serialized), "Valid equipment snapshot should restore")
	_expect(is_equal_approx(stats.get_value(&"armor"), 15.0), "Restored equipment should rebuild stats")
	var before := equipment.serialize()
	_expect(not equipment.restore({"main_hand": item.to_dict()}), "Wrong-slot restore should fail")
	_expect(equipment.serialize() == before, "Failed restore must leave equipment unchanged")
	_expect(not equipment.can_equip(&"head", ItemInstance.new(&"missing_definition")), "Unknown definitions should be rejected")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
