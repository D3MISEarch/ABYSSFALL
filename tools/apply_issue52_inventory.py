#!/usr/bin/env python3
import base64
import io
import pathlib
import shutil
import subprocess
import tarfile

EXPECTED = {'Docs/Architecture/ARCHITECTURE.md': '426f49acb8a44ec1def4e7080158b8a4c569fb9b', 'Docs/Standards/TESTING.md': 'b6a1f4f2b381cdd1c50ca8b068753c430e8bc40a', 'scripts/characters/penitent_playable.gd': 'd58dbc09c3db2bb3f5403bc4ccd09c6221ded5e7', 'scripts/characters/void_warlock.gd': '561a7d042d807f783fcdf651a90f64a25f9da923', 'scripts/core/character_contract.gd': '09701a2c4f00c17a239a19bf670c3b1250ca71e0', 'scripts/core/playable_item_catalog.gd': '56f11600a815451365a47751ca7bdd3e5c3efd83', 'scripts/item_pickup.gd': 'cd548fb84a32eea768e3fb99eb2c720cdd9f913b', 'scripts/main.gd': '9ae301ba8d0f36fa910b00096f4329127046744b', 'scripts/multiclass_main.gd': '08d91570b4b00e1b19a1b774c3b96428aee990bd', 'scripts/ui/playable_inventory_bridge.gd': 'a5e6d74d90320236969475401a9b4867b5c187c3', 'scripts/ui/playable_progression_bridge.gd': 'cc5dfbae892c1f4c871020ac551b5c75e495564a', 'tests/test_playable_inventory_persistence.gd': 'eef49cf1b394500bb9e107611443400773aaa8de'}
ROOT = pathlib.Path(__file__).resolve().parents[1]
CHUNKS = ROOT / "tools" / "issue52_payload"
payload = "".join(path.read_text(encoding="ascii") for path in sorted(CHUNKS.glob("chunk*.txt")))
archive = base64.b64decode(payload)
with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as tar:
    for member in tar.getmembers():
        target = (ROOT / member.name).resolve()
        if ROOT.resolve() not in target.parents:
            raise SystemExit(f"unsafe payload path: {member.name}")
    tar.extractall(ROOT)
for path, expected in EXPECTED.items():
    actual = subprocess.check_output(["git", "hash-object", path], cwd=ROOT, text=True).strip()
    if actual != expected:
        raise SystemExit(f"hash mismatch for {path}: {actual} != {expected}")
print(f"Applied and verified {len(EXPECTED)} Issue #52 files")
shutil.rmtree(CHUNKS)
pathlib.Path(__file__).unlink()
