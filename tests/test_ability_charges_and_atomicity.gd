extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_cooldown_only_abilities_remain_compatible()
	_test_multi_charge_recharge_is_deterministic()
	_test_rejections_do_not_spend_or_create_liability()
	if failures.is_empty():
		print("PASS: Voidbringer ability charges and atomicity")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_cooldown_only_abilities_remain_compatible() -> void:
	var character := _character_with_ability(&"legacy.cast", 100.0)
	var definition := AbilityDefinition.new(&"legacy.cast", &"corruption", 10.0, 1.5)
	var executor := AbilityExecutor.new()

	var first := executor.execute(character, definition)
	_expect(bool(first.get("success", false)), "Cooldown-only ability should still execute")
	_expect(is_equal_approx(character.class_resource.current, 90.0), "Successful cooldown-only cast should spend once")
	_expect(not bool(first.get("uses_charges", true)), "Legacy ability should remain non-charge based")

	var blocked := executor.execute(character, definition)
	_expect(blocked.get("reason") == AbilityExecutor.REASON_COOLDOWN, "Cooldown should reject a repeated cast")
	_expect(is_equal_approx(character.class_resource.current, 90.0), "Cooldown rejection must not spend resource")

	executor.tick(1.5)
	var after_tick := executor.execute(character, definition)
	_expect(bool(after_tick.get("success", false)), "Cooldown-only ability should recover after its timer")
	_expect(is_equal_approx(character.class_resource.current, 80.0), "Recovered cooldown cast should spend exactly once")


func _test_multi_charge_recharge_is_deterministic() -> void:
	var ability_id: StringName = &"vb.skill.mass_brand"
	var character := _character_with_ability(ability_id, 100.0)
	var definition := AbilityDefinition.new(
		ability_id,
		&"corruption",
		5.0,
		0.0,
		&"active",
		2,
		3.0,
		12.0,
		[&"spatial", &"anchor"]
	)
	var executor := AbilityExecutor.new()

	var first := executor.execute(character, definition, [ability_id])
	var second := executor.execute(character, definition, [ability_id])
	_expect(bool(first.get("success", false)) and bool(second.get("success", false)), "Both initial Mass Brand charges should execute")
	_expect(executor.charges_remaining(character.build_id, ability_id) == 0, "Two casts should exhaust two charges")
	_expect(is_equal_approx(character.class_resource.current, 90.0), "Two charged casts should spend resource exactly twice")

	var exhausted := executor.execute(character, definition, [ability_id])
	_expect(exhausted.get("reason") == AbilityExecutor.REASON_NO_CHARGES, "Exhausted charged ability should report no_charges")
	_expect(is_equal_approx(character.class_resource.current, 90.0), "No-charge rejection must not spend resource")

	executor.tick(2.99)
	_expect(executor.charges_remaining(character.build_id, ability_id) == 0, "A charge must not return before the full recharge duration")
	executor.tick(0.02)
	_expect(executor.charges_remaining(character.build_id, ability_id) == 1, "Exactly one charge should return after the first recharge duration")
	var snapshot := executor.charge_snapshot(character.build_id, ability_id)
	_expect(int(snapshot.get("queued_recharges", 0)) == 1, "The second spent charge should remain queued")
	_expect(float(snapshot.get("recharge_remaining", 0.0)) > 2.9, "Sequential recharge should begin the next full timer")


func _test_rejections_do_not_spend_or_create_liability() -> void:
	var ability_id: StringName = &"vb.skill.null_shard"
	var character := _character_with_ability(ability_id, 4.0)
	var definition := AbilityDefinition.new(
		ability_id,
		&"corruption",
		5.0,
		0.0,
		&"active",
		1,
		2.0,
		8.0,
		[&"spatial", &"projectile"]
	)
	var executor := AbilityExecutor.new()

	var not_equipped := executor.execute(character, definition, [&"vb.skill.mass_brand"])
	_expect(not_equipped.get("reason") == AbilityExecutor.REASON_NOT_EQUIPPED, "Supplied loadout should reject an unequipped skill")
	_expect(is_equal_approx(character.class_resource.current, 4.0), "Unequipped rejection must not spend resource")
	_expect(executor.charge_snapshot(character.build_id, ability_id).is_empty(), "Validation rejection should not create runtime liability")

	var insufficient := executor.execute(character, definition, [ability_id])
	_expect(insufficient.get("reason") == AbilityExecutor.REASON_INSUFFICIENT_RESOURCE, "Insufficient resource should remain explicit")
	_expect(is_equal_approx(character.class_resource.current, 4.0), "Insufficient-resource rejection must be atomic")
	var snapshot := executor.charge_snapshot(character.build_id, ability_id)
	_expect(int(snapshot.get("current", 0)) == 1, "Insufficient-resource rejection must preserve the available charge")
	_expect(int(snapshot.get("queued_recharges", 0)) == 0, "Insufficient-resource rejection must not start recharge")


func _character_with_ability(ability_id: StringName, resource_amount: float) -> RuntimeCharacter:
	var character := RuntimeCharacter.new()
	character.build_id = "ability-charge-test"
	character.class_id = &"void_warlock"
	character.unlocked_abilities = [ability_id]
	character.class_resource.configure(&"corruption", 100.0)
	character.class_resource.current = resource_amount
	return character


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
