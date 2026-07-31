extends Node
class_name VisualFoundationVFX

const ROUTE_MARKER := "SunkenCryptsArtPass0"
const ROOT_NAME := "VisualFoundationV01_VFX"
const MAX_ACTIVE_EFFECTS := 18
const DEFAULT_LIFETIME := 1.35
const INSTALL_INTERVAL_SECONDS := 0.45
const PALE_VOID := Color(0.72, 0.70, 0.90, 0.72)
const RESTRAINED_VIOLET := Color(0.43, 0.18, 0.68, 0.62)
const DUST := Color(0.22, 0.19, 0.25, 0.62)

var _install_timer: Timer
var _installed_scene_id := 0
var _effect_root: Node3D
var _active_effects: Array[Node] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_install_timer = Timer.new()
	_install_timer.name = "VisualFoundationVFXInstallTimer"
	_install_timer.wait_time = INSTALL_INTERVAL_SECONDS
	_install_timer.one_shot = false
	_install_timer.autostart = true
	_install_timer.timeout.connect(_try_install_into_current_scene)
	add_child(_install_timer)
	call_deferred("_try_install_into_current_scene")


func _exit_tree() -> void:
	_clear_effects()


func _try_install_into_current_scene() -> void:
	var scene := get_tree().current_scene as Node3D
	if scene == null or scene.get_node_or_null(ROUTE_MARKER) == null:
		return
	var scene_id := scene.get_instance_id()
	if _installed_scene_id == scene_id and is_instance_valid(_effect_root):
		return
	_clear_effects()
	var existing := scene.get_node_or_null(ROOT_NAME) as Node3D
	if existing != null:
		_effect_root = existing
	else:
		_effect_root = Node3D.new()
		_effect_root.name = ROOT_NAME
		_effect_root.set_meta("presentation_only", true)
		_effect_root.set_meta("bounded_effect_budget", MAX_ACTIVE_EFFECTS)
		scene.add_child(_effect_root)
	_installed_scene_id = scene_id
	_call_deferred_route_settle()


func _call_deferred_route_settle() -> void:
	await get_tree().create_timer(0.35, true, false, true).timeout
	if not is_instance_valid(_effect_root):
		return
	spawn_dust_burst(Vector3(0.0, 0.18, -20.0), 0.62, 14)
	spawn_dust_burst(Vector3(0.0, 0.18, -73.0), 0.54, 12)
	spawn_void_pulse(Vector3(0.0, 0.12, -103.0), 0.78)


func spawn_gravity_burst(world_position: Vector3, strength: float = 1.0) -> void:
	if not _can_spawn():
		return
	var clamped_strength := clampf(strength, 0.25, 1.6)
	spawn_dust_burst(world_position, clamped_strength, clampi(int(16.0 * clamped_strength), 8, 24))
	spawn_void_pulse(world_position, clamped_strength)


func spawn_dust_burst(world_position: Vector3, strength: float = 1.0, amount: int = 16) -> void:
	if not _can_spawn():
		return
	var particles := CPUParticles3D.new()
	particles.name = "BoundedDustBurst"
	particles.global_position = world_position
	particles.one_shot = true
	particles.amount = clampi(amount, 6, 28)
	particles.lifetime = DEFAULT_LIFETIME
	particles.explosiveness = 0.92
	particles.randomness = 0.62
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.85 * clampf(strength, 0.35, 1.5)
	particles.direction = Vector3(0.0, 0.5, 0.0)
	particles.spread = 180.0
	particles.gravity = Vector3(0.0, -0.48, 0.0)
	particles.initial_velocity_min = 0.35 * strength
	particles.initial_velocity_max = 1.35 * strength
	particles.scale_amount_min = 0.55
	particles.scale_amount_max = 1.15
	particles.color = DUST
	particles.draw_pass_1 = _make_dust_mesh()
	particles.set_meta("presentation_only", true)
	_register_effect(particles, particles.lifetime + 0.25)
	particles.restart()


func spawn_void_pulse(world_position: Vector3, strength: float = 1.0) -> void:
	if not _can_spawn():
		return
	var pulse := MeshInstance3D.new()
	pulse.name = "BoundedVoidPulse"
	pulse.global_position = world_position
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.42
	mesh.bottom_radius = 0.42
	mesh.height = 0.025
	mesh.radial_segments = 32
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = RESTRAINED_VIOLET
	material.emission_enabled = true
	material.emission = PALE_VOID
	material.emission_energy_multiplier = 1.25
	material.no_depth_test = false
	mesh.material = material
	pulse.mesh = mesh
	pulse.scale = Vector3.ONE * 0.25
	pulse.set_meta("presentation_only", true)
	_register_effect(pulse, 0.72)
	var tween := pulse.create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse, "scale", Vector3.ONE * (2.6 * clampf(strength, 0.4, 1.5)), 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.68).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func clear_presentation_effects() -> void:
	_clear_effects(false)


func get_active_effect_count() -> int:
	_prune_invalid_effects()
	return _active_effects.size()


func _can_spawn() -> bool:
	_prune_invalid_effects()
	return is_instance_valid(_effect_root) and _active_effects.size() < MAX_ACTIVE_EFFECTS


func _register_effect(effect: Node3D, lifetime: float) -> void:
	if not is_instance_valid(_effect_root):
		effect.queue_free()
		return
	_effect_root.add_child(effect)
	_active_effects.append(effect)
	var timer := get_tree().create_timer(maxf(lifetime, 0.05), true, false, true)
	timer.timeout.connect(_expire_effect.bind(effect), CONNECT_ONE_SHOT)


func _expire_effect(effect: Node) -> void:
	_active_effects.erase(effect)
	if is_instance_valid(effect):
		effect.queue_free()


func _clear_effects(reset_root: bool = true) -> void:
	for effect in _active_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	_active_effects.clear()
	if reset_root:
		_effect_root = null
		_installed_scene_id = 0


func _prune_invalid_effects() -> void:
	for index in range(_active_effects.size() - 1, -1, -1):
		if not is_instance_valid(_active_effects[index]):
			_active_effects.remove_at(index)


func _make_dust_mesh() -> Mesh:
	var mesh := SphereMesh.new()
	mesh.radius = 0.018
	mesh.height = 0.032
	mesh.radial_segments = 4
	mesh.rings = 2
	var material := StandardMaterial3D.new()
	material.albedo_color = DUST
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_receive_shadows = true
	mesh.material = material
	return mesh
