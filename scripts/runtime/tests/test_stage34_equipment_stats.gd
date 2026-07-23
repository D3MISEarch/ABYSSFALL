extends SceneTree

var failures: Array[String] = []
var equipment_changed_events := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("START: Stage 3-4 equipment stat integration")
	_test_equip_replace_unequip()
	_test_restore_and_identity_validation()
	_test_two_handed_occupancy()
	if failures.is_empty():
		print("PASS: Stage 3-4 equipment stat integration")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _identity(session_id: String) -> ItemIdentityService:
	var service := ItemIdentityService.new()
	_expect(service.configure(session_id), "Identity service %s should configure" % session_id)
	return service


func _item(definition_id: StringName, identity: ItemIdentityService) -> ItemInstance:
	var item := ItemInstance.new(definition_id)
	item.instance_id = identity.mint()
	return item


func _test_equip_replace_unequip() -> void:
	var identity := _identity("equipment-basic")
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
	_expect(catalog.register(blade), "Blade definition should register")
	_expect(catalog.register(relic), "Relic definition should register")
	var stats := StatBlock.new()
	stats.set_base(&"power", 100.0)
	var equipment := EquipmentManager.new()
	equipment.configure(catalog, stats)
	var blade_item := _item(&"ritual_blade", identity)
	blade_item.affixes.append({"stat_id": "power", "operation": StatModifier.Operation.FLAT, "value": 5.0})
	_expect(equipment.can_equip(&"main_hand", blade_item), "Catalog slot should allow blade")
	equipment.equip(&"main_hand", blade_item)
	_expect(is_equal_approx(stats.get_value(&"power"), 125.0), "Definition and affix modifiers should apply")
	var relic_item := _item(&"faithbreaker", identity)
	var replaced := equipment.equip(&"main_hand", relic_item)
	_expect(replaced == blade_item, "Replacing equipment should return previous item")
	_expect(is_equal_approx(stats.get_value(&"power"), 125.0), "Replacement should remove old source before applying new source")
	var removed := equipment.unequip(&"main_hand")
	_expect(removed == relic_item, "Unequip should return equipped item")
	_expect(is_equal_approx(stats.get_value(&"power"), 100.0), "Unequip should remove equipment modifiers")


func _test_restore_and_identity_validation() -> void:
	var identity := _identity("equipment-restore")
	var catalog := ItemCatalog.new()
	_expect(catalog.register(ItemDefinition.new(
		&"ashen_hood",
		"Ashen Hood",
		[&"head"],
		1,
		[{"stat_id": "armor", "operation": StatModifier.Operation.FLAT, "value": 12.0}]
	)), "Hood definition should register")
	_expect(catalog.register(ItemDefinition.new(
		&"binding_ring",
		"Binding Ring",
		[&"ring_left", &"ring_right"],
		1,
		[{"stat_id": "armor", "operation": StatModifier.Operation.FLAT, "value": 3.0}]
	)), "Ring definition should register")
	var stats := StatBlock.new()
	stats.set_base(&"armor", 3.0)
	var equipment := EquipmentManager.new()
	equipment.configure(catalog, stats)
	equipment.equipment_changed.connect(_on_equipment_changed)
	var hood := _item(&"ashen_hood", identity)
	var serialized := {"head": hood.to_dict()}
	_expect(equipment.restore(serialized), "Valid equipment snapshot should restore")
	_expect(is_equal_approx(stats.get_value(&"armor"), 15.0), "Restored equipment should rebuild stats")
	var before := equipment.serialize()
	var before_armor := stats.get_value(&"armor")
	equipment_changed_events = 0
	_expect(not equipment.restore({"main_hand": hood.to_dict()}), "Wrong-slot restore should fail")
	_expect(equipment.serialize() == before and is_equal_approx(stats.get_value(&"armor"), before_armor), "Failed wrong-slot restore must leave equipment and stats unchanged")

	var empty_id := hood.to_dict()
	empty_id["instance_id"] = ""
	_expect(not equipment.restore({"head": empty_id}), "Empty equipment identity should fail restoration")
	_expect(equipment.serialize() == before and is_equal_approx(stats.get_value(&"armor"), before_armor), "Empty-ID failure must preserve prior state")

	var ring := _item(&"binding_ring", identity)
	var duplicate_snapshot := {
		"ring_left": ring.to_dict(),
		"ring_right": ring.to_dict(),
	}
	_expect(not equipment.restore(duplicate_snapshot), "Duplicate physical identity across equipment slots should fail")
	_expect(equipment.serialize() == before and is_equal_approx(stats.get_value(&"armor"), before_armor), "Duplicate restore failure must preserve equipment and stats")
	_expect(equipment_changed_events == 0, "Failed restoration must emit no equipment change signal")

	var live_ring := _item(&"binding_ring", identity)
	_expect(equipment.equip(&"ring_left", live_ring) == null, "First ring equip into an empty slot should succeed")
	var equipped_before := equipment.serialize()
	var events_before := equipment_changed_events
	_expect(equipment.equip(&"ring_right", live_ring) == null, "Same physical ring should be rejected in a second slot")
	_expect(equipment.serialize() == equipped_before, "Duplicate live equip should preserve equipment")
	_expect(equipment_changed_events == events_before, "Duplicate live equip should emit no signal")
	var missing := _item(&"missing_definition", identity)
	_expect(not equipment.can_equip(&"head", missing), "Unknown definitions should be rejected")


func _test_two_handed_occupancy() -> void:
	var identity := _identity("two-handed")
	var catalog := ItemCatalog.new()
	var two_handed_tags: Array[StringName] = [&"weapon", &"two_handed"]
	var weapon_tags: Array[StringName] = [&"weapon"]
	var shield_tags: Array[StringName] = [&"shield"]
	_expect(catalog.register(ItemDefinition.new(
		&"great_cleaver",
		"Great Cleaver",
		[&"main_hand"],
		1,
		[{"stat_id": "power", "operation": StatModifier.Operation.FLAT, "value": 20.0}],
		two_handed_tags
	)), "Two-handed definition should register")
	_expect(catalog.register(ItemDefinition.new(
		&"one_hand_blade",
		"One Hand Blade",
		[&"main_hand"],
		1,
		[{"stat_id": "power", "operation": StatModifier.Operation.FLAT, "value": 8.0}],
		weapon_tags
	)), "One-handed definition should register")
	_expect(catalog.register(ItemDefinition.new(
		&"iron_guard",
		"Iron Guard",
		[&"off_hand"],
		1,
		[{"stat_id": "armor", "operation": StatModifier.Operation.FLAT, "value": 10.0}],
		shield_tags
	)), "Off-hand definition should register")

	var clear_stats := StatBlock.new()
	clear_stats.set_base(&"power", 0.0)
	clear_stats.set_base(&"armor", 0.0)
	var clear_equipment := EquipmentManager.new()
	clear_equipment.configure(catalog, clear_stats)
	var great_cleaver := _item(&"great_cleaver", identity)
	clear_equipment.equip(&"main_hand", great_cleaver)
	_expect(clear_equipment.equipped.get(&"main_hand") == great_cleaver, "Two-handed item should equip when off-hand is empty")
	_expect(is_equal_approx(clear_stats.get_value(&"power"), 20.0), "Two-handed modifiers should apply")
	var blocked_shield := _item(&"iron_guard", identity)
	var clear_before := clear_equipment.serialize()
	_expect(clear_equipment.equip(&"off_hand", blocked_shield) == null, "Off-hand equip should fail while two-handed main hand is active")
	_expect(clear_equipment.serialize() == clear_before, "Blocked off-hand equip must preserve equipment")

	var occupied_stats := StatBlock.new()
	occupied_stats.set_base(&"power", 0.0)
	occupied_stats.set_base(&"armor", 0.0)
	var occupied_equipment := EquipmentManager.new()
	occupied_equipment.configure(catalog, occupied_stats)
	var shield := _item(&"iron_guard", identity)
	occupied_equipment.equip(&"off_hand", shield)
	var occupied_before := occupied_equipment.serialize()
	var occupied_armor := occupied_stats.get_value(&"armor")
	var blocked_cleaver := _item(&"great_cleaver", identity)
	_expect(occupied_equipment.equip(&"main_hand", blocked_cleaver) == null, "Two-handed equip should fail while off-hand is occupied")
	_expect(occupied_equipment.serialize() == occupied_before and is_equal_approx(occupied_stats.get_value(&"armor"), occupied_armor), "Blocked two-handed equip must preserve equipment and stats")

	var one_hand := _item(&"one_hand_blade", identity)
	occupied_equipment.equip(&"main_hand", one_hand)
	_expect(occupied_equipment.equipped.get(&"main_hand") == one_hand and occupied_equipment.equipped.get(&"off_hand") == shield, "Ordinary one-hand and off-hand equipment should coexist")
	var valid_before := occupied_equipment.serialize()
	var power_before := occupied_stats.get_value(&"power")
	var armor_before := occupied_stats.get_value(&"armor")
	var invalid_restore := {
		"main_hand": blocked_cleaver.to_dict(),
		"off_hand": shield.to_dict(),
	}
	_expect(not occupied_equipment.restore(invalid_restore), "Restore should reject two-handed main hand plus off-hand")
	_expect(occupied_equipment.serialize() == valid_before, "Invalid two-handed restore must preserve prior equipment")
	_expect(is_equal_approx(occupied_stats.get_value(&"power"), power_before) and is_equal_approx(occupied_stats.get_value(&"armor"), armor_before), "Invalid two-handed restore must preserve prior stats")


func _on_equipment_changed(_slot_id: StringName, _equipped: ItemInstance, _unequipped: ItemInstance) -> void:
	equipment_changed_events += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
