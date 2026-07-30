extends SceneTree

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const HAPTICS_SCRIPT = preload("res://scripts/presentation/voidbringer_haptics.gd")
const PRESENTER_SCRIPT = preload("res://scripts/presentation/voidbringer_impact_presenter.gd")

class TargetFixture:
	extends Node3D
	var received_impacts: Array[Dictionary] = []
	var received_settings: Array[Dictionary] = []

	func present_voidbringer_impact_result(impact: Dictionary, settings: Dictionary) -> void:
		received_impacts.append(impact.duplicate(true))
		received_settings.append(settings.duplicate(true))
		impact["damage"] = 99999
		settings["mode"] = &"mutated"


class ControllerStub:
	extends RefCounted
	signal impact_committed(result: Variant)
	signal skill_committed(commit: Variant)


var failures: Array[String] = []
var targets: Dictionary = {}
var start_requests: Array[Dictionary] = []
var stop_requests: Array[int] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node3D.new()
	host.name = "ImmutableImpactPresenterTestHost"
	root.add_child(host)
	await process_frame
	_test_direct_immutable_impact(host)
	_test_skill_haptic_ownership()
	_test_bound_signal_path(host)
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer immutable impact presentation")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_direct_immutable_impact(host: Node3D) -> void:
	start_requests.clear()
	stop_requests.clear()
	targets.clear()
	var target := TargetFixture.new()
	target.name = "CommittedImpactTarget"
	host.add_child(target)
	targets[target.get_instance_id()] = target
	var settings := SETTINGS_SCRIPT.new() as VoidbringerPresentationSettings
	var haptics := HAPTICS_SCRIPT.new(
		settings,
		Callable(self, "_record_start"),
		Callable(self, "_record_stop")
	) as VoidbringerHaptics
	var presenter := PRESENTER_SCRIPT.new(
		settings,
		haptics,
		Callable(self, "_lookup_target")
	) as VoidbringerImpactPresenter
	var impact := VoidbringerImpactResult.new({
		"cast_id": &"vb.cast.presenter.0001",
		"ability_id": &"vb.skill.null_shard",
		"target_instance_id": target.get_instance_id(),
		"travel_direction": Vector3(0.0, 0.0, -1.0),
		"impact_point": Vector3(1.0, 0.5, -2.0),
		"surface_normal": Vector3.UP,
		"damage": 20,
		"damage_applied": 20.0,
		"critical": false,
		"fatal": false,
		"fold_crossing_count": 1,
		"entered_breach": false,
	})
	var report := presenter.consume_impact(impact)
	_expect(target.received_impacts.size() == 1, "Committed impact must reach the resolved target exactly once")
	_expect(start_requests.size() == 1, "Committed impact must request haptics exactly once")
	_expect(bool(report.get("visual_requested", false)), "Full mode must request target presentation")
	_expect(bool(report.get("haptic_requested", false)), "Full mode must request impact haptics")
	_expect(int(report.get("damage", 0)) == 20, "Presenter must preserve committed damage")
	_expect(int(report.get("fold_crossing_count", 0)) == 1, "Presenter must preserve committed Fold count")
	_expect(
		int((presenter.debug_snapshot().get("last_impact_report", {}) as Dictionary).get("damage", 0)) == 20,
		"Target-side mutation must not leak back into presenter state"
	)
	var report_impact := report.get("impact", {}) as Dictionary
	report_impact["damage"] = 777
	_expect(
		int((presenter.debug_snapshot().get("last_impact_report", {}) as Dictionary).get("damage", 0)) == 20,
		"Caller mutation of a returned report must not alter committed presenter state"
	)
	_expect(
		StringName(str(target.received_settings[0].get("mode", ""))) == &"full",
		"Target must receive the selected presentation mode snapshot"
	)

	settings.configure(&"disabled", true, true)
	var disabled_target := TargetFixture.new()
	disabled_target.name = "DisabledPresentationTarget"
	host.add_child(disabled_target)
	targets[disabled_target.get_instance_id()] = disabled_target
	var disabled_report := presenter.consume_impact({
		"cast_id": &"vb.cast.presenter.0002",
		"ability_id": &"vb.skill.null_shard",
		"target_instance_id": disabled_target.get_instance_id(),
		"damage": 18,
		"damage_applied": 18.0,
		"critical": false,
		"fatal": false,
		"fold_crossing_count": 0,
	})
	_expect(disabled_target.received_impacts.is_empty(), "Disabled mode must issue zero target presentation calls")
	_expect(start_requests.size() == 1, "Disabled mode must issue zero additional motor calls")
	_expect(not bool(disabled_report.get("visual_requested", true)), "Disabled report must expose suppressed visuals")
	_expect(not bool(disabled_report.get("haptic_requested", true)), "Disabled report must expose suppressed haptics")

	presenter.clear()
	_expect(stop_requests == [0], "Clearing an active presenter must stop haptics exactly once")
	targets.erase(target.get_instance_id())
	targets.erase(disabled_target.get_instance_id())
	target.queue_free()
	disabled_target.queue_free()


func _test_skill_haptic_ownership() -> void:
	start_requests.clear()
	stop_requests.clear()
	var settings := SETTINGS_SCRIPT.new() as VoidbringerPresentationSettings
	var haptics := HAPTICS_SCRIPT.new(
		settings,
		Callable(self, "_record_start"),
		Callable(self, "_record_stop")
	) as VoidbringerHaptics
	var presenter := PRESENTER_SCRIPT.new(settings, haptics, Callable(self, "_lookup_target")) as VoidbringerImpactPresenter

	var terrain_brand := VoidbringerSkillCommit.new({
		"success": true,
		"cast_id": &"vb.cast.brand.terrain",
		"ability_id": &"vb.skill.mass_brand",
		"entered_breach": false,
		"impact": {"damage_applied": 0.0},
	})
	var terrain_report := presenter.consume_skill_commit(terrain_brand)
	_expect(bool(terrain_report.get("haptic_requested", false)), "Terrain Mass Brand must request one anchor haptic")
	_expect(start_requests.size() == 1, "Terrain Mass Brand must make exactly one motor call")

	var damaging_brand := VoidbringerSkillCommit.new({
		"success": true,
		"cast_id": &"vb.cast.brand.enemy",
		"ability_id": &"vb.skill.mass_brand",
		"entered_breach": false,
		"impact": {"damage_applied": 8.0},
	})
	var damaging_report := presenter.consume_skill_commit(damaging_brand)
	_expect(
		bool(damaging_report.get("impact_will_own_haptics", false)),
		"Damaging Mass Brand must defer rumble to impact_committed"
	)
	_expect(not bool(damaging_report.get("haptic_requested", true)), "Damaging Mass Brand skill event must not double-rumble")
	_expect(start_requests.size() == 1, "Damaging skill commit must make zero duplicate motor calls")

	var shard_launch := VoidbringerSkillCommit.new({
		"success": true,
		"cast_id": &"vb.cast.shard.launch",
		"ability_id": &"vb.skill.null_shard",
		"entered_breach": false,
		"impact": {},
	})
	presenter.consume_skill_commit(shard_launch)
	_expect(start_requests.size() == 1, "Null Shard launch without Breach must not fake contact rumble")

	var breach_launch := VoidbringerSkillCommit.new({
		"success": true,
		"cast_id": &"vb.cast.shard.breach",
		"ability_id": &"vb.skill.null_shard",
		"entered_breach": true,
		"impact": {},
	})
	var breach_report := presenter.consume_skill_commit(breach_launch)
	_expect(bool(breach_report.get("haptic_requested", false)), "Threshold launch must request one combined Breach haptic")
	_expect(start_requests.size() == 2, "Threshold launch must add exactly one motor call")
	presenter.clear()


func _test_bound_signal_path(host: Node3D) -> void:
	start_requests.clear()
	stop_requests.clear()
	targets.clear()
	var target := TargetFixture.new()
	target.name = "SignalBoundTarget"
	host.add_child(target)
	targets[target.get_instance_id()] = target
	var settings := SETTINGS_SCRIPT.new() as VoidbringerPresentationSettings
	var haptics := HAPTICS_SCRIPT.new(
		settings,
		Callable(self, "_record_start"),
		Callable(self, "_record_stop")
	) as VoidbringerHaptics
	var presenter := PRESENTER_SCRIPT.new(settings, haptics, Callable(self, "_lookup_target")) as VoidbringerImpactPresenter
	var controller := ControllerStub.new()
	_expect(presenter.bind(controller), "Presenter must bind to the committed controller signals")
	controller.impact_committed.emit(VoidbringerImpactResult.new({
		"cast_id": &"vb.cast.bound.impact",
		"ability_id": &"vb.skill.mass_brand",
		"target_instance_id": target.get_instance_id(),
		"travel_direction": Vector3.FORWARD,
		"damage": 8,
		"damage_applied": 8.0,
		"critical": false,
		"fatal": false,
		"fold_crossing_count": 0,
	}))
	controller.skill_committed.emit(VoidbringerSkillCommit.new({
		"success": true,
		"cast_id": &"vb.cast.bound.impact",
		"ability_id": &"vb.skill.mass_brand",
		"entered_breach": false,
		"impact": {"damage_applied": 8.0},
	}))
	_expect(target.received_impacts.size() == 1, "Bound impact signal must forward the committed packet once")
	_expect(start_requests.size() == 1, "Bound impact and skill signals must produce one total motor call")
	_expect(presenter.impact_present_count == 1, "Presenter must count one bound impact")
	_expect(presenter.skill_present_count == 1, "Presenter must count one bound skill commit")
	presenter.unbind()
	controller.impact_committed.emit(VoidbringerImpactResult.new({
		"cast_id": &"vb.cast.after.unbind",
		"ability_id": &"vb.skill.mass_brand",
		"target_instance_id": target.get_instance_id(),
		"damage_applied": 8.0,
	}))
	_expect(target.received_impacts.size() == 1, "Unbound presenter must receive no later impacts")
	presenter.clear()
	targets.erase(target.get_instance_id())
	target.queue_free()


func _lookup_target(instance_id: int) -> Object:
	return targets.get(instance_id) as Object


func _record_start(
	device_id: int,
	weak_magnitude: float,
	strong_magnitude: float,
	duration: float
) -> void:
	start_requests.append({
		"device_id": device_id,
		"weak": weak_magnitude,
		"strong": strong_magnitude,
		"duration": duration,
	})


func _record_stop(device_id: int) -> void:
	stop_requests.append(device_id)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
