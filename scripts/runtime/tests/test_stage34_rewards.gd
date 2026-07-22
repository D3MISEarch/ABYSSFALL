extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("START: Stage 3-4 rewards")
	_test_deterministic_loot()
	_test_exactly_once_rewards()
	if failures.is_empty():
		print("PASS: Stage 3-4 rewards")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_deterministic_loot() -> void:
	var entries: Array = [
		{"definition_id": "ember_shard", "chance": 1.0, "minimum": 1, "maximum": 3},
		{"definition_id": "ritual_blade", "chance": 0.5, "minimum": 1, "maximum": 1},
	]
	var first_identity := ItemIdentityService.new()
	var second_identity := ItemIdentityService.new()
	_expect(first_identity.configure("loot-determinism"), "First deterministic identity service should configure")
	_expect(second_identity.configure("loot-determinism"), "Second deterministic identity service should configure")
	var first := LootGenerator.roll(entries, 7734, null, null, 1, LootRarity.Tier.NORMAL, first_identity)
	var second := LootGenerator.roll(entries, 7734, null, null, 1, LootRarity.Tier.NORMAL, second_identity)
	_expect(_serialize(first) == _serialize(second), "Same seed and identity state should produce identical loot")


func _test_exactly_once_rewards() -> void:
	var catalog := ItemCatalog.new()
	catalog.register(ItemDefinition.new(&"ember_shard", "Ember Shard", [], 99))
	var identity := ItemIdentityService.new()
	_expect(identity.configure("reward-test"), "Reward identity service should configure")
	var inventory := InventoryContainer.new(4, identity)
	var character := RuntimeCharacter.new()
	character.build_id = "reward-test"
	character.experience_to_next = 100
	var enemy := EnemyRuntime.new()
	enemy.configure({
		"enemy_id": "husk",
		"maximum_health": 10.0,
		"experience_reward": 120,
		"loot_seed": 99,
		"loot_entries": [{"definition_id": "ember_shard", "chance": 1.0, "minimum": 2, "maximum": 2}],
	})
	enemy.apply_damage(10.0)
	var service := EnemyRewardService.new()
	var first: Dictionary = service.grant(enemy, character, inventory, catalog, null, identity)
	var second: Dictionary = service.grant(enemy, character, inventory, catalog, null, identity)
	_expect(bool(first.get("granted", false)), "First reward claim should succeed")
	_expect(not bool(second.get("granted", false)), "Second reward claim should be rejected")
	_expect(character.level == 2 and character.experience == 20, "Reward XP should support level rollover")
	_expect(inventory.items.size() == 1 and inventory.items[0].quantity == 2, "Reward loot should enter inventory once")


func _serialize(items: Array[ItemInstance]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: ItemInstance in items:
		result.append(item.to_dict())
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
