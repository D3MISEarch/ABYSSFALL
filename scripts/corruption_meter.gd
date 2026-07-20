extends Control

var current_value := 0.0
var maximum_value := 100.0
var displayed_value := 0.0
var pulse_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(470.0, 76.0)
	queue_redraw()


func set_corruption(new_value: float, new_maximum: float) -> void:
	current_value = clampf(new_value, 0.0, maxf(new_maximum, 1.0))
	maximum_value = maxf(new_maximum, 1.0)


func _process(delta: float) -> void:
	pulse_time += delta
	displayed_value = lerpf(displayed_value, current_value, clampf(delta * 7.0, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	var ratio: float = clampf(displayed_value / maximum_value, 0.0, 1.0)
	var bar_rect: Rect2 = Rect2(42.0, 27.0, maxf(size.x - 84.0, 120.0), 22.0)
	var pulse: float = (sin(pulse_time * (3.0 + ratio * 3.0)) + 1.0) * 0.5

	draw_rect(
		Rect2(bar_rect.position - Vector2(6.0, 7.0), bar_rect.size + Vector2(12.0, 14.0)),
		Color(0.015, 0.007, 0.020, 0.98),
		true
	)
	draw_rect(bar_rect, Color(0.025, 0.009, 0.035, 1.0), true)

	var fill_width: float = bar_rect.size.x * ratio
	if fill_width > 1.0:
		draw_rect(
			Rect2(bar_rect.position, Vector2(fill_width, bar_rect.size.y)),
			Color(0.36 + pulse * 0.10, 0.02, 0.68 + pulse * 0.20, 0.96),
			true
		)
		draw_rect(
			Rect2(bar_rect.position + Vector2(0.0, 5.0), Vector2(fill_width, 4.0)),
			Color(0.72, 0.18, 1.0, 0.65),
			true
		)
		draw_rect(
			Rect2(bar_rect.position + Vector2(0.0, 14.0), Vector2(fill_width, 3.0)),
			Color(0.24, 0.72, 0.045, 0.45 + pulse * 0.20),
			true
		)

	_draw_living_frame(bar_rect, ratio, pulse)
	_draw_eye(Vector2(25.0, 38.0), ratio, pulse)
	_draw_growth_mouth(bar_rect, ratio, pulse)
	_draw_tendrils(bar_rect, ratio, pulse)


func _draw_living_frame(bar_rect: Rect2, ratio: float, pulse: float) -> void:
	var top_points := PackedVector2Array()
	var bottom_points := PackedVector2Array()
	var segments: int = 26
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var x: float = bar_rect.position.x + bar_rect.size.x * t
		var local_growth: float = clampf((ratio - t * 0.86) * 3.2, 0.0, 1.0)
		var wobble: float = sin(t * 21.0 + pulse_time * 2.2) * (1.2 + local_growth * 2.4)
		top_points.append(Vector2(x, bar_rect.position.y - 7.0 - local_growth * 8.0 + wobble))
		bottom_points.append(Vector2(x, bar_rect.end.y + 7.0 + local_growth * 8.0 - wobble))

	draw_polyline(top_points, Color(0.035, 0.012, 0.040, 1.0), 14.0, true)
	draw_polyline(bottom_points, Color(0.035, 0.012, 0.040, 1.0), 14.0, true)
	draw_polyline(top_points, Color(0.16, 0.075, 0.12, 0.95), 7.0, true)
	draw_polyline(bottom_points, Color(0.16, 0.075, 0.12, 0.95), 7.0, true)

	if ratio > 0.18:
		draw_polyline(top_points, Color(0.27, 0.74, 0.045, 0.28 + pulse * 0.20), 1.8, true)
		draw_polyline(bottom_points, Color(0.45, 0.06, 0.86, 0.42 + pulse * 0.24), 2.0, true)


func _draw_eye(center: Vector2, ratio: float, pulse: float) -> void:
	var growth: float = 1.0 + ratio * 0.35 + pulse * 0.06
	draw_circle(center, 19.0 * growth, Color(0.025, 0.008, 0.030, 1.0))
	draw_circle(center, 13.0 * growth, Color(0.17, 0.045, 0.15, 1.0))
	draw_circle(center, (5.0 + pulse * 2.0) * growth, Color(0.58, 0.04, 1.0, 1.0))
	draw_circle(center, 2.0 * growth, Color(0.88, 0.48, 1.0, 1.0))
	for i in range(6):
		var angle: float = TAU * float(i) / 6.0 + pulse_time * 0.08
		var start: Vector2 = center + Vector2(cos(angle), sin(angle)) * 14.0
		var finish: Vector2 = center + Vector2(cos(angle), sin(angle)) * (22.0 + ratio * 7.0)
		draw_line(start, finish, Color(0.18, 0.08, 0.16, 1.0), 4.0, true)


func _draw_growth_mouth(bar_rect: Rect2, ratio: float, pulse: float) -> void:
	if ratio < 0.68:
		return
	var mouth_growth: float = clampf((ratio - 0.68) / 0.32, 0.0, 1.0)
	var center: Vector2 = Vector2(bar_rect.end.x + 7.0, bar_rect.get_center().y)
	var radius_x: float = 15.0 + mouth_growth * 22.0
	var radius_y: float = 12.0 + mouth_growth * 15.0 + pulse * 2.0
	draw_set_transform(center, 0.0, Vector2(radius_x / radius_y, 1.0))
	draw_circle(Vector2.ZERO, radius_y + 8.0, Color(0.045, 0.012, 0.035, 1.0))
	draw_circle(Vector2.ZERO, radius_y, Color(0.005, 0.001, 0.008, 1.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var tooth_count: int = 8
	for i in range(tooth_count):
		var t: float = (float(i) + 0.5) / float(tooth_count)
		var x: float = center.x - radius_x * 0.72 + t * radius_x * 1.44
		var tooth_height: float = 4.0 + mouth_growth * 8.0
		var top_tooth := PackedVector2Array(
			[
				Vector2(x - 3.0, center.y - radius_y * 0.55),
				Vector2(x + 3.0, center.y - radius_y * 0.55),
				Vector2(x, center.y - radius_y * 0.55 + tooth_height)
			]
		)
		var bottom_tooth := PackedVector2Array(
			[
				Vector2(x - 3.0, center.y + radius_y * 0.55),
				Vector2(x + 3.0, center.y + radius_y * 0.55),
				Vector2(x, center.y + radius_y * 0.55 - tooth_height)
			]
		)
		draw_colored_polygon(top_tooth, Color(0.55, 0.55, 0.42, 0.90))
		draw_colored_polygon(bottom_tooth, Color(0.55, 0.55, 0.42, 0.90))


func _draw_tendrils(bar_rect: Rect2, ratio: float, pulse: float) -> void:
	var count: int = int(floor(ratio * 9.0))
	if count <= 0:
		return
	var fill_x: float = bar_rect.position.x + bar_rect.size.x * ratio
	for i in range(count):
		var tendril_seed: float = float(i) * 1.91
		var start := Vector2(
			fill_x - fmod(tendril_seed * 37.0, maxf(bar_rect.size.x * ratio, 1.0)),
			bar_rect.position.y if i % 2 == 0 else bar_rect.end.y
		)
		var direction: float = -1.0 if i % 2 == 0 else 1.0
		var length: float = 7.0 + ratio * 20.0 + sin(tendril_seed + pulse_time * 1.4) * 4.0
		var end: Vector2 = start + Vector2(sin(tendril_seed * 2.3 + pulse_time) * 8.0, direction * length)
		var midpoint: Vector2 = (start + end) * 0.5 + Vector2(cos(tendril_seed) * 6.0, 0.0)
		var points: PackedVector2Array = PackedVector2Array([start, midpoint, end])
		draw_polyline(points, Color(0.12, 0.04, 0.10, 0.96), 5.0 + ratio * 2.0, true)
		draw_polyline(points, Color(0.30, 0.68, 0.05, 0.35 + pulse * 0.25), 1.5, true)
