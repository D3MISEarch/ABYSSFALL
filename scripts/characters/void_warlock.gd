extends "res://scripts/player.gd"
class_name VoidWarlockCharacter

signal resource_changed(
	resource_id: String,
	display_name: String,
	current_value: float,
	maximum_value: float
)

const CLASS_ID := "void_warlock"
const CLASS_DISPLAY_NAME := "Void Warlock"
const RESOURCE_ID := "corruption"
const RESOURCE_DISPLAY_NAME := "Corruption"
const PERSISTENT_LEVEL_RULES = preload("res://scripts/core/persistent_level_rules.gd")
const PLAYABLE_COMBAT_PROJECTION = preload("res://scripts/core/playable_combat_projection.gd")
const PLAYABLE_AIM_RESOLVER = preload("res://scripts/core/playable_aim_resolver.gd")
const VOIDBRINGER_CONTROLLER_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_controller.gd")

var class_tree_combat := PLAYABLE_COMBAT_PROJECTION.new() as PlayableCombatProjection
var playable_inventory_bridge: PlayableInventoryBridge
var controller_aim_authority := false
var voidbringer_controller := VOIDBRINGER_CONTROLLER_SCRIPT.new() as VoidbringerController


func _ready() -> void:
	var forwarder := Callable(self, "_forward_corruption_changed")
	if not corruption_changed.is_connected(forwarder):
		corruption_changed.connect(forwarder)
	voidbringer_controller.configure(level)
	super._ready()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		controller_aim_authority = false
	elif event is InputEventMouseButton:
		if (event as InputEventMouseButton).pressed:
			controller_aim_authority = false
	elif event is InputEventKey:
		if (event as InputEventKey).pressed:
			controller_aim_authority = false
	elif event is InputEventJoypadButton:
		if (event as InputEventJoypadButton).pressed:
			controller_aim_authority = true
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		if absf(motion.axis_value) > PLAYABLE_AIM_RESOLVER.STICK_DEADZONE:
			controller_aim_authority = true


func _update_aim(move_direction: Vector3) -> void:
	var stick_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick_aim.length() > PLAYABLE_AIM_RESOLVER.STICK_DEADZONE:
		controller_aim_authority = true
	var mouse_direction := Vector3.ZERO
	var has_mouse_direction := false
	if not controller_aim_authority:
		var mouse_point := super._mouse_ground_point()
		if mouse_point != Vector3.INF:
			mouse_direction = mouse_point - global_position
			mouse_direction.y = 0.0
			has_mouse_direction = true
	facing = PLAYABLE_AIM_RESOLVER.resolve_facing(
		facing,
		move_direction,
		stick_aim,
		controller_aim_authority,
		mouse_direction,
		has_mouse_direction
	)
	rotation.y = atan2(-facing.x, -facing.z)


func _mouse_ground_point() -> Vector3:
	if controller_aim_authority:
		return Vector3.INF
	return super._mouse_ground_point()


func get_class_id() -> String:
	return CLASS_ID


func get_class_display_name() -> String:
	return CLASS_DISPLAY_NAME


func get_class_definition() -> Dictionary:
	return {
		"id": CLASS_ID,
		"display_name": CLASS_DISPLAY_NAME,
		"title": "Master of the Hungry Rift",
		"resource_id": RESOURCE_ID,
		"resource_name": RESOURCE_DISPLAY_NAME,
		"tags": ["Ranged", "Control", "Summoning", "Burst"],
		"difficulty": "Moderate",
		"skill_branches": ["Abyss", "Corruption", "Soulbinding"],
	}


func get_health_snapshot() -> Dictionary:
	return {
		"current": health,
		"maximum": max_health,
		"alive": alive,
	}


func get_resource_snapshot() -> Dictionary:
	return {
		"id": RESOURCE_ID,
		"display_name": RESOURCE_DISPLAY_NAME,
		"current": corruption,
		"maximum": max_corruption,
		"normalized": corruption / maxf(max_corruption, 1.0),
	}


func get_progression_snapshot() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"required_experience": experience_required,
		"pending_level_ups": pending_level_ups,
	}


func add_experience(amount: int) -> void:
	var previous_level := level
	PERSISTENT_LEVEL_RULES.apply_experience(self, amount)
	if level != previous_level:
		voidbringer_controller.configure(level)


func restore_persistent_progression(saved_level: int, saved_experience: int) -> void:
	PERSISTENT_LEVEL_RULES.restore(self, saved_level, saved_experience)
	voidbringer_controller.configure(level)


func bind_runtime_session(session: RuntimeSession, runtime_character: RuntimeCharacter) -> bool:
	return voidbringer_controller.bind_runtime(session, runtime_character)


func get_voidbringer_foundation_snapshot() -> Dictionary:
	return voidbringer_controller.snapshot()


func add_class_resource(amount: float) -> void:
	add_corruption(amount)


func spend_class_resource(amount: float) -> bool:
	return spend_corruption(amount)


func _forward_corruption_changed(current_value: float, maximum_value: float) -> void:
	resource_changed.emit(
		RESOURCE_ID,
		RESOURCE_DISPLAY_NAME,
		current_value,
		maximum_value
	)


func bind_playable_inventory_bridge(bridge: PlayableInventoryBridge) -> bool:
	if bridge == null or not bridge.is_configured() or bridge.runtime_bridge == null:
		return false
	if not bind_runtime_session(bridge.runtime_bridge.session, bridge.runtime_bridge.runtime_character):
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
		return false
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
	_recalculate_stats(true)
	inventory_changed.emit()


func apply_class_tree_projection(snapshot: Dictionary) -> void:
	class_tree_combat.configure(snapshot)


func get_class_tree_combat_snapshot() -> Dictionary:
	return class_tree_combat.snapshot()


func _resolve_outgoing_damage(base_damage: int) -> int:
	return class_tree_combat.resolve_outgoing_damage(base_damage)


func _resolve_incoming_damage(base_damage: int) -> int:
	return class_tree_combat.resolve_incoming_damage(base_damage)
