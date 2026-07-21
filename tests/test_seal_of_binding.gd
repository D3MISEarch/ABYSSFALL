extends SceneTree

const RULES = preload("res://scripts/characters/penitent/seal_binding_rules.gd")
const ROSTER_SCRIPT = preload("res://scripts/characters/penitent/sigil_roster.gd")
const CONTROL_SCRIPT = preload("res://scripts/characters/penitent/ritual_control_component.gd")
const PENITENT_CHARACTER_SCRIPT = preload("res://scripts/characters/penitent_character.gd")

var failures := 0


class DummyEnemy extends Node:
	var move_speed := 10.0


class DummyWorldEnemy extends Node3D:
	var move_speed := 10.0
	var alive := true


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_standard_binding_profile()
	_test_resistant_profiles()
	_test_radius_math()
	_test_three_sigil_replacement_order()
	_test_stack_safe_control_sources()
	_test_initial_pulse_uses_placed_position()

	if failures > 0:
		printerr("Seal of Binding tests failed: %d" % failures)
		quit(1)
		return
	print("Seal of Binding tests passed.")
	quit(0)


func _test_standard_binding_profile() -> void:
	var partial: Dictionary = RULES.get_control_profile(RULES.TARGET_STANDARD, false)
	_assert_float(float(partial.get("movement_multiplier", 0.0)), 0.58, "Uncompleted enemies are slowed")
	_assert_float(float(partial.get("bind_duration", -1.0)), 0.0, "Uncompleted enemies are not bound")

	var complete: Dictionary = RULES.get_control_profile(RULES.TARGET_STANDARD, true)
	_assert_float(float(complete.get("movement_multiplier", 1.0)), 0.0, "Completed Rite fully arrests standard enemies")
	_assert_true(float(complete.get("bind_duration", 0.0)) > 0.30, "Completed Rite receives a continuous bind pulse")
	_assert_true(bool(complete.get("show_chains", false)), "Completed Rite displays ritual chains")


func _test_resistant_profiles() -> void:
	var brute: Dictionary = RULES.get_control_profile(RULES.TARGET_BRUTE, true)
	_assert_float(float(brute.get("movement_multiplier", 0.0)), 0.48, "Brute retains resistant movement")
	_assert_true(float(brute.get("bind_duration", 0.0)) < 0.20, "Brute bind window is shortened")

	var boss: Dictionary = RULES.get_control_profile(RULES.TARGET_BOSS, true)
	_assert_float(float(boss.get("movement_multiplier", 0.0)), 0.72, "Boss receives a hinder rather than a root")
	_assert_float(float(boss.get("bind_duration", -1.0)), 0.0, "Boss cannot be hard bound")
	_assert_true(bool(boss.get("show_chains", false)), "Boss resistance still receives readable chain feedback")


func _test_radius_math() -> void:
	_assert_true(RULES.is_inside_radius(Vector3.ZERO, Vector3(3.0, 8.0, 0.0), 3.4), "Vertical offset does not break ground-circle inclusion")
	_assert_true(not RULES.is_inside_radius(Vector3.ZERO, Vector3(3.5, 0.0, 0.0), 3.4), "Target outside radius is excluded")


func _test_three_sigil_replacement_order() -> void:
	var roster := ROSTER_SCRIPT.new() as SigilRoster
	roster.configure(3)
	var first := Node.new()
	var second := Node.new()
	var third := Node.new()
	var fourth := Node.new()
	_assert_true(roster.register(first) == null, "First sigil does not evict")
	roster.register(second)
	roster.register(third)
	var evicted := roster.register(fourth)
	_assert_true(evicted == first, "Fourth sigil evicts the oldest")
	var snapshot: Dictionary = roster.get_snapshot()
	_assert_equal(int(snapshot.get("active", 0)), 3, "Roster remains capped at three sigils")
	first.free()
	second.free()
	third.free()
	fourth.free()


func _test_stack_safe_control_sources() -> void:
	var enemy := DummyEnemy.new()
	root.add_child(enemy)
	enemy.set_physics_process(true)
	var control := CONTROL_SCRIPT.new() as RitualControlComponent
	enemy.add_child(control)
	control.bind_to(enemy)
	control.apply_source(11, 0.50, 10.0, 0.0)
	control.apply_source(22, 0.70, 10.0, 0.0)
	_assert_float(enemy.move_speed, 5.0, "Strongest overlapping slow wins")
	control.remove_source(11)
	_assert_float(enemy.move_speed, 7.0, "Removing one seal preserves the other seal")
	control.apply_source(33, 0.0, 10.0, 2.0)
	_assert_true(not enemy.is_physics_processing(), "Completed Rite disables enemy physics while bound")
	control.remove_source(33)
	_assert_true(enemy.is_physics_processing(), "Removing bind restores enemy physics")
	control.remove_source(22)
	_assert_float(enemy.move_speed, 10.0, "Removing all seals restores original movement")
	enemy.queue_free()


func _test_initial_pulse_uses_placed_position() -> void:
	var previous_scene := current_scene
	var world := Node3D.new()
	world.name = "SealSpawnOrderWorld"
	root.add_child(world)
	current_scene = world

	var origin_decoy := DummyWorldEnemy.new()
	origin_decoy.name = "OriginDecoy"
	origin_decoy.position = Vector3.ZERO
	world.add_child(origin_decoy)
	origin_decoy.add_to_group("enemies")

	var placed_target := DummyWorldEnemy.new()
	placed_target.name = "PlacedTarget"
	placed_target.position = Vector3(23.0, 0.0, 20.0)
	world.add_child(placed_target)
	placed_target.add_to_group("enemies")

	var penitent := PENITENT_CHARACTER_SCRIPT.new() as PenitentCharacter
	penitent.position = Vector3(20.0, 0.9, 20.0)
	penitent.facing = Vector3.RIGHT
	world.add_child(penitent)
	penitent.facing = Vector3.RIGHT
	penitent.fervor_component.configure(100.0, 100.0)
	penitent._place_seal_of_binding()

	var seal := world.get_node_or_null("SealOfBinding") as Node3D
	_assert_true(is_instance_valid(seal), "Seal is added to the active scene")
	if is_instance_valid(seal):
		_assert_true(
			seal.global_position.distance_to(Vector3(23.0, 0.07, 20.0)) < 0.01,
			"Canonical Penitent seal enters the tree at its intended world position"
		)
	_assert_true(
		is_instance_valid(placed_target.get_node_or_null("RitualControl")),
		"First binding pulse affects the enemy at the placed seal"
	)
	_assert_true(
		not is_instance_valid(origin_decoy.get_node_or_null("RitualControl")),
		"First binding pulse never flickers at world origin"
	)

	current_scene = previous_scene
	world.free()


func _assert_true(condition: bool, label: String) -> void:
	if condition:
		return
	failures += 1
	printerr("FAIL: %s" % label)


func _assert_equal(actual, expected, label: String) -> void:
	if actual == expected:
		return
	failures += 1
	printerr("FAIL: %s — expected %s, got %s" % [label, str(expected), str(actual)])


func _assert_float(actual: float, expected: float, label: String) -> void:
	if is_equal_approx(actual, expected):
		return
	failures += 1
	printerr("FAIL: %s — expected %.3f, got %.3f" % [label, expected, actual])
