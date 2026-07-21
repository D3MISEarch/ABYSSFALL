class_name ProfileData
extends RefCounted

const CURRENT_VERSION := 1

var save_version: int = CURRENT_VERSION
var profile_id: String = ""
var display_name: String = "Player"
var currencies: Dictionary = {}
var account_unlocks: Dictionary = {}
var world_unlocks: Dictionary = {}
var story_progress: Dictionary = {}
var content_chapter_progress: Dictionary[String, ContentChapterProgress] = {}
var seasonal_history: Dictionary = {}
var reward_claims: Dictionary = {}
var shared_inventory: Dictionary = {}
var build_ids: Array[String] = []
var selected_build_id: String = ""
var statistics: Dictionary = {}
var created_at_unix: int = 0
var last_played_at_unix: int = 0


static func create_new(new_display_name: String = "Player") -> ProfileData:
	var result := ProfileData.new()
	result.profile_id = _new_id()
	result.display_name = new_display_name.strip_edges() if not new_display_name.strip_edges().is_empty() else "Player"
	result.created_at_unix = int(Time.get_unix_time_from_system())
	result.last_played_at_unix = result.created_at_unix
	return result


func set_chapter_progress(progress: ContentChapterProgress) -> bool:
	if progress == null or progress.chapter_id.strip_edges().is_empty():
		return false
	content_chapter_progress[progress.chapter_id] = progress
	return true


func get_chapter_progress(chapter_id: String) -> ContentChapterProgress:
	return content_chapter_progress.get(chapter_id) as ContentChapterProgress


func to_dict() -> Dictionary:
	var serialized_chapters: Dictionary = {}
	for chapter_id: String in content_chapter_progress:
		var progress: ContentChapterProgress = content_chapter_progress[chapter_id]
		serialized_chapters[chapter_id] = progress.to_dict()
	return {
		"save_version": save_version,
		"profile_id": profile_id,
		"display_name": display_name,
		"currencies": currencies.duplicate(true),
		"account_unlocks": account_unlocks.duplicate(true),
		"world_unlocks": world_unlocks.duplicate(true),
		"story_progress": story_progress.duplicate(true),
		"content_chapter_progress": serialized_chapters,
		"seasonal_history": seasonal_history.duplicate(true),
		"reward_claims": reward_claims.duplicate(true),
		"shared_inventory": shared_inventory.duplicate(true),
		"build_ids": build_ids.duplicate(),
		"selected_build_id": selected_build_id,
		"statistics": statistics.duplicate(true),
		"created_at_unix": created_at_unix,
		"last_played_at_unix": last_played_at_unix,
	}


static func from_dict(data: Dictionary) -> ProfileData:
	var result := ProfileData.new()
	result.save_version = int(data.get("save_version", CURRENT_VERSION))
	result.profile_id = str(data.get("profile_id", ""))
	result.display_name = str(data.get("display_name", "Player"))
	result.currencies = _dictionary_or_empty(data.get("currencies", {}))
	result.account_unlocks = _dictionary_or_empty(data.get("account_unlocks", {}))
	result.world_unlocks = _dictionary_or_empty(data.get("world_unlocks", {}))
	result.story_progress = _dictionary_or_empty(data.get("story_progress", {}))
	result.content_chapter_progress = _chapter_progress_or_empty(data.get("content_chapter_progress", {}))
	result.seasonal_history = _dictionary_or_empty(data.get("seasonal_history", {}))
	result.reward_claims = _dictionary_or_empty(data.get("reward_claims", {}))
	result.shared_inventory = _dictionary_or_empty(data.get("shared_inventory", {}))
	result.build_ids = _string_array_or_empty(data.get("build_ids", []))
	result.selected_build_id = str(data.get("selected_build_id", ""))
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


static func _chapter_progress_or_empty(value: Variant) -> Dictionary[String, ContentChapterProgress]:
	var result: Dictionary[String, ContentChapterProgress] = {}
	if value is Dictionary:
		for chapter_id: Variant in value:
			var chapter_data: Variant = value[chapter_id]
			if chapter_data is Dictionary:
				var progress := ContentChapterProgress.from_dict(chapter_data)
				if progress.chapter_id.is_empty():
					progress.chapter_id = str(chapter_id)
				result[str(chapter_id)] = progress
	return result


static func _string_array_or_empty(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			result.append(str(entry))
	return result
