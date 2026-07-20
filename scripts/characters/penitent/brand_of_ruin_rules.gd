extends RefCounted
class_name BrandOfRuinRules

const MAX_TARGET_RANGE := 8.0
const MIN_FORWARD_DOT := -0.10
const ECHO_RADIUS := 4.8
const ECHO_RATIO := 0.42
const MAX_ECHO_TARGETS := 5


static func score_target(
	caster_position: Vector3,
	facing: Vector3,
	target_position: Vector3
) -> float:
	var offset: Vector3 = target_position - caster_position
	offset.y = 0.0
	var distance := offset.length()
	if distance <= 0.01 or distance > MAX_TARGET_RANGE:
		return -1.0
	var flat_facing := facing
	flat_facing.y = 0.0
	if flat_facing.length_squared() <= 0.001:
		flat_facing = Vector3(0.0, 0.0, -1.0)
	var forward_dot := flat_facing.normalized().dot(offset / distance)
	if forward_dot < MIN_FORWARD_DOT:
		return -1.0
	return forward_dot * 2.4 + (1.0 - distance / MAX_TARGET_RANGE)


static func calculate_echo_damage(base_damage: int) -> int:
	return maxi(int(round(float(maxi(base_damage, 0)) * ECHO_RATIO)), 1)


static func can_echo_between(primary_position: Vector3, target_position: Vector3) -> bool:
	var offset: Vector3 = target_position - primary_position
	offset.y = 0.0
	return offset.length_squared() <= ECHO_RADIUS * ECHO_RADIUS
