class_name RuntimeSession
extends Node

var event_bus: RuntimeEventBus
var character: RuntimeCharacter


func _init() -> void:
	event_bus = RuntimeEventBus.new()
	event_bus.name = "RuntimeEventBus"
	add_child(event_bus)


func bind_character(runtime_character: RuntimeCharacter) -> void:
	if character != null:
		_disconnect_character(character)
	character = runtime_character
	if character == null:
		return
	character.state_changed.connect(_on_character_state_changed)
	character.level_gained.connect(_on_character_level_gained)
	event_bus.build_loaded.emit(character.build_id)


func _disconnect_character(runtime_character: RuntimeCharacter) -> void:
	if runtime_character.state_changed.is_connected(_on_character_state_changed):
		runtime_character.state_changed.disconnect(_on_character_state_changed)
	if runtime_character.level_gained.is_connected(_on_character_level_gained):
		runtime_character.level_gained.disconnect(_on_character_level_gained)


func _on_character_state_changed(reason: StringName) -> void:
	if character == null:
		return
	event_bus.runtime_state_changed.emit(character.build_id, reason)


func _on_character_level_gained(new_level: int) -> void:
	if character == null:
		return
	event_bus.level_gained.emit(character.build_id, new_level)
