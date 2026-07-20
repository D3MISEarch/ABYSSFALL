extends RefCounted
class_name AshenProcessionRules

const TRAIL_LIFETIME := 5.0
const ARM_DISTANCE := 0.85
const CROSSING_RADIUS := 0.52
const ENEMY_LINE_RADIUS := 0.74
const MINIMUM_TRAIL_LENGTH := 1.15


static func point_segment_distance(point: Vector3, start: Vector3, finish: Vector3) -> float:
	var point_2d := Vector2(point.x, point.z)
	var start_2d := Vector2(start.x, start.z)
	var finish_2d := Vector2(finish.x, finish.z)
	var segment := finish_2d - start_2d
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point_2d.distance_to(start_2d)
	var ratio := clampf((point_2d - start_2d).dot(segment) / length_squared, 0.0, 1.0)
	return point_2d.distance_to(start_2d + segment * ratio)


static func should_arm(
	caster_position: Vector3,
	start: Vector3,
	finish: Vector3,
	arm_distance: float = ARM_DISTANCE
) -> bool:
	return point_segment_distance(caster_position, start, finish) >= maxf(arm_distance, 0.05)


static func did_cross(
	previous_position: Vector3,
	current_position: Vector3,
	start: Vector3,
	finish: Vector3,
	trigger_radius: float = CROSSING_RADIUS
) -> bool:
	var safe_radius := maxf(trigger_radius, 0.05)
	var previous_distance := point_segment_distance(previous_position, start, finish)
	var current_distance := point_segment_distance(current_position, start, finish)
	if previous_distance > safe_radius and current_distance <= safe_radius:
		return true
	if previous_position.distance_squared_to(current_position) <= 0.0025:
		return false
	return (
		previous_distance > safe_radius * 0.45
		and _segments_intersect(
			Vector2(previous_position.x, previous_position.z),
			Vector2(current_position.x, current_position.z),
			Vector2(start.x, start.z),
			Vector2(finish.x, finish.z)
		)
	)


static func is_enemy_on_rite_line(
	enemy_position: Vector3,
	start: Vector3,
	finish: Vector3,
	radius: float = ENEMY_LINE_RADIUS
) -> bool:
	return point_segment_distance(enemy_position, start, finish) <= maxf(radius, 0.05)


static func is_valid_trail(start: Vector3, finish: Vector3) -> bool:
	var offset := finish - start
	offset.y = 0.0
	return offset.length() >= MINIMUM_TRAIL_LENGTH


static func get_impact_damage(mark_state: int) -> int:
	if mark_state >= 3:
		return 28
	if mark_state > 0:
		return 21
	return 16


static func get_fervor_reward(hit_count: int, complete_rite_count: int) -> float:
	if hit_count <= 0:
		return 0.0
	return minf(4.0 + float(hit_count) * 2.0 + float(maxi(complete_rite_count, 0)) * 2.0, 16.0)


static func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var movement := b - a
	var trail := d - c
	var denominator := _cross_2d(movement, trail)
	if absf(denominator) <= 0.0001:
		return false
	var offset := c - a
	var movement_ratio := _cross_2d(offset, trail) / denominator
	var trail_ratio := _cross_2d(offset, movement) / denominator
	return (
		movement_ratio >= 0.0
		and movement_ratio <= 1.0
		and trail_ratio >= 0.0
		and trail_ratio <= 1.0
	)


static func _cross_2d(a: Vector2, b: Vector2) -> float:
	return a.x * b.y - a.y * b.x
