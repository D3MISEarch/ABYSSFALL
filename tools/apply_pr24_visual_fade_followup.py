from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"Expected patch block missing from {path}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


penitent = ROOT / "scripts/characters/penitent_character.gd"
replace_once(
    penitent,
    '''\tpulse.material_override = material
\ttarget.add_child(pulse)
\tvar tween := pulse.create_tween()
\ttween.set_parallel(true)
\ttween.tween_property(pulse, "scale", Vector3.ONE * 1.35, 0.18)
\ttween.tween_property(pulse, "modulate:a", 0.0, 0.18)
\ttween.chain().tween_callback(pulse.queue_free)''',
    '''\tpulse.material_override = material
\ttarget.add_child(pulse)
\tvar faded_color := material.albedo_color
\tfaded_color.a = 0.0
\tvar tween := pulse.create_tween()
\ttween.set_parallel(true)
\ttween.tween_property(pulse, "scale", Vector3.ONE * 1.35, 0.18)
\ttween.tween_property(material, "albedo_color", faded_color, 0.18)
\ttween.chain().tween_callback(pulse.queue_free)''',
)
replace_once(
    penitent,
    '''\tvar pulse := MeshInstance3D.new()
\tvar sphere := SphereMesh.new()
\tsphere.radius = 0.34''',
    '''\tvar pulse := MeshInstance3D.new()
\tpulse.name = "BrandPulse"
\tvar sphere := SphereMesh.new()
\tsphere.radius = 0.34''',
)
replace_once(
    penitent,
    '''\tpulse.material_override = material
\ttarget.add_child(pulse)
\tvar tween := pulse.create_tween()
\ttween.set_parallel(true)
\ttween.tween_property(pulse, "scale", Vector3.ONE * maximum_scale, 0.24)
\ttween.tween_property(pulse, "modulate:a", 0.0, 0.24)
\ttween.chain().tween_callback(pulse.queue_free)''',
    '''\tpulse.material_override = material
\ttarget.add_child(pulse)
\tvar faded_color := material.albedo_color
\tfaded_color.a = 0.0
\tvar tween := pulse.create_tween()
\ttween.set_parallel(true)
\ttween.tween_property(pulse, "scale", Vector3.ONE * maximum_scale, 0.24)
\ttween.tween_property(material, "albedo_color", faded_color, 0.24)
\ttween.chain().tween_callback(pulse.queue_free)''',
)

brute = ROOT / "scripts/crypt_brute.gd"
replace_once(
    brute,
    '''\tring.material_override = _material(Color(0.31, 0.75, 0.05), true)
\tadd_child(ring)
\tvar tween := create_tween()
\ttween.tween_property(ring, "scale", Vector3(3.0, 3.0, 3.0), 0.22)
\ttween.tween_property(ring, "modulate:a", 0.0, 0.12)
\ttween.tween_callback(ring.queue_free)''',
    '''\tvar ring_material := _material(Color(0.31, 0.75, 0.05, 0.82), true)
\tring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
\tring.material_override = ring_material
\tadd_child(ring)
\tvar faded_color := ring_material.albedo_color
\tfaded_color.a = 0.0
\tvar tween := create_tween()
\ttween.tween_property(ring, "scale", Vector3(3.0, 3.0, 3.0), 0.22)
\ttween.tween_property(ring_material, "albedo_color", faded_color, 0.12)
\ttween.tween_callback(ring.queue_free)''',
)

agents = ROOT / "AGENTS.md"
text = agents.read_text(encoding="utf-8")
marker = "\n## Documentation ownership\n"
entry = '''
### 3D material fades and invalid CanvasItem properties

Observed failures:

- Tweening `modulate` or `modulate:a` on `MeshInstance3D`. Those properties belong to `CanvasItem`/2D nodes, so Godot logs a runtime error and drops the tween track.
- Assertion-only test scripts can still print `passed` and exit zero while Godot has emitted an engine-level runtime error.

Prevention:

- Fade a unique `StandardMaterial3D` resource through `albedo_color` alpha, with material transparency enabled.
- Do not apply CanvasItem-only visual properties to Node3D-derived objects.
- Avoid tweening a shared material unless every mesh using it is intended to fade together.
- Capture headless test output and fail CI on Godot parser, script, runtime, invalid-property, or engine error lines.

Regression expectation:

- Spawn the real 3D feedback effect under test and assert that its material alpha decreases before cleanup.
- A test suite is not considered passing when assertion counts are green but the Godot log contains runtime errors.
'''
if entry.strip() not in text:
    if marker not in text:
        raise RuntimeError("AGENTS.md insertion marker missing")
    agents.write_text(text.replace(marker, "\n" + entry + marker, 1), encoding="utf-8")

ritual_test = ROOT / "tests/test_ritual_blade.gd"
replace_once(
    ritual_test,
    '''\t_test_damage_sequence()
\t_test_canonical_attack_hits_readable_range()
\t_test_attack_visual_exists_on_miss()''',
    '''\t_test_damage_sequence()
\tawait _test_canonical_attack_hits_readable_range_and_fades()
\tawait _test_brand_pulse_material_fades()
\t_test_attack_visual_exists_on_miss()''',
)
replace_once(
    ritual_test,
    "func _test_canonical_attack_hits_readable_range() -> void:",
    "func _test_canonical_attack_hits_readable_range_and_fades() -> void:",
)
replace_once(
    ritual_test,
    '''\tvar snapshot: Dictionary = penitent.get_ritual_blade_snapshot()
\t_assert_equal(int(snapshot.get("hits", 0)), 1, "Attack snapshot records the hit")
\t_assert_equal(int(snapshot.get("combo_step", 0)), 1, "Attack snapshot records combo step one")

\tcurrent_scene = previous_scene
\tworld.free()


func _test_attack_visual_exists_on_miss() -> void:''',
    '''\tvar snapshot: Dictionary = penitent.get_ritual_blade_snapshot()
\t_assert_equal(int(snapshot.get("hits", 0)), 1, "Attack snapshot records the hit")
\t_assert_equal(int(snapshot.get("combo_step", 0)), 1, "Attack snapshot records combo step one")

\tvar hit_visual := front_target.get_node_or_null("RitualBladeHit") as MeshInstance3D
\t_assert_true(is_instance_valid(hit_visual), "A successful hit creates an impact pulse")
\tif is_instance_valid(hit_visual):
\t\tvar hit_material := hit_visual.material_override as StandardMaterial3D
\t\t_assert_true(is_instance_valid(hit_material), "Impact pulse owns a 3D fade material")
\t\tif is_instance_valid(hit_material):
\t\t\tvar starting_alpha := hit_material.albedo_color.a
\t\t\tawait create_timer(0.08).timeout
\t\t\t_assert_true(
\t\t\t\thit_material.albedo_color.a < starting_alpha,
\t\t\t\t"Impact pulse fades its material alpha before cleanup"
\t\t\t)

\tcurrent_scene = previous_scene
\tworld.free()


func _test_brand_pulse_material_fades() -> void:
\tvar previous_scene := current_scene
\tvar world := Node3D.new()
\tworld.name = "BrandPulseWorld"
\troot.add_child(world)
\tcurrent_scene = world

\tvar penitent := PENITENT_CHARACTER_SCRIPT.new() as PenitentCharacter
\tworld.add_child(penitent)
\tvar target := DummyEnemy.new()
\tworld.add_child(target)
\tpenitent._spawn_brand_pulse(target, Color(0.82, 0.025, 0.045), 1.65)

\tvar brand_visual := target.get_node_or_null("BrandPulse") as MeshInstance3D
\t_assert_true(is_instance_valid(brand_visual), "Brand of Ruin creates a named 3D pulse")
\tif is_instance_valid(brand_visual):
\t\tvar brand_material := brand_visual.material_override as StandardMaterial3D
\t\t_assert_true(is_instance_valid(brand_material), "Brand pulse owns a 3D fade material")
\t\tif is_instance_valid(brand_material):
\t\t\tvar starting_alpha := brand_material.albedo_color.a
\t\t\tawait create_timer(0.10).timeout
\t\t\t_assert_true(
\t\t\t\tbrand_material.albedo_color.a < starting_alpha,
\t\t\t\t"Brand pulse fades its material alpha before cleanup"
\t\t\t)

\tcurrent_scene = previous_scene
\tworld.free()


func _test_attack_visual_exists_on_miss() -> void:''',
)

for path in (penitent, brute, agents, ritual_test):
    text = path.read_text(encoding="utf-8")
    if path.name != "AGENTS.md" and '"modulate:a"' in text:
        raise RuntimeError(f"Invalid 3D modulate tween remains in {path}")

print("PR #24 visual fade follow-up applied.")
