extends RefCounted
class_name MartyrsChainRules

const TARGET_STANDARD := "standard"
const TARGET_BRUTE := "brute"
const TARGET_BOSS := "boss"
const MODE_PULL_TARGET := "pull_target"
const MODE_PULL_CASTER := "pull_caster"
const MAX_TARGET_RANGE := 10.0
const MIN_FORWARD_DOT := -0.18
const STANDARD_STOP_DISTANCE := 1.8
const ANCHOR_STOP_DISTANCE := 2.6


static func score_target(
	caster_position: Vector3,
	facing: Vector3,
	target_position: Vector3,
	has_rite_mark: bool
) -> float:
	var offset: Vector3 = target_position - caster_position
	offset.y = 0.0
	var distance := offset.length()
	if distance <= 0.05 or distance > MAX_TARGET_RANGE:
		return -1.0
	var flat_facing := facing
	flat_facing.y = 0.0
	if flat_facing.length_squared() <= 0.001:
		flat_facing = Vector3(0.0, 0.0, -1.0)
	var forward_dot := flat_facing.normalized().dot(offset / distance)
	if forward_dot < MIN_FORWARD_DOT:
		return -1.0
	var mark_bonus := 0.42 if has_rite_mark else 0.0
	return forward_dot * 2.1 + (1.0 - distance / MAX_TARGET_RANGE) + mark_bonus


static func resolve_mode(target_kind: String) -> String:
	return MODE_PULL_CASTER if target_kind in [TARGET_BRUTE, TARGET_BOSS] else MODE_PULL_TARGET


static func calculate_destination(
	caster_position: Vector3,
	target_position: Vector3,
	mode: String
) -> Vector3:
	var offset: Vector3 = target_position - caster_position
	offset.y = 0.0
	var direction := offset.normalized() if offset.length_squared() > 0.001 else Vector3(0.0, 0.0, -1.0)
	if mode == MODE_PULL_CASTER:
		var caster_destination := target_position - direction * ANCHOR_STOP_DISTANCE
		caster_destination.y = caster_position.y
		return caster_destination
	var target_destination := caster_position + direction * STANDARD_STOP_DISTANCE
	target_destination.y = target_position.y
	return target_destination


static func get_pull_duration(target_kind: String) -> float:
	return 0.24 if target_kind in [TARGET_BRUTE, TARGET_BOSS] else 0.30


static func get_impact_damage(target_kind: String, has_complete_rite: bool) -> int:
	var base_damage := 7 if target_kind == TARGET_STANDARD else 4
	return base_damage + (5 if has_complete_rite else 0)
