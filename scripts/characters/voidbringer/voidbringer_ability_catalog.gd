class_name VoidbringerAbilityCatalog
extends RefCounted

const CLOSURE: StringName = &"vb.action.closure"
const MASS_BRAND: StringName = &"vb.skill.mass_brand"
const NULL_SHARD: StringName = &"vb.skill.null_shard"
const WORLDSHEAR: StringName = &"vb.skill.worldshear"
const EVENT_STEP: StringName = &"vb.skill.event_step"
const HARD_VACUUM: StringName = &"vb.skill.hard_vacuum"
const CONVERGENCE: StringName = &"vb.skill.convergence"
const DEAD_STAR: StringName = &"vb.ultimate.dead_star"

const FOUNDATION_ACTIVE_IDS := [
	MASS_BRAND,
	NULL_SHARD,
	WORLDSHEAR,
	EVENT_STEP,
	HARD_VACUUM,
]


func all_stable_ids() -> Array[StringName]:
	return [
		CLOSURE,
		MASS_BRAND,
		NULL_SHARD,
		WORLDSHEAR,
		EVENT_STEP,
		HARD_VACUUM,
		CONVERGENCE,
		DEAD_STAR,
	]


func mass_brand_definition() -> AbilityDefinition:
	return AbilityDefinition.new(
		MASS_BRAND,
		&"corruption",
		0.0,
		0.0,
		&"active",
		2,
		4.0,
		5.0,
		[&"spatial", &"projectile", &"anchor_create"]
	)


func null_shard_definition() -> AbilityDefinition:
	return AbilityDefinition.new(
		NULL_SHARD,
		&"corruption",
		0.0,
		0.0,
		&"active",
		0,
		0.0,
		4.0,
		[&"spatial", &"projectile", &"fold_line_interaction"]
	)


func closure_definition() -> AbilityDefinition:
	return AbilityDefinition.new(
		CLOSURE,
		&"corruption",
		0.0,
		0.7,
		&"closure",
		0,
		0.0,
		0.0,
		[&"spatial", &"anchor_consume"]
	)


func definition_for(ability_id: StringName) -> AbilityDefinition:
	match ability_id:
		MASS_BRAND:
			return mass_brand_definition()
		NULL_SHARD:
			return null_shard_definition()
		CLOSURE:
			return closure_definition()
	return null
