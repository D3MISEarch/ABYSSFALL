# Issue #44 — Canonical Penitent Gate Fix

## Authority and branch

- Repository: `D3MISEarch/ABYSSFALL`
- Branch: `fix/penitent-canonical-gates`
- Base commit: `aeaaa58f5c11b567d1c309cc9e0e6d67dc0786b1`
- Issue: #44
- Human owner authorized continued focused implementation work.
- Keep the pull request draft and unmerged until CI and independent verification are complete.

## Problem

`scripts/multiclass_main.gd` still contains two pre-canonical class-ID gates:

1. `preview_penitent_sacrament()` compares `selected_class_id` against `"penitent_placeholder"`.
2. `_update_class_specific_copy()` compares `selected_class_id` against `"penitent_placeholder"` before installing the Penitent HUD.

The canonical registered runtime ID is `penitent`. Valid Penitent launches therefore cannot enter these two intended Penitent-only branches.

## Required implementation

1. Load the shared class-ID authority in `scripts/multiclass_main.gd`:

   ```gdscript
   const CLASS_IDS = preload("res://scripts/shared/class_ids.gd")
   ```

2. Replace both stale string comparisons with `CLASS_IDS.PENITENT`.
3. Do not add another raw durable class-ID literal.
4. Preserve existing behavior for Void Warlock and unknown/invalid IDs.
5. Do not change combat balance, Sacrament cost math, HUD visuals, persistence, camera, scene layout, controls, or PR #34 files.

## Required regression coverage

Add a focused Godot 4.4.1 test suite, preferably `tests/test_penitent_class_gates.gd`, that proves behavior rather than only checking source text.

At minimum verify:

1. **Canonical Penitent Sacrament preview**
   - `selected_class_id = CLASS_IDS.PENITENT`;
   - a valid fake/player double exposing `quote_sacrament_cost()` is accepted;
   - the returned quote is passed through;
   - the HUD cost-preview method receives the expected values when available.

2. **Canonical Penitent HUD installation**
   - `_update_class_specific_copy()` enters the Penitent-only HUD path for `CLASS_IDS.PENITENT`;
   - the Penitent resource HUD is installed exactly once;
   - repeated calls remain idempotent.

3. **Non-Penitent exclusion**
   - Void Warlock does not receive Sacrament preview access;
   - Void Warlock does not install the Penitent HUD;
   - an unknown/invalid ID does not enter either branch.

4. **Legacy-ID rejection**
   - `penitent_placeholder` does not activate either canonical Penitent-only branch.

Tests may use narrow test doubles or an instrumented subclass, but must exercise the real `multiclass_main.gd` branch conditions. Avoid requiring a graphical display for the automated suite.

## Validation

Run and report:

- Godot 4.4.1 editor/import validation;
- the new focused test suite;
- existing Penitent combat UX suites;
- `Validate AbyssFall`;
- `Validate Playtest Tooling`;
- persistence tests;
- headless canonical Void Warlock and Penitent launch smoke tests.

## Return packet

When implementation is complete, update the draft PR with:

- exact final head SHA;
- changed-file list;
- concise behavior summary;
- test commands and outcomes;
- workflow run IDs;
- confirmation that no out-of-scope files changed;
- any remaining graphical-playtest requirement.

Stop before merge and before claiming independent verification.