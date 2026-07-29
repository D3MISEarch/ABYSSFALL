class_name VoidbringerCommandContract
extends RefCounted

const ACTIVE_SLOT_COUNT := 6
const BASIC_ATTACK_COMMAND: StringName = &"basic_attack"
const EVADE_COMMAND: StringName = &"evade"


func build_snapshot(
	active_slots: Array,
	closure_ability_id: StringName,
	ultimate_ability_id: StringName
) -> Dictionary:
	if active_slots.size() != ACTIVE_SLOT_COUNT:
		return {}
	var normalized_slots: Array[StringName] = []
	var seen: Dictionary = {}
	for raw_id: Variant in active_slots:
		var ability_id := StringName(str(raw_id))
		if ability_id == &"" or seen.has(ability_id):
			return {}
		seen[ability_id] = true
		normalized_slots.append(ability_id)
	if closure_ability_id != VoidbringerAbilityCatalog.CLOSURE:
		return {}
	if ultimate_ability_id == &"":
		return {}
	return {
		"active_slots": normalized_slots,
		"closure": closure_ability_id,
		"basic_attack": BASIC_ATTACK_COMMAND,
		"evade": EVADE_COMMAND,
		"ultimate": ultimate_ability_id,
	}


func debug_snapshot() -> Dictionary:
	return build_snapshot(
		[
			VoidbringerAbilityCatalog.MASS_BRAND,
			VoidbringerAbilityCatalog.NULL_SHARD,
			VoidbringerAbilityCatalog.WORLDSHEAR,
			VoidbringerAbilityCatalog.EVENT_STEP,
			VoidbringerAbilityCatalog.HARD_VACUUM,
			VoidbringerAbilityCatalog.CONVERGENCE,
		],
		VoidbringerAbilityCatalog.CLOSURE,
		VoidbringerAbilityCatalog.DEAD_STAR
	)


func is_valid_snapshot(snapshot: Dictionary) -> bool:
	var active_slots: Variant = snapshot.get("active_slots", [])
	if not active_slots is Array or (active_slots as Array).size() != ACTIVE_SLOT_COUNT:
		return false
	return (
		StringName(str(snapshot.get("closure", ""))) == VoidbringerAbilityCatalog.CLOSURE
		and StringName(str(snapshot.get("basic_attack", ""))) == BASIC_ATTACK_COMMAND
		and StringName(str(snapshot.get("evade", ""))) == EVADE_COMMAND
		and StringName(str(snapshot.get("ultimate", ""))) != &""
	)
