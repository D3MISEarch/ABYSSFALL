extends "res://scripts/multiclass_main.gd"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_physics_process(false)


func install_dependencies(menu: GameplayPauseMenu, bridge: PlayableProgressionBridge) -> void:
	pause_menu = menu
	progression_bridge = bridge
	add_child(menu)
	add_child(bridge)
