extends Node3D

var active := false
var timer := 0.0
var cycle_offset := 0.0
var damage := 15
var radius := 1.8
var visual_root: Node3D
var spikes: Array[MeshInstance3D] = []
var warning_ring: MeshInstance3D


func setup(new_offset: float = 0.0, new_damage: int = 15) -> void:
	cycle_offset = new_offset
	damage = new_damage


func _ready() -> void:
	timer = cycle_offset
	_build_visual()


func _process(delta: float) -> void:
	timer += delta
	var local_cycle := fmod(timer, 3.0)
	if local_cycle >= 1.65 and local_cycle < 2.18:
		if not active:
			_activate()
	elif active:
		_deactivate()
	if is_instance_valid(warning_ring):
		var ring_material: StandardMaterial3D = (
			warning_ring.material_override as StandardMaterial3D
		)
		if is_instance_valid(ring_material):
			ring_material.emission_energy_multiplier = 2.4 + sin(timer * 6.0) * 0.8


func _activate() -> void:
	active = true
	for spike in spikes:
		spike.position.y = 0.72
		spike.scale = Vector3(1.0, 1.0, 1.0)
	for body in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(body) or not body.has_method("take_damage"):
			continue
		var offset: Vector3 = body.global_position - global_position
		offset.y = 0.0
		if offset.length() <= radius:
			body.take_damage(damage)


func _deactivate() -> void:
	active = false
	for spike in spikes:
		spike.position.y = 0.05
		spike.scale = Vector3(0.85, 0.15, 0.85)


func _build_visual() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	var dark := _material(Color(0.035, 0.018, 0.045), false)
	var glow := _material(Color(0.40, 0.025, 0.82), true)
	var green := _material(Color(0.25, 0.70, 0.04), true)

	var plate := MeshInstance3D.new()
	var plate_mesh := CylinderMesh.new()
	plate_mesh.top_radius = 1.65
	plate_mesh.bottom_radius = 1.65
	plate_mesh.height = 0.08
	plate.mesh = plate_mesh
	plate.position.y = 0.02
	plate.material_override = dark
	visual_root.add_child(plate)

	warning_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.35
	torus.outer_radius = 1.55
	torus.rings = 18
	torus.ring_segments = 7
	warning_ring.mesh = torus
	warning_ring.rotation_degrees.x = 90.0
	warning_ring.position.y = 0.09
	var ring_glow: StandardMaterial3D = glow.duplicate() as StandardMaterial3D
	warning_ring.material_override = ring_glow
	visual_root.add_child(warning_ring)

	for i in range(8):
		var spike := MeshInstance3D.new()
		var spike_mesh := PrismMesh.new()
		spike_mesh.size = Vector3(0.30, 1.35, 0.30)
		spike.mesh = spike_mesh
		var angle := TAU * float(i) / 8.0
		spike.position = Vector3(cos(angle) * 1.0, 0.05, sin(angle) * 1.0)
		spike.material_override = green if i % 3 == 0 else glow
		spike.scale = Vector3(0.85, 0.15, 0.85)
		visual_root.add_child(spike)
		spikes.append(spike)


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.8
		material.emission_energy_multiplier = 2.4
	return material
