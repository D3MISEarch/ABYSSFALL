class_name VoidbringerFoldLineManager
extends RefCounted

signal lines_rebuilt(lines: Array[Dictionary])

var _lines: Dictionary = {}
var _ordered_ids: Array[StringName] = []


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
	for line: Dictionary in lines():
		if line.get("anchor_a_id", &"") == anchor_id or line.get("anchor_b_id", &"") == anchor_id:
			result.append(line)
	return result


func segment_crossings(from: Vector3, to: Vector3, epsilon: float = 0.001) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var movement_a := Vector2(from.x, from.z)
	var movement_b := Vector2(to.x, to.z)
	for line: Dictionary in lines():
		var start: Vector3 = line.get("start", Vector3.ZERO)
		var finish: Vector3 = line.get("end", Vector3.ZERO)
		if _segments_intersect(
			movement_a,
			movement_b,
			Vector2(start.x, start.z),
			Vector2(finish.x, finish.z),
			epsilon
		):
			result.append(line)
	return result


func _tension(first: Dictionary, second: Dictionary, length: float) -> float:
	if length <= 0.0001:
		return 0.0
	var combined_mass := float(first.get("mass", 0.0)) + float(second.get("mass", 0.0))
	return clampf(combined_mass / maxf(length, 1.0), 0.0, 100.0)


func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2, epsilon: float) -> bool:
	var ab := b - a
	var cd := d - c
	var denominator := ab.cross(cd)
	if absf(denominator) <= epsilon:
		return false
	var offset := c - a
	var t := offset.cross(cd) / denominator
	var u := offset.cross(ab) / denominator
	return t >= -epsilon and t <= 1.0 + epsilon and u >= -epsilon and u <= 1.0 + epsilon
