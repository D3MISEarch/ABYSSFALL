# Voidbringer Codex

Status: Approved design, independently audited and corrected  
Codex version: 1.1  
Last updated: 2026-07-22  
Canonical design ID: `voidbringer`  
Runtime/save compatibility ID during migration: `void_warlock`

## Read this first

The numbered bibles preserve the complete approved design developed with the project owner. Independent review found a small number of cross-document contradictions at the seams.

**Read [`09_AUDIT_RESOLUTIONS.md`](09_AUDIT_RESOLUTIONS.md) before implementation.** Its rulings are binding and supersede only the exact conflicting sections it names. All unaffected content in the numbered bibles remains approved.

## Authority inside this folder

1. `09_AUDIT_RESOLUTIONS.md` for explicitly resolved contradictions and canonical terminology.
2. `02_SKILL_TREE.md` for progression, costs, skills, passives, keystones, capstones and numeric mechanics.
3. `03_ITEMIZATION.md` for Frames, equipment, Distortions, uniques, crafting and stacking.
4. `05_ENCOUNTER_INTERACTIONS.md` for enemy/boss translation and force conversion.
5. `06_NARRATIVE_AND_QUESTS.md` for lore, class quests, Trials and Edras.
6. `07_IMPLEMENTATION_CONTRACT.md` for design-to-code requirements, subordinate to repository Governance/ADRs/Architecture.
7. `08_BALANCE_AND_TEST_MATRIX.md` for verification criteria.
8. `04_COMBAT_PRESENTATION.md` for controls, animation, VFX, audio, HUD and accessibility.
9. `01_CLASS_BIBLE.md` for fantasy, identity and high-level mechanical intent. Where a named mechanic differs from 02/03, the specialized document and audit resolutions control.

Repository engineering authority remains:

- `Docs/Governance/ENGINEERING_CONSTITUTION.md`
- relevant `Docs/ADR/`
- `Docs/Architecture/ARCHITECTURE.md`
- `Docs/Standards/`

The Codex specifies what the class should do. It does not permit bypassing existing architecture.

## Documents

- [`01_CLASS_BIBLE.md`](01_CLASS_BIBLE.md) — identity, combat verb, core systems, disciplines, builds and non-negotiables.
- [`02_SKILL_TREE.md`](02_SKILL_TREE.md) — complete level 1–50 progression and every skill-tree component.
- [`03_ITEMIZATION.md`](03_ITEMIZATION.md) — Frames, class slots, affixes, Distortions, uniques, crafting and loot rules.
- [`04_COMBAT_PRESENTATION.md`](04_COMBAT_PRESENTATION.md) — controls, basic attacks, loadouts, animation, VFX, sound, HUD and accessibility.
- [`05_ENCOUNTER_INTERACTIONS.md`](05_ENCOUNTER_INTERACTIONS.md) — all enemy families, boss translation, force conversion and anti-exploit rules.
- [`06_NARRATIVE_AND_QUESTS.md`](06_NARRATIVE_AND_QUESTS.md) — Black Measure, Last Measure, Gaugehouse, characters, Trials, final boss and endings.
- [`07_IMPLEMENTATION_CONTRACT.md`](07_IMPLEMENTATION_CONTRACT.md) — stable IDs, runtime/data contracts and production milestones.
- [`08_BALANCE_AND_TEST_MATRIX.md`](08_BALANCE_AND_TEST_MATRIX.md) — balance expectations, telemetry and validation suite.
- [`09_AUDIT_RESOLUTIONS.md`](09_AUDIT_RESOLUTIONS.md) — binding consistency corrections from independent review.
- [`CHANGELOG.md`](CHANGELOG.md) — class-document history.

## Implementation status

The existing game still runs the Void Warlock prototype. The approved Voidbringer implementation has not replaced it.

Migration rule:

- preserve `void_warlock` for existing selection and saves,
- introduce Voidbringer behavior behind compatible adapters,
- validate the anchor sandbox before replacing old combat,
- approve a versioned ID migration before changing persisted class identity.

## Core identity

> The Voidbringer does not cast destruction. It decides where weight, distance and direction are permitted to exist—and then revokes permission.

Core loop:

**Anchor → Load → Bend → Collapse**
