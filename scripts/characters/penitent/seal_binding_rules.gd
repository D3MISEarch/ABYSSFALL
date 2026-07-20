extends RefCounted
class_name SealBindingRules

const TARGET_STANDARD := "standard"
const TARGET_BRUTE := "brute"
const TARGET_BOSS := "boss"


static func get_control_profile(target_kind: String, has_complete_rite: bool) -> Dictionary:
	match target_kind:
		TARGET_BOSS:
			return {
				"movement_multiplier": 0.72 if has_complete_rite else 0.88,
				"control_duration": 0.32,
				"bind_duration": 0.0,
				"show_chains": has_complete_rite,
				"resistance_label": "BOSS RESISTS THE BINDING",
			}
		TARGET_BRUTE:
			return {
				"movement_multiplier": 0.48 if has_complete_rite else 0.72,
				"control_duration": 0.32,
				"bind_duration": 0.12 if has_complete_rite else 0.0,
				"show_chains": has_complete_rite,
				"resistance_label": "BRUTE STRAINS AGAINST THE CHAINS",
			}
		_:
			return {
				"movement_multiplier": 0.0 if has_complete_rite else 0.58,
				"control_duration": 0.32,
				"bind_duration": 0.36 if has_complete_rite else 0.0,
				"show_chains": has_complete_rite,
				"resistance_label": "",
			}


static func is_inside_radius(center: Vector3, target_position: Vector3, radius: float) -> bool:
	var offset: Vector3 = target_position - center
	offset.y = 0.0
	return offset.length_squared() <= radius * radius
