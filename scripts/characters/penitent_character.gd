extends "res://scripts/characters/penitent_placeholder.gd"
class_name PenitentCharacter


func get_health_snapshot() -> Dictionary:
	return {
		"current": health,
		"maximum": max_health,
		"alive": alive,
	}


func get_progression_snapshot() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"required_experience": experience_required,
		"pending_level_ups": pending_level_ups,
	}
