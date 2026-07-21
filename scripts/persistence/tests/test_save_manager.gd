extends SceneTree

const SAVE_MANAGER_SCRIPT := preload("res://scripts/persistence/save_manager.gd")
const TEST_ROOT_DIR := "user://abyssfall"
const TEST_PROFILE_PATH := TEST_ROOT_DIR + "/profile.json"

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("START: Stage 1 persistence smoke tests")
	_cleanup()
	_run_case("profile round-trip", _test_profile_round_trip)
	_run_case("independent builds", _test_independent_builds)
	_run_case("rename/select/delete", _test_rename_select_delete)
	_run_case("profile backup recovery", _test_backup_recovery)
	_cleanup()

	if failures.is_empty():
		print("PASS: Stage 1 persistence smoke tests")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _save_call(method: StringName, arguments: Array = []) -> Variant:
	return SAVE_MANAGER_SCRIPT.callv(method, arguments)


func _run_case(label: String, test_callable: Callable) -> void:
	print("TEST: %s" % label)
	var failure_count_before: int = failures.size()
	test_callable.call()
	if failures.size() == failure_count_before:
		print("PASS: %s" % label)


func _test_profile_round_trip() -> void:
	var profile: Variant = _save_call(&"create_profile", ["Abyss Tester"])
	_expect(profile != null, "Profile should be created")
	if profile == null:
		return
	profile.currencies["embers"] = 25
	_expect(int(_save_call(&"save_profile", [profile])) == OK, "Profile should save")
	var loaded: Variant = _save_call(&"load_profile")
	_expect(loaded != null, "Profile should load")
	if loaded != null:
		_expect(loaded.profile_id == profile.profile_id, "Profile ID should round-trip")
		_expect(int(loaded.currencies.get("embers", 0)) == 25, "Currency should round-trip")


func _test_independent_builds() -> void:
	var profile: Variant = _save_call(&"load_profile")
	if profile == null:
		_expect(false, "Profile required for build test")
		return
	var penitent: Variant = _save_call(&"create_build", [profile, "penitent", "Ashen Vow"])
	var warlock: Variant = _save_call(&"create_build", [profile, "void_warlock", "Black Star"])
	_expect(penitent != null and warlock != null, "Two builds should be created")
	if penitent == null or warlock == null:
		return
	_expect(penitent.build_id != warlock.build_id, "Build IDs should be unique")
	penitent.level = 8
	penitent.build_specific_progress["fervor_mastery"] = 3
	warlock.level = 5
	warlock.build_specific_progress["corruption_mastery"] = 2
	_expect(int(_save_call(&"save_build", [penitent])) == OK, "Penitent build should save")
	_expect(int(_save_call(&"save_build", [warlock])) == OK, "Warlock build should save")
	var loaded_penitent: Variant = _save_call(&"load_build", [penitent.build_id])
	var loaded_warlock: Variant = _save_call(&"load_build", [warlock.build_id])
	_expect(loaded_penitent != null, "Penitent build should load")
	_expect(loaded_warlock != null, "Warlock build should load")
	if loaded_penitent == null or loaded_warlock == null:
		return
	_expect(loaded_penitent.level == 8, "Penitent level should remain independent")
	_expect(loaded_warlock.level == 5, "Warlock level should remain independent")
	_expect(not loaded_warlock.build_specific_progress.has("fervor_mastery"), "Warlock should not inherit Penitent progress")


func _test_rename_select_delete() -> void:
	var profile: Variant = _save_call(&"load_profile")
	if profile == null or profile.build_ids.size() < 2:
		_expect(false, "Two builds required for management test")
		return
	var first_id: String = str(profile.build_ids[0])
	var second_id: String = str(profile.build_ids[1])
	_expect(int(_save_call(&"rename_build", [profile, first_id, "Faithbreaker"])) == OK, "Build should rename")
	var renamed: Variant = _save_call(&"load_build", [first_id])
	_expect(renamed != null, "Renamed build should load")
	if renamed != null:
		_expect(renamed.build_name == "Faithbreaker", "Renamed build should persist")
	_expect(int(_save_call(&"select_build", [profile, first_id])) == OK, "Build should select")
	_expect(int(_save_call(&"delete_build", [profile, first_id])) == OK, "Build should delete")
	_expect(_save_call(&"load_build", [first_id]) == null, "Deleted build should not load")
	_expect(profile.selected_build_id == second_id, "Deleting selected build should select remaining build")
	var reloaded_profile: Variant = _save_call(&"load_profile")
	_expect(reloaded_profile != null, "Profile should reload after deletion")
	if reloaded_profile != null:
		_expect(reloaded_profile.selected_build_id == second_id, "Fallback selection should persist")
		_expect(not reloaded_profile.build_ids.has(first_id), "Deleted build ID should be removed from profile")


func _test_backup_recovery() -> void:
	var profile: Variant = _save_call(&"load_profile")
	if profile == null:
		_expect(false, "Profile required for backup test")
		return
	profile.display_name = "Backup Seed"
	_expect(int(_save_call(&"save_profile", [profile])) == OK, "Backup seed should save")
	profile.display_name = "Current Primary"
	_expect(int(_save_call(&"save_profile", [profile])) == OK, "Current primary should save")
	var corrupt := FileAccess.open(TEST_PROFILE_PATH, FileAccess.WRITE)
	_expect(corrupt != null, "Primary profile should open for corruption test")
	if corrupt == null:
		return
	corrupt.store_string("{ definitely not json")
	corrupt.close()
	var recovered: Variant = _save_call(&"load_profile")
	_expect(recovered != null, "Corrupted primary should recover from backup")
	if recovered != null:
		_expect(recovered.display_name == "Backup Seed", "Recovery should use last known backup")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)


func _cleanup() -> void:
	if DirAccess.dir_exists_absolute(TEST_ROOT_DIR):
		_remove_tree(TEST_ROOT_DIR)


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
	directory = null
	DirAccess.remove_absolute(path)
