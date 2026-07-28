extends Node3D
class_name ShadowStepVfxPass0B

const PALETTE = preload("res://scripts/art/abyssfall_art_palette.gd")

var source: Node3D
var travel_direction := Vector3.FORWARD
var travel_duration := 0.16
var elapsed := 0.0
var emit_elapsed := 0.0
var arrival_spawned := false
var last_emit_position := Vector3.ZERO
var segment_index := 0
var trail_root: Node3D
var departure_root: Node3D
var arrival_root: Node3D


func _ready() -> void:
	set_process(false)


func setup(
	new_source: Node3D,
	origin: Vector3,
	direction: Vector3,
	duration: float
) -> void:
	source = new_source
	travel_direction = direction.normalized()
	travel_duration = maxf(duration, 0.01)
	global_position = origin
	last_emit_position = Vector3.ZERO
	_build_visual()
	set_process(true)


func _process(delta: float) -> void:
	elapsed += delta
	emit_elapsed += delta
	var local_source_position := _source_local_position()
	if elapsed <= travel_duration + 0.045:
		if emit_elapsed >= 0.028 or local_source_position.distance_to(last_emit_position) >= 0.36:
			emit_elapsed = 0.0
			_spawn_afterimage(local_source_position)
			last_emit_position = local_source_position
	elif not arrival_spawned:
		arrival_spawned = true
		_spawn_arrival(local_source_position)
	_fade_afterimages()
	if elapsed >= travel_duration + 0.48:
		queue_free()


func _source_local_position() -> Vector3:
	if is_instance_valid(source):
		return to_local(source.global_position)
	return travel_direction * 3.0


func _build_visual() -> void:
	trail_root = Node3D.new()
	trail_root.name = "ShadowStepAfterimageTrail"
	add_child(trail_root)

	departure_root = _create_burst_root("ShadowStepDeparture", Vector3.ZERO)
	add_child(departure_root)

	var direction_streak := MeshInstance3D.new()
	direction_streak.name = "ShadowStepDirectionStreak"
	var streak_mesh := BoxMesh.new()
	streak_mesh.size = Vector3(0.16, 0.045, 3.0)
	direction_streak.mesh = streak_mesh
	direction_streak.position = travel_direction * 1.5 + Vector3(0.0, 0.10, 0.0)
	direction_streak.rotation.y = atan2(-travel_direction.x, -travel_direction.z)
	direction_streak.material_override = PALETTE.translucent(PALETTE.VOID_FRACTURE, 0.34, 2.6)
	departure_root.add_child(direction_streak)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(departure_root, "scale", Vector3(1.55, 0.25, 1.55), 0.18).set_trans(
		Tween.TRANS_EXPO
	)


func _create_burst_root(root_name: String, position_value: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	root.position = position_value

	var violet_ring := _create_ring(0.74, 0.055, PALETTE.emissive(PALETTE.VOID_FRACTURE, 3.4, 0.10))
	violet_ring.name = "%s_VioletRing" % root_name
	violet_ring.position.y = 0.055
	root.add_child(violet_ring)

	var white_ring := _create_ring(
		0.49, 0.025, PALETTE.emissive(PALETTE.GRAVITATIONAL_WHITE, 4.2, 0.05)
	)
	white_ring.name = "%s_WhiteRing" % root_name
	white_ring.position.y = 0.07
	root.add_child(white_ring)

	for shard_index in range(6):
		var shard := MeshInstance3D.new()
		shard.name = "%s_Fracture_%02d" % [root_name, shard_index]
		var shard_mesh := PrismMesh.new()
		shard_mesh.size = Vector3(0.055, 0.27 + float(shard_index % 3) * 0.08, 0.04)
		shard.mesh = shard_mesh
		var angle := TAU * float(shard_index) / 6.0
		shard.position = Vector3(cos(angle) * 0.62, 0.12, sin(angle) * 0.62)
		shard.rotation_degrees = Vector3(42.0, -rad_to_deg(angle), 24.0 + float(shard_index) * 13.0)
		shard.material_override = (
			PALETTE.emissive(PALETTE.GRAVITATIONAL_WHITE, 3.8, 0.06)
			if shard_index == 0
			else PALETTE.emissive(PALETTE.VOID_FRACTURE, 2.8, 0.12)
		)
		root.add_child(shard)
	return root


func _spawn_afterimage(position_value: Vector3) -> void:
	if not is_instance_valid(trail_root):
		return
	var afterimage := MeshInstance3D.new()
	afterimage.name = "ShadowAfterimage_%03d" % segment_index
	afterimage.set_meta("born_at", elapsed)
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.46, 1.08, 0.18)
	afterimage.mesh = mesh
	afterimage.position = position_value + Vector3(0.0, 0.46, 0.0)
	afterimage.rotation.y = atan2(-travel_direction.x, -travel_direction.z)
	afterimage.scale = Vector3(0.58, 1.0, 1.75)
	var alpha := 0.31 - float(segment_index % 3) * 0.035
	afterimage.material_override = PALETTE.translucent(PALETTE.VOID_VIOLET, alpha, 1.8)
	trail_root.add_child(afterimage)
	segment_index += 1


func _spawn_arrival(position_value: Vector3) -> void:
	arrival_root = _create_burst_root("ShadowStepArrival", position_value)
	add_child(arrival_root)
	arrival_root.scale = Vector3(0.22, 1.4, 0.22)
	var light := OmniLight3D.new()
	light.name = "ShadowStepArrivalLight"
	light.light_color = PALETTE.GRAVITATIONAL_WHITE
	light.light_energy = 3.4
	light.omni_range = 2.8
	light.position = Vector3(0.0, 0.42, 0.0)
	arrival_root.add_child(light)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(arrival_root, "scale", Vector3(1.28, 0.24, 1.28), 0.13).set_trans(
		Tween.TRANS_BACK
	)
	tween.tween_property(arrival_root, "rotation_degrees:y", 95.0, 0.16)


func _fade_afterimages() -> void:
	if not is_instance_valid(trail_root):
		return
	for child: Node in trail_root.get_children():
		if not child is MeshInstance3D:
			continue
		var afterimage := child as MeshInstance3D
		var born_at := float(afterimage.get_meta("born_at", elapsed))
		var age := elapsed - born_at
		var remaining := clampf(1.0 - age / 0.30, 0.0, 1.0)
		afterimage.scale = Vector3(0.58 * remaining, maxf(0.08, remaining), 1.75 * remaining)
		if age >= 0.30:
			afterimage.queue_free()


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
