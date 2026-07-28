extends SceneTree

const VOID_WARLOCK_SCRIPT = preload("res://scripts/characters/void_warlock.gd")
const PENITENT_SCRIPT = preload("res://scripts/characters/penitent_playable.gd")
const PROGRESSION_BRIDGE_SCRIPT = preload("res://scripts/ui/playable_progression_bridge.gd")
const INVENTORY_BRIDGE_SCRIPT = preload("res://scripts/ui/playable_inventory_bridge.gd")
const PLAYABLE_ITEM_CATALOG = preload("res://scripts/core/playable_item_catalog.gd")
const ITEM_PICKUP_SCRIPT = preload("res://scripts/item_pickup.gd")
const INVENTORY_FOCUS_HARNESS = preload("res://tests/playable_inventory_focus_harness.gd")

class RejectingTarget:
	extends Node3D

	func try_add_item(_item: Dictionary) -> bool:
		return false

class InventoryFocusPlayer:
	extends Node

	signal inventory_changed

	var backpack: Array[Dictionary] = []

	func get_inventory_snapshot() -> Dictionary:
		return {
			"equipment": {
				"Weapon": {},
				"Hood": {},
				"Chest": {},
				"Gloves": {},
				"Boots": {},
				"Relic": {},
			},
			"backpack": backpack.duplicate(true),
			"capacity": 12,
		}

	func equip_inventory_index(index: int) -> void:
		if index < 0 or index >= backpack.size():
			return
		backpack.remove_at(index)
		inventory_changed.emit()

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_pickup_policy_swap_and_failure_atomicity()
	_test_both_playable_classes_use_authoritative_inventory()
	_test_rejected_world_pickup_remains()
	await _test_controller_focus_survives_inventory_refresh()
	_test_real_disk_round_trip_preserves_items_and_canary()
	if failures.is_empty():
		print("PASS: Player-controlled durable inventory")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_pickup_policy_swap_and_failure_atomicity() -> void:
	var build := BuildData.create_new(ClassIds.VOID_WARLOCK, "Inventory Policy")
	var bridges := _create_ephemeral_bridges(build)
	var progression: PlayableProgressionBridge = bridges.get("progression")
	var inventory_bridge: PlayableInventoryBridge = bridges.get("inventory")
	if progression == null or inventory_bridge == null:
		return

	var first_drop := PLAYABLE_ITEM_CATALOG.item_data(&"void_scepter")
	var first_result := inventory_bridge.collect_drop(first_drop)
	_expect(bool(first_result.get("success", false)), "First playable drop should enter the authoritative inventory")
	var first_snapshot := inventory_bridge.snapshot()
	_expect(_equipment_item(first_snapshot, "Weapon").is_empty(), "An empty weapon slot must not auto-equip the first drop")
	_expect(_backpack(first_snapshot).size() == 1, "First drop should remain in the backpack")
	var first_instance_id := str((_backpack(first_snapshot)[0] as Dictionary).get("instance_id", ""))
	_expect(not first_instance_id.is_empty(), "Stored drop should receive a stable physical identity")

	var first_equip := inventory_bridge.equip_inventory_index(0)
	_expect(bool(first_equip.get("success", false)), "Explicit player equip should succeed")
	var equipped_snapshot := inventory_bridge.snapshot()
	_expect(str(_equipment_item(equipped_snapshot, "Weapon").get("instance_id", "")) == first_instance_id, "Explicit equip should preserve the physical item identity")
	_expect(_backpack(equipped_snapshot).is_empty(), "Equipping into an empty slot should remove the item from backpack")

	var second_result := inventory_bridge.collect_drop(PLAYABLE_ITEM_CATALOG.item_data(&"bonebound_grimoire"))
	_expect(bool(second_result.get("success", false)), "Second weapon should enter backpack instead of replacing equipped gear")
	var second_instance_id := str((second_result.get("item", {}) as Dictionary).get("instance_id", ""))
	var swap_result := inventory_bridge.equip_inventory_index(0)
	_expect(bool(swap_result.get("success", false)), "Explicit weapon swap should succeed")
	var swapped := inventory_bridge.snapshot()
	_expect(str(_equipment_item(swapped, "Weapon").get("instance_id", "")) == second_instance_id, "Swap should equip the selected physical item")
	var swapped_backpack := _backpack(swapped)
	_expect(swapped_backpack.size() == 1 and str((swapped_backpack[0] as Dictionary).get("instance_id", "")) == first_instance_id, "Swap should return the previous physical item to backpack")

	var currency_slots: Array[StringName] = []
	_expect(progression.session.item_catalog.register(ItemDefinition.new(&"test_non_equipment", "Test Non Equipment", currency_slots, 1)), "Test should register a non-equipment definition")
	var non_equipment := ItemInstance.new(&"test_non_equipment", 1)
	non_equipment.instance_id = progression.session.item_identity.mint()
	_expect(progression.session.inventory.add_item(non_equipment, progression.session.item_catalog.get_definition(&"test_non_equipment")), "Test non-equipment item should enter inventory")
	var inventory_before := JSON.stringify(progression.session.inventory.serialize())
	var equipment_before := JSON.stringify(progression.session.equipment.serialize())
	var invalid_equip := inventory_bridge.equip_inventory_index(progression.session.inventory.items.size() - 1)
	_expect(not bool(invalid_equip.get("success", false)), "A non-equipment item should be rejected by the equip transaction")
	_expect(JSON.stringify(progression.session.inventory.serialize()) == inventory_before, "Failed equip must leave inventory unchanged")
	_expect(JSON.stringify(progression.session.equipment.serialize()) == equipment_before, "Failed equip must leave equipment unchanged")

	while progression.session.inventory.items.size() < progression.session.inventory.capacity:
		var fill_result := inventory_bridge.collect_drop(PLAYABLE_ITEM_CATALOG.item_data(&"riftwalker_greaves"))
		if not bool(fill_result.get("success", false)):
			break
	var full_before := JSON.stringify(inventory_bridge.snapshot())
	var rejected := inventory_bridge.collect_drop(PLAYABLE_ITEM_CATALOG.item_data(&"graven_crown"))
	_expect(not bool(rejected.get("success", false)) and StringName(str(rejected.get("reason", &""))) == &"inventory_full", "A full backpack should reject the incoming drop explicitly")
	_expect(JSON.stringify(inventory_bridge.snapshot()) == full_before, "Full-backpack rejection must not delete or mutate any owned item")

	inventory_bridge.queue_free()
	progression.queue_free()


func _test_both_playable_classes_use_authoritative_inventory() -> void:
	var cases := [
		{"script": VOID_WARLOCK_SCRIPT, "class_id": ClassIds.VOID_WARLOCK, "label": "Void Warlock"},
		{"script": PENITENT_SCRIPT, "class_id": ClassIds.PENITENT, "label": "Penitent"},
	]
	for test_case: Dictionary in cases:
		var build := BuildData.create_new(str(test_case.get("class_id", "")), "%s Inventory" % str(test_case.get("label", "")))
		var bridges := _create_ephemeral_bridges(build)
		var progression: PlayableProgressionBridge = bridges.get("progression")
		var inventory_bridge: PlayableInventoryBridge = bridges.get("inventory")
		if progression == null or inventory_bridge == null:
			continue
		var character_script := test_case.get("script") as Script
		var character = character_script.new()
		_expect(CharacterContract.is_valid_character(character), "%s should satisfy the durable playable contract" % str(test_case.get("label", "")))
		_expect(character.bind_playable_inventory_bridge(inventory_bridge), "%s should bind the shared authoritative inventory bridge" % str(test_case.get("label", "")))
		_expect(character.try_add_item(PLAYABLE_ITEM_CATALOG.item_data(&"void_scepter")), "%s should accept a pickup through the shared bridge" % str(test_case.get("label", "")))
		var stored: Dictionary = character.get_inventory_snapshot()
		_expect(_equipment_item(stored, "Weapon").is_empty(), "%s should never auto-equip the first pickup" % str(test_case.get("label", "")))
		_expect(_backpack(stored).size() == 1, "%s should store the first pickup in backpack" % str(test_case.get("label", "")))
		character.equip_inventory_index(0)
		var equipped: Dictionary = character.get_inventory_snapshot()
		_expect(not _equipment_item(equipped, "Weapon").is_empty(), "%s should equip only after explicit selection" % str(test_case.get("label", "")))
		character.free()
		inventory_bridge.queue_free()
		progression.queue_free()


func _test_rejected_world_pickup_remains() -> void:
	var target := RejectingTarget.new()
	root.add_child(target)
	var pickup = ITEM_PICKUP_SCRIPT.new()
	pickup.setup(target, PLAYABLE_ITEM_CATALOG.item_data(&"graven_crown"))
	root.add_child(pickup)
	target.global_position = Vector3.ZERO
	pickup.global_position = Vector3.ZERO
	pickup.age = pickup.magnet_delay
	pickup._process(0.1)
	_expect(not pickup.is_queued_for_deletion(), "A rejected full-backpack pickup must remain in the world")
	pickup.free()
	target.free()


func _test_controller_focus_survives_inventory_refresh() -> void:
	var harness = INVENTORY_FOCUS_HARNESS.new()
	root.add_child(harness)
	var player := InventoryFocusPlayer.new()
	player.backpack = [
		PLAYABLE_ITEM_CATALOG.item_data(&"void_scepter"),
		PLAYABLE_ITEM_CATALOG.item_data(&"bonebound_grimoire"),
	]
	harness.add_child(player)
	harness.player = player
	harness.inventory_panel = Control.new()
	harness.add_child(harness.inventory_panel)
	harness.inventory_equipment_box = VBoxContainer.new()
	harness.inventory_panel.add_child(harness.inventory_equipment_box)
	harness.inventory_backpack_box = VBoxContainer.new()
	harness.inventory_panel.add_child(harness.inventory_backpack_box)
	harness.equipment_summary_label = Label.new()
	harness.inventory_panel.add_child(harness.equipment_summary_label)
	player.inventory_changed.connect(harness._refresh_inventory)
	harness.inventory_panel.visible = true
	harness._refresh_inventory()
	await process_frame
	await process_frame
	_expect(harness.inventory_item_buttons.size() == 2, "Controller inventory test should build two focusable item buttons")
	if harness.inventory_item_buttons.size() == 2:
		_expect(harness.inventory_item_buttons[0].has_focus(), "Opening inventory should focus the first backpack item for controller input")
		harness.inventory_item_buttons[0].pressed.emit()
		await process_frame
		await process_frame
		_expect(harness.inventory_item_buttons.size() == 1, "Explicit equip should rebuild the backpack after removing the selected item")
		if harness.inventory_item_buttons.size() == 1:
			_expect(harness.inventory_item_buttons[0].has_focus(), "Inventory refresh after equip should preserve a valid controller focus target")
	harness.free()


func _test_real_disk_round_trip_preserves_items_and_canary() -> void:
	var service := PersistenceService.new()
	_expect(service.initialize("Playable Inventory Disk Tester"), "Inventory disk test service should initialize")
	if service.profile == null:
		service.free()
		return
	var previous_selection := service.profile.selected_build_id
	var canary := service.create_and_select_build(ClassIds.PENITENT, "Inventory Canary %s" % str(Time.get_ticks_usec()))
	_expect(canary != null, "Inventory disk test should create an isolated canary build")
	if canary == null:
		_restore_previous_selection(service.profile, previous_selection)
		service.free()
		return
	var canary_id := canary.build_id
	canary.statistics["inventory_canary"] = "DO_NOT_TOUCH"
	_expect(SaveManager.save_build(canary) == OK, "Canary build should save its marker")

	var test_build := service.create_and_select_build(ClassIds.VOID_WARLOCK, "Inventory Disk %s" % str(Time.get_ticks_usec()))
	_expect(test_build != null, "Inventory disk test should create an isolated target build")
	if test_build == null:
		SaveManager.delete_build(service.profile, canary_id)
		_restore_previous_selection(service.profile, previous_selection)
		service.free()
		return
	var test_build_id := test_build.build_id

	var first := _create_persistent_bridges(service)
	var first_progression: PlayableProgressionBridge = first.get("progression")
	var first_inventory: PlayableInventoryBridge = first.get("inventory")
	if first_progression == null or first_inventory == null:
		_cleanup_disk_test(service, test_build_id, canary_id, previous_selection)
		return
	_expect(bool(first_inventory.collect_drop(PLAYABLE_ITEM_CATALOG.item_data(&"void_scepter")).get("success", false)), "Disk test should store the first weapon")
	_expect(bool(first_inventory.equip_inventory_index(0).get("success", false)), "Disk test should explicitly equip the first weapon")
	_expect(bool(first_inventory.collect_drop(PLAYABLE_ITEM_CATALOG.item_data(&"bonebound_grimoire")).get("success", false)), "Disk test should store a second weapon")
	_expect(bool(first_inventory.collect_drop(PLAYABLE_ITEM_CATALOG.item_data(&"riftwalker_greaves")).get("success", false)), "Disk test should store boots")
	_expect(bool(first_inventory.equip_inventory_index(1).get("success", false)), "Disk test should equip boots while retaining the second weapon")
	var before := first_inventory.snapshot()
	var before_json := JSON.stringify(before)
	var before_ids := _all_instance_ids(before)
	_expect(before_ids.size() == 3, "Disk test should own three distinct physical items before reload")
	_expect(first_inventory.flush("playable_inventory_disk_round_trip") == OK, "Inventory disk test should flush exact durable state")

	var restored_service := PersistenceService.new()
	_expect(restored_service.initialize("Playable Inventory Disk Tester"), "Reload service should initialize from real disk data")
	var restored := _create_persistent_bridges(restored_service)
	var restored_progression: PlayableProgressionBridge = restored.get("progression")
	var restored_inventory: PlayableInventoryBridge = restored.get("inventory")
	if restored_progression != null and restored_inventory != null:
		var after := restored_inventory.snapshot()
		_expect(JSON.stringify(after) == before_json, "Real disk reload should restore identical equipment slots, backpack order, and item data")
		_expect(_all_instance_ids(after) == before_ids, "Real disk reload should preserve every physical item identity exactly")
		var new_drop := restored_inventory.collect_drop(PLAYABLE_ITEM_CATALOG.item_data(&"gravegrip_wraps"))
		_expect(bool(new_drop.get("success", false)), "Allocator should mint a new item after reload")
		var new_id := str((new_drop.get("item", {}) as Dictionary).get("instance_id", ""))
		_expect(not new_id.is_empty() and not before_ids.has(new_id), "Reloaded allocator must continue without colliding with restored identities")

	var canary_after := SaveManager.load_build(canary_id)
	_expect(canary_after != null and str(canary_after.statistics.get("inventory_canary", "")) == "DO_NOT_TOUCH", "Inventory test must preserve the unrelated canary build")

	first_inventory.queue_free()
	first_progression.queue_free()
	if restored_inventory != null:
		restored_inventory.queue_free()
	if restored_progression != null:
		restored_progression.queue_free()
	restored_service.free()
	_cleanup_disk_test(service, test_build_id, canary_id, previous_selection)


func _create_ephemeral_bridges(build: BuildData) -> Dictionary:
	var progression := PROGRESSION_BRIDGE_SCRIPT.new() as PlayableProgressionBridge
	root.add_child(progression)
	if not progression.configure_ephemeral(build):
		_expect(false, "Ephemeral progression bridge should bind")
		progression.queue_free()
		return {}
	var inventory_bridge := INVENTORY_BRIDGE_SCRIPT.new() as PlayableInventoryBridge
	root.add_child(inventory_bridge)
	if not inventory_bridge.configure(progression):
		_expect(false, "Ephemeral inventory bridge should bind the existing runtime session")
		inventory_bridge.queue_free()
		progression.queue_free()
		return {}
	return {"progression": progression, "inventory": inventory_bridge}


func _create_persistent_bridges(service: PersistenceService) -> Dictionary:
	var progression := PROGRESSION_BRIDGE_SCRIPT.new() as PlayableProgressionBridge
	root.add_child(progression)
	if not progression.configure_persistent(ClassIds.VOID_WARLOCK, service, "Unused"):
		_expect(false, "Persistent progression bridge should bind the selected inventory test build")
		progression.queue_free()
		return {}
	var inventory_bridge := INVENTORY_BRIDGE_SCRIPT.new() as PlayableInventoryBridge
	root.add_child(inventory_bridge)
	if not inventory_bridge.configure(progression):
		_expect(false, "Persistent inventory bridge should bind the existing runtime session")
		inventory_bridge.queue_free()
		progression.queue_free()
		return {}
	return {"progression": progression, "inventory": inventory_bridge}


func _equipment_item(snapshot: Dictionary, slot: String) -> Dictionary:
	var equipment: Dictionary = snapshot.get("equipment", {})
	var item: Variant = equipment.get(slot, {})
	if item is Dictionary:
		return item
	return {}


func _backpack(snapshot: Dictionary) -> Array:
	var stored: Variant = snapshot.get("backpack", [])
	if stored is Array:
		return stored
	return []


func _all_instance_ids(snapshot: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var equipment: Dictionary = snapshot.get("equipment", {})
	var slots := equipment.keys()
	slots.sort()
	for raw_slot: Variant in slots:
		var item: Dictionary = equipment.get(raw_slot, {})
		var instance_id := str(item.get("instance_id", ""))
		if not instance_id.is_empty():
			result.append(instance_id)
	for raw_item: Variant in snapshot.get("backpack", []):
		if raw_item is Dictionary:
			var instance_id := str(raw_item.get("instance_id", ""))
			if not instance_id.is_empty():
				result.append(instance_id)
	result.sort()
	return result


func _cleanup_disk_test(service: PersistenceService, test_build_id: String, canary_id: String, previous_selection: String) -> void:
	_expect(SaveManager.delete_build(service.profile, test_build_id) == OK, "Inventory disk test should delete only its target build")
	_expect(SaveManager.delete_build(service.profile, canary_id) == OK, "Inventory disk test should delete only its generated canary")
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
