from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / "scripts" / "multiclass_main.gd"
text = path.read_text(encoding="utf-8")
old = '\tif not progression_bridge.configure_persistent(selected_class_id, Persistence, build_name):\n'
new = (
    '\tvar persistence_service := get_node_or_null("/root/Persistence") as PersistenceService\n'
    '\tif persistence_service == null or not progression_bridge.configure_persistent(selected_class_id, persistence_service, build_name):\n'
)
if text.count(old) != 1:
    raise SystemExit(f"Expected exactly one Persistence binding, found {text.count(old)}")
path.write_text(text.replace(old, new), encoding="utf-8")
Path(__file__).unlink()
