extends Area3D

const PALETTE = preload("res://scripts/art/abyssfall_art_palette.gd")

var direction := Vector3.FORWARD
var move_speed := 22.0
var damage := 18
var source: Node
var lifetime := 1.8
var initialized := false
var splash_radius := 0.0
var splash_damage := 0
var impact_started := false
var visual_elapsed := 0.0

var visual_root: Node3D
var shell_root: Node3D
var wake_root: Node3D
var pale_core: MeshInstance3D
var splash_shell: MeshInstance3D
var bolt_light: OmniLight3D


func _ready() -> void:
	collision_layer = 8
	collision_mask = 4
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	_build_visual()
	_apply_variant_visual()


func setup(
	new_direction: Vector3,
	new_speed: float,
	new_damage: int,
	new_source: Node,
	new_splash_radius: float = 0.0,
	new_splash_damage: int = 0
) -> void:
	direction = new_direction.normalized()
	move_speed = new_speed
	damage = new_damage
	source = new_source
	splash_radius = new_splash_radius
	splash_damage = new_splash_damage
	initialized = true
	rotation.y = atan2(-direction.x, -direction.z)
	_apply_variant_visual()


func _physics_process(delta: float) -> void:
	visual_elapsed += delta
	if is_instance_valid(shell_root):
		shell_root.rotation.z += delta * 5.8
	if is_instance_valid(pale_core):
		var pulse := 0.92 + sin(visual_elapsed * 18.0) * 0.08
		pale_core.scale = Vector3.ONE * pulse
	if not initialized or impact_started:
		return
	global_position += direction * move_speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if impact_started or body == source:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		if splash_radius > 0.0 and splash_damage > 0:
			_splash_damage(body)
		_impact_burst()


func _splash_damage(primary_body: Node) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if (
			enemy == primary_body
			or not is_instance_valid(enemy)
			or not enemy.has_method("take_damage")
		):
			continue
		var offset: Vector3 = enemy.global_position - global_position
		offset.y = 0.0
		if offset.length() <= splash_radius:
			enemy.take_damage(splash_damage)


func _impact_burst() -> void:
	impact_started = true
	monitoring = false
	move_speed = 0.0
	if is_instance_valid(wake_root):
		wake_root.visible = false
	if is_instance_valid(bolt_light):
		bolt_light.light_color = PALETTE.GRAVITATIONAL_WHITE
		bolt_light.light_energy = 5.2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.44, 1.55, 0.44), 0.045).set_trans(
		Tween.TRANS_EXPO
	)
	if is_instance_valid(shell_root):
		tween.tween_property(shell_root, "rotation_degrees:z", 210.0, 0.09)
	tween.chain().tween_property(self, "scale", Vector3(2.15, 0.22, 2.15), 0.075).set_trans(
		Tween.TRANS_EXPO
	)
	tween.chain().tween_callback(queue_free)


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "VoidBoltVisual"
	add_child(visual_root)

	var white_material := PALETTE.emissive(PALETTE.GRAVITATIONAL_WHITE, 5.2, 0.08)
	var violet_material := PALETTE.emissive(PALETTE.VOID_FRACTURE, 3.8, 0.12)
	var dark_violet := PALETTE.translucent(PALETTE.VOID_VIOLET, 0.62, 2.2)
	var wake_material := PALETTE.translucent(PALETTE.VOID_FRACTURE, 0.46, 2.8)

	pale_core = MeshInstance3D.new()
	pale_core.name = "PaleGravitationalCore"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.135
	core_mesh.height = 0.27
	pale_core.mesh = core_mesh
	pale_core.material_override = white_material
	visual_root.add_child(pale_core)

	var compressed_shell := MeshInstance3D.new()
	compressed_shell.name = "CompressedVoidShell"
	var shell_mesh := SphereMesh.new()
	shell_mesh.radius = 0.255
	shell_mesh.height = 0.51
	compressed_shell.mesh = shell_mesh
	compressed_shell.scale = Vector3(1.0, 0.82, 1.0)
	compressed_shell.material_override = dark_violet
	visual_root.add_child(compressed_shell)

	shell_root = Node3D.new()
	shell_root.name = "FracturedShell"
	visual_root.add_child(shell_root)
	for ring_index in range(3):
		var ring := _create_ring(
			0.30 + float(ring_index) * 0.055,
			0.020 + float(ring_index) * 0.006,
			white_material if ring_index == 1 else violet_material
		)
		ring.name = "FractureRing_%02d" % ring_index
		ring.rotation_degrees = Vector3(
			90.0 + float(ring_index) * 27.0,
			float(ring_index) * 41.0,
			float(ring_index) * 19.0
		)
		shell_root.add_child(ring)

	for shard_index in range(8):
		var shard := MeshInstance3D.new()
		shard.name = "ShellShard_%02d" % shard_index
		var shard_mesh := PrismMesh.new()
		shard_mesh.size = Vector3(0.045, 0.18 + float(shard_index % 3) * 0.035, 0.035)
		shard.mesh = shard_mesh
		var angle := TAU * float(shard_index) / 8.0
		shard.position = Vector3(cos(angle) * 0.33, sin(angle * 2.0) * 0.09, sin(angle) * 0.33)
		shard.rotation_degrees = Vector3(35.0, -rad_to_deg(angle), 22.0 + float(shard_index) * 9.0)
		shard.material_override = white_material if shard_index % 4 == 0 else violet_material
		shell_root.add_child(shard)

	wake_root = Node3D.new()
	wake_root.name = "WarpedWake"
	visual_root.add_child(wake_root)
	for wake_index in range(7):
		var wake_piece := MeshInstance3D.new()
		wake_piece.name = "WakeSegment_%02d" % wake_index
		var wake_mesh := SphereMesh.new()
		wake_mesh.radius = maxf(0.028, 0.105 - float(wake_index) * 0.011)
		wake_mesh.height = wake_mesh.radius * 2.0
		wake_piece.mesh = wake_mesh
		var side := -1.0 if wake_index % 2 == 0 else 1.0
		wake_piece.position = Vector3(
			side * (0.025 + float(wake_index) * 0.012),
			sin(float(wake_index) * 1.4) * 0.035,
			0.24 + float(wake_index) * 0.16
		)
		wake_piece.scale = Vector3(0.72, 0.72, 1.7 + float(wake_index) * 0.18)
		wake_piece.material_override = wake_material
		wake_root.add_child(wake_piece)

	splash_shell = _create_ring(0.47, 0.028, violet_material)
	splash_shell.name = "ExplosiveBoltTell"
	splash_shell.rotation_degrees.x = 90.0
	splash_shell.visible = false
	visual_root.add_child(splash_shell)

	bolt_light = OmniLight3D.new()
	bolt_light.name = "VoidBoltLight"
	bolt_light.light_color = PALETTE.GRAVITATIONAL_WHITE
	bolt_light.light_energy = 2.7
	bolt_light.omni_range = 2.4
	visual_root.add_child(bolt_light)

	var collision := CollisionShape3D.new()
	collision.name = "VoidBoltCollision"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.28
	collision.shape = sphere
	add_child(collision)


func _apply_variant_visual() -> void:
	if not is_instance_valid(splash_shell):
		return
	var explosive := splash_radius > 0.0 and splash_damage > 0
	splash_shell.visible = explosive
	if explosive:
		splash_shell.scale = Vector3.ONE * clampf(splash_radius / 2.1, 0.82, 1.35)


func _create_ring(radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(radius - thickness, 0.01)
	torus.outer_radius = radius
	torus.rings = 24
	torus.ring_segments = 7
	ring.mesh = torus
	ring.material_override = material
	return ring
