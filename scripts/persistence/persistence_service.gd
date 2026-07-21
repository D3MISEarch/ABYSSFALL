class_name PersistenceService
extends Node

signal profile_loaded(profile: ProfileData)
signal build_loaded(build: BuildData)
signal save_failed(context: String, error: Error)

const AUTOSAVE_INTERVAL_SECONDS := 60.0

var profile: ProfileData
var active_build: BuildData
var _autosave_elapsed := 0.0
var _dirty := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialize()


func _process(delta: float) -> void:
	if not _dirty:
		return
	_autosave_elapsed += delta
	if _autosave_elapsed >= AUTOSAVE_INTERVAL_SECONDS:
		save_all("autosave")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if _dirty:
			save_all("lifecycle")


func initialize(display_name: String = "Player") -> bool:
	profile = SaveManager.load_profile()
	if profile == null:
		profile = SaveManager.create_profile(display_name)
	if profile == null:
		save_failed.emit("initialize_profile", ERR_CANT_CREATE)
		return false
	profile_loaded.emit(profile)

	if not profile.selected_build_id.is_empty():
		active_build = SaveManager.load_build(profile.selected_build_id)
		if active_build == null:
			profile.selected_build_id = ""
			SaveManager.save_profile(profile)
		else:
			build_loaded.emit(active_build)
	return true


func has_active_build() -> bool:
	return active_build != null


func create_and_select_build(class_id: String, build_name: String = "New Build") -> BuildData:
	if profile == null and not initialize():
		return null
	var build := SaveManager.create_build(profile, class_id, build_name)
	if build == null:
		save_failed.emit("create_build", ERR_CANT_CREATE)
		return null
	active_build = build
	_dirty = false
	_autosave_elapsed = 0.0
	build_loaded.emit(active_build)
	return active_build


func select_build(build_id: String) -> bool:
	if profile == null:
		return false
	var error := SaveManager.select_build(profile, build_id)
	if error != OK:
		save_failed.emit("select_build", error)
		return false
	active_build = SaveManager.load_build(build_id)
	if active_build == null:
		save_failed.emit("load_selected_build", ERR_FILE_CORRUPT)
		return false
	build_loaded.emit(active_build)
	return true


func mark_dirty() -> void:
	_dirty = true


func save_all(context: String = "manual") -> Error:
	if profile == null:
		return ERR_UNCONFIGURED
	if active_build != null:
		var build_error := SaveManager.save_build(active_build)
		if build_error != OK:
			save_failed.emit(context + "_build", build_error)
			return build_error
	var profile_error := SaveManager.save_profile(profile)
	if profile_error != OK:
		save_failed.emit(context + "_profile", profile_error)
		return profile_error
	_dirty = false
	_autosave_elapsed = 0.0
	return OK
