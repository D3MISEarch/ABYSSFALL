extends SceneTree

const CATALOG_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_ability_catalog.gd")
const COMMAND_CONTRACT_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_command_contract.gd")
const DAMAGE_BRIDGE_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_damage_bridge.gd")
const PROJECTION_SCRIPT = preload("res://scripts/core/playable_combat_projection.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_stable_catalog_and_approved_base_definitions()
	_test_six_slot_command_contract()
	_test_compatibility_damage_bridge_and_single_critical_consumption()
	if failures.is_empty():
		print("PASS: Voidbringer command and damage foundation")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_stable_catalog_and_approved_base_definitions() -> void:
	var catalog = CATALOG_SCRIPT.new()
	var expected_ids: Array[StringName] = [
		&"vb.action.closure",
		&"vb.skill.mass_brand",
		&"vb.skill.null_shard",
		&"vb.skill.worldshear",
		&"vb.skill.event_step",
		&"vb.skill.hard_vacuum",
		&"vb.skill.convergence",
		&"vb.ultimate.dead_star",
	]
	_expect(catalog.all_stable_ids() == expected_ids, "The catalog should preserve every approved durable foundation ID")

	var mass_brand: AbilityDefinition = catalog.mass_brand_definition()
	_expect(mass_brand.ability_id == &"vb.skill.mass_brand", "Mass Brand should use its approved stable ID")
	_expect(mass_brand.maximum_charges == 2, "Mass Brand should begin with two charges")
	_expect(is_equal_approx(mass_brand.recharge_seconds, 4.0), "Mass Brand should recharge each charge in four seconds")
	_expect(is_equal_approx(mass_brand.instability_delta, 5.0), "Mass Brand should generate five Instability")
	_expect(is_equal_approx(mass_brand.resource_cost, 0.0), "Foundation migration should not invent a Corruption cost")

	var null_shard: AbilityDefinition = catalog.null_shard_definition()
	_expect(null_shard.ability_id == &"vb.skill.null_shard", "Null Shard should use its approved stable ID")
	_expect(not null_shard.uses_charges(), "Null Shard should have no charge gate")
	_expect(is_equal_approx(null_shard.cooldown_seconds, 0.0), "Null Shard should have no cooldown")
	_expect(is_equal_approx(null_shard.instability_delta, 4.0), "Null Shard should generate four Instability")

	var closure: AbilityDefinition = catalog.closure_definition()
	_expect(closure.slot_type == &"closure", "Closure should occupy the dedicated class-action channel")
	_expect(is_equal_approx(closure.cooldown_seconds, 0.7), "Closure should preserve its approved base cooldown")


func _test_six_slot_command_contract() -> void:
	var contract = COMMAND_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = contract.debug_snapshot()
	_expect(contract.is_valid_snapshot(snapshot), "The deterministic sandbox loadout should satisfy the command contract")
	_expect((snapshot.get("active_slots", []) as Array).size() == 6, "The command contract should expose six ordered active slots")
	_expect(snapshot.get("closure", &"") == &"vb.action.closure", "Closure should remain a dedicated action")
	_expect(snapshot.get("basic_attack", &"") == &"basic_attack", "The contract should preserve one weapon basic-attack channel")
	_expect(snapshot.get("evade", &"") == &"evade", "The contract should preserve universal evade")
	_expect(snapshot.get("ultimate", &"") == &"vb.ultimate.dead_star", "The contract should expose one ultimate slot")

	var duplicate_slots := (snapshot.get("active_slots", []) as Array).duplicate()
	duplicate_slots[5] = duplicate_slots[0]
	_expect(contract.build_snapshot(duplicate_slots, &"vb.action.closure", &"vb.ultimate.dead_star").is_empty(), "Duplicate active IDs should be rejected")
	_expect(contract.build_snapshot(duplicate_slots.slice(0, 5), &"vb.action.closure", &"vb.ultimate.dead_star").is_empty(), "A loadout without six slots should be rejected")


func _test_compatibility_damage_bridge_and_single_critical_consumption() -> void:
	var bridge = DAMAGE_BRIDGE_SCRIPT.new()
	_expect(bridge.base_damage_for_coefficient(0.75) == 18, "Null Shard 75% should preserve the current eighteen-damage baseline")
	_expect(bridge.base_damage_for_coefficient(0.35) == 8, "Mass Brand 35% should resolve from the same compatibility Weapon Power")

	var projection: PlayableCombatProjection = PROJECTION_SCRIPT.new()
	projection.configure({"power": 4.0, "critical_chance": 0.5})
	var first: Dictionary = bridge.resolve_with_projection(0.75, projection)
	_expect(int(first.get("base_damage", 0)) == 18, "The bridge should apply coefficient before class-tree power")
	_expect(int(first.get("pre_critical_damage", 0)) == 22, "Projected power should apply before the critical multiplier")
	_expect(not bool(first.get("critical", true)) and int(first.get("damage", 0)) == 22, "The first half-meter hit should remain non-critical")

	var second: Dictionary = bridge.resolve_with_projection(0.75, projection)
	_expect(bool(second.get("critical", false)), "The second half-meter hit should consume exactly one deterministic critical")
	_expect(int(second.get("damage", 0)) == 33, "The detailed result should report the resolved critical damage")

	var legacy_damage := projection.resolve_outgoing_damage(18)
	_expect(legacy_damage == 22, "The legacy integer API should delegate once without double-advancing the critical meter")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
