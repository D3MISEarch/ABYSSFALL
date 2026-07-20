extends Control
class_name FervorSeal

const THRESHOLD_NAMES := ["DORMANT", "KINDLED", "ZEALOUS", "FANATICAL", "REVELATION"]

var current_value := 0.0
var maximum_value := 100.0
var displayed_value := 0.0
var threshold := 0
var pulse_time := 0.0

var preview_fervor_cost := 0.0
var preview_health_percent := 0
var active_sigils := 0
var maximum_sigils := 3

var value_label: Label
var threshold_label: Label
var sacrifice_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(196.0, 196.0)
	_build_labels()
	queue_redraw()


func set_resource(new_value: float, new_maximum: float) -> void:
	maximum_value = maxf(new_maximum, 1.0)
	current_value = clampf(new_value, 0.0, maximum_value)
	threshold = _threshold_for_value(current_value)
	_update_labels()


func set_cost_preview(fervor_cost: float, health_percent: int = 0) -> void:
	preview_fervor_cost = clampf(fervor_cost, 0.0, maximum_value)
	preview_health_percent = maxi(health_percent, 0)
	_update_labels()
	queue_redraw()


func clear_cost_preview() -> void:
	set_cost_preview(0.0, 0)


func set_sigil_capacity(active_count: int, maximum_count: int) -> void:
	maximum_sigils = maxi(maximum_count, 1)
	active_sigils = clampi(active_count, 0, maximum_sigils)
	queue_redraw()


func get_state_snapshot() -> Dictionary:
	return {
		"current": current_value,
		"maximum": maximum_value,
		"threshold": threshold,
		"preview_fervor_cost": preview_fervor_cost,
		"preview_health_percent": preview_health_percent,
		"active_sigils": active_sigils,
		"maximum_sigils": maximum_sigils,
	}


func _process(delta: float) -> void:
	pulse_time += delta
	displayed_value = lerpf(displayed_value, current_value, clampf(delta * 8.0, 0.0, 1.0))
	threshold = _threshold_for_value(displayed_value)
	_update_labels()
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.39
	var ratio := clampf(displayed_value / maxf(maximum_value, 1.0), 0.0, 1.0)
	var heartbeat := (sin(pulse_time * (2.3 + float(threshold) * 0.55)) + 1.0) * 0.5

	_draw_backplate(center, radius)
	_draw_assembled_segments(center, radius, ratio, heartbeat)
	_draw_inner_geometry(center, radius, ratio, heartbeat)
	_draw_threshold_ticks(center, radius)
	_draw_cost_preview(center, radius, ratio)
	_draw_sigil_pips(center, radius)


func _draw_backplate(center: Vector2, radius: float) -> void:
	draw_circle(center, radius + 19.0, Color(0.008, 0.005, 0.008, 0.94))
	draw_arc(center, radius + 17.0, 0.0, TAU, 72, Color(0.08, 0.06, 0.07), 8.0, true)
	draw_arc(center, radius + 7.0, 0.0, TAU, 72, Color(0.20, 0.025, 0.035), 2.0, true)


func _draw_assembled_segments(
	center: Vector2,
	radius: float,
	ratio: float,
	heartbeat: float
) -> void:
	var segment_count := 16
	var active_count := int(ceil(ratio * float(segment_count)))
	for index in range(segment_count):
		var segment_start := -PI * 0.5 + TAU * float(index) / float(segment_count) + 0.035
		var segment_end := -PI * 0.5 + TAU * float(index + 1) / float(segment_count) - 0.035
		var is_active := index < active_count
		var segment_color := Color(0.16, 0.025, 0.032, 0.50)
		var width := 7.0
		if is_active:
			segment_color = Color(0.78 + heartbeat * 0.12, 0.025, 0.04, 0.94)
			width = 9.0
			if threshold >= 2 and index % 3 == 0:
				segment_color = Color(0.28, 0.88, 0.055, 0.82)
		draw_arc(center, radius, segment_start, segment_end, 7, segment_color, width, true)

		var middle_angle := (segment_start + segment_end) * 0.5
		var inner_point := center + Vector2(cos(middle_angle), sin(middle_angle)) * (radius - 11.0)
		var outer_point := center + Vector2(cos(middle_angle), sin(middle_angle)) * (radius + 13.0)
		draw_line(
			inner_point,
			outer_point,
			Color(0.54, 0.48, 0.39, 0.82) if is_active else Color(0.15, 0.14, 0.14, 0.52),
			2.0,
			true
		)


func _draw_inner_geometry(
	center: Vector2,
	radius: float,
	ratio: float,
	heartbeat: float
) -> void:
	var inner_radius := radius * 0.58
	draw_arc(center, inner_radius, 0.0, TAU, 64, Color(0.43, 0.018, 0.028, 0.84), 3.0, true)

	var rotation_offset := pulse_time * (0.08 + float(threshold) * 0.015)
	var points := PackedVector2Array()
	for index in range(6):
		var angle := rotation_offset + TAU * float(index) / 6.0
		points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)
	points.append(points[0])
	draw_polyline(points, Color(0.68, 0.03, 0.045, 0.70 + heartbeat * 0.18), 2.5, true)

	for index in range(3):
		var angle := -PI * 0.5 + TAU * float(index) / 3.0 - rotation_offset * 0.45
		var point_a := center + Vector2(cos(angle), sin(angle)) * inner_radius * 0.92
		var point_b := center + Vector2(cos(angle + PI), sin(angle + PI)) * inner_radius * 0.92
		draw_line(point_a, point_b, Color(0.45, 0.025, 0.04, 0.64), 2.0, true)

	if ratio >= 0.50:
		var contamination := clampf((ratio - 0.5) * 2.0, 0.0, 1.0)
		for index in range(4):
			var angle := pulse_time * 0.05 + TAU * float(index) / 4.0
			var start := center + Vector2(cos(angle), sin(angle)) * (inner_radius * 0.30)
			var finish := center + Vector2(cos(angle + 0.35), sin(angle + 0.35)) * (inner_radius * (0.72 + contamination * 0.18))
			draw_line(start, finish, Color(0.31, 0.92, 0.05, 0.38 + contamination * 0.38), 2.0, true)

	if threshold == 4:
		draw_circle(center, 8.0 + heartbeat * 3.0, Color(0.88, 0.82, 0.66, 0.90))
		draw_arc(center, radius + 15.0, 0.0, TAU, 64, Color(0.86, 0.05, 0.07, 0.55 + heartbeat * 0.25), 3.0, true)


func _draw_threshold_ticks(center: Vector2, radius: float) -> void:
	for index in range(4):
		var angle := -PI * 0.5 + TAU * float(index) / 4.0
		var start := center + Vector2(cos(angle), sin(angle)) * (radius + 5.0)
		var finish := center + Vector2(cos(angle), sin(angle)) * (radius + 17.0)
		draw_line(start, finish, Color(0.73, 0.68, 0.52, 0.92), 4.0, true)


func _draw_cost_preview(center: Vector2, radius: float, ratio: float) -> void:
	if preview_fervor_cost <= 0.0:
		return
	var available_ratio := minf(preview_fervor_cost / maxf(maximum_value, 1.0), ratio)
	var end_angle := -PI * 0.5
	var start_angle := end_angle - TAU * available_ratio
	draw_arc(center, radius - 13.0, start_angle, end_angle, 32, Color(0.95, 0.36, 0.10, 0.88), 6.0, true)

	if preview_health_percent > 0:
		var health_ratio := clampf(float(preview_health_percent) / 100.0, 0.0, 1.0)
		draw_arc(
			center,
			radius - 21.0,
			end_angle,
			end_angle + TAU * health_ratio,
			18,
			Color(0.95, 0.02, 0.04, 0.96),
			7.0,
			true
		)


func _draw_sigil_pips(center: Vector2, radius: float) -> void:
	var spacing := 17.0
	var total_width := float(maximum_sigils - 1) * spacing
	for index in range(maximum_sigils):
		var pip_center := Vector2(center.x - total_width * 0.5 + float(index) * spacing, center.y + radius + 29.0)
		var filled := index < active_sigils
		draw_circle(pip_center, 5.0, Color(0.72, 0.035, 0.05, 0.92) if filled else Color(0.12, 0.08, 0.09, 0.88))
		draw_arc(pip_center, 6.5, 0.0, TAU, 18, Color(0.43, 0.36, 0.29, 0.82), 1.5, true)


func _build_labels() -> void:
	value_label = Label.new()
	value_label.set_anchors_preset(Control.PRESET_CENTER)
	value_label.position = Vector2(-48.0, -23.0)
	value_label.size = Vector2(96.0, 34.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 25)
	value_label.modulate = Color(0.94, 0.84, 0.76)
	add_child(value_label)

	threshold_label = Label.new()
	threshold_label.set_anchors_preset(Control.PRESET_CENTER)
	threshold_label.position = Vector2(-63.0, 8.0)
	threshold_label.size = Vector2(126.0, 24.0)
	threshold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	threshold_label.add_theme_font_size_override("font_size", 13)
	threshold_label.modulate = Color(0.82, 0.12, 0.16)
	add_child(threshold_label)

	sacrifice_label = Label.new()
	sacrifice_label.set_anchors_preset(Control.PRESET_CENTER)
	sacrifice_label.position = Vector2(-68.0, 31.0)
	sacrifice_label.size = Vector2(136.0, 22.0)
	sacrifice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sacrifice_label.add_theme_font_size_override("font_size", 11)
	sacrifice_label.modulate = Color(0.96, 0.20, 0.18)
	add_child(sacrifice_label)
	_update_labels()


func _update_labels() -> void:
	if not is_instance_valid(value_label):
		return
	value_label.text = "%d" % int(round(displayed_value))
	threshold_label.text = THRESHOLD_NAMES[clampi(threshold, 0, THRESHOLD_NAMES.size() - 1)]
	threshold_label.modulate = Color(0.36, 0.92, 0.06) if threshold >= 2 else Color(0.82, 0.12, 0.16)
	if preview_health_percent > 0:
		sacrifice_label.text = "BLOOD COST: %d%%" % preview_health_percent
	else:
		sacrifice_label.text = ""


func _threshold_for_value(value: float) -> int:
	var ratio := clampf(value / maxf(maximum_value, 1.0), 0.0, 1.0)
	if ratio >= 0.999:
		return 4
	if ratio >= 0.75:
		return 3
	if ratio >= 0.50:
		return 2
	if ratio >= 0.25:
		return 1
	return 0
