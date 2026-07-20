extends Node3D

var target: Node3D
var item: Dictionary = {}
var age := 0.0
var magnet_delay := 0.75
var move_speed := 3.0
var visual_root: Node3D


func setup(new_target: Node3D, new_item: Dictionary) -> void:
	target = new_target
	item = new_item.duplicate(true)


func _ready() -> void:
	_build_visual()


func _process(delta: float) -> void:
	age += delta
	if is_instance_valid(visual_root):
		visual_root.rotation.y += delta * 1.8
		var pulse := 1.0 + sin(age * 5.5) * 0.08
		visual_root.scale = Vector3(pulse, pulse, pulse)

	if not is_instance_valid(target):
		return
	if age < magnet_delay:
		global_position.y = 0.75 + sin(age * 4.0) * 0.12
		return

	var target_position := target.global_position + Vector3(0.0, 0.65, 0.0)
	var distance := global_position.distance_to(target_position)
	move_speed = minf(move_speed + delta * 8.0, 14.0)
	global_position = global_position.move_toward(target_position, move_speed * delta)
	if distance <= 0.72:
		if target.has_method("add_item"):
			target.add_item(item)
		queue_free()


func _build_visual() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)

	var rarity: String = str(item.get("rarity", "Common"))
	var color := _rarity_color(rarity)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 2.8
	material.emission_energy_multiplier = 2.5
	material.roughness = 0.22

	var core := MeshInstance3D.new()
	var core_mesh := PrismMesh.new()
	core_mesh.size = Vector3(0.38, 0.78, 0.26)
	core.mesh = core_mesh
	core.material_override = material
	visual_root.add_child(core)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.40
	ring_mesh.outer_radius = 0.50
	ring_mesh.rings = 18
	ring_mesh.ring_segments = 7
	ring.mesh = ring_mesh
	ring.rotation_degrees.x = 90.0
	ring.material_override = material
	visual_root.add_child(ring)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 2.0
	light.omni_range = 3.0
	visual_root.add_child(light)


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Magic":
			return Color(0.16, 0.42, 1.0)
		"Rare":
			return Color(0.91, 0.82, 0.14)
		"Epic":
			return Color(0.63, 0.12, 1.0)
		"Legendary":
			return Color(1.0, 0.43, 0.06)
		"Mythic":
			return Color(1.0, 0.05, 0.18)
		_:
			return Color(0.78, 0.80, 0.84)
