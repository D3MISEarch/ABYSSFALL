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


func _ready() -> void:
	var forwarder := Callable(self, "_forward_corruption_changed")
	if not corruption_changed.is_connected(forwarder):
		corruption_changed.connect(forwarder)
	super._ready()


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


func get_resource_snapshot() -> Dictionary:
	return {
		"id": RESOURCE_ID,
		"display_name": RESOURCE_DISPLAY_NAME,
		"current": corruption,
		"maximum": max_corruption,
		"normalized": corruption / maxf(max_corruption, 1.0),
	}


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
