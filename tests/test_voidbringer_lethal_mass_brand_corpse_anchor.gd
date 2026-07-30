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
	target.position = Vector3(2.0, 0.0, -3.0)
	root.add_child(target)
	var created_events: Array[Dictionary] = []
	var removed_events: Array[Dictionary] = []
	controller.anchors.anchor_created.connect(
		func(anchor: Dictionary) -> void:
			created_events.append(anchor.duplicate(true))
	)
	controller.anchors.anchor_removed.connect(
		func(anchor_id: StringName, reason: StringName) -> void:
			removed_events.append({"anchor_id": anchor_id, "reason": reason})
	)

	var result := controller.execute_mass_brand_command(
		definition,
		&"enemy",
		target,
		target.global_position,
		8.0,
		{},
		[definition.ability_id],
		null
	)
	var committed_anchor: Dictionary = result.get("anchor", {})
	var foundation: Dictionary = result.get("foundation_snapshot", {})
	var active_anchors: Array = foundation.get("anchors", [])
	var impact: Dictionary = result.get("impact", {})
	var frozen_position: Vector3 = committed_anchor.get("position", Vector3.ZERO)

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

	target.free()
	controller.tick(0.1)
	var after_free_tick := controller.anchors.active_anchors()
	_expect(after_free_tick.size() == 1, "Freeing the dead enemy node must not invalidate its detached corpse Anchor")
	if after_free_tick.size() == 1:
		var detached_anchor: Dictionary = after_free_tick[0]
		_expect(detached_anchor.get("carrier_type", &"") == &"corpse", "Detached Anchor should remain classified as corpse after the enemy node is freed")
		_expect(is_equal_approx(float(detached_anchor.get("remaining_seconds", 0.0)), 7.9), "Detached corpse Anchor should continue its independent eight-second countdown")
		_expect((detached_anchor.get("position", Vector3.ZERO) as Vector3).is_equal_approx(frozen_position), "Detached corpse Anchor should preserve the final enemy position")

	controller.tick(7.7)
	var before_expiry := controller.anchors.active_anchors()
	_expect(before_expiry.size() == 1, "Detached corpse Anchor should remain active until its full duration elapses")
	if before_expiry.size() == 1:
		var nearly_expired: Dictionary = before_expiry[0]
		var remaining := float(nearly_expired.get("remaining_seconds", 0.0))
		_expect(remaining > 0.0 and remaining <= 0.21, "Detached corpse Anchor should approach zero without expiring early")

	controller.tick(0.3)
	_expect(controller.anchors.active_count() == 0, "Detached corpse Anchor should expire after its full eight-second lifetime")
	_expect(removed_events.size() == 1 and removed_events[0].get("reason", &"") == &"expired", "Detached corpse Anchor should end with the expired reason, not carrier_invalidated")

	controller.clear()
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
