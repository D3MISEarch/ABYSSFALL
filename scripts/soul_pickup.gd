extends Node3D

var target: Node3D
var corruption_amount := 13.0
var rare := false
var age := 0.0
var magnet_delay := 0.32
var move_speed := 5.0
var visual_root: Node3D


func setup(new_target: Node3D, amount: float, is_rare: bool) -> void:
	target = new_target
	corruption_amount = amount
	rare = is_rare


func _ready() -> void:
	_build_visual()


func _process(delta: float) -> void:
	age += delta
	if is_instance_valid(visual_root):
		visual_root.rotation.y += delta * (3.4 if rare else 2.4)
		var pulse := 1.0 + sin(age * 7.0) * 0.12
		visual_root.scale = Vector3(pulse, pulse, pulse)

	if not is_instance_valid(target):
		return

	var hover_height := 0.75 + sin(age * 4.5) * 0.12
	if age < magnet_delay:
		global_position.y = move_toward(global_position.y, hover_height, delta * 2.2)
		return

	var target_position := target.global_position + Vector3(0.0, 0.55, 0.0)
	var distance := global_position.distance_to(target_position)
	move_speed = minf(move_speed + delta * 10.0, 18.0)
	global_position = global_position.move_toward(target_position, move_speed * delta)
	if distance <= 0.65:
		if target.has_method("collect_soul"):
			target.collect_soul(corruption_amount, rare)
		elif target.has_method("add_corruption"):
			target.add_corruption(corruption_amount)
		queue_free()


func _build_visual() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)

	var color := Color(0.34, 0.83, 0.06) if rare else Color(0.48, 0.045, 1.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 3.1
	material.emission_energy_multiplier = 3.0
	material.roughness = 0.12

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.18 if rare else 0.14
	core_mesh.height = 0.36 if rare else 0.28
	core.mesh = core_mesh
	core.material_override = material
	visual_root.add_child(core)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.22
	ring_mesh.outer_radius = 0.28 if rare else 0.25
	ring_mesh.rings = 16
	ring_mesh.ring_segments = 6
	ring.mesh = ring_mesh
	ring.material_override = material
	visual_root.add_child(ring)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.9 if rare else 1.25
	light.omni_range = 2.8 if rare else 2.0
	visual_root.add_child(light)
