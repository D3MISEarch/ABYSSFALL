extends SceneTree

const CATALOG_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_ability_catalog.gd")
const CONTROLLER_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_controller.gd")

class CarrierFixture:
	extends Node3D
	var alive := true
	var health := 100
	var hit_calls := 0

	func take_damage(amount: int) -> int:
		hit_calls += 1
		var applied := mini(health, maxi(amount, 0))
		health -= applied
		alive = health > 0
		return applied

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_dead_carrier_rejection_is_atomic()
	_test_success_commits_before_cast_event_and_packet_is_immutable()
	_test_damage_and_critical_resolve_once()
	_test_capacity_replacement_publishes_two_clean_rebuilds()
	_test_breach_entry_is_single_and_authoritative()
	if failures.is_empty():
		print("PASS: Voidbringer transactional Mass Brand")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_dead_carrier_rejection_is_atomic() -> void:
	var setup := _setup(5)
	var controller: VoidbringerController = setup.controller
	var session: RuntimeSession = setup.session
	var definition: AbilityDefinition = setup.definition
	var rejected_events := [0]
	session.event_bus.ability_rejected.connect(
		func(_build_id: String, _ability_id: StringName, _reason: StringName) -> void:
			rejected_events[0] += 1
	)
	var dead_enemy := CarrierFixture.new()
	root.add_child(dead_enemy)
	dead_enemy.alive = false

	var result := controller.execute_mass_brand_command(
		definition,
		&"enemy",
		dead_enemy,
		Vector3.ZERO,
		8.0,
		{},
		[definition.ability_id]
	)
	_expect(not bool(result.get("success", true)), "A logically dead enemy should reject Mass Brand")
	_expect(result.get("reason", &"") == &"carrier_invalidated", "Dead carrier rejection should remain stable and explicit")
	_expect(controller.anchors.active_count() == 0, "Rejected dead-carrier casts must create zero Anchors")
	_expect(is_equal_approx(controller.instability.current, 0.0), "Rejected dead-carrier casts must add zero Instability")
	_expect(session.ability_executor.charge_snapshot(setup.character.build_id, definition.ability_id).is_empty(), "Carrier rejection before preflight must create no charge liability")
	_expect(rejected_events[0] == 1, "A rejected dead carrier should emit exactly one rejection event")
	_expect(dead_enemy.hit_calls == 0 and dead_enemy.health == 100, "Rejected dead-carrier casts must deal zero damage")

	dead_enemy.free()
	session.free()


func _test_success_commits_before_cast_event_and_packet_is_immutable() -> void:
	var setup := _setup(5)
	var controller: VoidbringerController = setup.controller
	var session: RuntimeSession = setup.session
	var definition: AbilityDefinition = setup.definition
	var enemy := CarrierFixture.new()
	root.add_child(enemy)
	var cast_events := [0]
	var committed_events := [0]
	var impact_events := [0]
	var foundation_events := [0]
	var state_at_cast: Array[Dictionary] = []
	session.event_bus.ability_cast.connect(
		func(_build_id: String, _ability_id: StringName) -> void:
			cast_events[0] += 1
			state_at_cast.append(controller.snapshot())
	)
	controller.skill_committed.connect(
		func(_commit: VoidbringerSkillCommit) -> void:
			committed_events[0] += 1
	)
	controller.impact_committed.connect(
		func(_impact: VoidbringerImpactResult) -> void:
			impact_events[0] += 1
	)
	controller.foundation_changed.connect(
		func(_snapshot: Dictionary) -> void:
			foundation_events[0] += 1
	)

	var result := controller.execute_mass_brand_command(
		definition,
		&"enemy",
		enemy,
		Vector3(2.0, 0.0, 1.0),
		8.0,
		{
			"source": &"test",
			"attack_origin": Vector3(2.0, 3.0, 1.0),
			"surface_normal": Vector3.UP,
		},
		[definition.ability_id]
	)
	_expect(bool(result.get("success", false)), "A valid Mass Brand command should succeed")
	_expect(controller.anchors.active_count() == 1, "Successful Mass Brand should create exactly one Anchor")
	_expect(is_equal_approx(controller.instability.current, 5.0), "Successful Mass Brand should apply its five Instability once")
	_expect(session.ability_executor.charges_remaining(setup.character.build_id, definition.ability_id) == 1, "Successful Mass Brand should consume exactly one charge")
	_expect(cast_events[0] == 1, "Successful Mass Brand should publish one deferred ability_cast event")
	_expect(committed_events[0] == 1, "Successful Mass Brand should publish one immutable commit packet")
	_expect(impact_events[0] == 1, "Successful enemy Mass Brand should publish one immutable impact result")
	_expect(foundation_events[0] == 1, "Mass Brand transaction should coalesce Anchor and Instability callbacks into one final foundation snapshot")
	_expect(state_at_cast.size() == 1, "The cast listener should observe one committed state")
	if state_at_cast.size() == 1:
		var cast_snapshot: Dictionary = state_at_cast[0]
		_expect((cast_snapshot.get("anchors", []) as Array).size() == 1, "ability_cast must not fire before Anchor placement")
		_expect(is_equal_approx(float((cast_snapshot.get("instability", {}) as Dictionary).get("current", 0.0)), 5.0), "ability_cast must observe committed Instability")

	var impact: Dictionary = result.get("impact", {})
	_expect(int(impact.get("base_damage", 0)) == 8 and int(impact.get("damage", 0)) == 8, "Mass Brand should deliver its approved eight damage at zero power and zero critical chance")
	_expect(enemy.hit_calls == 1 and enemy.health == 92, "Mass Brand enemy contact should call damage exactly once")
	_expect((impact.get("impact_point", Vector3.ZERO) as Vector3).is_equal_approx(Vector3(2.0, 0.0, 1.0)), "Mass Brand impact point should survive into the immutable result")
	_expect((impact.get("travel_direction", Vector3.ZERO) as Vector3).is_equal_approx(Vector3.DOWN), "Mass Brand attack origin should produce the correct impact direction")
	_expect((impact.get("surface_normal", Vector3.ZERO) as Vector3).is_equal_approx(Vector3.UP), "Mass Brand surface normal should survive into the immutable result")

	result["success"] = false
	result["anchor"] = {}
	(result.get("impact", {}) as Dictionary)["damage"] = 999
	_expect(controller.last_skill_commit != null and controller.last_skill_commit.succeeded(), "Mutating a returned snapshot must not mutate the immutable commit packet")
	_expect(not (controller.last_skill_commit.snapshot().get("anchor", {}) as Dictionary).is_empty(), "Immutable commit packet should preserve committed Anchor metadata")
	_expect(controller.last_impact_result != null and controller.last_impact_result.damage() == 8, "Mutating returned impact data must not mutate the authoritative result")

	enemy.free()
	session.free()


func _test_damage_and_critical_resolve_once() -> void:
	var setup := _setup(5)
	var controller: VoidbringerController = setup.controller
	var session: RuntimeSession = setup.session
	var definition: AbilityDefinition = setup.definition
	var projection := PlayableCombatProjection.new()
	projection.configure({"power": 0.0, "critical_chance": 0.5})
	var first_enemy := CarrierFixture.new()
	var second_enemy := CarrierFixture.new()
	root.add_child(first_enemy)
	root.add_child(second_enemy)
	var impact_events := [0]
	controller.impact_committed.connect(
		func(_impact: VoidbringerImpactResult) -> void:
			impact_events[0] += 1
	)

	var first := controller.execute_mass_brand_command(
		definition,
		&"enemy",
		first_enemy,
		Vector3(-1.0, 0.0, 0.0),
		8.0,
		{},
		[definition.ability_id],
		projection
	)
	var second := controller.execute_mass_brand_command(
		definition,
		&"enemy",
		second_enemy,
		Vector3(1.0, 0.0, 0.0),
		8.0,
		{},
		[definition.ability_id],
		projection
	)
	var first_impact: Dictionary = first.get("impact", {})
	var second_impact: Dictionary = second.get("impact", {})
	_expect(not bool(first_impact.get("critical", true)) and int(first_impact.get("damage", 0)) == 8, "First half-meter Mass Brand should resolve one non-critical eight-damage hit")
	_expect(bool(second_impact.get("critical", false)) and int(second_impact.get("damage", 0)) == 12, "Second Mass Brand contact should consume exactly one critical")
	_expect(first_enemy.hit_calls == 1 and second_enemy.hit_calls == 1, "Each Mass Brand command should own exactly one target damage call")
	_expect(impact_events[0] == 2, "Two Mass Brand contacts should publish two and only two impact results")

	first_enemy.free()
	second_enemy.free()
	session.free()


func _test_capacity_replacement_publishes_two_clean_rebuilds() -> void:
	var setup := _setup(1)
	var controller: VoidbringerController = setup.controller
	var session: RuntimeSession = setup.session
	var definition: AbilityDefinition = setup.definition
	controller.execute_mass_brand_command(definition, &"terrain", null, Vector3(-2.0, 0.0, 0.0), 5.0, {}, [definition.ability_id])
	controller.execute_mass_brand_command(definition, &"terrain", null, Vector3(0.0, 0.0, 0.0), 5.0, {}, [definition.ability_id])
	session.tick_runtime(4.0)
	var rebuilds := [0]
	var final_snapshots := [0]
	controller.fold_lines.lines_rebuilt.connect(
		func(_lines: Array[Dictionary]) -> void:
			rebuilds[0] += 1
	)
	controller.foundation_changed.connect(
		func(_snapshot: Dictionary) -> void:
			final_snapshots[0] += 1
	)

	var result := controller.execute_mass_brand_command(
		definition,
		&"terrain",
		null,
		Vector3(2.0, 0.0, 0.0),
		5.0,
		{},
		[definition.ability_id]
	)
	_expect(bool(result.get("success", false)), "A recharged Mass Brand should succeed at capacity")
	_expect(controller.anchors.active_count() == 2, "Capacity replacement should retain exactly two level-one Anchors")
	_expect(controller.fold_lines.line_count() == 1, "Capacity replacement should leave exactly one current Fold Line")
	_expect(rebuilds[0] == 2, "Capacity replacement should publish one removal rebuild and one creation rebuild")
	_expect(final_snapshots[0] == 1, "Two rebuild emissions should still coalesce to one authoritative foundation snapshot")
	var removed_events: Array = result.get("removed_anchor_events", [])
	_expect(removed_events.size() == 1 and (removed_events[0] as Dictionary).get("reason", &"") == &"capacity_replacement", "The committed result should distinguish cast eviction from level downgrade")
	var impact: Dictionary = result.get("impact", {})
	_expect(int(impact.get("damage", -1)) == 0 and int(impact.get("damage_applied", -1)) == 0, "Terrain Mass Brand should produce contact metadata without fake enemy damage")

	session.free()


func _test_breach_entry_is_single_and_authoritative() -> void:
	var setup := _setup(5)
	var controller: VoidbringerController = setup.controller
	var session: RuntimeSession = setup.session
	var definition: AbilityDefinition = setup.definition
	controller.instability.current = 95.0
	var breach_starts := [0]
	var foundation_events := [0]
	controller.instability.breach_started.connect(
		func(_duration: float) -> void:
			breach_starts[0] += 1
	)
	controller.foundation_changed.connect(
		func(_snapshot: Dictionary) -> void:
			foundation_events[0] += 1
	)

	var result := controller.execute_mass_brand_command(
		definition,
		&"terrain",
		null,
		Vector3.ZERO,
		5.0,
		{},
		[definition.ability_id]
	)
	_expect(bool(result.get("success", false)), "Threshold Mass Brand should still commit successfully")
	_expect(bool(result.get("entered_breach", false)), "Committed result should explicitly report Breach entry")
	_expect(is_equal_approx(float(result.get("instability_applied", 0.0)), 5.0), "Threshold cast should report the exact applied Instability")
	_expect(breach_starts[0] == 1, "Threshold cast should emit exactly one authoritative Breach transition")
	_expect(foundation_events[0] == 1, "Threshold cast should coalesce state callbacks into one final foundation snapshot")
	_expect(controller.instability.in_breach, "Threshold cast should leave the authoritative controller in Breach")

	session.free()


func _setup(level: int) -> Dictionary:
	var catalog = CATALOG_SCRIPT.new()
	var definition: AbilityDefinition = catalog.mass_brand_definition()
	var character := RuntimeCharacter.new()
	character.build_id = "mass-brand-transaction-%d" % level
	character.class_id = &"void_warlock"
	character.level = level
	character.unlocked_abilities = [definition.ability_id]
	character.class_resource.configure(&"corruption", 100.0)
	character.class_resource.fill()
	var session := RuntimeSession.new()
	session.character = character
	var controller: VoidbringerController = CONTROLLER_SCRIPT.new()
	_expect(controller.bind_runtime(session, character), "Mass Brand test setup should bind the authoritative runtime")
	return {
		"catalog": catalog,
		"definition": definition,
		"character": character,
		"session": session,
		"controller": controller,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
