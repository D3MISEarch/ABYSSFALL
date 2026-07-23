# Stages 3 and 4 — Durable ARPG Gameplay Loop

Status: IMPLEMENTED / AUTOMATED CI GREEN / INDEPENDENT VERIFICATION PENDING  
Release target: CORE  
Branch: `stage3/equipment-runtime-foundation`  
Pull request: #34

## Goal

Deliver the complete reusable gameplay loop in one reviewable milestone:

`Load build → enter room → fight enemies → gain XP → generate loot → manage inventory → equip items → recompute stats → unlock/use abilities → save → reload`

The work is delivered as one pull request, but remains split into deterministic internal slices so failures can be isolated and reviewed.

## Stage 3 — Runtime systems completion

- Immutable item and ability definition catalogs
- Deterministic item-instance creation and affix ownership
- Inventory container with capacity, stacking, add/remove, transfer, and serialization semantics
- Atomic inventory-add preflight: a failed partial merge leaves inventory, incoming quantity, signals, and allocator state unchanged
- Equipment validation, swapping, unique-instance enforcement, and data-driven `two_handed` occupancy rules
- Global inventory/equipment identity-disjointness during restoration
- Equipment-driven stat modifiers with source replacement and deterministic recomputation
- Transactional `RuntimeSession` rebinding that preserves the active session when an incoming character snapshot is invalid
- RuntimeSession ownership of inventory, equipment, ability execution, identity allocation, and event routing
- Class-specific starter kits
- Runtime snapshot integration for inventory, equipment, unlocked abilities, XP, and level

## Stage 4 — Playable progression loop

- Deterministic XP curve and multi-level gain handling
- Enemy reward definitions and exactly-once reward grants
- Deterministic loot tables with injected seed/RNG
- Loot pickup and inventory-full rejection behavior
- Room/run orchestration for enemy registration, completion, and rewards
- Event routing for enemy defeat, XP gain, level gain, loot generation, pickup, equip, and stat changes
- Save/reload integration for the complete loop
- Headless vertical-slice test covering combat through durable reload

## Architecture rules

- `BuildData` remains the durable source of truth.
- Runtime systems never call `SaveManager` or write to disk.
- `PersistenceService` remains the only runtime-to-persistence boundary.
- `RuntimeSession` remains the session composition root.
- Definitions are immutable; instances own mutable state.
- `ItemInstance` construction does not fabricate an ID; the session-owned `ItemIdentityService` is the only runtime minter.
- Item instance IDs are stable across serialization.
- Equipment slots may not share a physical instance ID.
- Equipment and inventory may never own the same instance simultaneously.
- A `two_handed` item may occupy `main_hand` only while `off_hand` is empty; no automatic off-hand ejection occurs in this milestone.
- Reward grants and enemy death effects occur exactly once.
- Identical seeds and inputs produce identical loot and combat results.
- Failed operations are atomic: no partial resource, inventory, equipment, XP, binding, or persistence mutation.

## Acceptance criteria

1. Inventory rejects invalid quantities and over-capacity additions without partial mutation.
2. A capacity-1 inventory containing 19/20 items rejects an incoming quantity of 5 without changing either stack or emitting signals.
3. Stackable items merge deterministically and partial removals require a configured identity service.
4. Equipping validates slots and definitions, returns displaced items, and prevents duplicate physical identity across slots.
5. Equipment restore rejects empty or duplicate IDs and preserves prior equipment and stats on failure.
6. Inventory/equipment restoration rejects cross-container ID collisions before attachment or stat mutation.
7. Two-handed main-hand/off-hand occupancy is enforced for live equips and restoration.
8. Failed character rebinding preserves the previously active session, allocator, item systems, stats, and signal connections.
9. Two builds and two item instances cannot leak runtime ownership or cooldown state.
10. XP rewards can cross multiple levels in one grant and produce deterministic remaining XP.
11. Enemy rewards are granted exactly once even if death is reported repeatedly.
12. Seeded loot generation is repeatable and weighted selections are deterministic.
13. Inventory-full loot pickup leaves both the pickup and inventory unchanged.
14. Runtime snapshots preserve inventory, equipment, level, XP, unlocked abilities, and allocator state.
15. A complete fight-to-loot-to-equip-to-save-to-JSON-reload test passes on real Godot 4.4.1.
16. All existing workflows remain green.

## Internal delivery slices

1. Definition catalogs and inventory semantics
2. Equipment/stat integration
3. XP and progression
4. Enemy rewards and deterministic loot
5. RuntimeSession orchestration and events
6. Persistence round trip
7. Full vertical-slice regression and documentation
8. Ownership/atomicity blocker-fix pass and regressions

## Current automated evidence

At blocker-fix head `95a4e5ab072a329e19d57ac3c545610d9e60ea8b`, the Godot 4.4.1 runtime workflow passed every explicitly listed runtime suite. This is implementation evidence only; independent verification and graphical playtest gates remain open.

## Merge gate

Do not merge until all CI is green, the frozen verifier artifact is independently reviewed, graphical playtest requirements are resolved, and the human owner authorizes merge.

Required independent-verifier statement:

**Stages 3, 4, and 5 durable gameplay loop approved.**
