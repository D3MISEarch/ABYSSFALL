extends SceneTree

const CATALOG_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_ability_catalog.gd")
const CONTROLLER_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_controller.gd")

class LethalTarget:
	extends Node3D
	var health := 8
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
	var catalog = CATALOG_SCRIPT.new()
	var definition: AbilityDefinition = catalog.mass_brand_definition()
	var character := RuntimeCharacter.new()
	character.build_id = "lethal-mass-brand-corpse"
	character.class_id = &"void_warlock"
	character.level = 5
	character.unlocked_abilities = [definition.ability_id]
	character.class_resource.configure(&"corruption", 100.0)
	character.class_resource.fill()
	var session := RuntimeSession.new()
	session.character = character
	var controller: VoidbringerController = CONTROLLER_SCRIPT.new()
	_expect(controller.bind_runtime(session, character), "Lethal Mass Brand setup should bind authoritative runtime")
	var target := LethalTarget.new()
	root.add_child(target)
	var created_events: Array[Dictionary] = []
	controller.anchors.anchor_created.connect(
		func(anchor: Dictionary) -> void:
			created_events.append(anchor.duplicate(true))
	)

	var result := controller.execute_mass_brand_command(
		definition,
		&"enemy",
		target,
		Vector3.ZERO,
		8.0,
		{},
		[definition.ability_id],
		null
	)
	var committed_anchor: Dictionary = result.get("anchor", {})
	var foundation: Dictionary = result.get("foundation_snapshot", {})
	var active_anchors: Array = foundation.get("anchors", [])
	var impact: Dictionary = result.get("impact", {})

	_expect(bool(result.get("success", false)), "Lethal enemy Mass Brand should remain a successful committed cast")
	_expect(bool(impact.get("fatal", false)), "Eight damage against an eight-health enemy should report a fatal impact")
	_expect(target.hit_calls == 1 and target.health == 0 and not target.alive, "Lethal enemy should receive one damage call and become logically dead")
	_expect(result.get("carrier_type", &"") == &"corpse", "Final skill packet should publish the Anchor as an explicit corpse carrier")
	_expect(committed_anchor.get("carrier_type", &"") == &"corpse", "Committed Anchor snapshot should never expose a dead enemy carrier")
	_expect(is_equal_approx(float(committed_anchor.get("remaining_seconds", 0.0)), 8.0), "Lethal Mass Brand corpse Anchor should receive the approved eight-second duration")
	_expect(active_anchors.size() == 1, "Final foundation snapshot should contain one Anchor")
	if active_anchors.size() == 1:
		var final_anchor: Dictionary = active_anchors[0]
		_expect(final_anchor.get("carrier_type", &"") == &"corpse", "Final foundation snapshot should contain a corpse Anchor, not an enemy Anchor")
		_expect(is_equal_approx(float(final_anchor.get("remaining_seconds", 0.0)), 8.0), "Final foundation snapshot should preserve corpse duration")
	_expect(created_events.size() == 1, "Lethal Mass Brand should publish one and only one Anchor creation event")
	if created_events.size() == 1:
		_expect(created_events[0].get("carrier_type", &"") == &"corpse", "Anchor-created listeners should only observe the final corpse classification")
	_expect(controller.anchors.active_count() == 1, "Corpse reclassification should retain the committed Anchor")

	controller.tick(0.1)
	var after_tick := controller.anchors.active_anchors()
	_expect(after_tick.size() == 1 and (after_tick[0] as Dictionary).get("carrier_type", &"") == &"corpse", "The next tick must not delete or briefly reclassify the corpse Anchor")

	controller.clear()
	target.free()
	session.free()
	if failures.is_empty():
		print("PASS: Voidbringer lethal Mass Brand corpse Anchor")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
