extends SceneTree

const ITEM_DEFINITION_SCRIPT := preload("res://scripts/runtime/items/item_definition.gd")
const ITEM_CATALOG_SCRIPT := preload("res://scripts/runtime/items/item_catalog.gd")
const ITEM_INSTANCE_SCRIPT := preload("res://scripts/runtime/items/item_instance.gd")
const INVENTORY_CONTAINER_SCRIPT := preload("res://scripts/runtime/items/inventory_container.gd")

var failures: Array[String] = []
var item_added_events := 0
var item_removed_events := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("START: Stages 3 and 4 catalog/inventory")
	_test_catalog_rejects_duplicates()
	_test_inventory_stacking_and_capacity_are_atomic()
	_test_partial_merge_failure_is_atomic()
	_test_identity_requirements_and_stack_splitting()
	_test_inventory_removal_and_round_trip()
	if failures.is_empty():
		print("PASS: Stages 3 and 4 catalog/inventory")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _make_definition(id: StringName, stack_size: int) -> Variant:
	var slots: Array[StringName] = []
	var modifiers: Array[Dictionary] = []
	var tags: Array[StringName] = []
	return ITEM_DEFINITION_SCRIPT.new(id, String(id), slots, stack_size, modifiers, tags)


func _identity(session_id: String) -> ItemIdentityService:
	var service := ItemIdentityService.new()
	_expect(service.configure(session_id), "Identity service %s should configure" % session_id)
	return service


func _item(definition_id: StringName, quantity: int, identity: ItemIdentityService) -> ItemInstance:
	var item := ITEM_INSTANCE_SCRIPT.new(definition_id, quantity)
	item.instance_id = identity.mint()
	return item


func _test_catalog_rejects_duplicates() -> void:
	var catalog: Variant = ITEM_CATALOG_SCRIPT.new()
	var shard: Variant = _make_definition(&"ember_shard", 20)
	_expect(bool(catalog.register(shard)), "Catalog should register a valid definition")
	_expect(not bool(catalog.register(shard)), "Catalog should reject duplicate definition IDs")
	var returned: Variant = catalog.get_definition(&"ember_shard")
	_expect(returned != null, "Catalog lookup should return a definition")
	_expect(returned != shard, "Catalog lookup should return a defensive copy")
	_expect(returned.to_read_only_dict() == shard.to_read_only_dict(), "Catalog lookup copy should preserve registered definition values")


func _test_inventory_stacking_and_capacity_are_atomic() -> void:
	var identity := _identity("stacking")
	var inventory: Variant = INVENTORY_CONTAINER_SCRIPT.new(1, identity)
	var definition: Variant = _make_definition(&"ember_shard", 20)
	var first := _item(&"ember_shard", 15, identity)
	var second := _item(&"ember_shard", 5, identity)
	_expect(bool(inventory.add_item(first, definition)), "First stack should be accepted")
	_expect(bool(inventory.add_item(second, definition)), "Compatible stack should merge even when slots are full")
	_expect(inventory.items.size() == 1 and inventory.items[0].quantity == 20, "Merged stack should preserve one slot and exact quantity")
	_expect(second.quantity == 0, "Fully merged incoming stack should be consumed")
	var overflow := _item(&"ember_shard", 1, identity)
	var before: Array[Dictionary] = inventory.serialize()
	_expect(not bool(inventory.add_item(overflow, definition)), "Full inventory should reject overflow atomically")
	_expect(inventory.serialize() == before, "Rejected add must not mutate inventory")
	_expect(overflow.quantity == 1, "Rejected add must not mutate incoming quantity")


func _test_partial_merge_failure_is_atomic() -> void:
	var identity := _identity("partial-failure")
	var definition: Variant = _make_definition(&"ember_shard", 20)
	var inventory: Variant = INVENTORY_CONTAINER_SCRIPT.new(1, identity)
	inventory.item_added.connect(_on_item_added)
	inventory.item_removed.connect(_on_item_removed)
	var existing := _item(&"ember_shard", 19, identity)
	_expect(bool(inventory.add_item(existing, definition)), "Partial-failure source stack should enter inventory")
	item_added_events = 0
	item_removed_events = 0
	var incoming := _item(&"ember_shard", 5, identity)
	var before: Array[Dictionary] = inventory.serialize()
	_expect(not bool(inventory.add_item(incoming, definition)), "A partial merge with no slot for the remainder must fail")
	_expect(inventory.serialize() == before, "Failed partial merge must preserve byte-equivalent inventory")
	_expect(existing.quantity == 19, "Failed partial merge must preserve existing quantity")
	_expect(incoming.quantity == 5, "Failed partial merge must preserve incoming quantity")
	_expect(item_added_events == 0 and item_removed_events == 0, "Failed partial merge must emit no inventory signals")

	var oversize := _item(&"ember_shard", 21, identity)
	var oversize_before: Array[Dictionary] = inventory.serialize()
	_expect(not bool(inventory.add_item(oversize, definition)), "Oversize single-stack payload should be rejected")
	_expect(inventory.serialize() == oversize_before and oversize.quantity == 21, "Oversize rejection must remain atomic")

	var fitting_inventory: Variant = INVENTORY_CONTAINER_SCRIPT.new(2, identity)
	var fitting_existing := _item(&"ember_shard", 19, identity)
	var fitting_incoming := _item(&"ember_shard", 5, identity)
	_expect(bool(fitting_inventory.add_item(fitting_existing, definition)), "Fitting source stack should enter inventory")
	_expect(bool(fitting_inventory.add_item(fitting_incoming, definition)), "Partial merge should succeed when the remainder has a slot")
	_expect(fitting_inventory.items.size() == 2, "Successful partial merge should use one existing and one new stack")
	_expect(fitting_existing.quantity == 20 and fitting_incoming.quantity == 4, "Successful partial merge should preserve exact quantities")


func _test_identity_requirements_and_stack_splitting() -> void:
	var definition: Variant = _make_definition(&"ember_shard", 20)
	var unminted := ITEM_INSTANCE_SCRIPT.new(&"ember_shard", 1)
	_expect(unminted.instance_id.is_empty(), "New ItemInstance should not fabricate an identity")
	var rejection_inventory: Variant = INVENTORY_CONTAINER_SCRIPT.new(2)
	_expect(not bool(rejection_inventory.add_item(unminted, definition)), "Inventory should reject an unminted item")
	var restored_unminted := ITEM_INSTANCE_SCRIPT.from_dict({"definition_id": "ember_shard", "quantity": 1})
	_expect(restored_unminted.instance_id.is_empty(), "Restoration without identity should remain unminted")

	var source_identity := _identity("split-source")
	var inventory_without_identity: Variant = INVENTORY_CONTAINER_SCRIPT.new(2)
	var unsplittable := _item(&"ember_shard", 7, source_identity)
	_expect(bool(inventory_without_identity.add_item(unsplittable, definition)), "Minted source stack should enter inventory without a split service")
	inventory_without_identity.item_removed.connect(_on_item_removed)
	item_removed_events = 0
	var before: Array[Dictionary] = inventory_without_identity.serialize()
	_expect(inventory_without_identity.remove_instance(unsplittable.instance_id, 3) == null, "Partial removal without identity service should fail")
	_expect(inventory_without_identity.serialize() == before, "Failed split should preserve original stack")
	_expect(item_removed_events == 0, "Failed split should emit no removal signal")

	var split_identity := _identity("split")
	var split_inventory: Variant = INVENTORY_CONTAINER_SCRIPT.new(2, split_identity)
	var splittable := _item(&"ember_shard", 7, split_identity)
	_expect(splittable.instance_id == "item:split:1", "Source stack should use first monotonic identity")
	_expect(bool(split_inventory.add_item(splittable, definition)), "Splittable stack should enter inventory")
	var removed: ItemInstance = split_inventory.remove_instance(splittable.instance_id, 3)
	_expect(removed != null and removed.quantity == 3, "Configured split should return requested quantity")
	if removed != null:
		_expect(removed.instance_id == "item:split:2", "Split should mint the next monotonic identity")
	_expect(split_inventory.items[0].quantity == 4, "Configured split should preserve exact remainder")
	var snapshot := split_identity.snapshot()
	_expect(int(snapshot.get("next_sequence", 0)) == 3, "Split should advance allocator exactly once")
	var disk_snapshot: Variant = JSON.parse_string(JSON.stringify(snapshot))
	var restored_identity := ItemIdentityService.new()
	_expect(disk_snapshot is Dictionary and restored_identity.configure("split", disk_snapshot), "Allocator snapshot should survive JSON round trip")
	_expect(restored_identity.mint() == "item:split:3", "JSON-restored allocator should continue at the next unused identity")


func _test_inventory_removal_and_round_trip() -> void:
	var identity := _identity("round-trip")
	var inventory: Variant = INVENTORY_CONTAINER_SCRIPT.new(2, identity)
	var definition: Variant = _make_definition(&"ember_shard", 20)
	var item := _item(&"ember_shard", 7, identity)
	var stable_id := item.instance_id
	_expect(bool(inventory.add_item(item, definition)), "Inventory should accept item")
	var removed: Variant = inventory.remove_instance(stable_id, 3)
	_expect(removed != null and removed.quantity == 3, "Partial removal should return requested quantity")
	_expect(inventory.items[0].quantity == 4, "Partial removal should leave exact remainder")
	var serialized: Array[Dictionary] = inventory.serialize()
	var restored: Variant = INVENTORY_CONTAINER_SCRIPT.new(2, identity)
	_expect(bool(restored.restore(serialized)), "Serialized inventory should restore")
	_expect(restored.items.size() == 1 and restored.items[0].instance_id == stable_id, "Round trip should preserve instance identity")
	var duplicate_payload: Array = serialized.duplicate(true)
	duplicate_payload.append(serialized[0].duplicate(true))
	_expect(not bool(restored.restore(duplicate_payload)), "Restore should reject duplicate instance IDs")
	_expect(restored.items.size() == 1 and restored.items[0].quantity == 4, "Failed restore must preserve previous inventory")


func _on_item_added(_item: ItemInstance) -> void:
	item_added_events += 1


func _on_item_removed(_item: ItemInstance) -> void:
	item_removed_events += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
