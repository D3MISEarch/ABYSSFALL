extends SceneTree

const ITEM_DEFINITION_SCRIPT := preload("res://scripts/runtime/items/item_definition.gd")
const ITEM_CATALOG_SCRIPT := preload("res://scripts/runtime/items/item_catalog.gd")
const ITEM_INSTANCE_SCRIPT := preload("res://scripts/runtime/items/item_instance.gd")
const INVENTORY_CONTAINER_SCRIPT := preload("res://scripts/runtime/items/inventory_container.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("START: Stages 3 and 4 catalog/inventory")
	_test_catalog_rejects_duplicates()
	_test_inventory_stacking_and_capacity_are_atomic()
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


func _test_catalog_rejects_duplicates() -> void:
	var catalog: Variant = ITEM_CATALOG_SCRIPT.new()
	var shard: Variant = _make_definition(&"ember_shard", 20)
	_expect(bool(catalog.register(shard)), "Catalog should register a valid definition")
	_expect(not bool(catalog.register(shard)), "Catalog should reject duplicate definition IDs")
	_expect(catalog.get_definition(&"ember_shard") == shard, "Catalog lookup should return the registered immutable definition")


func _test_inventory_stacking_and_capacity_are_atomic() -> void:
	var inventory: Variant = INVENTORY_CONTAINER_SCRIPT.new(1)
	var definition: Variant = _make_definition(&"ember_shard", 20)
	var first: Variant = ITEM_INSTANCE_SCRIPT.new(&"ember_shard", 15)
	first.instance_id = "shard-a"
	var second: Variant = ITEM_INSTANCE_SCRIPT.new(&"ember_shard", 5)
	second.instance_id = "shard-b"
	_expect(bool(inventory.add_item(first, definition)), "First stack should be accepted")
	_expect(bool(inventory.add_item(second, definition)), "Compatible stack should merge even when slots are full")
	_expect(inventory.items.size() == 1 and inventory.items[0].quantity == 20, "Merged stack should preserve one slot and exact quantity")
	var overflow: Variant = ITEM_INSTANCE_SCRIPT.new(&"ember_shard", 1)
	overflow.instance_id = "shard-c"
	_expect(not bool(inventory.add_item(overflow, definition)), "Full inventory should reject overflow atomically")
	_expect(inventory.items.size() == 1 and inventory.items[0].quantity == 20, "Rejected add must not mutate inventory")


func _test_inventory_removal_and_round_trip() -> void:
	var inventory: Variant = INVENTORY_CONTAINER_SCRIPT.new(2)
	var definition: Variant = _make_definition(&"ember_shard", 20)
	var item: Variant = ITEM_INSTANCE_SCRIPT.new(&"ember_shard", 7)
	item.instance_id = "stable-instance"
	_expect(bool(inventory.add_item(item, definition)), "Inventory should accept item")
	var removed: Variant = inventory.remove_instance("stable-instance", 3)
	_expect(removed != null and removed.quantity == 3, "Partial removal should return requested quantity")
	_expect(inventory.items[0].quantity == 4, "Partial removal should leave exact remainder")
	var serialized: Array[Dictionary] = inventory.serialize()
	var restored: Variant = INVENTORY_CONTAINER_SCRIPT.new(2)
	_expect(bool(restored.restore(serialized)), "Serialized inventory should restore")
	_expect(restored.items.size() == 1 and restored.items[0].instance_id == "stable-instance", "Round trip should preserve instance identity")
	var duplicate_payload: Array = serialized.duplicate(true)
	duplicate_payload.append(serialized[0].duplicate(true))
	_expect(not bool(restored.restore(duplicate_payload)), "Restore should reject duplicate instance IDs")
	_expect(restored.items.size() == 1 and restored.items[0].quantity == 4, "Failed restore must preserve previous inventory")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
