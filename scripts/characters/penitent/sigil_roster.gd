extends RefCounted
class_name SigilRoster

signal changed(active_count: int, maximum_count: int)

var maximum_count := 3
var active_sigils: Array[Node] = []


func configure(new_maximum: int = 3) -> void:
	maximum_count = maxi(new_maximum, 1)
	_prune_invalid()
	while active_sigils.size() > maximum_count:
		active_sigils.pop_front()
	changed.emit(active_sigils.size(), maximum_count)


func register(sigil: Node) -> Node:
	_prune_invalid()
	if not is_instance_valid(sigil):
		return null
	active_sigils.erase(sigil)
	active_sigils.append(sigil)
	var evicted: Node = null
	if active_sigils.size() > maximum_count:
		evicted = active_sigils.pop_front()
	changed.emit(active_sigils.size(), maximum_count)
	return evicted


func remove(sigil: Node) -> void:
	_prune_invalid()
	var previous_count := active_sigils.size()
	active_sigils.erase(sigil)
	if active_sigils.size() != previous_count:
		changed.emit(active_sigils.size(), maximum_count)


func clear() -> Array[Node]:
	_prune_invalid()
	var removed: Array[Node] = active_sigils.duplicate()
	active_sigils.clear()
	changed.emit(0, maximum_count)
	return removed


func get_active_sigils() -> Array[Node]:
	_prune_invalid()
	return active_sigils.duplicate()


func get_snapshot() -> Dictionary:
	_prune_invalid()
	return {
		"active": active_sigils.size(),
		"maximum": maximum_count,
	}


func _prune_invalid() -> void:
	for index in range(active_sigils.size() - 1, -1, -1):
		if not is_instance_valid(active_sigils[index]):
			active_sigils.remove_at(index)
