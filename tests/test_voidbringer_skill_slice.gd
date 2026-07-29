extends SceneTree

const CATALOG_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_ability_catalog.gd")
const CONTROLLER_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_controller.gd")

class DamageTarget:
	extends Node3D
	var health := 100
	var alive := true
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
	_test_rejected_launch_vs_committed_miss()
	_test_zero_and_one_crossing_with_jitter_immunity()
	_test_two_and_three_crossing_accumulation_and_cap()
	_test_contact_and_critical_resolve_once()
	_test_teardown_clears_projectile_ownership()
	if failures.is_empty():
		print("PASS: Voidbringer Mass Brand and Null Shard skill slice")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_rejected_launch_vs_committed_miss() -> void:
	var setup := _setup()
	var controller: VoidbringerController = setup.controller
	var session: RuntimeSession = setup.session
	var definition: AbilityDefinition = setup.null_shard

	var rejected := controller.execute_null_shard_command(
		definition,
		Vector3.ZERO,
		Vector3.ZERO,
		null,
		{},
		[definition.ability_id]
	)
	_expect(not bool(rejected.get("success", true)), "Zero-direction Null Shard input should reject")
	_expect(rejected.get("reason", &"") == &"invalid_direction", "Rejected aim should expose a stable invalid_direction reason")
	_expect(controller.active_null_shards.is_empty(), "Rejected Null Shard input must create no projectile")
	_expect(is_equal_approx(controller.instability.current, 0.0), "Rejected Null Shard input must add zero Instability")
	_expect(session.ability_executor.charge_snapshot(setup.character.build_id, definition.ability_id).is_empty(), "Rejected aim before preflight should create no runtime liability")

	var spawn_events := [0]
	var cast_events := [0]
	var foundation_events := [0]
	var spawn_observations: Array[Dictionary] = []
	var controller_ref := weakref(controller)
	controller.null_shard_spawned.connect(
		func(projectile: VoidbringerNullShardProjectile) -> void:
			var observed_controller := controller_ref.get_ref() as VoidbringerController
			if observed_controller == null:
				return
			spawn_events[0] += 1
			spawn_observations.append({
				"active_count": observed_controller.active_null_shards.size(),
				"instability": observed_controller.instability.current,
				"projectile_active": projectile.active,
			})
	)
	session.event_bus.ability_cast.connect(
		func(_build_id: String, _ability_id: StringName) -> void:
			cast_events[0] += 1
	)
	controller.foundation_changed.connect(
		func(_snapshot: Dictionary) -> void:
			foundation_events[0] += 1
	)

	var committed := controller.execute_null_shard_command(
		definition,
		Vector3(0.0, 0.0, -2.0),
		Vector3.BACK,
		null,
		{"test": &"committed_miss"},
		[definition.ability_id]
	)
	_expect(bool(committed.get("success", false)), "Valid Null Shard input should commit")
	_expect(is_equal_approx(float(committed.get("instability_applied", 0.0)), 4.0), "Committed Null Shard should apply four Instability exactly once")
	_expect(controller.active_null_shards.size() == 1, "Committed Null Shard should create exactly one projectile owner")
	_expect(spawn_events[0] == 1 and cast_events[0] == 1, "Committed Null Shard should emit one spawn and one cast event")
	_expect(foundation_events[0] == 1, "Null Shard launch should coalesce to one authoritative foundation snapshot")
	if spawn_observations.size() == 1:
		_expect(int(spawn_observations[0].get("active_count", 0)) == 1, "Spawn listeners must observe the registered projectile")
		_expect(is_equal_approx(float(spawn_observations[0].get("instability", 0.0)), 4.0), "Spawn listeners must observe committed Instability")
		_expect(bool(spawn_observations[0].get("projectile_active", false)), "Spawn listeners must observe an active projectile")

	var committed_projectile: Dictionary = committed.get("projectile", {})
	var projectile_id := StringName(str(committed_projectile.get("projectile_id", "")))
	committed_projectile["active"] = false
	var projectile := controller.get_null_shard(projectile_id)
	_expect(projectile != null and projectile.active, "Mutating a returned launch snapshot must not mutate projectile ownership")
	controller.tick(2.0)
	_expect(controller.active_null_shards.is_empty(), "A committed Null Shard miss should expire and clean up")
	_expect(is_equal_approx(controller.instability.current, 4.0), "A committed miss should retain its committed Instability liability")

	session.free()


func _test_zero_and_one_crossing_with_jitter_immunity() -> void:
	var zero_setup := _setup()
	var zero_controller: VoidbringerController = zero_setup.controller
	var zero_definition: AbilityDefinition = zero_setup.null_shard
	var zero_launch := zero_controller.execute_null_shard_command(
		zero_definition,
		Vector3(0.0, 0.0, -2.0),
		Vector3.BACK,
		null,
		{},
		[zero_definition.ability_id]
	)
	var zero_projectile := zero_controller.get_null_shard(StringName(str((zero_launch.get("projectile", {}) as Dictionary).get("projectile_id", ""))))
	zero_projectile.tick(0.05)
	_expect(zero_projectile.crossing_count == 0, "A direct Null Shard with no Fold Lines should receive zero bonuses")
	_expect(is_equal_approx(zero_projectile.speed, 22.0), "A zero-crossing Null Shard should preserve base speed")
	_expect(is_equal_approx(zero_projectile.damage_multiplier, 1.0), "A zero-crossing Null Shard should preserve base damage")
	zero_setup.session.free()

	var setup := _setup()
	var controller: VoidbringerController = setup.controller
	var definition: AbilityDefinition = setup.null_shard
	var anchor_a := controller.place_anchor(&"terrain", null, Vector3(-1.0, 0.0, 0.0), 10.0)
	var anchor_b := controller.place_anchor(&"terrain", null, Vector3(1.0, 0.0, 0.0), 20.0)
	var launch := controller.execute_null_shard_command(
		definition,
		Vector3(0.0, 0.0, -2.0),
		Vector3.BACK,
		null,
		{},
		[definition.ability_id]
	)
	var projectile := controller.get_null_shard(StringName(str((launch.get("projectile", {}) as Dictionary).get("projectile_id", ""))))
	projectile.tick(0.16)
	_expect(projectile.crossing_count == 1, "Crossing one Fold Line should credit exactly one bonus")
	_expect(is_equal_approx(projectile.speed, 27.5), "One Fold crossing should multiply speed by 1.25")
	_expect(is_equal_approx(projectile.damage_multiplier, 1.12), "One Fold crossing should multiply damage by 1.12")
	_expect(is_equal_approx(float(controller.anchors.get_anchor(anchor_a.get("anchor_id", &"")).get("mass", 0.0)), 12.0), "One crossing should add two Mass to endpoint A")
	_expect(is_equal_approx(float(controller.anchors.get_anchor(anchor_b.get("anchor_id", &"")).get("mass", 0.0)), 22.0), "One crossing should add two Mass to endpoint B")

	projectile.direction = Vector3.FORWARD
	projectile.tick(0.16)
	_expect(projectile.crossing_count == 1, "Boundary recrossing and oscillation must not credit the same line twice")
	_expect(is_equal_approx(float(controller.anchors.get_anchor(anchor_a.get("anchor_id", &"")).get("mass", 0.0)), 12.0), "Duplicate crossing queries must not add endpoint Mass twice")

	var target := DamageTarget.new()
	root.add_child(target)
	var impact := projectile.commit_contact(target, projectile.position, Vector3.FORWARD)
	_expect(int(impact.get("damage", 0)) == 20, "One Fold crossing should modify base Null Shard damage before one-pass resolution")
	target.free()
	setup.session.free()


func _test_two_and_three_crossing_accumulation_and_cap() -> void:
	var two_setup := _setup()
	var two_controller: VoidbringerController = two_setup.controller
	var two_definition: AbilityDefinition = two_setup.null_shard
	two_controller.place_anchor(&"terrain", null, Vector3(-2.0, 0.0, 0.0), 0.0)
	two_controller.place_anchor(&"terrain", null, Vector3(2.0, 0.0, 1.0), 0.0)
	two_controller.place_anchor(&"terrain", null, Vector3(-2.0, 0.0, 2.0), 0.0)
	var two_launch := two_controller.execute_null_shard_command(
		two_definition,
		Vector3(0.0, 0.0, -1.0),
		Vector3.BACK,
		null,
		{},
		[two_definition.ability_id]
	)
	var two_projectile := two_controller.get_null_shard(StringName(str((two_launch.get("projectile", {}) as Dictionary).get("projectile_id", ""))))
	two_projectile.tick(0.20)
	_expect(two_projectile.crossing_count == 2, "A path through two separate Fold Lines should receive two bonuses")
	_expect(is_equal_approx(two_projectile.speed, 22.0 * 1.25 * 1.25), "Two crossings should accumulate speed multiplicatively in crossing order")
	_expect(is_equal_approx(two_projectile.damage_multiplier, 1.12 * 1.12), "Two crossings should accumulate damage multiplicatively")
	two_setup.session.free()

	var setup := _setup()
	var controller: VoidbringerController = setup.controller
	var definition: AbilityDefinition = setup.null_shard
	controller.place_anchor(&"terrain", null, Vector3(-2.0, 0.0, 0.0), 0.0)
	controller.place_anchor(&"terrain", null, Vector3(2.0, 0.0, 0.0), 0.0)
	controller.place_anchor(&"terrain", null, Vector3(0.0, 0.0, 2.0), 0.0)
	var launch := controller.execute_null_shard_command(
		definition,
		Vector3(0.0, 0.0, -1.0),
		Vector3.BACK,
		null,
		{},
		[definition.ability_id]
	)
	var projectile := controller.get_null_shard(StringName(str((launch.get("projectile", {}) as Dictionary).get("projectile_id", ""))))
	projectile.tick(0.20)
	_expect(projectile.crossing_count == 3, "A path through a Fold vertex and opposite edge should receive the three-bonus maximum")
	_expect((projectile.snapshot().get("credited_fold_line_ids", []) as Array).size() == 3, "Projectile should own three credited stable Fold Line IDs")
	_expect(is_equal_approx(projectile.speed, 22.0 * pow(1.25, 3.0)), "Three crossings should apply exactly three speed bonuses")
	_expect(is_equal_approx(projectile.damage_multiplier, pow(1.12, 3.0)), "Three crossings should apply exactly three damage bonuses")

	controller.anchors.clear(&"capacity_replacement")
	controller.place_anchor(&"terrain", null, Vector3(-2.0, 0.0, 0.0), 0.0)
	controller.place_anchor(&"terrain", null, Vector3(2.0, 0.0, 0.0), 0.0)
	controller.place_anchor(&"terrain", null, Vector3(0.0, 0.0, 2.0), 0.0)
	projectile.position = Vector3(0.0, 0.0, 3.0)
	projectile.previous_position = projectile.position
	projectile.direction = Vector3.FORWARD
	projectile.tick(0.20)
	_expect(projectile.crossing_count == 3, "A rebuilt geometric line with new IDs must never exceed the three-crossing cap")
	for anchor: Dictionary in controller.anchors.active_anchors():
		_expect(is_equal_approx(float(anchor.get("mass", -1.0)), 0.0), "A capped projectile must not load Mass onto rebuilt endpoint Anchors")

	setup.session.free()


func _test_contact_and_critical_resolve_once() -> void:
	var setup := _setup()
	var controller: VoidbringerController = setup.controller
	var definition: AbilityDefinition = setup.null_shard
	var projection := PlayableCombatProjection.new()
	projection.configure({"power": 0.0, "critical_chance": 0.5})
	var impact_events := [0]
	controller.impact_committed.connect(
		func(_result: VoidbringerImpactResult) -> void:
			impact_events[0] += 1
	)

	var first_launch := controller.execute_null_shard_command(
		definition,
		Vector3.ZERO,
		Vector3.BACK,
		projection,
		{},
		[definition.ability_id]
	)
	var first_projectile := controller.get_null_shard(StringName(str((first_launch.get("projectile", {}) as Dictionary).get("projectile_id", ""))))
	var first_target := DamageTarget.new()
	root.add_child(first_target)
	var first_impact := first_projectile.commit_contact(first_target, Vector3(0.0, 0.0, 1.0), Vector3.FORWARD)
	var duplicate_impact := first_projectile.commit_contact(first_target, Vector3(0.0, 0.0, 1.0), Vector3.FORWARD)
	_expect(int(first_impact.get("damage", 0)) == 18 and not bool(first_impact.get("critical", true)), "First half-meter contact should resolve the approved eighteen non-critical damage")
	_expect(duplicate_impact.is_empty(), "Repeated collision callbacks must not produce a second impact result")
	_expect(first_target.hit_calls == 1 and first_target.health == 82, "One projectile contact must call target damage exactly once")
	_expect(impact_events[0] == 1, "One projectile contact must publish exactly one immutable impact result")
	first_impact["damage"] = 999
	_expect(first_projectile.impact_result.damage() == 18, "Mutating a returned impact snapshot must not mutate the immutable result")

	var second_launch := controller.execute_null_shard_command(
		definition,
		Vector3.ZERO,
		Vector3.BACK,
		projection,
		{},
		[definition.ability_id]
	)
	var second_projectile := controller.get_null_shard(StringName(str((second_launch.get("projectile", {}) as Dictionary).get("projectile_id", ""))))
	var second_target := DamageTarget.new()
	root.add_child(second_target)
	var second_impact := second_projectile.commit_contact(second_target, Vector3(0.0, 0.0, 1.0), Vector3.FORWARD)
	_expect(bool(second_impact.get("critical", false)) and int(second_impact.get("damage", 0)) == 27, "The second real contact should consume exactly one deterministic critical")
	_expect(impact_events[0] == 2, "Two distinct projectiles should publish two and only two impact results")

	first_target.free()
	second_target.free()
	setup.session.free()


func _test_teardown_clears_projectile_ownership() -> void:
	var setup := _setup()
	var controller: VoidbringerController = setup.controller
	var definition: AbilityDefinition = setup.null_shard
	var launch := controller.execute_null_shard_command(
		definition,
		Vector3.ZERO,
		Vector3.BACK,
		null,
		{},
		[definition.ability_id]
	)
	var projectile := controller.get_null_shard(StringName(str((launch.get("projectile", {}) as Dictionary).get("projectile_id", ""))))
	controller.clear()
	_expect(controller.active_null_shards.is_empty(), "Controller teardown should clear all Null Shard ownership")
	_expect(projectile != null and not projectile.active and projectile.end_reason == &"teardown", "Teardown should deterministically invalidate existing projectile references")
	_expect((controller.snapshot().get("null_shards", []) as Array).is_empty(), "Foundation snapshot should expose no stale projectile after teardown")
	setup.session.free()


func _setup() -> Dictionary:
	var catalog = CATALOG_SCRIPT.new()
	var mass_brand: AbilityDefinition = catalog.mass_brand_definition()
	var null_shard: AbilityDefinition = catalog.null_shard_definition()
	var character := RuntimeCharacter.new()
	character.build_id = "voidbringer-skill-slice"
	character.class_id = &"void_warlock"
	character.level = 5
	character.unlocked_abilities = [mass_brand.ability_id, null_shard.ability_id]
	character.class_resource.configure(&"corruption", 100.0)
	character.class_resource.fill()
	var session := RuntimeSession.new()
	session.character = character
	var controller: VoidbringerController = CONTROLLER_SCRIPT.new()
	_expect(controller.bind_runtime(session, character), "Skill-slice setup should bind the authoritative runtime")
	return {
		"catalog": catalog,
		"mass_brand": mass_brand,
		"null_shard": null_shard,
		"character": character,
		"session": session,
		"controller": controller,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
