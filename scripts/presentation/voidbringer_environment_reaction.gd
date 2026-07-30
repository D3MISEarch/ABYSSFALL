class_name VoidbringerEnvironmentReaction
extends Node3D

signal reaction_started(snapshot: Dictionary)
signal reaction_finished

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const MAX_FULL_REACTIVE_PROPS := 6
const MAX_REDUCED_REACTIVE_PROPS := 3
const REACTION_RADIUS := 4.25
const REACTION_DURATION := 0.42

var settings: VoidbringerPresentationSettings
var props: Array[Dictionary] = []
var active_reactions: Dictionary = {}
var reaction_count := 0
var last_reaction: Dictionary = {}
var _next_prop_serial := 1


func configure(presentation_settings: VoidbringerPresentationSettings) -> void:
	settings = presentation_settings
	if settings == null:
		settings = SETTINGS_SCRIPT.new()


func build_showcase_props() -> void:
	clear()
	var placements := [
		{"position": Vector3(-3.3, 0.08, -1.1), "size": 0.16, "kind": &"stone"},
		{"position": Vector3(-2.4, 0.07, 0.2), "size": 0.12, "kind": &"stone"},
		{"position": Vector3(-1.6, 0.10, -3.2), "size": 0.18, "kind": &"urn"},
		{"position": Vector3(-0.7, 0.06, -1.4), "size": 0.10, "kind": &"stone"},
		{"position": Vector3(0.8, 0.08, -2.6), "size": 0.14, "kind": &"stone"},
		{"position": Vector3(1.7, 0.09, -0.9), "size": 0.17, "kind": &"urn"},
		{"position": Vector3(2.5, 0.06, 0.15), "size": 0.11, "kind": &"stone"},
		{"position": Vector3(3.2, 0.08, -1.5), "size": 0.15, "kind": &"stone"},
		{"position": Vector3(-0.2, 0.07, -4.6), "size": 0.13, "kind": &"stone"},
	]
	for placement: Dictionary in placements:
		_add_prop(
			placement.get("position", Vector3.ZERO),
			float(placement.get("size", 0.12)),
			StringName(str(placement.get("kind", &"stone")))
		)


func consume_impact(value: Variant) -> Dictionary:
	var impact := _snapshot(value)
	if impact.is_empty() or settings == null:
		return {}
	var mode := settings.effective_mode()
	if mode == VoidbringerPresentationSettings.MODE_DISABLED:
		return {}
	var impact_point: Vector3 = impact.get("impact_point", Vector3.ZERO)
	var travel_direction: Vector3 = impact.get("travel_direction", Vector3.FORWARD)
	if travel_direction.length_squared() <= 0.000001:
		travel_direction = Vector3.FORWARD
	else:
		travel_direction = travel_direction.normalized()
	var intensity := 0.55
	if bool(impact.get("fatal", false)):
		intensity = 1.0
	elif bool(impact.get("critical", false)):
		intensity = 0.82
	intensity = clampf(
		intensity + minf(float(impact.get("fold_crossing_count", 0)) * 0.08, 0.24),
		0.0,
		1.0
	)
	var limit := MAX_FULL_REACTIVE_PROPS
	if mode == VoidbringerPresentationSettings.MODE_REDUCED:
		limit = MAX_REDUCED_REACTIVE_PROPS
		intensity *= 0.52
	var selected := _nearest_props(impact_point, limit)
	for prop: Dictionary in selected:
		_activate_prop(prop, impact_point, travel_direction, intensity)
	reaction_count += 1
	last_reaction = {
		"cast_id": impact.get("cast_id", &""),
		"ability_id": impact.get("ability_id", &""),
		"mode": mode,
		"impact_point": impact_point,
		"intensity": intensity,
		"reactive_prop_count": selected.size(),
		"active_prop_count": active_reactions.size(),
	}
	reaction_started.emit(last_reaction.duplicate(true))
	return last_reaction.duplicate(true)


func tick(delta: float) -> void:
	var step := maxf(delta, 0.0)
	if step <= 0.0 or active_reactions.is_empty():
		return
	for raw_id: Variant in active_reactions.keys().duplicate():
		var prop_id := StringName(str(raw_id))
		var reaction := active_reactions.get(prop_id, {}) as Dictionary
		var node := reaction.get("node") as Node3D
		if not is_instance_valid(node):
			active_reactions.erase(prop_id)
			continue
		var elapsed := float(reaction.get("elapsed", 0.0)) + step
		var duration := maxf(float(reaction.get("duration", REACTION_DURATION)), 0.01)
		var progress := clampf(elapsed / duration, 0.0, 1.0)
		var envelope := sin(progress * PI)
		var base_position: Vector3 = reaction.get("base_position", node.position)
		var offset: Vector3 = reaction.get("offset", Vector3.ZERO)
		var spin: Vector3 = reaction.get("spin", Vector3.ZERO)
		node.position = base_position + offset * envelope
		node.rotation_degrees = spin * envelope
		if progress >= 1.0:
			node.position = base_position
			node.rotation_degrees = Vector3.ZERO
			active_reactions.erase(prop_id)
		else:
			reaction["elapsed"] = elapsed
			active_reactions[prop_id] = reaction
	if active_reactions.is_empty():
		reaction_finished.emit()


func clear() -> void:
	for prop: Dictionary in props:
		var node := prop.get("node") as Node3D
		if is_instance_valid(node):
			node.queue_free()
	props.clear()
	active_reactions.clear()
	last_reaction.clear()
	reaction_count = 0
	_next_prop_serial = 1


func reset_reactions() -> void:
	for prop: Dictionary in props:
		var node := prop.get("node") as Node3D
		if not is_instance_valid(node):
			continue
		node.position = prop.get("base_position", node.position)
		node.rotation_degrees = Vector3.ZERO
	active_reactions.clear()
	last_reaction.clear()


func debug_snapshot() -> Dictionary:
	var positions: Array[Dictionary] = []
	for prop: Dictionary in props:
		var node := prop.get("node") as Node3D
		if not is_instance_valid(node):
			continue
		positions.append({
			"prop_id": prop.get("prop_id", &""),
			"position": node.position,
			"base_position": prop.get("base_position", node.position),
			"kind": prop.get("kind", &""),
		})
	return {
		"prop_count": props.size(),
		"active_prop_count": active_reactions.size(),
		"reaction_count": reaction_count,
		"last_reaction": last_reaction.duplicate(true),
		"positions": positions,
	}


func _add_prop(position_value: Vector3, size_value: float, kind: StringName) -> void:
	var root := Node3D.new()
	var prop_id := StringName("vb.environment.prop.%04d" % _next_prop_serial)
	_next_prop_serial += 1
	root.name = String(prop_id)
	root.position = position_value
	add_child(root)
	var mesh_instance := MeshInstance3D.new()
	if kind == &"urn":
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = size_value * 0.52
		cylinder.bottom_radius = size_value * 0.78
		cylinder.height = size_value * 2.2
		mesh_instance.mesh = cylinder
	else:
		var sphere := SphereMesh.new()
		sphere.radius = size_value
		sphere.height = size_value * 1.45
		mesh_instance.mesh = sphere
		mesh_instance.scale = Vector3(1.25, 0.72, 0.92)
	mesh_instance.material_override = _prop_material(kind)
	root.add_child(mesh_instance)
	props.append({
		"prop_id": prop_id,
		"node": root,
		"base_position": position_value,
		"kind": kind,
	})


func _nearest_props(origin: Vector3, limit: int) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for prop: Dictionary in props:
		var base_position: Vector3 = prop.get("base_position", Vector3.ZERO)
		var distance := base_position.distance_to(origin)
		if distance > REACTION_RADIUS:
			continue
		var candidate := prop.duplicate(false)
		candidate["distance"] = distance
		candidates.append(candidate)
	candidates.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			var left_distance := float(left.get("distance", 0.0))
			var right_distance := float(right.get("distance", 0.0))
			if not is_equal_approx(left_distance, right_distance):
				return left_distance < right_distance
			return String(left.get("prop_id", "")) < String(right.get("prop_id", ""))
	)
	return candidates.slice(0, mini(limit, candidates.size()))


func _activate_prop(
	prop: Dictionary,
	impact_point: Vector3,
	travel_direction: Vector3,
	intensity: float
) -> void:
	var node := prop.get("node") as Node3D
	if not is_instance_valid(node):
		return
	var prop_id := StringName(str(prop.get("prop_id", "")))
	var base_position: Vector3 = prop.get("base_position", node.position)
	var outward := base_position - impact_point
	outward.y = 0.0
	if outward.length_squared() <= 0.000001:
		outward = -travel_direction
	outward.y = 0.0
	if outward.length_squared() <= 0.000001:
		outward = Vector3.RIGHT
	outward = outward.normalized()
	var serial := int(String(prop_id).get_slice(".", 3))
	var deterministic_side := -1.0 if serial % 2 == 0 else 1.0
	var sideways := Vector3(-outward.z, 0.0, outward.x) * deterministic_side
	var offset := (
		outward * (0.18 + 0.24 * intensity)
		+ sideways * (0.04 + 0.06 * intensity)
		+ Vector3.UP * (0.10 + 0.28 * intensity)
	)
	active_reactions[prop_id] = {
		"node": node,
		"base_position": base_position,
		"offset": offset,
		"spin": Vector3(18.0, 55.0 * deterministic_side, 24.0) * intensity,
		"elapsed": 0.0,
		"duration": REACTION_DURATION,
	}


func _prop_material(kind: StringName) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.11, 0.09, 0.14) if kind == &"urn" else Color(0.16, 0.15, 0.20)
	material.roughness = 0.94
	return material


func _snapshot(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value != null and value.has_method("snapshot"):
		return value.snapshot()
	return {}
