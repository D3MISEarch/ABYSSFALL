extends CharacterBody3D

signal died(enemy: Node)

var target: Node3D
var max_health := 150
var health := 150
var move_speed := 1.75
var attack_damage := 19
var attack_range := 1.85
var attack_interval := 1.35
var attack_timer := 0.4
var slam_interval := 4.6
var slam_timer := 2.1
var alive := true
var visual_root: Node3D
var body_material: StandardMaterial3D
var rift_pull_velocity := Vector3.ZERO
var rift_pull_time := 0.0
var elite := false
var xp_reward := 44
var guaranteed_item_drop := false


func setup_elite(is_elite: bool) -> void:
	elite = is_elite
	if elite:
		max_health = int(round(float(max_health) * 1.85))
		health = max_health
		move_speed *= 1.08
		attack_damage = int(round(float(attack_damage) * 1.45))
		xp_reward = 88
		guaranteed_item_drop = true


func _ready() -> void:
	add_to_group("enemies")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 3
	_build_visual()
	if elite:
		_apply_elite_visuals()


func _physics_process(delta: float) -> void:
	if not alive or not is_instance_valid(target):
		velocity = Vector3.ZERO
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	slam_timer = maxf(slam_timer - delta, 0.0)
	rift_pull_time = maxf(rift_pull_time - delta, 0.0)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var desired := Vector3.ZERO
	if distance > 0.02:
		var direction := offset.normalized()
		rotation.y = atan2(-direction.x, -direction.z)
		if distance > attack_range:
			desired = direction * move_speed
		elif attack_timer <= 0.0:
			target.take_damage(attack_damage)
			attack_timer = attack_interval
			_attack_pulse()

	if distance <= 3.1 and slam_timer <= 0.0:
		_ground_slam()
		slam_timer = slam_interval

	if rift_pull_time > 0.0:
		desired += rift_pull_velocity * 0.48
	else:
		rift_pull_velocity = rift_pull_velocity.move_toward(Vector3.ZERO, delta * 18.0)
	velocity = desired
	move_and_slide()


func _ground_slam() -> void:
	if is_instance_valid(target):
		var offset: Vector3 = target.global_position - global_position
		offset.y = 0.0
		if offset.length() <= 3.3 and target.has_method("take_damage"):
			target.take_damage(int(round(float(attack_damage) * 0.75)))
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.05
	torus.rings = 20
	torus.ring_segments = 7
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.position.y = -0.72
	var ring_material := _material(Color(0.31, 0.75, 0.05, 0.82), true)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_material
	add_child(ring)
	var faded_color := ring_material.albedo_color
	faded_color.a = 0.0
	var tween := create_tween()
	tween.tween_property(ring, "scale", Vector3(3.0, 3.0, 3.0), 0.22)
	tween.tween_property(ring_material, "albedo_color", faded_color, 0.12)
	tween.tween_callback(ring.queue_free)
	_attack_pulse()


func apply_rift_pull(center: Vector3, strength: float, hold_time: float = 0.12) -> void:
	if not alive:
		return
	var pull := center - global_position
	pull.y = 0.0
	var distance: float = maxf(pull.length(), 0.25)
	rift_pull_velocity = pull.normalized() * strength * clampf(distance / 3.0, 0.35, 0.85)
	rift_pull_time = hold_time


func take_damage(amount: int) -> void:
	if not alive:
		return
	health = maxi(health - amount, 0)
	_hit_flash()
	if health <= 0:
		_die()


func _die() -> void:
	alive = false
	collision_layer = 0
	collision_mask = 0
	died.emit(self)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_root, "scale", Vector3(0.08, 0.08, 0.08), 0.38)
	tween.tween_property(
		visual_root, "rotation_degrees:x", visual_root.rotation_degrees.x + 80.0, 0.38
	)
	tween.chain().tween_callback(queue_free)


func _attack_pulse() -> void:
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(1.18, 0.88, 1.18), 0.09)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.16)


func _hit_flash() -> void:
	if not is_instance_valid(body_material):
		return
	var original := Color(0.33, 0.30, 0.31)
	body_material.albedo_color = Color(1.0, 0.14, 0.82)
	var tween := create_tween()
	tween.tween_property(body_material, "albedo_color", original, 0.14)


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "CryptBruteVisual"
	add_child(visual_root)
	body_material = _material(Color(0.33, 0.30, 0.31), false)
	var armor := _material(Color(0.075, 0.055, 0.09), false)
	var void_glow := _material(Color(0.48, 0.035, 0.92), true)
	var green_glow := _material(Color(0.26, 0.70, 0.05), true)

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.72
	torso_mesh.height = 1.75
	torso.mesh = torso_mesh
	torso.position = Vector3(0.0, 0.15, 0.0)
	torso.scale = Vector3(1.25, 1.0, 1.0)
	torso.material_override = body_material
	visual_root.add_child(torso)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.48
	head_mesh.height = 0.82
	head.mesh = head_mesh
	head.position = Vector3(0.0, 1.15, 0.0)
	head.material_override = armor
	visual_root.add_child(head)

	for eye_x in [-0.15, 0.15]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.06
		eye_mesh.height = 0.12
		eye.mesh = eye_mesh
		eye.position = Vector3(eye_x, 1.20, -0.42)
		eye.material_override = void_glow
		visual_root.add_child(eye)

	for arm_x in [-0.72, 0.72]:
		var arm := MeshInstance3D.new()
		var arm_mesh := BoxMesh.new()
		arm_mesh.size = Vector3(0.38, 1.30, 0.42)
		arm.mesh = arm_mesh
		arm.position = Vector3(arm_x, 0.10, 0.0)
		arm.rotation_degrees.z = -8.0 if arm_x < 0.0 else 8.0
		arm.material_override = armor
		visual_root.add_child(arm)

	for leg_x in [-0.28, 0.28]:
		var leg := MeshInstance3D.new()
		var leg_mesh := BoxMesh.new()
		leg_mesh.size = Vector3(0.34, 1.10, 0.38)
		leg.mesh = leg_mesh
		leg.position = Vector3(leg_x, -1.05, 0.0)
		leg.material_override = armor
		visual_root.add_child(leg)

	var chest_core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.22
	core_mesh.height = 0.44
	chest_core.mesh = core_mesh
	chest_core.position = Vector3(0.0, 0.28, -0.68)
	chest_core.material_override = green_glow
	visual_root.add_child(chest_core)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.78
	shape.height = 2.65
	collision.shape = shape
	collision.position = Vector3(0.0, 0.0, 0.0)
	add_child(collision)


func _apply_elite_visuals() -> void:
	visual_root.scale = Vector3(1.18, 1.18, 1.18)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.4, 0.0)
	light.light_color = Color(0.35, 0.84, 0.05)
	light.light_energy = 2.6
	light.omni_range = 4.0
	visual_root.add_child(light)


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.9
		material.emission_energy_multiplier = 2.6
	return material
