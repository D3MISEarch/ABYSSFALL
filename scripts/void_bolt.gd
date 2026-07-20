extends Area3D

var direction := Vector3.FORWARD
var move_speed := 22.0
var damage := 18
var source: Node
var lifetime := 1.8
var initialized := false
var splash_radius := 0.0
var splash_damage := 0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 4
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	_build_visual()


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


func _physics_process(delta: float) -> void:
	if not initialized:
		return
	global_position += direction * move_speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == source:
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
	monitoring = false
	move_speed = 0.0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(2.3, 2.3, 2.3), 0.07)
	tween.tween_callback(queue_free)


func _build_visual() -> void:
	var void_material := StandardMaterial3D.new()
	void_material.albedo_color = Color(0.48, 0.04, 1.0)
	void_material.emission_enabled = true
	void_material.emission = Color(1.1, 0.10, 2.8)
	void_material.emission_energy_multiplier = 3.2
	void_material.roughness = 0.1

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.24
	core_mesh.height = 0.48
	core.mesh = core_mesh
	core.material_override = void_material
	add_child(core)

	var tail := MeshInstance3D.new()
	var tail_mesh := CylinderMesh.new()
	tail_mesh.top_radius = 0.07
	tail_mesh.bottom_radius = 0.18
	tail_mesh.height = 0.75
	tail.mesh = tail_mesh
	tail.rotation_degrees.x = 90.0
	tail.position = Vector3(0.0, 0.0, 0.38)
	tail.material_override = void_material
	add_child(tail)

	var light := OmniLight3D.new()
	light.light_color = Color(0.52, 0.08, 1.0)
	light.light_energy = 2.4
	light.omni_range = 2.7
	add_child(light)

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.28
	collision.shape = sphere
	add_child(collision)
