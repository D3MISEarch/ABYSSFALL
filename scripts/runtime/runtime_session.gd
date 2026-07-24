class_name RuntimeSession
extends Node

var event_bus: RuntimeEventBus
var ability_executor: AbilityExecutor
var item_catalog: ItemCatalog
var affix_catalog: AffixCatalog
var class_tree_catalog: ClassTreeCatalog
var item_identity: ItemIdentityService
var inventory: InventoryContainer
var equipment: EquipmentManager
var class_progression: ClassProgressionState
var reward_service: EnemyRewardService
var character: RuntimeCharacter


func _init() -> void:
	event_bus = RuntimeEventBus.new()
	event_bus.name = "RuntimeEventBus"
	add_child(event_bus)
	ability_executor = AbilityExecutor.new(event_bus)
	item_catalog = ItemCatalog.new()
	affix_catalog = AffixCatalog.new()
	class_tree_catalog = ClassTreeCatalog.new()
	class_tree_catalog.register_framework_proofs()
	item_identity = ItemIdentityService.new()
	reward_service = EnemyRewardService.new()


func bind_character(runtime_character: RuntimeCharacter, inventory_capacity: int = 24) -> bool:
	if runtime_character == null:
		return false

	var next_definition := class_tree_catalog.get_definition(String(runtime_character.class_id))
	if next_definition == null:
		return false
	var next_progression := ClassProgressionState.new()
	if not next_progression.configure(next_definition):
		return false
	if not next_progression.restore(runtime_character.pending_class_tree_snapshot(), runtime_character.level):
		return false
	var reconciled_points := next_progression.reconcile_level_awards(runtime_character.level)

	var next_identity := ItemIdentityService.new()
	if not next_identity.configure(runtime_character.build_id, runtime_character.pending_item_identity_snapshot()):
		return false

	var next_inventory := InventoryContainer.new(inventory_capacity, next_identity)
	var next_equipment := EquipmentManager.new()
	next_equipment.configure(item_catalog, null)
	if not runtime_character.attach_item_systems(next_inventory, next_equipment):
		return false

	next_identity.observe_items(next_inventory.items)
	next_identity.observe_equipment(next_equipment.equipped)
	if not next_progression.attach_stat_block(runtime_character.stats):
		return false

	if character != null:
		_disconnect_character(character)
	_disconnect_item_systems()
	_disconnect_progression()
	character = runtime_character
	item_identity = next_identity
	inventory = next_inventory
	equipment = next_equipment
	class_progression = next_progression
	equipment.configure(item_catalog, character.stats)
	character.state_changed.connect(_on_character_state_changed)
	character.level_gained.connect(_on_character_level_gained)
	inventory.item_added.connect(_on_inventory_changed)
	inventory.item_removed.connect(_on_inventory_changed)
	equipment.equipment_changed.connect(_on_equipment_changed)
	class_progression.award_applied.connect(_on_class_point_awarded)
	class_progression.node_purchased.connect(_on_class_node_purchased)
	event_bus.build_loaded.emit(character.build_id)
	if reconciled_points > 0:
		event_bus.runtime_state_changed.emit(character.build_id, &"class_progression")
	return true


func execute_ability(definition: AbilityDefinition) -> Dictionary:
	return ability_executor.execute(character, definition)


func purchase_class_tree_node(node_id: StringName) -> Dictionary:
	if class_progression == null:
		return {"success": false, "reason": &"unbound"}
	return class_progression.purchase_rank(node_id)


func grant_enemy_rewards(enemy: EnemyRuntime) -> Dictionary:
	if character == null or inventory == null:
		return {"granted": false, "experience": 0, "levels": 0, "loot": [], "rejected_loot": []}
	var result := reward_service.grant(enemy, character, inventory, item_catalog, affix_catalog, item_identity)
	if bool(result.get("granted", false)):
		event_bus.enemy_killed.emit(enemy.enemy_id, character.build_id)
		event_bus.experience_gained.emit(character.build_id, int(result.get("experience", 0)))
	return result


func tick_runtime(delta: float) -> void:
	ability_executor.tick(delta)
	if character != null:
		character.class_resource.tick(delta)


func durable_snapshot() -> Dictionary:
	if character == null:
		return {}
	var progression_snapshot := class_progression.serialize() if class_progression != null else character.pending_class_tree_snapshot()
	return character.durable_snapshot(item_identity.snapshot(), progression_snapshot)


func _disconnect_character(runtime_character: RuntimeCharacter) -> void:
	if runtime_character.state_changed.is_connected(_on_character_state_changed):
		runtime_character.state_changed.disconnect(_on_character_state_changed)
	if runtime_character.level_gained.is_connected(_on_character_level_gained):
		runtime_character.level_gained.disconnect(_on_character_level_gained)


func _disconnect_item_systems() -> void:
	if inventory != null:
		if inventory.item_added.is_connected(_on_inventory_changed):
			inventory.item_added.disconnect(_on_inventory_changed)
		if inventory.item_removed.is_connected(_on_inventory_changed):
			inventory.item_removed.disconnect(_on_inventory_changed)
	if equipment != null and equipment.equipment_changed.is_connected(_on_equipment_changed):
		equipment.equipment_changed.disconnect(_on_equipment_changed)


func _disconnect_progression() -> void:
	if class_progression == null:
		return
	if class_progression.award_applied.is_connected(_on_class_point_awarded):
		class_progression.award_applied.disconnect(_on_class_point_awarded)
	if class_progression.node_purchased.is_connected(_on_class_node_purchased):
		class_progression.node_purchased.disconnect(_on_class_node_purchased)


func _on_character_state_changed(reason: StringName) -> void:
	if character == null:
		return
	event_bus.runtime_state_changed.emit(character.build_id, reason)


func _on_character_level_gained(new_level: int) -> void:
	if character == null:
		return
	if class_progression != null and class_progression.definition != null:
		var amount := class_progression.definition.point_award_for_level(new_level)
		if amount > 0:
			class_progression.award("level:%d" % new_level, amount)
	event_bus.level_gained.emit(character.build_id, new_level)


func _on_class_point_awarded(source_id: String, amount: int, available_points: int) -> void:
	if character == null:
		return
	event_bus.class_point_awarded.emit(character.build_id, source_id, amount, available_points)
	event_bus.runtime_state_changed.emit(character.build_id, &"class_progression")


func _on_class_node_purchased(node_id: StringName, rank: int, cost: int, available_points: int) -> void:
	if character == null:
		return
	event_bus.class_node_purchased.emit(character.build_id, node_id, rank, cost, available_points)
	event_bus.runtime_state_changed.emit(character.build_id, &"class_progression")


func _on_inventory_changed(_item: ItemInstance) -> void:
	if character != null:
		event_bus.runtime_state_changed.emit(character.build_id, &"inventory")


func _on_equipment_changed(slot_id: StringName, equipped_item: ItemInstance, _unequipped_item: ItemInstance) -> void:
	if character == null:
		return
	event_bus.runtime_state_changed.emit(character.build_id, &"equipment")
	if equipped_item != null:
		event_bus.item_equipped.emit(character.build_id, slot_id, equipped_item.instance_id)
