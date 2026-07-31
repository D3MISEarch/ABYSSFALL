extends Node
class_name VisualFoundationVFX

const ROOT_NAME := "VisualFoundationV01_VFX"
const MAX_ACTIVE_EFFECTS := 18
const MAX_DEBRIS_PER_BURST := 12
const DEFAULT_LIFETIME := 1.35
const INSTALL_INTERVAL_SECONDS := 0.45
const ROUTE_SETTLE_DELAY_SECONDS := 0.35
const PALE_VOID := Color(0.72, 0.70, 0.90, 0.72)
const RESTRAINED_VIOLET := Color(0.43, 0.18, 0.68, 0.62)
const DUST := Color(0.22, 0.19, 0.25, 0.62)
const DEBRIS_STONE := Color(0.075, 0.065, 0.085, 1.0)

var _install_timer: Timer
var _route_settle_timer: Timer
var _route_host: Node3D
var _pending_settle_scene_id := 0
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
	_install_timer.timeout.connect(_try_bind_route)
	add_child(_install_timer)

	_route_settle_timer = Timer.new()
	_route_settle_timer.name = "VisualFoundationRouteSettleTimer"
	_route_settle_timer.wait_time = ROUTE_SETTLE_DELAY_SECONDS
	_route_settle_timer.one_shot = true
	_route_settle_timer.timeout.connect(_on_route_settle_timeout)
	add_child(_route_settle_timer)
	call_deferred("_try_bind_route")


func _exit_tree() -> void:
	_clear_effects()


func _try_bind_route() -> void:
	if is_instance_valid(_route_host) and _route_host.is_inside_tree() and is_instance_valid(_effect_root):
		return
	_clear_route_binding(false)
	var route_host := get_tree().get_first_node_in_group("visual_foundation_route_host") as Node3D
	if route_host == null:
		_start_discovery()
		return
	var scene_id := route_host.get_instance_id()
	if _installed_scene_id == scene_id and is_instance_valid(_effect_root):
		_route_host = route_host
		_watch_route_host(route_host)
		_stop_discovery()
		return
	_clear_effects()
	var existing := route_host.get_node_or_null(ROOT_NAME) as Node3D
	if existing != null:
		_effect_root = existing
	else:
		_effect_root = Node3D.new()
		_effect_root.name = ROOT_NAME
		_effect_root.set_meta("presentation_only", true)
		_effect_root.set_meta("bounded_effect_budget", MAX_ACTIVE_EFFECTS)
		_effect_root.set_meta("bounded_debris_per_burst", MAX_DEBRIS_PER_BURST)
		route_host.add_child(_effect_root)
	_route_host = route_host
	_installed_scene_id = scene_id
	_watch_route_host(route_host)
	_stop_discovery()
	_schedule_route_settle(scene_id)


func _schedule_route_settle(expected_scene_id: int) -> void:
	_pending_settle_scene_id = expected_scene_id
	if not is_instance_valid(_route_settle_timer):
		return
	_route_settle_timer.stop()
	_route_settle_timer.start(ROUTE_SETTLE_DELAY_SECONDS)


func _on_route_settle_timeout() -> void:
	var expected_scene_id := _pending_settle_scene_id
	_pending_settle_scene_id = 0
	if not is_instance_valid(_route_host) or _route_host.get_instance_id() != expected_scene_id:
		return
	if _installed_scene_id != expected_scene_id or not is_instance_valid(_effect_root):
		return
	spawn_dust_burst(Vector3(0.0, 0.18, -20.0), 0.62, 14)
	spawn_dust_burst(Vector3(0.0, 0.18, -73.0), 0.54, 12)
	spawn_void_pulse(Vector3(0.0, 0.12, -103.0), 0.78)
	spawn_debris_reaction(Vector3(0.0, 0.08, -103.0), 0.70, 8)


func _on_route_host_tree_exited() -> void:
	_clear_route_binding()


func _watch_route_host(route_host: Node3D) -> void:
	if not route_host.tree_exited.is_connected(_on_route_host_tree_exited):
		route_host.tree_exited.connect(_on_route_host_tree_exited, CONNECT_ONE_SHOT)


func _clear_route_binding(restart_discovery: bool = true) -> void:
	_clear_effects()
	_route_host = null
	if restart_discovery:
		_start_discovery()


func _start_discovery() -> void:
	if is_instance_valid(_install_timer) and _install_timer.is_stopped():
		_install_timer.start()


func _stop_discovery() -> void:
	if is_instance_valid(_install_timer):
		_install_timer.stop()


func spawn_gravity_burst(world_position: Vector3, strength: float = 1.0) -> void:
	if not _can_spawn():
		return
	var clamped_strength := clampf(strength, 0.25, 1.6)
	spawn_dust_burst(world_position, clamped_strength, clampi(int(16.0 * clamped_strength), 8, 24))
	spawn_void_pulse(world_position, clamped_strength)
	spawn_debris_reaction(
		world_position,
		clamped_strength,
		clampi(int(8.0 * clamped_strength), 5, MAX_DEBRIS_PER_BURST)
	)


func spawn_dust_burst(world_position: Vector3, strength: float = 1.0, amount: int = 16) -> void:
	if not _can_spawn():
		return
	var particles := CPUParticles3D.new()
	particles.name = "BoundedDustBurst"
	particles.position = world_position
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
	particles.mesh = _make_dust_mesh()
	particles.set_meta("presentation_only", true)
	_register_effect(particles, particles.lifetime + 0.25)
	particles.restart()


func spawn_void_pulse(world_position: Vector3, strength: float = 1.0) -> void:
	if not _can_spawn():
		return
	var pulse := MeshInstance3D.new()
	pulse.name = "BoundedVoidPulse"
	pulse.position = world_position
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


func spawn_debris_reaction(world_position: Vector3, strength: float = 1.0, amount: int = 8) -> void:
	if not _can_spawn():
		return
	var clamped_strength := clampf(strength, 0.35, 1.5)
	var fragment_count := clampi(amount, 4, MAX_DEBRIS_PER_BURST)
	var debris_root := Node3D.new()
	debris_root.name = "BoundedReactiveDebris"
	debris_root.position = world_position
	debris_root.set_meta("presentation_only", true)
	debris_root.set_meta("fragment_count", fragment_count)
	debris_root.set_meta("collision_disabled", true)
	_register_effect(debris_root, 1.22)

	var shared_mesh := _make_debris_mesh()
	var start_radius := 1.15 * clamped_strength
	for index in fragment_count:
		var angle := TAU * float(index) / float(fragment_count) + 0.21 * float(index % 3)
		var radial := Vector3(cos(angle), 0.0, sin(angle))
		var tangent := Vector3(-radial.z, 0.0, radial.x)
		var fragment := MeshInstance3D.new()
		fragment.name = "DecorativeFragment_%02d" % index
		fragment.mesh = shared_mesh
		fragment.position = radial * (start_radius * (0.72 + 0.08 * float(index % 4)))
		fragment.position.y = 0.035 + 0.012 * float(index % 3)
		fragment.rotation = Vector3(0.18 * float(index % 2), angle, 0.13 * float(index % 4))
		fragment.scale = Vector3.ONE * (0.72 + 0.09 * float(index % 4))
		fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fragment.set_meta("presentation_only", true)
		fragment.set_meta("non_colliding", true)
		debris_root.add_child(fragment)

		var inward_target := radial * (0.16 + 0.035 * float(index % 3))
		inward_target.y = 0.12 + 0.025 * float(index % 2)
		var settle_target := inward_target + tangent * (0.22 + 0.04 * float(index % 3))
		settle_target.y = 0.025
		var fragment_tween := fragment.create_tween()
		fragment_tween.tween_property(fragment, "position", inward_target, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fragment_tween.parallel().tween_property(fragment, "rotation", fragment.rotation + Vector3(1.1, 1.8, 0.8), 0.30)
		fragment_tween.tween_property(fragment, "position", settle_target, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		fragment_tween.parallel().tween_property(fragment, "rotation", fragment.rotation + Vector3(2.0, 2.8, 1.5), 0.48)
		fragment_tween.tween_interval(0.18)
		fragment_tween.tween_property(fragment, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


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
	var lifetime_timer := Timer.new()
	lifetime_timer.name = "VisualFoundationEffectLifetime"
	lifetime_timer.wait_time = maxf(lifetime, 0.05)
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(_expire_effect.bind(effect), CONNECT_ONE_SHOT)
	effect.add_child(lifetime_timer)
	lifetime_timer.start()


func _expire_effect(effect: Node) -> void:
	_active_effects.erase(effect)
	if is_instance_valid(effect):
		effect.queue_free()


func _clear_effects(reset_root: bool = true) -> void:
	if is_instance_valid(_route_settle_timer):
		_route_settle_timer.stop()
	_pending_settle_scene_id = 0
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


func _make_debris_mesh() -> Mesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.095, 0.045, 0.065)
	var material := StandardMaterial3D.new()
	material.albedo_color = DEBRIS_STONE
	material.roughness = 0.92
	material.metallic = 0.02
	material.disable_receive_shadows = true
	mesh.material = material
	return mesh
