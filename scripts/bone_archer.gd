extends CharacterBody3D

signal died(enemy: Node)

const ENEMY_BOLT_SCRIPT = preload("res://scripts/enemy_bolt.gd")

var target: Node3D
var max_health := 38
var health := 38
var move_speed := 2.45
var attack_damage := 8
var preferred_range := 7.0
var retreat_range := 4.0
var attack_interval := 1.45
var attack_timer := 0.55
var alive := true
var visual_root: Node3D
var bone_material: StandardMaterial3D
var rift_pull_velocity := Vector3.ZERO
var rift_pull_time := 0.0
var elite := false
var xp_reward := 26
var guaranteed_item_drop := false


func setup_elite(is_elite: bool) -> void:
	elite = is_elite
	if elite:
		max_health = int(round(float(max_health) * 2.0))
		health = max_health
		move_speed *= 1.10
		attack_damage = int(round(float(attack_damage) * 1.55))
		attack_interval *= 0.82
		xp_reward = 58
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
	rift_pull_time = maxf(rift_pull_time - delta, 0.0)
	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.02 else Vector3.ZERO
	var desired := Vector3.ZERO

	if distance > 0.02:
		rotation.y = atan2(-direction.x, -direction.z)
	if distance > preferred_range:
		desired = direction * move_speed
	elif distance < retreat_range:
		desired = -direction * move_speed * 0.85
	elif attack_timer <= 0.0:
		_fire_bone_bolt(direction)
		attack_timer = attack_interval

	if rift_pull_time > 0.0:
		desired += rift_pull_velocity
	else:
		rift_pull_velocity = rift_pull_velocity.move_toward(Vector3.ZERO, delta * 20.0)
	velocity = desired
	move_and_slide()


func _fire_bone_bolt(direction: Vector3) -> void:
	if direction.length_squared() <= 0.01:
		return
	var bolt := ENEMY_BOLT_SCRIPT.new()
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position + direction * 0.75 + Vector3(0.0, 0.58, 0.0)
	bolt.setup(direction, 12.5, attack_damage, self, Color(0.60, 0.05, 1.0))
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(0.90, 1.12, 0.90), 0.06)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.12)


func apply_rift_pull(center: Vector3, strength: float, hold_time: float = 0.12) -> void:
	if not alive:
		return
	var pull := center - global_position
	pull.y = 0.0
	var distance: float = maxf(pull.length(), 0.25)
	rift_pull_velocity = pull.normalized() * strength * clampf(distance / 2.3, 0.55, 1.35)
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
	tween.tween_property(visual_root, "scale", Vector3(0.06, 0.06, 0.06), 0.28)
	tween.tween_property(
		visual_root, "rotation_degrees:y", visual_root.rotation_degrees.y + 170.0, 0.28
	)
	tween.chain().tween_callback(queue_free)


func _hit_flash() -> void:
	if not is_instance_valid(bone_material):
		return
	var original := Color(0.70, 0.66, 0.58)
	bone_material.albedo_color = Color(1.0, 0.15, 0.90)
	var tween := create_tween()
	tween.tween_property(bone_material, "albedo_color", original, 0.13)


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "BoneArcherVisual"
	add_child(visual_root)

	bone_material = _material(Color(0.70, 0.66, 0.58), false)
	var cloth := _material(Color(0.055, 0.018, 0.075), false)
	var metal := _material(Color(0.12, 0.09, 0.14), false)
	var glow := _material(Color(0.55, 0.04, 1.0), true)

	_add_box(Vector3(0.0, 0.08, 0.0), Vector3(0.34, 0.72, 0.22), bone_material)
	_add_box(Vector3(-0.24, 0.05, 0.0), Vector3(0.10, 0.76, 0.10), bone_material)
	_add_box(Vector3(0.24, 0.05, 0.0), Vector3(0.10, 0.76, 0.10), bone_material)
	_add_box(Vector3(-0.12, -0.57, 0.0), Vector3(0.12, 0.70, 0.12), bone_material)
	_add_box(Vector3(0.12, -0.57, 0.0), Vector3(0.12, 0.70, 0.12), bone_material)

	var skull := MeshInstance3D.new()
	var skull_mesh := SphereMesh.new()
	skull_mesh.radius = 0.28
	skull_mesh.height = 0.50
	skull.mesh = skull_mesh
	skull.position = Vector3(0.0, 0.67, 0.0)
	skull.material_override = bone_material
	visual_root.add_child(skull)

	for eye_x in [-0.09, 0.09]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.045
		eye_mesh.height = 0.09
		eye.mesh = eye_mesh
		eye.position = Vector3(eye_x, 0.70, -0.245)
		eye.material_override = glow
		visual_root.add_child(eye)

	var cape := MeshInstance3D.new()
	var cape_mesh := BoxMesh.new()
	cape_mesh.size = Vector3(0.55, 1.20, 0.05)
	cape.mesh = cape_mesh
	cape.position = Vector3(0.0, -0.05, 0.18)
	cape.material_override = cloth
	visual_root.add_child(cape)

	var bow := MeshInstance3D.new()
	var bow_mesh := TorusMesh.new()
	bow_mesh.inner_radius = 0.62
	bow_mesh.outer_radius = 0.70
	bow_mesh.rings = 18
	bow_mesh.ring_segments = 5
	bow.mesh = bow_mesh
	bow.position = Vector3(0.48, 0.10, -0.08)
	bow.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	bow.scale = Vector3(1.0, 0.50, 1.0)
	bow.material_override = metal
	visual_root.add_child(bow)

	var arrow := MeshInstance3D.new()
	var arrow_mesh := CylinderMesh.new()
	arrow_mesh.top_radius = 0.025
	arrow_mesh.bottom_radius = 0.025
	arrow_mesh.height = 1.05
	arrow.mesh = arrow_mesh
	arrow.position = Vector3(0.30, 0.10, -0.10)
	arrow.rotation_degrees.z = 90.0
	arrow.material_override = glow
	visual_root.add_child(arrow)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.65
	collision.shape = capsule
	add_child(collision)


func _apply_elite_visuals() -> void:
	visual_root.scale = Vector3(1.18, 1.18, 1.18)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.45, 0.0)
	light.light_color = Color(0.30, 0.82, 0.05)
	light.light_energy = 2.0
	light.omni_range = 3.2
	visual_root.add_child(light)


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.8
		material.emission_energy_multiplier = 2.5
	return material


func _add_box(position_value: Vector3, size_value: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	part.mesh = mesh
	part.position = position_value
	part.material_override = material
	visual_root.add_child(part)
