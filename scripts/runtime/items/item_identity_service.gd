class_name ItemIdentityService
extends RefCounted

const ID_PREFIX := "item"

var _session_id: String = ""
var _next_sequence: int = 1


func configure(p_session_id: String, snapshot: Dictionary = {}) -> bool:
	var normalized_session_id := p_session_id.strip_edges()
	if normalized_session_id.is_empty():
		clear()
		return false
	_session_id = normalized_session_id
	_next_sequence = 1
	if not snapshot.is_empty() and str(snapshot.get("session_id", "")) == _session_id:
		_next_sequence = maxi(1, int(snapshot.get("next_sequence", 1)))
	return true


func clear() -> void:
	_session_id = ""
	_next_sequence = 1


func mint() -> String:
	if _session_id.is_empty():
		return ""
	var sequence := _next_sequence
	_next_sequence += 1
	return "%s:%s:%s" % [ID_PREFIX, _session_id, sequence]


func observe(instance_id: String) -> void:
	if _session_id.is_empty() or instance_id.is_empty():
		return
	var prefix := "%s:%s:" % [ID_PREFIX, _session_id]
	if not instance_id.begins_with(prefix):
		return
	var raw_sequence := instance_id.trim_prefix(prefix)
	if not raw_sequence.is_valid_int():
		return
	_next_sequence = maxi(_next_sequence, int(raw_sequence) + 1)


func observe_items(items: Array[ItemInstance]) -> void:
	for item: ItemInstance in items:
		if item != null:
			observe(item.instance_id)


func observe_equipment(equipped_items: Dictionary) -> void:
	for slot_id: Variant in equipped_items:
		var item: ItemInstance = equipped_items.get(slot_id)
		if item != null:
			observe(item.instance_id)


func snapshot() -> Dictionary:
	if _session_id.is_empty():
		return {}
	return {
		"session_id": _session_id,
		"next_sequence": _next_sequence,
	}
