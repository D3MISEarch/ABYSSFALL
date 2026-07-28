class_name FrontEndBuildService
extends RefCounted

const CHARACTER_FACTORY = preload("res://scripts/core/character_factory.gd")


static func valid_build_summaries(profile: ProfileData) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	if profile == null:
		return summaries
	for raw_id: Variant in profile.build_ids:
		var build_id := str(raw_id)
		var build := SaveManager.load_build(build_id)
		if build == null or not CHARACTER_FACTORY.has_class(build.class_id):
			continue
		summaries.append(build_summary(build, build_id == profile.selected_build_id))
	summaries.sort_custom(_sort_recent_first)
	return summaries


static func startup_route(profile: ProfileData) -> StringName:
	return &"class_selection" if valid_build_summaries(profile).is_empty() else &"front_end"


static func selected_build(profile: ProfileData) -> BuildData:
	if profile == null or profile.selected_build_id.is_empty():
		return null
	var build := SaveManager.load_build(profile.selected_build_id)
	if build == null or not CHARACTER_FACTORY.has_class(build.class_id):
		return null
	return build


static func build_summary(build: BuildData, selected: bool = false) -> Dictionary:
	if build == null:
		return {}
	var definition := CHARACTER_FACTORY.get_class_definition(build.class_id)
	return {
		"build_id": build.build_id,
		"build_name": build.build_name,
		"class_id": build.class_id,
		"class_name": str(definition.get("display_name", build.class_id)),
		"level": build.level,
		"experience": build.experience,
		"last_played_at_unix": build.last_played_at_unix,
		"last_played_text": format_timestamp(build.last_played_at_unix),
		"selected": selected,
	}


static func next_default_build_name(profile: ProfileData, class_id: String) -> String:
	var definition := CHARACTER_FACTORY.get_class_definition(class_id)
	var base_name := str(definition.get("display_name", class_id.replace("_", " ").capitalize()))
	var used: Dictionary = {}
	if profile != null:
		for summary: Dictionary in valid_build_summaries(profile):
			used[str(summary.get("build_name", ""))] = true
	var index := 1
	while used.has("%s %d" % [base_name, index]):
		index += 1
	return "%s %d" % [base_name, index]


static func format_timestamp(unix_time: int) -> String:
	if unix_time <= 0:
		return "Never"
	var value := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d  %02d:%02d" % [
		int(value.get("year", 0)),
		int(value.get("month", 0)),
		int(value.get("day", 0)),
		int(value.get("hour", 0)),
		int(value.get("minute", 0)),
	]


static func _sort_recent_first(left: Dictionary, right: Dictionary) -> bool:
	var left_time := int(left.get("last_played_at_unix", 0))
	var right_time := int(right.get("last_played_at_unix", 0))
	if left_time == right_time:
		return str(left.get("build_name", "")) < str(right.get("build_name", ""))
	return left_time > right_time
