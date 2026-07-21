class_name ContentChapterProgress
extends RefCounted

var chapter_id: String = ""
var chapter_version: int = 1
var unlocked: bool = false
var quest_progress: Dictionary = {}
var boss_progress: Dictionary = {}
var activity_progress: Dictionary = {}
var reward_progress: Dictionary = {}
var completion_flags: Dictionary = {}


func to_dict() -> Dictionary:
	return {
		"chapter_id": chapter_id,
		"chapter_version": chapter_version,
		"unlocked": unlocked,
		"quest_progress": quest_progress.duplicate(true),
		"boss_progress": boss_progress.duplicate(true),
		"activity_progress": activity_progress.duplicate(true),
		"reward_progress": reward_progress.duplicate(true),
		"completion_flags": completion_flags.duplicate(true),
	}


static func from_dict(data: Dictionary) -> ContentChapterProgress:
	var result := ContentChapterProgress.new()
	result.chapter_id = str(data.get("chapter_id", ""))
	result.chapter_version = int(data.get("chapter_version", 1))
	result.unlocked = bool(data.get("unlocked", false))
	result.quest_progress = _dictionary_or_empty(data.get("quest_progress", {}))
	result.boss_progress = _dictionary_or_empty(data.get("boss_progress", {}))
	result.activity_progress = _dictionary_or_empty(data.get("activity_progress", {}))
	result.reward_progress = _dictionary_or_empty(data.get("reward_progress", {}))
	result.completion_flags = _dictionary_or_empty(data.get("completion_flags", {}))
	return result


static func _dictionary_or_empty(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}
