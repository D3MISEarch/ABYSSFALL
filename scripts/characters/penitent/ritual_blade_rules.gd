extends RefCounted
class_name RitualBladeRules

const REACH := 3.35
const HALF_ANGLE_DEGREES := 68.0
const STEP_IN_DISTANCE := 0.42
const STEP_IN_MIN_TARGET_DISTANCE := 1.85
const COMBO_DAMAGE := [10, 12, 18]


static func get_damage(combo_step: int) -> int:
	var resolved_step := clampi(combo_step, 1, COMBO_DAMAGE.size())
	return int(COMBO_DAMAGE[resolved_step - 1])


static func is_target_in_arc(
	origin: Vector3,
	facing: Vector3,
	target_position: Vector3,
	reach: float = REACH,
	half_angle_degrees: float = HALF_ANGLE_DEGREES
) -> bool:
	var flat_offset := target_position - origin
	flat_offset.y = 0.0
	var distance := flat_offset.length()
	if distance > reach:
		return false
	if distance <= 0.001:
		return true

	var flat_facing := facing
	flat_facing.y = 0.0
	if flat_facing.length_squared() <= 0.001:
		return false
	flat_facing = flat_facing.normalized()
	var direction := flat_offset / distance
	var minimum_dot := cos(deg_to_rad(clampf(half_angle_degrees, 0.0, 179.0)))
	return flat_facing.dot(direction) >= minimum_dot


static func get_step_in_distance(
	origin: Vector3,
	facing: Vector3,
	target_position: Vector3
) -> float:
	if not is_target_in_arc(
		origin,
		facing,
		target_position,
		REACH + STEP_IN_DISTANCE,
		HALF_ANGLE_DEGREES
	):
		return 0.0
	var flat_offset := target_position - origin
	flat_offset.y = 0.0
	var distance := flat_offset.length()
	if distance <= STEP_IN_MIN_TARGET_DISTANCE:
		return 0.0
	return minf(STEP_IN_DISTANCE, distance - STEP_IN_MIN_TARGET_DISTANCE)
