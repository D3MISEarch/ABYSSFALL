extends "res://scripts/characters/penitent_character.gd"
class_name PenitentPlayable

const MARTYRS_CHAIN_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/martyrs_chain_controller.gd")
const ASHEN_PROCESSION_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/ashen_procession_controller.gd")
const SACRAMENT_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/sacrament_controller.gd")
const PERSISTENT_LEVEL_RULES = preload("res://scripts/core/persistent_level_rules.gd")
const PLAYABLE_COMBAT_PROJECTION = preload("res://scripts/core/playable_combat_projection.gd")

var martyrs_chain_controller: MartyrsChainController
var ashen_procession_controller: AshenProcessionController
var sacrament_controller: SacramentController
var class_tree_combat := PLAYABLE_COMBAT_PROJECTION.new() as PlayableCombatProjection


func _ready() -> void:
	super._ready()
	martyrs_chain_controller = MARTYRS_CHAIN_CONTROLLER_SCRIPT.new() as MartyrsChainController
	martyrs_chain_controller.name = "MartyrsChainController"
	add_child(martyrs_chain_controller)
	martyrs_chain_controller.bind_to(self)

	ashen_procession_controller = ASHEN_PROCESSION_CONTROLLER_SCRIPT.new() as AshenProcessionController
	ashen_procession_controller.name = "AshenProcessionController"
	add_child(ashen_procession_controller)
	ashen_procession_controller.bind_to(self)

	sacrament_controller = SACRAMENT_CONTROLLER_SCRIPT.new() as SacramentController
	sacrament_controller.name = "SacramentController"
	add_child(sacrament_controller)
	sacrament_controller.bind_to(self)


func add_experience(amount: int) -> void:
	PERSISTENT_LEVEL_RULES.apply_experience(self, amount)


func restore_persistent_progression(saved_level: int, saved_experience: int) -> void:
	PERSISTENT_LEVEL_RULES.restore(self, saved_level, saved_experience)


func apply_class_tree_projection(snapshot: Dictionary) -> void:
	class_tree_combat.configure(snapshot)


func get_class_tree_combat_snapshot() -> Dictionary:
	return class_tree_combat.snapshot()


func _resolve_outgoing_damage(base_damage: int) -> int:
	return class_tree_combat.resolve_outgoing_damage(base_damage)


func _resolve_incoming_damage(base_damage: int) -> int:
	return class_tree_combat.resolve_incoming_damage(base_damage)
