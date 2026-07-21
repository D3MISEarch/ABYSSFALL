extends RefCounted
class_name BuildIdentity

const BUILD_INFO_PATH := "res://BUILD_INFO.cfg"
const DEFAULTS := {
	"name": "AbyssFall developer build",
	"commit": "development",
	"short_commit": "dev",
	"branch": "local",
	"workflow_run": "local",
	"built_at_utc": "not-exported",
}


static func load_current() -> Dictionary:
	var result := DEFAULTS.duplicate(true)
	var config := ConfigFile.new()
	if config.load(BUILD_INFO_PATH) != OK:
		return result
	for key in DEFAULTS.keys():
		result[key] = str(config.get_value("build", key, DEFAULTS[key]))
	return result


static func display_line(identity: Dictionary = {}) -> String:
	var resolved := load_current() if identity.is_empty() else identity
	return "%s | %s | %s" % [
		str(resolved.get("name", DEFAULTS["name"])),
		str(resolved.get("short_commit", DEFAULTS["short_commit"])),
		str(resolved.get("built_at_utc", DEFAULTS["built_at_utc"])),
	]
