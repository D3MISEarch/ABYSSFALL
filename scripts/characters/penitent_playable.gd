extends "res://scripts/characters/penitent_character.gd"
class_name PenitentPlayable

const MARTYRS_CHAIN_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/martyrs_chain_controller.gd")
const ASHEN_PROCESSION_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/ashen_procession_controller.gd")
const SACRAMENT_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/sacrament_controller.gd")
const PERSISTENT_LEVEL_RULES = preload("res://scripts/core/persistent_level_rules.gd")
const PLAYABLE_COMBAT_PROJECTION = preload("res://scripts/core/playable_combat_projection.gd")

var martyrs_chain_controller: MartyrsChainController
var ashen_procession_controller: AshenProcessionController
var sacrament_controller: SacramentController
var class_tree_combat := PLAYABLE_COMBAT_PROJECTION.new() as PlayableCombatProjection
var playable_inventory_bridge: PlayableInventoryBridge


func _ready() -> void:
	super._ready()
	martyrs_chain_controller = MARTYRS_CHAIN_CONTROLLER_SCRIPT.new() as MartyrsChainController
	martyrs_chain_controller.name = "MartyrsChainController"
	add_child(martyrs_chain_controller)
	martyrs_chain_controller.bind_to(self)

	ashen_procession_controller = ASHEN_PROCESSION_CONTROLLER_SCRIPT.new() as AshenProcessionController
	ashen_procession_controller.name = "AshenProcessionController"
	add_child(ashen_procession_controller)
	ashen_procession_controller.bind_to(self)

	sacrament_controller = SACRAMENT_CONTROLLER_SCRIPT.new() as SacramentController
	sacrament_controller.name = "SacramentController"
	add_child(sacrament_controller)
	sacrament_controller.bind_to(self)


func add_experience(amount: int) -> void:
	PERSISTENT_LEVEL_RULES.apply_experience(self, amount)


func restore_persistent_progression(saved_level: int, saved_experience: int) -> void:
	PERSISTENT_LEVEL_RULES.restore(self, saved_level, saved_experience)


func bind_playable_inventory_bridge(bridge: PlayableInventoryBridge) -> bool:
	if bridge == null or not bridge.is_configured():
		return false
	playable_inventory_bridge = bridge
	_apply_persistent_inventory_snapshot(bridge.snapshot())
	return true


func add_item(item: Dictionary) -> void:
	try_add_item(item)


func try_add_item(item: Dictionary) -> bool:
	if playable_inventory_bridge == null:
		super.add_item(item)
		return true
	var result := playable_inventory_bridge.collect_drop(item)
	if bool(result.get("success", false)):
		_apply_persistent_inventory_snapshot(playable_inventory_bridge.snapshot())
		var stored_item: Dictionary = result.get("item", {})
		loot_message.emit("LOOT STORED: %s — PRESS I" % str(stored_item.get("name", "Unknown Relic")))
		return true
	var reason := StringName(str(result.get("reason", &"rejected")))
	if reason == &"inventory_full":
		loot_message.emit("BACKPACK FULL — LOOT REMAINS ON THE GROUND")
	else:
		loot_message.emit("LOOT COULD NOT BE STORED: %s" % String(reason).replace("_", " ").to_upper())
	return false


func equip_inventory_index(index: int) -> void:
	if playable_inventory_bridge == null:
		super.equip_inventory_index(index)
		return
	var result := playable_inventory_bridge.equip_inventory_index(index)
	if not bool(result.get("success", false)):
		loot_message.emit("EQUIP BLOCKED: %s" % str(result.get("reason", &"invalid")).replace("_", " ").to_upper())
		return
	_apply_persistent_inventory_snapshot(playable_inventory_bridge.snapshot())
	var equipped_item: Dictionary = result.get("item", {})
	loot_message.emit("EQUIPPED: %s" % str(equipped_item.get("name", "Unknown Relic")))


func unequip_slot(slot: String) -> bool:
	if playable_inventory_bridge == null:
		return super.unequip_slot(slot)
	var result := playable_inventory_bridge.unequip_slot(slot)
	if not bool(result.get("success", false)):
		loot_message.emit("UNEQUIP BLOCKED: %s" % str(result.get("reason", &"invalid")).replace("_", " ").to_upper())
		return false
	_apply_persistent_inventory_snapshot(playable_inventory_bridge.snapshot())
	var unequipped_item: Dictionary = result.get("item", {})
	loot_message.emit("UNEQUIPPED: %s" % str(unequipped_item.get("name", "Unknown Relic")))
	return true


func get_inventory_snapshot() -> Dictionary:
	if playable_inventory_bridge != null and playable_inventory_bridge.is_configured():
		return playable_inventory_bridge.snapshot()
	return super.get_inventory_snapshot()


func _apply_persistent_inventory_snapshot(snapshot: Dictionary) -> void:
	var projected_equipment: Dictionary = snapshot.get("equipment", {})
	for slot: String in EQUIPMENT_SLOTS:
		equipment[slot] = projected_equipment.get(slot, {}).duplicate(true)
	backpack = snapshot.get("backpack", []).duplicate(true)
	inventory_changed.emit()


func apply_class_tree_projection(snapshot: Dictionary) -> void:
	class_tree_combat.configure(snapshot)


func get_class_tree_combat_snapshot() -> Dictionary:
	return class_tree_combat.snapshot()


func _resolve_outgoing_damage(base_damage: int) -> int:
	return class_tree_combat.resolve_outgoing_damage(base_damage)


func _resolve_incoming_damage(base_damage: int) -> int:
	return class_tree_combat.resolve_incoming_damage(base_damage)
