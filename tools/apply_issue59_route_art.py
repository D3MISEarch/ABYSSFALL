from __future__ import annotations

import base64
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAYLOAD = ROOT / "tools" / "issue59_route_art_payload"
EXPECTED = {
    "scripts/art/sunken_crypts_art_pass0.gd": "2aa87c260bc091208a567a4d7501f67071326807f4a835ba86a2ca1624b8893a",
    "tests/test_art_pass0_visual_contract.gd": "8b35d58265fca1ba6de574ab7f5e17f1ea2c8ca528d06a2d70646dd863fd60eb",
}
DOC_CLEANUP = [
    "ISSUE_59_CORRECTED_BUILD_NOTE.md", "ISSUE_59_CORRECTED_HEAD.md",
    "ISSUE_59_CORRECTED_OWNER_GATE.md", "ISSUE_59_CORRECTED_SUMMARY.md",
    "ISSUE_59_CORRECTION_SCOPE.md", "ISSUE_59_DO_NOT_APPROVE_OLD_BUILD.md",
    "ISSUE_59_OWNER_FEEDBACK.md", "ISSUE_59_OWNER_VISUAL_PLAYTEST.md",
    "ISSUE_59_RETEST_GATE.md", "ISSUE_59_RETEST_REQUIRED.md",
    "ISSUE_59_VISIBLE_DIFFERENCE_REQUIREMENT.md", "ISSUE_59_VISUAL_GATE_CORRECTION.md",
    "ISSUE_59_VISUAL_GATE_STATUS.md",
]

encoded = "".join(path.read_text(encoding="utf-8").strip() for path in sorted(PAYLOAD.glob("payload.*")))
payload = json.loads(gzip.decompress(base64.b64decode(encoded)).decode("utf-8"))
for relative, expected_sha in EXPECTED.items():
    content = payload.get(relative)
    if not isinstance(content, str):
        raise SystemExit(f"Missing payload target: {relative}")
    digest = hashlib.sha256(content.encode("utf-8")).hexdigest()
    if digest != expected_sha:
        raise SystemExit(f"Hash mismatch for {relative}: {digest} != {expected_sha}")
    target = ROOT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")

roadmap = ROOT / "Docs" / "Roadmap"
for name in DOC_CLEANUP:
    path = roadmap / name
    if path.exists():
        path.unlink()

for path in sorted(PAYLOAD.rglob("*"), reverse=True):
    if path.is_file():
        path.unlink()
    elif path.is_dir():
        path.rmdir()
if PAYLOAD.exists():
    PAYLOAD.rmdir()
Path(__file__).unlink()
