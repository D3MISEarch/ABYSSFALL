extends SceneTree

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const HAPTICS_SCRIPT = preload("res://scripts/presentation/voidbringer_haptics.gd")

var failures: Array[String] = []
var start_requests: Array[Dictionary] = []
var stop_requests: Array[int] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_mode_contract()
	_test_haptic_scaling_and_zero_call_contract()
	_test_real_api_call_budget()
	if failures.is_empty():
		print("PASS: Voidbringer presentation modes and real haptics")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_mode_contract() -> void:
	var settings := SETTINGS_SCRIPT.new() as VoidbringerPresentationSettings
	_expect(settings.effective_mode() == &"full", "Default presentation mode must be full")
	_expect(is_equal_approx(settings.transform_scale(), 1.0), "Full mode must retain full transform response")
	_expect(is_equal_approx(settings.rumble_scale(), 0.65), "Full mode rumble scale must be locked at 0.65")

	settings.configure(&"reduced", true, true)
	_expect(settings.effective_mode() == &"reduced", "Reduced mode must remain independently observable")
	_expect(is_equal_approx(settings.transform_scale(), 0.55), "Reduced mode must lower transform response")
	_expect(is_equal_approx(settings.fracture_detail_scale(), 0.60), "Reduced mode must lower Fracture detail")
	_expect(is_equal_approx(settings.rumble_scale(), 0.35), "Reduced mode rumble scale must be locked at 0.35")

	settings.configure(&"disabled", true, true)
	_expect(settings.effective_mode() == &"disabled", "Disabled mode must remain independently observable")
	_expect(is_zero_approx(settings.transform_scale()), "Disabled mode must suppress presentation transforms")
	_expect(is_zero_approx(settings.light_scale()), "Disabled mode must suppress presentation lights")
	_expect(is_zero_approx(settings.rumble_scale()), "Disabled mode must suppress rumble")

	settings.configure(&"full", false, true)
	_expect(settings.effective_mode() == &"disabled", "Master disable must override the selected presentation mode")
	_expect(is_zero_approx(settings.rumble_scale()), "Master disable must produce zero rumble")

	settings.configure(&"full", true, false)
	_expect(settings.effective_mode() == &"full", "Haptics disable must not disable visual presentation")
	_expect(is_zero_approx(settings.rumble_scale()), "Haptics disable must produce zero rumble")

	settings.configure(&"invalid_mode", true, true)
	_expect(settings.mode == &"full", "Invalid presentation modes must fall back deterministically to full")


func _test_haptic_scaling_and_zero_call_contract() -> void:
	start_requests.clear()
	stop_requests.clear()
	var settings := SETTINGS_SCRIPT.new() as VoidbringerPresentationSettings
	var haptics := HAPTICS_SCRIPT.new(
		settings,
		Callable(self, "_record_start"),
		Callable(self, "_record_stop")
	) as VoidbringerHaptics
	haptics.configure_device(2)

	var normal_impact := {
		"damage_applied": true,
		"critical": false,
		"fatal": false,
		"fold_crossing_count": 0,
	}
	_expect(haptics.play_impact(normal_impact), "Full-mode valid impact must request rumble")
	_expect(start_requests.size() == 1, "One impact must produce exactly one motor call")
	var normal_request: Dictionary = start_requests.back()
	_expect(int(normal_request.get("device_id", -1)) == 2, "Haptics must preserve the configured device")
	_expect(
		is_equal_approx(float(normal_request.get("strong", -1.0)), 0.58 * 0.65),
		"Full-mode normal impact must apply the 0.65 scale exactly"
	)
	_expect(
		is_equal_approx(float(normal_request.get("weak", -1.0)), 0.58 * 0.65 * 0.55),
		"Weak motor must derive deterministically from the scaled strong motor"
	)

	settings.configure(&"reduced", true, true)
	var fatal_impact := {
		"damage_applied": true,
		"critical": true,
		"fatal": true,
		"fold_crossing_count": 3,
	}
	_expect(haptics.play_impact(fatal_impact), "Reduced-mode fatal impact must retain restrained rumble")
	_expect(start_requests.size() == 2, "Second valid impact must add exactly one motor call")
	var fatal_request: Dictionary = start_requests.back()
	_expect(
		is_equal_approx(float(fatal_request.get("strong", -1.0)), 1.0 * 0.35),
		"Reduced fatal rumble must clamp base strength and apply the locked 0.35 scale"
	)
	_expect(is_equal_approx(float(fatal_request.get("duration", 0.0)), 0.18), "Fatal rumble duration must be bounded and deterministic")

	settings.configure(&"disabled", true, true)
	_expect(not haptics.play_impact(normal_impact), "Disabled mode must reject rumble requests")
	_expect(start_requests.size() == 2, "Disabled mode must make zero motor calls")
	_expect(not haptics.play_anchor_commit(), "Disabled mode must suppress anchor rumble")
	_expect(start_requests.size() == 2, "Disabled anchor feedback must make zero motor calls")

	settings.configure(&"full", false, true)
	_expect(not haptics.play_breach(true), "Master disable must suppress Breach rumble")
	_expect(start_requests.size() == 2, "Master disable must make zero motor calls")

	settings.configure(&"full", true, false)
	_expect(not haptics.play_breach(true), "Haptics disable must suppress Breach rumble")
	_expect(start_requests.size() == 2, "Haptics disable must make zero motor calls")

	settings.configure(&"full", true, true)
	_expect(
		not haptics.play_impact({"damage_applied": false, "fatal": true}),
		"Unapplied impact packets must not produce fake rumble"
	)
	_expect(start_requests.size() == 2, "Unapplied impacts must make zero motor calls")
	_expect(not haptics.play_breach(false), "Non-transition Breach observations must not rumble")
	_expect(start_requests.size() == 2, "Non-transition Breach observations must make zero motor calls")

	haptics.clear()
	_expect(stop_requests == [2], "Clearing an active haptic owner must stop its configured device exactly once")
	haptics.clear()
	_expect(stop_requests == [2], "Repeated clear must not duplicate stop calls")
	var snapshot := haptics.debug_snapshot()
	_expect(int(snapshot.get("start_call_count", -1)) == 2, "Haptic debug state must report actual start calls")
	_expect(int(snapshot.get("stop_call_count", -1)) == 1, "Haptic debug state must report actual stop calls")
	_expect(not bool(snapshot.get("active", true)), "Haptic cleanup must leave no active motor state")


func _test_real_api_call_budget() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/presentation/voidbringer_haptics.gd")
	_expect(
		source.count("Input.start_joy_vibration") == 1,
		"The haptics owner must contain exactly one real motor start call site"
	)
	_expect(
		source.count("Input.stop_joy_vibration") == 1,
		"The haptics owner must contain exactly one real motor cleanup call site"
	)
	_expect(
		not source.contains("vibration =") and not source.contains("visual_vibration"),
		"Controller rumble must remain separate from visual oscillation fields"
	)


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
