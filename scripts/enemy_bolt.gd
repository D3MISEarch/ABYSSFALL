extends Area3D

var direction := Vector3.FORWARD
var move_speed := 12.0
var damage := 9
var source: Node
var lifetime := 3.2
var initialized := false
var color := Color(0.60, 0.05, 1.0)


func setup(
	new_direction: Vector3,
	new_speed: float,
	new_damage: int,
	new_source: Node,
	new_color: Color = Color(0.60, 0.05, 1.0)
) -> void:
	direction = new_direction.normalized()
	move_speed = new_speed
	damage = new_damage
	source = new_source
	color = new_color
	initialized = true
	rotation.y = atan2(-direction.x, -direction.z)


func _ready() -> void:
	collision_layer = 16
	collision_mask = 3
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	_build_visual()


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
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		_impact()
	elif body.collision_layer == 1:
		_impact()


func _impact() -> void:
	monitoring = false
	move_speed = 0.0
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.9, 1.9, 1.9), 0.07)
	tween.tween_callback(queue_free)


func _build_visual() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 3.2
	material.emission_energy_multiplier = 3.0
	material.roughness = 0.08

	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.20
	sphere.height = 0.40
	core.mesh = sphere
	core.material_override = material
	add_child(core)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.23
	torus.outer_radius = 0.31
	torus.rings = 16
	torus.ring_segments = 7
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = material
	add_child(ring)

	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.9
	light.omni_range = 2.4
	add_child(light)

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	collision.shape = shape
	add_child(collision)
