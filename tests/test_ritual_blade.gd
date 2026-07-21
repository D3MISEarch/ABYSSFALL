extends SceneTree

const RULES = preload("res://scripts/characters/penitent/ritual_blade_rules.gd")
const PENITENT_CHARACTER_SCRIPT = preload("res://scripts/characters/penitent_character.gd")

var failures := 0


class DummyEnemy extends Node3D:
	var alive := true
	var damage_taken := 0

	func take_damage(amount: int) -> void:
		damage_taken += amount


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_arc_geometry()
	_test_step_in_rules()
	_test_damage_sequence()
	await _test_canonical_attack_hits_readable_range_and_fades()
	await _test_brand_pulse_material_fades()
	_test_attack_visual_exists_on_miss()

	if failures > 0:
		printerr("Ritual Blade tests failed: %d" % failures)
		quit(1)
		return
	print("Ritual Blade tests passed.")
	quit(0)


func _test_arc_geometry() -> void:
	var origin := Vector3.ZERO
	var facing := Vector3.FORWARD
	_assert_true(
		RULES.is_target_in_arc(origin, facing, Vector3(0.0, 0.0, -3.20)),
		"Readable frontal melee distance is included"
	)
	_assert_true(
		RULES.is_target_in_arc(origin, facing, Vector3(2.20, 0.0, -2.20)),
		"Wide frontal cleave includes an angled pack target"
	)
	_assert_true(
		not RULES.is_target_in_arc(origin, facing, Vector3(0.0, 0.0, -3.60)),
		"Target beyond Ritual Blade reach is excluded"
	)
	_assert_true(
		not RULES.is_target_in_arc(origin, facing, Vector3(0.0, 0.0, 1.0)),
		"Target behind the Penitent is excluded"
	)


func _test_step_in_rules() -> void:
	var origin := Vector3.ZERO
	var facing := Vector3.FORWARD
	_assert_true(
		RULES.get_step_in_distance(origin, facing, Vector3(0.0, 0.0, -3.60)) > 0.0,
		"Attack can step into a target just beyond normal reach"
	)
	_assert_float(
		RULES.get_step_in_distance(origin, facing, Vector3(0.0, 0.0, -1.40)),
		0.0,
		"Attack does not lunge when already in close range"
	)
	_assert_float(
		RULES.get_step_in_distance(origin, facing, Vector3(0.0, 0.0, 2.0)),
		0.0,
		"Attack never lunges backward"
	)


func _test_damage_sequence() -> void:
	_assert_equal(RULES.get_damage(1), 10, "First slash keeps its damage")
	_assert_equal(RULES.get_damage(2), 12, "Second slash keeps its damage")
	_assert_equal(RULES.get_damage(3), 18, "Finisher keeps its damage")


func _test_canonical_attack_hits_readable_range_and_fades() -> void:
	var previous_scene := current_scene
	var world := Node3D.new()
	world.name = "RitualBladeWorld"
	root.add_child(world)
	current_scene = world

	var penitent := PENITENT_CHARACTER_SCRIPT.new() as PenitentCharacter
	penitent.position = Vector3(0.0, 0.9, 0.0)
	penitent.set_physics_process(false)
	world.add_child(penitent)
	penitent.facing = Vector3.FORWARD

	var front_target := DummyEnemy.new()
	front_target.name = "FrontTarget"
	front_target.position = Vector3(0.0, 0.0, -3.10)
	world.add_child(front_target)
	front_target.add_to_group("enemies")

	var rear_target := DummyEnemy.new()
	rear_target.name = "RearTarget"
	rear_target.position = Vector3(0.0, 0.0, 1.0)
	world.add_child(rear_target)
	rear_target.add_to_group("enemies")

	penitent._perform_ritual_blade_attack()
	_assert_equal(front_target.damage_taken, 10, "Canonical attack reaches the frontal target")
	_assert_equal(rear_target.damage_taken, 0, "Canonical attack does not hit behind the player")
	var snapshot: Dictionary = penitent.get_ritual_blade_snapshot()
	_assert_equal(int(snapshot.get("hits", 0)), 1, "Attack snapshot records the hit")
	_assert_equal(int(snapshot.get("combo_step", 0)), 1, "Attack snapshot records combo step one")

	var hit_visual := front_target.get_node_or_null("RitualBladeHit") as MeshInstance3D
	_assert_true(is_instance_valid(hit_visual), "A successful hit creates an impact pulse")
	if is_instance_valid(hit_visual):
		var hit_material := hit_visual.material_override as StandardMaterial3D
		_assert_true(is_instance_valid(hit_material), "Impact pulse owns a 3D fade material")
		if is_instance_valid(hit_material):
			var starting_alpha := hit_material.albedo_color.a
			await create_timer(0.08).timeout
			_assert_true(
				hit_material.albedo_color.a < starting_alpha,
				"Impact pulse fades its material alpha before cleanup"
			)

	current_scene = previous_scene
	world.free()


func _test_brand_pulse_material_fades() -> void:
	var previous_scene := current_scene
	var world := Node3D.new()
	world.name = "BrandPulseWorld"
	root.add_child(world)
	current_scene = world

	var penitent := PENITENT_CHARACTER_SCRIPT.new() as PenitentCharacter
	penitent.set_physics_process(false)
	world.add_child(penitent)
	var target := DummyEnemy.new()
	world.add_child(target)
	penitent._spawn_brand_pulse(target, Color(0.82, 0.025, 0.045), 1.65)

	var brand_visual := target.get_node_or_null("BrandPulse") as MeshInstance3D
	_assert_true(is_instance_valid(brand_visual), "Brand of Ruin creates a named 3D pulse")
	if is_instance_valid(brand_visual):
		var brand_material := brand_visual.material_override as StandardMaterial3D
		_assert_true(is_instance_valid(brand_material), "Brand pulse owns a 3D fade material")
		if is_instance_valid(brand_material):
			var starting_alpha := brand_material.albedo_color.a
			await create_timer(0.10).timeout
			_assert_true(
				brand_material.albedo_color.a < starting_alpha,
				"Brand pulse fades its material alpha before cleanup"
			)

	current_scene = previous_scene
	world.free()


func _test_attack_visual_exists_on_miss() -> void:
	var previous_scene := current_scene
	var world := Node3D.new()
	world.name = "RitualBladeMissWorld"
	root.add_child(world)
	current_scene = world

	var penitent := PENITENT_CHARACTER_SCRIPT.new() as PenitentCharacter
	penitent.set_physics_process(false)
	world.add_child(penitent)
	penitent.facing = Vector3.FORWARD
	penitent._perform_ritual_blade_attack()

	_assert_true(
		is_instance_valid(world.get_node_or_null("RitualBladeArc")),
		"A missed basic attack still creates readable swing feedback"
	)
	var snapshot: Dictionary = penitent.get_ritual_blade_snapshot()
	_assert_equal(int(snapshot.get("hits", -1)), 0, "Attack snapshot distinguishes a miss")

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
