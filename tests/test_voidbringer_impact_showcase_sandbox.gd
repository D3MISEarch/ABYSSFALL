extends SceneTree

const SHOWCASE_SCENE = preload("res://scenes/voidbringer_impact_showcase_sandbox.tscn")
const HAPTICS_SCRIPT = preload("res://scripts/presentation/voidbringer_haptics.gd")

var failures: Array[String] = []
var start_requests: Array[Dictionary] = []
var stop_requests: Array[int] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var showcase := SHOWCASE_SCENE.instantiate() as VoidbringerImpactShowcaseSandbox
	root.add_child(showcase)
	await process_frame
	_install_test_haptics(showcase)

	var full := _run_combo(showcase, &"full")
	var reduced := _run_combo(showcase, &"reduced")
	var disabled := _run_combo(showcase, &"disabled")
	_test_gameplay_equivalence(full, reduced, disabled)
	_test_mode_specific_presentation(full, reduced, disabled)
	_test_lethal_fracture_and_reset(showcase)

	showcase.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer savage impact showcase sandbox")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _install_test_haptics(showcase: VoidbringerImpactShowcaseSandbox) -> void:
	start_requests.clear()
	stop_requests.clear()
	var test_haptics := HAPTICS_SCRIPT.new(
		showcase.presentation_settings,
		Callable(self, "_record_start"),
		Callable(self, "_record_stop")
	) as VoidbringerHaptics
	showcase.haptics = test_haptics
	showcase.impact_presenter.haptics = test_haptics


func _run_combo(
	showcase: VoidbringerImpactShowcaseSandbox,
	mode: StringName
) -> Dictionary:
	start_requests.clear()
	stop_requests.clear()
	showcase.simulate_showcase_command(StringName("mode_%s" % String(mode)))
	showcase.simulate_command(&"clear")
	showcase.simulate_command(&"mass_brand_terrain")
	showcase.simulate_command(&"mass_brand_corpse")
	showcase.simulate_command(&"fire_null_shard")
	var elapsed := 0.0
	while elapsed < 1.5 and showcase.enemy_fixture.health == showcase.enemy_fixture.maximum_health:
		showcase.simulate_seconds(0.02, 0.02)
		elapsed += 0.02
	var snapshot := showcase.debug_showcase_snapshot()
	snapshot["test_start_calls"] = start_requests.size()
	snapshot["test_stop_calls"] = stop_requests.size()
	snapshot["gameplay_signature"] = _gameplay_signature(snapshot)
	return snapshot


func _gameplay_signature(snapshot: Dictionary) -> Dictionary:
	var foundation := snapshot.get("foundation", {}) as Dictionary
	var anchors: Array = foundation.get("anchors", []) as Array
	var carrier_types: Array[String] = []
	var masses: Array[int] = []
	for raw_anchor: Variant in anchors:
		var anchor := raw_anchor as Dictionary
		carrier_types.append(String(anchor.get("carrier_type", &"")))
		masses.append(int(round(float(anchor.get("mass", 0.0)))))
	carrier_types.sort()
	masses.sort()
	var instability := foundation.get("instability", {}) as Dictionary
	var enemy := foundation.get("enemy", {}) as Dictionary
	var impact := foundation.get("last_impact", {}) as Dictionary
	return {
		"enemy_health": int(enemy.get("health", -1)),
		"enemy_alive": bool(enemy.get("alive", false)),
		"enemy_hit_calls": int(enemy.get("hit_calls", -1)),
		"anchor_count": anchors.size(),
		"carrier_types": carrier_types,
		"masses": masses,
		"fold_line_count": (foundation.get("fold_lines", []) as Array).size(),
		"instability": snappedf(float(instability.get("current", -1.0)), 0.001),
		"impact_damage": int(impact.get("damage", -1)),
		"impact_fold_crossings": int(impact.get("fold_crossing_count", -1)),
		"impact_critical": bool(impact.get("critical", true)),
		"projectiles": int(foundation.get("projectile_visual_count", -1)),
	}


func _test_gameplay_equivalence(
	full: Dictionary,
	reduced: Dictionary,
	disabled: Dictionary
) -> void:
	var full_signature := full.get("gameplay_signature", {}) as Dictionary
	var reduced_signature := reduced.get("gameplay_signature", {}) as Dictionary
	var disabled_signature := disabled.get("gameplay_signature", {}) as Dictionary
	_expect(full_signature == reduced_signature, "Reduced presentation must not alter combo gameplay results")
	_expect(full_signature == disabled_signature, "Disabled presentation must not alter combo gameplay results")
	_expect(int(full_signature.get("enemy_health", -1)) == 80, "Fold-enhanced showcase combo must deal the committed 20 damage")
	_expect(int(full_signature.get("enemy_hit_calls", -1)) == 1, "Showcase combo must resolve target damage exactly once")
	_expect(int(full_signature.get("anchor_count", -1)) == 2, "Showcase combo must retain two committed Anchors")
	_expect(int(full_signature.get("fold_line_count", -1)) == 1, "Two showcase Anchors must expose one Fold Line")
	_expect(full_signature.get("masses", []) == [7, 22], "Fold crossing must add +2 Mass to both endpoint Anchors")
	_expect(is_equal_approx(float(full_signature.get("instability", -1.0)), 14.0), "Two Brands and one Shard must commit 14 Instability")
	_expect(int(full_signature.get("impact_damage", -1)) == 20, "Showcase must preserve committed Fold-enhanced impact damage")
	_expect(int(full_signature.get("impact_fold_crossings", -1)) == 1, "Showcase must preserve one committed Fold crossing")
	_expect(int(full_signature.get("projectiles", -1)) == 0, "Committed showcase contact must leave no active projectile visual")


func _test_mode_specific_presentation(
	full: Dictionary,
	reduced: Dictionary,
	disabled: Dictionary
) -> void:
	var full_settings := full.get("presentation", {}) as Dictionary
	var reduced_settings := reduced.get("presentation", {}) as Dictionary
	var disabled_settings := disabled.get("presentation", {}) as Dictionary
	_expect(StringName(str(full_settings.get("effective_mode", ""))) == &"full", "Full run must report full presentation mode")
	_expect(StringName(str(reduced_settings.get("effective_mode", ""))) == &"reduced", "Reduced run must report reduced presentation mode")
	_expect(StringName(str(disabled_settings.get("effective_mode", ""))) == &"disabled", "Disabled run must report disabled presentation mode")
	_expect(is_equal_approx(float(full_settings.get("rumble_scale", -1.0)), 0.65), "Full showcase rumble scale must remain 0.65")
	_expect(is_equal_approx(float(reduced_settings.get("rumble_scale", -1.0)), 0.35), "Reduced showcase rumble scale must remain 0.35")
	_expect(is_zero_approx(float(disabled_settings.get("rumble_scale", -1.0))), "Disabled showcase rumble scale must remain zero")
	_expect(bool((full.get("last_showcase_report", {}) as Dictionary).get("visual_requested", false)), "Full impact must request target presentation")
	_expect(bool((reduced.get("last_showcase_report", {}) as Dictionary).get("visual_requested", false)), "Reduced impact must retain target presentation")
	_expect(not bool((disabled.get("last_showcase_report", {}) as Dictionary).get("visual_requested", true)), "Disabled impact must request zero target presentation")
	_expect(int(full.get("target_feedback_count", -1)) == 1, "Full impact must keep one target transform owner")
	_expect(int(reduced.get("target_feedback_count", -1)) == 1, "Reduced impact must keep one restrained target transform owner")
	_expect(int(disabled.get("target_feedback_count", -1)) == 0, "Disabled impact must keep zero target transform owners")
	_expect(int(full.get("contact_visual_count", -1)) >= 1, "Full impact must expose a readable contact flash")
	_expect(int(reduced.get("contact_visual_count", -1)) >= 1, "Reduced impact must retain a restrained contact flash")
	_expect(int(disabled.get("contact_visual_count", -1)) == 0, "Disabled impact must expose zero contact flashes")
	_expect(int(full.get("test_start_calls", -1)) == 3, "Full combo must request two Brand haptics and one committed impact haptic")
	_expect(int(reduced.get("test_start_calls", -1)) == 3, "Reduced combo must preserve haptic event count while scaling magnitude")
	_expect(int(disabled.get("test_start_calls", -1)) == 0, "Disabled combo must make zero motor calls")


func _test_lethal_fracture_and_reset(showcase: VoidbringerImpactShowcaseSandbox) -> void:
	start_requests.clear()
	stop_requests.clear()
	showcase.simulate_showcase_command(&"mode_full")
	showcase.simulate_showcase_command(&"demo_lethal")
	var lethal := showcase.debug_showcase_snapshot()
	var foundation := lethal.get("foundation", {}) as Dictionary
	var enemy := foundation.get("enemy", {}) as Dictionary
	var impact := foundation.get("last_impact", {}) as Dictionary
	var anchors := foundation.get("anchors", []) as Array
	_expect(not bool(enemy.get("alive", true)) and int(enemy.get("health", -1)) == 0, "Lethal showcase command must commit gameplay death")
	_expect(bool(impact.get("fatal", false)), "Lethal showcase command must preserve the committed fatal result")
	_expect(int(impact.get("damage", 0)) == 8, "Lethal Mass Brand must preserve committed 8 damage")
	_expect(anchors.size() == 1, "Lethal showcase command must create exactly one Anchor")
	if not anchors.is_empty():
		_expect(StringName(str((anchors[0] as Dictionary).get("carrier_type", ""))) == &"corpse", "Lethal showcase Anchor must finalize as corpse")
	_expect(int(lethal.get("target_feedback_count", -1)) == 1, "Lethal showcase must expose one fatal Fracture owner")
	_expect(start_requests.size() == 1, "Lethal damaging Brand must request one impact haptic without a duplicate skill haptic")
	var feedback := showcase.enemy_fixture.visual_root.get_node_or_null("VoidbringerImpactFeedback") as ImpactFeedback
	_expect(feedback != null and feedback.is_fatal_active(), "Lethal showcase target must enter the fatal profile")
	if feedback != null:
		_expect(feedback.get_node_or_null("ProceduralFracture") != null, "Lethal showcase must expose the procedural Fracture visual")

	showcase.simulate_command(&"clear")
	var reset := showcase.debug_showcase_snapshot()
	var reset_foundation := reset.get("foundation", {}) as Dictionary
	var reset_enemy := reset_foundation.get("enemy", {}) as Dictionary
	_expect(bool(reset_enemy.get("alive", false)) and int(reset_enemy.get("health", -1)) == 100, "Showcase reset must restore target gameplay state")
	_expect((reset_foundation.get("anchors", []) as Array).is_empty(), "Showcase reset must remove all Anchors")
	_expect((reset_foundation.get("fold_lines", []) as Array).is_empty(), "Showcase reset must remove all Fold Lines")
	_expect(int(reset.get("target_feedback_count", -1)) == 0, "Showcase reset must remove fatal presentation state")
	_expect(int(reset.get("contact_visual_count", -1)) == 0, "Showcase reset must remove all contact flashes")
	_expect(stop_requests.size() == 1, "Showcase reset must stop active haptics exactly once")


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
