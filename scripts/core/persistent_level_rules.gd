class_name PersistentLevelRules
extends RefCounted


static func experience_requirement(level: int) -> int:
	return int(round(70.0 + pow(float(maxi(1, level) - 1), 1.28) * 42.0))


static func apply_experience(character: Variant, amount: int) -> void:
	if character == null or amount <= 0:
		return
	var level := int(character.get("level"))
	var experience := int(character.get("experience")) + amount
	var required := int(character.get("experience_required"))
	while experience >= required:
		experience -= required
		level += 1
		required = experience_requirement(level)
	character.set("level", level)
	character.set("experience", experience)
	character.set("experience_required", required)
	character.set("pending_level_ups", 0)
	character.set("level_up_in_progress", false)
	character.emit_signal(&"experience_changed", level, experience, required)


static func restore(character: Variant, saved_level: int, saved_experience: int) -> void:
	if character == null:
		return
	var level := maxi(1, saved_level)
	var required := experience_requirement(level)
	var experience := clampi(saved_experience, 0, maxi(0, required - 1))
	character.set("level", level)
	character.set("experience", experience)
	character.set("experience_required", required)
	character.set("pending_level_ups", 0)
	character.set("level_up_in_progress", false)
	character.emit_signal(&"experience_changed", level, experience, required)
