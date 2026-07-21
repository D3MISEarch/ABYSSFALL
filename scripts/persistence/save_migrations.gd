class_name SaveMigrations
extends RefCounted


static func migrate_profile(data: Dictionary) -> Dictionary:
	var working := data.duplicate(true)
	var version := int(working.get("save_version", 1))
	while version < ProfileData.CURRENT_VERSION:
		match version:
			_:
				push_error("No profile migration exists from version %d" % version)
				return {}
		version += 1
		working["save_version"] = version
	return working


static func migrate_build(data: Dictionary) -> Dictionary:
	var working := data.duplicate(true)
	var version := int(working.get("save_version", 1))
	while version < BuildData.CURRENT_VERSION:
		match version:
			_:
				push_error("No build migration exists from version %d" % version)
				return {}
		version += 1
		working["save_version"] = version
	return working
