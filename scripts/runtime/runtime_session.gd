class_name RuntimeSession
extends Node

var event_bus: RuntimeEventBus
var ability_executor: AbilityExecutor
var item_catalog: ItemCatalog
var affix_catalog: AffixCatalog
var item_identity: ItemIdentityService
var inventory: InventoryContainer
var equipment: EquipmentManager
var reward_service: EnemyRewardService
var character: RuntimeCharacter


func _init() -> void:
	event_bus = RuntimeEventBus.new()
	event_bus.name = "RuntimeEventBus"
	add_child(event_bus)
	ability_executor = AbilityExecutor.new(event_bus)
	item_catalog = ItemCatalog.new()
	affix_catalog = AffixCatalog.new()
	item_identity = ItemIdentityService.new()
	reward_service = EnemyRewardService.new()


func bind_character(runtime_character: RuntimeCharacter, inventory_capacity: int = 24) -> bool:
	if character != null:
		_disconnect_character(character)
	_disconnect_item_systems()
	character = runtime_character
	if character == null:
		inventory = null
		equipment = null
		item_identity.clear()
		return false
	if not item_identity.configure(character.build_id, character.pending_item_identity_snapshot()):
		character = null
		inventory = null
		equipment = null
		return false

	var next_inventory := InventoryContainer.new(inventory_capacity, item_identity)
	var next_equipment := EquipmentManager.new()
	next_equipment.configure(item_catalog, character.stats)
	if not character.attach_item_systems(next_inventory, next_equipment):
		character = null
		inventory = null
		equipment = null
		item_identity.clear()
		return false

	item_identity.observe_items(next_inventory.items)
	item_identity.observe_equipment(next_equipment.equipped)
	inventory = next_inventory
	equipment = next_equipment
	character.state_changed.connect(_on_character_state_changed)
	character.level_gained.connect(_on_character_level_gained)
	inventory.item_added.connect(_on_inventory_changed)
	inventory.item_removed.connect(_on_inventory_changed)
	equipment.equipment_changed.connect(_on_equipment_changed)
	event_bus.build_loaded.emit(character.build_id)
	return true


func execute_ability(definition: AbilityDefinition) -> Dictionary:
	return ability_executor.execute(character, definition)


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
	return character.durable_snapshot(item_identity.snapshot()) if character != null else {}


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


func _on_character_state_changed(reason: StringName) -> void:
	if character == null:
		return
	event_bus.runtime_state_changed.emit(character.build_id, reason)


func _on_character_level_gained(new_level: int) -> void:
	if character == null:
		return
	event_bus.level_gained.emit(character.build_id, new_level)


func _on_inventory_changed(_item: ItemInstance) -> void:
	if character != null:
		event_bus.runtime_state_changed.emit(character.build_id, &"inventory")


func _on_equipment_changed(slot_id: StringName, equipped_item: ItemInstance, _unequipped_item: ItemInstance) -> void:
	if character == null:
		return
	event_bus.runtime_state_changed.emit(character.build_id, &"equipment")
	if equipped_item != null:
		event_bus.item_equipped.emit(character.build_id, slot_id, equipped_item.instance_id)
