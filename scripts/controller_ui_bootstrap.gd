extends Node

const CONTROLLER_UI_INPUT_MAP = preload("res://scripts/core/controller_ui_input_map.gd")


func _ready() -> void:
	CONTROLLER_UI_INPUT_MAP.install_defaults()
