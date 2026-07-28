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

var class_tree_combat := PLAYABLE_COMBAT_PROJECTION.new() as PlayableCombatProjection
var controller_aim_authority := false


func _ready() -> void:
	var forwarder := Callable(self, "_forward_corruption_changed")
	if not corruption_changed.is_connected(forwarder):
		corruption_changed.connect(forwarder)
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
		var mouse_point := _mouse_ground_point()
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


func unequip_slot(slot: String) -> bool:
	if not EQUIPMENT_SLOTS.has(slot):
		return false
	var equipped_item: Dictionary = equipment.get(slot, {})
	if equipped_item.is_empty():
		return false
	if backpack.size() >= MAX_BACKPACK_SIZE:
		loot_message.emit("BACKPACK FULL — CANNOT UNEQUIP")
		return false
	backpack.append(equipped_item)
	equipment[slot] = {}
	_recalculate_stats(true)
	inventory_changed.emit()
	loot_message.emit("UNEQUIPPED: %s" % str(equipped_item.get("name", "Unknown Relic")))
	return true


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
	PERSISTENT_LEVEL_RULES.apply_experience(self, amount)


func restore_persistent_progression(saved_level: int, saved_experience: int) -> void:
	PERSISTENT_LEVEL_RULES.restore(self, saved_level, saved_experience)


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


func apply_class_tree_projection(snapshot: Dictionary) -> void:
	class_tree_combat.configure(snapshot)


func get_class_tree_combat_snapshot() -> Dictionary:
	return class_tree_combat.snapshot()


func _resolve_outgoing_damage(base_damage: int) -> int:
	return class_tree_combat.resolve_outgoing_damage(base_damage)


func _resolve_incoming_damage(base_damage: int) -> int:
	return class_tree_combat.resolve_incoming_damage(base_damage)
