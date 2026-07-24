# PR #34 Blocker-Fix Implementation Brief

> Status: **OWNER AUTHORIZED / IMPLEMENTATION REQUIRED / PR REMAINS DRAFT**  
> Pull request: **#34 — Stages 3–5: durable ARPG loop and deterministic item generation**  
> Starting reviewed head: `812f51ca451d66935f7f478bd37a7ca7c707d371`  
> Current `main` foundation head at authorization: `ceaa62ecfdd8c27ca0e028a3d0adde03b7f1b130`  
> Owner authorization: **“Awesome lets keep working.”** on 2026-07-23  
> Technical direction: ChatGPT review submissions on PR #34  
> Merge authority: human owner only

## 1. Goal

Close the ownership, atomicity, identity, restoration, and two-handed occupancy blockers found during technical-director review without broad refactoring or new gameplay scope.

The corrected milestone must safely support:

`fight → gain XP → generate loot → inventory → equip → recompute stats → save → JSON reload`

for Stages 3, 4, and 5.

## 2. Mandatory branch synchronization

Before changing runtime behavior, update `stage3/equipment-runtime-foundation` from current `main`.

The branch is currently one commit behind because PR #40 merged the canonical campaign, class-boundary, creative-direction, and camera documentation.

Requirements:

- preserve every PR #40 document exactly unless a real conflict requires a focused reconciliation;
- do not overwrite `docs/design/ABYSSFALL_CANONICAL_DESIGN_FOUNDATION.md`;
- do not overwrite `docs/design/ABYSSFALL_CAMERA_AND_COMBAT_PRESENTATION_CANONICAL.md`;
- do not rewrite owner decision records;
- report any merge conflict instead of choosing silently;
- rerun all workflows after synchronization.

## 3. Allowed implementation files

Primary expected files:

- `scripts/runtime/items/inventory_container.gd`
- `scripts/runtime/items/equipment_manager.gd`
- `scripts/runtime/items/item_instance.gd`
- `scripts/runtime/runtime_character.gd`
- `scripts/runtime/runtime_session.gd` only if orchestration or bind cleanup requires a focused change
- existing Stage 3–5 runtime test suites
- `.github/workflows/runtime-foundation-tests.yml` only when a new test suite is added
- relevant ADR, architecture, roadmap, testing, and repository-map documentation

Do not alter combat balance, abilities, class mechanics, camera nodes, scenes, input mapping, UI, save-file locations, unrelated workflows, or PR #24 history.

## 4. Required fix A — atomic inventory addition

### Problem

`InventoryContainer.add_item()` may partially fill compatible stacks before discovering that the remainder cannot fit, then return `false` after mutating live state.

### Required behavior

- Validate the complete add operation before mutating inventory or the incoming instance.
- Reject an empty or duplicate `instance_id` before preflight.
- Reject invalid or non-positive quantity.
- For the current milestone, reject a single incoming stack whose quantity exceeds `definition.max_stack`; do not create multiple physical stacks implicitly.
- Calculate compatible-stack free capacity and required empty-slot capacity before changing any quantity.
- When the full quantity cannot fit, return `false` with:
  - inventory byte-equivalent to its prior serialized state;
  - incoming item unchanged;
  - no signals emitted;
  - no identity minted or allocator advancement.
- On success, perform the planned mutations deterministically and emit only the established success signal behavior.

### Required regressions

Extend `test_stage34_catalog_inventory.gd` or add one explicitly wired suite covering:

1. capacity 1, existing compatible stack 19/20, incoming quantity 5;
2. operation returns `false`;
3. existing stack remains 19;
4. incoming remains quantity 5;
5. inventory serialization is unchanged;
6. no `item_added` or `item_removed` signal fires;
7. oversize single-stack payload is rejected unchanged;
8. a fully fitting partial merge still succeeds deterministically.

## 5. Required fix B — unique equipment identity

### Problem

The same physical `instance_id` may occupy multiple equipment slots, and restore currently accepts duplicate IDs across slots.

### Required behavior

- Every equipped item must have a non-empty `instance_id`.
- `can_equip()` and `equip()` must reject an ID already equipped in another slot.
- Re-equipping the currently equipped item into its existing slot may be treated as a deterministic no-op or rejected unchanged; document and test the selected behavior.
- `restore()` must validate all slot names, definitions, quantities, compatibility, non-empty IDs, and ID uniqueness into temporary state before replacing live equipment.
- Failed equip or restore must leave equipment, stats, and signals unchanged.

### Required regressions

Extend `test_stage34_equipment_stats.gd`:

1. one ring instance cannot occupy both `ring_left` and `ring_right`;
2. duplicate IDs in serialized equipment fail restoration;
3. empty equipment ID fails restoration;
4. failed restoration preserves prior serialized equipment and exact calculated stats;
5. no `equipment_changed` signal fires on failure.

## 6. Required fix C — globally disjoint inventory/equipment restoration

### Problem

Inventory and equipment are restored independently, so one serialized physical item may appear in both.

### Required behavior

- Before attaching either restored system to `RuntimeCharacter`, validate that inventory IDs and equipment IDs are globally disjoint.
- Perform this validation before equipment modifiers can alter the live character stat block.
- A collision must make binding fail atomically.
- Do not create a global registry or singleton.
- Keep `RuntimeSession` as the composition root and `RuntimeCharacter.attach_item_systems()` as the current attachment boundary unless the smallest safe implementation requires a documented focused adjustment.
- A failed rebind must not leak connections, inventory, equipment, modifiers, or the incoming build’s allocator state into a previously bound session.

### Required regressions

Add coverage to `test_runtime_session.gd` or the vertical-slice suite:

1. build snapshot contains the same non-empty ID in inventory and equipment;
2. bind returns `false`;
3. no duplicate ownership becomes attached;
4. character stats remain at their pre-bind values;
5. an already bound prior character/session state is not partially replaced or leaked;
6. corrected disjoint snapshots bind successfully.

## 7. Required fix D — session-owned identity only

### Problem

`ItemInstance._init()` and inventory split fallback fabricate IDs using time/global randomness.

### Required behavior

- `ItemInstance` construction leaves `instance_id` empty unless an explicit serialized or minted identity is assigned by the caller.
- `ItemInstance.from_dict()` preserves a serialized ID but never invents one when absent.
- Runtime-created physical items obtain identity only from the active `ItemIdentityService`.
- Partial stack removal requires a configured identity service.
- Without that service, a split fails atomically:
  - original quantity unchanged;
  - no returned item;
  - no signals;
  - no hidden fallback ID.
- With the service, a split receives the next monotonic ID and allocator snapshot advances exactly once.
- Remove all `Time.*` and global `randi()` physical-ID generation from these paths.

### Required regressions

1. `ItemInstance.new()` has an empty ID;
2. inventory rejects an unminted incoming item;
3. `from_dict()` with a valid ID preserves it;
4. `from_dict()` without an ID remains unminted;
5. split without identity service fails unchanged;
6. split with identity service mints the expected `item:<build>:<sequence>` ID;
7. split ID and next sequence survive JSON round trip;
8. no test fabricates runtime IDs except malformed-snapshot validation tests.

## 8. Required fix E — two-handed occupancy

Use existing `ItemDefinition.tags`; do not add another manager or ownership layer.

Locked rule:

- data tag: `two_handed`;
- a two-handed item may equip only in `main_hand`;
- two-handed main-hand equip fails while `off_hand` is occupied;
- off-hand equip fails while main hand contains a two-handed item;
- restore rejects a two-handed main-hand item plus any off-hand item;
- all failures are atomic and signal-free;
- do not auto-unequip off-hand in this milestone;
- no public API widening to return multiple displaced items.

Required regressions:

1. two-handed main-hand equip succeeds when off-hand is empty;
2. two-handed main-hand equip fails unchanged when off-hand is occupied;
3. off-hand equip fails unchanged while two-handed main hand is equipped;
4. invalid restore combination fails with prior equipment and stats unchanged;
5. ordinary one-handed main/off-hand behavior remains valid.

## 9. Documentation corrections after behavior exists

Update only after tests demonstrate corrected behavior:

- `AGENTS.md`: replace incorrect PR #35 references with PR #34 or remove transient PR-number wording where stable stage wording is better;
- `Docs/Architecture/ARCHITECTURE.md`: describe the corrected atomic preflight, global restore disjointness, explicit identity-only construction, and two-handed occupancy;
- `Docs/Roadmap/STAGE_3_4_GAMEPLAY_LOOP.md`: mark the corrected behavior accurately;
- `Docs/Roadmap/STAGE_5_LOOT_AFFIXES.md`: update status from pending/review-fix language to the actual handoff state;
- `Docs/Standards/TESTING.md`: add a short ownership/atomicity bug-pattern entry only if it represents a reusable category;
- PR #34 body: replace the blocker list with exact fixed-head, CI, and handoff status when complete.

Do not claim the blockers are closed before the corrected tests run in Godot.

## 10. Validation requirements

Run from repository root using Godot 4.4.1:

```bash
godot --headless --path . --editor --quit
timeout 20s godot --headless --path .
```

Run every runtime suite, including:

- runtime foundation;
- runtime session isolation;
- ability execution;
- Stage 3–4 catalog/inventory;
- Stage 3–4 equipment/stats;
- Stage 3–4 rewards;
- Stage 3–4 durable vertical slice;
- Stage 5 affix catalog;
- Stage 5 item generation;
- Stage 5 generated rewards;
- any newly added suite.

Run persistence tests and preserve the explicit `PASS:` marker and log-error grep behavior.

Every persistence-affecting regression must include a real JSON stringify/parse round trip.

## 11. Completion evidence required in PR #34

The implementation handoff must include:

- exact fixed commit SHA;
- concise file list;
- explanation of each blocker’s resolution;
- exact Godot commands run;
- test result summary;
- workflow run links or IDs;
- frozen `abyssfall-verifier-*` artifact identity;
- remaining non-blocking guidance separated from blockers;
- confirmation that PR #34 remains draft and unmerged.

## 12. Independent verification gate

After the fixed head is green, hand the frozen artifact to Claude for independent review.

Claude must specifically re-test:

- partial-stack atomic failure;
- duplicate equipment ID rejection;
- inventory/equipment collision rejection;
- identity minting and JSON allocator continuation;
- two-handed occupancy;
- fight-to-generated-loot-to-equip-to-save-to-reload behavior;
- branch synchronization with PR #40 documentation preserved.

Required final statement:

> **Stages 3, 4, and 5 durable gameplay loop approved.**

A PASS may still require a separate graphical playtest before merge.

## 13. Prohibited shortcuts

- no weakening tests;
- no time/random ID fallback;
- no silent quantity truncation;
- no mutation followed by `false`;
- no duplicate physical identity across containers or slots;
- no global ownership singleton;
- no automatic off-hand ejection;
- no broad equipment API redesign;
- no unrelated refactor;
- no merge or ready-for-review transition without later owner authorization.
