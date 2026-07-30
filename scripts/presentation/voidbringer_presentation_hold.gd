class_name VoidbringerPresentationHold
extends Node

const NODE_NAME := "VoidbringerPresentationHold"
const MODE_REDUCED: StringName = &"reduced"
const MODE_DISABLED: StringName = &"disabled"

var remaining_seconds := 0.0
var requested_seconds := 0.0
var _feedback_ref
var _released := false


static func duration_for(
	mode: StringName,
	critical: bool,
	fatal: bool
) -> float:
	if mode == MODE_DISABLED:
		return 0.0
	var duration := 0.035
	if fatal:
		duration = 0.065
	elif critical:
		duration = 0.050
	if mode == MODE_REDUCED:
		duration *= 0.50
	return duration


static func apply(feedback: Node, duration: float):
	if not is_instance_valid(feedback) or duration <= 0.0:
		return null
	var existing := feedback.get_node_or_null(NODE_NAME)
	if is_instance_valid(existing) and existing.has_method("extend"):
		existing.call("extend", duration)
		return existing
	var hold := VoidbringerPresentationHold.new()
	hold.name = NODE_NAME
	hold.process_mode = Node.PROCESS_MODE_ALWAYS
	feedback.add_child(hold)
	hold._configure(feedback, duration)
	return hold


func extend(duration: float) -> void:
	if _released:
		return
	var bounded := clampf(duration, 0.0, 0.10)
	requested_seconds = maxf(requested_seconds, bounded)
	remaining_seconds = maxf(remaining_seconds, bounded)


func release() -> void:
	if _released:
		return
	_released = true
	var feedback := _feedback()
	if is_instance_valid(feedback):
		feedback.set_process(true)
	queue_free()


func debug_snapshot() -> Dictionary:
	return {
		"remaining_seconds": remaining_seconds,
		"requested_seconds": requested_seconds,
		"released": _released,
		"feedback_valid": is_instance_valid(_feedback()),
	}


func _configure(feedback: Node, duration: float) -> void:
	_feedback_ref = weakref(feedback)
	var bounded := clampf(duration, 0.0, 0.10)
	requested_seconds = bounded
	remaining_seconds = bounded
	if feedback.has_method("_process"):
		feedback.call("_process", minf(0.018, bounded))
	feedback.set_process(false)
	set_process(true)


func _process(delta: float) -> void:
	if _released:
		return
	var feedback := _feedback()
	if not is_instance_valid(feedback):
		_released = true
		queue_free()
		return
	remaining_seconds = maxf(remaining_seconds - maxf(delta, 0.0), 0.0)
	if remaining_seconds <= 0.0:
		release()


func _exit_tree() -> void:
	if _released:
		return
	var feedback := _feedback()
	if is_instance_valid(feedback):
		feedback.set_process(true)


func _feedback() -> Node:
	if _feedback_ref == null:
		return null
	return _feedback_ref.get_ref() as Node
