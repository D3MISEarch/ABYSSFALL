class_name RuntimeCharacter
extends RefCounted

const CLASS_IDS = preload("res://scripts/shared/class_ids.gd")

signal state_changed(reason: StringName)
signal level_gained(new_level: int)

var build_id: String = ""
var class_id: StringName = &""
var level: int = 1
var experience: int = 0
var experience_to_next: int = 100
var current_health: float = 1.0
var stats := StatBlock.new()
var class_resource := ClassResourcePool.new()
var inventory: Array[Dictionary] = []
var equipment: Dictionary = {}
var unlocked_abilities: Array[StringName] = []


func configure_from_build(build: Variant) -> void:
	build_id = str(build.build_id)
	class_id = StringName(str(build.class_id))
	level = maxi(1, int(build.level))
	experience = maxi(0, int(build.experience))
	experience_to_next = _required_experience(level)
	equipment = build.equipped_gear.duplicate(true)
	inventory = _inventory_from_progress(build.build_specific_progress)
	unlocked_abilities = _abilities_from_skills(build.skills)
	_apply_class_defaults()
	current_health = stats.get_value(&"max_health", 100.0)


func gain_experience(amount: int) -> int:
	if amount <= 0:
		return 0
	experience += amount
	var gained_levels := 0
	while experience >= experience_to_next:
		experience -= experience_to_next
		level += 1
		gained_levels += 1
		experience_to_next = _required_experience(level)
		level_gained.emit(level)
	state_changed.emit(&"experience")
	return gained_levels


func take_damage(amount: float) -> float:
	var applied := clampf(amount, 0.0, current_health)
	current_health -= applied
	return applied


func heal(amount: float) -> float:
	var maximum := stats.get_value(&"max_health", 100.0)
	var before := current_health
	current_health = clampf(current_health + maxf(amount, 0.0), 0.0, maximum)
	return current_health - before


func is_dead() -> bool:
	return current_health <= 0.0


func durable_snapshot() -> Dictionary:
	var serialized_abilities: Array[String] = []
	for ability_id: StringName in unlocked_abilities:
		serialized_abilities.append(String(ability_id))
	return {
		"build_id": build_id,
		"level": level,
		"experience": experience,
		"equipped_gear": equipment.duplicate(true),
		"skills": {"unlocked_abilities": serialized_abilities},
		"build_specific_progress": {"inventory": inventory.duplicate(true)},
	}


func _apply_class_defaults() -> void:
	stats.set_base(&"max_health", 100.0 + float(level - 1) * 8.0)
	stats.set_base(&"armor", 0.0)
	stats.set_base(&"critical_chance", 0.05)
	match String(class_id):
		CLASS_IDS.PENITENT:
			stats.set_base(&"max_health", 125.0 + float(level - 1) * 10.0)
			class_resource.configure(&"fervor", 100.0)
		CLASS_IDS.VOID_WARLOCK:
			stats.set_base(&"max_health", 90.0 + float(level - 1) * 7.0)
			class_resource.configure(&"corruption", 100.0, 2.0)
		_:
			class_resource.configure(&"resource", 100.0)


func _inventory_from_progress(progress: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var stored: Variant = progress.get("inventory", [])
	if stored is Array:
		for entry: Variant in stored:
			if entry is Dictionary:
				result.append(entry.duplicate(true))
	return result


func _abilities_from_skills(skills: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	var stored: Variant = skills.get("unlocked_abilities", [])
	if stored is Array:
		for entry: Variant in stored:
			result.append(StringName(str(entry)))
	return result


func _required_experience(target_level: int) -> int:
	return 100 + maxi(0, target_level - 1) * 35
