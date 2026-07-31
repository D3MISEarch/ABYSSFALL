class_name IntegratedCameraDirector
extends Node

## Presentation-only camera owner for the live Voidbringer-to-Hollow-King route.
## It consumes stable encounter facts and safe actor transforms; it never owns gameplay state.

const STATE_DEFAULT_GAMEPLAY: StringName = &"default_gameplay"
const STATE_SWARM_COMBAT: StringName = &"swarm_combat"
const STATE_BOSS_REVEAL: StringName = &"boss_reveal"

## Default gameplay is intentionally lower and closer than the legacy 17.8 / 16.2 frame.
const DEFAULT_CAMERA_HEIGHT := 15.4
const DEFAULT_CAMERA_DISTANCE := 13.8
const DEFAULT_LOOK_HEIGHT := 0.55
const DEFAULT_FOV := 50.0
const DEFAULT_TRANSITION_SECONDS := 0.34

## Swarm pressure uses the existing encounter count with explicit hysteresis.
const SWARM_CAMERA_HEIGHT := 20.6
const SWARM_CAMERA_DISTANCE := 21.0
const SWARM_FOV := 53.0
const SWARM_TRANSITION_SECONDS := 0.62
const SWARM_ENTER_ENEMY_COUNT := 5
const SWARM_EXIT_ENEMY_COUNT := 2
const SWARM_EXIT_HOLD_SECONDS := 1.20

## One authored, temporary Hollow King introduction.
const BOSS_REVEAL_CAMERA_HEIGHT := 9.2
const BOSS_REVEAL_CAMERA_DISTANCE := 19.5
const BOSS_REVEAL_LOOK_HEIGHT := 1.25
const BOSS_REVEAL_FOV := 42.0
const BOSS_REVEAL_APPROACH_SECONDS := 0.58
const BOSS_REVEAL_HOLD_SECONDS := 0.78
const BOSS_REVEAL_RETURN_SECONDS := 0.58

const SWARM_ENCOUNTER_STATES: Array[StringName] = [
	&"courtyard",
	&"generator_room",
	&"catacombs_wave_1",
	&"catacombs_wave_2",
	&"trap_hall",
]

var state: StringName = STATE_DEFAULT_GAMEPLAY
var _camera: Camera3D
var _swarm_exit_elapsed := 0.0
var _reveal_consumed := false
var _reveal_active := false
var _reveal_elapsed := 0.0
var _reveal_player: Node3D
var _reveal_boss: Node3D
var _pre_reveal_transform := Transform3D.IDENTITY
var _pre_reveal_fov := DEFAULT_FOV
var _pre_reveal_state: StringName = STATE_DEFAULT_GAMEPLAY
var _has_reveal_snapshot := false


func configure(presentation_camera: Camera3D) -> void:
	restore_immediately()
	_camera = presentation_camera
	if is_instance_valid(_camera):
		_pre_reveal_fov = _camera.fov


func update(
	delta: float,
	player: Node3D,
	enemy_count: int,
	encounter_state: String,
	boss: Node3D
) -> void:
	if not is_instance_valid(_camera):
		return
	if not _is_living_actor(player):
		restore_immediately()
		return
	if _reveal_active:
		if not _is_living_actor(_reveal_boss) or boss != _reveal_boss:
			restore_immediately()
			return
		_tick_boss_reveal(maxf(delta, 0.0))
		return
	_update_swarm_state(maxf(delta, 0.0), enemy_count, StringName(encounter_state))
	_apply_gameplay_pose(player, maxf(delta, 0.0))


func request_hollow_king_reveal(player: Node3D, boss: Node3D) -> bool:
	if (
		_reveal_consumed
		or not is_instance_valid(_camera)
		or not _is_living_actor(player)
		or not _is_living_actor(boss)
	):
		return false
	_reveal_consumed = true
	_reveal_active = true
	_reveal_elapsed = 0.0
	_reveal_player = player
	_reveal_boss = boss
	_pre_reveal_transform = _camera.global_transform
	_pre_reveal_fov = _camera.fov
	_pre_reveal_state = state
	_has_reveal_snapshot = true
	state = STATE_BOSS_REVEAL
	return true


func restore_immediately() -> void:
	if _has_reveal_snapshot and is_instance_valid(_camera) and _camera.is_inside_tree():
		_camera.global_transform = _pre_reveal_transform
		_camera.fov = _pre_reveal_fov
	_reveal_active = false
	_reveal_elapsed = 0.0
	_reveal_player = null
	_reveal_boss = null
	_has_reveal_snapshot = false
	state = _pre_reveal_state if _pre_reveal_state in [STATE_DEFAULT_GAMEPLAY, STATE_SWARM_COMBAT] else STATE_DEFAULT_GAMEPLAY
	_swarm_exit_elapsed = 0.0


func reset_for_replay() -> void:
	restore_immediately()
	_reveal_consumed = false
	_pre_reveal_state = STATE_DEFAULT_GAMEPLAY
	state = STATE_DEFAULT_GAMEPLAY


func snapshot() -> Dictionary:
	return {
		"state": state,
		"reveal_consumed": _reveal_consumed,
		"reveal_active": _reveal_active,
		"swarm_exit_elapsed": _swarm_exit_elapsed,
		"camera_position": _camera.global_position if is_instance_valid(_camera) else Vector3.ZERO,
		"camera_fov": _camera.fov if is_instance_valid(_camera) else 0.0,
		"tuning": {
			"default_height": DEFAULT_CAMERA_HEIGHT,
			"default_distance": DEFAULT_CAMERA_DISTANCE,
			"default_transition": DEFAULT_TRANSITION_SECONDS,
			"swarm_height": SWARM_CAMERA_HEIGHT,
			"swarm_distance": SWARM_CAMERA_DISTANCE,
			"swarm_transition": SWARM_TRANSITION_SECONDS,
			"swarm_enter_count": SWARM_ENTER_ENEMY_COUNT,
			"swarm_exit_count": SWARM_EXIT_ENEMY_COUNT,
			"swarm_exit_hold": SWARM_EXIT_HOLD_SECONDS,
		},
	}


func _exit_tree() -> void:
	restore_immediately()


func _update_swarm_state(delta: float, enemy_count: int, encounter_state: StringName) -> void:
	var swarm_eligible := encounter_state in SWARM_ENCOUNTER_STATES
	if state == STATE_DEFAULT_GAMEPLAY:
		if swarm_eligible and enemy_count >= SWARM_ENTER_ENEMY_COUNT:
			state = STATE_SWARM_COMBAT
			_swarm_exit_elapsed = 0.0
		return
	if state != STATE_SWARM_COMBAT:
		return
	if not swarm_eligible or enemy_count <= SWARM_EXIT_ENEMY_COUNT:
		_swarm_exit_elapsed += delta
		if _swarm_exit_elapsed >= SWARM_EXIT_HOLD_SECONDS:
			state = STATE_DEFAULT_GAMEPLAY
			_swarm_exit_elapsed = 0.0
	else:
		_swarm_exit_elapsed = 0.0


func _apply_gameplay_pose(player: Node3D, delta: float) -> void:
	var is_swarm := state == STATE_SWARM_COMBAT
	var height := SWARM_CAMERA_HEIGHT if is_swarm else DEFAULT_CAMERA_HEIGHT
	var distance := SWARM_CAMERA_DISTANCE if is_swarm else DEFAULT_CAMERA_DISTANCE
	var fov := SWARM_FOV if is_swarm else DEFAULT_FOV
	var duration := SWARM_TRANSITION_SECONDS if is_swarm else DEFAULT_TRANSITION_SECONDS
	var pose := {
		"position": player.global_position + Vector3(0.0, height, distance),
		"target": player.global_position + Vector3(0.0, DEFAULT_LOOK_HEIGHT, 0.0),
		"fov": fov,
	}
	_apply_pose(pose, _transition_alpha(delta, duration))


func _tick_boss_reveal(delta: float) -> void:
	_reveal_elapsed += delta
	var approach_end := BOSS_REVEAL_APPROACH_SECONDS
	var hold_end := approach_end + BOSS_REVEAL_HOLD_SECONDS
	var return_end := hold_end + BOSS_REVEAL_RETURN_SECONDS
	if _reveal_elapsed <= approach_end:
		_apply_pose(_boss_reveal_pose(), clampf(_reveal_elapsed / approach_end, 0.0, 1.0))
		return
	if _reveal_elapsed <= hold_end:
		_apply_pose(_boss_reveal_pose(), 1.0)
		return
	if _reveal_elapsed < return_end:
		var progress := clampf((_reveal_elapsed - hold_end) / BOSS_REVEAL_RETURN_SECONDS, 0.0, 1.0)
		_camera.global_transform = _camera.global_transform.interpolate_with(_pre_reveal_transform, progress)
		_camera.fov = lerpf(_camera.fov, _pre_reveal_fov, progress)
		return
	restore_immediately()


func _boss_reveal_pose() -> Dictionary:
	var player_position := _reveal_player.global_position
	var boss_position := _reveal_boss.global_position
	var player_to_boss := boss_position - player_position
	player_to_boss.y = 0.0
	var retreat_direction := -player_to_boss.normalized() if player_to_boss.length_squared() > 0.001 else Vector3.BACK
	var focus := player_position.lerp(boss_position, 0.58) + Vector3(0.0, BOSS_REVEAL_LOOK_HEIGHT, 0.0)
	return {
		"position": player_position + retreat_direction * BOSS_REVEAL_CAMERA_DISTANCE + Vector3(0.0, BOSS_REVEAL_CAMERA_HEIGHT, 0.0),
		"target": focus,
		"fov": BOSS_REVEAL_FOV,
	}


func _apply_pose(pose: Dictionary, alpha: float) -> void:
	if not is_instance_valid(_camera):
		return
	var target_position: Vector3 = pose.get("position", _camera.global_position)
	var target_focus: Vector3 = pose.get("target", Vector3.ZERO)
	var target_fov := float(pose.get("fov", _camera.fov))
	_camera.global_position = _camera.global_position.lerp(target_position, clampf(alpha, 0.0, 1.0))
	_camera.look_at(target_focus, Vector3.UP)
	_camera.fov = lerpf(_camera.fov, target_fov, clampf(alpha, 0.0, 1.0))


func _transition_alpha(delta: float, duration: float) -> float:
	return clampf(delta / maxf(duration, 0.001), 0.0, 1.0)


func _is_living_actor(actor: Node3D) -> bool:
	return is_instance_valid(actor) and (actor.get("alive") == null or bool(actor.get("alive")))
