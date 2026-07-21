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
	_expect(session.item_catalog.register(ItemDefinition.new(
		&"ritual_blade",
		"Ritual Blade",
		slots,
		1,
		base_modifiers,
		tags
	)), "Generated reward base item should register")
	_expect(_register_affix(session.affix_catalog, &"brutal", AffixDefinition.Kind.PREFIX, 100, {"stat_id": "power", "operation": StatModifier.Operation.FLAT, "value": 8.0}), "Prefix should register")
	_expect(_register_affix(session.affix_catalog, &"of_haste", AffixDefinition.Kind.SUFFIX, 100, {"stat_id": "attack_speed", "operation": StatModifier.Operation.ADDITIVE_PERCENT, "value": 0.08}), "Suffix should register")
	_expect(session.bind_character(character), "Session should bind generated reward character")

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
	_expect(not generated.affixes.is_empty(), "Generated magic reward should contain affix modifiers")
	_expect(not bool(session.grant_enemy_rewards(enemy).get("granted", false)), "Generated rewards should remain exactly once")

	var snapshot := session.durable_snapshot()
	var reloaded_build := BuildData.from_dict(build.to_dict())
	reloaded_build.build_specific_progress = snapshot.get("build_specific_progress", {}).duplicate(true)
	reloaded_build.equipped_gear = snapshot.get("equipped_gear", {}).duplicate(true)
	var reloaded_character := RuntimeCharacter.new()
	reloaded_character.configure_from_build(reloaded_build)
	var reloaded_session := RuntimeSession.new()
	_expect(reloaded_session.item_catalog.register(ItemDefinition.new(&"ritual_blade", "Ritual Blade", slots, 1, base_modifiers, tags)), "Reload base item should register")
	_expect(reloaded_session.bind_character(reloaded_character), "Reloaded generated inventory should bind")
	_expect(reloaded_session.inventory.serialize() == session.inventory.serialize(), "Generated item rarity, level, identity, and affixes should survive runtime reload")

	session.free()
	reloaded_session.free()


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
