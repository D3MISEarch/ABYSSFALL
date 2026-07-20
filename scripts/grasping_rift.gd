extends Node3D

var source: Node
var pull_radius := 6.0
var pull_duration := 2.2
var collapse_delay := 0.35
var pull_strength := 7.4
var collapse_damage := 30
var elapsed := 0.0
var collapsed := false
var visual_root: Node3D
var core: MeshInstance3D
var outer_ring: MeshInstance3D
var inner_ring: MeshInstance3D
var void_material: StandardMaterial3D
var corruption_material: StandardMaterial3D


func setup(
	new_source: Node,
	new_radius: float = 6.0,
	new_duration: float = 2.2,
	new_pull_strength: float = 7.4,
	new_damage: int = 30,
	visual_scale: float = 1.0
) -> void:
	source = new_source
	pull_radius = new_radius
	pull_duration = new_duration
	pull_strength = new_pull_strength
	collapse_damage = new_damage
	scale = Vector3.ONE * visual_scale


func _ready() -> void:
	_build_visual()
	var target_scale: Vector3 = scale
	scale = target_scale * 0.08
	var tween := create_tween()
	tween.tween_property(self, "scale", target_scale, 0.22).set_trans(Tween.TRANS_BACK)


func _physics_process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(outer_ring):
		outer_ring.rotation.y += delta * 1.8
	if is_instance_valid(inner_ring):
		inner_ring.rotation.y -= delta * 2.7
	if is_instance_valid(core):
		var pulse: float = 0.84 + sin(elapsed * 9.0) * 0.12
		core.scale = Vector3(pulse, 0.25, pulse)

	if elapsed <= pull_duration:
		_pull_targets(delta)
	elif not collapsed:
		_collapse()
	elif elapsed >= pull_duration + collapse_delay:
		queue_free()


func _pull_targets(_delta: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("apply_rift_pull"):
			continue
		var offset: Vector3 = global_position - enemy.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		if distance <= pull_radius:
			var strength_scale: float = lerpf(1.25, 0.72, clampf(distance / pull_radius, 0.0, 1.0))
			enemy.apply_rift_pull(global_position, pull_strength * strength_scale)


func _collapse() -> void:
	collapsed = true
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var offset: Vector3 = enemy.global_position - global_position
		offset.y = 0.0
		if offset.length() <= pull_radius:
			enemy.take_damage(collapse_damage)

	for generator in get_tree().get_nodes_in_group("generators"):
		if not is_instance_valid(generator) or not generator.has_method("take_damage"):
			continue
		var offset: Vector3 = generator.global_position - global_position
		offset.y = 0.0
		if offset.length() <= pull_radius:
			generator.take_damage(18)

	if is_instance_valid(void_material):
		void_material.emission_energy_multiplier = 5.0
	if is_instance_valid(corruption_material):
		corruption_material.emission_energy_multiplier = 4.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.85, 0.30, 1.85), 0.16).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "rotation_degrees:y", rotation_degrees.y + 120.0, 0.16)
	tween.chain().tween_property(self, "scale", Vector3(0.03, 0.03, 0.03), 0.18)


func _build_visual() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)

	void_material = _material(Color(0.42, 0.025, 0.90), true)
	corruption_material = _material(Color(0.28, 0.72, 0.055), true)
	var dark_material := _material(Color(0.005, 0.003, 0.010), false)

	core = MeshInstance3D.new()
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 2.25
	core_mesh.bottom_radius = 2.25
	core_mesh.height = 0.10
	core.mesh = core_mesh
	core.position.y = 0.02
	core.material_override = dark_material
	visual_root.add_child(core)

	outer_ring = _create_ring(3.0, 0.20, void_material)
	outer_ring.position.y = 0.08
	visual_root.add_child(outer_ring)

	inner_ring = _create_ring(2.18, 0.12, corruption_material)
	inner_ring.position.y = 0.11
	visual_root.add_child(inner_ring)

	for i in range(12):
		var shard := MeshInstance3D.new()
		var shard_mesh := PrismMesh.new()
		shard_mesh.size = Vector3(0.18, 0.55, 0.13)
		shard.mesh = shard_mesh
		var angle := TAU * float(i) / 12.0
		var radius := 2.70 + sin(float(i) * 1.7) * 0.30
		shard.position = Vector3(
			cos(angle) * radius, 0.18 + float(i % 3) * 0.12, sin(angle) * radius
		)
		shard.rotation_degrees = Vector3(35.0, -rad_to_deg(angle), 25.0)
		shard.material_override = void_material if i % 3 != 0 else corruption_material
		visual_root.add_child(shard)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.7, 0.0)
	light.light_color = Color(0.48, 0.05, 1.0)
	light.light_energy = 3.1
	light.omni_range = 7.0
	visual_root.add_child(light)


func _create_ring(radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(radius - thickness, 0.05)
	torus.outer_radius = radius
	torus.rings = 24
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = material
	return ring


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.26 if glowing else 0.95
	if glowing:
		material.emission_enabled = true
		material.emission = color * 3.0
		material.emission_energy_multiplier = 2.8
	return material
