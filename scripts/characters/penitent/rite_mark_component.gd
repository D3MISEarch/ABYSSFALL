extends Node
class_name RiteMarkComponent

signal state_changed(previous_state: int, current_state: int)
signal brand_changed(active: bool)
signal duration_changed(remaining_seconds: float, total_seconds: float)
signal completed
signal expired

const STATE_NONE := 0
const STATE_PARTIAL_ONE := 1
const STATE_PARTIAL_TWO := 2
const STATE_COMPLETE := 3

var current_state := STATE_NONE
var base_duration := 6.0
var complete_duration := 8.0
var remaining_duration := 0.0
var total_duration := 0.0

var branded := false
var brand_remaining := 0.0
var brand_duration := 0.0
var boss_safe := false


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	advance_time(delta)


func configure(
	new_base_duration: float = 6.0,
	new_complete_duration: float = 8.0,
	is_boss: bool = false
) -> void:
	base_duration = maxf(new_base_duration, 0.1)
	complete_duration = maxf(new_complete_duration, base_duration)
	boss_safe = is_boss


func apply_partial(stacks: int = 1, duration_bonus: float = 0.0) -> int:
	if stacks <= 0:
		return current_state
	var previous_state := current_state
	current_state = mini(current_state + stacks, STATE_COMPLETE)
	_refresh_duration(duration_bonus)
	_emit_state_transition(previous_state)
	return current_state


func complete_rite(duration_bonus: float = 0.0) -> bool:
	var was_complete := current_state == STATE_COMPLETE
	var previous_state := current_state
	current_state = STATE_COMPLETE
	_refresh_duration(duration_bonus)
	_emit_state_transition(previous_state)
	return not was_complete


func consume_rite() -> bool:
	if current_state != STATE_COMPLETE:
		return false
	clear_mark()
	return true


func apply_brand(duration: float = 10.0) -> void:
	var safe_duration := maxf(duration, 0.1)
	var was_branded := branded
	branded = true
	brand_duration = safe_duration
	brand_remaining = safe_duration
	if not was_branded:
		brand_changed.emit(true)


func remove_brand() -> void:
	if not branded:
		return
	branded = false
	brand_remaining = 0.0
	brand_duration = 0.0
	brand_changed.emit(false)


func clear_mark() -> void:
	var previous_state := current_state
	current_state = STATE_NONE
	remaining_duration = 0.0
	total_duration = 0.0
	if previous_state != STATE_NONE:
		state_changed.emit(previous_state, STATE_NONE)
		duration_changed.emit(0.0, 0.0)


func extend_duration(seconds: float) -> void:
	if current_state == STATE_NONE or seconds <= 0.0:
		return
	remaining_duration += seconds
	total_duration += seconds
	duration_changed.emit(remaining_duration, total_duration)


func advance_time(delta: float) -> void:
	if delta <= 0.0:
		return

	if current_state != STATE_NONE:
		remaining_duration = maxf(remaining_duration - delta, 0.0)
		duration_changed.emit(remaining_duration, total_duration)
		if remaining_duration <= 0.0:
			clear_mark()
			expired.emit()

	if branded:
		brand_remaining = maxf(brand_remaining - delta, 0.0)
		if brand_remaining <= 0.0:
			remove_brand()


func get_snapshot() -> Dictionary:
	return {
		"state": current_state,
		"state_name": get_state_name(),
		"remaining_duration": remaining_duration,
		"total_duration": total_duration,
		"normalized_duration": (
			remaining_duration / maxf(total_duration, 0.001)
			if current_state != STATE_NONE
			else 0.0
		),
		"branded": branded,
		"brand_remaining": brand_remaining,
		"brand_duration": brand_duration,
		"boss_safe": boss_safe,
	}


func get_state_name() -> String:
	match current_state:
		STATE_PARTIAL_ONE:
			return "partial_one"
		STATE_PARTIAL_TWO:
			return "partial_two"
		STATE_COMPLETE:
			return "complete"
		_:
			return "none"


func is_complete() -> bool:
	return current_state == STATE_COMPLETE


func _refresh_duration(duration_bonus: float) -> void:
	var duration := complete_duration if current_state == STATE_COMPLETE else base_duration
	duration += maxf(duration_bonus, 0.0)
	remaining_duration = duration
	total_duration = duration
	duration_changed.emit(remaining_duration, total_duration)


func _emit_state_transition(previous_state: int) -> void:
	if previous_state == current_state:
		return
	state_changed.emit(previous_state, current_state)
	if current_state == STATE_COMPLETE:
		completed.emit()
