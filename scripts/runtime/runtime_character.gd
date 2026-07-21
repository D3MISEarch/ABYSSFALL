class_name RuntimeCharacter
extends RefCounted

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
	experience = int(build.experience)
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
	return {
		"build_id": build_id,
		"class_id": String(class_id),
		"level": level,
		"experience": experience,
		"inventory": inventory.duplicate(true),
		"equipment": equipment.duplicate(true),
		"unlocked_abilities": unlocked_abilities.duplicate(),
	}


func _apply_class_defaults() -> void:
	stats.set_base(&"max_health", 100.0 + float(level - 1) * 8.0)
	stats.set_base(&"armor", 0.0)
	stats.set_base(&"critical_chance", 0.05)
	match class_id:
		&"penitent":
			stats.set_base(&"max_health", 125.0 + float(level - 1) * 10.0)
			class_resource.configure(&"fervor", 100.0)
		&"void_warlock":
			stats.set_base(&"max_health", 90.0 + float(level - 1) * 7.0)
			class_resource.configure(&"corruption", 100.0, 2.0)
		_:
			class_resource.configure(&"resource", 100.0)


func _required_experience(target_level: int) -> int:
	return 100 + maxi(0, target_level - 1) * 35
