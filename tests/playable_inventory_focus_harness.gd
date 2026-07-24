extends "res://scripts/main.gd"


func _ready() -> void:
	# Test harness: assemble only the inventory UI under test and keep the
	# inherited gameplay loop completely dormant.
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
