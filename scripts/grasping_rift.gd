extends Node3D

const PALETTE = preload("res://scripts/art/abyssfall_art_palette.gd")

var source: Node
var pull_radius := 6.0
var pull_duration := 2.2
var collapse_delay := 0.35
var pull_strength := 7.4
var collapse_damage := 30
var elapsed := 0.0
var collapsed := false
var visual_root: Node3D
var lens_root: Node3D
var fracture_root: Node3D
var debris_root: Node3D
var core_lens: MeshInstance3D
var outer_ring: MeshInstance3D
var inner_ring: MeshInstance3D
var white_ring: MeshInstance3D
var void_material: StandardMaterial3D
var white_material: StandardMaterial3D
var corruption_material: StandardMaterial3D
var rift_light: OmniLight3D
var orbit_debris: Array[MeshInstance3D] = []


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
	var pull_progress := clampf(elapsed / maxf(pull_duration, 0.01), 0.0, 1.0)
	if is_instance_valid(fracture_root):
		fracture_root.rotation.y += delta * lerpf(0.65, 2.6, pull_progress)
	if is_instance_valid(debris_root):
		debris_root.rotation.y -= delta * lerpf(0.9, 4.8, pull_progress)
	if is_instance_valid(inner_ring):
		inner_ring.rotation.y -= delta * 2.1
	if is_instance_valid(white_ring):
		white_ring.rotation.y += delta * 1.35
	if is_instance_valid(core_lens):
		var pulse: float = 0.92 + sin(elapsed * 8.5) * 0.055
		core_lens.scale = Vector3(pulse, 0.14 + pull_progress * 0.05, pulse)
	_update_orbit_debris(pull_progress)

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
		void_material.emission_energy_multiplier = 5.2
	if is_instance_valid(white_material):
		white_material.emission_energy_multiplier = 7.0
	if is_instance_valid(corruption_material):
		corruption_material.emission_energy_multiplier = 3.6
	if is_instance_valid(rift_light):
		rift_light.light_color = PALETTE.GRAVITATIONAL_WHITE
		rift_light.light_energy = 6.2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(1.45, 0.18, 1.45), 0.105).set_trans(
		Tween.TRANS_EXPO
	)
	tween.tween_property(self, "rotation_degrees:y", rotation_degrees.y + 145.0, 0.105)
	tween.chain().tween_property(self, "scale", Vector3(0.03, 0.03, 0.03), 0.20).set_trans(
		Tween.TRANS_EXPO
	)


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "GraspingRiftVisual"
	add_child(visual_root)

	void_material = PALETTE.emissive(PALETTE.VOID_FRACTURE, 3.4, 0.11)
	white_material = PALETTE.emissive(PALETTE.GRAVITATIONAL_WHITE, 4.8, 0.06)
	corruption_material = PALETTE.emissive(PALETTE.CORRUPTION_GREEN, 2.0, 0.18)
	var dark_material := PALETTE.stone(PALETTE.ABYSS_BLACK, 0.08)
	var lens_material := PALETTE.translucent(Color(0.015, 0.008, 0.035), 0.93, 0.25)
	var streak_material := PALETTE.translucent(PALETTE.GRAVITATIONAL_WHITE, 0.68, 3.8)

	lens_root = Node3D.new()
	lens_root.name = "GravitationalLens"
	visual_root.add_child(lens_root)

	var under_disc := MeshInstance3D.new()
	under_disc.name = "AbyssOcclusionDisc"
	var under_mesh := CylinderMesh.new()
	under_mesh.top_radius = 2.42
	under_mesh.bottom_radius = 2.42
	under_mesh.height = 0.035
	under_disc.mesh = under_mesh
	under_disc.position.y = 0.012
	under_disc.material_override = dark_material
	lens_root.add_child(under_disc)

	core_lens = MeshInstance3D.new()
	core_lens.name = "CompressedLensCore"
	var lens_mesh := SphereMesh.new()
	lens_mesh.radius = 2.02
	lens_mesh.height = 4.04
	core_lens.mesh = lens_mesh
	core_lens.position.y = 0.055
	core_lens.scale = Vector3(1.0, 0.14, 1.0)
	core_lens.material_override = lens_material
	lens_root.add_child(core_lens)

	outer_ring = _create_ring(3.02, 0.095, void_material)
	outer_ring.name = "OuterVoidFracture"
	outer_ring.position.y = 0.09
	visual_root.add_child(outer_ring)

	white_ring = _create_ring(2.63, 0.045, white_material)
	white_ring.name = "GravitationalWhiteEdge"
	white_ring.position.y = 0.115
	visual_root.add_child(white_ring)

	inner_ring = _create_ring(2.12, 0.055, void_material)
	inner_ring.name = "InnerCompressionRing"
	inner_ring.position.y = 0.135
	visual_root.add_child(inner_ring)

	fracture_root = Node3D.new()
	fracture_root.name = "InwardFractureSpokes"
	visual_root.add_child(fracture_root)
	for spoke_index in range(10):
		var angle := TAU * float(spoke_index) / 10.0
		var spoke := MeshInstance3D.new()
		spoke.name = "InwardStreak_%02d" % spoke_index
		var spoke_mesh := BoxMesh.new()
		spoke_mesh.size = Vector3(0.035, 0.025, 0.72 + float(spoke_index % 3) * 0.18)
		spoke.mesh = spoke_mesh
		spoke.position = Vector3(cos(angle) * 1.62, 0.16, sin(angle) * 1.62)
		spoke.rotation.y = -angle
		spoke.rotation_degrees.z = -12.0 + float(spoke_index % 5) * 6.0
		spoke.material_override = streak_material if spoke_index % 3 != 0 else void_material
		fracture_root.add_child(spoke)

	debris_root = Node3D.new()
	debris_root.name = "OrbitingDebris"
	visual_root.add_child(debris_root)
	orbit_debris.clear()
	for shard_index in range(18):
		var shard := MeshInstance3D.new()
		shard.name = "OrbitShard_%02d" % shard_index
		var shard_mesh := PrismMesh.new()
		shard_mesh.size = Vector3(
			0.10 + float(shard_index % 4) * 0.025,
			0.32 + float(shard_index % 5) * 0.075,
			0.075 + float(shard_index % 3) * 0.022
		)
		shard.mesh = shard_mesh
		var angle := TAU * float(shard_index) / 18.0
		var radius := 2.65 + sin(float(shard_index) * 1.7) * 0.38
		shard.set_meta("orbit_angle", angle)
		shard.set_meta("orbit_radius", radius)
		shard.set_meta("orbit_speed", 0.72 + float(shard_index % 5) * 0.14)
		shard.position = Vector3(cos(angle) * radius, 0.18 + float(shard_index % 4) * 0.10, sin(angle) * radius)
		shard.rotation_degrees = Vector3(38.0, -rad_to_deg(angle), 18.0 + float(shard_index) * 11.0)
		shard.material_override = (
			white_material
			if shard_index % 6 == 0
			else (corruption_material if shard_index % 7 == 0 else void_material)
		)
		debris_root.add_child(shard)
		orbit_debris.append(shard)

	rift_light = OmniLight3D.new()
	rift_light.name = "RiftCompressionLight"
	rift_light.position = Vector3(0.0, 0.75, 0.0)
	rift_light.light_color = PALETTE.VOID_FRACTURE
	rift_light.light_energy = 2.8
	rift_light.omni_range = 6.4
	visual_root.add_child(rift_light)


func _update_orbit_debris(pull_progress: float) -> void:
	for shard_index in range(orbit_debris.size()):
		var shard := orbit_debris[shard_index]
		if not is_instance_valid(shard):
			continue
		var base_angle := float(shard.get_meta("orbit_angle", 0.0))
		var base_radius := float(shard.get_meta("orbit_radius", 2.6))
		var speed := float(shard.get_meta("orbit_speed", 1.0))
		var angle := base_angle + elapsed * speed * lerpf(1.0, 3.4, pull_progress)
		var radius := lerpf(base_radius, maxf(0.72, base_radius * 0.34), pull_progress)
		shard.position = Vector3(
			cos(angle) * radius,
			0.18 + float(shard_index % 4) * 0.10 + sin(elapsed * 5.0 + float(shard_index)) * 0.05,
			sin(angle) * radius
		)
		shard.rotation_degrees.y += speed * 7.0
		shard.rotation_degrees.z += speed * 4.5


func _create_ring(radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(radius - thickness, 0.05)
	torus.outer_radius = radius
	torus.rings = 32
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = material
	return ring
