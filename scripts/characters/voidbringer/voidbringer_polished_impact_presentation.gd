class_name VoidbringerPolishedImpactPresentation
extends Node

## Scene-local, presentation-only observer for the owner-playtestable Null Shard impact.
## It receives an already-committed VoidbringerImpactResult and never resolves damage,
## critical state, validation, target health, rewards, or persistent state.

const IMPACT_FEEDBACK_SCRIPT = preload("res://scripts/impact_feedback.gd")

const MODE_ENABLED: StringName = &"enabled"
const MODE_REDUCED: StringName = &"reduced"
const MODE_DISABLED: StringName = &"disabled"

const ANTICIPATION_DURATION := 0.16
const CONTACT_DURATION := 0.42
const TARGET_RESPONSE_DURATION := 0.36
const CAMERA_IMPULSE_DURATION := 0.13
const CAMERA_IMPULSE_DISTANCE := 0.12
const AUDIO_DURATION_SECONDS := 0.09

## These bounds keep the spectacle replayable without a particle system, timer, or pool.
const MAX_ACTIVE_TRANSACTIONS := 1
const MAX_SHOCK_RINGS := 1
const MAX_INWARD_MOTES := 8
const MAX_RESIDUE_NODES := 1
const MAX_LIGHT_PULSES := 1
const MAX_AUDIO_PLAYERS := 1
const MAX_TARGET_FEEDBACK_OBJECTS := 1
const ENABLED_MOTE_COUNT := 8
const REDUCED_MOTE_COUNT := 4

var mode: StringName = MODE_ENABLED
var transaction_count := 0
var audio_event_count := 0
var haptic_event_count := 0
var last_critical := false
var last_cast_id: StringName = &""

var _effect_root: Node3D
var _camera: Camera3D
var _camera_base_position := Vector3.ZERO
var _camera_offset := Vector3.ZERO
var _camera_remaining := 0.0
var _anticipation_cues: Dictionary = {}
var _contact_cues: Array[Dictionary] = []
var _completed_cast_ids: Dictionary = {}
var _target_feedback: ImpactFeedback
var _target_feedback_remaining := 0.0
var _audio_player: AudioStreamPlayer
var _last_haptic_device := -1
var _last_profile: Dictionary = {}


func configure(effect_root: Node3D, camera: Camera3D, presentation_mode: StringName = MODE_ENABLED) -> void:
	clear()
	_effect_root = effect_root
	_camera = camera
	if is_instance_valid(_camera):
		_camera_base_position = _camera.position
	set_mode(presentation_mode)


func set_mode(presentation_mode: StringName) -> void:
	if presentation_mode not in [MODE_ENABLED, MODE_REDUCED, MODE_DISABLED]:
		mode = MODE_ENABLED
		return
	mode = presentation_mode
	if mode == MODE_DISABLED:
		clear()


func begin_null_shard_cast(projectile: VoidbringerNullShardProjectile) -> bool:
	if mode == MODE_DISABLED or projectile == null or not projectile.active:
		return false
	if not is_instance_valid(_effect_root) or _anticipation_cues.has(projectile.projectile_id):
		return false
	var cue := Node3D.new()
	cue.name = "NullShardCastAnticipation"
	_effect_root.add_child(cue)
	cue.global_position = projectile.origin
	var ring := MeshInstance3D.new()
	ring.name = "BraceRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.16
	torus.outer_radius = 0.20
	torus.rings = 16
	torus.ring_segments = 6
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = _emissive_material(Color(0.47, 0.30, 0.86), 3.4)
	cue.add_child(ring)
	var brace := MeshInstance3D.new()
	brace.name = "BraceDirection"
	var bar := BoxMesh.new()
	bar.size = Vector3(0.05, 0.05, 0.62)
	brace.mesh = bar
	brace.position = projectile.direction.normalized() * 0.28
	brace.material_override = _emissive_material(Color(0.88, 0.84, 1.0), 4.0)
	cue.add_child(brace)
	_anticipation_cues[projectile.projectile_id] = {
		"node": cue,
		"remaining": ANTICIPATION_DURATION,
		"duration": ANTICIPATION_DURATION,
	}
	return true


func present_accepted_null_shard(result: VoidbringerImpactResult, target: VoidbringerSandboxTarget) -> bool:
	if result == null or target == null or mode == MODE_DISABLED:
		return false
	var impact := result.snapshot()
	if StringName(str(impact.get("ability_id", ""))) != VoidbringerAbilityCatalog.NULL_SHARD:
		return false
	if int(impact.get("damage_applied", 0)) <= 0:
		return false
	var cast_id := StringName(str(impact.get("cast_id", "")))
	if cast_id == &"" or _completed_cast_ids.has(cast_id):
		return false
	_completed_cast_ids[cast_id] = true
	transaction_count += 1
	last_cast_id = cast_id
	last_critical = bool(impact.get("critical", false))
	_last_profile = _spectacle_profile(last_critical)

	if is_instance_valid(_effect_root):
		_create_contact_cue(impact, _last_profile)
		_present_target_response(target, impact)
	if mode == MODE_ENABLED:
		_begin_camera_impulse(impact.get("travel_direction", Vector3.FORWARD) as Vector3)
		_play_impact_audio(last_critical)
		_request_haptic()
	return true


func tick(delta: float) -> void:
	var step := maxf(delta, 0.0)
	if step <= 0.0:
		return
	_tick_anticipation(step)
	_tick_contacts(step)
	_tick_camera(step)
	_tick_target_response(step)


func clear() -> void:
	_restore_camera()
	for entry: Dictionary in _anticipation_cues.values():
		_queue_free(entry.get("node") as Node)
	_anticipation_cues.clear()
	_clear_contact_cues()
	if is_instance_valid(_target_feedback):
		_target_feedback.cancel_and_restore()
		_target_feedback.queue_free()
	_target_feedback = null
	_target_feedback_remaining = 0.0
	_completed_cast_ids.clear()
	transaction_count = 0
	audio_event_count = 0
	haptic_event_count = 0
	last_cast_id = &""
	last_critical = false
	_last_profile.clear()
	if is_instance_valid(_audio_player):
		_audio_player.stop()
		_audio_player.stream = null
	if _last_haptic_device >= 0:
		Input.stop_joy_vibration(_last_haptic_device)
	_last_haptic_device = -1


func snapshot() -> Dictionary:
	var active_contacts := _contact_cues.size()
	var mote_count := 0
	var residue_count := 0
	var light_count := 0
	for entry: Dictionary in _contact_cues:
		mote_count += (entry.get("motes", []) as Array).size()
		residue_count += 1 if is_instance_valid(entry.get("residue") as Node) else 0
		light_count += 1 if is_instance_valid(entry.get("light") as Node) else 0
	return {
		"mode": mode,
		"transactions": transaction_count,
		"active_transactions": active_contacts,
		"anticipation_cues": _anticipation_cues.size(),
		"contact_cues": active_contacts,
		"shock_rings": active_contacts,
		"inward_motes": mote_count,
		"residue_nodes": residue_count,
		"light_pulses": light_count,
		"camera_impulse_active": _camera_remaining > 0.0,
		"camera_restored": _camera_remaining <= 0.0 and _camera_offset == Vector3.ZERO,
		"target_response_active": is_instance_valid(_target_feedback) and _target_feedback_remaining > 0.0,
		"target_feedback_objects": 1 if is_instance_valid(_target_feedback) else 0,
		"audio_players": 1 if is_instance_valid(_audio_player) else 0,
		"audio_events": audio_event_count,
		"haptic_events": haptic_event_count,
		"last_critical": last_critical,
		"last_cast_id": last_cast_id,
		"last_profile": _last_profile.duplicate(true),
		"maxima": {
			"active_transactions": MAX_ACTIVE_TRANSACTIONS,
			"shock_rings": MAX_SHOCK_RINGS,
			"inward_motes": MAX_INWARD_MOTES,
			"residue_nodes": MAX_RESIDUE_NODES,
			"light_pulses": MAX_LIGHT_PULSES,
			"audio_players": MAX_AUDIO_PLAYERS,
			"target_feedback_objects": MAX_TARGET_FEEDBACK_OBJECTS,
		},
	}


func _exit_tree() -> void:
	clear()


func _spectacle_profile(critical: bool) -> Dictionary:
	var reduced := mode == MODE_REDUCED
	return {
		"critical": critical,
		"mote_count": REDUCED_MOTE_COUNT if reduced else ENABLED_MOTE_COUNT,
		"ring_peak": 1.48 if reduced else (2.38 if critical else 1.92),
		"residue_peak": 0.72 if reduced else (1.28 if critical else 0.96),
		"light_energy": 0.0 if reduced else (5.4 if critical else 3.2),
		"mote_turns": 0.52 if reduced else (1.18 if critical else 0.84),
	}


func _create_contact_cue(impact: Dictionary, profile: Dictionary) -> void:
	_clear_contact_cues()
	var cue := Node3D.new()
	cue.name = "NullShardContactFlash"
	_effect_root.add_child(cue)
	cue.global_position = impact.get("impact_point", Vector3.ZERO)

	var ring := MeshInstance3D.new()
	ring.name = "NullShardSingularityShockRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.24
	torus.outer_radius = 0.31
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ring.material_override = _emissive_material(
		Color(1.0, 0.74, 0.98) if bool(profile.get("critical", false)) else Color(0.68, 0.52, 1.0),
		7.8 if bool(profile.get("critical", false)) else 5.2,
		0.98
	)
	cue.add_child(ring)

	var mote_entries: Array[Dictionary] = []
	var mote_count := mini(int(profile.get("mote_count", 0)), MAX_INWARD_MOTES)
	for index in range(mote_count):
		var mote := MeshInstance3D.new()
		mote.name = "NullShardInwardMote_%02d" % index
		var prism := PrismMesh.new()
		prism.size = Vector3(0.055, 0.18 + float(index % 3) * 0.025, 0.055)
		mote.mesh = prism
		mote.material_override = _emissive_material(
			Color(0.92, 0.88, 1.0) if index % 2 == 0 else Color(0.40, 0.15, 0.84),
			4.8,
			0.88
		)
		cue.add_child(mote)
		mote_entries.append({
			"node": mote,
			"angle": TAU * float(index) / float(mote_count),
			"radius": 0.72 + float(index % 4) * 0.13,
			"height": -0.10 + float(index % 3) * 0.11,
		})

	var residue := MeshInstance3D.new()
	residue.name = "NullShardGroundResidue"
	var residue_mesh := CylinderMesh.new()
	residue_mesh.top_radius = 0.58
	residue_mesh.bottom_radius = 0.68
	residue_mesh.height = 0.018
	residue_mesh.radial_segments = 24
	residue.mesh = residue_mesh
	residue.position = Vector3(0.0, -minf(cue.global_position.y, 0.52), 0.0)
	residue.material_override = _emissive_material(Color(0.24, 0.06, 0.48), 2.4, 0.56)
	cue.add_child(residue)

	var light: OmniLight3D
	if float(profile.get("light_energy", 0.0)) > 0.0:
		light = OmniLight3D.new()
		light.name = "NullShardImpactLightPulse"
		light.light_color = Color(1.0, 0.72, 0.98) if bool(profile.get("critical", false)) else Color(0.61, 0.42, 1.0)
		light.light_energy = float(profile.get("light_energy", 0.0))
		light.omni_range = 3.2 if bool(profile.get("critical", false)) else 2.4
		cue.add_child(light)

	_contact_cues.append({
		"node": cue,
		"ring": ring,
		"motes": mote_entries,
		"residue": residue,
		"light": light,
		"remaining": CONTACT_DURATION,
		"duration": CONTACT_DURATION,
		"profile": profile.duplicate(true),
	})


func _present_target_response(target: VoidbringerSandboxTarget, impact: Dictionary) -> void:
	if not is_instance_valid(target.visual_root):
		return
	var travel_direction: Vector3 = impact.get("travel_direction", Vector3.FORWARD)
	var target_mass_class := StringName(str(impact.get("target_mass_class", &"standard")))
	var tier := &"heavy" if target_mass_class == &"heavy" else &"light"
	_target_feedback = IMPACT_FEEDBACK_SCRIPT.play_contact(
		target.visual_root,
		-travel_direction,
		tier,
		true,
		bool(impact.get("fatal", false))
	)
	if is_instance_valid(_target_feedback):
		_target_feedback.set_process(false)
		_target_feedback_remaining = TARGET_RESPONSE_DURATION


func _begin_camera_impulse(travel_direction: Vector3) -> void:
	if not is_instance_valid(_camera):
		return
	_camera_base_position = _camera.position
	var horizontal := Vector3(travel_direction.x, 0.0, travel_direction.z)
	if horizontal.length_squared() <= 0.000001:
		horizontal = Vector3.FORWARD
	_camera_offset = horizontal.normalized() * -CAMERA_IMPULSE_DISTANCE
	_camera_remaining = CAMERA_IMPULSE_DURATION
	_camera.position = _camera_base_position + _camera_offset


func _play_impact_audio(critical: bool) -> void:
	audio_event_count += 1
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		return
	_ensure_audio_player()
	if not is_instance_valid(_audio_player):
		return
	_audio_player.stream = _build_impact_stream(critical)
	_audio_player.volume_db = -8.0 if mode == MODE_REDUCED else -3.0
	_audio_player.play()


func _request_haptic() -> void:
	var joypads := Input.get_connected_joypads()
	if joypads.is_empty():
		return
	_last_haptic_device = int(joypads[0])
	Input.start_joy_vibration(_last_haptic_device, 0.18, 0.42, AUDIO_DURATION_SECONDS)
	haptic_event_count += 1


func _ensure_audio_player() -> void:
	if is_instance_valid(_audio_player):
		return
	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "NullShardImpactAudio"
	add_child(_audio_player)


func _build_impact_stream(critical: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var frames := 1984 if critical else 1544
	var data := PackedByteArray()
	data.resize(frames * 2)
	var frequency := 96.0 if critical else 72.0
	for index in range(frames):
		var progress := float(index) / float(frames)
		var envelope := pow(1.0 - progress, 2.8)
		var pressure := sin(TAU * frequency * progress * AUDIO_DURATION_SECONDS)
		var scrape := sin(TAU * (frequency * 2.4) * progress * AUDIO_DURATION_SECONDS) * 0.24
		data.encode_s16(index * 2, int(clampf((pressure + scrape) * envelope, -1.0, 1.0) * 32767.0))
	stream.data = data
	return stream


func _tick_anticipation(delta: float) -> void:
	for projectile_id: StringName in _anticipation_cues.keys().duplicate():
		var entry: Dictionary = _anticipation_cues.get(projectile_id, {})
		var remaining := maxf(float(entry.get("remaining", 0.0)) - delta, 0.0)
		var duration := maxf(float(entry.get("duration", ANTICIPATION_DURATION)), 0.001)
		var node := entry.get("node") as Node3D
		if is_instance_valid(node):
			var progress := 1.0 - remaining / duration
			node.scale = Vector3.ONE * lerpf(0.56, 1.45, progress)
		if remaining <= 0.0:
			_anticipation_cues.erase(projectile_id)
			_queue_free(node)
		else:
			entry["remaining"] = remaining
			_anticipation_cues[projectile_id] = entry


func _tick_contacts(delta: float) -> void:
	for index in range(_contact_cues.size() - 1, -1, -1):
		var entry: Dictionary = _contact_cues[index]
		var remaining := maxf(float(entry.get("remaining", 0.0)) - delta, 0.0)
		var duration := maxf(float(entry.get("duration", CONTACT_DURATION)), 0.001)
		var progress := 1.0 - remaining / duration
		_tick_spectacle_entry(entry, progress)
		if remaining <= 0.0:
			_contact_cues.remove_at(index)
			_queue_free(entry.get("node") as Node)
		else:
			entry["remaining"] = remaining
			_contact_cues[index] = entry


func _tick_spectacle_entry(entry: Dictionary, progress: float) -> void:
	var profile: Dictionary = entry.get("profile", {})
	var ring := entry.get("ring") as MeshInstance3D
	if is_instance_valid(ring):
		var ring_peak := float(profile.get("ring_peak", 1.8))
		var collapse := sin(clampf(progress, 0.0, 1.0) * PI)
		var radial_scale := lerpf(0.30, ring_peak, collapse)
		if progress > 0.52:
			radial_scale = lerpf(ring_peak, 0.06, (progress - 0.52) / 0.48)
		ring.scale = Vector3(radial_scale, lerpf(1.0, 0.16, progress), radial_scale)
		ring.rotation_degrees.z = progress * (210.0 if bool(profile.get("critical", false)) else 150.0)
		_set_material_alpha(ring.material_override as StandardMaterial3D, 1.0 - progress)

	var motes: Array = entry.get("motes", [])
	for mote_entry: Dictionary in motes:
		var mote := mote_entry.get("node") as MeshInstance3D
		if not is_instance_valid(mote):
			continue
		var angle := float(mote_entry.get("angle", 0.0)) + progress * TAU * float(profile.get("mote_turns", 0.8))
		var radius := lerpf(float(mote_entry.get("radius", 0.7)), 0.035, progress)
		mote.position = Vector3(cos(angle) * radius, lerpf(float(mote_entry.get("height", 0.0)), 0.0, progress), sin(angle) * radius)
		mote.rotation = Vector3(progress * 5.2, angle, progress * 3.6)
		mote.scale = Vector3.ONE * lerpf(1.0, 0.12, progress)
		_set_material_alpha(mote.material_override as StandardMaterial3D, 0.92 * (1.0 - progress))

	var residue := entry.get("residue") as MeshInstance3D
	if is_instance_valid(residue):
		var residue_peak := float(profile.get("residue_peak", 0.9))
		var residue_scale := lerpf(residue_peak, 0.10, progress)
		residue.scale = Vector3(residue_scale, 1.0, residue_scale)
		_set_material_alpha(residue.material_override as StandardMaterial3D, 0.56 * (1.0 - progress))

	var light := entry.get("light") as OmniLight3D
	if is_instance_valid(light):
		light.light_energy = float(profile.get("light_energy", 0.0)) * pow(maxf(1.0 - progress, 0.0), 2.0)


func _tick_camera(delta: float) -> void:
	if _camera_remaining <= 0.0:
		return
	_camera_remaining = maxf(_camera_remaining - delta, 0.0)
	if _camera_remaining <= 0.0:
		_restore_camera()


func _tick_target_response(delta: float) -> void:
	if not is_instance_valid(_target_feedback) or _target_feedback_remaining <= 0.0:
		return
	_target_feedback._process(delta)
	_target_feedback_remaining = maxf(_target_feedback_remaining - delta, 0.0)
	if _target_feedback_remaining <= 0.0 and is_instance_valid(_target_feedback):
		_target_feedback.cancel_and_restore()
		_target_feedback.queue_free()
		_target_feedback = null


func _clear_contact_cues() -> void:
	for entry: Dictionary in _contact_cues:
		_queue_free(entry.get("node") as Node)
	_contact_cues.clear()


func _restore_camera() -> void:
	if is_instance_valid(_camera):
		_camera.position = _camera_base_position
	_camera_offset = Vector3.ZERO
	_camera_remaining = 0.0


func _queue_free(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()


func _emissive_material(color: Color, emission_energy: float, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.metallic = 0.12
	material.roughness = 0.22
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	return material


func _set_material_alpha(material: StandardMaterial3D, alpha: float) -> void:
	if material == null:
		return
	var color := material.albedo_color
	material.albedo_color = Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))
