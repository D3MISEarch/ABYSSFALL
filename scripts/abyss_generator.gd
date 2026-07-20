extends StaticBody3D

signal spawn_requested(generator: Node)
signal destroyed(generator: Node)

var max_health := 190
var health := 190
var spawn_interval := 3.1
var spawn_timer := 1.0
var alive := true
var core: MeshInstance3D
var visual_root: Node3D
var void_material: StandardMaterial3D
var corruption_material: StandardMaterial3D
var pulse_time := 0.0


func _ready() -> void:
	add_to_group("generators")
	collision_layer = 4
	collision_mask = 0
	_build_visual()


func _process(delta: float) -> void:
	if not alive:
		return
	pulse_time += delta
	spawn_timer -= delta

	if is_instance_valid(core):
		var health_pressure := 1.0 + (1.0 - float(health) / float(max_health)) * 0.45
		var pulse := 1.0 + sin(pulse_time * 4.8) * 0.08 * health_pressure
		core.scale = Vector3(pulse, pulse, pulse)

	if spawn_timer <= 0.0:
		spawn_requested.emit(self)
		var health_ratio := float(health) / float(max_health)
		spawn_timer = lerpf(1.75, spawn_interval, health_ratio)
		_spawn_pulse()


func take_damage(amount: int) -> void:
	if not alive:
		return
	health = maxi(health - amount, 0)
	_hit_pulse()
	if health <= 0:
		_die()


func _die() -> void:
	alive = false
	collision_layer = 0
	destroyed.emit(self)
	if is_instance_valid(void_material):
		void_material.emission_energy_multiplier = 5.4
	if is_instance_valid(corruption_material):
		corruption_material.emission_energy_multiplier = 4.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_root, "scale", Vector3(1.35, 1.65, 1.35), 0.14)
	tween.tween_property(
		visual_root, "rotation_degrees:y", visual_root.rotation_degrees.y + 80.0, 0.14
	)
	tween.chain().tween_property(visual_root, "scale", Vector3(0.03, 0.03, 0.03), 0.36).set_trans(
		Tween.TRANS_BACK
	)
	tween.chain().tween_callback(queue_free)


func _spawn_pulse() -> void:
	if not is_instance_valid(visual_root):
		return
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(1.12, 0.90, 1.12), 0.09)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.17).set_trans(Tween.TRANS_BACK)


func _hit_pulse() -> void:
	if not is_instance_valid(core):
		return
	var tween := create_tween()
	tween.tween_property(core, "scale", Vector3(1.35, 1.35, 1.35), 0.055)
	tween.tween_property(core, "scale", Vector3.ONE, 0.12)


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "AbyssGeneratorVisual"
	add_child(visual_root)

	var obsidian_material := _material(Color(0.025, 0.018, 0.038), false)
	var ritual_metal := _material(Color(0.11, 0.085, 0.13), false)
	void_material = _material(Color(0.43, 0.035, 0.92), true)
	corruption_material = _material(Color(0.25, 0.69, 0.05), true)

	for i in range(5):
		var spire := MeshInstance3D.new()
		var spire_mesh := PrismMesh.new()
		spire_mesh.size = Vector3(0.75 - float(i) * 0.07, 2.6 + float(i % 2) * 0.7, 0.70)
		spire.mesh = spire_mesh
		var angle := TAU * float(i) / 5.0
		spire.position = Vector3(cos(angle) * 0.72, 1.0 + float(i % 2) * 0.22, sin(angle) * 0.72)
		spire.rotation_degrees = Vector3(0.0, -rad_to_deg(angle), 8.0 if i % 2 == 0 else -10.0)
		spire.material_override = obsidian_material
		visual_root.add_child(spire)

	core = MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.58
	core_mesh.height = 1.05
	core.mesh = core_mesh
	core.position = Vector3(0.0, 1.15, -0.62)
	core.material_override = void_material
	visual_root.add_child(core)

	var core_ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.62
	torus.outer_radius = 0.82
	torus.rings = 20
	torus.ring_segments = 8
	core_ring.mesh = torus
	core_ring.rotation_degrees.x = 90.0
	core_ring.position = core.position
	core_ring.material_override = corruption_material
	visual_root.add_child(core_ring)

	for i in range(4):
		var root := MeshInstance3D.new()
		var root_mesh := BoxMesh.new()
		root_mesh.size = Vector3(0.30, 0.22, 2.6)
		root.mesh = root_mesh
		var angle := TAU * float(i) / 4.0
		root.position = Vector3(cos(angle) * 1.05, 0.10, sin(angle) * 1.05)
		root.rotation_degrees.y = -rad_to_deg(angle)
		root.material_override = ritual_metal if i % 2 == 0 else corruption_material
		visual_root.add_child(root)

	for i in range(4):
		var shard := MeshInstance3D.new()
		var shard_mesh := PrismMesh.new()
		shard_mesh.size = Vector3(0.20, 0.55, 0.16)
		shard.mesh = shard_mesh
		var angle := TAU * float(i) / 4.0 + 0.45
		shard.position = Vector3(cos(angle) * 1.45, 1.65 + float(i % 2) * 0.40, sin(angle) * 1.45)
		shard.rotation_degrees = Vector3(20.0, -rad_to_deg(angle), 30.0)
		shard.material_override = void_material
		visual_root.add_child(shard)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.35, 0.0)
	light.light_color = Color(0.48, 0.045, 1.0)
	light.light_energy = 2.7
	light.omni_range = 6.2
	visual_root.add_child(light)

	var collision := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.0
	cylinder.height = 2.8
	collision.shape = cylinder
	collision.position = Vector3(0.0, 1.0, 0.0)
	add_child(collision)


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.84
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.8
		material.emission_energy_multiplier = 2.8
	return material
