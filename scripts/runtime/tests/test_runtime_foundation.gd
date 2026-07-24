extends SceneTree

const STAT_MODIFIER_SCRIPT := preload("res://scripts/runtime/stats/stat_modifier.gd")
const STAT_BLOCK_SCRIPT := preload("res://scripts/runtime/stats/stat_block.gd")
const RESOURCE_POOL_SCRIPT := preload("res://scripts/runtime/resources/class_resource_pool.gd")
const ABILITY_RUNTIME_SCRIPT := preload("res://scripts/runtime/abilities/ability_runtime.gd")
const COMBAT_RESOLVER_SCRIPT := preload("res://scripts/runtime/combat/combat_resolver.gd")
const ENEMY_RUNTIME_SCRIPT := preload("res://scripts/runtime/enemies/enemy_runtime.gd")
const RUNTIME_CHARACTER_SCRIPT := preload("res://scripts/runtime/runtime_character.gd")
const PERSISTENCE_SERVICE_SCRIPT := preload("res://scripts/persistence/persistence_service.gd")
const TEST_ROOT_DIR := "user://abyssfall"

var failures: Array[String] = []
var death_count: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("START: Stage 2 runtime foundation")
	_run_case("deterministic stats", _test_stats)
	_run_case("resource and ability", _test_resource_and_ability)
	_run_case("combat resolution", _test_combat)
	_run_case("enemy death once", _test_enemy_death_once)
	_run_case("runtime character snapshot", _test_runtime_character_snapshot)
	_run_case("runtime persistence round-trip", _test_runtime_persistence_round_trip)
	_cleanup()
	if failures.is_empty():
		print("PASS: Stage 2 runtime foundation")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _run_case(label: String, test_callable: Callable) -> void:
	print("TEST: %s" % label)
	var before: int = failures.size()
	test_callable.call()
	if failures.size() == before:
		print("PASS: %s" % label)


func _call(target: Variant, method: StringName, arguments: Array = []) -> Variant:
	return target.callv(method, arguments)


func _test_stats() -> void:
	var stats: Variant = STAT_BLOCK_SCRIPT.new()
	_call(stats, &"set_base", [&"power", 100.0])
	var gear_modifier: Variant = STAT_MODIFIER_SCRIPT.new("gear", &"power", 0, 20.0, 10)
	var talent_modifier: Variant = STAT_MODIFIER_SCRIPT.new("talent", &"power", 1, 0.10, 20)
	var buff_modifier: Variant = STAT_MODIFIER_SCRIPT.new("buff", &"power", 2, 0.50, 30)
	_call(stats, &"add_modifier", [gear_modifier])
	_call(stats, &"add_modifier", [talent_modifier])
	_call(stats, &"add_modifier", [buff_modifier])
	_expect(is_equal_approx(float(_call(stats, &"get_value", [&"power"])), 198.0), "Stat pipeline should apply flat, additive, then multiplicative layers")
	_call(stats, &"remove_source", ["gear"])
	_expect(is_equal_approx(float(_call(stats, &"get_value", [&"power"])), 165.0), "Removing a source should rebuild stats")


func _test_resource_and_ability() -> void:
	var pool: Variant = RESOURCE_POOL_SCRIPT.new()
	_call(pool, &"configure", [&"fervor", 100.0])
	_call(pool, &"generate", [40.0])
	var ability: Variant = ABILITY_RUNTIME_SCRIPT.new(&"ashen_sigil", 25.0, 2.0)
	_expect(bool(_call(ability, &"try_cast", [pool])), "Ability should cast with enough resource")
	_expect(is_equal_approx(float(pool.current), 15.0), "Ability should spend its cost")
	_expect(not bool(_call(ability, &"try_cast", [pool])), "Ability should respect cooldown")
	_call(ability, &"tick", [2.0])
	_expect(not bool(_call(ability, &"try_cast", [pool])), "Ability should fail when resource is insufficient")
	_expect(is_equal_approx(float(pool.current), 15.0), "Failed cast must not spend resource")


func _test_combat() -> void:
	var result: Dictionary = COMBAT_RESOLVER_SCRIPT.resolve_damage({
		"base_damage": 20.0,
		"power": 100.0,
		"coefficient": 1.0,
		"armor": 100.0,
		"resistance": 0.0,
		"critical": false,
	})
	_expect(is_equal_approx(float(result.get("final_damage", 0.0)), 60.0), "Combat resolver should apply armor deterministically")


func _test_enemy_death_once() -> void:
	death_count = 0
	var enemy: Variant = ENEMY_RUNTIME_SCRIPT.new()
	_call(enemy, &"configure", [{"enemy_id": "husk", "maximum_health": 10.0}])
	enemy.died.connect(_on_enemy_died)
	_call(enemy, &"apply_damage", [20.0])
	_call(enemy, &"apply_damage", [20.0])
	_expect(death_count == 1, "Enemy death should emit exactly once")


func _test_runtime_character_snapshot() -> void:
	var build := BuildData.create_new(ClassIds.PENITENT, "Ashen Vow")
	build.level = 3
	build.experience = 40
	build.equipped_gear["main_hand"] = {"definition_id": "ritual_blade"}
	build.skills["unlocked_abilities"] = ["ashen_sigil"]
	build.build_specific_progress["inventory"] = [{"definition_id": "ember_shard", "quantity": 2}]
	var runtime: Variant = RUNTIME_CHARACTER_SCRIPT.new()
	_call(runtime, &"configure_from_build", [build])
	_expect(runtime.build_id == build.build_id, "Runtime character should bind to its build")
	_expect(runtime.class_id == StringName(ClassIds.PENITENT), "Runtime character should retain canonical class ID")
	_expect(is_equal_approx(float(runtime.current_health), 145.0), "Penitent runtime defaults should derive from level")
	var pre_attach_snapshot: Dictionary = _call(runtime, &"durable_snapshot")
	_expect(pre_attach_snapshot.get("equipped_gear", {}).has("main_hand"), "Runtime character should retain pending equipment until session attachment")
	_expect(pre_attach_snapshot.get("build_specific_progress", {}).get("inventory", []).size() == 1, "Runtime character should retain pending inventory until session attachment")
	_expect(runtime.unlocked_abilities.has(&"ashen_sigil"), "Runtime character should restore unlocked abilities")
	var snapshot: Dictionary = _call(runtime, &"durable_snapshot")
	_expect(snapshot.get("build_id", "") == build.build_id, "Durable snapshot should retain build ID")
	_expect(int(snapshot.get("level", 0)) == 3, "Durable snapshot should retain level")
	_expect(snapshot.has("equipped_gear"), "Durable snapshot should use BuildData equipment field")


func _test_runtime_persistence_round_trip() -> void:
	_cleanup()
	var service: Variant = PERSISTENCE_SERVICE_SCRIPT.new()
	_expect(bool(_call(service, &"initialize", ["Runtime Tester"])), "Persistence service should initialize")
	var build: Variant = _call(service, &"create_and_select_build", [ClassIds.PENITENT, "Last Rite"])
	_expect(build != null, "Persistence service should create a canonical build")
	if build == null:
		service.free()
		return

	build.build_specific_progress["existing_flag"] = true
	build.equipped_gear["main_hand"] = {"definition_id": "faithbreaker", "instance_id": "test:faithbreaker", "quantity": 1}
	build.build_specific_progress["inventory"] = [{"definition_id": "ember_shard", "instance_id": "test:ember_shard", "quantity": 3}]
	build.skills["unlocked_abilities"] = ["brand_of_ruin"]
	var runtime: Variant = RUNTIME_CHARACTER_SCRIPT.new()
	_call(runtime, &"configure_from_build", [build])
	runtime.level = 6
	runtime.experience = 19
	var snapshot: Dictionary = _call(runtime, &"durable_snapshot")

	_expect(bool(_call(service, &"apply_active_build_snapshot", [snapshot])), "Matching runtime snapshot should apply")
	_expect(bool(_call(service, &"is_dirty")), "Applied runtime snapshot should mark persistence dirty")
	var wrong_snapshot := snapshot.duplicate(true)
	wrong_snapshot["build_id"] = "wrong-build"
	_expect(not bool(_call(service, &"apply_active_build_snapshot", [wrong_snapshot])), "Mismatched build snapshot should be rejected")
	_expect(int(_call(service, &"flush_if_dirty", ["runtime_round_trip"])) == OK, "Runtime snapshot should flush")

	var loaded := SaveManager.load_build(build.build_id)
	_expect(loaded != null, "Persisted runtime build should reload")
	if loaded != null:
		_expect(loaded.level == 6 and loaded.experience == 19, "Runtime progression should persist")
		_expect(loaded.equipped_gear.has("main_hand"), "Runtime equipment should persist")
		_expect(bool(loaded.build_specific_progress.get("existing_flag", false)), "Snapshot merge should preserve unrelated build progress")
		var loaded_inventory: Variant = loaded.build_specific_progress.get("inventory", [])
		_expect(loaded_inventory is Array and loaded_inventory.size() == 1, "Runtime inventory should persist")
		var loaded_abilities: Variant = loaded.skills.get("unlocked_abilities", [])
		_expect(loaded_abilities is Array and loaded_abilities.has("brand_of_ruin"), "Runtime abilities should persist")
	service.free()


func _on_enemy_died(_enemy_id: StringName) -> void:
	death_count += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(TEST_ROOT_DIR):
		_remove_tree(TEST_ROOT_DIR)


func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child := path.path_join(entry)
			if directory.current_is_dir():
				_remove_tree(child)
			else:
				DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	directory = null
	DirAccess.remove_absolute(path)
