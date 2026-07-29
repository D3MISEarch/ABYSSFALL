class_name VoidbringerFoldLineManager
extends RefCounted

signal lines_rebuilt(lines: Array[Dictionary])

const DEFAULT_LINE_INTERACTION_RADIUS := 0.25
const GEOMETRY_EPSILON := 0.000001

var line_interaction_radius := DEFAULT_LINE_INTERACTION_RADIUS
var _lines: Dictionary = {}
var _ordered_ids: Array[StringName] = []


func configure_interaction_radius(radius: float) -> void:
	line_interaction_radius = maxf(radius, 0.0)


func rebuild(anchor_snapshots: Array) -> Array[Dictionary]:
	_lines.clear()
	_ordered_ids.clear()
	var anchors: Array[Dictionary] = []
	for raw_anchor: Variant in anchor_snapshots:
		if raw_anchor is Dictionary and StringName(str(raw_anchor.get("anchor_id", ""))) != &"":
			anchors.append((raw_anchor as Dictionary).duplicate(true))
	anchors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("anchor_id", "")) < str(b.get("anchor_id", ""))
	)

	for first_index in range(anchors.size()):
		for second_index in range(first_index + 1, anchors.size()):
			var first: Dictionary = anchors[first_index]
			var second: Dictionary = anchors[second_index]
			var first_id := StringName(str(first.get("anchor_id", "")))
			var second_id := StringName(str(second.get("anchor_id", "")))
			var start: Vector3 = first.get("position", Vector3.ZERO)
			var finish: Vector3 = second.get("position", Vector3.ZERO)
			var offset := finish - start
			var length := offset.length()
			var line_id := StringName("vb.fold_line.%s--%s" % [String(first_id), String(second_id)])
			var line := {
				"line_id": line_id,
				"anchor_a_id": first_id,
				"anchor_b_id": second_id,
				"start": start,
				"end": finish,
				"length": length,
				"direction": offset.normalized() if length > 0.0001 else Vector3.ZERO,
				"mass_difference": absf(float(first.get("mass", 0.0)) - float(second.get("mass", 0.0))),
				"tension": _tension(first, second, length),
				"has_gameplay_collision": false,
			}
			_lines[line_id] = line
			_ordered_ids.append(line_id)

	var result := lines()
	lines_rebuilt.emit(result)
	return result


func clear() -> void:
	_lines.clear()
	_ordered_ids.clear()
	lines_rebuilt.emit([])


func line_count() -> int:
	return _ordered_ids.size()


func lines() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for line_id: StringName in _ordered_ids:
		if _lines.has(line_id):
			result.append((_lines[line_id] as Dictionary).duplicate(true))
	return result


func get_line(line_id: StringName) -> Dictionary:
	if not _lines.has(line_id):
		return {}
	return (_lines[line_id] as Dictionary).duplicate(true)


func lines_for_anchor(anchor_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for line_id: StringName in _ordered_ids:
		if not _lines.has(line_id):
			continue
		var line: Dictionary = _lines[line_id]
		if line.get("anchor_a_id", &"") == anchor_id or line.get("anchor_b_id", &"") == anchor_id:
			result.append(line.duplicate(true))
	return result


func segment_crossings(from: Vector3, to: Vector3, projectile_radius: float = 0.0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var total_radius := maxf(projectile_radius, 0.0) + line_interaction_radius
	var threshold_squared := total_radius * total_radius
	for line_id: StringName in _ordered_ids:
		if not _lines.has(line_id):
			continue
		var line: Dictionary = _lines[line_id]
		var start: Vector3 = line.get("start", Vector3.ZERO)
		var finish: Vector3 = line.get("end", Vector3.ZERO)
		if _segment_distance_squared(from, to, start, finish) <= threshold_squared:
			result.append(line.duplicate(true))
	return result


func interaction_snapshot() -> Dictionary:
	return {
		"line_interaction_radius": line_interaction_radius,
	}


func _tension(first: Dictionary, second: Dictionary, length: float) -> float:
	if length <= 0.0001:
		return 0.0
	var combined_mass := float(first.get("mass", 0.0)) + float(second.get("mass", 0.0))
	return clampf(combined_mass / maxf(length, 1.0), 0.0, 100.0)


func _segment_distance_squared(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	var d1 := q1 - p1
	var d2 := q2 - p2
	var r := p1 - p2
	var a := d1.dot(d1)
	var e := d2.dot(d2)
	var f := d2.dot(r)
	var s := 0.0
	var t := 0.0

	if a <= GEOMETRY_EPSILON and e <= GEOMETRY_EPSILON:
		return p1.distance_squared_to(p2)
	if a <= GEOMETRY_EPSILON:
		t = clampf(f / e, 0.0, 1.0)
	else:
		var c := d1.dot(r)
		if e <= GEOMETRY_EPSILON:
			s = clampf(-c / a, 0.0, 1.0)
		else:
			var b := d1.dot(d2)
			var denominator := a * e - b * b
			if absf(denominator) > GEOMETRY_EPSILON:
				s = clampf((b * f - c * e) / denominator, 0.0, 1.0)
			t = (b * s + f) / e
			if t < 0.0:
				t = 0.0
				s = clampf(-c / a, 0.0, 1.0)
			elif t > 1.0:
				t = 1.0
				s = clampf((b - c) / a, 0.0, 1.0)

	var closest_first := p1 + d1 * s
	var closest_second := p2 + d2 * t
	return closest_first.distance_squared_to(closest_second)
