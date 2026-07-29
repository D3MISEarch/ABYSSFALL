extends Node

const CHARACTER_FACTORY = preload("res://scripts/core/character_factory.gd")
const CLASS_SELECTION_SCRIPT = preload("res://scripts/ui/class_selection_screen.gd")
const FRONT_END_SCRIPT = preload("res://scripts/ui/front_end_screen.gd")
const BUILD_SELECTION_SCRIPT = preload("res://scripts/ui/build_selection_screen.gd")
const FRONT_END_BUILD_SERVICE = preload("res://scripts/ui/front_end_build_service.gd")
const DIAGNOSTIC_OVERLAY_SCRIPT = preload("res://scripts/tooling/playtest_diagnostic_overlay.gd")
const GAMEPLAY_SCENE = preload("res://gameplay.tscn")
const VOIDBRINGER_FOUNDATION_SANDBOX_SCENE = preload("res://scenes/voidbringer_foundation_sandbox.tscn")

var front_end: FrontEndScreen
var class_selection: ClassSelectionScreen
var build_selection: BuildSelectionScreen
var gameplay_root: Node3D
var sandbox_root: Node3D
var diagnostic_overlay: PlaytestDiagnosticOverlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_install_diagnostic_overlay()
	_install_front_end_input_map()
	var command_line_sandbox := _get_command_line_sandbox()
	if command_line_sandbox == "voidbringer_anchor":
		call_deferred("_launch_voidbringer_foundation_sandbox")
		return
	if Persistence.profile == null:
		Persistence.initialize()
	var command_line_class := _get_command_line_class()
	if CHARACTER_FACTORY.has_class(command_line_class):
		call_deferred("_launch_command_line_gameplay", command_line_class)
		return
	_sanitize_selected_build()
	if FRONT_END_BUILD_SERVICE.startup_route(Persistence.profile) == &"class_selection":
		_show_class_selection()
	else:
		_show_front_end()


func _install_diagnostic_overlay() -> void:
	if is_instance_valid(diagnostic_overlay):
		return
	diagnostic_overlay = DIAGNOSTIC_OVERLAY_SCRIPT.new()
	diagnostic_overlay.name = "PlaytestDiagnosticOverlay"
	add_child(diagnostic_overlay)


func _install_front_end_input_map() -> void:
	if not InputMap.has_action("menu_close"):
		InputMap.add_action("menu_close", 0.2)
	var has_escape := false
	var has_start := false
	for event: InputEvent in InputMap.action_get_events("menu_close"):
		if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
			has_escape = true
		elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
			has_start = true
	if not has_escape:
		var escape := InputEventKey.new()
		escape.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("menu_close", escape)
	if not has_start:
		var start := InputEventJoypadButton.new()
		start.button_index = JOY_BUTTON_START
		InputMap.action_add_event("menu_close", start)


func _show_front_end(status_message: String = "", failed: bool = false) -> void:
	_clear_front_end_screens()
	front_end = FRONT_END_SCRIPT.new() as FrontEndScreen
	if front_end == null:
		push_error("Could not create front-end screen.")
		return
	front_end.name = "FrontEndScreen"
	front_end.continue_requested.connect(_on_continue_requested)
	front_end.new_character_requested.connect(_on_new_character_requested)
	front_end.select_build_requested.connect(_on_select_build_requested)
	front_end.quit_requested.connect(_on_quit_requested)
	add_child(front_end)
	var summaries := _valid_build_summaries()
	var selected := FRONT_END_BUILD_SERVICE.selected_build(Persistence.profile)
	var selected_summary := FRONT_END_BUILD_SERVICE.build_summary(selected, true) if selected != null else {}
	front_end.configure(selected_summary, summaries.size())
	if not status_message.is_empty():
		front_end.show_status(status_message, failed)


func _show_class_selection() -> void:
	_clear_front_end_screens()
	class_selection = CLASS_SELECTION_SCRIPT.new() as ClassSelectionScreen
	if class_selection == null:
		push_error("Could not create class-selection screen.")
		return
	class_selection.name = "ClassSelectionScreen"
	class_selection.class_confirmed.connect(_on_class_confirmed)
	class_selection.back_requested.connect(_on_class_selection_back)
	add_child(class_selection)


func _show_build_selection() -> void:
	var summaries := _valid_build_summaries()
	if summaries.is_empty():
		_show_front_end("NO VALID CHARACTERS FOUND", true)
		return
	_clear_front_end_screens()
	build_selection = BUILD_SELECTION_SCRIPT.new() as BuildSelectionScreen
	if build_selection == null:
		push_error("Could not create build-selection screen.")
		return
	build_selection.name = "BuildSelectionScreen"
	build_selection.build_confirmed.connect(_on_build_confirmed)
	build_selection.back_requested.connect(_show_front_end)
	add_child(build_selection)
	build_selection.configure(summaries)


func _on_continue_requested() -> void:
	var selected := FRONT_END_BUILD_SERVICE.selected_build(Persistence.profile)
	if selected == null:
		_sanitize_selected_build()
		selected = FRONT_END_BUILD_SERVICE.selected_build(Persistence.profile)
	if selected == null:
		_show_front_end("NO VALID CONTINUE BUILD", true)
		return
	if Persistence.active_build == null or Persistence.active_build.build_id != selected.build_id:
		if not Persistence.select_build(selected.build_id):
			_show_front_end("COULD NOT LOAD SELECTED CHARACTER", true)
			return
	_launch_gameplay(selected.class_id)


func _on_new_character_requested() -> void:
	_show_class_selection()


func _on_select_build_requested() -> void:
	_show_build_selection()


func _on_quit_requested() -> void:
	var error := Persistence.flush_if_dirty("front_end_quit")
	if error != OK:
		if front_end != null:
			front_end.show_status("SAVE FAILED — QUIT CANCELLED", true)
		return
	get_tree().quit()


func _on_class_confirmed(class_id: String) -> void:
	if not CHARACTER_FACTORY.has_class(class_id):
		push_warning("Class-selection screen requested an unavailable class: %s" % class_id)
		return
	var build_name := FRONT_END_BUILD_SERVICE.next_default_build_name(Persistence.profile, class_id)
	var build := Persistence.create_and_select_build(class_id, build_name)
	if build == null:
		push_error("Could not create persistent build for class: %s" % class_id)
		_show_front_end("CHARACTER CREATION FAILED", true)
		return
	_launch_gameplay(build.class_id)


func _on_class_selection_back() -> void:
	_show_front_end()


func _on_build_confirmed(build_id: String) -> void:
	if build_id.is_empty() or not Persistence.select_build(build_id):
		_show_front_end("COULD NOT LOAD CHARACTER", true)
		return
	if Persistence.active_build == null or not CHARACTER_FACTORY.has_class(Persistence.active_build.class_id):
		_show_front_end("SELECTED CHARACTER IS INVALID", true)
		return
	_launch_gameplay(Persistence.active_build.class_id)


func _launch_command_line_gameplay(class_id: String) -> void:
	if Persistence.active_build == null or Persistence.active_build.class_id != class_id:
		var matching_id := ""
		for summary: Dictionary in _valid_build_summaries():
			if str(summary.get("class_id", "")) == class_id:
				matching_id = str(summary.get("build_id", ""))
				break
		if not matching_id.is_empty():
			Persistence.select_build(matching_id)
	_launch_gameplay(class_id)


func _launch_voidbringer_foundation_sandbox() -> void:
	if is_instance_valid(sandbox_root):
		return
	_clear_front_end_screens()
	sandbox_root = VOIDBRINGER_FOUNDATION_SANDBOX_SCENE.instantiate()
	add_child(sandbox_root)


func _launch_gameplay(class_id: String) -> void:
	if is_instance_valid(gameplay_root) or not CHARACTER_FACTORY.has_class(class_id):
		return
	_clear_front_end_screens()
	gameplay_root = GAMEPLAY_SCENE.instantiate()
	gameplay_root.requested_class_id = class_id
	if gameplay_root.has_signal("exit_to_front_end_requested"):
		gameplay_root.connect("exit_to_front_end_requested", Callable(self, "_on_gameplay_exit_requested"))
	add_child(gameplay_root)
	print("ABYSSFALL_CLASS_LAUNCHED:%s" % class_id)


func _on_gameplay_exit_requested() -> void:
	get_tree().paused = false
	var error := Persistence.flush_if_dirty("gameplay_exit_to_menu")
	if error != OK:
		push_error("Could not flush gameplay state before returning to the front end.")
		return
	if is_instance_valid(gameplay_root):
		gameplay_root.queue_free()
	gameplay_root = null
	call_deferred("_show_front_end", "SAVED", false)


func _sanitize_selected_build() -> void:
	var summaries := _valid_build_summaries()
	var selected := FRONT_END_BUILD_SERVICE.selected_build(Persistence.profile)
	if selected != null:
		if Persistence.active_build == null or Persistence.active_build.build_id != selected.build_id:
			Persistence.select_build(selected.build_id)
		return
	Persistence.active_build = null
	if Persistence.profile == null:
		return
	if summaries.is_empty():
		if not Persistence.profile.selected_build_id.is_empty():
			Persistence.profile.selected_build_id = ""
			SaveManager.save_profile(Persistence.profile)
		return
	Persistence.select_build(str(summaries[0].get("build_id", "")))


func _valid_build_summaries() -> Array[Dictionary]:
	return FRONT_END_BUILD_SERVICE.valid_build_summaries(Persistence.profile)


func _clear_front_end_screens() -> void:
	for screen in [front_end, class_selection, build_selection]:
		if is_instance_valid(screen):
			screen.queue_free()
	front_end = null
	class_selection = null
	build_selection = null


func _get_command_line_class() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--class="):
			return argument.trim_prefix("--class=")
	return ""


func _get_command_line_sandbox() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--sandbox="):
			return argument.trim_prefix("--sandbox=")
	return ""
