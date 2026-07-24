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
	var origin_before := _find_tree_node(nodes, "proof_origin")
	var force_before := _find_tree_node(nodes, "proof_force")
	_expect(str(origin_before.get("visual_state", "")) == "available", "Affordable root should render available")
	_expect(str(force_before.get("visual_state", "")) == "locked", "Prerequisite-gated child should render locked")
	var purchase := bridge.purchase_node(&"proof_origin")
	_expect(bool(purchase.get("success", false)), "Root node purchase should transact through RuntimeSession")
	_expect(bridge.available_points() == 1, "Successful purchase should reduce derived availability")
	var after_purchase := bridge.tree_snapshot()
	var origin_after := _find_tree_node(after_purchase.get("nodes", []), "proof_origin")
	var force_after := _find_tree_node(after_purchase.get("nodes", []), "proof_force")
	_expect(str(origin_after.get("visual_state", "")) == "max_rank", "Purchased one-rank root should render maximum rank")
	_expect(str(force_after.get("visual_state", "")) == "available", "Unlocked affordable child should render available")
	var duplicate_rank := bridge.purchase_node(&"proof_origin")
	_expect(not bool(duplicate_rank.get("success", false)), "Maximum-rank purchase should fail")
	_expect(bridge.available_points() == 1, "Failed purchase must not change available points")
	bridge.queue_free()


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
