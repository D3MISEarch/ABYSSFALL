class_name VoidbringerImpactPresenter
extends RefCounted

signal impact_presented(report: Dictionary)
signal skill_presented(report: Dictionary)

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const HAPTICS_SCRIPT = preload("res://scripts/presentation/voidbringer_haptics.gd")
const HOLD_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_hold.gd")
const MASS_BRAND_ID: StringName = &"vb.skill.mass_brand"
const NULL_SHARD_ID: StringName = &"vb.skill.null_shard"

var settings: VoidbringerPresentationSettings
var haptics: VoidbringerHaptics
var last_impact_report: Dictionary = {}
var last_skill_report: Dictionary = {}
var impact_present_count := 0
var skill_present_count := 0

var _target_lookup := Callable()
var _controller_ref


func _init(
	presentation_settings: VoidbringerPresentationSettings = null,
	haptic_owner: VoidbringerHaptics = null,
	target_lookup: Callable = Callable()
) -> void:
	settings = presentation_settings
	if settings == null:
		settings = SETTINGS_SCRIPT.new()
	haptics = haptic_owner
	if haptics == null:
		haptics = HAPTICS_SCRIPT.new(settings)
	_target_lookup = target_lookup if target_lookup.is_valid() else Callable(self, "_lookup_instance")


func bind(controller: Object) -> bool:
	unbind()
	if controller == null:
		return false
	if not controller.has_signal("impact_committed") or not controller.has_signal("skill_committed"):
		return false
	_controller_ref = weakref(controller)
	controller.connect("impact_committed", Callable(self, "_on_impact_committed"))
	controller.connect("skill_committed", Callable(self, "_on_skill_committed"))
	return true


func unbind() -> void:
	var controller := _controller()
	if controller != null:
		var impact_callable := Callable(self, "_on_impact_committed")
		var skill_callable := Callable(self, "_on_skill_committed")
		if controller.is_connected("impact_committed", impact_callable):
			controller.disconnect("impact_committed", impact_callable)
		if controller.is_connected("skill_committed", skill_callable):
			controller.disconnect("skill_committed", skill_callable)
	_controller_ref = null


func consume_impact(result: Variant) -> Dictionary:
	var impact := _snapshot(result)
	if impact.is_empty():
		return {}
	var target_instance_id := int(impact.get("target_instance_id", 0))
	var target := _target_lookup.call(target_instance_id) as Object if target_instance_id > 0 else null
	var visual_requested := false
	var hold_requested := false
	var hold_seconds := 0.0
	if settings.effective_mode() != VoidbringerPresentationSettings.MODE_DISABLED:
		visual_requested = _present_target(target, impact)
		if visual_requested:
			hold_seconds = HOLD_SCRIPT.duration_for(
				settings.effective_mode(),
				bool(impact.get("critical", false)),
				bool(impact.get("fatal", false))
			)
			hold_requested = _apply_presentation_hold(target, hold_seconds)
	var haptic_requested := haptics.play_impact(impact)
	impact_present_count += 1
	last_impact_report = {
		"cast_id": impact.get("cast_id", &""),
		"ability_id": impact.get("ability_id", &""),
		"target_instance_id": target_instance_id,
		"damage": int(impact.get("damage", 0)),
		"damage_applied": float(impact.get("damage_applied", 0.0)),
		"critical": bool(impact.get("critical", false)),
		"fatal": bool(impact.get("fatal", false)),
		"fold_crossing_count": int(impact.get("fold_crossing_count", 0)),
		"entered_breach": bool(impact.get("entered_breach", false)),
		"mode": settings.effective_mode(),
		"visual_requested": visual_requested,
		"hold_requested": hold_requested,
		"hold_seconds": hold_seconds,
		"haptic_requested": haptic_requested,
		"impact": impact.duplicate(true),
	}
	impact_presented.emit(last_impact_report.duplicate(true))
	return last_impact_report.duplicate(true)


func consume_skill_commit(commit: Variant) -> Dictionary:
	var skill := _snapshot(commit)
	if skill.is_empty() or not bool(skill.get("success", false)):
		return {}
	var ability_id := StringName(str(skill.get("ability_id", "")))
	var entered_breach := bool(skill.get("entered_breach", false))
	var impact: Dictionary = (skill.get("impact", {}) as Dictionary).duplicate(true)
	var impact_will_own_haptics := (
		not impact.is_empty()
		and float(impact.get("damage_applied", 0.0)) > 0.0
	)
	var haptic_requested := false
	if not impact_will_own_haptics:
		if entered_breach:
			haptic_requested = haptics.play_breach(true)
		elif ability_id == MASS_BRAND_ID:
			haptic_requested = haptics.play_anchor_commit(false)
		elif ability_id == NULL_SHARD_ID:
			haptic_requested = false
	skill_present_count += 1
	last_skill_report = {
		"cast_id": skill.get("cast_id", &""),
		"ability_id": ability_id,
		"entered_breach": entered_breach,
		"impact_will_own_haptics": impact_will_own_haptics,
		"haptic_requested": haptic_requested,
		"mode": settings.effective_mode(),
		"skill": skill.duplicate(true),
	}
	skill_presented.emit(last_skill_report.duplicate(true))
	return last_skill_report.duplicate(true)


func clear() -> void:
	unbind()
	haptics.clear()
	last_impact_report.clear()
	last_skill_report.clear()
	impact_present_count = 0
	skill_present_count = 0


func debug_snapshot() -> Dictionary:
	return {
		"bound": _controller() != null,
		"impact_present_count": impact_present_count,
		"skill_present_count": skill_present_count,
		"last_impact_report": last_impact_report.duplicate(true),
		"last_skill_report": last_skill_report.duplicate(true),
		"settings": settings.snapshot(),
		"haptics": haptics.debug_snapshot(),
	}


func _on_impact_committed(result: Variant) -> void:
	consume_impact(result)


func _on_skill_committed(commit: Variant) -> void:
	consume_skill_commit(commit)


func _present_target(target: Object, impact: Dictionary) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.has_method("present_voidbringer_impact_result"):
		target.call(
			"present_voidbringer_impact_result",
			impact.duplicate(true),
			settings.snapshot()
		)
		return true
	if target.has_method("present_void_bolt_impact"):
		var primary_hit := settings.effective_mode() == VoidbringerPresentationSettings.MODE_FULL
		target.call(
			"present_void_bolt_impact",
			impact.get("travel_direction", Vector3.FORWARD),
			primary_hit,
			bool(impact.get("fatal", false))
		)
		return true
	return false


func _apply_presentation_hold(target: Object, duration: float) -> bool:
	if target == null or not is_instance_valid(target) or duration <= 0.0:
		return false
	if not _object_has_property(target, &"visual_root"):
		return false
	var visual_root := target.get("visual_root") as Node3D
	if not is_instance_valid(visual_root):
		return false
	var feedback := visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	if not is_instance_valid(feedback):
		return false
	return HOLD_SCRIPT.apply(feedback, duration) != null


func _snapshot(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value != null and value.has_method("snapshot"):
		return value.snapshot()
	return {}


func _controller() -> Object:
	if _controller_ref == null:
		return null
	return _controller_ref.get_ref() as Object


func _lookup_instance(instance_id: int) -> Object:
	if instance_id <= 0:
		return null
	return instance_from_id(instance_id)


func _object_has_property(object: Object, property_name: StringName) -> bool:
	if object == null:
		return false
	for property: Dictionary in object.get_property_list():
		if StringName(str(property.get("name", ""))) == property_name:
			return true
	return false
