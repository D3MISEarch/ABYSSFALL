extends SceneTree

var failures: Array[String] = []
var session_one_events := 0
var session_two_events := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var build_one := BuildData.create_new(ClassIds.PENITENT, "First")
	var build_two := BuildData.create_new(ClassIds.VOID_WARLOCK, "Second")
	var character_one := RuntimeCharacter.new()
	var character_two := RuntimeCharacter.new()
	character_one.configure_from_build(build_one)
	character_two.configure_from_build(build_two)

	var session_one := RuntimeSession.new()
	var session_two := RuntimeSession.new()
	root.add_child(session_one)
	root.add_child(session_two)
	session_one.event_bus.runtime_state_changed.connect(_on_session_one_event)
	session_two.event_bus.runtime_state_changed.connect(_on_session_two_event)
	session_one.bind_character(character_one)
	session_two.bind_character(character_two)

	character_one.gain_experience(10)
	_expect(session_one_events == 1, "Session one should receive its character event")
	_expect(session_two_events == 0, "Session two must not receive session one events")
	character_two.gain_experience(10)
	_expect(session_one_events == 1, "Session one must not receive session two events")
	_expect(session_two_events == 1, "Session two should receive its character event")

	if failures.is_empty():
		print("PASS: RuntimeSession event bus isolation")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _on_session_one_event(_build_id: String, _reason: StringName) -> void:
	session_one_events += 1


func _on_session_two_event(_build_id: String, _reason: StringName) -> void:
	session_two_events += 1


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
