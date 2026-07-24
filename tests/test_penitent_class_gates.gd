extends SceneTree

const CLASS_IDS = preload("res://scripts/shared/class_ids.gd")
const FERVOR_SEAL_SCRIPT = preload("res://scripts/ui/fervor_seal.gd")
const MULTICLASS_MAIN = preload("res://scripts/multiclass_main.gd")

const LEGACY_PENITENT_ID := "penitent_placeholder"
const UNKNOWN_CLASS_ID := "unknown_class"

var failures := 0


class GateTestMain extends MULTICLASS_MAIN:
	func _ready() -> void:
		pass


class FakePenitentPlayer extends Node:
	var quote_calls := 0

	func quote_sacrament_cost(cost: float) -> Dictionary:
		quote_calls += 1
		return {
			"can_cast": true,
			"requested_cost": cost,
			"fervor_spent": 32.0,
			"health_percent": 4,
		}

	func get_class_definition() -> Dictionary:
		return {"display_name": "The Penitent", "resource_name": "Fervor"}

	func get_resource_snapshot() -> Dictionary:
		return {"current": 68.0, "maximum": 100.0}

	func get_sigil_capacity_snapshot() -> Dictionary:
		return {"active": 2, "maximum": 3}


class FakeCostPreviewMeter extends Control:
	var previews: Array[Dictionary] = []

	func set_cost_preview(fervor_spent: float, health_percent: int) -> void:
		previews.append(
			{"fervor_spent": fervor_spent, "health_percent": health_percent}
		)


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_canonical_penitent_sacrament_preview()
	_test_canonical_penitent_hud_installation_is_idempotent()
	_test_non_penitent_ids_are_excluded()
	if failures > 0:
		printerr("Canonical Penitent class gate tests failed: %d" % failures)
		quit(1)
		return
	print("Canonical Penitent class gate tests passed.")
	quit(0)


func _test_canonical_penitent_sacrament_preview() -> void:
	var main := _new_main()
	var fake_player := FakePenitentPlayer.new()
	var preview_meter := FakeCostPreviewMeter.new()
	main.player = fake_player
	main.add_child(fake_player)
	main.corruption_meter = preview_meter
	main.add_child(preview_meter)
	main.selected_class_id = CLASS_IDS.PENITENT

	var quote := main.preview_penitent_sacrament(40.0)
	_assert_equal(
		quote,
		{
			"can_cast": true,
			"requested_cost": 40.0,
			"fervor_spent": 32.0,
			"health_percent": 4,
		},
		"Canonical Penitent passes through the Sacrament quote"
	)
	_assert_equal(fake_player.quote_calls, 1, "Canonical Penitent asks the player for one quote")
	_assert_equal(preview_meter.previews.size(), 1, "Canonical Penitent updates the cost preview")
	if preview_meter.previews.size() == 1:
		_assert_equal(
			preview_meter.previews[0],
			{"fervor_spent": 32.0, "health_percent": 4},
			"Cost preview receives the quoted Fervor and health payment"
		)
	_cleanup(main)


func _test_canonical_penitent_hud_installation_is_idempotent() -> void:
	var main := _new_main()
	var fake_player := FakePenitentPlayer.new()
	var hud_canvas := Control.new()
	var previous_meter := Control.new()
	main.player = fake_player
	main.add_child(fake_player)
	main.add_child(hud_canvas)
	hud_canvas.add_child(previous_meter)
	main.corruption_meter = previous_meter
	main.selected_class_id = CLASS_IDS.PENITENT

	main._update_class_specific_copy()
	var installed_meter = main.corruption_meter
	_assert_true(main.penitent_hud_installed, "Canonical Penitent installs the resource HUD")
	_assert_equal(
		installed_meter.get_script(),
		FERVOR_SEAL_SCRIPT,
		"Canonical Penitent installs the Fervor seal resource HUD"
	)
	_assert_equal(
		_count_fervor_seals(hud_canvas),
		1,
		"Canonical Penitent adds exactly one Fervor seal"
	)

	main._update_class_specific_copy()
	_assert_true(
		main.corruption_meter == installed_meter,
		"Repeated class-copy updates retain the installed Fervor seal"
	)
	_assert_equal(
		_count_fervor_seals(hud_canvas),
		1,
		"Repeated class-copy updates do not add another Fervor seal"
	)
	_cleanup(main)


func _test_non_penitent_ids_are_excluded() -> void:
	for class_id in [CLASS_IDS.VOID_WARLOCK, UNKNOWN_CLASS_ID, LEGACY_PENITENT_ID]:
		var main := _new_main()
		var fake_player := FakePenitentPlayer.new()
		var preview_meter := FakeCostPreviewMeter.new()
		var hud_canvas := Control.new()
		var previous_meter := Control.new()
		main.player = fake_player
		main.add_child(fake_player)
		main.add_child(hud_canvas)
		hud_canvas.add_child(previous_meter)
		main.corruption_meter = preview_meter
		main.add_child(preview_meter)
		main.selected_class_id = class_id

		_assert_equal(
			main.preview_penitent_sacrament(),
			{"can_cast": false},
			"%s cannot enter the Sacrament preview branch" % class_id
		)
		_assert_equal(
			fake_player.quote_calls,
			0,
			"%s does not request a Sacrament quote" % class_id
		)
		_assert_equal(
			preview_meter.previews.size(),
			0,
			"%s does not update the Sacrament cost preview" % class_id
		)

		main.corruption_meter = previous_meter
		preview_meter.queue_free()
		main._update_class_specific_copy()
		_assert_true(
			not main.penitent_hud_installed,
			"%s cannot install the Penitent resource HUD" % class_id
		)
		_assert_true(
			main.corruption_meter == previous_meter,
			"%s retains the non-Penitent HUD" % class_id
		)
		_assert_equal(
			_count_fervor_seals(hud_canvas),
			0,
			"%s does not add a Fervor seal" % class_id
		)
		_cleanup(main)


func _new_main() -> GateTestMain:
	var main := GateTestMain.new()
	root.add_child(main)
	return main


func _count_fervor_seals(container: Node) -> int:
	var count := 0
	for child in container.get_children():
		if child.get_script() == FERVOR_SEAL_SCRIPT:
			count += 1
	return count


func _cleanup(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


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
