extends Node3D
class_name SealOfBinding

signal expired(seal: Node, reason: String)

const BINDING_RULES = preload("res://scripts/characters/penitent/seal_binding_rules.gd")

var caster: Node3D
var radius := 3.4
var lifetime := 7.0
var pulse_interval := 0.16
var pulse_timer := 0.0
var active := true
var visual_root: Node3D
var binding_markers: Dictionary = {}


func configure(source: Node3D, new_radius: float = 3.4, new_lifetime: float = 7.0) -> void:
	caster = source
	radius = maxf(new_radius, 0.5)
	lifetime = maxf(new_lifetime, 0.1)


func _ready() -> void:
	process_priority = 20
	_build_visual()
	_apply_binding_pulse()


func _physics_process(delta: float) -> void:
	if not active:
		return
	lifetime = maxf(lifetime - delta, 0.0)
	pulse_timer -= delta
	if pulse_timer <= 0.0:
		pulse_timer = pulse_interval
		_apply_binding_pulse()
	if is_instance_valid(visual_root):
		visual_root.rotation.y += delta * 0.22
		var pulse: float = 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.025
		visual_root.scale = Vector3(pulse, 1.0, pulse)
	if lifetime <= 0.0:
		dismiss("expired")


func dismiss(reason: String = "dismissed") -> void:
	if not active:
		return
	active = false
	_clear_binding_markers()
	expired.emit(self, reason)
	queue_free()


func get_snapshot() -> Dictionary:
	return {
		"active": active,
		"radius": radius,
		"lifetime": lifetime,
		"bound_visuals": binding_markers.size(),
	}


func _apply_binding_pulse() -> void:
	if not is_inside_tree():
		return
	var chained_this_pulse: Dictionary = {}
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node3D
		if not is_instance_valid(enemy):
			continue
		if not BINDING_RULES.is_inside_radius(global_position, enemy.global_position, radius):
			continue
		if enemy.get("alive") != null and not bool(enemy.get("alive")):
			continue

		var has_complete_rite := _has_complete_rite(enemy)
		var target_kind := _resolve_target_kind(enemy)
		var profile: Dictionary = BINDING_RULES.get_control_profile(target_kind, has_complete_rite)
		if enemy.has_method("apply_ritual_control"):
			enemy.apply_ritual_control(
				float(profile.get("movement_multiplier", 1.0)),
				float(profile.get("control_duration", 0.0)),
				float(profile.get("bind_duration", 0.0))
			)
		if bool(profile.get("show_chains", false)):
			var instance_id: int = enemy.get_instance_id()
			chained_this_pulse[instance_id] = true
			_ensure_binding_marker(enemy, target_kind)

	for key in binding_markers.keys():
		var marker_id := int(key)
		if not chained_this_pulse.has(marker_id):
			_remove_binding_marker(marker_id)


func _has_complete_rite(enemy: Node3D) -> bool:
	var mark := enemy.get_node_or_null("RiteMark")
	if not is_instance_valid(mark) or not mark.has_method("get_snapshot"):
		return false
	var snapshot: Dictionary = mark.get_snapshot()
	return int(snapshot.get("state", 0)) >= 3


func _resolve_target_kind(enemy: Node3D) -> String:
	if enemy.is_in_group("bosses") or enemy.has_signal("phase_changed"):
		return BINDING_RULES.TARGET_BOSS
	var script := enemy.get_script() as Script
	var script_path := script.resource_path if is_instance_valid(script) else ""
	if script_path.ends_with("crypt_brute.gd") or enemy.name.to_lower().contains("brute"):
		return BINDING_RULES.TARGET_BRUTE
	return BINDING_RULES.TARGET_STANDARD


func _ensure_binding_marker(enemy: Node3D, target_kind: String) -> void:
	var instance_id: int = enemy.get_instance_id()
	var existing := binding_markers.get(instance_id) as Node3D
	if is_instance_valid(existing):
		return

	var marker := Node3D.new()
	marker.name = "SealBindingChains"
	marker.position = Vector3(0.0, -0.65 if target_kind != BINDING_RULES.TARGET_BOSS else -1.35, 0.0)
	enemy.add_child(marker)

	var chain_color := Color(0.78, 0.025, 0.035)
	if target_kind == BINDING_RULES.TARGET_BOSS:
		chain_color = Color(0.34, 0.86, 0.06)
	var chain_material := _material(chain_color, true, 0.95)
	var base_radius := 0.78 if target_kind == BINDING_RULES.TARGET_STANDARD else (1.12 if target_kind == BINDING_RULES.TARGET_BRUTE else 1.45)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = base_radius
	torus.outer_radius = base_radius + 0.09
	torus.rings = 24
	torus.ring_segments = 7
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = chain_material
	marker.add_child(ring)

	for index in range(4):
		var angle := TAU * float(index) / 4.0
		var chain := MeshInstance3D.new()
		var chain_mesh := BoxMesh.new()
		chain_mesh.size = Vector3(0.09, 1.15 if target_kind != BINDING_RULES.TARGET_BOSS else 1.65, 0.09)
		chain.mesh = chain_mesh
		chain.position = Vector3(cos(angle) * base_radius, chain_mesh.size.y * 0.46, sin(angle) * base_radius)
		chain.rotation_degrees.y = rad_to_deg(-angle)
		chain.material_override = chain_material
		marker.add_child(chain)

	binding_markers[instance_id] = marker


func _remove_binding_marker(instance_id: int) -> void:
	var marker := binding_markers.get(instance_id) as Node3D
	binding_markers.erase(instance_id)
	if is_instance_valid(marker):
		marker.queue_free()


func _clear_binding_markers() -> void:
	for key in binding_markers.keys():
		_remove_binding_marker(int(key))
	binding_markers.clear()


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "SealVisual"
	add_child(visual_root)

	var blood_material := _material(Color(0.62, 0.018, 0.028), true, 0.78)
	var iron_material := _material(Color(0.035, 0.026, 0.030), false, 0.92)
	var venom_material := _material(Color(0.27, 0.80, 0.045), true, 0.70)

	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = radius
	disc_mesh.bottom_radius = radius
	disc_mesh.height = 0.025
	disc.mesh = disc_mesh
	disc.position.y = 0.025
	disc.material_override = _material(Color(0.085, 0.008, 0.012), true, 0.30)
	visual_root.add_child(disc)

	for ring_ratio in [0.42, 0.70, 0.96]:
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = radius * float(ring_ratio)
		ring_mesh.outer_radius = ring_mesh.inner_radius + 0.055
		ring_mesh.rings = 32
		ring_mesh.ring_segments = 7
		ring.mesh = ring_mesh
		ring.rotation_degrees.x = 90.0
		ring.position.y = 0.055
		ring.material_override = blood_material if float(ring_ratio) < 0.9 else iron_material
		visual_root.add_child(ring)

	for index in range(12):
		var angle := TAU * float(index) / 12.0
		var stroke := MeshInstance3D.new()
		var stroke_mesh := BoxMesh.new()
		stroke_mesh.size = Vector3(0.07, 0.025, radius * 0.58)
		stroke.mesh = stroke_mesh
		stroke.position = Vector3(cos(angle) * radius * 0.55, 0.07, sin(angle) * radius * 0.55)
		stroke.rotation_degrees.y = -rad_to_deg(angle)
		stroke.material_override = venom_material if index % 3 == 0 else blood_material
		visual_root.add_child(stroke)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.35, 0.0)
	light.light_color = Color(0.70, 0.025, 0.035)
	light.light_energy = 1.45
	light.omni_range = radius * 1.35
	visual_root.add_child(light)


func _material(color: Color, glowing: bool, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var resolved := color
	resolved.a = clampf(alpha, 0.0, 1.0)
	material.albedo_color = resolved
	material.roughness = 0.78
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.6
		material.emission_energy_multiplier = 2.2
	return material
