extends Node3D
class_name SacramentVisual

var intensity := 1.0
var visual_root: Node3D
var blood_material: StandardMaterial3D
var venom_material: StandardMaterial3D
var bone_material: StandardMaterial3D


func configure(new_intensity: float = 1.0) -> void:
	intensity = clampf(new_intensity, 1.0, 3.2)


func _ready() -> void:
	_build_visual()
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(1.18, 1.18, 1.18), 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_property(visual_root, "scale", Vector3(0.03, 0.03, 0.03), 0.62)
	tween.tween_callback(queue_free)


func spawn_judgment(world_position: Vector3, complete_rite: bool, branded: bool) -> void:
	if not is_inside_tree():
		return
	var root := Node3D.new()
	root.position = to_local(world_position)
	root.position.y = 0.08
	add_child(root)

	var beam := MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.075
	beam_mesh.bottom_radius = 0.22 if complete_rite else 0.14
	beam_mesh.height = 2.8
	beam.mesh = beam_mesh
	beam.position.y = 1.35
	beam.material_override = venom_material if complete_rite else blood_material
	root.add_child(beam)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.48 if branded else 0.34
	torus.outer_radius = torus.inner_radius + 0.10
	torus.rings = 22
	torus.ring_segments = 7
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = blood_material if branded else (venom_material if complete_rite else bone_material)
	root.add_child(ring)

	var tween := create_tween()
	tween.tween_property(root, "scale", Vector3(1.65, 1.25, 1.65), 0.22)
	tween.tween_property(root, "scale", Vector3(0.04, 0.04, 0.04), 0.24)
	tween.tween_callback(root.queue_free)


func spawn_sigil_collapse(world_position: Vector3, radius: float) -> void:
	if not is_inside_tree():
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	var safe_radius := maxf(radius, 0.5)
	torus.inner_radius = safe_radius * 0.78
	torus.outer_radius = safe_radius * 0.84
	torus.rings = 28
	torus.ring_segments = 7
	ring.mesh = torus
	ring.position = to_local(world_position)
	ring.position.y = 0.10
	ring.rotation_degrees.x = 90.0
	ring.material_override = venom_material
	add_child(ring)
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector3(1.22, 1.22, 1.22), 0.18)
	tween.tween_property(ring, "scale", Vector3(0.03, 0.03, 0.03), 0.28)
	tween.tween_callback(ring.queue_free)


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "SacramentCathedral"
	add_child(visual_root)

	blood_material = _material(Color(0.92, 0.018, 0.035), true, 0.94)
	venom_material = _material(Color(0.28, 0.88, 0.055), true, 0.90)
	bone_material = _material(Color(0.72, 0.66, 0.52), false, 0.88)

	for ratio in [0.42, 0.68, 0.94]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 6.5 * float(ratio)
		torus.outer_radius = torus.inner_radius + 0.07
		torus.rings = 36
		torus.ring_segments = 7
		ring.mesh = torus
		ring.rotation_degrees.x = 90.0
		ring.position.y = 0.06 + float(ratio) * 0.03
		ring.material_override = blood_material if float(ratio) < 0.9 else bone_material
		visual_root.add_child(ring)

	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var pillar := MeshInstance3D.new()
		var pillar_mesh := BoxMesh.new()
		pillar_mesh.size = Vector3(0.10, 0.055, 2.2 + float(index % 3) * 0.35)
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(cos(angle) * 4.15, 0.10, sin(angle) * 4.15)
		pillar.rotation_degrees.y = -rad_to_deg(angle)
		pillar.material_override = venom_material if index % 4 == 0 else blood_material
		visual_root.add_child(pillar)

	var halo := MeshInstance3D.new()
	var halo_mesh := TorusMesh.new()
	halo_mesh.inner_radius = 1.05
	halo_mesh.outer_radius = 1.20
	halo.mesh = halo_mesh
	halo.position = Vector3(0.0, 2.2, 0.0)
	halo.material_override = venom_material
	visual_root.add_child(halo)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.0, 0.0)
	light.light_color = Color(0.90, 0.02, 0.04)
	light.light_energy = 4.0 * intensity
	light.omni_range = 9.0
	visual_root.add_child(light)


func _material(color: Color, glowing: bool, alpha: float = 1.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var resolved := color
	resolved.a = clampf(alpha, 0.0, 1.0)
	material.albedo_color = resolved
	material.roughness = 0.76
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.8
		material.emission_energy_multiplier = 3.0 * intensity
	return material
