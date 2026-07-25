from __future__ import annotations

import base64
import hashlib
import io
import json
import shutil
import subprocess
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAYLOAD_DIR = ROOT / "tools" / "issue53_payload"
MANIFEST_PATH = ROOT / "tools" / "issue53_manifest.json"


def git_blob_sha(path: Path) -> str:
    data = path.read_bytes()
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()


def main() -> None:
    chunks = sorted(PAYLOAD_DIR.glob("chunk_*.txt"))
    if not chunks:
        raise SystemExit("No Issue 53 payload chunks found")
    encoded = "".join(path.read_text(encoding="utf-8") for path in chunks)
    archive = base64.b64decode(encoded)
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as bundle:
        bundle.extractall(ROOT)

    expected = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    mismatches: list[str] = []
    for relative_path, expected_sha in expected.items():
        path = ROOT / relative_path
        actual = git_blob_sha(path) if path.is_file() else "missing"
        if actual != expected_sha:
            mismatches.append(f"{relative_path}: expected {expected_sha}, got {actual}")
    if mismatches:
        raise SystemExit("Issue 53 payload verification failed:\n" + "\n".join(mismatches))

    shutil.rmtree(PAYLOAD_DIR)
    MANIFEST_PATH.unlink()
    Path(__file__).unlink()
    subprocess.run(["git", "status", "--short"], cwd=ROOT, check=True)


if __name__ == "__main__":
    main()
