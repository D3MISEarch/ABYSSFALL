class_name InventoryContainer
extends RefCounted

signal item_added(item: ItemInstance)
signal item_removed(item: ItemInstance)

var capacity: int = 24
var items: Array[ItemInstance] = []
var item_identity_service: ItemIdentityService


func _init(p_capacity: int = 24, p_item_identity_service: ItemIdentityService = null) -> void:
	capacity = maxi(1, p_capacity)
	item_identity_service = p_item_identity_service


func add_item(item: ItemInstance, definition: ItemDefinition) -> bool:
	if item == null or definition == null:
		return false
	if item.instance_id.is_empty() or has_instance(item.instance_id):
		return false
	if item.definition_id != definition.definition_id:
		return false
	if item.quantity <= 0 or item.quantity > definition.max_stack:
		return false

	var remaining := item.quantity
	var merge_plan: Array[Dictionary] = []
	if definition.max_stack > 1:
		for existing: ItemInstance in items:
			if existing.definition_id != item.definition_id:
				continue
			if existing.affixes != item.affixes or existing.durability != item.durability:
				continue
			var available := definition.max_stack - existing.quantity
			if available <= 0:
				continue
			var moved := mini(available, remaining)
			if moved <= 0:
				continue
			merge_plan.append({"item": existing, "quantity": moved})
			remaining -= moved
			if remaining <= 0:
				break

	if remaining > 0 and items.size() >= capacity:
		return false

	for step: Dictionary in merge_plan:
		var target: ItemInstance = step.get("item")
		target.quantity += int(step.get("quantity", 0))

	if remaining > 0:
		item.quantity = remaining
		items.append(item)
		item_added.emit(item)
		return true

	item.quantity = 0
	var final_target: ItemInstance = merge_plan[merge_plan.size() - 1].get("item")
	item_added.emit(final_target)
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
		var split_instance_id := _new_split_instance_id()
		if split_instance_id.is_empty():
			return null
		var removed := ItemInstance.from_dict(existing.to_dict())
		removed.instance_id = split_instance_id
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
		if item.definition_id == &"" or item.quantity <= 0:
			return false
		seen_ids[item.instance_id] = true
		restored.append(item)
	items = restored
	return true


func _new_split_instance_id() -> String:
	if item_identity_service == null:
		return ""
	return item_identity_service.mint()
