class_name SaveManager
extends RefCounted

const ROOT_DIR := "user://abyssfall"
const BUILDS_DIR := ROOT_DIR + "/builds"
const BACKUPS_DIR := ROOT_DIR + "/backups"
const PROFILE_PATH := ROOT_DIR + "/profile.json"
const PROFILE_BACKUP_PATH := BACKUPS_DIR + "/profile_backup.json"


static func ensure_directories() -> Error:
	for path in [ROOT_DIR, BUILDS_DIR, BACKUPS_DIR]:
		var error := DirAccess.make_dir_recursive_absolute(path)
		if error != OK and error != ERR_ALREADY_EXISTS:
			push_error("Could not create save directory %s (error %d)" % [path, error])
			return error
	return OK


static func create_profile(display_name: String = "Player") -> ProfileData:
	var profile := ProfileData.create_new(display_name)
	if save_profile(profile) != OK:
		return null
	return profile


static func save_profile(profile: ProfileData) -> Error:
	if profile == null:
		return ERR_INVALID_PARAMETER
	var directory_error := ensure_directories()
	if directory_error != OK:
		return directory_error
	profile.last_played_at_unix = int(Time.get_unix_time_from_system())
	return _write_json_with_backup(PROFILE_PATH, PROFILE_BACKUP_PATH, profile.to_dict())


static func load_profile() -> ProfileData:
	var data := _load_json_with_recovery(PROFILE_PATH, PROFILE_BACKUP_PATH)
	if data.is_empty():
		return null
	var migrated := SaveMigrations.migrate_profile(data)
	if migrated.is_empty():
		return null
	var profile := ProfileData.from_dict(migrated)
	if not _is_valid_profile(profile):
		push_error("Loaded profile data failed validation")
		return null
	return profile


static func create_build(profile: ProfileData, class_id: String, build_name: String = "New Build") -> BuildData:
	if profile == null or class_id.strip_edges().is_empty():
		return null
	var build := BuildData.create_new(class_id.strip_edges(), build_name)
	if save_build(build) != OK:
		return null
	profile.build_ids.append(build.build_id)
	profile.selected_build_id = build.build_id
	if save_profile(profile) != OK:
		delete_build_file(build.build_id)
		profile.build_ids.erase(build.build_id)
		profile.selected_build_id = ""
		return null
	return build


static func save_build(build: BuildData) -> Error:
	if build == null or build.build_id.strip_edges().is_empty():
		return ERR_INVALID_PARAMETER
	var directory_error := ensure_directories()
	if directory_error != OK:
		return directory_error
	build.last_played_at_unix = int(Time.get_unix_time_from_system())
	return _write_json_with_backup(_build_path(build.build_id), _build_backup_path(build.build_id), build.to_dict())


static func load_build(build_id: String) -> BuildData:
	if build_id.strip_edges().is_empty():
		return null
	var data := _load_json_with_recovery(_build_path(build_id), _build_backup_path(build_id))
	if data.is_empty():
		return null
	var migrated := SaveMigrations.migrate_build(data)
	if migrated.is_empty():
		return null
	var build := BuildData.from_dict(migrated)
	if not _is_valid_build(build, build_id):
		push_error("Loaded build data failed validation for %s" % build_id)
		return null
	return build


static func rename_build(profile: ProfileData, build_id: String, new_name: String) -> Error:
	var clean_name := new_name.strip_edges()
	if profile == null or clean_name.is_empty() or not profile.build_ids.has(build_id):
		return ERR_INVALID_PARAMETER
	var build := load_build(build_id)
	if build == null:
		return ERR_FILE_CORRUPT
	build.build_name = clean_name
	return save_build(build)


static func select_build(profile: ProfileData, build_id: String) -> Error:
	if profile == null or not profile.build_ids.has(build_id):
		return ERR_INVALID_PARAMETER
	if load_build(build_id) == null:
		return ERR_FILE_NOT_FOUND
	profile.selected_build_id = build_id
	return save_profile(profile)


static func delete_build(profile: ProfileData, build_id: String) -> Error:
	if profile == null or not profile.build_ids.has(build_id):
		return ERR_INVALID_PARAMETER
	var file_error := delete_build_file(build_id)
	if file_error != OK:
		return file_error
	profile.build_ids.erase(build_id)
	if profile.selected_build_id == build_id:
		profile.selected_build_id = profile.build_ids[0] if not profile.build_ids.is_empty() else ""
	return save_profile(profile)


static func delete_build_file(build_id: String) -> Error:
	var primary_error := _remove_if_present(_build_path(build_id))
	var backup_error := _remove_if_present(_build_backup_path(build_id))
	if primary_error != OK:
		return primary_error
	return backup_error


static func _write_json_with_backup(primary_path: String, backup_path: String, data: Dictionary) -> Error:
	if FileAccess.file_exists(primary_path):
		var copy_error := _copy_file(primary_path, backup_path)
		if copy_error != OK:
			return copy_error
	var temporary_path := primary_path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t", false))
	file.flush()
	file.close()
	var replace_error := _replace_file(temporary_path, primary_path)
	if replace_error != OK:
		_remove_if_present(temporary_path)
	return replace_error


static func _load_json_with_recovery(primary_path: String, backup_path: String) -> Dictionary:
	var primary := _read_json(primary_path)
	if not primary.is_empty():
		return primary
	var backup := _read_json(backup_path)
	if backup.is_empty():
		return {}
	push_warning("Recovered save data from backup: %s" % backup_path)
	_copy_file(backup_path, primary_path)
	return backup


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	push_warning("Invalid or corrupted JSON save: %s" % path)
	return {}


static func _copy_file(source_path: String, destination_path: String) -> Error:
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		return FileAccess.get_open_error()
	var destination := FileAccess.open(destination_path, FileAccess.WRITE)
	if destination == null:
		source.close()
		return FileAccess.get_open_error()
	destination.store_buffer(source.get_buffer(source.get_length()))
	destination.flush()
	source.close()
	destination.close()
	return OK


static func _replace_file(source_path: String, destination_path: String) -> Error:
	_remove_if_present(destination_path)
	return DirAccess.rename_absolute(source_path, destination_path)


static func _remove_if_present(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return OK
	return DirAccess.remove_absolute(path)


static func _build_path(build_id: String) -> String:
	return BUILDS_DIR + "/build_%s.json" % build_id


static func _build_backup_path(build_id: String) -> String:
	return BACKUPS_DIR + "/build_%s_backup.json" % build_id


static func _is_valid_profile(profile: ProfileData) -> bool:
	return profile != null and not profile.profile_id.is_empty() and profile.save_version <= ProfileData.CURRENT_VERSION


static func _is_valid_build(build: BuildData, expected_id: String) -> bool:
	return (
		build != null
		and build.build_id == expected_id
		and not build.class_id.is_empty()
		and build.save_version <= BuildData.CURRENT_VERSION
	)
