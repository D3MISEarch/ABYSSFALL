extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("START: Stage 3-4 durable vertical slice")
	_test_kill_loot_equip_save_reload()
	if failures.is_empty():
		print("PASS: Stage 3-4 durable vertical slice")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_kill_loot_equip_save_reload() -> void:
	var build := BuildData.new()
	build.build_id = "vertical-slice"
	build.class_id = "penitent"
	build.level = 1
	build.experience = 0
	build.equipped_gear = {}
	build.skills = {}
	build.build_specific_progress = {"inventory": []}

	var character := RuntimeCharacter.new()
	character.configure_from_build(build)
	var session := RuntimeSession.new()
	var definition := ItemDefinition.new(
		&"ashen_hood",
		"Ashen Hood",
		[&"head"],
		1,
		[{"stat_id": "armor", "operation": StatModifier.Operation.FLAT, "value": 12.0}]
	)
	_expect(session.item_catalog.register(definition), "Item definition should register")
	_expect(session.bind_character(character), "RuntimeSession should bind and restore item systems")

	var enemy := EnemyRuntime.new()
	enemy.configure({
		"enemy_id": "husk",
		"maximum_health": 10.0,
		"experience_reward": 120,
		"loot_seed": 991337,
		"loot_entries": [{"definition_id": "ashen_hood", "chance": 1.0, "minimum": 1, "maximum": 1}],
	})
	enemy.apply_damage(10.0)
	var reward := session.grant_enemy_rewards(enemy)
	_expect(bool(reward.get("granted", false)), "Enemy reward should be granted")
	_expect(character.level == 2 and character.experience == 20, "XP should level the character exactly once")
	_expect(session.inventory.items.size() == 1, "Loot should enter the session inventory")

	if session.inventory.items.is_empty():
		return
	var instance_id := session.inventory.items[0].instance_id
	var item := session.inventory.remove_instance(instance_id, 1)
	_expect(item != null, "Loot should be removable for equipping")
	if item == null:
		return
	session.equipment.equip(&"head", item)
	_expect(is_equal_approx(character.stats.get_value(&"armor"), 12.0), "Equipping loot should rebuild character stats")

	var persistence := PersistenceService.new()
	persistence.active_build = build
	_expect(persistence.apply_active_build_snapshot(session.durable_snapshot()), "Durable runtime snapshot should apply to persistence")
	var reloaded_build := BuildData.from_dict(build.to_dict())
	var reloaded_character := RuntimeCharacter.new()
	reloaded_character.configure_from_build(reloaded_build)
	var reloaded_session := RuntimeSession.new()
	_expect(reloaded_session.item_catalog.register(definition), "Reload catalog should register the same immutable definition")
	_expect(reloaded_session.bind_character(reloaded_character), "Reloaded session should restore inventory and equipment")
	_expect(reloaded_character.level == 2 and reloaded_character.experience == 20, "Reload should preserve XP progression")
	_expect(reloaded_session.inventory.items.is_empty(), "Equipped item should not remain duplicated in inventory")
	_expect(reloaded_session.equipment.serialize() == session.equipment.serialize(), "Reload should preserve equipped item identity")
	_expect(is_equal_approx(reloaded_character.stats.get_value(&"armor"), 12.0), "Reload should rebuild equipment stats deterministically")
	_expect(reloaded_session.durable_snapshot() == session.durable_snapshot(), "Reloaded durable state should match the original snapshot")

	session.free()
	reloaded_session.free()
	persistence.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
