class_name VoidbringerSandboxTarget
extends Node3D

signal damaged(amount: int, health: int)
signal died()
signal reset_completed()

const IMPACT_FEEDBACK_SCRIPT = preload("res://scripts/impact_feedback.gd")
const PRESENTATION_SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")

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
	_refresh_state_visuals()
	return applied


func present_voidbringer_impact_result(
	impact: Dictionary,
	presentation_settings: Dictionary
) -> void:
	if not is_instance_valid(visual_root):
		return
	var effective_mode := StringName(str(
		presentation_settings.get("effective_mode", presentation_settings.get("mode", &"full"))
	))
	if effective_mode == PRESENTATION_SETTINGS_SCRIPT.MODE_DISABLED:
		return
	var direction: Vector3 = impact.get("travel_direction", Vector3.FORWARD)
	var primary_hit := effective_mode == PRESENTATION_SETTINGS_SCRIPT.MODE_FULL
	IMPACT_FEEDBACK_SCRIPT.play_contact(
		visual_root,
		direction,
		&"light",
		primary_hit,
		bool(impact.get("fatal", false))
	)


func reset_target() -> void:
	health = maximum_health
	alive = true
	hit_calls = 0
	_reset_presentation_root()
	_refresh_state_visuals()
	reset_completed.emit()


func _reset_presentation_root() -> void:
	if not is_instance_valid(visual_root):
		return
	var feedback := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	if is_instance_valid(feedback):
		visual_root.remove_child(feedback)
		feedback.queue_free()
	visual_root.position = Vector3.ZERO
	visual_root.scale = Vector3.ONE
	visual_root.rotation_degrees = Vector3.ZERO


func _refresh_state_visuals() -> void:
	if body_mesh != null:
		body_mesh.material_override = _alive_material if alive else _dead_material
	if health_label != null:
		health_label.text = "ENEMY  %d / %d" % [health, maximum_health]
		health_label.modulate = Color(0.95, 0.90, 0.92) if alive else Color(0.55, 0.32, 0.35)
