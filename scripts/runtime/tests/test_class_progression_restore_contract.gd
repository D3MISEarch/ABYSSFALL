extends SceneTree

var failures: Array[String] = []
var progression_state_events := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_case("definition identity and canonical restore", _test_definition_identity)
	_run_case("level award restoration validation", _test_level_award_validation)
	_run_case("bind reconciliation surfaces durable mutation", _test_bind_reconciliation_event)

	if failures.is_empty():
		print("PASS: Class progression restoration contract")
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


func _test_definition_identity() -> void:
	var state := _new_state()
	_expect(state.reconcile_level_awards(4) == 3, "Validation state should receive levels two through four")
	var live_snapshot := state.serialize()
	_expect(str(live_snapshot.get("definition_schema_id", "")) == "framework_proof_v1", "Serialized state should identify its immutable tree definition")
	_expect(int(live_snapshot.get("definition_schema_version", 0)) == 1, "Serialized state should identify its tree definition version")

	var wrong_schema_id := live_snapshot.duplicate(true)
	wrong_schema_id["definition_schema_id"] = "another_tree"
	_expect(not state.restore(wrong_schema_id, 4), "A different tree schema identity must reject restoration")
	_expect(state.serialize() == live_snapshot, "Schema-identity rejection must preserve live progression")

	var wrong_schema_version := live_snapshot.duplicate(true)
	wrong_schema_version["definition_schema_version"] = 2
	_expect(not state.restore(wrong_schema_version, 4), "A different tree definition version must reject restoration")
	_expect(state.serialize() == live_snapshot, "Definition-version rejection must preserve live progression")

	var unaffordable := live_snapshot.duplicate(true)
	unaffordable["award_ledger"] = {}
	unaffordable["allocations"] = {"proof_origin": 1}
	_expect(not state.restore(unaffordable, 4), "An allocation without awarded points must reject restoration")
	_expect(state.serialize() == live_snapshot, "Affordability rejection must preserve live progression")

	var fractional_rank := live_snapshot.duplicate(true)
	fractional_rank["allocations"] = {"proof_origin": 0.5}
	_expect(not state.restore(fractional_rank, 4), "Fractional allocation ranks must reject restoration")
	_expect(state.serialize() == live_snapshot, "Fractional-rank rejection must preserve live progression")


func _test_level_award_validation() -> void:
	var state := _new_state()
	_expect(state.reconcile_level_awards(4) == 3, "Level-source validation should begin from a canonical ledger")
	var live_snapshot := state.serialize()

	var future_level := live_snapshot.duplicate(true)
	future_level["award_ledger"] = future_level["award_ledger"].duplicate(true)
	future_level["award_ledger"]["level:99"] = 1
	_expect(not state.restore(future_level, 4), "A level source above the character's reached level must reject restoration")
	_expect(state.serialize() == live_snapshot, "Future-level rejection must preserve live progression")

	var wrong_level_amount := live_snapshot.duplicate(true)
	wrong_level_amount["award_ledger"] = wrong_level_amount["award_ledger"].duplicate(true)
	wrong_level_amount["award_ledger"]["level:3"] = 2
	_expect(not state.restore(wrong_level_amount, 4), "A level source must match the definition's authored award amount")
	_expect(state.serialize() == live_snapshot, "Wrong-award rejection must preserve live progression")

	var noncanonical_source := live_snapshot.duplicate(true)
	noncanonical_source["award_ledger"] = noncanonical_source["award_ledger"].duplicate(true)
	noncanonical_source["award_ledger"]["level:03"] = 1
	_expect(not state.restore(noncanonical_source, 4), "Noncanonical level source IDs must reject restoration")
	_expect(state.serialize() == live_snapshot, "Noncanonical-source rejection must preserve live progression")

	var fractional_amount := live_snapshot.duplicate(true)
	fractional_amount["award_ledger"] = fractional_amount["award_ledger"].duplicate(true)
	fractional_amount["award_ledger"]["trial:fractional"] = 1.5
	_expect(not state.restore(fractional_amount, 4), "Fractional award amounts must reject restoration")
	_expect(state.serialize() == live_snapshot, "Fractional-award rejection must preserve live progression")


func _test_bind_reconciliation_event() -> void:
	progression_state_events = 0
	var build := BuildData.create_new(ClassIds.VOID_WARLOCK, "Backfill Event")
	build.level = 6
	var character := RuntimeCharacter.new()
	character.configure_from_build(build)
	var session := RuntimeSession.new()
	root.add_child(session)
	session.event_bus.runtime_state_changed.connect(_on_runtime_state_changed)
	_expect(session.bind_character(character), "A pre-feature leveled build should bind")
	_expect(session.class_progression.available_points() == 5, "Binding should backfill every reached level source")
	_expect(progression_state_events == 1, "Backfill should surface one durable class-progression state change after commit")

	var durable := session.durable_snapshot()
	var restored_build := BuildData.from_dict(build.to_dict())
	restored_build.level = int(durable.get("level", restored_build.level))
	restored_build.experience = int(durable.get("experience", restored_build.experience))
	restored_build.class_tree_state = durable.get("class_tree_state", {}).duplicate(true)
	var restored_character := RuntimeCharacter.new()
	restored_character.configure_from_build(restored_build)
	var restored_session := RuntimeSession.new()
	root.add_child(restored_session)
	progression_state_events = 0
	restored_session.event_bus.runtime_state_changed.connect(_on_runtime_state_changed)
	_expect(restored_session.bind_character(restored_character), "A fully reconciled durable build should rebind")
	_expect(progression_state_events == 0, "A fully reconciled rebind must not report a false durable mutation")

	session.queue_free()
	restored_session.queue_free()


func _new_state() -> ClassProgressionState:
	var catalog := ClassTreeCatalog.new()
	_expect(catalog.register_framework_proofs(), "Framework proof catalog should register")
	var state := ClassProgressionState.new()
	_expect(state.configure(catalog.get_definition(ClassIds.VOID_WARLOCK)), "Framework proof state should configure")
	return state


func _on_runtime_state_changed(_build_id: String, reason: StringName) -> void:
	if reason == &"class_progression":
		progression_state_events += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
