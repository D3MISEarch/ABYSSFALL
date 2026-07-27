extends RefCounted
class_name PlayableAimResolver

const STICK_DEADZONE := 0.28
const DIRECTION_EPSILON_SQUARED := 0.01
const MOUSE_EPSILON_SQUARED := 0.04


static func resolve_facing(
	current_facing: Vector3,
	move_direction: Vector3,
	stick_aim: Vector2,
	controller_authority: bool,
	mouse_direction: Vector3 = Vector3.ZERO,
	has_mouse_direction: bool = false
) -> Vector3:
	if stick_aim.length() > STICK_DEADZONE:
		return _flattened(Vector3(stick_aim.x, 0.0, stick_aim.y), current_facing)
	if controller_authority:
		if move_direction.length_squared() > DIRECTION_EPSILON_SQUARED:
			return _flattened(move_direction, current_facing)
		return _flattened(current_facing, Vector3(0.0, 0.0, -1.0))
	if has_mouse_direction and mouse_direction.length_squared() > MOUSE_EPSILON_SQUARED:
		return _flattened(mouse_direction, current_facing)
	if move_direction.length_squared() > DIRECTION_EPSILON_SQUARED:
		return _flattened(move_direction, current_facing)
	return _flattened(current_facing, Vector3(0.0, 0.0, -1.0))


static func _flattened(direction: Vector3, fallback: Vector3) -> Vector3:
	var flattened := Vector3(direction.x, 0.0, direction.z)
	if flattened.length_squared() <= DIRECTION_EPSILON_SQUARED:
		flattened = Vector3(fallback.x, 0.0, fallback.z)
	if flattened.length_squared() <= DIRECTION_EPSILON_SQUARED:
		return Vector3(0.0, 0.0, -1.0)
	return flattened.normalized()
