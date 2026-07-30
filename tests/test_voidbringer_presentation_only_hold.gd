extends SceneTree

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const HAPTICS_SCRIPT = preload("res://scripts/presentation/voidbringer_haptics.gd")
const PRESENTER_SCRIPT = preload("res://scripts/presentation/voidbringer_impact_presenter.gd")
const HOLD_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_hold.gd")
const TARGET_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_sandbox_target.gd")

class GameplayClock:
	extends Node
	var ticks := 0
	var elapsed := 0.0

	func _process(delta: float) -> void:
		ticks += 1
		elapsed += delta


var failures: Array[String] = []
var targets: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node3D.new()
	host.name = "PresentationOnlyHoldTestHost"
	root.add_child(host)
	await process_frame
	_test_duration_contract()
	await _test_feedback_only_hold(host)
	await _test_presenter_integration(host)
	_test_global_time_authority_guard()
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer presentation-only impact hold")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_duration_contract() -> void:
	_expect(is_equal_approx(HOLD_SCRIPT.duration_for(&"full", false, false), 0.035), "Full normal impact hold must be 35 ms")
	_expect(is_equal_approx(HOLD_SCRIPT.duration_for(&"full", true, false), 0.050), "Full critical impact hold must be 50 ms")
	_expect(is_equal_approx(HOLD_SCRIPT.duration_for(&"full", true, true), 0.065), "Full fatal impact hold must be 65 ms")
	_expect(is_equal_approx(HOLD_SCRIPT.duration_for(&"reduced", false, false), 0.0175), "Reduced normal hold must be half of full")
	_expect(is_equal_approx(HOLD_SCRIPT.duration_for(&"reduced", true, true), 0.0325), "Reduced fatal hold must be half of full")
	_expect(is_zero_approx(HOLD_SCRIPT.duration_for(&"disabled", true, true)), "Disabled presentation must request zero hold")


func _test_feedback_only_hold(host: Node3D) -> void:
	var clock := GameplayClock.new()
	clock.name = "AuthoritativeGameplayClock"
	host.add_child(clock)
	var visual_root := Node3D.new()
	visual_root.name = "HeldVisualRoot"
	host.add_child(visual_root)
	var base_scale := visual_root.scale
	var feedback := ImpactFeedback.play_contact(visual_root, Vector3.FORWARD, &"light", true, false)
	var hold: Variant = HOLD_SCRIPT.apply(feedback, 0.050)
	_expect(hold != null, "Valid impact feedback must accept a presentation-only hold")
	_expect(not feedback.is_processing(), "Presentation hold must pause only ImpactFeedback processing")
	_expect(visual_root.scale != base_scale, "Presentation hold must freeze an already deformed contact pose")
	_expect(_count_nodes_named(feedback, "VoidbringerPresentationHold") == 1, "Impact feedback may own only one hold node")
	var extended: Variant = HOLD_SCRIPT.apply(feedback, 0.065)
	_expect(extended == hold, "Repeated hold requests must extend one owner rather than add timers")
	_expect(is_equal_approx(float(hold.debug_snapshot().get("requested_seconds", 0.0)), 0.065), "Hold extension must preserve the longest requested duration")
	var ticks_before := clock.ticks
	var elapsed_before := clock.elapsed
	await process_frame
	_expect(clock.ticks > ticks_before and clock.elapsed >= elapsed_before, "Gameplay processing must continue while presentation feedback is held")
	hold._process(1.0)
	await process_frame
	_expect(feedback.is_processing(), "Expired hold must resume ImpactFeedback processing")
	_expect(_count_nodes_named(feedback, "VoidbringerPresentationHold") == 0, "Expired hold must leave no stale hold node")
	feedback._process(1.0)
	await process_frame
	_expect(visual_root.scale == base_scale, "Resumed feedback must complete and restore the base pose")
	clock.queue_free()
	visual_root.queue_free()
	await process_frame


func _test_presenter_integration(host: Node3D) -> void:
	targets.clear()
	var target := TARGET_SCRIPT.new() as VoidbringerSandboxTarget
	target.name = "PresenterHoldTarget"
	host.add_child(target)
	var alive_material := StandardMaterial3D.new()
	var dead_material := StandardMaterial3D.new()
	target.configure_visuals(alive_material, dead_material)
	targets[target.get_instance_id()] = target
	var settings := SETTINGS_SCRIPT.new() as VoidbringerPresentationSettings
	var haptics := HAPTICS_SCRIPT.new(settings, Callable(self, "_ignore_start"), Callable(self, "_ignore_stop")) as VoidbringerHaptics
	var presenter := PRESENTER_SCRIPT.new(settings, haptics, Callable(self, "_lookup_target")) as VoidbringerImpactPresenter
	var impact := VoidbringerImpactResult.new({
		"cast_id": &"vb.cast.hold.0001",
		"ability_id": &"vb.skill.null_shard",
		"target_instance_id": target.get_instance_id(),
		"travel_direction": Vector3.FORWARD,
		"damage": 20,
		"damage_applied": 20.0,
		"critical": false,
		"fatal": false,
		"fold_crossing_count": 1,
	})
	var full_report := presenter.consume_impact(impact)
	_expect(bool(full_report.get("hold_requested", false)), "Full committed impact must request a presentation-only hold")
	_expect(is_equal_approx(float(full_report.get("hold_seconds", 0.0)), 0.035), "Presenter must report the exact full hold duration")
	var feedback := target.visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	_expect(feedback != null and not feedback.is_processing(), "Presenter must hold the target feedback owner, not gameplay")
	var hold := feedback.get_node_or_null("VoidbringerPresentationHold") as VoidbringerPresentationHold
	if hold != null:
		hold.release()
	if feedback != null:
		feedback._process(1.0)
	await process_frame

	settings.configure(&"reduced", true, true)
	var reduced_report := presenter.consume_impact(impact)
	_expect(bool(reduced_report.get("hold_requested", false)), "Reduced committed impact must retain a shorter presentation hold")
	_expect(is_equal_approx(float(reduced_report.get("hold_seconds", 0.0)), 0.0175), "Presenter must report the exact reduced hold duration")
	feedback = target.visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	hold = feedback.get_node_or_null("VoidbringerPresentationHold") as VoidbringerPresentationHold if feedback != null else null
	if hold != null:
		hold.release()
	if feedback != null:
		feedback._process(1.0)
	await process_frame

	settings.configure(&"disabled", true, true)
	var disabled_report := presenter.consume_impact(impact)
	_expect(not bool(disabled_report.get("hold_requested", true)), "Disabled presentation must request zero hold")
	_expect(is_zero_approx(float(disabled_report.get("hold_seconds", -1.0))), "Disabled presenter report must expose zero hold duration")
	_expect(target.visual_root.get_node_or_null("VoidbringerPresentationHold") == null, "Disabled presentation must create no hold nodes")
	presenter.clear()
	targets.erase(target.get_instance_id())
	target.queue_free()
	await process_frame


func _test_global_time_authority_guard() -> void:
	var hold_source := FileAccess.get_file_as_string("res://scripts/presentation/voidbringer_presentation_hold.gd")
	var presenter_source := FileAccess.get_file_as_string("res://scripts/presentation/voidbringer_impact_presenter.gd")
	var combined := hold_source + "\n" + presenter_source
	for forbidden in ["Engine.time_scale", "get_tree().paused", "SceneTree.paused", "physics_ticks_per_second"]:
		_expect(not combined.contains(forbidden), "Presentation-only hold must never touch gameplay time authority: %s" % forbidden)
	_expect(
		hold_source.contains("feedback.set_process(false)") and hold_source.contains("feedback.set_process(true)"),
		"Hold implementation must pause and resume only the ImpactFeedback owner"
	)


func _lookup_target(instance_id: int) -> Object:
	return targets.get(instance_id) as Object


func _ignore_start(
	_device_id: int,
	_weak_magnitude: float,
	_strong_magnitude: float,
	_duration: float
) -> void:
	pass


func _ignore_stop(_device_id: int) -> void:
	pass


func _count_nodes_named(root_node: Node, node_name: String) -> int:
	var count := 1 if root_node.name == node_name else 0
	for child: Node in root_node.get_children():
		count += _count_nodes_named(child, node_name)
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
