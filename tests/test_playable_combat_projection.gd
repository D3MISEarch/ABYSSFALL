extends SceneTree

const VOID_WARLOCK_SCRIPT = preload("res://scripts/characters/void_warlock.gd")
const PENITENT_SCRIPT = preload("res://scripts/characters/penitent_playable.gd")

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
	var projection := PlayableCombatProjection.new()
	projection.configure({"armor": 2.0, "power": 4.0, "critical_chance": 0.5})
	_expect(projection.resolve_incoming_damage(10) == 8, "Armor should reduce incoming damage without reaching zero")
	_expect(projection.resolve_outgoing_damage(10) == 14, "Power should add flat outgoing damage")
	_expect(projection.resolve_outgoing_damage(10) == 21, "Deterministic critical meter should amplify the expected hit")
	_expect(projection.resolve_incoming_damage(1) == 1, "Armor should preserve the one-damage floor")
	_expect(projection.resolve_outgoing_damage(0) == 0, "Zero outgoing damage should remain zero")


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
		_expect(character._resolve_outgoing_damage(11) == 16, "Playable class should route outgoing damage through projected power")
		_expect(character._resolve_outgoing_damage(11) == 24, "Playable class should route deterministic critical hits through the projection")
		character.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
