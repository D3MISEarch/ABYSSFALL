class_name BuildData
extends RefCounted

const CURRENT_VERSION := 1

var save_version: int = CURRENT_VERSION
var build_id: String = ""
var build_name: String = "New Build"
var class_id: String = ""
var level: int = 1
var experience: int = 0
var equipped_gear: Dictionary = {}
var skills: Dictionary = {}
var hotbar: Array = []
var weapon_sets: Array = []
var class_tree_state: Dictionary = {}
var shared_core_state: Dictionary = {}
var build_specific_progress: Dictionary = {}
var quest_state: Dictionary = {}
var statistics: Dictionary = {}
var created_at_unix: int = 0
var last_played_at_unix: int = 0


static func create_new(new_class_id: String, new_name: String = "New Build") -> BuildData:
	var result := BuildData.new()
	result.build_id = _new_id()
	result.class_id = new_class_id
	result.build_name = new_name.strip_edges() if not new_name.strip_edges().is_empty() else "New Build"
	result.created_at_unix = int(Time.get_unix_time_from_system())
	result.last_played_at_unix = result.created_at_unix
	return result


func to_dict() -> Dictionary:
	return {
		"save_version": save_version,
		"build_id": build_id,
		"build_name": build_name,
		"class_id": class_id,
		"level": level,
		"experience": experience,
		"equipped_gear": equipped_gear.duplicate(true),
		"skills": skills.duplicate(true),
		"hotbar": hotbar.duplicate(true),
		"weapon_sets": weapon_sets.duplicate(true),
		"class_tree_state": class_tree_state.duplicate(true),
		"shared_core_state": shared_core_state.duplicate(true),
		"build_specific_progress": build_specific_progress.duplicate(true),
		"quest_state": quest_state.duplicate(true),
		"statistics": statistics.duplicate(true),
		"created_at_unix": created_at_unix,
		"last_played_at_unix": last_played_at_unix,
	}


static func from_dict(data: Dictionary) -> BuildData:
	var result := BuildData.new()
	result.save_version = int(data.get("save_version", CURRENT_VERSION))
	result.build_id = str(data.get("build_id", ""))
	result.build_name = str(data.get("build_name", "New Build"))
	result.class_id = str(data.get("class_id", ""))
	result.level = maxi(1, int(data.get("level", 1)))
	result.experience = maxi(0, int(data.get("experience", 0)))
	result.equipped_gear = _dictionary_or_empty(data.get("equipped_gear", {}))
	result.skills = _dictionary_or_empty(data.get("skills", {}))
	result.hotbar = _array_or_empty(data.get("hotbar", []))
	result.weapon_sets = _array_or_empty(data.get("weapon_sets", []))
	result.class_tree_state = _dictionary_or_empty(data.get("class_tree_state", {}))
	result.shared_core_state = _dictionary_or_empty(data.get("shared_core_state", {}))
	result.build_specific_progress = _dictionary_or_empty(data.get("build_specific_progress", {}))
	result.quest_state = _dictionary_or_empty(data.get("quest_state", {}))
	result.statistics = _dictionary_or_empty(data.get("statistics", {}))
	result.created_at_unix = int(data.get("created_at_unix", 0))
	result.last_played_at_unix = int(data.get("last_played_at_unix", 0))
	return result


static func _new_id() -> String:
	return "%s-%s" % [str(Time.get_unix_time_from_system()).replace(".", ""), str(randi())]


static func _dictionary_or_empty(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


static func _array_or_empty(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []
