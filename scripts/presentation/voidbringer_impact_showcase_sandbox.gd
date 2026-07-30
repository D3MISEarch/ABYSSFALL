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
	_configure_showcase_camera()
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
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and _handle_showcase_key(key_event.physical_keycode):
			return
	elif event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if button_event.pressed and _handle_showcase_button(button_event.button_index):
			return
	super._unhandled_input(event)


func _handle_showcase_key(keycode: int) -> bool:
	if keycode == KEY_F1 or keycode == KEY_7:
		return simulate_showcase_command(&"mode_full")
	if keycode == KEY_F2 or keycode == KEY_8:
		return simulate_showcase_command(&"mode_reduced")
	if keycode == KEY_F3 or keycode == KEY_9:
		return simulate_showcase_command(&"mode_disabled")
	if keycode == KEY_H:
		return simulate_showcase_command(&"toggle_haptics")
	if keycode == KEY_Z:
		return simulate_showcase_command(&"demo_combo")
	if keycode == KEY_X:
		return simulate_showcase_command(&"demo_lethal")
	return false


func _handle_showcase_button(button_index: int) -> bool:
	if button_index == JOY_BUTTON_DPAD_LEFT:
		return simulate_showcase_command(&"mode_full")
	if button_index == JOY_BUTTON_DPAD_UP:
		return simulate_showcase_command(&"mode_reduced")
	if button_index == JOY_BUTTON_DPAD_RIGHT:
		return simulate_showcase_command(&"mode_disabled")
	return false


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


func _configure_showcase_camera() -> void:
	var camera := get_viewport().get_camera_3d()
	if not is_instance_valid(camera):
		for child: Node in get_children():
			if child is Camera3D:
				camera = child as Camera3D
				break
	if not is_instance_valid(camera):
		return
	camera.position = Vector3(0.0, 8.6, 11.0)
	camera.fov = 58.0
	camera.look_at(Vector3(0.0, 0.45, -0.65), Vector3.UP)


func _build_showcase_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "ShowcaseHUD"
	add_child(canvas)
	showcase_label = Label.new()
	showcase_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	showcase_label.offset_left = -610.0
	showcase_label.offset_top = 18.0
	showcase_label.offset_right = -24.0
	showcase_label.offset_bottom = 430.0
	showcase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	showcase_label.add_theme_font_size_override("font_size", 18)
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
	var last_audio := audio_snapshot.get("last_audio_report", {}) as Dictionary
	var environment_snapshot := {} if environment_reaction == null else environment_reaction.debug_snapshot()
	showcase_label.text = "\n".join([
		"SAVAGE IMPACT SHOWCASE",
		"7 FULL   8 REDUCED   9 DISABLED",
		"DPAD LEFT / UP / RIGHT ALSO CHANGES MODE",
		"H TOGGLE HAPTICS   Z COMBO   X LETHAL   C RESET",
		"MODE %s   HAPTICS %s" % [
			String(settings_snapshot.get("effective_mode", &"full")).to_upper(),
			"ON" if haptics_enabled else "OFF",
		],
		"AUDIO SCALE x%.2f   ACTIVE %d   LAST %s" % [
			float(settings_snapshot.get("audio_scale", 0.0)),
			int(audio_snapshot.get("active_voice_count", 0)),
			String(last_audio.get("profile_id", &"none")).to_upper(),
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
	var mode := presentation_settings.effective_mode()
	if mode == &"disabled":
		return
	super._create_contact_flash(impact)
	if contact_flashes.is_empty():
		return
	var entry: Dictionary = contact_flashes.back()
	var root := entry.get("node") as Node3D
	if not is_instance_valid(root):
		return
	var full_mode := mode == &"full"
	var fatal := bool(impact.get("fatal", false))
	var critical := bool(impact.get("critical", false))
	var color := Color(0.93, 0.88, 1.0) if not critical else Color(1.0, 0.48, 0.86)
	if fatal:
		color = Color(0.98, 0.95, 1.0)
	var ring := MeshInstance3D.new()
	ring.name = "ShowcaseImpactShockRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.46 if full_mode else 0.30
	torus.outer_radius = 0.60 if full_mode else 0.39
	torus.rings = 28
	torus.ring_segments = 8
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = _material(color, 9.0 if full_mode else 4.0)
	root.add_child(ring)
	var halo := MeshInstance3D.new()
	halo.name = "ShowcaseImpactHalo"
	var halo_mesh := SphereMesh.new()
	halo_mesh.radius = 0.40 if full_mode else 0.25
	halo_mesh.height = 0.80 if full_mode else 0.50
	halo.mesh = halo_mesh
	halo.material_override = _material(Color(0.30, 0.06, 0.70), 7.0 if full_mode else 2.5)
	root.add_child(halo)
	var light := OmniLight3D.new()
	light.name = "ShowcaseImpactLight"
	light.light_color = color
	light.light_energy = 9.0 if fatal else (7.0 if full_mode else 2.5)
	light.omni_range = 5.5 if full_mode else 3.0
	light.position.y = 0.25
	root.add_child(light)
	var duration := 0.62 if fatal and full_mode else (0.44 if full_mode else 0.24)
	entry["duration"] = duration
	entry["remaining"] = duration
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
	var start_scale := 0.72 if mode == &"full" else 0.82
	var finish_scale := 2.85 if mode == &"full" else 1.42
	for index in range(contact_flashes.size() - 1, -1, -1):
		var entry: Dictionary = contact_flashes[index]
		var remaining := maxf(float(entry.get("remaining", 0.0)) - delta, 0.0)
		var duration := maxf(float(entry.get("duration", 0.20)), 0.001)
		var node := entry.get("node") as Node3D
		if is_instance_valid(node):
			var progress := 1.0 - remaining / duration
			node.scale = Vector3.ONE * lerpf(start_scale, finish_scale, progress)
			node.rotation.y = progress * 0.85
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
