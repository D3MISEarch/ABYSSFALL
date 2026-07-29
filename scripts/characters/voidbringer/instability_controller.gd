class_name VoidbringerInstabilityController
extends RefCounted

signal instability_changed(current: float, maximum: float)
signal breach_started(duration_seconds: float)
signal breach_ended

const MAXIMUM := 100.0
const DECAY_DELAY_SECONDS := 4.0
const DECAY_PER_SECOND := 5.0
const BREACH_DURATION_SECONDS := 8.0
const BREACH_ANCHOR_INFLUENCE_MULTIPLIER := 1.30

var current: float = 0.0
var seconds_since_spatial_commit: float = 0.0
var in_breach := false
var breach_remaining: float = 0.0


func commit_spatial_ability(instability_delta: float) -> float:
	seconds_since_spatial_commit = 0.0
	if in_breach:
		return 0.0
	var before := current
	current = clampf(current + maxf(instability_delta, 0.0), 0.0, MAXIMUM)
	var applied := current - before
	if applied > 0.0:
		instability_changed.emit(current, MAXIMUM)
	if current >= MAXIMUM:
		_enter_breach()
	return applied


func tick(delta: float) -> void:
	var step := maxf(delta, 0.0)
	if step <= 0.0:
		return
	if in_breach:
		breach_remaining = maxf(breach_remaining - step, 0.0)
		current = MAXIMUM * (breach_remaining / BREACH_DURATION_SECONDS)
		instability_changed.emit(current, MAXIMUM)
		if breach_remaining <= 0.0:
			current = 0.0
			in_breach = false
			seconds_since_spatial_commit = 0.0
			breach_ended.emit()
		return

	seconds_since_spatial_commit += step
	if seconds_since_spatial_commit <= DECAY_DELAY_SECONDS or current <= 0.0:
		return
	var before := current
	current = maxf(0.0, current - DECAY_PER_SECOND * step)
	if not is_equal_approx(before, current):
		instability_changed.emit(current, MAXIMUM)


func anchor_influence_multiplier() -> float:
	return BREACH_ANCHOR_INFLUENCE_MULTIPLIER if in_breach else 1.0


func snapshot() -> Dictionary:
	return {
		"current": current,
		"maximum": MAXIMUM,
		"seconds_since_spatial_commit": seconds_since_spatial_commit,
		"in_breach": in_breach,
		"breach_remaining": breach_remaining,
		"anchor_influence_multiplier": anchor_influence_multiplier(),
	}


func clear() -> void:
	current = 0.0
	seconds_since_spatial_commit = 0.0
	in_breach = false
	breach_remaining = 0.0
	instability_changed.emit(current, MAXIMUM)


func _enter_breach() -> void:
	if in_breach:
		return
	current = MAXIMUM
	in_breach = true
	breach_remaining = BREACH_DURATION_SECONDS
	breach_started.emit(BREACH_DURATION_SECONDS)
	instability_changed.emit(current, MAXIMUM)
