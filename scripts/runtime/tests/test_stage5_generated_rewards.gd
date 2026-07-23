extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("START: Stage 5 generated rewards")
	_test_enemy_generated_loot_round_trip()
	if failures.is_empty():
		print("PASS: Stage 5 generated rewards")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_enemy_generated_loot_round_trip() -> void:
	var build := BuildData.new()
	build.build_id = "generated-reward-build"
	build.class_id = "penitent"
	build.build_specific_progress = {"inventory": []}

	var character := RuntimeCharacter.new()
	character.configure_from_build(build)
	var session := RuntimeSession.new()
	var tags: Array[StringName] = [&"weapon"]
	var slots: Array[StringName] = [&"main_hand"]
	var base_modifiers: Array[Dictionary] = []
	_expect(_register_item_and_affixes(session, tags, slots, base_modifiers), "Generated reward data should register")
	_expect(session.bind_character(character), "Session should bind generated reward character")

	var enemy := _generated_enemy()
	enemy.apply_damage(10.0)
	var reward := session.grant_enemy_rewards(enemy)
	_expect(bool(reward.get("granted", false)), "Generated reward should be granted")
	_expect(session.inventory.items.size() == 1, "Generated item should enter inventory")
	if session.inventory.items.is_empty():
		session.free()
		return
	var generated: ItemInstance = session.inventory.items[0]
	_expect(generated.definition_id == &"ritual_blade", "Generated reward should preserve base definition")
	_expect(generated.rarity == LootRarity.Tier.MAGIC, "Generated reward should preserve rarity")
	_expect(generated.item_level == 8, "Enemy level should propagate to generated item level")
	_expect(generated.generation_seed != 0, "Generated reward should retain deterministic seed provenance")
	_expect(generated.instance_id == "item:generated-reward-build:1", "First generated reward should use the first session identity")
	_expect(not generated.affixes.is_empty(), "Generated magic reward should contain affix modifiers")
	_expect(not bool(session.grant_enemy_rewards(enemy).get("granted", false)), "Generated rewards should remain exactly once")

	var snapshot := session.durable_snapshot()
	var disk_snapshot := _json_round_trip(snapshot)
	_expect(not disk_snapshot.is_empty(), "Durable snapshot should survive JSON serialization and parsing")
	var identity_snapshot: Dictionary = disk_snapshot.get("build_specific_progress", {}).get("item_identity", {})
	_expect(int(identity_snapshot.get("next_sequence", 0)) == 2, "Snapshot should persist the next unused item identity")
	var reloaded_build := BuildData.from_dict(build.to_dict())
	reloaded_build.level = int(disk_snapshot.get("level", reloaded_build.level))
	reloaded_build.experience = int(disk_snapshot.get("experience", reloaded_build.experience))
	reloaded_build.build_specific_progress = disk_snapshot.get("build_specific_progress", {}).duplicate(true)
	reloaded_build.equipped_gear = disk_snapshot.get("equipped_gear", {}).duplicate(true)
	var reloaded_character := RuntimeCharacter.new()
	reloaded_character.configure_from_build(reloaded_build)
	var reloaded_session := RuntimeSession.new()
	_expect(_register_item_and_affixes(reloaded_session, tags, slots, base_modifiers), "Reload reward data should register")
	_expect(reloaded_session.bind_character(reloaded_character), "JSON-reloaded generated inventory should bind")
	_expect(reloaded_session.inventory.serialize() == session.inventory.serialize(), "Generated item rarity, level, identity, seed, and affixes should survive a real JSON round trip")

	var repeated_enemy := _generated_enemy()
	repeated_enemy.apply_damage(10.0)
	var repeated_reward := reloaded_session.grant_enemy_rewards(repeated_enemy)
	_expect(bool(repeated_reward.get("granted", false)), "A new enemy should grant a second deterministic reward")
	_expect(reloaded_session.inventory.items.size() == 2, "Reloaded identity state should allow a second otherwise-identical item")
	if reloaded_session.inventory.items.size() == 2:
		var repeated: ItemInstance = reloaded_session.inventory.items[1]
		_expect(repeated.instance_id == "item:generated-reward-build:2", "Reloaded allocator must continue without reusing identity one")
		_expect(repeated.instance_id != generated.instance_id, "Repeated generation parameters must not collide after reload")
		_expect(repeated.generation_seed == generated.generation_seed, "Repeated deterministic reward should preserve matching provenance")
		_expect(repeated.affixes == generated.affixes, "Repeated deterministic reward should preserve matching contents")
	var second_snapshot := reloaded_session.durable_snapshot()
	var second_disk_snapshot := _json_round_trip(second_snapshot)
	_expect(not second_disk_snapshot.is_empty(), "Two-item snapshot should survive JSON serialization and parsing")
	var second_identity_snapshot: Dictionary = second_disk_snapshot.get("build_specific_progress", {}).get("item_identity", {})
	_expect(int(second_identity_snapshot.get("next_sequence", 0)) == 3, "Allocator state should advance after the second item")

	var final_build := BuildData.from_dict(reloaded_build.to_dict())
	final_build.build_specific_progress = second_disk_snapshot.get("build_specific_progress", {}).duplicate(true)
	final_build.equipped_gear = second_disk_snapshot.get("equipped_gear", {}).duplicate(true)
	var final_character := RuntimeCharacter.new()
	final_character.configure_from_build(final_build)
	var final_session := RuntimeSession.new()
	_expect(final_session.item_catalog.register(ItemDefinition.new(&"ritual_blade", "Ritual Blade", slots, 1, base_modifiers, tags)), "Final reload base item should register")
	_expect(final_session.bind_character(final_character), "JSON save containing otherwise-identical generated items should remain restorable")
	_expect(final_session.inventory.items.size() == 2, "Final JSON reload should retain both unique physical items")

	session.free()
	reloaded_session.free()
	final_session.free()


func _json_round_trip(data: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	return parsed if parsed is Dictionary else {}


func _generated_enemy() -> EnemyRuntime:
	var enemy := EnemyRuntime.new()
	enemy.configure({
		"enemy_id": "elite_husk",
		"level": 8,
		"maximum_health": 10.0,
		"experience_reward": 30,
		"loot_seed": 884422,
		"loot_entries": [{
			"definition_id": "ritual_blade",
			"chance": 1.0,
			"generated": true,
			"rarity": LootRarity.Tier.MAGIC,
		}],
	})
	return enemy


func _register_item_and_affixes(
	session: RuntimeSession,
	tags: Array[StringName],
	slots: Array[StringName],
	base_modifiers: Array[Dictionary]
) -> bool:
	if not session.item_catalog.register(ItemDefinition.new(&"ritual_blade", "Ritual Blade", slots, 1, base_modifiers, tags)):
		return false
	if not _register_affix(session.affix_catalog, &"brutal", AffixDefinition.Kind.PREFIX, 100, {"stat_id": "power", "operation": StatModifier.Operation.FLAT, "value": 8.0}):
		return false
	return _register_affix(session.affix_catalog, &"of_haste", AffixDefinition.Kind.SUFFIX, 100, {"stat_id": "attack_speed", "operation": StatModifier.Operation.ADDITIVE_PERCENT, "value": 0.08})


func _register_affix(
	catalog: AffixCatalog,
	affix_id: StringName,
	kind: AffixDefinition.Kind,
	weight: int,
	modifier: Dictionary
) -> bool:
	var required: Array[StringName] = [&"weapon"]
	var excluded: Array[StringName] = []
	var modifiers: Array[Dictionary] = [modifier]
	return catalog.register(AffixDefinition.new(
		affix_id,
		String(affix_id),
		kind,
		weight,
		1,
		required,
		excluded,
		modifiers
	))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
