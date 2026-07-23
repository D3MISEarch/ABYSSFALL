extends SceneTree

var failures: Array[String] = []
var session_one_events := 0
var session_two_events := 0
var rebound_state_events := 0
var rebound_level_events := 0
var last_rebound_state_build_id := ""
var last_rebound_level_build_id := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_cross_session_isolation()
	_test_rebind_disconnects_previous_character()
	_test_failed_rebind_preserves_active_session()

	if failures.is_empty():
		print("PASS: RuntimeSession event bus isolation and rebinding")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_cross_session_isolation() -> void:
	var build_one := BuildData.create_new(ClassIds.PENITENT, "First")
	var build_two := BuildData.create_new(ClassIds.VOID_WARLOCK, "Second")
	var character_one := RuntimeCharacter.new()
	var character_two := RuntimeCharacter.new()
	character_one.configure_from_build(build_one)
	character_two.configure_from_build(build_two)

	var session_one := RuntimeSession.new()
	var session_two := RuntimeSession.new()
	root.add_child(session_one)
	root.add_child(session_two)
	session_one.event_bus.runtime_state_changed.connect(_on_session_one_event)
	session_two.event_bus.runtime_state_changed.connect(_on_session_two_event)
	session_one.bind_character(character_one)
	session_two.bind_character(character_two)

	character_one.gain_experience(10)
	_expect(session_one_events == 1, "Session one should receive its character event")
	_expect(session_two_events == 0, "Session two must not receive session one events")
	character_two.gain_experience(10)
	_expect(session_one_events == 1, "Session one must not receive session two events")
	_expect(session_two_events == 1, "Session two should receive its character event")

	session_one.queue_free()
	session_two.queue_free()


func _test_rebind_disconnects_previous_character() -> void:
	var build_a := BuildData.create_new(ClassIds.PENITENT, "Rebind A")
	var build_b := BuildData.create_new(ClassIds.VOID_WARLOCK, "Rebind B")
	var character_a := RuntimeCharacter.new()
	var character_b := RuntimeCharacter.new()
	character_a.configure_from_build(build_a)
	character_b.configure_from_build(build_b)

	var session := RuntimeSession.new()
	root.add_child(session)
	session.event_bus.runtime_state_changed.connect(_on_rebound_state_event)
	session.event_bus.level_gained.connect(_on_rebound_level_event)

	session.bind_character(character_a)
	var inventory_a := session.inventory
	var equipment_a := session.equipment
	character_a.state_changed.emit(&"before_rebind")
	character_a.level_gained.emit(2)
	_expect(rebound_state_events == 1, "Character A state event should reach the bus before rebinding")
	_expect(rebound_level_events == 1, "Character A level event should reach the bus before rebinding")
	_expect(last_rebound_state_build_id == character_a.build_id, "Pre-rebind state event should use character A build ID")
	_expect(last_rebound_level_build_id == character_a.build_id, "Pre-rebind level event should use character A build ID")

	session.bind_character(character_b)
	_expect(not character_a.state_changed.is_connected(session._on_character_state_changed), "Character A state signal should be disconnected after rebinding")
	_expect(not character_a.level_gained.is_connected(session._on_character_level_gained), "Character A level signal should be disconnected after rebinding")
	_expect(character_b.state_changed.is_connected(session._on_character_state_changed), "Character B state signal should be connected after rebinding")
	_expect(character_b.level_gained.is_connected(session._on_character_level_gained), "Character B level signal should be connected after rebinding")
	_expect(not inventory_a.item_added.is_connected(session._on_inventory_changed), "Character A inventory add signal should be disconnected after rebinding")
	_expect(not inventory_a.item_removed.is_connected(session._on_inventory_changed), "Character A inventory remove signal should be disconnected after rebinding")
	_expect(not equipment_a.equipment_changed.is_connected(session._on_equipment_changed), "Character A equipment signal should be disconnected after rebinding")
	_expect(session.inventory.item_added.is_connected(session._on_inventory_changed), "Character B inventory add signal should be connected after rebinding")
	_expect(session.inventory.item_removed.is_connected(session._on_inventory_changed), "Character B inventory remove signal should be connected after rebinding")
	_expect(session.equipment.equipment_changed.is_connected(session._on_equipment_changed), "Character B equipment signal should be connected after rebinding")

	character_a.state_changed.emit(&"stale_state")
	character_a.level_gained.emit(3)
	var probe_item := ItemInstance.new(&"rebind_probe", 1)
	inventory_a.item_added.emit(probe_item)
	inventory_a.item_removed.emit(probe_item)
	equipment_a.equipment_changed.emit(&"main_hand", probe_item, null)
	_expect(rebound_state_events == 1, "Character A character and item-system events must not leak after rebinding")
	_expect(rebound_level_events == 1, "Character A level event must not leak after rebinding")

	session.inventory.item_added.emit(probe_item)
	session.equipment.equipment_changed.emit(&"main_hand", probe_item, null)
	_expect(rebound_state_events == 3, "Character B item-system events should reach the bus after rebinding")
	_expect(last_rebound_state_build_id == character_b.build_id, "Active item-system events should use character B build ID")

	character_b.state_changed.emit(&"active_state")
	character_b.level_gained.emit(4)
	_expect(rebound_state_events == 4, "Character B state event should reach the bus after rebinding")
	_expect(rebound_level_events == 2, "Character B level event should reach the bus after rebinding")
	_expect(last_rebound_state_build_id == character_b.build_id, "Post-rebind state event should use character B build ID")
	_expect(last_rebound_level_build_id == character_b.build_id, "Post-rebind level event should use character B build ID")

	session.queue_free()


func _test_failed_rebind_preserves_active_session() -> void:
	var session := RuntimeSession.new()
	root.add_child(session)
	var slots: Array[StringName] = [&"head"]
	var modifiers: Array[Dictionary] = [{"stat_id": "armor", "operation": StatModifier.Operation.FLAT, "value": 12.0}]
	_expect(session.item_catalog.register(ItemDefinition.new(&"ashen_hood", "Ashen Hood", slots, 1, modifiers)), "Transactional rebind item definition should register")

	var active_build := BuildData.create_new(ClassIds.PENITENT, "Active")
	var active_character := RuntimeCharacter.new()
	active_character.configure_from_build(active_build)
	_expect(session.bind_character(active_character), "Initial character should bind")
	var active_inventory := session.inventory
	var active_equipment := session.equipment
	var active_identity := session.item_identity
	var active_identity_snapshot := active_identity.snapshot()
	var active_stats := active_character.stats.snapshot()

	var corrupt_build := BuildData.create_new(ClassIds.PENITENT, "Corrupt")
	var collision_item := ItemInstance.new(&"ashen_hood")
	collision_item.instance_id = "malformed-shared-id"
	corrupt_build.build_specific_progress = {"inventory": [collision_item.to_dict()]}
	corrupt_build.equipped_gear = {"head": collision_item.to_dict()}
	var corrupt_character := RuntimeCharacter.new()
	corrupt_character.configure_from_build(corrupt_build)
	_expect(not session.bind_character(corrupt_character), "Cross-container identity collision should reject binding")
	_expect(session.character == active_character, "Failed rebind must preserve active character")
	_expect(session.inventory == active_inventory and session.equipment == active_equipment, "Failed rebind must preserve active item-system references")
	_expect(session.item_identity == active_identity and session.item_identity.snapshot() == active_identity_snapshot, "Failed rebind must preserve active identity allocator")
	_expect(active_character.stats.snapshot() == active_stats, "Failed rebind must preserve active character stats")
	_expect(corrupt_character.inventory == null and corrupt_character.equipment == null, "Rejected character must not receive partial item systems")
	_expect(active_character.state_changed.is_connected(session._on_character_state_changed), "Failed rebind must preserve active signal connections")
	_expect(active_inventory.item_added.is_connected(session._on_inventory_changed), "Failed rebind must preserve active inventory signals")

	var corrected_build := BuildData.create_new(ClassIds.PENITENT, "Corrected")
	var corrected_identity := ItemIdentityService.new()
	_expect(corrected_identity.configure(corrected_build.build_id), "Corrected identity service should configure")
	var inventory_item := ItemInstance.new(&"ashen_hood")
	inventory_item.instance_id = corrected_identity.mint()
	var equipped_item := ItemInstance.new(&"ashen_hood")
	equipped_item.instance_id = corrected_identity.mint()
	corrected_build.build_specific_progress = {
		"inventory": [inventory_item.to_dict()],
		"item_identity": corrected_identity.snapshot(),
	}
	corrected_build.equipped_gear = {"head": equipped_item.to_dict()}
	var corrected_character := RuntimeCharacter.new()
	corrected_character.configure_from_build(corrected_build)
	_expect(session.bind_character(corrected_character), "Disjoint inventory and equipment identities should bind")
	_expect(session.character == corrected_character, "Corrected character should become active")
	_expect(session.inventory.items.size() == 1 and session.equipment.equipped.has(&"head"), "Corrected bind should restore both ownership containers")
	_expect(session.inventory.items[0].instance_id != session.equipment.equipped[&"head"].instance_id, "Corrected ownership must remain globally disjoint")
	_expect(is_equal_approx(corrected_character.stats.get_value(&"armor"), 12.0), "Corrected bind should apply restored equipment modifiers")

	session.queue_free()


func _on_session_one_event(_build_id: String, _reason: StringName) -> void:
	session_one_events += 1


func _on_session_two_event(_build_id: String, _reason: StringName) -> void:
	session_two_events += 1


func _on_rebound_state_event(build_id: String, _reason: StringName) -> void:
	rebound_state_events += 1
	last_rebound_state_build_id = build_id


func _on_rebound_level_event(build_id: String, _new_level: int) -> void:
	rebound_level_events += 1
	last_rebound_level_build_id = build_id


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
