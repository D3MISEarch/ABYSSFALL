from pathlib import Path

MAIN_PATH = Path("scripts/main.gd")
text = MAIN_PATH.read_text(encoding="utf-8")

replacements = [
    (
        'const PLAYABLE_ITEM_CATALOG = preload("res://scripts/core/playable_item_catalog.gd")\n',
        'const PLAYABLE_ITEM_CATALOG = preload("res://scripts/core/playable_item_catalog.gd")\n'
        'const SUNKEN_CRYPTS_ART_PASS0_SCRIPT = preload("res://scripts/art/sunken_crypts_art_pass0.gd")\n',
    ),
    (
        'var relic_altar: Node3D\n',
        'var relic_altar: Node3D\nvar sunken_crypts_art_pass0: SunkenCryptsArtPass0\n',
    ),
    (
        '\t_build_arena()\n\t_build_hud()\n',
        '\t_build_arena()\n\t_install_sunken_crypts_art_pass0()\n\t_build_hud()\n',
    ),
    (
        '\tdisc.mesh = disc_mesh\n'
        '\tdisc.position = center + Vector3(0.0, 0.04, 0.0)\n'
        '\tdisc.material_override = _make_material(\n'
        '\t\tColor(glow_color.r * 0.18, glow_color.g * 0.18, glow_color.b * 0.18), true\n'
        '\t)\n',
        '\tdisc.name = "RoomFoundationDisc_%d" % int(abs(center.z))\n'
        '\tdisc.mesh = disc_mesh\n'
        '\tdisc.position = center + Vector3(0.0, 0.025, 0.0)\n'
        '\tdisc.material_override = _make_material(\n'
        '\t\tColor(glow_color.r * 0.055, glow_color.g * 0.055, glow_color.b * 0.055), false\n'
        '\t)\n',
    ),
    ('\t\tlight.light_energy = 1.35\n', '\t\tlight.light_energy = 0.72\n'),
]

for old, new in replacements:
    if old not in text:
        raise SystemExit(f"Required Issue #59 patch anchor missing: {old!r}")
    text = text.replace(old, new, 1)

installer = '''\n\nfunc _install_sunken_crypts_art_pass0() -> void:\n\tif sunken_crypts_art_pass0 != null:\n\t\treturn\n\tsunken_crypts_art_pass0 = SUNKEN_CRYPTS_ART_PASS0_SCRIPT.new() as SunkenCryptsArtPass0\n\tif sunken_crypts_art_pass0 == null:\n\t\tpush_error("Could not create Sunken Crypts Art Pass 0 controller.")\n\t\treturn\n\tadd_child(sunken_crypts_art_pass0)\n\tif not sunken_crypts_art_pass0.install(self):\n\t\tpush_error("Could not install Sunken Crypts Art Pass 0 controller.")\n'''
marker = '\n\nfunc _create_gate(gate_name: String, position_value: Vector3) -> StaticBody3D:\n'
if marker not in text:
    raise SystemExit("Issue #59 installer insertion marker missing")
text = text.replace(marker, installer + marker, 1)

MAIN_PATH.write_text(text, encoding="utf-8")
Path(__file__).unlink()
