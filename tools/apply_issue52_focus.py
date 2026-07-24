#!/usr/bin/env python3
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    "scripts/main.gd": "0e79d7348aa0ef5ff6bbff0bd4fd997c4dadefd3",
    "scripts/multiclass_main.gd": "c17a554aad967e820799ec69231b7ded0b056a9a",
    "tests/test_playable_inventory_persistence.gd": "895e63153e34908cf549951a73b7f821d6ea9096",
    "tests/playable_inventory_focus_harness.gd": "2a77d285a694d2cf09acc75e9207eb6dba307353",
    "Docs/Standards/TESTING.md": "dfef75287e9778185c7ca8e0f3a0642af0e711e7",
}

def replace_once(path: str, old: str, new: str) -> None:
    target = ROOT / path
    text = target.read_text(encoding="utf-8")
    if text.count(old) != 1:
        raise SystemExit(f"expected one replacement in {path}, found {text.count(old)}")
    target.write_text(text.replace(old, new, 1), encoding="utf-8")

replace_once(
    "scripts/main.gd",
    "var inventory_backpack_box: VBoxContainer\nvar skill_panel: Control",
    "var inventory_backpack_box: VBoxContainer\nvar inventory_item_buttons: Array[Button] = []\nvar inventory_focus_index := 0\nvar skill_panel: Control",
)
replace_once(
    "scripts/main.gd",
    "\tif inventory_panel.visible:\n\t\t_refresh_inventory()\n\t_update_pause_state()\n\n\nfunc _toggle_skill_tree()",
    "\tif inventory_panel.visible:\n\t\t_refresh_inventory()\n\t\t_focus_inventory_item_deferred()\n\t_update_pause_state()\n\n\nfunc _toggle_skill_tree()",
)
replace_once(
    "scripts/main.gd",
    "\t_clear_container(inventory_equipment_box)\n\t_clear_container(inventory_backpack_box)\n\tvar snapshot: Dictionary = player.get_inventory_snapshot()",
    "\tvar focus_owner := get_viewport().gui_get_focus_owner()\n\tif focus_owner is Button and inventory_item_buttons.has(focus_owner):\n\t\tinventory_focus_index = inventory_item_buttons.find(focus_owner)\n\tinventory_item_buttons.clear()\n\t_clear_container(inventory_equipment_box)\n\t_clear_container(inventory_backpack_box)\n\tvar snapshot: Dictionary = player.get_inventory_snapshot()",
)
replace_once(
    "scripts/main.gd",
    '"BACKPACK  %d / %d   — CLICK AN ITEM TO EQUIP"',
    '"BACKPACK  %d / %d   — SELECT AN ITEM TO EQUIP"',
)
replace_once(
    "scripts/main.gd",
    '''\t\t\tbutton.modulate = _rarity_color(str(item.get("rarity", "Common")))\n\t\t\tbutton.pressed.connect(_on_inventory_item_pressed.bind(i))\n\t\t\tinventory_backpack_box.add_child(button)\n\n\nfunc _on_inventory_item_pressed(index: int) -> void:\n\tif is_instance_valid(player):\n\t\tplayer.equip_inventory_index(index)\n''',
    '''\t\t\tbutton.modulate = _rarity_color(str(item.get("rarity", "Common")))\n\t\t\tbutton.focus_mode = Control.FOCUS_ALL\n\t\t\tbutton.pressed.connect(_on_inventory_item_pressed.bind(i))\n\t\t\tinventory_backpack_box.add_child(button)\n\t\t\tinventory_item_buttons.append(button)\n\n\tif is_instance_valid(inventory_panel) and inventory_panel.visible:\n\t\t_focus_inventory_item_deferred()\n\n\nfunc _on_inventory_item_pressed(index: int) -> void:\n\tinventory_focus_index = maxi(0, index)\n\tif is_instance_valid(player):\n\t\tplayer.equip_inventory_index(index)\n\n\nfunc _focus_inventory_item_deferred() -> void:\n\tif inventory_item_buttons.is_empty():\n\t\treturn\n\tinventory_focus_index = clampi(inventory_focus_index, 0, inventory_item_buttons.size() - 1)\n\tcall_deferred("_focus_inventory_item", inventory_focus_index)\n\n\nfunc _focus_inventory_item(index: int) -> void:\n\tif not is_instance_valid(inventory_panel) or not inventory_panel.visible:\n\t\treturn\n\tif index < 0 or index >= inventory_item_buttons.size():\n\t\treturn\n\tvar button := inventory_item_buttons[index]\n\tif is_instance_valid(button) and not button.disabled:\n\t\tbutton.grab_focus()\n''',
)
replace_once(
    "scripts/multiclass_main.gd",
    "\tif inventory_panel.visible:\n\t\t_refresh_inventory()\n\t_update_pause_state()\n",
    "\tif inventory_panel.visible:\n\t\t_refresh_inventory()\n\t\t_focus_inventory_item_deferred()\n\t_update_pause_state()\n",
)
replace_once(
    "tests/test_playable_inventory_persistence.gd",
    'const ITEM_PICKUP_SCRIPT = preload("res://scripts/item_pickup.gd")\n',
    'const ITEM_PICKUP_SCRIPT = preload("res://scripts/item_pickup.gd")\nconst INVENTORY_FOCUS_HARNESS = preload("res://tests/playable_inventory_focus_harness.gd")\n',
)
replace_once(
    "tests/test_playable_inventory_persistence.gd",
    '''class RejectingTarget:\n\textends Node3D\n\n\tfunc try_add_item(_item: Dictionary) -> bool:\n\t\treturn false\n''',
    '''class RejectingTarget:\n\textends Node3D\n\n\tfunc try_add_item(_item: Dictionary) -> bool:\n\t\treturn false\n\nclass InventoryFocusPlayer:\n\textends Node\n\n\tsignal inventory_changed\n\n\tvar backpack: Array[Dictionary] = []\n\n\tfunc get_inventory_snapshot() -> Dictionary:\n\t\treturn {\n\t\t\t"equipment": {\n\t\t\t\t"Weapon": {},\n\t\t\t\t"Hood": {},\n\t\t\t\t"Chest": {},\n\t\t\t\t"Gloves": {},\n\t\t\t\t"Boots": {},\n\t\t\t\t"Relic": {},\n\t\t\t},\n\t\t\t"backpack": backpack.duplicate(true),\n\t\t\t"capacity": 12,\n\t\t}\n\n\tfunc equip_inventory_index(index: int) -> void:\n\t\tif index < 0 or index >= backpack.size():\n\t\t\treturn\n\t\tbackpack.remove_at(index)\n\t\tinventory_changed.emit()\n''',
)
replace_once(
    "tests/test_playable_inventory_persistence.gd",
    "\t_test_rejected_world_pickup_remains()\n\t_test_real_disk_round_trip_preserves_items_and_canary()\n",
    "\t_test_rejected_world_pickup_remains()\n\tawait _test_controller_focus_survives_inventory_refresh()\n\t_test_real_disk_round_trip_preserves_items_and_canary()\n",
)
replace_once(
    "tests/test_playable_inventory_persistence.gd",
    "func _test_real_disk_round_trip_preserves_items_and_canary() -> void:\n",
    '''func _test_controller_focus_survives_inventory_refresh() -> void:\n\tvar harness = INVENTORY_FOCUS_HARNESS.new()\n\troot.add_child(harness)\n\tvar player := InventoryFocusPlayer.new()\n\tplayer.backpack = [\n\t\tPLAYABLE_ITEM_CATALOG.item_data(&"void_scepter"),\n\t\tPLAYABLE_ITEM_CATALOG.item_data(&"bonebound_grimoire"),\n\t]\n\tharness.add_child(player)\n\tharness.player = player\n\tharness.inventory_panel = Control.new()\n\tharness.add_child(harness.inventory_panel)\n\tharness.inventory_equipment_box = VBoxContainer.new()\n\tharness.inventory_panel.add_child(harness.inventory_equipment_box)\n\tharness.inventory_backpack_box = VBoxContainer.new()\n\tharness.inventory_panel.add_child(harness.inventory_backpack_box)\n\tharness.equipment_summary_label = Label.new()\n\tharness.inventory_panel.add_child(harness.equipment_summary_label)\n\tplayer.inventory_changed.connect(harness._refresh_inventory)\n\tharness.inventory_panel.visible = true\n\tharness._refresh_inventory()\n\tawait process_frame\n\tawait process_frame\n\t_expect(harness.inventory_item_buttons.size() == 2, "Controller inventory test should build two focusable item buttons")\n\tif harness.inventory_item_buttons.size() == 2:\n\t\t_expect(harness.inventory_item_buttons[0].has_focus(), "Opening inventory should focus the first backpack item for controller input")\n\t\tharness.inventory_item_buttons[0].pressed.emit()\n\t\tawait process_frame\n\t\tawait process_frame\n\t\t_expect(harness.inventory_item_buttons.size() == 1, "Explicit equip should rebuild the backpack after removing the selected item")\n\t\tif harness.inventory_item_buttons.size() == 1:\n\t\t\t_expect(harness.inventory_item_buttons[0].has_focus(), "Inventory refresh after equip should preserve a valid controller focus target")\n\tharness.free()\n\n\nfunc _test_real_disk_round_trip_preserves_items_and_canary() -> void:\n''',
)
(ROOT / "tests/playable_inventory_focus_harness.gd").write_text(
    'extends "res://scripts/main.gd"\n\n\nfunc _ready() -> void:\n\t# Test harness: the inventory UI is assembled explicitly by the regression.\n\tpass\n',
    encoding="utf-8",
)
replace_once(
    "Docs/Standards/TESTING.md",
    "- Assert a full-backpack rejection leaves both the incoming world pickup and all owned items intact.\n",
    "- Assert a full-backpack rejection leaves both the incoming world pickup and all owned items intact.\n- Open the inventory with controller-style focus, equip an item, rebuild the list, and assert focus remains on a valid backpack action.\n",
)
for path, expected in EXPECTED.items():
    actual = subprocess.check_output(["git", "hash-object", path], cwd=ROOT, text=True).strip()
    if actual != expected:
        raise SystemExit(f"hash mismatch for {path}: {actual} != {expected}")
print(f"Applied and verified {len(EXPECTED)} controller-focus files")
Path(__file__).unlink()
