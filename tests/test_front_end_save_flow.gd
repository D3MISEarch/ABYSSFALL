extends SceneTree

const FRONT_END_BUILD_SERVICE = preload("res://scripts/ui/front_end_build_service.gd")
const FRONT_END_SCREEN = preload("res://scripts/ui/front_end_screen.gd")
const BUILD_SELECTION_SCREEN = preload("res://scripts/ui/build_selection_screen.gd")
const GAMEPLAY_PAUSE_MENU = preload("res://scripts/ui/gameplay_pause_menu.gd")
const PLAYABLE_PROGRESSION_BRIDGE = preload("res://scripts/ui/playable_progression_bridge.gd")
const GAMEPLAY_HARNESS = preload("res://tests/front_end_gameplay_harness.gd")

var failures: Array[String] = []
var created_build_ids: Array[String] = []
var prior_selected_build_id := ""
var service: PersistenceService


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	service = PersistenceService.new()
	root.add_child(service)
	await process_frame
	if service.profile == null:
		_fail("Persistence service must initialize a profile")
		_finish()
		return
	prior_selected_build_id = service.profile.selected_build_id

	_test_empty_route_without_touching_real_profile()
	var canary := _create_build("void_warlock", "ISSUE53 CANARY")
	var first := _create_build("void_warlock", "Void Warlock 1")
	var second := _create_build("penitent", "Ashen Witness")
	if canary == null or first == null or second == null:
		_finish()
		return
	first.level = 4
	first.experience = 31
	SaveManager.save_build(first)
	second.level = 7
	second.experience = 222
	SaveManager.save_build(second)
	service.select_build(second.build_id)

	await _test_build_index_and_front_end(second)
	await _test_build_selection_screen()
	await _test_pause_menu_and_manual_save(second)
	_test_canary_survives(canary)
	_finish()


func _test_empty_route_without_touching_real_profile() -> void:
	var empty_profile := ProfileData.create_new("Empty Route")
	_expect(
		FRONT_END_BUILD_SERVICE.startup_route(empty_profile) == &"class_selection",
		"Profile without builds should route to class selection"
	)


func _create_build(class_id: String, build_name: String) -> BuildData:
	var build := SaveManager.create_build(service.profile, class_id, build_name)
	_expect(build != null, "Build should be created: %s" % build_name)
	if build != null:
		created_build_ids.append(build.build_id)
		service.active_build = build
	return build


func _test_build_index_and_front_end(selected_build: BuildData) -> void:
	var summaries := FRONT_END_BUILD_SERVICE.valid_build_summaries(service.profile)
	_expect(summaries.size() >= 3, "Valid build index should include created builds")
	var selected := FRONT_END_BUILD_SERVICE.selected_build(service.profile)
	_expect(selected != null and selected.build_id == selected_build.build_id, "Selected build should resolve")
	_expect(
		FRONT_END_BUILD_SERVICE.startup_route(service.profile) == &"front_end",
		"Profile with valid builds should route to front end"
	)
	_expect(
		FRONT_END_BUILD_SERVICE.next_default_build_name(service.profile, "void_warlock") == "Void Warlock 2",
		"New character naming should not overwrite Void Warlock 1"
	)

	var screen := FRONT_END_SCREEN.new() as FrontEndScreen
	root.add_child(screen)
	await process_frame
	screen.configure(FRONT_END_BUILD_SERVICE.build_summary(selected, true), summaries.size())
	await process_frame
	_expect(not screen.continue_button.disabled, "Continue should be available for valid selected build")
	_expect(not screen.select_button.disabled, "Select Character should be available when builds exist")
	_expect(screen.continue_button.has_focus(), "Continue should receive initial controller focus")
	screen.queue_free()
	await process_frame


func _test_build_selection_screen() -> void:
	var screen := BUILD_SELECTION_SCREEN.new() as BuildSelectionScreen
	root.add_child(screen)
	await process_frame
	screen.configure(FRONT_END_BUILD_SERVICE.valid_build_summaries(service.profile))
	await process_frame
	_expect(screen.build_buttons.size() >= 3, "Build selection should render all valid builds")
	_expect(screen.build_buttons[0].has_focus(), "Build selection should begin with valid controller focus")
	var confirmation := {"build_id": ""}
	screen.build_confirmed.connect(func(build_id: String): confirmation["build_id"] = build_id)
	screen.build_buttons[0].emit_signal("pressed")
	await process_frame
	_expect(not str(confirmation["build_id"]).is_empty(), "Focused build should be confirmable")
	screen.queue_free()
	await process_frame


func _test_pause_menu_and_manual_save(selected_build: BuildData) -> void:
	service.select_build(selected_build.build_id)
	var harness = GAMEPLAY_HARNESS.new()
	root.add_child(harness)
	await process_frame
	var menu := GAMEPLAY_PAUSE_MENU.new() as GameplayPauseMenu
	var bridge := PLAYABLE_PROGRESSION_BRIDGE.new() as PlayableProgressionBridge
	harness.install_dependencies(menu, bridge)
	await process_frame
	_expect(
		bridge.configure_persistent(selected_build.class_id, service, selected_build.build_name),
		"Progression bridge should bind selected build"
	)
	bridge.runtime_character.level = 9
	bridge.runtime_character.experience = 123
	bridge.session.class_progression.reconcile_level_awards(9)
	menu.open_menu()
	await process_frame
	_expect(menu.resume_button.has_focus(), "Pause menu should begin with Resume focused")

	harness._save_runtime(false)
	var saved := SaveManager.load_build(selected_build.build_id)
	_expect(saved != null and saved.level == 9 and saved.experience == 123, "Save & Continue should flush runtime state")
	_expect(menu.status_label.text == "SAVED", "Successful manual save should be visible")

	var exit_state := {"requested": false}
	harness.exit_to_front_end_requested.connect(func(): exit_state["requested"] = true)
	harness._save_runtime(true)
	_expect(bool(exit_state["requested"]), "Save & Exit should request the front end only after a successful flush")
	harness.queue_free()
	await process_frame


func _test_canary_survives(canary: BuildData) -> void:
	var loaded := SaveManager.load_build(canary.build_id)
	_expect(loaded != null, "Unrelated canary build should survive front-end tests")
	if loaded != null:
		_expect(loaded.build_name == "ISSUE53 CANARY", "Canary build content should remain unchanged")


func _cleanup() -> void:
	var profile := SaveManager.load_profile()
	if profile == null:
		return
	for build_id: String in created_build_ids:
		if profile.build_ids.has(build_id):
			SaveManager.delete_build(profile, build_id)
	profile = SaveManager.load_profile()
	if profile == null:
		return
	if not prior_selected_build_id.is_empty() and profile.build_ids.has(prior_selected_build_id):
		SaveManager.select_build(profile, prior_selected_build_id)
	else:
		profile.selected_build_id = ""
		SaveManager.save_profile(profile)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _fail(message: String) -> void:
	failures.append(message)
	push_error("ASSERTION FAILED: %s" % message)


func _finish() -> void:
	_cleanup()
	if service != null:
		service.queue_free()
	if failures.is_empty():
		print("PASS: Front end and visible save flow")
		quit(0)
		return
	for failure: String in failures:
		print("FAIL: %s" % failure)
	quit(1)
