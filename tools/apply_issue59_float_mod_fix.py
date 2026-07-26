from pathlib import Path

path = Path("scripts/art/sunken_crypts_art_pass0.gd")
text = path.read_text(encoding="utf-8")
replacements = {
    "Vector3(float(i * 17) % 30.0, float(i * 47) % 180.0, float(i * 23) % 25.0)": "Vector3(float((i * 17) % 30), float((i * 47) % 180), float((i * 23) % 25))",
    "Vector3(90.0, float(i * 37) % 180.0, 18.0)": "Vector3(90.0, float((i * 37) % 180), 18.0)",
}
for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"Issue #59 float-modulo anchor missing: {old}")
    text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
Path(__file__).unlink()
