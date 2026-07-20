extends CharacterBody3D

signal died(enemy: Node)

var target: Node3D
var max_health := 48
var health := 48
var move_speed := 2.75
var attack_damage := 9
var attack_range := 1.35
var attack_interval := 0.8
var attack_timer := 0.0
var alive := true
var visual_root: Node3D
var bone_material: StandardMaterial3D
var rift_pull_velocity := Vector3.ZERO
var rift_pull_time := 0.0
var elite := false
var xp_reward := 22
var guaranteed_item_drop := false


func setup_elite(is_elite: bool) -> void:
	elite = is_elite
	if elite:
		max_health = int(round(float(max_health) * 2.35))
		health = max_health
		move_speed *= 1.12
		attack_damage = int(round(float(attack_damage) * 1.55))
		xp_reward = 52
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

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	var desired_velocity := Vector3.ZERO

	if distance > 0.02:
		var direction := to_target / distance
		rotation.y = atan2(-direction.x, -direction.z)

		if distance > attack_range:
			desired_velocity = direction * move_speed
		elif attack_timer <= 0.0 and target.has_method("take_damage"):
			target.take_damage(attack_damage)
			attack_timer = attack_interval
			_attack_pulse()

	if rift_pull_time > 0.0:
		desired_velocity += rift_pull_velocity
	else:
		rift_pull_velocity = rift_pull_velocity.move_toward(Vector3.ZERO, delta * 20.0)

	velocity = desired_velocity
	move_and_slide()


func apply_rift_pull(center: Vector3, strength: float, hold_time: float = 0.12) -> void:
	if not alive:
		return
	var pull_direction := center - global_position
	pull_direction.y = 0.0
	var distance: float = maxf(pull_direction.length(), 0.25)
	rift_pull_velocity = pull_direction.normalized() * strength * clampf(distance / 2.2, 0.65, 1.45)
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
	tween.tween_property(visual_root, "scale", Vector3(0.08, 0.08, 0.08), 0.28).set_trans(
		Tween.TRANS_BACK
	)
	tween.tween_property(
		visual_root, "rotation_degrees:y", visual_root.rotation_degrees.y + 140.0, 0.28
	)
	tween.chain().tween_callback(queue_free)


func _hit_flash() -> void:
	if not is_instance_valid(bone_material):
		return
	var original := Color(0.67, 0.64, 0.58)
	bone_material.albedo_color = Color(1.0, 0.12, 0.82)
	var tween := create_tween()
	tween.tween_property(bone_material, "albedo_color", original, 0.13)


func _attack_pulse() -> void:
	if not is_instance_valid(visual_root):
		return
	var tween := create_tween()
	tween.tween_property(visual_root, "position:z", -0.28, 0.06)
	tween.tween_property(visual_root, "position:z", 0.0, 0.10)


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "SkeletonReaverVisual"
	add_child(visual_root)

	bone_material = StandardMaterial3D.new()
	bone_material.albedo_color = Color(0.67, 0.64, 0.58)
	bone_material.roughness = 0.9

	var dark_material := _material(Color(0.032, 0.018, 0.045), false)
	var eye_material := _material(Color(0.48, 0.035, 0.92), true)
	var green_material := _material(Color(0.26, 0.64, 0.055), true)
	var metal_material := _material(Color(0.10, 0.085, 0.12), false)

	_add_box_part(Vector3(0.0, 0.15, 0.0), Vector3(0.42, 0.72, 0.24), bone_material)
	_add_box_part(Vector3(-0.30, 0.14, 0.0), Vector3(0.13, 0.80, 0.13), bone_material)
	_add_box_part(Vector3(0.30, 0.14, 0.0), Vector3(0.13, 0.80, 0.13), bone_material)
	_add_box_part(Vector3(-0.14, -0.55, 0.0), Vector3(0.15, 0.72, 0.15), bone_material)
	_add_box_part(Vector3(0.14, -0.55, 0.0), Vector3(0.15, 0.72, 0.15), bone_material)

	var skull := MeshInstance3D.new()
	var skull_mesh := SphereMesh.new()
	skull_mesh.radius = 0.31
	skull_mesh.height = 0.58
	skull.mesh = skull_mesh
	skull.position = Vector3(0.0, 0.72, 0.0)
	skull.scale = Vector3(0.95, 1.05, 0.84)
	skull.material_override = bone_material
	visual_root.add_child(skull)

	var jaw := MeshInstance3D.new()
	var jaw_mesh := BoxMesh.new()
	jaw_mesh.size = Vector3(0.36, 0.16, 0.27)
	jaw.mesh = jaw_mesh
	jaw.position = Vector3(0.0, 0.50, -0.06)
	jaw.material_override = bone_material
	visual_root.add_child(jaw)

	for eye_x in [-0.10, 0.10]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.05
		eye_mesh.height = 0.10
		eye.mesh = eye_mesh
		eye.position = Vector3(eye_x, 0.75, -0.27)
		eye.material_override = eye_material
		visual_root.add_child(eye)

	var chest_void := MeshInstance3D.new()
	var chest_mesh := SphereMesh.new()
	chest_mesh.radius = 0.15
	chest_mesh.height = 0.30
	chest_void.mesh = chest_mesh
	chest_void.position = Vector3(0.0, 0.20, -0.16)
	chest_void.material_override = eye_material
	visual_root.add_child(chest_void)

	for shoulder_x in [-0.36, 0.36]:
		var armor := MeshInstance3D.new()
		var armor_mesh := PrismMesh.new()
		armor_mesh.size = Vector3(0.36, 0.36, 0.32)
		armor.mesh = armor_mesh
		armor.position = Vector3(shoulder_x, 0.44, 0.0)
		armor.rotation_degrees.z = -18.0 if shoulder_x < 0.0 else 18.0
		armor.material_override = metal_material
		visual_root.add_child(armor)

	var cleaver := MeshInstance3D.new()
	var cleaver_mesh := BoxMesh.new()
	cleaver_mesh.size = Vector3(0.20, 1.25, 0.11)
	cleaver.mesh = cleaver_mesh
	cleaver.position = Vector3(0.48, -0.02, -0.10)
	cleaver.rotation_degrees.z = 24.0
	cleaver.material_override = dark_material
	visual_root.add_child(cleaver)

	var blade_glow := MeshInstance3D.new()
	var glow_mesh := BoxMesh.new()
	glow_mesh.size = Vector3(0.055, 1.08, 0.13)
	blade_glow.mesh = glow_mesh
	blade_glow.position = cleaver.position + Vector3(-0.08, 0.0, 0.0)
	blade_glow.rotation_degrees.z = 24.0
	blade_glow.material_override = green_material
	visual_root.add_child(blade_glow)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.7
	collision.shape = capsule
	add_child(collision)


func _apply_elite_visuals() -> void:
	if not is_instance_valid(visual_root):
		return
	visual_root.scale = Vector3(1.22, 1.22, 1.22)
	var crown := MeshInstance3D.new()
	var crown_mesh := PrismMesh.new()
	crown_mesh.size = Vector3(0.68, 0.52, 0.40)
	crown.mesh = crown_mesh
	crown.position = Vector3(0.0, 1.18, 0.0)
	crown.rotation_degrees = Vector3(0.0, 0.0, 180.0)
	crown.material_override = _material(Color(0.33, 0.78, 0.045), true)
	visual_root.add_child(crown)

	var elite_light := OmniLight3D.new()
	elite_light.position = Vector3(0.0, 0.45, 0.0)
	elite_light.light_color = Color(0.35, 0.82, 0.06)
	elite_light.light_energy = 2.1
	elite_light.omni_range = 3.4
	visual_root.add_child(elite_light)


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.7
		material.emission_energy_multiplier = 2.4
	return material


func _add_box_part(position_value: Vector3, size_value: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	part.mesh = mesh
	part.position = position_value
	part.material_override = material
	visual_root.add_child(part)
