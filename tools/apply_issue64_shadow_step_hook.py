from pathlib import Path

path = Path("scripts/player.gd")
text = path.read_text(encoding="utf-8")

replacements = [
    (
        'const GRASPING_RIFT_SCRIPT = preload("res://scripts/grasping_rift.gd")\n',
        'const GRASPING_RIFT_SCRIPT = preload("res://scripts/grasping_rift.gd")\n'
        'const SHADOW_STEP_VFX_SCRIPT = preload("res://scripts/shadow_step_vfx.gd")\n',
    ),
    (
        '\t\tif infected_step:\n'
        '\t\t\t_damage_enemies_around(dash_origin, 2.15, 20)\n'
        '\t\tmove_and_slide()\n'
        '\t\t_pulse_shadow_step()\n',
        '\t\tif infected_step:\n'
        '\t\t\t_damage_enemies_around(dash_origin, 2.15, 20)\n'
        '\t\t_spawn_shadow_step_vfx(dash_origin, dodge_direction, dodge_time)\n'
        '\t\tmove_and_slide()\n'
        '\t\t_pulse_shadow_step()\n',
    ),
    (
        'func _pulse_shadow_step() -> void:\n',
        'func _spawn_shadow_step_vfx(origin: Vector3, direction: Vector3, duration: float) -> void:\n'
        '\tif not is_instance_valid(get_tree().current_scene):\n'
        '\t\treturn\n'
        '\tvar effect = SHADOW_STEP_VFX_SCRIPT.new()\n'
        '\tif effect == null:\n'
        '\t\treturn\n'
        '\tget_tree().current_scene.add_child(effect)\n'
        '\teffect.setup(self, origin, direction, duration)\n\n\n'
        'func _pulse_shadow_step() -> void:\n',
    ),
]

for old, new in replacements:
    if text.count(old) != 1:
        raise SystemExit(f"Expected exactly one guarded player hook anchor, found {text.count(old)}")
    text = text.replace(old, new, 1)

path.write_text(text, encoding="utf-8")
Path(__file__).unlink()
