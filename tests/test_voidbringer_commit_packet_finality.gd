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
	var setup := _setup()
	var controller: VoidbringerController = setup.controller
	var session: RuntimeSession = setup.session
	var mass_brand: AbilityDefinition = setup.mass_brand
	var null_shard: AbilityDefinition = setup.null_shard
	var equipped: Array[StringName] = [mass_brand.ability_id, null_shard.ability_id]

	var first := controller.execute_mass_brand_command(
		mass_brand,
		&"terrain",
		null,
		Vector3(-2.0, 0.0, 0.0),
		5.0,
		{},
		equipped
	)
	_expect(bool(first.get("success", false)), "First Mass Brand setup cast should succeed")

	var foundation_events := [0]
	var line_rebuilds := [0]
	var anchor_event_saw_final := [false]
	var cast_event_saw_final := [false]
	controller.foundation_changed.connect(
		func(_snapshot: Dictionary) -> void:
			foundation_events[0] += 1
	)
	controller.fold_lines.lines_rebuilt.connect(
		func(_lines: Array[Dictionary]) -> void:
			line_rebuilds[0] += 1
	)
	controller.anchors.anchor_created.connect(
		func(_anchor: Dictionary) -> void:
			var commit := controller.last_skill_commit
			if commit == null:
				return
			var committed_snapshot: Dictionary = commit.snapshot().get("foundation_snapshot", {})
			anchor_event_saw_final[0] = (
				(committed_snapshot.get("anchors", []) as Array).size() == 2
				and (committed_snapshot.get("fold_lines", []) as Array).size() == 1
			)
	)
	session.event_bus.ability_cast.connect(
		func(_build_id: String, ability_id: StringName) -> void:
			if ability_id != mass_brand.ability_id or controller.last_skill_commit == null:
				return
			var committed_snapshot: Dictionary = controller.last_skill_commit.snapshot().get("foundation_snapshot", {})
			cast_event_saw_final[0] = (
				(committed_snapshot.get("anchors", []) as Array).size() == 2
				and (committed_snapshot.get("fold_lines", []) as Array).size() == 1
			)
	)

	var second := controller.execute_mass_brand_command(
		mass_brand,
		&"corpse",
		DamageTarget.new(),
		Vector3(2.0, 0.0, 0.0),
		20.0,
		{},
		equipped
	)
	var second_snapshot: Dictionary = second.get("foundation_snapshot", {})
	_expect(bool(second.get("success", false)), "Second Mass Brand setup cast should succeed")
	_expect((second_snapshot.get("anchors", []) as Array).size() == 2, "Mass Brand commit packet should contain both committed Anchors")
	_expect((second_snapshot.get("fold_lines", []) as Array).size() == 1, "Mass Brand commit packet should contain the post-rebuild Fold Line")
	_expect(is_equal_approx(float((second_snapshot.get("instability", {}) as Dictionary).get("current", 0.0)), 10.0), "Mass Brand commit packet should contain final Instability")
	_expect(foundation_events[0] == 1, "Second Mass Brand should publish exactly one authoritative foundation snapshot")
	_expect(line_rebuilds[0] == 1, "Normal Mass Brand placement should publish one Fold rebuild")
	_expect(anchor_event_saw_final[0], "Anchor-created listeners should observe an already-frozen final commit packet")
	_expect(cast_event_saw_final[0], "Ability-cast listeners should observe an already-frozen final commit packet")

	var null_result := controller.execute_null_shard_command(
		null_shard,
		Vector3(0.0, 0.0, -2.0),
		Vector3.BACK,
		null,
		{},
		equipped
	)
	var null_snapshot: Dictionary = null_result.get("foundation_snapshot", {})
	var projectile_snapshot: Dictionary = null_result.get("projectile", {})
	_expect(bool(null_result.get("success", false)), "Null Shard launch should succeed")
	_expect((null_snapshot.get("null_shards", []) as Array).size() == 1, "Null Shard commit packet should contain the registered projectile")
	_expect(is_equal_approx(float((null_snapshot.get("instability", {}) as Dictionary).get("current", 0.0)), 14.0), "Null Shard commit packet should contain final launch Instability")
	_expect(is_equal_approx(float(projectile_snapshot.get("instability_applied", 0.0)), 4.0), "Projectile snapshot should carry the committed four Instability")
	_expect(not bool(projectile_snapshot.get("entered_breach", true)), "Non-threshold projectile should report no Breach entry")
	_expect(not bool(projectile_snapshot.get("in_breach_at_launch", true)), "Non-threshold projectile should report contained launch state")
	_expect(is_equal_approx(float(projectile_snapshot.get("anchor_influence_multiplier_at_launch", 0.0)), 1.0), "Contained projectile should carry baseline Anchor influence metadata")

	var projectile_id := StringName(str(projectile_snapshot.get("projectile_id", "")))
	var projectile := controller.get_null_shard(projectile_id)
	var target := DamageTarget.new()
	root.add_child(target)
	var impact := projectile.commit_contact(target, Vector3(0.0, 0.0, 1.0), Vector3.FORWARD)
	_expect(is_equal_approx(float(impact.get("instability_applied", 0.0)), 4.0), "Immutable Null Shard impact should retain launch Instability metadata")
	_expect(not bool(impact.get("entered_breach", true)), "Immutable Null Shard impact should retain launch Breach-transition metadata")
	_expect(not bool(impact.get("in_breach_at_launch", true)), "Immutable Null Shard impact should retain contained launch state")
	_expect(is_equal_approx(float(impact.get("anchor_influence_multiplier_at_launch", 0.0)), 1.0), "Immutable Null Shard impact should retain launch Anchor influence metadata")

	target.free()
	controller.clear()
	session.free()
	if failures.is_empty():
		print("PASS: Voidbringer authoritative commit packet finality")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _setup() -> Dictionary:
	var catalog = CATALOG_SCRIPT.new()
	var mass_brand: AbilityDefinition = catalog.mass_brand_definition()
	var null_shard: AbilityDefinition = catalog.null_shard_definition()
	var character := RuntimeCharacter.new()
	character.build_id = "voidbringer-commit-finality"
	character.class_id = &"void_warlock"
	character.level = 5
	character.unlocked_abilities = [mass_brand.ability_id, null_shard.ability_id]
	character.class_resource.configure(&"corruption", 100.0)
	character.class_resource.fill()
	var session := RuntimeSession.new()
	session.character = character
	var controller: VoidbringerController = CONTROLLER_SCRIPT.new()
	_expect(controller.bind_runtime(session, character), "Commit-finality setup should bind authoritative runtime")
	return {
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
