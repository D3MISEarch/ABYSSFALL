class_name VoidbringerAnchorManager
extends RefCounted

signal anchor_created(anchor: Dictionary)
signal anchor_updated(anchor: Dictionary)
signal anchor_removed(anchor_id: StringName, reason: StringName)

const CARRIER_ENEMY: StringName = &"enemy"
const CARRIER_TERRAIN: StringName = &"terrain"
const CARRIER_CORPSE: StringName = &"corpse"
const CARRIER_SELF: StringName = &"self"

const STAGE_DORMANT: StringName = &"dormant"
const STAGE_DENSE: StringName = &"dense"
const STAGE_CRITICAL: StringName = &"critical"

const PLACEMENT_OK: StringName = &"ok"
const REASON_CARRIER_TYPE_NOT_ALLOWED: StringName = &"carrier_type_not_allowed"
const REASON_CARRIER_INVALIDATED: StringName = &"carrier_invalidated"

const ENEMY_DURATION := 12.0
const TERRAIN_DURATION := 18.0
const CORPSE_DURATION := 8.0
const SELF_DURATION := 12.0

var owner_level: int = 1
var allow_self_anchors := false
var _next_serial: int = 1
var _anchors: Dictionary = {}
var _order: Array[StringName] = []


func configure(p_owner_level: int, p_allow_self_anchors: bool = false) -> void:
	owner_level = maxi(1, p_owner_level)
	allow_self_anchors = p_allow_self_anchors
	_enforce_capacity()


func capacity() -> int:
	return 3 if owner_level >= 5 else 2


func validate_placement(carrier_type: StringName, carrier: Variant) -> StringName:
	if not _carrier_type_is_allowed(carrier_type):
		return REASON_CARRIER_TYPE_NOT_ALLOWED
	if not _carrier_is_valid(carrier_type, carrier):
		return REASON_CARRIER_INVALIDATED
	return PLACEMENT_OK


func place_anchor(
	carrier_type: StringName,
	carrier: Variant,
	position: Vector3,
	mass: float = 0.0,
	metadata: Dictionary = {}
) -> Dictionary:
	if validate_placement(carrier_type, carrier) != PLACEMENT_OK:
		return {}
	while _order.size() >= capacity():
		remove_anchor(_order.front(), &"capacity_replacement")

	var anchor_id := StringName("vb.anchor.%04d" % _next_serial)
	_next_serial += 1
	var anchor := {
		"anchor_id": anchor_id,
		"carrier_type": carrier_type,
		"carrier_ref": weakref(carrier) if carrier is Object else null,
		"position": position,
		"mass": clampf(mass, 0.0, 100.0),
		"mass_stage": mass_stage(mass),
		"remaining_seconds": _duration_for(carrier_type),
		"created_serial": _next_serial - 1,
		"metadata": metadata.duplicate(true),
	}
	_anchors[anchor_id] = anchor
	_order.append(anchor_id)
	anchor_created.emit(_public_snapshot(anchor))
	return _public_snapshot(anchor)


func add_mass(anchor_id: StringName, amount: float) -> Dictionary:
	if not _anchors.has(anchor_id):
		return {}
	var anchor: Dictionary = _anchors[anchor_id]
	anchor["mass"] = clampf(float(anchor.get("mass", 0.0)) + amount, 0.0, 100.0)
	anchor["mass_stage"] = mass_stage(float(anchor["mass"]))
	_anchors[anchor_id] = anchor
	anchor_updated.emit(_public_snapshot(anchor))
	return _public_snapshot(anchor)


func set_mass(anchor_id: StringName, amount: float) -> Dictionary:
	if not _anchors.has(anchor_id):
		return {}
	var anchor: Dictionary = _anchors[anchor_id]
	anchor["mass"] = clampf(amount, 0.0, 100.0)
	anchor["mass_stage"] = mass_stage(float(anchor["mass"]))
	_anchors[anchor_id] = anchor
	anchor_updated.emit(_public_snapshot(anchor))
	return _public_snapshot(anchor)


func tick(delta: float) -> void:
	var step := maxf(delta, 0.0)
	if step <= 0.0:
		return
	for anchor_id: StringName in _order.duplicate():
		if not _anchors.has(anchor_id):
			continue
		var anchor: Dictionary = _anchors[anchor_id]
		var carrier_type: StringName = anchor.get("carrier_type", &"")
		var carrier_ref: WeakRef = anchor.get("carrier_ref") as WeakRef
		var carrier: Object = carrier_ref.get_ref() if carrier_ref != null else null
		if not _carrier_is_valid(carrier_type, carrier):
			remove_anchor(anchor_id, REASON_CARRIER_INVALIDATED)
			continue
		if carrier is Node3D:
			anchor["position"] = (carrier as Node3D).global_position
		anchor["remaining_seconds"] = maxf(float(anchor.get("remaining_seconds", 0.0)) - step, 0.0)
		if float(anchor["remaining_seconds"]) <= 0.0:
			remove_anchor(anchor_id, &"expired")
			continue
		_anchors[anchor_id] = anchor


func remove_anchor(anchor_id: StringName, reason: StringName = &"removed") -> bool:
	if not _anchors.has(anchor_id):
		return false
	_anchors.erase(anchor_id)
	_order.erase(anchor_id)
	anchor_removed.emit(anchor_id, reason)
	return true


func clear(reason: StringName = &"teardown") -> void:
	for anchor_id: StringName in _order.duplicate():
		remove_anchor(anchor_id, reason)
	_anchors.clear()
	_order.clear()


func active_count() -> int:
	return _order.size()


func has_anchor(anchor_id: StringName) -> bool:
	return _anchors.has(anchor_id)


func get_anchor(anchor_id: StringName) -> Dictionary:
	if not _anchors.has(anchor_id):
		return {}
	return _public_snapshot(_anchors[anchor_id])


func active_anchors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for anchor_id: StringName in _order:
		if _anchors.has(anchor_id):
			result.append(_public_snapshot(_anchors[anchor_id]))
	return result


func mass_stage(mass: float) -> StringName:
	var clamped := clampf(mass, 0.0, 100.0)
	if clamped >= 70.0:
		return STAGE_CRITICAL
	if clamped >= 35.0:
		return STAGE_DENSE
	return STAGE_DORMANT


func _carrier_type_is_allowed(carrier_type: StringName) -> bool:
	if carrier_type == CARRIER_SELF:
		return allow_self_anchors
	return carrier_type in [CARRIER_ENEMY, CARRIER_TERRAIN, CARRIER_CORPSE]


func _carrier_is_valid(carrier_type: StringName, carrier: Variant) -> bool:
	if carrier_type == CARRIER_TERRAIN and carrier == null:
		return true
	if not carrier is Object or not is_instance_valid(carrier):
		return false
	if carrier_type == CARRIER_ENEMY and _object_has_property(carrier as Object, &"alive"):
		return bool((carrier as Object).get("alive"))
	return true


func _object_has_property(object: Object, property_name: StringName) -> bool:
	if object == null:
		return false
	for property: Dictionary in object.get_property_list():
		if StringName(str(property.get("name", ""))) == property_name:
			return true
	return false


func _duration_for(carrier_type: StringName) -> float:
	match carrier_type:
		CARRIER_ENEMY:
			return ENEMY_DURATION
		CARRIER_TERRAIN:
			return TERRAIN_DURATION
		CARRIER_CORPSE:
			return CORPSE_DURATION
		CARRIER_SELF:
			return SELF_DURATION
	return 0.0


func _enforce_capacity() -> void:
	while _order.size() > capacity():
		remove_anchor(_order.front(), &"capacity_downgrade")


func _public_snapshot(anchor: Dictionary) -> Dictionary:
	return {
		"anchor_id": anchor.get("anchor_id", &""),
		"carrier_type": anchor.get("carrier_type", &""),
		"position": anchor.get("position", Vector3.ZERO),
		"mass": float(anchor.get("mass", 0.0)),
		"mass_stage": anchor.get("mass_stage", STAGE_DORMANT),
		"remaining_seconds": float(anchor.get("remaining_seconds", 0.0)),
		"created_serial": int(anchor.get("created_serial", 0)),
		"metadata": (anchor.get("metadata", {}) as Dictionary).duplicate(true),
	}
