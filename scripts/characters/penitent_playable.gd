extends "res://scripts/characters/penitent_character.gd"
class_name PenitentPlayable

const MARTYRS_CHAIN_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/martyrs_chain_controller.gd")
const ASHEN_PROCESSION_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/ashen_procession_controller.gd")
const SACRAMENT_CONTROLLER_SCRIPT = preload("res://scripts/characters/penitent/sacrament_controller.gd")

var martyrs_chain_controller: MartyrsChainController
var ashen_procession_controller: AshenProcessionController
var sacrament_controller: SacramentController


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


func _place_seal_of_binding() -> void:
	if not spend_fervor(SEAL_OF_BINDING_COST):
		ability_message.emit("SEAL OF BINDING REQUIRES %d FERVOR" % int(SEAL_OF_BINDING_COST))
		return

	var scene_root := get_tree().current_scene as Node3D
	if not is_instance_valid(scene_root):
		scene_root = get_parent() as Node3D
	if not is_instance_valid(scene_root):
		add_fervor(SEAL_OF_BINDING_COST)
		ability_message.emit("SEAL OF BINDING FINDS NO GROUND")
		return

	var seal := SEAL_OF_BINDING_SCRIPT.new() as SealOfBinding
	seal.name = "SealOfBinding"
	seal.configure(self, SEAL_OF_BINDING_RADIUS, SEAL_OF_BINDING_LIFETIME)
	seal.expired.connect(_on_seal_expired)

	# SealOfBinding performs its first pulse in _ready(). Assign its local
	# transform before add_child() so that pulse occurs at the intended point,
	# never at world origin for one frame.
	var spawn_global := global_position + facing * 3.0
	spawn_global.y = 0.07
	seal.position = scene_root.to_local(spawn_global)
	scene_root.add_child(seal)

	var evicted := sigil_roster.register(seal)
	if is_instance_valid(evicted) and evicted.has_method("dismiss"):
		evicted.dismiss("replaced")
	set_combat_active(true)
	ability_message.emit("SEAL OF BINDING CARVED")
