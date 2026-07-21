class_name InventoryContainer
extends RefCounted

signal item_added(item: ItemInstance)
signal item_removed(item: ItemInstance)

var capacity: int = 24
var items: Array[ItemInstance] = []


func _init(p_capacity: int = 24) -> void:
	capacity = maxi(1, p_capacity)


func add_item(item: ItemInstance, definition: ItemDefinition) -> bool:
	if item == null or definition == null:
		return false
	if item.definition_id != definition.definition_id:
		return false
	if definition.max_stack > 1:
		for existing: ItemInstance in items:
			if existing.definition_id != item.definition_id:
				continue
			if existing.affixes != item.affixes or existing.durability != item.durability:
				continue
			var available: int = definition.max_stack - existing.quantity
			if available <= 0:
				continue
			var moved: int = mini(available, item.quantity)
			existing.quantity += moved
			item.quantity -= moved
			if item.quantity <= 0:
				item_added.emit(existing)
				return true
	if items.size() >= capacity:
		return false
	item.quantity = mini(item.quantity, definition.max_stack)
	items.append(item)
	item_added.emit(item)
	return true


func remove_instance(instance_id: String, quantity: int = 1) -> ItemInstance:
	if quantity <= 0:
		return null
	for index: int in items.size():
		var existing: ItemInstance = items[index]
		if existing.instance_id != instance_id:
			continue
		if quantity >= existing.quantity:
			items.remove_at(index)
			item_removed.emit(existing)
			return existing
		var removed := ItemInstance.from_dict(existing.to_dict())
		removed.instance_id = "%s:split:%s" % [existing.instance_id, existing.quantity - quantity]
		removed.quantity = quantity
		existing.quantity -= quantity
		item_removed.emit(removed)
		return removed
	return null


func has_instance(instance_id: String) -> bool:
	return find_instance(instance_id) != null


func find_instance(instance_id: String) -> ItemInstance:
	for item: ItemInstance in items:
		if item.instance_id == instance_id:
			return item
	return null


func serialize() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: ItemInstance in items:
		result.append(item.to_dict())
	return result


func restore(serialized_items: Array) -> bool:
	var restored: Array[ItemInstance] = []
	var seen_ids: Dictionary = {}
	if serialized_items.size() > capacity:
		return false
	for raw_item: Variant in serialized_items:
		if not raw_item is Dictionary:
			return false
		var item := ItemInstance.from_dict(raw_item)
		if item.instance_id.is_empty() or seen_ids.has(item.instance_id):
			return false
		seen_ids[item.instance_id] = true
		restored.append(item)
	items = restored
	return true
