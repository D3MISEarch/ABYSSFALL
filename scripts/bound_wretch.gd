extends CharacterBody3D

var owner_player: Node3D
var lifetime := 12.0
var attack_timer := 0.4
var attack_interval := 0.75
var attack_damage := 14
var move_speed := 5.6
var visual_root: Node3D


func setup(new_owner: Node3D) -> void:
	owner_player = new_owner


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 0
	collision_mask = 1
	_build_visual()


func _physics_process(delta: float) -> void:
	lifetime -= delta
	attack_timer = maxf(attack_timer - delta, 0.0)
	if lifetime <= 0.0 or not is_instance_valid(owner_player):
		_fade_out()
		return

	var target := _nearest_enemy()
	if is_instance_valid(target):
		var offset: Vector3 = target.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance > 1.55:
			velocity = offset.normalized() * move_speed
		else:
			velocity = Vector3.ZERO
			if attack_timer <= 0.0 and target.has_method("take_damage"):
				target.take_damage(attack_damage)
				attack_timer = attack_interval
				_attack_pulse()
		if distance > 0.02:
			rotation.y = atan2(-offset.x, -offset.z)
	else:
		var follow_offset: Vector3 = owner_player.global_position - global_position
		follow_offset.y = 0.0
		if follow_offset.length() > 2.4:
			velocity = follow_offset.normalized() * move_speed
		else:
			velocity = Vector3.ZERO
	move_and_slide()


func _nearest_enemy() -> Node3D:
	var nearest: Node3D
	var nearest_distance := 9999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance and distance <= 9.0:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _attack_pulse() -> void:
	if not is_instance_valid(visual_root):
		return
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(1.28, 0.82, 1.28), 0.07)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.13)


func _fade_out() -> void:
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.28)
	tween.tween_callback(queue_free)


func _build_visual() -> void:
	visual_root = Node3D.new()
	add_child(visual_root)
	var bone := _material(Color(0.34, 0.31, 0.30), false)
	var void_glow := _material(Color(0.55, 0.04, 1.0), true)
	var green_glow := _material(Color(0.30, 0.78, 0.05), true)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.25
	body_mesh.height = 0.90
	body.mesh = body_mesh
	body.material_override = bone
	visual_root.add_child(body)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.25
	head_mesh.height = 0.45
	head.mesh = head_mesh
	head.position = Vector3(0.0, 0.58, 0.0)
	head.material_override = bone
	visual_root.add_child(head)

	for eye_x in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.035
		eye_mesh.height = 0.07
		eye.mesh = eye_mesh
		eye.position = Vector3(eye_x, 0.61, -0.22)
		eye.material_override = void_glow
		visual_root.add_child(eye)

	var soul_core := MeshInstance3D.new()
	var soul_mesh := SphereMesh.new()
	soul_mesh.radius = 0.13
	soul_mesh.height = 0.26
	soul_core.mesh = soul_mesh
	soul_core.position = Vector3(0.0, 0.15, -0.20)
	soul_core.material_override = green_glow
	visual_root.add_child(soul_core)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.2
	collision.shape = shape
	add_child(collision)


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if glowing:
		material.emission_enabled = true
		material.emission = color * 3.0
		material.emission_energy_multiplier = 2.6
	return material
