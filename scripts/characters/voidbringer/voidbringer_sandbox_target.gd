class_name VoidbringerSandboxTarget
extends Node3D

signal damaged(amount: int, health: int)
signal died()
signal reset_completed()

@export var maximum_health := 100
@export var collision_radius := 0.72

var health := 100
var alive := true
var hit_calls := 0
var visual_root: Node3D
var body_mesh: MeshInstance3D
var health_label: Label3D
var _alive_material: StandardMaterial3D
var _dead_material: StandardMaterial3D


func configure_visuals(
	alive_material: StandardMaterial3D,
	dead_material: StandardMaterial3D
) -> void:
	_alive_material = alive_material
	_dead_material = dead_material
	if visual_root == null:
		visual_root = Node3D.new()
		visual_root.name = "VisualRoot"
		add_child(visual_root)
	if body_mesh == null:
		body_mesh = MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.58
		capsule.height = 1.8
		body_mesh.mesh = capsule
		visual_root.add_child(body_mesh)
	if health_label == null:
		health_label = Label3D.new()
		health_label.position.y = 1.55
		health_label.font_size = 32
		health_label.modulate = Color(0.95, 0.90, 0.92)
		add_child(health_label)
	reset_target()


func take_damage(amount: int) -> int:
	if not alive or amount <= 0:
		return 0
	hit_calls += 1
	var applied := mini(health, amount)
	health -= applied
	damaged.emit(applied, health)
	if health <= 0:
		health = 0
		alive = false
		died.emit()
	_refresh_visual()
	return applied


func reset_target() -> void:
	health = maximum_health
	alive = true
	hit_calls = 0
	_refresh_visual()
	reset_completed.emit()


func _refresh_visual() -> void:
	if body_mesh != null:
		body_mesh.material_override = _alive_material if alive else _dead_material
	if visual_root != null:
		visual_root.scale = Vector3.ONE if alive else Vector3(1.0, 0.32, 1.0)
		visual_root.rotation_degrees = Vector3.ZERO if alive else Vector3(0.0, 0.0, 78.0)
	if health_label != null:
		health_label.text = "ENEMY  %d / %d" % [health, maximum_health]
		health_label.modulate = Color(0.95, 0.90, 0.92) if alive else Color(0.55, 0.32, 0.35)
