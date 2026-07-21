extends SceneTree

var failures: Array[String] = []
var cast_events: Array[Dictionary] = []
var rejection_events: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var build := BuildData.create_new(ClassIds.PENITENT, "Ability Tester")
	build.skills["unlocked_abilities"] = ["ashen_sigil"]
	var character := RuntimeCharacter.new()
	character.configure_from_build(build)
	character.class_resource.fill()

	var session := RuntimeSession.new()
	root.add_child(session)
	session.event_bus.ability_cast.connect(_on_ability_cast)
	session.event_bus.ability_rejected.connect(_on_ability_rejected)
	session.bind_character(character)

	var definition := AbilityDefinition.new(&"ashen_sigil", &"fervor", 25.0, 2.0)
	var first: Dictionary = session.execute_ability(definition)
	_expect(bool(first.get("success", false)), "Unlocked ability should execute")
	_expect(first.get("reason") == AbilityExecutor.REASON_OK, "Successful execution should return ok")
	_expect(is_equal_approx(character.class_resource.current, 75.0), "Successful execution should spend resource once")
	_expect(cast_events.size() == 1, "Successful execution should emit one cast event")
	_expect(cast_events[0].get("build_id") == character.build_id, "Cast event should carry the active build ID")
	_expect(cast_events[0].get("ability_id") == &"ashen_sigil", "Cast event should carry the ability ID")

	var cooldown: Dictionary = session.execute_ability(definition)
	_expect(not bool(cooldown.get("success", true)), "Ability should reject while cooling down")
	_expect(cooldown.get("reason") == AbilityExecutor.REASON_COOLDOWN, "Cooldown rejection should be explicit")
	_expect(is_equal_approx(character.class_resource.current, 75.0), "Cooldown rejection must not spend resource")

	session.tick_runtime(2.0)
	character.class_resource.current = 10.0
	var insufficient: Dictionary = session.execute_ability(definition)
	_expect(not bool(insufficient.get("success", true)), "Ability should reject insufficient resource")
	_expect(insufficient.get("reason") == AbilityExecutor.REASON_INSUFFICIENT_RESOURCE, "Resource rejection should be explicit")
	_expect(is_equal_approx(character.class_resource.current, 10.0), "Resource rejection must not change the pool")

	var locked_definition := AbilityDefinition.new(&"brand_of_ruin", &"fervor", 0.0, 0.0)
	var locked: Dictionary = session.execute_ability(locked_definition)
	_expect(locked.get("reason") == AbilityExecutor.REASON_LOCKED, "Locked abilities should not execute")

	var wrong_resource := AbilityDefinition.new(&"ashen_sigil", &"corruption", 0.0, 0.0)
	var mismatch: Dictionary = session.execute_ability(wrong_resource)
	_expect(mismatch.get("reason") == AbilityExecutor.REASON_RESOURCE_MISMATCH, "Abilities should require the matching class resource")
	_expect(rejection_events.size() == 4, "Every rejected execution should emit exactly one rejection event")

	_test_cooldown_key_isolation()

	if failures.is_empty():
		print("PASS: Stage 3 ability execution foundation")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_cooldown_key_isolation() -> void:
	var executor := AbilityExecutor.new()
	var shared_definition := AbilityDefinition.new(&"ashen_sigil", &"fervor", 10.0, 5.0)

	var build_a := BuildData.create_new(ClassIds.PENITENT, "Cooldown Build A")
	build_a.skills["unlocked_abilities"] = ["ashen_sigil"]
	var character_a := RuntimeCharacter.new()
	character_a.configure_from_build(build_a)
	character_a.class_resource.fill()

	var build_b := BuildData.create_new(ClassIds.PENITENT, "Cooldown Build B")
	build_b.skills["unlocked_abilities"] = ["ashen_sigil"]
	var character_b := RuntimeCharacter.new()
	character_b.configure_from_build(build_b)
	character_b.class_resource.fill()

	var build_a_cast: Dictionary = executor.execute(character_a, shared_definition)
	var build_b_cast: Dictionary = executor.execute(character_b, shared_definition)
	_expect(bool(build_a_cast.get("success", false)), "First build should cast the shared ability")
	_expect(bool(build_b_cast.get("success", false)), "One build's cooldown must not block another build")
	_expect(executor.cooldown_remaining(character_a.build_id, &"ashen_sigil") > 0.0, "First build should retain its own cooldown")
	_expect(executor.cooldown_remaining(character_b.build_id, &"ashen_sigil") > 0.0, "Second build should retain its own cooldown")

	var multi_build := BuildData.create_new(ClassIds.PENITENT, "Cooldown Ability Pair")
	multi_build.skills["unlocked_abilities"] = ["ashen_sigil", "brand_of_ruin"]
	var multi_character := RuntimeCharacter.new()
	multi_character.configure_from_build(multi_build)
	multi_character.class_resource.fill()
	var first_definition := AbilityDefinition.new(&"ashen_sigil", &"fervor", 10.0, 5.0)
	var second_definition := AbilityDefinition.new(&"brand_of_ruin", &"fervor", 10.0, 5.0)

	var first_ability_cast: Dictionary = executor.execute(multi_character, first_definition)
	var second_ability_cast: Dictionary = executor.execute(multi_character, second_definition)
	_expect(bool(first_ability_cast.get("success", false)), "First ability should begin its cooldown")
	_expect(bool(second_ability_cast.get("success", false)), "One ability's cooldown must not block another ability on the same build")
	_expect(executor.cooldown_remaining(multi_character.build_id, &"ashen_sigil") > 0.0, "First ability should retain its own cooldown")
	_expect(executor.cooldown_remaining(multi_character.build_id, &"brand_of_ruin") > 0.0, "Second ability should retain its own cooldown")


func _on_ability_cast(build_id: String, ability_id: StringName) -> void:
	cast_events.append({"build_id": build_id, "ability_id": ability_id})


func _on_ability_rejected(build_id: String, ability_id: StringName, reason: StringName) -> void:
	rejection_events.append({"build_id": build_id, "ability_id": ability_id, "reason": reason})


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
