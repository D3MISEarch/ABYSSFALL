extends RefCounted
class_name PlaytestReport

const REPORT_DIRECTORY := "user://playtest_reports"


static func build_text(
	identity: Dictionary,
	active_input_profile: String,
	controller_lines: Array[String],
	scene_name: String,
	fps: float,
	generated_at_utc: String = ""
) -> String:
	var timestamp := generated_at_utc
	if timestamp.is_empty():
		timestamp = Time.get_datetime_string_from_system(true, true)
	var controllers := controller_lines.duplicate()
	if controllers.is_empty():
		controllers.append("none")
	return "\n".join([
		"ABYSSFALL PLAYTEST REPORT",
		"Generated UTC: %s" % timestamp,
		"Build: %s" % str(identity.get("name", "unknown")),
		"Commit: %s" % str(identity.get("commit", "unknown")),
		"Short commit: %s" % str(identity.get("short_commit", "unknown")),
		"Branch: %s" % str(identity.get("branch", "unknown")),
		"Workflow: %s" % str(identity.get("workflow_run", "unknown")),
		"Built UTC: %s" % str(identity.get("built_at_utc", "unknown")),
		"Scene: %s" % scene_name,
		"FPS: %.1f" % fps,
		"Active input profile: %s" % active_input_profile,
		"Connected controllers:",
		"- %s" % "\n- ".join(controllers),
		"",
		"Player notes:",
		"",
	])


static func save_text(report_text: String, filename_stem: String = "") -> Dictionary:
	var stem := filename_stem
	if stem.is_empty():
		stem = Time.get_datetime_string_from_system(true, true)
	stem = stem.replace(":", "-").replace(" ", "_")
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIRECTORY))
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return {
			"ok": false,
			"path": "",
			"error": "Could not create report directory (error %d)" % directory_error,
		}
	var path := "%s/AbyssFall_Playtest_%s.txt" % [REPORT_DIRECTORY, stem]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"path": path,
			"error": "Could not open report file (error %d)" % FileAccess.get_open_error(),
		}
	file.store_string(report_text)
	file.close()
	return {
		"ok": true,
		"path": path,
		"absolute_path": ProjectSettings.globalize_path(path),
		"error": "",
	}
