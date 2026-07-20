extends CharacterBody3D

signal died(boss: Node)
signal health_changed(current_health: int, maximum_health: int, phase: int)
signal summon_requested(position_value: Vector3, enemy_type: String)
signal phase_changed(phase: int)

const ENEMY_BOLT_SCRIPT = preload("res://scripts/enemy_bolt.gd")

var target: Node3D
var max_health := 1050
var health := 1050
var phase := 1
var move_speed := 2.35
var attack_damage := 18
var melee_range := 2.25
var melee_timer := 0.8
var volley_timer := 1.8
var summon_timer := 6.5
var nova_timer := 4.2
var teleport_timer := 8.0
var alive := true
var visual_root: Node3D
var armor_material: StandardMaterial3D
var core_material: StandardMaterial3D
var corruption_material: StandardMaterial3D
var rift_pull_velocity := Vector3.ZERO
var rift_pull_time := 0.0
var phase_lock := false


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 3
	_build_visual()
	health_changed.emit(health, max_health, phase)


func _physics_process(delta: float) -> void:
	if not alive or not is_instance_valid(target) or phase_lock:
		velocity = Vector3.ZERO
		return

	melee_timer = maxf(melee_timer - delta, 0.0)
	volley_timer = maxf(volley_timer - delta, 0.0)
	summon_timer = maxf(summon_timer - delta, 0.0)
	nova_timer = maxf(nova_timer - delta, 0.0)
	teleport_timer = maxf(teleport_timer - delta, 0.0)
	rift_pull_time = maxf(rift_pull_time - delta, 0.0)

	var offset := target.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var direction := offset.normalized() if distance > 0.02 else Vector3.ZERO
	if direction.length_squared() > 0.01:
		rotation.y = atan2(-direction.x, -direction.z)

	var desired := Vector3.ZERO
	var desired_range := 5.4 if phase == 1 else (3.8 if phase == 2 else 2.7)
	if distance > desired_range:
		desired = direction * move_speed
	elif distance < desired_range - 1.6 and phase == 1:
		desired = -direction * move_speed * 0.45

	if distance <= melee_range and melee_timer <= 0.0:
		_melee_strike()
		melee_timer = 1.05 if phase == 1 else (0.86 if phase == 2 else 0.66)

	if volley_timer <= 0.0:
		_cast_volley(direction)
		volley_timer = 3.0 if phase == 1 else (2.4 if phase == 2 else 1.75)

	if summon_timer <= 0.0:
		_summon_servants()
		summon_timer = 8.5 if phase == 1 else (7.0 if phase == 2 else 5.8)

	if phase >= 2 and nova_timer <= 0.0:
		_cast_nova()
		nova_timer = 5.2 if phase == 2 else 3.7

	if phase == 3 and teleport_timer <= 0.0:
		_void_step()
		teleport_timer = 6.0

	if rift_pull_time > 0.0:
		desired += rift_pull_velocity * 0.20
	else:
		rift_pull_velocity = rift_pull_velocity.move_toward(Vector3.ZERO, delta * 16.0)
	velocity = desired
	move_and_slide()


func _melee_strike() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		var offset: Vector3 = target.global_position - global_position
		offset.y = 0.0
		if offset.length() <= melee_range + 0.35:
			target.take_damage(attack_damage + (4 if phase == 2 else (8 if phase == 3 else 0)))
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(1.18, 0.88, 1.18), 0.09)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.16)


func _cast_volley(direction: Vector3) -> void:
	if direction.length_squared() <= 0.01:
		return
	var count := 3 if phase == 1 else (5 if phase == 2 else 7)
	var spread := 0.18 if phase == 1 else (0.27 if phase == 2 else 0.36)
	for i in range(count):
		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		var angle: float = lerpf(-spread, spread, t)
		var cast_direction := direction.rotated(Vector3.UP, angle)
		_spawn_bolt(cast_direction, 10.5 + float(phase), 8 + phase * 2, Color(0.60, 0.04, 1.0))
	_cast_pulse(Color(0.52, 0.03, 1.0))


func _cast_nova() -> void:
	var count := 10 if phase == 2 else 14
	for i in range(count):
		var angle := TAU * float(i) / float(count)
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		_spawn_bolt(direction, 8.8 + float(phase), 7 + phase * 2, Color(0.28, 0.82, 0.05))
	if (
		is_instance_valid(target)
		and target.has_method("take_damage")
		and global_position.distance_to(target.global_position) <= 4.4
	):
		target.take_damage(10 + phase * 3)
	_cast_pulse(Color(0.28, 0.82, 0.05))


func _spawn_bolt(direction: Vector3, speed: float, damage_value: int, bolt_color: Color) -> void:
	var bolt := ENEMY_BOLT_SCRIPT.new()
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position + direction * 1.15 + Vector3(0.0, 1.05, 0.0)
	bolt.setup(direction, speed, damage_value, self, bolt_color)


func _summon_servants() -> void:
	var types: Array[String] = ["reaver", "reaver"]
	if phase >= 2:
		types.append("archer")
	if phase == 3:
		types.append("brute")
	for i in range(types.size()):
		var angle := TAU * float(i) / float(types.size()) + randf_range(-0.18, 0.18)
		var position_value := global_position + Vector3(cos(angle), 0.0, sin(angle)) * 4.0
		summon_requested.emit(position_value, types[i])
	_cast_pulse(Color(0.48, 0.03, 0.96))


func _void_step() -> void:
	if not is_instance_valid(target):
		return
	var angle := randf_range(0.0, TAU)
	var destination := (
		target.global_position + Vector3(cos(angle), 0.0, sin(angle)) * randf_range(2.8, 4.5)
	)
	global_position.x = destination.x
	global_position.z = destination.z
	_cast_nova()


func apply_rift_pull(center: Vector3, strength: float, hold_time: float = 0.12) -> void:
	if not alive:
		return
	var pull := center - global_position
	pull.y = 0.0
	if pull.length_squared() <= 0.01:
		return
	rift_pull_velocity = pull.normalized() * strength * 0.28
	rift_pull_time = hold_time


func take_damage(amount: int) -> void:
	if not alive or phase_lock:
		return
	health = maxi(health - amount, 0)
	_hit_flash()
	_update_phase()
	health_changed.emit(health, max_health, phase)
	if health <= 0:
		_die()


func _update_phase() -> void:
	var next_phase := 1
	var ratio := float(health) / float(max_health)
	if ratio <= 0.33:
		next_phase = 3
	elif ratio <= 0.66:
		next_phase = 2
	if next_phase != phase:
		phase = next_phase
		phase_changed.emit(phase)
		_begin_phase_transition()


func _begin_phase_transition() -> void:
	phase_lock = true
	velocity = Vector3.ZERO
	move_speed = 2.35 + float(phase - 1) * 0.42
	attack_damage = 18 + (phase - 1) * 4
	if is_instance_valid(core_material):
		core_material.emission_energy_multiplier = 4.0 + float(phase)
	if is_instance_valid(corruption_material):
		corruption_material.emission_energy_multiplier = 3.4 + float(phase) * 0.8
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(1.35, 1.35, 1.35), 0.22)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(_finish_phase_transition)


func _finish_phase_transition() -> void:
	phase_lock = false
	_cast_nova()


func _die() -> void:
	alive = false
	collision_layer = 0
	collision_mask = 0
	velocity = Vector3.ZERO
	died.emit(self)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_root, "scale", Vector3(1.55, 1.55, 1.55), 0.18)
	tween.tween_property(
		visual_root, "rotation_degrees:y", visual_root.rotation_degrees.y + 150.0, 0.45
	)
	tween.chain().tween_property(visual_root, "scale", Vector3(0.02, 0.02, 0.02), 0.55)
	tween.chain().tween_callback(queue_free)


func _hit_flash() -> void:
	if not is_instance_valid(armor_material):
		return
	var original := Color(0.075, 0.052, 0.10)
	armor_material.albedo_color = Color(0.92, 0.15, 1.0)
	var tween := create_tween()
	tween.tween_property(armor_material, "albedo_color", original, 0.13)


func _cast_pulse(color: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 4.0
	light.omni_range = 7.0
	light.position = Vector3(0.0, 1.0, 0.0)
	add_child(light)
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.32)
	tween.tween_callback(light.queue_free)


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "HollowKingVisual"
	add_child(visual_root)
	armor_material = _material(Color(0.075, 0.052, 0.10), false)
	var robe_material := _material(Color(0.035, 0.012, 0.055), false)
	core_material = _material(Color(0.55, 0.025, 1.0), true)
	corruption_material = _material(Color(0.28, 0.78, 0.05), true)
	var metal_material := _material(Color(0.15, 0.11, 0.17), false)

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.78
	torso_mesh.height = 2.1
	torso.mesh = torso_mesh
	torso.position = Vector3(0.0, 0.35, 0.0)
	torso.scale = Vector3(1.15, 1.0, 0.95)
	torso.material_override = armor_material
	visual_root.add_child(torso)

	var robe := MeshInstance3D.new()
	var robe_mesh := CylinderMesh.new()
	robe_mesh.top_radius = 0.72
	robe_mesh.bottom_radius = 1.22
	robe_mesh.height = 2.2
	robe.mesh = robe_mesh
	robe.position = Vector3(0.0, -1.05, 0.0)
	robe.material_override = robe_material
	visual_root.add_child(robe)

	var hood := MeshInstance3D.new()
	var hood_mesh := PrismMesh.new()
	hood_mesh.size = Vector3(1.25, 1.25, 1.05)
	hood.mesh = hood_mesh
	hood.position = Vector3(0.0, 1.55, 0.0)
	hood.rotation_degrees.x = 180.0
	hood.material_override = armor_material
	visual_root.add_child(hood)

	var face := MeshInstance3D.new()
	var face_mesh := SphereMesh.new()
	face_mesh.radius = 0.40
	face_mesh.height = 0.72
	face.mesh = face_mesh
	face.position = Vector3(0.0, 1.50, -0.42)
	face.material_override = robe_material
	visual_root.add_child(face)

	for eye_x in [-0.14, 0.14]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.065
		eye_mesh.height = 0.13
		eye.mesh = eye_mesh
		eye.position = Vector3(eye_x, 1.58, -0.78)
		eye.material_override = core_material
		visual_root.add_child(eye)

	var chest_core := MeshInstance3D.new()
	var chest_mesh := SphereMesh.new()
	chest_mesh.radius = 0.34
	chest_mesh.height = 0.64
	chest_core.mesh = chest_mesh
	chest_core.position = Vector3(0.0, 0.55, -0.72)
	chest_core.material_override = core_material
	visual_root.add_child(chest_core)

	for shoulder_x in [-0.86, 0.86]:
		var shoulder := MeshInstance3D.new()
		var shoulder_mesh := PrismMesh.new()
		shoulder_mesh.size = Vector3(0.72, 0.72, 0.62)
		shoulder.mesh = shoulder_mesh
		shoulder.position = Vector3(shoulder_x, 0.95, 0.0)
		shoulder.rotation_degrees.z = -18.0 if shoulder_x < 0.0 else 18.0
		shoulder.material_override = metal_material
		visual_root.add_child(shoulder)

	var scythe_handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.07
	handle_mesh.bottom_radius = 0.08
	handle_mesh.height = 3.2
	scythe_handle.mesh = handle_mesh
	scythe_handle.position = Vector3(1.05, 0.05, 0.0)
	scythe_handle.rotation_degrees.z = 18.0
	scythe_handle.material_override = metal_material
	visual_root.add_child(scythe_handle)

	var blade := MeshInstance3D.new()
	var blade_mesh := PrismMesh.new()
	blade_mesh.size = Vector3(1.55, 0.45, 0.18)
	blade.mesh = blade_mesh
	blade.position = Vector3(1.36, 1.43, 0.0)
	blade.rotation_degrees = Vector3(0.0, 0.0, -18.0)
	blade.material_override = corruption_material
	visual_root.add_child(blade)

	for i in range(5):
		var crown_spike := MeshInstance3D.new()
		var spike_mesh := PrismMesh.new()
		spike_mesh.size = Vector3(0.18, 0.72 + float(i % 2) * 0.28, 0.18)
		crown_spike.mesh = spike_mesh
		crown_spike.position = Vector3(-0.42 + float(i) * 0.21, 2.28 + float(i % 2) * 0.12, 0.0)
		crown_spike.material_override = core_material if i == 2 else metal_material
		visual_root.add_child(crown_spike)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.75, 0.0)
	light.light_color = Color(0.52, 0.04, 1.0)
	light.light_energy = 3.2
	light.omni_range = 7.5
	visual_root.add_child(light)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.90
	shape.height = 3.55
	collision.shape = shape
	collision.position = Vector3(0.0, 0.0, 0.0)
	add_child(collision)


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if glowing:
		material.emission_enabled = true
		material.emission = color * 3.0
		material.emission_energy_multiplier = 3.0
	return material
