extends SceneTree

const PLAYABLE_COMBAT_PROJECTION_SCRIPT = preload("res://scripts/core/playable_combat_projection.gd")
const VOID_WARLOCK_SCRIPT = preload("res://scripts/characters/void_warlock.gd")
const PENITENT_SCRIPT = preload("res://scripts/characters/penitent_playable.gd")


class DamageTarget:
	extends RefCounted
	var health := 100
	var hit_calls := 0

	func take_damage(amount: int) -> int:
		hit_calls += 1
		var applied := mini(health, maxi(amount, 0))
		health -= applied
		return applied


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_projection_math_is_deterministic()
	_test_playable_classes_consume_projection()
	if failures.is_empty():
		print("PASS: Playable combat projection")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_projection_math_is_deterministic() -> void:
	var projection := PLAYABLE_COMBAT_PROJECTION_SCRIPT.new()
	projection.configure({"armor": 2.0, "power": 4.0, "critical_chance": 0.5})
	_expect(projection.resolve_incoming_damage(10) == 8, "Armor should reduce incoming damage without reaching zero")
	var first_result := projection.resolve_outgoing_result(10)
	_expect(int(first_result.get("damage", 0)) == 14, "Power should add flat outgoing damage")
	_expect(not bool(first_result.get("critical", true)), "The first half-meter result should be non-critical")
	var second_result := projection.resolve_outgoing_result(10)
	_expect(int(second_result.get("damage", 0)) == 21, "Deterministic critical meter should amplify the expected hit")
	_expect(bool(second_result.get("critical", false)), "The second half-meter result should be critical")
	_expect(projection.resolve_incoming_damage(1) == 1, "Armor should preserve the one-damage floor")
	var rejected_projection := PLAYABLE_COMBAT_PROJECTION_SCRIPT.new()
	rejected_projection.configure({"power": 4.0, "critical_chance": 0.5})
	var rejected_result := rejected_projection.resolve_outgoing_result(0)
	_expect(int(rejected_result.get("damage", -1)) == 0 and not bool(rejected_result.get("critical", true)), "Invalid zero damage should return a non-critical empty result")
	var post_rejection_result := rejected_projection.resolve_outgoing_result(10)
	_expect(not bool(post_rejection_result.get("critical", true)) and int(post_rejection_result.get("damage", 0)) == 14, "Rejected damage must not advance the critical meter")
	var legacy_projection := PLAYABLE_COMBAT_PROJECTION_SCRIPT.new()
	legacy_projection.configure({"power": 4.0, "critical_chance": 0.5})
	_expect(legacy_projection.resolve_outgoing_damage(10) == 14, "Legacy integer damage should delegate once to the structured authority")
	_expect(legacy_projection.resolve_outgoing_damage(10) == 21, "Legacy integer damage should consume one critical meter step per call")


func _test_playable_classes_consume_projection() -> void:
	for character_script: Script in [VOID_WARLOCK_SCRIPT, PENITENT_SCRIPT]:
		var character = character_script.new()
		character.apply_class_tree_projection({"armor": 3.0, "power": 5.0, "critical_chance": 0.5})
		var snapshot: Dictionary = character.get_class_tree_combat_snapshot()
		_expect(is_equal_approx(float(snapshot.get("armor", 0.0)), 3.0), "Playable class should retain projected armor")
		_expect(is_equal_approx(float(snapshot.get("power", 0.0)), 5.0), "Playable class should retain projected power")
		_expect(character._resolve_incoming_damage(12) == 9, "Playable class should route incoming damage through projected armor")
		var health_before := int(character.health)
		character.take_damage(12)
		_expect(int(character.health) == health_before - 9, "Playable take-damage path should consume projected armor")
		var target := DamageTarget.new()
		var legacy_damage: int = int(character._resolve_outgoing_damage(11))
		_expect(legacy_damage == 16, "Playable class's legacy live outgoing path should delegate once to the projection")
		target.take_damage(legacy_damage)
		_expect(target.hit_calls == 1 and target.health == 84, "One authoritative legacy result should apply target health damage exactly once")
		var structured_result: Dictionary = character.resolve_outgoing_damage_result(11)
		_expect(int(structured_result.get("damage", 0)) == 24 and bool(structured_result.get("critical", false)), "Playable class should propagate the one-pass critical result")
		target.take_damage(int(structured_result.get("damage", 0)))
		_expect(target.hit_calls == 2 and target.health == 60, "A second valid hit should add only its own resolved damage")
		character.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
