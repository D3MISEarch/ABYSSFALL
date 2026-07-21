class_name RuntimeEventBus
extends Node

signal build_loaded(build_id: String)
signal runtime_state_changed(build_id: String, reason: StringName)
signal ability_cast(build_id: String, ability_id: StringName)
signal ability_rejected(build_id: String, ability_id: StringName, reason: StringName)
signal item_equipped(build_id: String, slot_id: StringName, item_instance_id: String)
signal enemy_killed(enemy_id: StringName, killer_build_id: String)
signal experience_gained(build_id: String, amount: int)
signal level_gained(build_id: String, new_level: int)
signal save_requested(build_id: String, reason: StringName)


func emit_state_change(build_id: String, reason: StringName) -> void:
	runtime_state_changed.emit(build_id, reason)
