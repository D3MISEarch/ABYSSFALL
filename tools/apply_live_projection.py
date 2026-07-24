#!/usr/bin/env python3
from pathlib import Path
import base64, io, subprocess, tarfile

CHUNK_DIR = Path("tools/live_projection_payload")
EXPECTED = {'.github/workflows/persistent-level-flow-tests.yml': 'dd0f9a1c0685ce475e46f7bc40f57583741ecc9c', 'scripts/player.gd': '01ac8913d7b4cf9247fdf8861eba243699f0fa6f', 'scripts/characters/penitent_placeholder.gd': 'b68250610cc46eec03d3ccac9e3d70e80d801c09', 'scripts/characters/penitent_character.gd': 'c5d0265717aad4e14ddab58b6791022bf4d155fc', 'scripts/characters/void_warlock.gd': '22b89213f60e40b5bd52af6baa3509a4d4aa9c42', 'scripts/characters/penitent_playable.gd': '120d3e55c83718fc5199a014f28b140b2ee047a6', 'scripts/core/character_contract.gd': '67c04ca05d972b81138dec9932e36951f053e5dd', 'scripts/core/playable_combat_projection.gd': 'aa229335e50103375b76cc79ca15704c58b5e168', 'scripts/ui/playable_progression_bridge.gd': 'ce8fa5d2be1ed16c3918975f01fbb865bb11f6ef', 'scripts/multiclass_main.gd': '374ca30e28101f0f2331f2bcf9c2d1be1bd5a202', 'scripts/ui/class_tree_screen.gd': '134700b9d1718ce962df914555e8ea7894cc450d', 'tests/test_persistent_level_flow.gd': '4bc855e3de0be284fcaa4df427e243eba16540ed', 'tests/test_class_tree_screen.gd': 'f56323eaad6019c2c670a7f5b88c4cfc7ebecc3a', 'tests/test_playable_combat_projection.gd': '9462b98d3e8a771511e4f4b2be780e0447722d0c'}

payload = "".join(path.read_text().strip() for path in sorted(CHUNK_DIR.glob("chunk_*.txt")))
archive = base64.b64decode(payload)
with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as bundle:
    for member in bundle.getmembers():
        target = Path(member.name)
        if target.is_absolute() or ".." in target.parts:
            raise SystemExit(f"unsafe archive path: {member.name}")
    bundle.extractall(".", filter="data")

for path, expected in EXPECTED.items():
    actual = subprocess.check_output(["git", "hash-object", path], text=True).strip()
    if actual != expected:
        raise SystemExit(f"hash mismatch for {path}: {actual} != {expected}")

Path(".github/workflows/apply-live-projection.yml").unlink(missing_ok=True)
for chunk in CHUNK_DIR.glob("chunk_*.txt"):
    chunk.unlink()
CHUNK_DIR.rmdir()
Path("tools/apply_live_projection.py").unlink(missing_ok=True)
try:
    Path("tools").rmdir()
except OSError:
    pass
print(f"Applied and verified {len(EXPECTED)} live-projection files")
