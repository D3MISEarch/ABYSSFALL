class_name ImpactFeedback
extends Node3D

const PALETTE = preload("res://scripts/art/abyssfall_art_palette.gd")

const DEATH_DURATION := 0.28

var _visual_root: Node3D
var _profile: Dictionary = {}
var _base_position := Vector3.ZERO
var _base_scale := Vector3.ONE
var _base_rotation := Vector3.ZERO
var _local_recoil := Vector3.ZERO
var _elapsed := 0.0
var _mode: StringName = &"contact"
var _lethal := false


static func reaction_profile(tier: StringName, primary_hit: bool) -> Dictionary:
	var secondary_multiplier := 1.0 if primary_hit else 0.46
	if tier == &"heavy":
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
	var vibration := sin(clamped_progress * PI * 5.0) * float(profile.get("vibration", 0.0)) * envelope
	return {
		"recoil": float(profile.get("recoil_distance", 0.0)) * envelope,
		"scale": Vector3(1.0 + (1.0 - compression) * envelope, compression, 1.0 + (1.0 - compression) * envelope),
		"roll": float(profile.get("roll_degrees", 0.0)) * envelope + vibration
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
	var existing := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	if is_instance_valid(existing):
		existing.queue_free()
	var feedback := ImpactFeedback.new()
	feedback.name = "VoidbringerImpactFeedback"
	feedback._configure_contact(visual_root, incoming_direction, tier, primary_hit, lethal_hit)
	visual_root.add_child(feedback)
	return feedback


static func spawn_death_consequence(
	parent: Node, death_position: Vector3, tier: StringName
) -> ImpactFeedback:
	var parent_3d := parent as Node3D
	if not is_instance_valid(parent_3d):
		return null
	var feedback := ImpactFeedback.new()
	feedback.name = "VoidbringerDeathConsequence"
	feedback._configure_death(tier)
	feedback.position = parent_3d.to_local(death_position)
	parent_3d.add_child(feedback)
	return feedback


func _configure_contact(
	visual_root: Node3D,
	incoming_direction: Vector3,
	tier: StringName,
	primary_hit: bool,
	lethal_hit: bool
) -> void:
	_visual_root = visual_root
	_profile = reaction_profile(tier, primary_hit)
	_lethal = lethal_hit
	_base_position = visual_root.position
	_base_scale = visual_root.scale
	_base_rotation = visual_root.rotation_degrees
	_local_recoil = visual_root.global_transform.basis.inverse() * incoming_direction
	_local_recoil.y = 0.0
	if _local_recoil.length_squared() <= 0.0001:
		_local_recoil = Vector3.FORWARD
	else:
		_local_recoil = _local_recoil.normalized()
	_build_contact_visual(primary_hit)


func _configure_death(tier: StringName) -> void:
	_mode = &"death"
	_profile = reaction_profile(tier, true)
	_build_death_visual()


func _process(delta: float) -> void:
	_elapsed += delta
	if _mode == &"death":
		_process_death(delta)
		return
	_process_contact()


func _process_contact() -> void:
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
	_visual_root.rotation_degrees = _base_rotation + Vector3(0.0, 0.0, float(sample.get("roll", 0.0)))
	if progress >= 1.0:
		_visual_root.position = _base_position
		_visual_root.scale = _base_scale
		_visual_root.rotation_degrees = _base_rotation
		queue_free()


func _process_death(delta: float) -> void:
	var progress := clampf(_elapsed / DEATH_DURATION, 0.0, 1.0)
	scale = Vector3.ONE * lerpf(0.72, 2.25, progress)
	rotation.y += delta * (1.8 + float(_profile.get("roll_degrees", 0.0)) * 0.03)
	if progress >= 1.0:
		queue_free()


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
		fracture.position = Vector3(cos(angle) * 0.34, 0.10 + float(index % 2) * 0.08, sin(angle) * 0.34)
		fracture.rotation_degrees = Vector3(18.0 + float(index) * 9.0, rad_to_deg(angle), 31.0)
		fracture.material_override = fracture_material
		add_child(fracture)
