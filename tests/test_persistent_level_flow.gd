extends SceneTree

const VOID_WARLOCK_SCRIPT = preload("res://scripts/characters/void_warlock.gd")
const PENITENT_SCRIPT = preload("res://scripts/characters/penitent_playable.gd")
const PROGRESSION_BRIDGE_SCRIPT = preload("res://scripts/ui/playable_progression_bridge.gd")

var failures: Array[String] = []
var card_request_count := 0
var award_total := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_playable_leveling_no_longer_requests_cards(VOID_WARLOCK_SCRIPT, "Void Warlock")
	_test_playable_leveling_no_longer_requests_cards(PENITENT_SCRIPT, "Penitent")
	_test_playable_restore_and_contract()
	_test_runtime_bridge_awards_and_spends()
	_test_persistent_bridge_disk_round_trip()
	if failures.is_empty():
		print("PASS: Persistent non-blocking level flow")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_playable_leveling_no_longer_requests_cards(character_script: Script, label: String) -> void:
	var character = character_script.new()
	card_request_count = 0
	character.level_up_requested.connect(_on_card_requested)
	character.add_experience(235)
	_expect(character.level >= 3, "%s should gain multiple levels from one reward" % label)
	_expect(character.pending_level_ups == 0, "%s should not queue mandatory card choices" % label)
	_expect(not character.level_up_in_progress, "%s should not enter a blocking level-up state" % label)
	_expect(card_request_count == 0, "%s should never request the legacy card panel" % label)
	character.free()


func _test_playable_restore_and_contract() -> void:
	for character_script: Script in [VOID_WARLOCK_SCRIPT, PENITENT_SCRIPT]:
		var character = character_script.new()
		_expect(CharacterContract.is_valid_character(character), "Playable class should satisfy the persistent character contract")
		character.restore_persistent_progression(6, 31)
		_expect(character.level == 6 and character.experience == 31, "Persistent level and XP should restore into the playable class")
		_expect(character.pending_level_ups == 0 and not character.level_up_in_progress, "Restore must clear every legacy blocking-level flag")
		character.free()


func _test_runtime_bridge_awards_and_spends() -> void:
	var build := BuildData.create_new(ClassIds.VOID_WARLOCK, "Bridge Test")
	var bridge := PROGRESSION_BRIDGE_SCRIPT.new()
	root.add_child(bridge)
	award_total = 0
	bridge.points_awarded.connect(_on_points_awarded)
	_expect(bridge.configure_ephemeral(build), "Bridge should bind an ephemeral build")
	_expect(bridge.sync_playable_progress(3, 12), "Bridge should accept playable progress")
	_expect(bridge.available_points() == 2, "Levels two and three should provide two derived points")
	_expect(award_total == 2, "A multi-level sync should aggregate exactly two point awards")
	_expect(bridge.sync_playable_progress(3, 20), "Same-level XP should remain synchronizable")
	_expect(bridge.available_points() == 2 and award_total == 2, "Repeated level sync must not duplicate points")

	var tree := bridge.tree_snapshot()
	_expect(str(tree.get("point_display_name", "")) == "Void Points", "Voidbringer proof should expose Void Points")
	var nodes: Array = tree.get("nodes", [])
	_expect(nodes.size() == 8, "Framework tree should expose all eight proof nodes")
	var origin_layout := _find_tree_node(nodes, "proof_origin")
	_expect(origin_layout.get("position", null) is Vector2, "Framework snapshot should expose authored graphical positions")
	_expect(origin_layout.get("neighbors", {}) is Dictionary, "Framework snapshot should expose authored controller neighbors")
	_expect(origin_layout.get("prerequisite_ids", []) is Array, "Framework snapshot should expose connection-ready prerequisite IDs")
	var origin_before := _find_tree_node(nodes, "proof_origin")
	var force_before := _find_tree_node(nodes, "proof_force")
	_expect(str(origin_before.get("visual_state", "")) == "available", "Affordable root should render available")
	_expect(str(force_before.get("visual_state", "")) == "locked", "Prerequisite-gated child should render locked")
	var purchase := bridge.purchase_node(&"proof_origin")
	_expect(bool(purchase.get("success", false)), "Root node purchase should transact through RuntimeSession")
	_expect(bridge.available_points() == 1, "Successful purchase should reduce derived availability")
	var root_projection := bridge.combat_projection()
	_expect(is_equal_approx(float(root_projection.get("armor", 0.0)), 2.0), "Purchased root should project its armor into live combat")
	var after_purchase := bridge.tree_snapshot()
	var origin_after := _find_tree_node(after_purchase.get("nodes", []), "proof_origin")
	var force_after := _find_tree_node(after_purchase.get("nodes", []), "proof_force")
	_expect(str(origin_after.get("visual_state", "")) == "max_rank", "Purchased one-rank root should render maximum rank")
	_expect(str(force_after.get("visual_state", "")) == "available", "Unlocked affordable child should render available")
	var duplicate_rank := bridge.purchase_node(&"proof_origin")
	_expect(not bool(duplicate_rank.get("success", false)), "Maximum-rank purchase should fail")
	_expect(bridge.available_points() == 1, "Failed purchase must not change available points")
	var force_purchase := bridge.purchase_node(&"proof_force")
	_expect(bool(force_purchase.get("success", false)), "Unlocked force rank should purchase")
	var force_projection := bridge.combat_projection()
	_expect(is_equal_approx(float(force_projection.get("power", 0.0)), 4.0), "Purchased force rank should project power into live combat")
	_expect(bridge.available_points() == 0, "Projected purchase should still consume the authoritative point")
	bridge.queue_free()


func _test_persistent_bridge_disk_round_trip() -> void:
	var service := PersistenceService.new()
	_expect(service.initialize("Progression UI Disk Tester"), "Persistent UI test service should initialize")
	if service.profile == null:
		service.free()
		return
	var previous_selection := service.profile.selected_build_id
	var test_build := service.create_and_select_build(
		ClassIds.VOID_WARLOCK,
		"Progression UI Disk %s" % str(Time.get_ticks_usec())
	)
	_expect(test_build != null, "Persistent UI test should create an isolated build")
	if test_build == null:
		_restore_previous_selection(service.profile, previous_selection)
		service.free()
		return
	var test_build_id := test_build.build_id

	var first_bridge := PROGRESSION_BRIDGE_SCRIPT.new() as PlayableProgressionBridge
	root.add_child(first_bridge)
	_expect(first_bridge.configure_persistent(ClassIds.VOID_WARLOCK, service, "Unused"), "Persistent bridge should bind the isolated build")
	_expect(first_bridge.sync_playable_progress(3, 27), "Persistent bridge should save level and XP")
	_expect(bool(first_bridge.purchase_node(&"proof_origin").get("success", false)), "Persistent bridge should save the root purchase")
	_expect(bool(first_bridge.purchase_node(&"proof_force").get("success", false)), "Persistent bridge should save the force purchase")
	_expect(first_bridge.flush("persistent_ui_round_trip") == OK, "Persistent bridge should flush its durable state")

	var restored_service := PersistenceService.new()
	_expect(restored_service.initialize("Progression UI Disk Tester"), "Reload service should initialize from real disk data")
	var restored_bridge := PROGRESSION_BRIDGE_SCRIPT.new() as PlayableProgressionBridge
	root.add_child(restored_bridge)
	_expect(restored_bridge.configure_persistent(ClassIds.VOID_WARLOCK, restored_service, "Unused"), "Reload bridge should bind the saved build")
	_expect(restored_bridge.current_level() == 3 and restored_bridge.current_experience() == 27, "Reload bridge should restore level and XP")
	_expect(restored_bridge.available_points() == 0, "Reload bridge should restore derived available points")
	var restored_tree := restored_bridge.tree_snapshot()
	var restored_origin := _find_tree_node(restored_tree.get("nodes", []), "proof_origin")
	var restored_force := _find_tree_node(restored_tree.get("nodes", []), "proof_force")
	_expect(int(restored_origin.get("rank", 0)) == 1, "Reload tree should restore the root rank")
	_expect(int(restored_force.get("rank", 0)) == 1, "Reload tree should restore the force rank")
	var restored_projection := restored_bridge.combat_projection()
	_expect(is_equal_approx(float(restored_projection.get("armor", 0.0)), 2.0), "Reload should rebuild projected armor")
	_expect(is_equal_approx(float(restored_projection.get("power", 0.0)), 4.0), "Reload should rebuild projected power")

	var screen := ClassTreeScreen.new()
	screen.size = Vector2(930.0, 478.0)
	root.add_child(screen)
	_expect(screen.set_tree_snapshot(restored_tree), "Graphical tree should accept the real disk-restored snapshot")
	_expect(screen.select_node(&"proof_force"), "Graphical tree should focus the restored purchased node")
	_expect(screen.node_title.text == "Applied Force", "Graphical detail panel should identify the restored node")
	_expect(screen.node_meta.text.contains("RANK 1 / 2"), "Graphical detail panel should display the restored rank")

	screen.queue_free()
	first_bridge.queue_free()
	restored_bridge.queue_free()
	restored_service.free()
	_expect(SaveManager.delete_build(service.profile, test_build_id) == OK, "Persistent UI test should delete only its generated build")
	_restore_previous_selection(service.profile, previous_selection)
	service.free()


func _restore_previous_selection(profile: ProfileData, previous_selection: String) -> void:
	if profile == null:
		return
	if not previous_selection.is_empty() and profile.build_ids.has(previous_selection):
		SaveManager.select_build(profile, previous_selection)
	else:
		profile.selected_build_id = ""
		SaveManager.save_profile(profile)


func _find_tree_node(nodes: Array, node_id: String) -> Dictionary:
	for raw_node: Variant in nodes:
		if raw_node is Dictionary and str(raw_node.get("node_id", "")) == node_id:
			return raw_node
	return {}


func _on_card_requested() -> void:
	card_request_count += 1


func _on_points_awarded(_level: int, amount: int, _available: int) -> void:
	award_total += amount


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
