extends SceneTree

var failures: Array[String] = []
var point_event_count := 0
var last_point_total := -1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_case("definition integrity and defensive catalog", _test_definition_integrity)
	_run_case("award ledger and atomic spending", _test_awards_and_spending)
	_run_case("JSON round trip and deterministic rebuild", _test_json_round_trip)
	_run_case("real persistence disk round trip", _test_disk_round_trip)
	_run_case("multi-level awards exactly once", _test_multi_level_awards)
	_run_case("failed progression bind preserves active session", _test_failed_bind_preserves_session)

	if failures.is_empty():
		print("PASS: Persistent class progression runtime")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _run_case(label: String, callable: Callable) -> void:
	print("TEST: %s" % label)
	var before := failures.size()
	callable.call()
	if failures.size() == before:
		print("PASS: %s" % label)


func _test_definition_integrity() -> void:
	var catalog := ClassTreeCatalog.new()
	_expect(catalog.register_framework_proofs(), "Framework proof definitions should register")
	var definition := catalog.get_definition(ClassIds.VOID_WARLOCK)
	_expect(definition != null and definition.is_valid(), "Voidbringer compatibility definition should be valid")
	_expect(definition.all_node_ids().size() == 8, "Framework proof should remain deliberately compact")
	definition.point_display_name = "Mutated Copy"
	_expect(catalog.get_definition(ClassIds.VOID_WARLOCK).point_display_name == "Void Points", "Catalog should return defensive definition copies")

	var cycle_a := ClassTreeNodeDefinition.new(&"cycle_a", ClassTreeNodeDefinition.NodeType.ROOT, "A", 1, [1], {"cycle_b": 1})
	var cycle_b := ClassTreeNodeDefinition.new(&"cycle_b", ClassTreeNodeDefinition.NodeType.MINOR, "B", 1, [1], {"cycle_a": 1})
	var cyclic := ClassTreeDefinition.new("bad", &"bad_cycle", 1, "Points", [&"cycle_a"], [cycle_a, cycle_b])
	_expect(not cyclic.is_valid(), "Definition cycles must be rejected")

	var unknown_prerequisite := ClassTreeNodeDefinition.new(&"orphan", ClassTreeNodeDefinition.NodeType.ROOT, "Orphan", 1, [1], {"missing": 1})
	var invalid := ClassTreeDefinition.new("bad2", &"bad_missing", 1, "Points", [&"orphan"], [unknown_prerequisite])
	_expect(not invalid.is_valid(), "Unknown prerequisite IDs must be rejected")


func _test_awards_and_spending() -> void:
	var state := _new_state(ClassIds.VOID_WARLOCK)
	var stats := StatBlock.new()
	stats.set_base(&"armor", 0.0)
	stats.set_base(&"power", 100.0)
	stats.set_base(&"critical_chance", 0.05)
	_expect(state.attach_stat_block(stats), "Progression should attach to a stat block")
	_expect(state.reconcile_level_awards(4) == 3, "Levels 2 through 4 should backfill exactly three points")
	_expect(state.available_points() == 3, "Backfilled points should be available")
	_expect(not state.award("level:3", 1), "Duplicate award source should be ignored")
	_expect(not state.award("", 1) and not state.award("quest:bad", 0), "Invalid awards should change nothing")

	var before := state.serialize()
	_expect(not bool(state.purchase_rank(&"missing").get("success", false)), "Unknown node purchase should fail")
	_expect(state.serialize() == before, "Unknown node failure must not mutate state")
	_expect(state.purchase_rank(&"proof_force").get("reason") == &"missing_prerequisite", "Prerequisites should be enforced")
	_expect(state.serialize() == before, "Prerequisite failure must be atomic")

	_expect(bool(state.purchase_rank(&"proof_origin").get("success", false)), "Root purchase should succeed")
	_expect(is_equal_approx(stats.get_value(&"armor"), 2.0), "Root effect should project once")
	_expect(bool(state.purchase_rank(&"proof_force").get("success", false)), "First ranked node purchase should succeed")
	_expect(bool(state.purchase_rank(&"proof_force").get("success", false)), "Second ranked node purchase should succeed")
	_expect(is_equal_approx(stats.get_value(&"power"), 108.0), "Two ranks should deterministically apply two flat effects")
	before = state.serialize()
	_expect(state.purchase_rank(&"proof_force").get("reason") == &"maximum_rank", "Maximum rank should be enforced")
	_expect(state.serialize() == before and is_equal_approx(stats.get_value(&"power"), 108.0), "Over-rank failure must preserve state and effects")
	_expect(state.purchase_rank(&"proof_notable").get("reason") == &"insufficient_points", "Unaffordable purchase should be rejected")

	_expect(state.award("trial:proof", 7), "Stable non-level award should apply once")
	_expect(bool(state.purchase_rank(&"proof_notable").get("success", false)), "Notable should unlock after prerequisite and funding")
	_expect(state.purchase_rank(&"proof_bridge").get("reason") == &"missing_prerequisite", "Bridge should require both paths")
	_expect(bool(state.purchase_rank(&"proof_guard").get("success", false)), "Guard path should purchase")
	_expect(bool(state.purchase_rank(&"proof_bridge").get("success", false)), "Bridge should unlock after both prerequisites")
	_expect(bool(state.purchase_rank(&"proof_law").get("success", false)), "Funded Law Node should purchase")
	var before_conflict := state.serialize()
	_expect(state.purchase_rank(&"proof_law_guard").get("reason") == &"mutually_exclusive", "Competing Law Nodes should enforce exclusion groups")
	_expect(state.serialize() == before_conflict, "Mutual-exclusion failure must be atomic")
	_expect(bool(state.purchase_rank(&"proof_culmination").get("success", false)), "Culmination should unlock after bridge and selected Law Node")
	var refund_preview := state.preview_refund(&"proof_guard")
	_expect(not bool(refund_preview.get("success", false)) and refund_preview.get("reason") == &"dependent_allocation", "Refund preview should protect dependent allocations")


func _test_json_round_trip() -> void:
	var build := BuildData.create_new(ClassIds.VOID_WARLOCK, "Round Trip")
	build.level = 6
	var character := RuntimeCharacter.new()
	character.configure_from_build(build)
	var session := RuntimeSession.new()
	root.add_child(session)
	_expect(session.bind_character(character), "Initial progression session should bind")
	_expect(session.class_progression.available_points() == 5, "Existing level should reconcile award ledger on first bind")
	_expect(bool(session.purchase_class_tree_node(&"proof_origin").get("success", false)), "Session purchase wrapper should transact")
	_expect(bool(session.purchase_class_tree_node(&"proof_force").get("success", false)), "Session should purchase ranked proof node")
	var first_stats := character.stats.snapshot()
	var first_progression := session.class_progression.serialize()
	var snapshot := session.durable_snapshot()
	_expect(snapshot.get("class_tree_state", {}) == first_progression, "Durable snapshot should include authoritative progression state")

	var encoded := JSON.stringify(snapshot)
	var parsed: Variant = JSON.parse_string(encoded)
	_expect(parsed is Dictionary, "Runtime snapshot should cross a real JSON boundary")
	var stored := build.to_dict()
	for key: Variant in parsed:
		stored[key] = parsed[key]
	var restored_build := BuildData.from_dict(stored)
	var restored_character := RuntimeCharacter.new()
	restored_character.configure_from_build(restored_build)
	var restored_session := RuntimeSession.new()
	root.add_child(restored_session)
	_expect(restored_session.bind_character(restored_character), "JSON-restored progression should bind")
	_expect(restored_session.class_progression.serialize() == first_progression, "Awards and allocations should survive JSON restore")
	_expect(restored_character.stats.snapshot() == first_stats, "Restored effects should be deterministic")

	var before_rebind_stats := restored_character.stats.snapshot()
	var rebound_character := RuntimeCharacter.new()
	rebound_character.configure_from_build(restored_build)
	_expect(restored_session.bind_character(rebound_character), "Rebinding the same durable build should succeed")
	_expect(rebound_character.stats.snapshot() == before_rebind_stats, "Rebinding must rebuild rather than stack progression effects")
	_expect(restored_session.class_progression.serialize() == first_progression, "Rebinding must not duplicate level awards")

	session.queue_free()
	restored_session.queue_free()


func _test_disk_round_trip() -> void:
	var service := PersistenceService.new()
	_expect(service.initialize("Progression Disk Tester"), "Persistence service should initialize")
	if service.profile == null:
		service.free()
		return
	var previous_selected_build_id := service.profile.selected_build_id
	var build := service.create_and_select_build(
		ClassIds.VOID_WARLOCK,
		"Class Progression Test %d" % Time.get_ticks_usec()
	)
	_expect(build != null, "Persistence service should create a uniquely identified durable test build")
	if build == null:
		service.free()
		return
	build.level = 4
	var character := RuntimeCharacter.new()
	character.configure_from_build(build)
	var session := RuntimeSession.new()
	root.add_child(session)
	_expect(session.bind_character(character), "Disk-path progression session should bind")
	_expect(bool(session.purchase_class_tree_node(&"proof_origin").get("success", false)), "Disk-path root purchase should succeed")
	_expect(bool(session.purchase_class_tree_node(&"proof_force").get("success", false)), "Disk-path child purchase should succeed")
	var expected_progression := session.class_progression.serialize()
	_expect(service.apply_active_build_snapshot(session.durable_snapshot()), "Progression snapshot should apply through PersistenceService")
	_expect(service.flush_if_dirty("class_progression_disk_round_trip") == OK, "Progression snapshot should write to disk")

	var loaded := SaveManager.load_build(build.build_id)
	_expect(loaded != null, "Progression build should reload from disk")
	if loaded != null:
		var loaded_tree: Dictionary = loaded.class_tree_state
		var loaded_awards: Dictionary = loaded_tree.get("award_ledger", {})
		var loaded_allocations: Dictionary = loaded_tree.get("allocations", {})
		_expect(int(loaded_tree.get("schema_version", 0)) == ClassProgressionState.SCHEMA_VERSION, "Disk reload should preserve the progression schema version")
		_expect(int(loaded_awards.get("level:2", 0)) == 1 and int(loaded_awards.get("level:3", 0)) == 1 and int(loaded_awards.get("level:4", 0)) == 1, "Disk reload should preserve every exactly-once level award source")
		_expect(int(loaded_allocations.get("proof_origin", 0)) == 1 and int(loaded_allocations.get("proof_force", 0)) == 1, "Disk reload should preserve allocated node ranks")
		var loaded_character := RuntimeCharacter.new()
		loaded_character.configure_from_build(loaded)
		var loaded_session := RuntimeSession.new()
		root.add_child(loaded_session)
		_expect(loaded_session.bind_character(loaded_character), "Disk-restored progression should bind")
		_expect(loaded_session.class_progression.serialize() == expected_progression, "Disk-restored runtime state should match the saved progression")
		loaded_session.queue_free()
	session.queue_free()
	_cleanup_test_build(service.profile, build.build_id, previous_selected_build_id)
	service.free()


func _test_multi_level_awards() -> void:
	point_event_count = 0
	last_point_total = -1
	var build := BuildData.create_new(ClassIds.PENITENT, "Multi Level")
	var character := RuntimeCharacter.new()
	character.configure_from_build(build)
	var session := RuntimeSession.new()
	root.add_child(session)
	_expect(session.bind_character(character), "Multi-level session should bind")
	session.event_bus.class_point_awarded.connect(_on_point_awarded)
	_expect(character.gain_experience(235) == 2, "Single reward should cross exactly two level thresholds")
	_expect(character.level == 3, "Character should reach level three")
	_expect(session.class_progression.available_points() == 2, "Both reached levels should award points")
	_expect(point_event_count == 2 and last_point_total == 2, "Each award should emit exactly once with resulting availability")
	character.level_gained.emit(3)
	_expect(session.class_progression.available_points() == 2 and point_event_count == 2, "Replayed level signal must not duplicate its source award")
	session.queue_free()


func _test_failed_bind_preserves_session() -> void:
	var active_build := BuildData.create_new(ClassIds.PENITENT, "Active Progression")
	active_build.level = 3
	var active_character := RuntimeCharacter.new()
	active_character.configure_from_build(active_build)
	var session := RuntimeSession.new()
	root.add_child(session)
	_expect(session.bind_character(active_character), "Active progression character should bind")
	var active_progression := session.class_progression
	var active_inventory := session.inventory
	var active_snapshot := session.durable_snapshot()

	var corrupt_build := BuildData.create_new(ClassIds.PENITENT, "Corrupt Progression")
	corrupt_build.class_tree_state = {
		"schema_version": 1,
		"award_ledger": {},
		"allocations": {"proof_origin": 1},
	}
	var corrupt_character := RuntimeCharacter.new()
	corrupt_character.configure_from_build(corrupt_build)
	_expect(not session.bind_character(corrupt_character), "Unaffordable restored allocation should reject binding")
	_expect(session.character == active_character and session.class_progression == active_progression, "Failed bind should preserve active character and progression service")
	_expect(session.inventory == active_inventory, "Failed progression bind should preserve active item systems")
	_expect(session.durable_snapshot() == active_snapshot, "Failed progression bind should preserve the full active durable snapshot")
	_expect(active_progression.award_applied.is_connected(session._on_class_point_awarded), "Failed bind should preserve progression signal wiring")
	session.queue_free()


func _new_state(class_id: String) -> ClassProgressionState:
	var catalog := ClassTreeCatalog.new()
	catalog.register_framework_proofs()
	var state := ClassProgressionState.new()
	_expect(state.configure(catalog.get_definition(class_id)), "Progression definition should configure")
	return state


func _on_point_awarded(_build_id: String, _source_id: String, _amount: int, available_points: int) -> void:
	point_event_count += 1
	last_point_total = available_points


func _cleanup_test_build(profile: ProfileData, build_id: String, previous_selected_build_id: String) -> void:
	if profile == null or build_id.is_empty():
		return
	_expect(SaveManager.delete_build(profile, build_id) == OK, "Progression test build should delete without touching unrelated saves")
	if not previous_selected_build_id.is_empty() and profile.build_ids.has(previous_selected_build_id):
		_expect(SaveManager.select_build(profile, previous_selected_build_id) == OK, "Progression test cleanup should restore the previously selected build")
	elif previous_selected_build_id.is_empty():
		profile.selected_build_id = ""
		_expect(SaveManager.save_profile(profile) == OK, "Progression test cleanup should restore an empty prior selection")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
