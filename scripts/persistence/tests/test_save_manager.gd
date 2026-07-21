extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	_cleanup()
	_test_profile_round_trip()
	_test_independent_builds()
	_test_rename_select_delete()
	_test_backup_recovery()
	_cleanup()

	if failures.is_empty():
		print("PASS: Stage 1 persistence smoke tests")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_profile_round_trip() -> void:
	var profile := SaveManager.create_profile("Abyss Tester")
	_expect(profile != null, "Profile should be created")
	if profile == null:
		return
	profile.currencies["embers"] = 25
	_expect(SaveManager.save_profile(profile) == OK, "Profile should save")
	var loaded := SaveManager.load_profile()
	_expect(loaded != null, "Profile should load")
	if loaded != null:
		_expect(loaded.profile_id == profile.profile_id, "Profile ID should round-trip")
		_expect(int(loaded.currencies.get("embers", 0)) == 25, "Currency should round-trip")


func _test_independent_builds() -> void:
	var profile := SaveManager.load_profile()
	if profile == null:
		_expect(false, "Profile required for build test")
		return
	var penitent := SaveManager.create_build(profile, "penitent", "Ashen Vow")
	var warlock := SaveManager.create_build(profile, "void_warlock", "Black Star")
	_expect(penitent != null and warlock != null, "Two builds should be created")
	if penitent == null or warlock == null:
		return
	penitent.level = 8
	penitent.build_specific_progress["fervor_mastery"] = 3
	warlock.level = 5
	warlock.build_specific_progress["corruption_mastery"] = 2
	SaveManager.save_build(penitent)
	SaveManager.save_build(warlock)
	var loaded_penitent := SaveManager.load_build(penitent.build_id)
	var loaded_warlock := SaveManager.load_build(warlock.build_id)
	_expect(loaded_penitent.level == 8, "Penitent level should remain independent")
	_expect(loaded_warlock.level == 5, "Warlock level should remain independent")
	_expect(not loaded_warlock.build_specific_progress.has("fervor_mastery"), "Warlock should not inherit Penitent progress")


func _test_rename_select_delete() -> void:
	var profile := SaveManager.load_profile()
	if profile == null or profile.build_ids.size() < 2:
		_expect(false, "Two builds required for management test")
		return
	var first_id := profile.build_ids[0]
	var second_id := profile.build_ids[1]
	_expect(SaveManager.rename_build(profile, first_id, "Faithbreaker") == OK, "Build should rename")
	_expect(SaveManager.load_build(first_id).build_name == "Faithbreaker", "Renamed build should persist")
	_expect(SaveManager.select_build(profile, first_id) == OK, "Build should select")
	_expect(SaveManager.delete_build(profile, first_id) == OK, "Build should delete")
	_expect(SaveManager.load_build(first_id) == null, "Deleted build should not load")
	_expect(profile.selected_build_id == second_id, "Deleting selected build should select remaining build")


func _test_backup_recovery() -> void:
	var profile := SaveManager.load_profile()
	if profile == null:
		_expect(false, "Profile required for backup test")
		return
	profile.display_name = "Backup Seed"
	SaveManager.save_profile(profile)
	profile.display_name = "Current Primary"
	SaveManager.save_profile(profile)
	var corrupt := FileAccess.open(SaveManager.PROFILE_PATH, FileAccess.WRITE)
	corrupt.store_string("{ definitely not json")
	corrupt.close()
	var recovered := SaveManager.load_profile()
	_expect(recovered != null, "Corrupted primary should recover from backup")
	if recovered != null:
		_expect(recovered.display_name == "Backup Seed", "Recovery should use last known backup")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(SaveManager.ROOT_DIR):
		_remove_tree(SaveManager.ROOT_DIR)


func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if entry != "." and entry != "..":
			var child := path.path_join(entry)
			if directory.current_is_dir():
				_remove_tree(child)
			else:
				DirAccess.remove_absolute(child)
		entry = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(path)
