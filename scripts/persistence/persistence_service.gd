class_name PersistenceService
extends Node

signal profile_loaded(profile: ProfileData)
signal build_loaded(build: BuildData)
signal save_failed(context: String, error: Error)

const AUTOSAVE_INTERVAL_SECONDS := 60.0
const SNAPSHOT_FIELDS: Array[String] = [
	"build_name",
	"level",
	"experience",
	"equipped_gear",
	"skills",
	"hotbar",
	"weapon_sets",
	"class_tree_state",
	"shared_core_state",
	"build_specific_progress",
	"quest_state",
	"statistics",
]
const MERGED_DICTIONARY_FIELDS: Array[String] = [
	"skills",
	"class_tree_state",
	"shared_core_state",
	"build_specific_progress",
	"quest_state",
	"statistics",
]

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
		flush_if_dirty("lifecycle")


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


func mutate_profile(mutator: Callable) -> bool:
	if profile == null or not mutator.is_valid():
		return false
	mutator.call(profile)
	mark_dirty()
	return true


func mutate_active_build(mutator: Callable) -> bool:
	if active_build == null or not mutator.is_valid():
		return false
	mutator.call(active_build)
	mark_dirty()
	return true


func apply_active_build_snapshot(snapshot: Dictionary) -> bool:
	if active_build == null:
		return false
	if str(snapshot.get("build_id", "")) != active_build.build_id:
		return false

	var applied_change := false
	for property_name: Variant in snapshot:
		var property_string := str(property_name)
		if not SNAPSHOT_FIELDS.has(property_string):
			continue
		var incoming: Variant = snapshot[property_name]
		if MERGED_DICTIONARY_FIELDS.has(property_string):
			if not incoming is Dictionary:
				continue
			var merged: Dictionary = active_build.get(property_string).duplicate(true)
			merged.merge(incoming, true)
			active_build.set(property_string, merged)
		else:
			active_build.set(property_string, incoming)
		applied_change = true

	if not applied_change:
		return false
	mark_dirty()
	return true


func mark_dirty() -> void:
	_dirty = true


func is_dirty() -> bool:
	return _dirty


func flush_if_dirty(context: String = "manual") -> Error:
	if not _dirty:
		return OK
	return save_all(context)


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
