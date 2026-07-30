extends SceneTree

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const AUDIO_SCRIPT = preload("res://scripts/presentation/voidbringer_impact_audio.gd")

var failures: Array[String] = []
var finished_voice_ids: Array[StringName] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node3D.new()
	host.name = "VoidbringerImpactAudioTestHost"
	root.add_child(host)
	var settings := SETTINGS_SCRIPT.new() as VoidbringerPresentationSettings
	var audio := AUDIO_SCRIPT.new() as VoidbringerImpactAudio
	audio.configure(settings)
	audio.audio_finished.connect(func(voice_id: StringName) -> void: finished_voice_ids.append(voice_id))
	host.add_child(audio)
	await process_frame

	_test_deterministic_streams(audio)
	_test_committed_audio_ownership(audio)
	audio.clear()
	await process_frame
	_test_modes_and_budget(audio, settings)
	audio.tick(1.0)
	await process_frame
	_test_cleanup_and_source_budget(audio)

	audio.clear()
	await process_frame
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer deterministic impact audio")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_deterministic_streams(audio: VoidbringerImpactAudio) -> void:
	var impact_a := audio.debug_stream(&"impact", 0)
	var impact_b := audio.debug_stream(&"impact", 0)
	var fold_impact := audio.debug_stream(&"impact", 1)
	var fatal := audio.debug_stream(&"fatal", 0)
	var clamped_fold := audio.debug_stream(&"impact", 4)
	var maximum_fold := audio.debug_stream(&"impact", 3)
	_expect(impact_a == impact_b, "Repeated profile requests must reuse one cached stream")
	_expect(impact_a.format == AudioStreamWAV.FORMAT_16_BITS, "Impact audio must use signed 16-bit PCM")
	_expect(impact_a.mix_rate == 22050, "Impact audio sample rate must remain 22050 Hz")
	_expect(not impact_a.stereo, "Impact audio must remain mono before positional playback")
	_expect(impact_a.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Impact audio must never loop")
	_expect(impact_a.data.size() == int(ceil(0.14 * 22050.0)) * 2, "Normal impact PCM byte count must match duration and sample rate")
	_expect(fatal.data.size() == int(ceil(0.24 * 22050.0)) * 2, "Fatal PCM byte count must match its longer profile")
	_expect(not impact_a.data.is_empty() and _contains_nonzero_byte(impact_a.data), "Generated impact PCM must contain audible nonzero data")
	_expect(_byte_checksum(impact_a.data) != _byte_checksum(fold_impact.data), "Fold-enhanced impact must add a distinct overtone")
	_expect(_byte_checksum(impact_a.data) != _byte_checksum(fatal.data), "Fatal impact must use a distinct waveform and duration")
	_expect(_byte_checksum(clamped_fold.data) == _byte_checksum(maximum_fold.data), "Fold audio profile must clamp to the gameplay maximum of three crossings")
	_expect(int(audio.debug_snapshot().get("cached_stream_count", 0)) == 4, "Stream cache must contain only the distinct requested profiles")


func _test_committed_audio_ownership(audio: VoidbringerImpactAudio) -> void:
	var baseline := int(audio.debug_snapshot().get("play_count", 0))
	var normal := audio.play_impact({
		"cast_id": &"vb.cast.audio.normal",
		"impact_point": Vector3(1.0, 0.0, -2.0),
		"damage_applied": 18.0,
		"critical": false,
		"fatal": false,
		"fold_crossing_count": 0,
	})
	_expect(StringName(str(normal.get("profile_id", ""))) == &"impact", "Normal committed hit must select the impact profile")
	_expect(normal.get("position", Vector3.ZERO) == Vector3(1.0, 0.0, -2.0), "Impact audio must preserve committed world position")
	var critical := audio.play_impact({
		"cast_id": &"vb.cast.audio.critical",
		"damage_applied": 27.0,
		"critical": true,
		"fatal": false,
		"fold_crossing_count": 2,
	})
	_expect(StringName(str(critical.get("profile_id", ""))) == &"critical", "Critical committed hit must select the critical profile")
	_expect(int(critical.get("fold_count", -1)) == 2, "Critical audio must preserve committed Fold count")
	var fatal := audio.play_impact({
		"cast_id": &"vb.cast.audio.fatal",
		"damage_applied": 20.0,
		"critical": true,
		"fatal": true,
		"fold_crossing_count": 9,
	})
	_expect(StringName(str(fatal.get("profile_id", ""))) == &"fatal", "Fatal state must take priority over critical state")
	_expect(int(fatal.get("fold_count", -1)) == 3, "Fatal audio Fold count must clamp to three")
	_expect(audio.play_impact({"damage_applied": 0.0, "fatal": true}).is_empty(), "Unapplied impact must produce no fake audio")
	var anchor := audio.play_skill_commit({
		"success": true,
		"cast_id": &"vb.cast.audio.anchor",
		"ability_id": &"vb.skill.mass_brand",
		"entered_breach": false,
		"anchor": {"position": Vector3(-2.0, 0.0, -1.0)},
		"impact": {"damage_applied": 0.0},
	})
	_expect(StringName(str(anchor.get("profile_id", ""))) == &"anchor", "Non-damaging Mass Brand must play one Anchor cue")
	_expect(anchor.get("position", Vector3.ZERO) == Vector3(-2.0, 0.0, -1.0), "Anchor cue must use committed Anchor position")
	var before_damaging_skill := int(audio.debug_snapshot().get("play_count", -1))
	_expect(audio.play_skill_commit({
		"success": true,
		"ability_id": &"vb.skill.mass_brand",
		"impact": {"damage_applied": 8.0},
	}).is_empty(), "Damaging Mass Brand skill commit must defer audio to impact_committed")
	_expect(int(audio.debug_snapshot().get("play_count", -1)) == before_damaging_skill, "Damaging skill commit must not duplicate its impact cue")
	_expect(audio.play_skill_commit({
		"success": true,
		"ability_id": &"vb.skill.null_shard",
		"entered_breach": false,
		"impact": {},
	}).is_empty(), "Null Shard launch must not fake contact audio")
	var breach := audio.play_skill_commit({
		"success": true,
		"cast_id": &"vb.cast.audio.breach",
		"ability_id": &"vb.skill.null_shard",
		"entered_breach": true,
		"impact": {},
	})
	_expect(StringName(str(breach.get("profile_id", ""))) == &"breach", "Threshold skill commit must play one combined Breach cue")
	_expect(int(audio.debug_snapshot().get("play_count", 0)) - baseline == 5, "Normal, critical, fatal, Anchor, and Breach must be the only five cues")


func _test_modes_and_budget(
	audio: VoidbringerImpactAudio,
	settings: VoidbringerPresentationSettings
) -> void:
	finished_voice_ids.clear()
	settings.configure(&"full", true, true)
	var full := audio.play_impact({"cast_id": &"vb.cast.audio.full", "damage_applied": 18.0})
	_expect(is_equal_approx(float(full.get("audio_scale", 0.0)), 1.0), "Full mode audio scale must remain 1.0")
	_expect(is_equal_approx(float(full.get("volume_db", -999.0)), linear_to_db(0.72)), "Full normal impact gain must match its profile")
	settings.configure(&"reduced", true, true)
	var reduced := audio.play_impact({"cast_id": &"vb.cast.audio.reduced", "damage_applied": 18.0})
	_expect(is_equal_approx(float(reduced.get("audio_scale", 0.0)), 0.45), "Reduced mode audio scale must remain 0.45")
	_expect(float(reduced.get("volume_db", 0.0)) < float(full.get("volume_db", 0.0)), "Reduced mode must lower positional impact gain")
	settings.configure(&"disabled", true, true)
	var count_before_disabled := int(audio.debug_snapshot().get("play_count", -1))
	_expect(audio.play_impact({"damage_applied": 18.0}).is_empty(), "Disabled mode must create no impact voice")
	_expect(audio.play_skill_commit({"success": true, "ability_id": &"vb.skill.mass_brand", "impact": {}}).is_empty(), "Disabled mode must create no skill voice")
	_expect(int(audio.debug_snapshot().get("play_count", -1)) == count_before_disabled, "Disabled mode must not increment audio play count")
	settings.configure(&"full", true, true)
	for index in range(12):
		audio.play_impact({
			"cast_id": StringName("vb.cast.audio.budget.%02d" % index),
			"damage_applied": 18.0,
			"critical": index % 3 == 0,
			"fatal": false,
			"fold_crossing_count": index % 4,
		})
	var budget := audio.debug_snapshot()
	_expect(int(budget.get("active_voice_count", -1)) == 8, "Audio owner must enforce the hard eight-voice cap")
	_expect(_count_audio_players(audio) == 8, "Voice cap must match actual AudioStreamPlayer3D children")


func _test_cleanup_and_source_budget(audio: VoidbringerImpactAudio) -> void:
	_expect(int(audio.debug_snapshot().get("active_voice_count", -1)) == 0, "Audio tick must clean every expired voice")
	_expect(_count_audio_players(audio) == 0, "Expired audio cleanup must leave no positional players")
	_expect(finished_voice_ids.size() == 8, "Bounded cleanup must emit completion for every remaining active voice")
	audio.play_impact({"damage_applied": 18.0})
	audio.clear()
	var source := FileAccess.get_file_as_string("res://scripts/presentation/voidbringer_impact_audio.gd")
	_expect(not source.contains("preload(\"res://audio"), "Procedural impact audio must not depend on placeholder external audio assets")
	_expect(source.count("AudioStreamPlayer3D.new()") == 1, "Impact audio must have one positional player allocation site")


func _byte_checksum(data: PackedByteArray) -> int:
	var checksum := 0
	for index in range(data.size()):
		checksum = (checksum + int(data[index]) * (index % 251 + 1)) % 2147483647
	return checksum


func _contains_nonzero_byte(data: PackedByteArray) -> bool:
	for byte: int in data:
		if byte != 0:
			return true
	return false


func _count_audio_players(root_node: Node) -> int:
	var count := 1 if root_node is AudioStreamPlayer3D else 0
	for child: Node in root_node.get_children():
		count += _count_audio_players(child)
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
