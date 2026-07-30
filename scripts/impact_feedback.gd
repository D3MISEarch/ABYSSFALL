class_name ImpactFeedback
extends Node3D

signal fatal_started
signal fatal_finished
signal pulse_finished(pulse_id: StringName)

const PALETTE = preload("res://scripts/art/abyssfall_art_palette.gd")

const FEEDBACK_NODE_NAME := "VoidbringerImpactFeedback"
const CONSEQUENCE_NODE_NAME := "VoidbringerDeathConsequence"
const CONSEQUENCE_DURATION := 0.28

var _visual_root: Node3D
var _profile: Dictionary = {}
var _base_position := Vector3.ZERO
var _base_scale := Vector3.ONE
var _base_rotation := Vector3.ZERO
var _start_position := Vector3.ZERO
var _start_scale := Vector3.ONE
var _start_rotation := Vector3.ZERO
var _local_recoil := Vector3.FORWARD
var _elapsed := 0.0
var _mode: StringName = &"idle"
var _contact_active := false
var _fatal_active := false
var _cleanup_requested := false
var _cleanup_owner_ref
var _completion := Callable()
var _pulse_id: StringName = &""
var _fracture_root: Node3D
var _fatal_light: OmniLight3D
var _fatal_contact_accent_added := false


static func reaction_profile(tier: StringName, primary_hit: bool) -> Dictionary:
	var secondary_multiplier := 1.0 if primary_hit else 0.46
	if tier == &"heavy" or tier == &"boss":
		return {
			"recoil_distance": 0.075 * secondary_multiplier,
			"compression": 0.86 if primary_hit else 0.93,
			"roll_degrees": 3.8 if primary_hit else 1.6,
			"duration": 0.34 if primary_hit else 0.22,
			"vibration": 1.7
		}
	return {
		"recoil_distance": 0.22 * secondary_multiplier,
		"compression": 0.79 if primary_hit else 0.90,
		"roll_degrees": 9.0 if primary_hit else 3.5,
		"duration": 0.24 if primary_hit else 0.16,
		"vibration": 0.6
	}


static func reaction_sample(profile: Dictionary, progress: float) -> Dictionary:
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var envelope := sin(clamped_progress * PI)
	var compression := lerpf(1.0, float(profile.get("compression", 1.0)), envelope)
	var vibration := (
		sin(clamped_progress * PI * 5.0)
		* float(profile.get("vibration", 0.0))
		* envelope
	)
	return {
		"recoil": float(profile.get("recoil_distance", 0.0)) * envelope,
		"scale": Vector3(
			1.0 + (1.0 - compression) * envelope,
			compression,
			1.0 + (1.0 - compression) * envelope
		),
		"roll": float(profile.get("roll_degrees", 0.0)) * envelope + vibration
	}


static func pulse_profile(pulse_id: StringName) -> Dictionary:
	match pulse_id:
		&"attack_lunge":
			return {
				"duration": 0.16,
				"scale_peak": Vector3.ONE,
				"position_offset": Vector3(0.0, 0.0, -0.28),
				"roll_degrees": 0.0
			}
		&"attack_light":
			return {
				"duration": 0.18,
				"scale_peak": Vector3(0.90, 1.12, 0.90),
				"position_offset": Vector3.ZERO,
				"roll_degrees": 0.0
			}
		&"attack_heavy":
			return {
				"duration": 0.25,
				"scale_peak": Vector3(1.18, 0.88, 1.18),
				"position_offset": Vector3.ZERO,
				"roll_degrees": 0.0
			}
		&"boss_phase":
			return {
				"duration": 0.50,
				"scale_peak": Vector3(1.35, 1.35, 1.35),
				"position_offset": Vector3.ZERO,
				"roll_degrees": 0.0
			}
		_:
			return {
				"duration": 0.18,
				"scale_peak": Vector3.ONE,
				"position_offset": Vector3.ZERO,
				"roll_degrees": 0.0
			}


static func fatal_profile(tier: StringName) -> Dictionary:
	if tier == &"boss":
		return {
			"duration": 0.78,
			"compression": 0.42,
			"recoil_distance": 0.34,
			"roll_degrees": 22.0,
			"spin_degrees": 150.0,
			"fracture_count": 9,
			"light_energy": 7.0,
			"light_range": 5.6
		}
	if tier == &"heavy":
		return {
			"duration": 0.56,
			"compression": 0.36,
			"recoil_distance": 0.25,
			"roll_degrees": 16.0,
			"spin_degrees": 92.0,
			"fracture_count": 7,
			"light_energy": 5.8,
			"light_range": 4.4
		}
	return {
		"duration": 0.42,
		"compression": 0.31,
		"recoil_distance": 0.22,
		"roll_degrees": 18.0,
		"spin_degrees": 118.0,
		"fracture_count": 6,
		"light_energy": 5.0,
		"light_range": 3.8
	}


static func play_contact(
	visual_root: Node3D,
	incoming_direction: Vector3,
	tier: StringName,
	primary_hit: bool,
	lethal_hit: bool
) -> ImpactFeedback:
	if not is_instance_valid(visual_root):
		return null
	if lethal_hit:
		var fatal := play_fatal(visual_root, incoming_direction, tier)
		if is_instance_valid(fatal):
			fatal._add_contact_accent(primary_hit)
		return fatal
	var existing := _existing_feedback(visual_root)
	if is_instance_valid(existing):
		if existing.is_fatal_active():
			return existing
		if existing._mode == &"contact":
			existing._restart_contact(incoming_direction, tier, primary_hit)
			return existing
		_remove_nonfatal(existing, visual_root)
	var feedback := ImpactFeedback.new()
	feedback.name = FEEDBACK_NODE_NAME
	visual_root.add_child(feedback)
	feedback._configure_contact(visual_root, incoming_direction, tier, primary_hit)
	return feedback


static func play_pulse(
	visual_root: Node3D,
	pulse_id: StringName,
	completion: Callable = Callable()
) -> ImpactFeedback:
	if not is_instance_valid(visual_root):
		return null
	var existing := _existing_feedback(visual_root)
	if is_instance_valid(existing):
		if existing.is_fatal_active() or existing._mode == &"contact":
			return existing
		_remove_nonfatal(existing, visual_root)
	var feedback := ImpactFeedback.new()
	feedback.name = FEEDBACK_NODE_NAME
	visual_root.add_child(feedback)
	feedback._configure_pulse(visual_root, pulse_id, completion)
	return feedback


static func play_fatal(
	visual_root: Node3D,
	incoming_direction: Vector3,
	tier: StringName,
	cleanup_owner: Node = null
) -> ImpactFeedback:
	if not is_instance_valid(visual_root):
		return null
	var existing := _existing_feedback(visual_root)
	if is_instance_valid(existing):
		existing._attach_cleanup_owner(cleanup_owner)
		existing._request_fatal(incoming_direction, tier)
		return existing
	var feedback := ImpactFeedback.new()
	feedback.name = FEEDBACK_NODE_NAME
	visual_root.add_child(feedback)
	feedback._visual_root = visual_root
	feedback._capture_base()
	feedback._attach_cleanup_owner(cleanup_owner)
	feedback._request_fatal(incoming_direction, tier)
	return feedback


static func spawn_death_consequence(
	parent: Node, death_position: Vector3, tier: StringName
) -> ImpactFeedback:
	var parent_3d := parent as Node3D
	if not is_instance_valid(parent_3d):
		return null
	var feedback := ImpactFeedback.new()
	feedback.name = CONSEQUENCE_NODE_NAME
	feedback._configure_consequence(tier)
	feedback.position = parent_3d.to_local(death_position)
	parent_3d.add_child(feedback)
	return feedback


static func _existing_feedback(visual_root: Node3D) -> ImpactFeedback:
	return visual_root.get_node_or_null(FEEDBACK_NODE_NAME) as ImpactFeedback


static func _remove_nonfatal(existing: ImpactFeedback, visual_root: Node3D) -> void:
	existing.cancel_and_restore()
	if existing.get_parent() == visual_root:
		visual_root.remove_child(existing)
	existing.queue_free()


func is_fatal_active() -> bool:
	return _fatal_active


func debug_snapshot() -> Dictionary:
	return {
		"mode": _mode,
		"elapsed": _elapsed,
		"fatal_active": _fatal_active,
		"cleanup_requested": _cleanup_requested,
		"pulse_id": _pulse_id
	}


func cancel_and_restore() -> void:
	if _fatal_active:
		return
	if is_instance_valid(_visual_root):
		_restore_base()
	_visual_root = null
	_contact_active = false
	set_process(false)


func _restart_contact(
	incoming_direction: Vector3,
	tier: StringName,
	primary_hit: bool
) -> void:
	if _fatal_active or not is_instance_valid(_visual_root):
		return
	_restore_base()
	_clear_feedback_visuals()
	_configure_contact(_visual_root, incoming_direction, tier, primary_hit)


func _configure_contact(
	visual_root: Node3D,
	incoming_direction: Vector3,
	tier: StringName,
	primary_hit: bool
) -> void:
	_visual_root = visual_root
	_capture_base()
	_profile = reaction_profile(tier, primary_hit)
	_set_recoil_direction(incoming_direction)
	_elapsed = 0.0
	_mode = &"contact"
	_contact_active = true
	_fatal_active = false
	_build_contact_visual(primary_hit)
	set_process(true)


func _configure_pulse(
	visual_root: Node3D,
	pulse_id: StringName,
	completion: Callable
) -> void:
	_visual_root = visual_root
	_capture_base()
	_profile = pulse_profile(pulse_id)
	_elapsed = 0.0
	_mode = &"pulse"
	_pulse_id = pulse_id
	_completion = completion
	_contact_active = false
	_fatal_active = false
	set_process(true)


func _configure_consequence(tier: StringName) -> void:
	_profile = fatal_profile(tier)
	_elapsed = 0.0
	_mode = &"consequence"
	_build_death_visual()
	set_process(true)


func _capture_base() -> void:
	if not is_instance_valid(_visual_root):
		return
	_base_position = _visual_root.position
	_base_scale = _visual_root.scale
	_base_rotation = _visual_root.rotation_degrees


func _capture_fatal_start() -> void:
	if not is_instance_valid(_visual_root):
		return
	_start_position = _visual_root.position
	_start_scale = _visual_root.scale
	_start_rotation = _visual_root.rotation_degrees


func _restore_base() -> void:
	_visual_root.position = _base_position
	_visual_root.scale = _base_scale
	_visual_root.rotation_degrees = _base_rotation


func _set_recoil_direction(incoming_direction: Vector3) -> void:
	if not is_instance_valid(_visual_root):
		return
	var local_direction := _visual_root.global_transform.basis.inverse() * incoming_direction
	local_direction.y = 0.0
	if local_direction.length_squared() > 0.0001:
		_local_recoil = local_direction.normalized()
	elif _local_recoil.length_squared() <= 0.0001:
		_local_recoil = Vector3.FORWARD


func _attach_cleanup_owner(cleanup_owner: Node) -> void:
	if not is_instance_valid(cleanup_owner) or _cleanup_owner_ref != null:
		return
	_cleanup_owner_ref = weakref(cleanup_owner)


func _request_fatal(incoming_direction: Vector3, tier: StringName) -> void:
	_set_recoil_direction(incoming_direction)
	if _fatal_active:
		return
	if not is_instance_valid(_visual_root):
		return
	_capture_fatal_start()
	_clear_feedback_visuals()
	_profile = fatal_profile(tier)
	_elapsed = 0.0
	_mode = &"fatal"
	_contact_active = false
	_fatal_active = true
	_fatal_contact_accent_added = false
	_completion = Callable()
	_build_fatal_visual()
	fatal_started.emit()
	set_process(true)


func _add_contact_accent(primary_hit: bool) -> void:
	if not _fatal_active or _fatal_contact_accent_added:
		return
	_fatal_contact_accent_added = true
	var accent := MeshInstance3D.new()
	accent.name = "FatalPrimaryContact" if primary_hit else "FatalSecondaryContact"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.27 if primary_hit else 0.17
	torus.outer_radius = 0.33 if primary_hit else 0.21
	torus.rings = 20
	torus.ring_segments = 6
	accent.mesh = torus
	accent.rotation_degrees.x = 90.0
	accent.material_override = PALETTE.emissive(
		PALETTE.GRAVITATIONAL_WHITE if primary_hit else PALETTE.VOID_FRACTURE,
		5.2 if primary_hit else 3.4,
		0.08
	)
	add_child(accent)


func _process(delta: float) -> void:
	_elapsed += delta
	match _mode:
		&"contact":
			_process_contact()
		&"pulse":
			_process_pulse()
		&"fatal":
			_process_fatal()
		&"consequence":
			_process_consequence(delta)
		_:
			set_process(false)


func _process_contact() -> void:
	if not _contact_active:
		return
	if not is_instance_valid(_visual_root):
		queue_free()
		return
	var duration := maxf(float(_profile.get("duration", 0.20)), 0.01)
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	var sample := reaction_sample(_profile, progress)
	var recoil := float(sample.get("recoil", 0.0))
	var scale_sample: Vector3 = sample.get("scale", Vector3.ONE)
	_visual_root.position = _base_position + _local_recoil * recoil
	_visual_root.scale = Vector3(
		_base_scale.x * scale_sample.x,
		_base_scale.y * scale_sample.y,
		_base_scale.z * scale_sample.z
	)
	_visual_root.rotation_degrees = (
		_base_rotation + Vector3(0.0, 0.0, float(sample.get("roll", 0.0)))
	)
	if progress >= 1.0:
		_restore_base()
		_contact_active = false
		queue_free()


func _process_pulse() -> void:
	if not is_instance_valid(_visual_root):
		queue_free()
		return
	var duration := maxf(float(_profile.get("duration", 0.18)), 0.01)
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	var envelope := sin(progress * PI)
	var peak_scale: Vector3 = _profile.get("scale_peak", Vector3.ONE)
	var position_offset: Vector3 = _profile.get("position_offset", Vector3.ZERO)
	var scale_sample := Vector3.ONE.lerp(peak_scale, envelope)
	_visual_root.position = _base_position + position_offset * envelope
	_visual_root.scale = Vector3(
		_base_scale.x * scale_sample.x,
		_base_scale.y * scale_sample.y,
		_base_scale.z * scale_sample.z
	)
	_visual_root.rotation_degrees = (
		_base_rotation
		+ Vector3(0.0, 0.0, float(_profile.get("roll_degrees", 0.0)) * envelope)
	)
	if progress >= 1.0:
		_restore_base()
		var completed_id := _pulse_id
		var completion := _completion
		_completion = Callable()
		pulse_finished.emit(completed_id)
		if completion.is_valid():
			completion.call()
		queue_free()


func _process_fatal() -> void:
	if not is_instance_valid(_visual_root):
		_finish_fatal()
		return
	var duration := maxf(float(_profile.get("duration", 0.42)), 0.01)
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	var compression_progress := smoothstep(0.0, 1.0, clampf(progress / 0.42, 0.0, 1.0))
	var fracture_progress := smoothstep(
		0.0, 1.0, clampf((progress - 0.30) / 0.70, 0.0, 1.0)
	)
	var compression := float(_profile.get("compression", 0.31))
	var compressed_scale := Vector3(
		_start_scale.x * (1.0 + compression * 0.72 * compression_progress),
		_start_scale.y * (1.0 - compression * compression_progress),
		_start_scale.z * (1.0 + compression * 0.72 * compression_progress)
	)
	var final_scale := _start_scale * 0.025
	_visual_root.scale = compressed_scale.lerp(final_scale, fracture_progress)
	var recoil := float(_profile.get("recoil_distance", 0.22))
	_visual_root.position = (
		_start_position
		+ _local_recoil * recoil * (0.42 * compression_progress + 0.78 * fracture_progress)
		+ Vector3.UP * 0.12 * fracture_progress
	)
	_visual_root.rotation_degrees = (
		_start_rotation
		+ Vector3(
			-float(_profile.get("roll_degrees", 18.0)) * 0.35 * fracture_progress,
			float(_profile.get("spin_degrees", 118.0)) * fracture_progress,
			float(_profile.get("roll_degrees", 18.0)) * compression_progress
		)
	)
	if is_instance_valid(_fracture_root):
		_fracture_root.scale = Vector3.ONE * lerpf(0.52, 2.65, fracture_progress)
		_fracture_root.rotation.y = fracture_progress * 2.1
	if is_instance_valid(_fatal_light):
		_fatal_light.light_energy = (
			float(_profile.get("light_energy", 5.0))
			* (1.0 - smoothstep(0.10, 1.0, progress))
		)
	if progress >= 1.0:
		_finish_fatal()


func _process_consequence(delta: float) -> void:
	var progress := clampf(_elapsed / CONSEQUENCE_DURATION, 0.0, 1.0)
	scale = Vector3.ONE * lerpf(0.72, 2.25, progress)
	rotation.y += delta * (1.8 + float(_profile.get("roll_degrees", 0.0)) * 0.03)
	if progress >= 1.0:
		queue_free()


func _finish_fatal() -> void:
	if _cleanup_requested:
		return
	_cleanup_requested = true
	set_process(false)
	fatal_finished.emit()
	var cleanup_owner: Node
	if _cleanup_owner_ref != null:
		cleanup_owner = _cleanup_owner_ref.get_ref() as Node
	if is_instance_valid(cleanup_owner) and not cleanup_owner.is_queued_for_deletion():
		cleanup_owner.queue_free()
	queue_free()


func _clear_feedback_visuals() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_fracture_root = null
	_fatal_light = null


func _build_contact_visual(primary_hit: bool) -> void:
	var white_material := PALETTE.emissive(PALETTE.GRAVITATIONAL_WHITE, 4.0, 0.08)
	var fracture_material := PALETTE.emissive(PALETTE.VOID_FRACTURE, 3.0, 0.10)
	var ring := MeshInstance3D.new()
	ring.name = "PrimaryContactFrame" if primary_hit else "SecondaryContactFrame"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.26 if primary_hit else 0.16
	torus.outer_radius = 0.31 if primary_hit else 0.20
	torus.rings = 20
	torus.ring_segments = 6
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = white_material if primary_hit else fracture_material
	add_child(ring)

	var fracture := MeshInstance3D.new()
	fracture.name = "ImpactFracture"
	var prism := PrismMesh.new()
	prism.size = Vector3(0.035, 0.28 if primary_hit else 0.16, 0.03)
	fracture.mesh = prism
	fracture.position = Vector3(0.0, 0.08, -0.12)
	fracture.rotation_degrees = Vector3(24.0, 0.0, 28.0)
	fracture.material_override = fracture_material
	add_child(fracture)


func _build_fatal_visual() -> void:
	_fracture_root = Node3D.new()
	_fracture_root.name = "ProceduralFracture"
	add_child(_fracture_root)
	var white_material := PALETTE.emissive(PALETTE.GRAVITATIONAL_WHITE, 5.8, 0.06)
	var fracture_material := PALETTE.emissive(PALETTE.VOID_FRACTURE, 4.2, 0.08)
	var ring := MeshInstance3D.new()
	ring.name = "FractureStressRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.30
	torus.outer_radius = 0.38
	torus.rings = 24
	torus.ring_segments = 7
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = white_material
	_fracture_root.add_child(ring)
	var fracture_count := int(_profile.get("fracture_count", 6))
	for index in range(fracture_count):
		var fracture := MeshInstance3D.new()
		fracture.name = "FractureShard_%02d" % index
		var prism := PrismMesh.new()
		prism.size = Vector3(
			0.035 + float(index % 2) * 0.012,
			0.22 + float(index % 3) * 0.055,
			0.032
		)
		fracture.mesh = prism
		var angle := TAU * float(index) / float(maxi(fracture_count, 1))
		fracture.position = Vector3(
			cos(angle) * 0.34,
			0.08 + float(index % 2) * 0.10,
			sin(angle) * 0.34
		)
		fracture.rotation_degrees = Vector3(
			18.0 + float(index) * 7.0,
			rad_to_deg(angle),
			28.0 + float(index) * 8.0
		)
		fracture.material_override = white_material if index % 3 == 0 else fracture_material
		_fracture_root.add_child(fracture)
	_fatal_light = OmniLight3D.new()
	_fatal_light.name = "FractureLight"
	_fatal_light.light_color = PALETTE.GRAVITATIONAL_WHITE
	_fatal_light.light_energy = float(_profile.get("light_energy", 5.0))
	_fatal_light.omni_range = float(_profile.get("light_range", 3.8))
	_fatal_light.position = Vector3(0.0, 0.35, 0.0)
	add_child(_fatal_light)


func _build_death_visual() -> void:
	var white_material := PALETTE.emissive(PALETTE.GRAVITATIONAL_WHITE, 4.8, 0.08)
	var fracture_material := PALETTE.emissive(PALETTE.VOID_FRACTURE, 3.4, 0.10)
	var ring := MeshInstance3D.new()
	ring.name = "DeathAbsenceRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.32
	torus.outer_radius = 0.39
	torus.rings = 24
	torus.ring_segments = 7
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = white_material
	add_child(ring)
	for index in range(5):
		var fracture := MeshInstance3D.new()
		fracture.name = "DeathFracture_%02d" % index
		var prism := PrismMesh.new()
		prism.size = Vector3(0.045, 0.24 + float(index) * 0.025, 0.04)
		fracture.mesh = prism
		var angle := TAU * float(index) / 5.0
		fracture.position = Vector3(
			cos(angle) * 0.34,
			0.10 + float(index % 2) * 0.08,
			sin(angle) * 0.34
		)
		fracture.rotation_degrees = Vector3(
			18.0 + float(index) * 9.0, rad_to_deg(angle), 31.0
		)
		fracture.material_override = fracture_material
		add_child(fracture)
