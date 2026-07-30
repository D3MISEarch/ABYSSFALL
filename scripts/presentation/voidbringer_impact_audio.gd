class_name VoidbringerImpactAudio
extends Node3D

signal audio_started(snapshot: Dictionary)
signal audio_finished(voice_id: StringName)

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const SAMPLE_RATE := 22050
const MAX_ACTIVE_VOICES := 8
const MASS_BRAND_ID: StringName = &"vb.skill.mass_brand"

var settings: VoidbringerPresentationSettings
var active_voices: Array[Dictionary] = []
var last_audio_report: Dictionary = {}
var play_count := 0
var _next_voice_serial := 1
var _stream_cache: Dictionary = {}


func configure(presentation_settings: VoidbringerPresentationSettings) -> void:
	settings = presentation_settings
	if settings == null:
		settings = SETTINGS_SCRIPT.new()


func play_impact(value: Variant) -> Dictionary:
	var impact := _snapshot(value)
	if impact.is_empty() or settings == null:
		return {}
	if float(impact.get("damage_applied", 0.0)) <= 0.0:
		return {}
	var profile_id: StringName = &"impact"
	if bool(impact.get("fatal", false)):
		profile_id = &"fatal"
	elif bool(impact.get("critical", false)):
		profile_id = &"critical"
	var fold_count := clampi(int(impact.get("fold_crossing_count", 0)), 0, 3)
	return _play_profile(
		profile_id,
		impact.get("impact_point", Vector3.ZERO),
		fold_count,
		impact.get("cast_id", &"")
	)


func play_skill_commit(value: Variant) -> Dictionary:
	var skill := _snapshot(value)
	if skill.is_empty() or not bool(skill.get("success", false)) or settings == null:
		return {}
	var impact := skill.get("impact", {}) as Dictionary
	if not impact.is_empty() and float(impact.get("damage_applied", 0.0)) > 0.0:
		return {}
	var anchor := skill.get("anchor", {}) as Dictionary
	var position_value: Vector3 = anchor.get("position", Vector3.ZERO)
	if bool(skill.get("entered_breach", false)):
		return _play_profile(&"breach", position_value, 0, skill.get("cast_id", &""))
	if StringName(str(skill.get("ability_id", ""))) == MASS_BRAND_ID:
		return _play_profile(&"anchor", position_value, 0, skill.get("cast_id", &""))
	return {}


func tick(delta: float) -> void:
	var step := maxf(delta, 0.0)
	for index in range(active_voices.size() - 1, -1, -1):
		var voice: Dictionary = active_voices[index]
		var remaining := maxf(float(voice.get("remaining", 0.0)) - step, 0.0)
		var player := voice.get("player") as AudioStreamPlayer3D
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
		_dispose_player(voice.get("player") as AudioStreamPlayer3D)
	active_voices.clear()
	last_audio_report.clear()


func debug_snapshot() -> Dictionary:
	var voices: Array[Dictionary] = []
	for voice: Dictionary in active_voices:
		voices.append({
			"voice_id": voice.get("voice_id", &""),
			"profile_id": voice.get("profile_id", &""),
			"remaining": float(voice.get("remaining", 0.0)),
			"volume_db": float(voice.get("volume_db", 0.0)),
			"fold_count": int(voice.get("fold_count", 0)),
		})
	return {
		"active_voice_count": active_voices.size(),
		"play_count": play_count,
		"cached_stream_count": _stream_cache.size(),
		"last_audio_report": last_audio_report.duplicate(true),
		"voices": voices,
	}


func debug_stream(profile_id: StringName, fold_count: int = 0) -> AudioStreamWAV:
	return _stream_for(profile_id, clampi(fold_count, 0, 3))


func _play_profile(
	profile_id: StringName,
	world_position: Vector3,
	fold_count: int,
	cast_id: Variant
) -> Dictionary:
	var audio_scale := settings.audio_scale()
	if audio_scale <= 0.0:
		return {}
	_prune_to_budget()
	var stream := _stream_for(profile_id, fold_count)
	var player := AudioStreamPlayer3D.new()
	var voice_id := StringName("vb.audio.voice.%04d" % _next_voice_serial)
	_next_voice_serial += 1
	player.name = String(voice_id)
	player.stream = stream
	player.position = to_local(world_position)
	player.max_distance = 18.0
	player.unit_size = 2.5
	player.max_polyphony = 1
	var profile_gain := _profile_gain(profile_id)
	var linear_gain := clampf(profile_gain * audio_scale, 0.001, 1.0)
	player.volume_db = linear_to_db(linear_gain)
	add_child(player)
	player.play()
	var duration := _profile_duration(profile_id)
	active_voices.append({
		"voice_id": voice_id,
		"profile_id": profile_id,
		"player": player,
		"remaining": duration + 0.04,
		"duration": duration,
		"volume_db": player.volume_db,
		"fold_count": fold_count,
	})
	play_count += 1
	last_audio_report = {
		"voice_id": voice_id,
		"cast_id": cast_id,
		"profile_id": profile_id,
		"position": world_position,
		"fold_count": fold_count,
		"duration": duration,
		"audio_scale": audio_scale,
		"volume_db": player.volume_db,
		"active_voice_count": active_voices.size(),
	}
	audio_started.emit(last_audio_report.duplicate(true))
	return last_audio_report.duplicate(true)


func _prune_to_budget() -> void:
	while active_voices.size() >= MAX_ACTIVE_VOICES:
		var oldest: Dictionary = active_voices.pop_front()
		_dispose_player(oldest.get("player") as AudioStreamPlayer3D)


func _dispose_player(player: AudioStreamPlayer3D) -> void:
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
	var sample_count := maxi(int(ceil(duration * float(SAMPLE_RATE))), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var seed := _profile_seed(profile_id) + fold_count * 977
	for sample_index in range(sample_count):
		var time := float(sample_index) / float(SAMPLE_RATE)
		var progress := clampf(time / duration, 0.0, 1.0)
		var envelope := minf(time / 0.006, 1.0) * pow(1.0 - progress, 2.25)
		var low_frequency := lerpf(_low_start(profile_id), _low_end(profile_id), progress)
		var mid_frequency := lerpf(_mid_start(profile_id), _mid_end(profile_id), progress)
		var low := sin(TAU * low_frequency * time)
		var mid := sin(TAU * mid_frequency * time + 0.35) * 0.34
		var noise := _deterministic_noise(sample_index, seed) * pow(1.0 - progress, 5.5)
		var fold_tone := 0.0
		if fold_count > 0:
			fold_tone = sin(TAU * (390.0 + float(fold_count) * 55.0) * time) * 0.10 * float(fold_count)
		var sample := (low * 0.62 + mid * 0.24 + noise * 0.32 + fold_tone) * envelope
		if profile_id == &"fatal":
			sample += sin(TAU * 31.0 * time) * pow(1.0 - progress, 1.55) * 0.24
		elif profile_id == &"breach":
			sample += sin(TAU * 172.0 * time + sin(time * 28.0) * 0.7) * envelope * 0.20
		var signed_sample := int(round(clampf(sample, -1.0, 1.0) * 32767.0))
		data[sample_index * 2] = signed_sample & 0xFF
		data[sample_index * 2 + 1] = (signed_sample >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = data
	_stream_cache[cache_key] = stream
	return stream


func _profile_duration(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 0.24
		&"critical":
			return 0.18
		&"breach":
			return 0.26
		&"anchor":
			return 0.11
		_:
			return 0.14


func _profile_gain(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 1.0
		&"critical":
			return 0.88
		&"breach":
			return 0.84
		&"anchor":
			return 0.56
		_:
			return 0.72


func _low_start(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 88.0
		&"critical":
			return 102.0
		&"breach":
			return 72.0
		&"anchor":
			return 118.0
		_:
			return 96.0


func _low_end(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 38.0
		&"critical":
			return 48.0
		&"breach":
			return 34.0
		&"anchor":
			return 62.0
		_:
			return 44.0


func _mid_start(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 285.0
		&"critical":
			return 340.0
		&"breach":
			return 230.0
		&"anchor":
			return 410.0
		_:
			return 315.0


func _mid_end(profile_id: StringName) -> float:
	match profile_id:
		&"fatal":
			return 92.0
		&"critical":
			return 125.0
		&"breach":
			return 84.0
		&"anchor":
			return 180.0
		_:
			return 110.0


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
