extends "res://scripts/characters/penitent_character.gd"
class_name PenitentPlayable

const MARTYRS_CHAIN_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/martyrs_chain_controller.gd")
const ASHEN_PROCESSION_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/ashen_procession_controller.gd")

var martyrs_chain_controller: MartyrsChainController
var ashen_procession_controller: AshenProcessionController


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
