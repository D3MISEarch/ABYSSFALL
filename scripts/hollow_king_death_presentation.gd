class_name HollowKingDeathPresentation
extends Node3D

## Boss-local, presentation-only observer for Hollow King's confirmed death.
## It receives only the already-dead fact plus immutable world-space visual points.

const MODE_ENABLED: StringName = &"enabled"
const MODE_REDUCED: StringName = &"reduced"
const MODE_DISABLED: StringName = &"disabled"

const COLLAPSE_DURATION_SECONDS := 0.18
const SUSPEND_DURATION_SECONDS := 0.24
const PAYOFF_DURATION_SECONDS := 0.20
const AFTERMATH_DURATION_SECONDS := 0.42
const TOTAL_DURATION_SECONDS := (
	COLLAPSE_DURATION_SECONDS
	+ SUSPEND_DURATION_SECONDS
	+ PAYOFF_DURATION_SECONDS
	+ AFTERMATH_DURATION_SECONDS
)
const FLOOR_OFFSET := -1.72

## Hard bounds prevent spectacle accumulation across replay/reset and scene teardown.
const MAX_DEATH_TRANSACTIONS := 1
const MAX_CORE_SINGULARITIES := 1
const MAX_RESIDUE_SCARS := 1
const MAX_LOCAL_LIGHTS := 1
const MAX_AUDIO_PLAYERS := 1
const MAX_CAMERA_IMPULSES := 1
const MAX_HAPTIC_EVENTS := 1
const MAX_FRAGMENTS := 6
const MAX_MOTES := 6
const MAX_PRESENTATION_HELPERS := 1
const ENABLED_FRAGMENT_COUNT := 6
const REDUCED_FRAGMENT_COUNT := 3
const ENABLED_MOTE_COUNT := 6
const REDUCED_MOTE_COUNT := 2

var mode: StringName = MODE_ENABLED
var transaction_count := 0
var completed_death_count := 0

var _state: StringName = &"idle"
var _active := false
var _death_consumed := false
var _elapsed := 0.0
var _core_local_position := Vector3.ZERO
var _silhouette: MeshInstance3D
var _singularity: Node3D
var _singularity_mesh: MeshInstance3D
var _residue: MeshInstance3D
var _local_light: OmniLight3D
var _fragments: Array[Dictionary] = []
var _motes: Array[MeshInstance3D] = []


func set_mode(presentation_mode: StringName) -> void:
	mode = presentation_mode if presentation_mode in [MODE_ENABLED, MODE_REDUCED, MODE_DISABLED] else MODE_ENABLED
	if mode == MODE_DISABLED:
		clear()


func observe_confirmed_death(boss_position: Vector3, chest_position: Vector3) -> bool:
	if mode == MODE_DISABLED or _death_consumed:
		return false
	_death_consumed = true
	_move_to_scene_root()
	_active = true
	_state = &"inward_collapse"
	_elapsed = 0.0
	transaction_count += 1
	completed_death_count += 1
	global_position = boss_position
	_core_local_position = chest_position - boss_position
	_create_death_effects()
	return true


func reset_for_replay() -> void:
	clear()
	_death_consumed = false
	transaction_count = 0
	completed_death_count = 0


func tick(delta: float) -> void:
	if not _active:
		return
	_elapsed = minf(_elapsed + maxf(delta, 0.0), TOTAL_DURATION_SECONDS)
	if _elapsed < COLLAPSE_DURATION_SECONDS:
		_state = &"inward_collapse"
		_tick_collapse(_elapsed / COLLAPSE_DURATION_SECONDS)
		return
	if _elapsed < COLLAPSE_DURATION_SECONDS + SUSPEND_DURATION_SECONDS:
		_state = &"fragment_suspension"
		_tick_suspension((_elapsed - COLLAPSE_DURATION_SECONDS) / SUSPEND_DURATION_SECONDS)
		return
	if _elapsed < COLLAPSE_DURATION_SECONDS + SUSPEND_DURATION_SECONDS + PAYOFF_DURATION_SECONDS:
		_state = &"final_payoff"
		_tick_payoff(
			(_elapsed - COLLAPSE_DURATION_SECONDS - SUSPEND_DURATION_SECONDS) / PAYOFF_DURATION_SECONDS
		)
		return
	_state = &"arena_aftermath"
	_tick_aftermath(
		(_elapsed - COLLAPSE_DURATION_SECONDS - SUSPEND_DURATION_SECONDS - PAYOFF_DURATION_SECONDS)
		/ AFTERMATH_DURATION_SECONDS
	)
	if _elapsed >= TOTAL_DURATION_SECONDS:
		clear()


func clear() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_silhouette = null
	_singularity = null
	_singularity_mesh = null
	_residue = null
	_local_light = null
	_fragments.clear()
	_motes.clear()
	_active = false
	_state = &"idle"
	_elapsed = 0.0


func snapshot() -> Dictionary:
	return {
		"mode": mode,
		"state": _state,
		"transactions": transaction_count,
		"completed_deaths": completed_death_count,
		"active_transactions": 1 if _active else 0,
		"core_singularities": 1 if is_instance_valid(_singularity) else 0,
		"residue_scars": 1 if is_instance_valid(_residue) else 0,
		"local_lights": 1 if is_instance_valid(_local_light) else 0,
		"audio_players": 0,
		"camera_impulses": 0,
		"haptic_events": 0,
		"fragments": _fragments.size(),
		"motes": _motes.size(),
		"effect_child_count": get_child_count(),
		"maxima": {
			"death_transactions": MAX_DEATH_TRANSACTIONS,
			"core_singularities": MAX_CORE_SINGULARITIES,
			"residue_scars": MAX_RESIDUE_SCARS,
			"local_lights": MAX_LOCAL_LIGHTS,
			"audio_players": MAX_AUDIO_PLAYERS,
			"camera_impulses": MAX_CAMERA_IMPULSES,
			"haptic_events": MAX_HAPTIC_EVENTS,
			"fragments": MAX_FRAGMENTS,
			"motes": MAX_MOTES,
			"presentation_helpers": MAX_PRESENTATION_HELPERS,
		},
	}


func _process(delta: float) -> void:
	tick(delta)


func _exit_tree() -> void:
	clear()


func _create_death_effects() -> void:
	_silhouette = MeshInstance3D.new()
	_silhouette.name = "HollowKingDeathCompressedSilhouette"
	var silhouette_mesh := CapsuleMesh.new()
	silhouette_mesh.radius = 0.78
	silhouette_mesh.height = 2.1
	_silhouette.mesh = silhouette_mesh
	_silhouette.position = _core_local_position + Vector3(0.0, -0.38, 0.34)
	_silhouette.scale = Vector3(1.15, 1.0, 0.95)
	_silhouette.material_override = _emissive_material(Color(0.045, 0.018, 0.08), 1.2, 0.52)
	add_child(_silhouette)

	_singularity = Node3D.new()
	_singularity.name = "HollowKingDeathSingularity"
	_singularity.position = _core_local_position
	add_child(_singularity)
	_singularity_mesh = MeshInstance3D.new()
	_singularity_mesh.name = "HollowKingDeathCoreVacancy"
	var singularity_mesh := SphereMesh.new()
	singularity_mesh.radius = 0.28
	singularity_mesh.height = 0.56
	_singularity_mesh.mesh = singularity_mesh
	_singularity_mesh.material_override = _emissive_material(Color(0.88, 0.82, 1.0), 3.8, 0.44)
	_singularity.add_child(_singularity_mesh)

	var fragment_count := REDUCED_FRAGMENT_COUNT if mode == MODE_REDUCED else ENABLED_FRAGMENT_COUNT
	for index in range(mini(fragment_count, MAX_FRAGMENTS)):
		var angle := TAU * float(index) / float(fragment_count)
		var fragment := MeshInstance3D.new()
		fragment.name = "HollowKingDeathFragment_%02d" % index
		var fragment_mesh := PrismMesh.new()
		fragment_mesh.size = Vector3(0.16 + float(index % 2) * 0.05, 0.34 + float(index % 3) * 0.10, 0.11)
		fragment.mesh = fragment_mesh
		var source_position := _core_local_position + Vector3(
			cos(angle) * (1.08 + float(index % 2) * 0.16),
			-0.62 + float(index % 3) * 0.42,
			sin(angle) * (0.82 + float(index % 2) * 0.14)
		)
		fragment.position = source_position
		fragment.material_override = _emissive_material(
			Color(0.18, 0.08, 0.29) if index % 2 == 0 else Color(0.58, 0.30, 0.92),
			2.8,
			0.84
		)
		add_child(fragment)
		_fragments.append({
			"node": fragment,
			"source_position": source_position,
			"suspend_position": _core_local_position + Vector3(cos(angle) * 0.64, -0.10 + float(index % 3) * 0.18, sin(angle) * 0.58),
			"angle": angle,
		})

	var mote_count := REDUCED_MOTE_COUNT if mode == MODE_REDUCED else ENABLED_MOTE_COUNT
	for index in range(mini(mote_count, MAX_MOTES)):
		var mote := MeshInstance3D.new()
		mote.name = "HollowKingDeathMote_%02d" % index
		var mote_mesh := SphereMesh.new()
		mote_mesh.radius = 0.035 + float(index % 2) * 0.012
		mote_mesh.height = mote_mesh.radius * 2.0
		mote.mesh = mote_mesh
		mote.material_override = _emissive_material(Color(0.94, 0.90, 1.0), 4.2, 0.76)
		add_child(mote)
		_motes.append(mote)


func _move_to_scene_root() -> void:
	var scene_root := get_tree().current_scene
	if is_instance_valid(scene_root) and get_parent() != scene_root:
		reparent(scene_root, true)


func _tick_collapse(progress: float) -> void:
	if is_instance_valid(_silhouette):
		_silhouette.scale = Vector3(lerpf(1.15, 0.32, progress), lerpf(1.0, 1.34, progress), lerpf(0.95, 0.32, progress))
		_silhouette.rotation_degrees.y = progress * 34.0
		_set_material_alpha(_silhouette.material_override as StandardMaterial3D, lerpf(0.52, 0.20, progress))
	if is_instance_valid(_singularity_mesh):
		_singularity_mesh.scale = Vector3.ONE * lerpf(0.64, 1.32, progress)
		_set_material_alpha(_singularity_mesh.material_override as StandardMaterial3D, lerpf(0.44, 0.90, progress))
	for entry: Dictionary in _fragments:
		var fragment := entry.get("node") as MeshInstance3D
		if is_instance_valid(fragment):
			fragment.position = (entry.get("source_position") as Vector3).lerp(entry.get("suspend_position") as Vector3, progress)
			fragment.rotation = Vector3(progress * 1.6, float(entry.get("angle", 0.0)) + progress, progress * 0.8)
	_tick_motes(progress, 0.88)


func _tick_suspension(progress: float) -> void:
	if is_instance_valid(_silhouette):
		_silhouette.scale = Vector3(0.32, lerpf(1.34, 0.82, progress), 0.32)
		_set_material_alpha(_silhouette.material_override as StandardMaterial3D, lerpf(0.20, 0.06, progress))
	if is_instance_valid(_singularity_mesh):
		_singularity_mesh.scale = Vector3.ONE * lerpf(1.32, 0.92, progress)
	for entry: Dictionary in _fragments:
		var fragment := entry.get("node") as MeshInstance3D
		if not is_instance_valid(fragment):
			continue
		var suspended := entry.get("suspend_position") as Vector3
		var angle := float(entry.get("angle", 0.0)) + progress * 1.8
		fragment.position = suspended + Vector3(cos(angle) * 0.08, sin(progress * PI + float(entry.get("angle", 0.0))) * 0.08, sin(angle) * 0.08)
		fragment.rotation = Vector3(1.6 + progress * 2.4, angle, progress * 1.7)
	_tick_motes(progress, 0.64)


func _tick_payoff(progress: float) -> void:
	if is_instance_valid(_silhouette):
		_silhouette.scale = Vector3.ONE * lerpf(0.22, 0.02, progress)
		_set_material_alpha(_silhouette.material_override as StandardMaterial3D, 0.06 * (1.0 - progress))
	if is_instance_valid(_singularity_mesh):
		_singularity_mesh.scale = Vector3.ONE * lerpf(0.92, 2.10, sin(progress * PI))
		_set_material_alpha(_singularity_mesh.material_override as StandardMaterial3D, lerpf(0.90, 0.18, progress))
	if mode == MODE_ENABLED and not is_instance_valid(_local_light):
		_local_light = OmniLight3D.new()
		_local_light.name = "HollowKingDeathLocalLight"
		_local_light.position = _core_local_position
		_local_light.light_color = Color(0.78, 0.54, 1.0)
		_local_light.light_energy = 5.2
		_local_light.omni_range = 5.0
		add_child(_local_light)
	for entry: Dictionary in _fragments:
		var fragment := entry.get("node") as MeshInstance3D
		if not is_instance_valid(fragment):
			continue
		var suspended := entry.get("suspend_position") as Vector3
		fragment.position = suspended.lerp(_core_local_position + Vector3(0.0, -0.14, 0.0), progress)
		fragment.scale = Vector3.ONE * lerpf(1.0, 0.08, progress)
		_set_material_alpha(fragment.material_override as StandardMaterial3D, 0.84 * (1.0 - progress))
	_tick_motes(progress, 0.20)


func _tick_aftermath(progress: float) -> void:
	if not is_instance_valid(_residue):
		_create_aftermath()
	if is_instance_valid(_singularity_mesh):
		_singularity_mesh.scale = Vector3.ONE * lerpf(0.20, 0.05, progress)
		_set_material_alpha(_singularity_mesh.material_override as StandardMaterial3D, 0.18 * (1.0 - progress))
	if is_instance_valid(_residue):
		_residue.scale = Vector3.ONE * lerpf(1.0, 0.72, progress)
		_set_material_alpha(_residue.material_override as StandardMaterial3D, 0.42 * (1.0 - progress))
	if is_instance_valid(_local_light):
		_local_light.light_energy = 5.2 * pow(maxf(1.0 - progress, 0.0), 2.0)
	for entry: Dictionary in _fragments:
		var fragment := entry.get("node") as MeshInstance3D
		if is_instance_valid(fragment):
			fragment.position = _core_local_position + Vector3(0.0, -0.14 - progress * 0.34, 0.0)
			_set_material_alpha(fragment.material_override as StandardMaterial3D, 0.08 * (1.0 - progress))
	_tick_motes(progress, 0.0)


func _create_aftermath() -> void:
	_residue = MeshInstance3D.new()
	_residue.name = "HollowKingDeathArenaScar"
	var residue_mesh := CylinderMesh.new()
	residue_mesh.top_radius = 1.32
	residue_mesh.bottom_radius = 1.48
	residue_mesh.height = 0.018
	residue_mesh.radial_segments = 28
	_residue.mesh = residue_mesh
	_residue.position = Vector3(0.0, FLOOR_OFFSET + 0.01, 0.0)
	_residue.material_override = _emissive_material(Color(0.10, 0.02, 0.16), 1.8, 0.42)
	add_child(_residue)


func _tick_motes(progress: float, radius_scale: float) -> void:
	for index in range(_motes.size()):
		var mote := _motes[index]
		if not is_instance_valid(mote):
			continue
		var angle := TAU * float(index) / float(_motes.size()) + progress * 2.4
		var radius := (0.46 + float(index % 2) * 0.12) * radius_scale
		mote.position = _core_local_position + Vector3(cos(angle) * radius, sin(angle * 1.7) * 0.22, sin(angle) * radius)
		mote.scale = Vector3.ONE * lerpf(1.0, 0.06, progress)
		_set_material_alpha(mote.material_override as StandardMaterial3D, 0.76 * maxf(radius_scale, 0.0))


func _emissive_material(color: Color, emission_energy: float, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.metallic = 0.10
	material.roughness = 0.26
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	return material


func _set_material_alpha(material: StandardMaterial3D, alpha: float) -> void:
	if material == null:
		return
	var color := material.albedo_color
	material.albedo_color = Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))
