class_name VoidbringerImpactShowcaseSandbox
extends VoidbringerFoundationSandbox

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const HAPTICS_SCRIPT = preload("res://scripts/presentation/voidbringer_haptics.gd")
const AUDIO_SCRIPT = preload("res://scripts/presentation/voidbringer_impact_audio.gd")
const PRESENTER_SCRIPT = preload("res://scripts/presentation/voidbringer_impact_presenter.gd")
const ENVIRONMENT_REACTION_SCRIPT = preload("res://scripts/presentation/voidbringer_environment_reaction.gd")

var presentation_settings: VoidbringerPresentationSettings
var haptics: VoidbringerHaptics
var impact_audio: VoidbringerImpactAudio
var impact_presenter: VoidbringerImpactPresenter
var environment_reaction: VoidbringerEnvironmentReaction
var showcase_label: Label
var haptics_enabled := true
var last_showcase_report: Dictionary = {}


func _ready() -> void:
	super._ready()
	name = "VoidbringerImpactShowcaseSandbox"
	presentation_settings = SETTINGS_SCRIPT.new()
	presentation_settings.configure(&"full", true, true)
	haptics = HAPTICS_SCRIPT.new(presentation_settings)
	impact_audio = AUDIO_SCRIPT.new() as VoidbringerImpactAudio
	impact_audio.name = "VoidbringerImpactAudio"
	impact_audio.configure(presentation_settings)
	add_child(impact_audio)
	_configure_connected_controller()
	impact_presenter = PRESENTER_SCRIPT.new(presentation_settings, haptics)
	impact_presenter.impact_presented.connect(_on_showcase_impact_presented)
	impact_presenter.skill_presented.connect(_on_showcase_skill_presented)
	impact_presenter.bind(controller)
	environment_reaction = ENVIRONMENT_REACTION_SCRIPT.new()
	environment_reaction.name = "BoundedEnvironmentReaction"
	environment_reaction.configure(presentation_settings)
	add_child(environment_reaction)
	environment_reaction.build_showcase_props()
	_build_showcase_hud()
	_refresh_showcase_hud()
	print("ABYSSFALL_SANDBOX_LAUNCHED:voidbringer_showcase")


func _process(delta: float) -> void:
	super._process(delta)
	if impact_audio != null:
		impact_audio.tick(delta)
	if environment_reaction != null:
		environment_reaction.tick(delta)


func _exit_tree() -> void:
	if impact_presenter != null:
		impact_presenter.clear()
	if impact_audio != null:
		impact_audio.clear()
	if environment_reaction != null:
		environment_reaction.clear()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		match (event as InputEventKey).physical_keycode:
			KEY_F1:
				simulate_showcase_command(&"mode_full")
				return
			KEY_F2:
				simulate_showcase_command(&"mode_reduced")
				return
			KEY_F3:
				simulate_showcase_command(&"mode_disabled")
				return
			KEY_H:
				simulate_showcase_command(&"toggle_haptics")
				return
			KEY_Z:
				simulate_showcase_command(&"demo_combo")
				return
			KEY_X:
				simulate_showcase_command(&"demo_lethal")
				return
	super._unhandled_input(event)


func simulate_command(command: StringName) -> bool:
	if command in [&"clear", &"reset"]:
		if haptics != null:
			haptics.clear()
		if impact_audio != null:
			impact_audio.clear()
	var result := super.simulate_command(command)
	if command in [&"clear", &"reset"] and environment_reaction != null:
		environment_reaction.reset_reactions()
	_refresh_showcase_hud()
	return result


func simulate_showcase_command(command: StringName) -> bool:
	match command:
		&"mode_full":
			_set_presentation_mode(&"full")
		&"mode_reduced":
			_set_presentation_mode(&"reduced")
		&"mode_disabled":
			_set_presentation_mode(&"disabled")
		&"toggle_haptics":
			haptics_enabled = not haptics_enabled
			presentation_settings.configure(
				presentation_settings.mode,
				true,
				haptics_enabled
			)
			if not haptics_enabled:
				haptics.clear()
			last_status = "HAPTICS %s" % ("ON" if haptics_enabled else "OFF")
		&"demo_combo":
			simulate_command(&"clear")
			simulate_command(&"mass_brand_terrain")
			simulate_command(&"mass_brand_corpse")
			simulate_command(&"fire_null_shard")
			last_status = "SHOWCASE COMBO FIRED"
		&"demo_lethal":
			simulate_command(&"clear")
			enemy_fixture.health = 8
			simulate_command(&"mass_brand_enemy")
			last_status = "SHOWCASE LETHAL BRAND"
		_:
			return false
	_refresh_presentation()
	_refresh_showcase_hud()
	return true


func debug_showcase_snapshot() -> Dictionary:
	return {
		"presentation": presentation_settings.snapshot(),
		"presenter": {} if impact_presenter == null else impact_presenter.debug_snapshot(),
		"audio": {} if impact_audio == null else impact_audio.debug_snapshot(),
		"environment": {} if environment_reaction == null else environment_reaction.debug_snapshot(),
		"last_showcase_report": last_showcase_report.duplicate(true),
		"contact_visual_count": contact_flashes.size(),
		"target_feedback_count": _count_named_nodes(enemy_fixture, "VoidbringerImpactFeedback"),
		"haptics_enabled": haptics_enabled,
		"foundation": debug_snapshot(),
	}


func _set_presentation_mode(mode: StringName) -> void:
	presentation_settings.configure(mode, true, haptics_enabled)
	if mode == &"disabled":
		haptics.clear()
		if impact_audio != null:
			impact_audio.clear()
		_clear_children(contact_visual_root)
		contact_flashes.clear()
		if environment_reaction != null:
			environment_reaction.reset_reactions()
	last_status = "PRESENTATION %s" % String(mode).to_upper()


func _configure_connected_controller() -> void:
	var connected := Input.get_connected_joypads()
	if not connected.is_empty():
		haptics.configure_device(int(connected[0]))


func _build_showcase_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ShowcaseHUD"
	add_child(canvas)
	showcase_label = Label.new()
	showcase_label.position = Vector2(1020.0, 18.0)
	showcase_label.size = Vector2(560.0, 380.0)
	showcase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	showcase_label.add_theme_font_size_override("font_size", 17)
	showcase_label.add_theme_color_override("font_color", Color(0.90, 0.88, 1.0))
	showcase_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	showcase_label.add_theme_constant_override("shadow_offset_x", 2)
	showcase_label.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(showcase_label)


func _refresh_showcase_hud() -> void:
	if not is_instance_valid(showcase_label) or presentation_settings == null:
		return
	var settings_snapshot := presentation_settings.snapshot()
	var haptic_snapshot := {} if haptics == null else haptics.debug_snapshot()
	var audio_snapshot := {} if impact_audio == null else impact_audio.debug_snapshot()
	var environment_snapshot := {} if environment_reaction == null else environment_reaction.debug_snapshot()
	showcase_label.text = "\n".join([
		"SAVAGE IMPACT SHOWCASE",
		"F1 FULL   F2 REDUCED   F3 DISABLED",
		"H TOGGLE HAPTICS   Z COMBO   X LETHAL",
		"MODE %s   HAPTICS %s" % [
			String(settings_snapshot.get("effective_mode", &"full")).to_upper(),
			"ON" if haptics_enabled else "OFF",
		],
		"AUDIO SCALE x%.2f   ACTIVE %d" % [
			float(settings_snapshot.get("audio_scale", 0.0)),
			int(audio_snapshot.get("active_voice_count", 0)),
		],
		"RUMBLE SCALE x%.2f   START CALLS %d" % [
			float(settings_snapshot.get("rumble_scale", 0.0)),
			int(haptic_snapshot.get("start_call_count", 0)),
		],
		"ENVIRONMENT ACTIVE %d / %d" % [
			int(environment_snapshot.get("active_prop_count", 0)),
			int(environment_snapshot.get("prop_count", 0)),
		],
		"LAST VISUAL %s   LAST HAPTIC %s" % [
			"YES" if bool(last_showcase_report.get("visual_requested", false)) else "NO",
			"YES" if bool(last_showcase_report.get("haptic_requested", false)) else "NO",
		],
	])


func _on_showcase_impact_presented(report: Dictionary) -> void:
	last_showcase_report = report.duplicate(true)
	if impact_audio != null:
		impact_audio.play_impact(report.get("impact", {}))
	if environment_reaction != null:
		environment_reaction.consume_impact(report.get("impact", {}))
	_refresh_showcase_hud()


func _on_showcase_skill_presented(report: Dictionary) -> void:
	if impact_audio != null:
		impact_audio.play_skill_commit(report.get("skill", {}))
	if last_showcase_report.is_empty():
		last_showcase_report = report.duplicate(true)
	_refresh_showcase_hud()


func _create_contact_flash(impact: Dictionary) -> void:
	if presentation_settings == null:
		super._create_contact_flash(impact)
		return
	if presentation_settings.effective_mode() == &"disabled":
		return
	super._create_contact_flash(impact)
	if presentation_settings.effective_mode() == &"reduced" and not contact_flashes.is_empty():
		var entry: Dictionary = contact_flashes.back()
		entry["duration"] = 0.12
		entry["remaining"] = minf(float(entry.get("remaining", 0.12)), 0.12)
		contact_flashes[contact_flashes.size() - 1] = entry


func _update_contact_flashes(delta: float) -> void:
	if presentation_settings == null:
		super._update_contact_flashes(delta)
		return
	var mode := presentation_settings.effective_mode()
	if mode == &"disabled":
		_clear_children(contact_visual_root)
		contact_flashes.clear()
		return
	var start_scale := 0.55 if mode == &"full" else 0.78
	var finish_scale := 2.0 if mode == &"full" else 1.28
	for index in range(contact_flashes.size() - 1, -1, -1):
		var entry: Dictionary = contact_flashes[index]
		var remaining := maxf(float(entry.get("remaining", 0.0)) - delta, 0.0)
		var duration := maxf(float(entry.get("duration", 0.20)), 0.001)
		var node := entry.get("node") as Node3D
		if is_instance_valid(node):
			var progress := 1.0 - remaining / duration
			node.scale = Vector3.ONE * lerpf(start_scale, finish_scale, progress)
		if remaining <= 0.0:
			contact_flashes.remove_at(index)
			if is_instance_valid(node):
				node.queue_free()
		else:
			entry["remaining"] = remaining
			contact_flashes[index] = entry


func _count_named_nodes(root_node: Node, node_name: String) -> int:
	if not is_instance_valid(root_node):
		return 0
	var count := 1 if root_node.name == node_name else 0
	for child: Node in root_node.get_children():
		count += _count_named_nodes(child, node_name)
	return count
