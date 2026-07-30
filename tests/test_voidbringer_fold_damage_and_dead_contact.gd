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
	_test_fold_multiplier_scales_total_pre_critical_hit()
	_test_logically_dead_contact_is_ignored()
	if failures.is_empty():
		print("PASS: Voidbringer Fold damage and dead-contact safety")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_fold_multiplier_scales_total_pre_critical_hit() -> void:
	var setup := _setup("fold-total-damage")
	var controller: VoidbringerController = setup.controller
	var definition: AbilityDefinition = setup.definition
	var projection := PlayableCombatProjection.new()
	projection.configure({"power": 4.0, "critical_chance": 0.0})
	controller.place_anchor(&"terrain", null, Vector3(-1.0, 0.0, 0.0), 0.0)
	controller.place_anchor(&"terrain", null, Vector3(1.0, 0.0, 0.0), 0.0)

	var launch := controller.execute_null_shard_command(
		definition,
		Vector3(0.0, 0.0, -2.0),
		Vector3.BACK,
		projection,
		{},
		[definition.ability_id]
	)
	var projectile_id := StringName(str((launch.get("projectile", {}) as Dictionary).get("projectile_id", "")))
	var projectile := controller.get_null_shard(projectile_id)
	projectile.tick(0.16)
	_expect(projectile.crossing_count == 1, "The power-scaling proof should credit exactly one Fold Line")

	var target := DamageTarget.new()
	root.add_child(target)
	var impact := projectile.commit_contact(target, projectile.position, Vector3.FORWARD)
	_expect(int(impact.get("base_damage", 0)) == 18, "Null Shard should preserve its approved eighteen coefficient-derived base damage")
	_expect(int(impact.get("pre_critical_damage", 0)) == 25, "Fold +12 percent should scale the full projected hit: round((18 + 4) * 1.12) = 25")
	_expect(int(impact.get("damage", 0)) == 25, "Non-critical Fold damage should equal the total scaled pre-critical hit")
	_expect(is_equal_approx(float(impact.get("damage_multiplier", 0.0)), 1.12), "Impact packet should preserve the exact one-crossing multiplier")
	_expect(target.health == 75 and target.hit_calls == 1, "The target should receive the total scaled hit exactly once")

	target.free()
	controller.clear()
	setup.session.free()


func _test_logically_dead_contact_is_ignored() -> void:
	var setup := _setup("dead-contact")
	var controller: VoidbringerController = setup.controller
	var definition: AbilityDefinition = setup.definition
	var impact_events := [0]
	controller.impact_committed.connect(
		func(_result: VoidbringerImpactResult) -> void:
			impact_events[0] += 1
	)
	var launch := controller.execute_null_shard_command(
		definition,
		Vector3.ZERO,
		Vector3.BACK,
		null,
		{},
		[definition.ability_id]
	)
	var projectile_id := StringName(str((launch.get("projectile", {}) as Dictionary).get("projectile_id", "")))
	var projectile := controller.get_null_shard(projectile_id)
	var dead_target := DamageTarget.new()
	root.add_child(dead_target)
	dead_target.health = 0
	dead_target.alive = false

	var rejected_contact := projectile.commit_contact(dead_target, Vector3(0.0, 0.0, 1.0), Vector3.FORWARD)
	_expect(rejected_contact.is_empty(), "An instance-valid but logically dead target must not produce an impact packet")
	_expect(projectile.active and not projectile.contact_committed, "Ignoring a dead target should leave the projectile available for a later valid contact")
	_expect(dead_target.hit_calls == 0 and dead_target.health == 0, "A dead target must receive no damage callback")
	_expect(impact_events[0] == 0, "A dead target must produce no false impact presentation event")

	projectile.invalidate(&"teardown")
	dead_target.free()
	controller.clear()
	setup.session.free()


func _setup(build_id: String) -> Dictionary:
	var catalog = CATALOG_SCRIPT.new()
	var definition: AbilityDefinition = catalog.null_shard_definition()
	var character := RuntimeCharacter.new()
	character.build_id = build_id
	character.class_id = &"void_warlock"
	character.level = 5
	character.unlocked_abilities = [definition.ability_id]
	character.class_resource.configure(&"corruption", 100.0)
	character.class_resource.fill()
	var session := RuntimeSession.new()
	session.character = character
	var controller: VoidbringerController = CONTROLLER_SCRIPT.new()
	_expect(controller.bind_runtime(session, character), "Safety-test setup should bind the authoritative runtime")
	return {
		"definition": definition,
		"character": character,
		"session": session,
		"controller": controller,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
