extends SceneTree

const SETTINGS_SCRIPT = preload("res://scripts/presentation/voidbringer_presentation_settings.gd")
const AUDIO_SCRIPT = preload("res://scripts/presentation/voidbringer_impact_audio.gd")


func _init() -> void:
	print("AUDIO_PROBE: init")
	call_deferred("_run")


func _run() -> void:
	print("AUDIO_PROBE: create host")
	var host := Node3D.new()
	root.add_child(host)
	print("AUDIO_PROBE: create settings")
	var settings := SETTINGS_SCRIPT.new() as VoidbringerPresentationSettings
	print("AUDIO_PROBE: create owner")
	var audio := AUDIO_SCRIPT.new() as VoidbringerImpactAudio
	print("AUDIO_PROBE: configure owner")
	audio.configure(settings)
	print("AUDIO_PROBE: add owner")
	host.add_child(audio)
	print("AUDIO_PROBE: generate stream")
	var stream := audio.debug_stream(&"impact", 0)
	print("AUDIO_PROBE: stream bytes=%d" % stream.data.size())
	print("AUDIO_PROBE: create voice")
	var report := audio.play_impact({
		"cast_id": &"vb.cast.audio.probe",
		"damage_applied": 18.0,
		"impact_point": Vector3.ZERO,
	})
	print("AUDIO_PROBE: voice=%s" % String(report.get("voice_id", &"")))
	audio.clear()
	host.queue_free()
	await process_frame
	print("PASS: Voidbringer impact audio probe")
	quit(0)
