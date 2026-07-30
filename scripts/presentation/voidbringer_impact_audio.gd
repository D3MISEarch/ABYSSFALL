class_name VoidbringerImpactAudio
extends Node

signal audio_started(snapshot: Dictionary)
signal audio_finished(voice_id: StringName)

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const CAMERA_IMPACT_SCRIPT = preload("res://scripts/presentation/voidbringer_camera_impact.gd")
const SAMPLE_RATE := 44100
const MAX_ACTIVE_VOICES := 8
const MASS_BRAND_ID: StringName = &"vb.skill.mass_brand"
const OUTPUT_BUS := &"Master"

var settings: VoidbringerPresentationSettings
var active_voices: Array[Dictionary] = []
var last_audio_report: Dictionary = {}
var play_count := 0
var _next_voice_serial := 1
var _stream_cache: Dictionary = {}
var camera_impact: VoidbringerCameraImpact


func configure(presentation_settings: VoidbringerPresentationSettings) -> void:
	settings = presentation_settings
	if settings == null:
		settings = SETTINGS_SCRIPT.new()
	camera_impact = CAMERA_IMPACT_SCRIPT.new() as VoidbringerCameraImpact
	camera_impact.name = "VoidbringerCameraImpact"
	add_child(camera_impact)
	camera_impact.configure(settings)


func play_impact(value: Variant) -> Dictionary:
	var impact := _snapshot(value)
	if impact.is_empty() or settings == null:
		return {}
	if float(impact.get("damage_applied", 0.0)) <= 0.0:
		return {}
	if camera_impact != null:
		camera_impact.play_impact(impact)
	var profile_id: StringName = &"impact"
	if bool(impact.get("fatal", false)):
		profile_id = &"fatal"
	elif bool(impact.get("critical", false)):
		profile_id = &"critical"
	var fold_count := clampi(int(impact.get("fold_crossing_count", 0)), 0, 3)
	return _play_profile(profile_id, fold_count, impact.get("cast_id", &""))


func play_skill_commit(value: Variant) -> Dictionary:
	var skill := _snapshot(value)
	if skill.is_empty() or not bool(skill.get("success", false)) or settings == null:
		return {}
	var impact := skill.get("impact", {}) as Dictionary
	if not impact.is_empty() and float(impact.get("damage_applied", 0.0)) > 0.0:
		return {}
	var anchor := skill.get("anchor", {}) as Dictionary
	if bool(skill.get("entered_breach", false)):
		return _play_profile(&"breach", 0, skill.get("cast_id", &""))
	if StringName(str(skill.get("ability_id", ""))) == MASS_BRAND_ID:
		return _play_profile(&"anchor", 0, skill.get("cast_id", &""))
	return {}


func tick(delta: float) -> void:
	var step := maxf(delta, 0.0)
	if camera_impact != null:
		camera_impact.tick(step)
	for index in range(active_voices.size() - 1, -1, -1):
		var voice: Dictionary = active_voices[index]
		var remaining := maxf(float(voice.get("remaining", 0.0)) - step, 0.0)
		var player := voice.get("player") as AudioStreamPlayer
		if remaining <= 0.0 or not is_instance_valid(player):
			var voice_id := StringName(str(voice.get("voice_id", "")))
			active_voices.remove_at(index)
			_dispose_player(player)
			audio_finished.emit(voice_id)
		else:
			voice["remaining"] = remaining
			active_voices[index] = voice


func clear() -> void:
	for voice: Dictionary in active_voices:
		_dispose_player(voice.get("player") as AudioStreamPlayer)
	active_voices.clear()
	last_audio_report.clear()
	if camera_impact != null:
		camera_impact.clear()


func debug_snapshot() -> Dictionary:
	var voices: Array[Dictionary] = []
	for voice: Dictionary in active_voices:
		voices.append({
			"voice_id": voice.get("voice_id", &""),
			"profile_id": voice.get("profile_id", &""),
			"remaining": float(voice.get("remaining", 0.0)),
			"volume_db": float(voice.get("volume_db", 0.0)),
			"fold_count": int(voice.get("fold_count", 0)),
			"playing": bool(voice.get("playing", false)),
		})
	return {
		"active_voice_count": active_voices.size(),
		"play_count": play_count,
		"cached_stream_count": _stream_cache.size(),
		"last_audio_report": last_audio_report.duplicate(true),
		"voices": voices,
		"output_bus": OUTPUT_BUS,
		"player_kind": &"AudioStreamPlayer",
		"camera": {} if camera_impact == null else camera_impact.debug_snapshot(),
	}


func debug_stream(profile_id: StringName, fold_count: int = 0) -> AudioStreamWAV:
	return _stream_for(profile_id, clampi(fold_count, 0, 3))


func _play_profile(profile_id: StringName, fold_count: int, cast_id: Variant) -> Dictionary:
	var audio_scale := settings.audio_scale()
	if audio_scale <= 0.0:
		return {}
	_prune_to_budget()
	var stream := _stream_for(profile_id, fold_count)
	var player := AudioStreamPlayer.new()
	var voice_id := StringName("vb.audio.voice.%04d" % _next_voice_serial)
	_next_voice_serial += 1
	player.name = String(voice_id)
	player.stream = stream
	player.bus = OUTPUT_BUS
	player.max_polyphony = 1
	var profile_gain := _profile_gain(profile_id)
	var linear_gain := clampf(profile_gain * audio_scale, 0.001, 1.0)
	player.volume_db = linear_to_db(linear_gain)
	add_child(player)
	player.play()
	var duration := _profile_duration(profile_id)
	var peak := _stream_peak(stream)
	active_voices.append({
		"voice_id": voice_id,
		"profile_id": profile_id,
		"player": player,
		"remaining": duration + 0.08,
		"duration": duration,
		"volume_db": player.volume_db,
		"fold_count": fold_count,
		"playing": player.playing,
	})
	play_count += 1
	last_audio_report = {
		"voice_id": voice_id,
		"cast_id": cast_id,
		"profile_id": profile_id,
		"fold_count": fold_count,
		"duration": duration,
		"audio_scale": audio_scale,
		"volume_db": player.volume_db,
		"active_voice_count": active_voices.size(),
		"output_bus": player.bus,
		"player_kind": &"AudioStreamPlayer",
		"stream_peak": peak,
		"playing_after_start": player.playing,
	}
	audio_started.emit(last_audio_report.duplicate(true))
	return last_audio_report.duplicate(true)


func _prune_to_budget() -> void:
	while active_voices.size() >= MAX_ACTIVE_VOICES:
		var oldest: Dictionary = active_voices.pop_front()
		_dispose_player(oldest.get("player") as AudioStreamPlayer)


func _dispose_player(player: AudioStreamPlayer) -> void:
	if not is_instance_valid(player):
		return
	player.stop()
	if player.get_parent() == self:
		remove_child(player)
	player.queue_free()


func _stream_for(profile_id: StringName, fold_count: int) -> AudioStreamWAV:
	var cache_key := "%s:%d" % [String(profile_id), fold_count]
	if _stream_cache.has(cache_key):
		return _stream_cache[cache_key] as AudioStreamWAV
	var duration := _profile_duration(profile_id)
	var frame_count := maxi(int(ceil(duration * float(SAMPLE_RATE))), 1)
	var mono_samples := PackedFloat32Array()
	mono_samples.resize(frame_count)
	var seed := _profile_seed(profile_id) + fold_count * 977
	var peak := 0.0
	for sample_index in range(frame_count):
		var time := float(sample_index) / float(SAMPLE_RATE)
		var progress := clampf(time / duration, 0.0, 1.0)
		var attack := minf(time / 0.0035, 1.0)
		var envelope := attack * pow(1.0 - progress, 1.65)
		var low_frequency := lerpf(_low_start(profile_id), _low_end(profile_id), progress)
		var mid_frequency := lerpf(_mid_start(profile_id), _mid_end(profile_id), progress)
		var low := sin(TAU * low_frequency * time)
		var mid := sin(TAU * mid_frequency * time + 0.35) * 0.38
		var click := _deterministic_noise(sample_index, seed) * pow(1.0 - progress, 9.0)
		var fold_tone := 0.0
		if fold_count > 0:
			fold_tone = sin(TAU * (390.0 + float(fold_count) * 55.0) * time) * 0.12 * float(fold_count)
		var sample := (low * 0.72 + mid * 0.30 + click * 0.42 + fold_tone) * envelope
		if profile_id == &"fatal":
			sample += sin(TAU * 38.0 * time) * pow(1.0 - progress, 1.25) * 0.42
		elif profile_id == &"breach":
			sample += sin(TAU * 172.0 * time + sin(time * 28.0) * 0.7) * envelope * 0.24
		mono_samples[sample_index] = sample
		peak = maxf(peak, absf(sample))
	var normalization := 0.92 / maxf(peak, 0.001)
	var data := PackedByteArray()
	data.resize(frame_count * 4)
	for sample_index in range(frame_count):
		var normalized := clampf(mono_samples[sample_index] * normalization, -0.92, 0.92)
		var signed_sample := int(round(normalized * 32767.0))
		var low_byte := signed_sample & 0xFF
		var high_byte := (signed_sample >> 8) & 0xFF
		var offset := sample_index * 4
		data[offset] = low_byte
		data[offset + 1] = high_byte
		data[offset + 2] = low_byte
		data[offset + 3] = high_byte
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	_stream_cache[cache_key] = stream
	return stream


func _stream_peak(stream: AudioStreamWAV) -> float:
	if stream == null or stream.data.is_empty():
		return 0.0
	var peak := 0.0
	var step := 4 if stream.stereo else 2
	for offset in range(0, stream.data.size() - 1, step):
		var value := int(stream.data[offset]) | (int(stream.data[offset + 1]) << 8)
		if value >= 32768:
			value -= 65536
		peak = maxf(peak, absf(float(value) / 32767.0))
	return peak


func _profile_duration(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 0.42
		&"critical":
			return 0.30
		&"breach":
			return 0.38
		&"anchor":
			return 0.18
		_:
			return 0.28


func _profile_gain(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 1.0
		&"critical":
			return 0.96
		&"breach":
			return 0.90
		&"anchor":
			return 0.68
		_:
			return 0.92


func _low_start(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 96.0
		&"critical":
			return 112.0
		&"breach":
			return 82.0
		&"anchor":
			return 132.0
		_:
			return 108.0


func _low_end(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 42.0
		&"critical":
			return 52.0
		&"breach":
			return 38.0
		&"anchor":
			return 70.0
		_:
			return 48.0


func _mid_start(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 320.0
		&"critical":
			return 390.0
		&"breach":
			return 260.0
		&"anchor":
			return 460.0
		_:
			return 360.0


func _mid_end(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 105.0
		&"critical":
			return 140.0
		&"breach":
			return 92.0
		&"anchor":
			return 195.0
		_:
			return 120.0


func _profile_seed(profile_id: StringName) -> int:
	return abs(String(profile_id).hash()) + 17011


func _deterministic_noise(sample_index: int, seed: int) -> float:
	var value := (sample_index * 1103515245 + seed * 12345 + 1013904223) & 0x7fffffff
	return float(value % 65536) / 32767.5 - 1.0


func _snapshot(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value != null and value.has_method("snapshot"):
		return value.snapshot()
	return {}
