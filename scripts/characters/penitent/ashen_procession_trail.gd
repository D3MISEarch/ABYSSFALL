extends Node3D
class_name AshenProcessionTrail

signal completed(trail: Node)
signal dismissed(trail: Node, reason: String)

const RULES = preload("res://scripts/characters/penitent/ashen_procession_rules.gd")

var caster: Node3D
var start_position := Vector3.ZERO
var finish_position := Vector3.ZERO
var lifetime := RULES.TRAIL_LIFETIME
var active := true
var armed := false
var previous_caster_position := Vector3.ZERO
var visual_root: Node3D
var blood_material: StandardMaterial3D
var venom_material: StandardMaterial3D


func configure(
	source: Node3D,
	start_value: Vector3,
	finish_value: Vector3,
	new_lifetime: float = RULES.TRAIL_LIFETIME
) -> void:
	caster = source
	start_position = start_value
	finish_position = finish_value
	lifetime = maxf(new_lifetime, 0.2)


func _ready() -> void:
	previous_caster_position = caster.global_position if is_instance_valid(caster) else finish_position
	_build_visual()
	set_process(true)


func _process(delta: float) -> void:
	if not active:
		return
	if not is_instance_valid(caster):
		dismiss("caster_missing")
		return

	lifetime = maxf(lifetime - delta, 0.0)
	var current_position := caster.global_position
	if not armed:
		if RULES.should_arm(current_position, start_position, finish_position):
			armed = true
			_set_armed_visuals()
	elif RULES.did_cross(
		previous_caster_position,
		current_position,
		start_position,
		finish_position
	):
		_complete_rite_line()
		return

	previous_caster_position = current_position
	if is_instance_valid(visual_root):
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.007) * (0.025 if armed else 0.012)
		visual_root.scale = Vector3(1.0, pulse, 1.0)
	if lifetime <= 0.0:
		dismiss("expired")


func dismiss(reason: String = "dismissed") -> void:
	if not active:
		return
	active = false
	dismissed.emit(self, reason)
	queue_free()


func get_snapshot() -> Dictionary:
	return {
		"active": active,
		"armed": armed,
		"lifetime": lifetime,
		"start": start_position,
		"finish": finish_position,
	}


func spawn_impact(world_position: Vector3, complete_rite: bool) -> void:
	if not is_inside_tree():
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.52
	torus.rings = 20
	torus.ring_segments = 7
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.position = to_local(world_position)
	ring.position.y = 0.14
	ring.material_override = venom_material if complete_rite else blood_material
	add_child(ring)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector3(2.1, 2.1, 2.1), 0.24).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(ring, "scale", Vector3(0.08, 0.08, 0.08), 0.12)
	tween.tween_callback(ring.queue_free)


func _complete_rite_line() -> void:
	if not active:
		return
	active = false
	if is_instance_valid(blood_material):
		blood_material.albedo_color = Color(0.95, 0.025, 0.045)
		blood_material.emission_energy_multiplier = 4.2
	if is_instance_valid(venom_material):
		venom_material.emission_energy_multiplier = 4.8
	completed.emit(self)
	if not is_instance_valid(visual_root):
		queue_free()
		return
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(1.12, 1.55, 1.12), 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(visual_root, "scale", Vector3(0.04, 0.04, 0.04), 0.30)
	tween.tween_callback(queue_free)


func _set_armed_visuals() -> void:
	if is_instance_valid(blood_material):
		blood_material.albedo_color = Color(0.78, 0.018, 0.032)
		blood_material.emission_energy_multiplier = 3.2
	if is_instance_valid(venom_material):
		venom_material.emission_energy_multiplier = 3.4


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "AshenProcessionVisual"
	add_child(visual_root)

	blood_material = _material(Color(0.42, 0.010, 0.018), true, 0.92)
	venom_material = _material(Color(0.26, 0.78, 0.045), true, 0.86)
	var ash_material := _material(Color(0.035, 0.028, 0.032), false, 0.82)

	var offset := finish_position - start_position
	offset.y = 0.0
	var length := maxf(offset.length(), 0.2)
	var direction := offset.normalized() if length > 0.01 else Vector3.FORWARD
	visual_root.rotation.y = atan2(direction.x, direction.z)

	var scripture := MeshInstance3D.new()
	var scripture_mesh := BoxMesh.new()
	scripture_mesh.size = Vector3(0.12, 0.025, length)
	scripture.mesh = scripture_mesh
	scripture.position.y = 0.05
	scripture.material_override = blood_material
	visual_root.add_child(scripture)

	var ash_underlay := MeshInstance3D.new()
	var ash_mesh := BoxMesh.new()
	ash_mesh.size = Vector3(0.38, 0.018, length + 0.28)
	ash_underlay.mesh = ash_mesh
	ash_underlay.position.y = 0.025
	ash_underlay.material_override = ash_material
	visual_root.add_child(ash_underlay)

	var glyph_count := maxi(int(round(length * 4.2)), 8)
	for index in range(glyph_count):
		var ratio := (float(index) + 0.5) / float(glyph_count)
		var stroke := MeshInstance3D.new()
		var stroke_mesh := BoxMesh.new()
		stroke_mesh.size = Vector3(0.34 if index % 3 == 0 else 0.22, 0.032, 0.055)
		stroke.mesh = stroke_mesh
		stroke.position = Vector3(
			-0.14 if index % 2 == 0 else 0.14,
			0.075,
			lerpf(-length * 0.5, length * 0.5, ratio)
		)
		stroke.rotation_degrees.y = -28.0 if index % 2 == 0 else 28.0
		stroke.material_override = venom_material if index % 5 == 0 else blood_material
		visual_root.add_child(stroke)

	for endpoint_z in [-length * 0.5, length * 0.5]:
		var endpoint := MeshInstance3D.new()
		var endpoint_mesh := TorusMesh.new()
		endpoint_mesh.inner_radius = 0.29
		endpoint_mesh.outer_radius = 0.37
		endpoint_mesh.rings = 22
		endpoint_mesh.ring_segments = 7
		endpoint.mesh = endpoint_mesh
		endpoint.position = Vector3(0.0, 0.07, endpoint_z)
		endpoint.rotation_degrees.x = 90.0
		endpoint.material_override = blood_material
		visual_root.add_child(endpoint)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.30, 0.0)
	light.light_color = Color(0.72, 0.02, 0.04)
	light.light_energy = 1.15
	light.omni_range = maxf(length * 0.72, 2.4)
	visual_root.add_child(light)


func _material(color: Color, glowing: bool, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var resolved := color
	resolved.a = clampf(alpha, 0.0, 1.0)
	material.albedo_color = resolved
	material.roughness = 0.82
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.6
		material.emission_energy_multiplier = 1.8
	return material
