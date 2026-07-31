class_name HollowKingNovaPresentation
extends Node

## Boss-local, presentation-only observer for Hollow King's existing Nova attack.
## It receives the owner-provided countdown, radius, and release confirmation only.

const MODE_ENABLED: StringName = &"enabled"
const MODE_REDUCED: StringName = &"reduced"
const MODE_DISABLED: StringName = &"disabled"

const ANTICIPATION_WINDOW_SECONDS := 1.20
const IMMINENT_WINDOW_SECONDS := 0.42
const AFTERMATH_DURATION_SECONDS := 0.58
const FLOOR_OFFSET := -1.72

## These hard bounds make repeated Nova cycles deterministic and scene-local.
const MAX_ACTIVE_TRANSACTIONS := 1
const MAX_DANGER_BOUNDARIES := 1
const MAX_IMMINENT_EFFECT_SETS := 1
const MAX_AFTERMATH_SETS := 1
const MAX_MOTES := 6
const MAX_RESIDUE_NODES := 1
const MAX_LOCAL_LIGHTS := 1
const MAX_AUDIO_PLAYERS := 1
const MAX_CAMERA_IMPULSES := 1
const MAX_PRESENTATION_HELPERS := 1
const ENABLED_MOTE_COUNT := 6
const REDUCED_MOTE_COUNT := 2

var mode: StringName = MODE_ENABLED
var transaction_count := 0
var release_count := 0
var last_authoritative_radius := 0.0

var _host: Node3D
var _effect_root: Node3D
var _state: StringName = &"idle"
var _active_transaction := false
var _release_observed := false
var _anticipation_elapsed := 0.0
var _aftermath_remaining := 0.0
var _danger_boundary: MeshInstance3D
var _gathering_core: MeshInstance3D
var _imminent_crown: MeshInstance3D
var _aftermath_root: Node3D
var _aftermath_ring: MeshInstance3D
var _residue: MeshInstance3D
var _local_light: OmniLight3D
var _motes: Array[MeshInstance3D] = []


func configure(host: Node3D, presentation_mode: StringName = MODE_ENABLED) -> void:
	clear()
	_host = host
	set_mode(presentation_mode)
	_ensure_effect_root()


func set_mode(presentation_mode: StringName) -> void:
	mode = presentation_mode if presentation_mode in [MODE_ENABLED, MODE_REDUCED, MODE_DISABLED] else MODE_ENABLED
	if mode == MODE_DISABLED:
		clear()


func observe_nova_countdown(remaining_seconds: float, authoritative_radius: float, current_phase: int) -> bool:
	if mode == MODE_DISABLED or current_phase < 2 or authoritative_radius <= 0.0:
		return false
	if remaining_seconds > ANTICIPATION_WINDOW_SECONDS:
		return false
	if not _active_transaction:
		_begin_transaction(authoritative_radius)
	if not _active_transaction or _release_observed:
		return false
	if remaining_seconds <= IMMINENT_WINDOW_SECONDS and _state == &"anticipation":
		_enter_imminent_state()
	return true


func observe_confirmed_nova_release(authoritative_radius: float, current_phase: int) -> bool:
	if mode == MODE_DISABLED or current_phase < 2 or authoritative_radius <= 0.0 or _release_observed:
		return false
	if not _active_transaction:
		_begin_transaction(authoritative_radius)
	if not _active_transaction:
		return false
	_release_observed = true
	release_count += 1
	last_authoritative_radius = authoritative_radius
	_show_aftermath()
	return true


func tick(delta: float) -> void:
	var step := maxf(delta, 0.0)
	if step <= 0.0 or not _active_transaction:
		return
	if _state == &"anticipation" or _state == &"imminent":
		_anticipation_elapsed += step
		_tick_intent_visuals()
		return
	if _state != &"aftermath":
		return
	_aftermath_remaining = maxf(_aftermath_remaining - step, 0.0)
	var progress := 1.0 - _aftermath_remaining / AFTERMATH_DURATION_SECONDS
	_tick_aftermath_visuals(progress)
	if _aftermath_remaining <= 0.0:
		clear()


func clear() -> void:
	_remove_effect_children()
	_state = &"idle"
	_active_transaction = false
	_release_observed = false
	_anticipation_elapsed = 0.0
	_aftermath_remaining = 0.0
	last_authoritative_radius = 0.0


func snapshot() -> Dictionary:
	return {
		"mode": mode,
		"state": _state,
		"transactions": transaction_count,
		"releases": release_count,
		"active_transactions": 1 if _active_transaction else 0,
		"danger_boundaries": 1 if is_instance_valid(_danger_boundary) else 0,
		"imminent_effect_sets": 1 if is_instance_valid(_imminent_crown) else 0,
		"aftermath_sets": 1 if is_instance_valid(_aftermath_root) else 0,
		"motes": _motes.size(),
		"residue_nodes": 1 if is_instance_valid(_residue) else 0,
		"local_lights": 1 if is_instance_valid(_local_light) else 0,
		"audio_players": 0,
		"camera_impulses": 0,
		"authoritative_radius": last_authoritative_radius,
		"effect_child_count": _effect_root.get_child_count() if is_instance_valid(_effect_root) else 0,
		"maxima": {
			"active_transactions": MAX_ACTIVE_TRANSACTIONS,
			"danger_boundaries": MAX_DANGER_BOUNDARIES,
			"imminent_effect_sets": MAX_IMMINENT_EFFECT_SETS,
			"aftermath_sets": MAX_AFTERMATH_SETS,
			"motes": MAX_MOTES,
			"residue_nodes": MAX_RESIDUE_NODES,
			"local_lights": MAX_LOCAL_LIGHTS,
			"audio_players": MAX_AUDIO_PLAYERS,
			"camera_impulses": MAX_CAMERA_IMPULSES,
			"presentation_helpers": MAX_PRESENTATION_HELPERS,
		},
	}


func _process(delta: float) -> void:
	tick(delta)


func _exit_tree() -> void:
	clear()
	if is_instance_valid(_effect_root):
		_effect_root.queue_free()
	_effect_root = null


func _begin_transaction(authoritative_radius: float) -> void:
	_ensure_effect_root()
	if not is_instance_valid(_effect_root):
		return
	_remove_effect_children()
	_active_transaction = true
	_release_observed = false
	_state = &"anticipation"
	transaction_count += 1
	last_authoritative_radius = authoritative_radius
	_anticipation_elapsed = 0.0
	_create_intent_visuals(authoritative_radius)


func _enter_imminent_state() -> void:
	if not is_instance_valid(_effect_root) or is_instance_valid(_imminent_crown):
		return
	_state = &"imminent"
	_imminent_crown = MeshInstance3D.new()
	_imminent_crown.name = "HollowKingNovaImminentCrown"
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = 0.74
	crown_mesh.bottom_radius = 0.58
	crown_mesh.height = 0.055
	crown_mesh.radial_segments = 20
	_imminent_crown.mesh = crown_mesh
	_imminent_crown.position = Vector3(0.0, 1.30, 0.0)
	_imminent_crown.material_override = _emissive_material(Color(0.94, 0.90, 1.0), 6.4, 0.72)
	_effect_root.add_child(_imminent_crown)


func _show_aftermath() -> void:
	_remove_effect_children()
	if not is_instance_valid(_effect_root):
		return
	_state = &"aftermath"
	_aftermath_remaining = AFTERMATH_DURATION_SECONDS
	_aftermath_root = Node3D.new()
	_aftermath_root.name = "HollowKingNovaAftermath"
	_effect_root.add_child(_aftermath_root)

	_aftermath_ring = MeshInstance3D.new()
	_aftermath_ring.name = "HollowKingNovaPressureFlash"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = maxf(last_authoritative_radius - 0.16, 0.12)
	ring_mesh.outer_radius = last_authoritative_radius
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 8
	_aftermath_ring.mesh = ring_mesh
	_aftermath_ring.position.y = FLOOR_OFFSET + 0.055
	_aftermath_ring.rotation_degrees.x = 90.0
	_aftermath_ring.material_override = _emissive_material(Color(0.92, 0.88, 1.0), 8.0, 0.96)
	_aftermath_root.add_child(_aftermath_ring)

	_residue = MeshInstance3D.new()
	_residue.name = "HollowKingNovaFloorResidue"
	var residue_mesh := CylinderMesh.new()
	residue_mesh.top_radius = maxf(last_authoritative_radius * 0.46, 0.10)
	residue_mesh.bottom_radius = maxf(last_authoritative_radius * 0.54, 0.12)
	residue_mesh.height = 0.018
	residue_mesh.radial_segments = 24
	_residue.mesh = residue_mesh
	_residue.position.y = FLOOR_OFFSET + 0.01
	_residue.material_override = _emissive_material(Color(0.12, 0.025, 0.20), 2.2, 0.48)
	_aftermath_root.add_child(_residue)

	var mote_count := REDUCED_MOTE_COUNT if mode == MODE_REDUCED else ENABLED_MOTE_COUNT
	for index in range(mini(mote_count, MAX_MOTES)):
		var mote := MeshInstance3D.new()
		mote.name = "HollowKingNovaMote_%02d" % index
		var mote_mesh := PrismMesh.new()
		mote_mesh.size = Vector3(0.05, 0.22 + float(index % 3) * 0.04, 0.05)
		mote.mesh = mote_mesh
		var angle := TAU * float(index) / float(mote_count)
		mote.position = Vector3(cos(angle), FLOOR_OFFSET + 0.22 + float(index % 2) * 0.10, sin(angle)) * (0.54 + float(index % 2) * 0.18)
		mote.material_override = _emissive_material(Color(0.48, 0.18, 0.86) if index % 2 == 0 else Color(0.94, 0.90, 1.0), 4.8, 0.88)
		_aftermath_root.add_child(mote)
		_motes.append(mote)

	if mode == MODE_ENABLED:
		_local_light = OmniLight3D.new()
		_local_light.name = "HollowKingNovaLocalLight"
		_local_light.position = Vector3(0.0, 0.75, 0.0)
		_local_light.light_color = Color(0.72, 0.42, 1.0)
		_local_light.light_energy = 4.6
		_local_light.omni_range = 6.0
		_aftermath_root.add_child(_local_light)


func _create_intent_visuals(authoritative_radius: float) -> void:
	_danger_boundary = MeshInstance3D.new()
	_danger_boundary.name = "HollowKingNovaDangerBoundary"
	var boundary_mesh := TorusMesh.new()
	boundary_mesh.inner_radius = maxf(authoritative_radius - 0.14, 0.10)
	boundary_mesh.outer_radius = authoritative_radius
	boundary_mesh.rings = 32
	boundary_mesh.ring_segments = 8
	_danger_boundary.mesh = boundary_mesh
	_danger_boundary.position.y = FLOOR_OFFSET + 0.05
	_danger_boundary.rotation_degrees.x = 90.0
	_danger_boundary.material_override = _emissive_material(Color(0.30, 0.08, 0.48), 3.2, 0.68)
	_effect_root.add_child(_danger_boundary)

	_gathering_core = MeshInstance3D.new()
	_gathering_core.name = "HollowKingNovaIntentGathering"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.22
	core_mesh.height = 0.44
	_gathering_core.mesh = core_mesh
	_gathering_core.position = Vector3(0.0, 0.88, 0.0)
	_gathering_core.material_override = _emissive_material(Color(0.82, 0.78, 1.0), 4.2, 0.82)
	_effect_root.add_child(_gathering_core)


func _tick_intent_visuals() -> void:
	var cadence := 0.5 + 0.5 * sin(_anticipation_elapsed * (11.0 if _state == &"imminent" else 5.0))
	if is_instance_valid(_gathering_core):
		_gathering_core.scale = Vector3.ONE * lerpf(0.78, 1.26 if _state == &"imminent" else 1.05, cadence)
		_set_material_alpha(_gathering_core.material_override as StandardMaterial3D, lerpf(0.52, 0.96, cadence))
	if is_instance_valid(_danger_boundary):
		_set_material_alpha(_danger_boundary.material_override as StandardMaterial3D, lerpf(0.36, 0.88 if _state == &"imminent" else 0.68, cadence))
	if is_instance_valid(_imminent_crown):
		_imminent_crown.scale = Vector3.ONE * lerpf(0.74, 1.18, cadence)
		_set_material_alpha(_imminent_crown.material_override as StandardMaterial3D, lerpf(0.42, 0.96, cadence))


func _tick_aftermath_visuals(progress: float) -> void:
	if is_instance_valid(_aftermath_ring):
		_aftermath_ring.scale = Vector3.ONE * lerpf(0.72, 1.16, progress)
		_set_material_alpha(_aftermath_ring.material_override as StandardMaterial3D, 0.96 * (1.0 - progress))
	if is_instance_valid(_residue):
		_residue.scale = Vector3.ONE * lerpf(1.0, 0.74, progress)
		_set_material_alpha(_residue.material_override as StandardMaterial3D, 0.48 * (1.0 - progress))
	for index in range(_motes.size()):
		var mote := _motes[index]
		if not is_instance_valid(mote):
			continue
		var angle := TAU * float(index) / float(_motes.size()) + progress * 1.6
		var radius := lerpf(0.72 + float(index % 2) * 0.14, 0.10, progress)
		mote.position = Vector3(cos(angle) * radius, FLOOR_OFFSET + lerpf(0.30, 0.06, progress), sin(angle) * radius)
		mote.rotation = Vector3(progress * 4.0, angle, progress * 2.0)
		mote.scale = Vector3.ONE * lerpf(1.0, 0.12, progress)
		_set_material_alpha(mote.material_override as StandardMaterial3D, 0.88 * (1.0 - progress))
	if is_instance_valid(_local_light):
		_local_light.light_energy = 4.6 * pow(maxf(1.0 - progress, 0.0), 2.0)


func _ensure_effect_root() -> void:
	if is_instance_valid(_effect_root) or not is_instance_valid(_host):
		return
	_effect_root = Node3D.new()
	_effect_root.name = "HollowKingNovaPresentationRoot"
	_host.add_child(_effect_root)


func _remove_effect_children() -> void:
	if is_instance_valid(_effect_root):
		for child: Node in _effect_root.get_children():
			_effect_root.remove_child(child)
			child.queue_free()
	_danger_boundary = null
	_gathering_core = null
	_imminent_crown = null
	_aftermath_root = null
	_aftermath_ring = null
	_residue = null
	_local_light = null
	_motes.clear()


func _emissive_material(color: Color, emission_energy: float, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.metallic = 0.08
	material.roughness = 0.24
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	return material


func _set_material_alpha(material: StandardMaterial3D, alpha: float) -> void:
	if material == null:
		return
	var color := material.albedo_color
	material.albedo_color = Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))
