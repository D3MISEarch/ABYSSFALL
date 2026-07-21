extends Node

const CHARACTER_FACTORY = preload("res://scripts/core/character_factory.gd")
const CLASS_SELECTION_SCRIPT = preload("res://scripts/ui/class_selection_screen.gd")
const DIAGNOSTIC_OVERLAY_SCRIPT = preload("res://scripts/tooling/playtest_diagnostic_overlay.gd")
const GAMEPLAY_SCENE = preload("res://gameplay.tscn")

var class_selection: ClassSelectionScreen
var gameplay_root: Node3D
var diagnostic_overlay: PlaytestDiagnosticOverlay


func _ready() -> void:
	_install_diagnostic_overlay()
	var command_line_class := _get_command_line_class()
	if CHARACTER_FACTORY.has_class(command_line_class):
		call_deferred("_launch_gameplay", command_line_class)
		return
	if Persistence.has_active_build() and CHARACTER_FACTORY.has_class(Persistence.active_build.class_id):
		call_deferred("_launch_gameplay", Persistence.active_build.class_id)
		return
	_show_class_selection()


func _install_diagnostic_overlay() -> void:
	if is_instance_valid(diagnostic_overlay):
		return
	diagnostic_overlay = DIAGNOSTIC_OVERLAY_SCRIPT.new()
	diagnostic_overlay.name = "PlaytestDiagnosticOverlay"
	add_child(diagnostic_overlay)


func _show_class_selection() -> void:
	if is_instance_valid(class_selection):
		return
	class_selection = CLASS_SELECTION_SCRIPT.new()
	class_selection.name = "ClassSelectionScreen"
	class_selection.class_confirmed.connect(_on_class_confirmed)
	add_child(class_selection)


func _on_class_confirmed(class_id: String) -> void:
	if not CHARACTER_FACTORY.has_class(class_id):
		push_warning("Class-selection screen requested an unavailable class: %s" % class_id)
		return
	var build_name := "%s Build" % class_id.replace("_", " ").capitalize()
	var build := Persistence.create_and_select_build(class_id, build_name)
	if build == null:
		push_error("Could not create persistent build for class: %s" % class_id)
		return
	_launch_gameplay(build.class_id)


func _launch_gameplay(class_id: String) -> void:
	if is_instance_valid(gameplay_root):
		return
	if is_instance_valid(class_selection):
		class_selection.queue_free()
		class_selection = null

	gameplay_root = GAMEPLAY_SCENE.instantiate()
	gameplay_root.requested_class_id = class_id
	add_child(gameplay_root)


func _get_command_line_class() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--class="):
			return argument.trim_prefix("--class=")
	return ""
