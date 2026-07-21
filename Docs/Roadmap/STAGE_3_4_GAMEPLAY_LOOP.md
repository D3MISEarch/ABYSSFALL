# Stages 3 and 4 — Durable ARPG Gameplay Loop

Status: IN PROGRESS  
Release target: CORE  
Branch: `stage3/equipment-runtime-foundation`

## Goal

Deliver the complete reusable gameplay loop in one reviewable milestone:

`Load build → enter room → fight enemies → gain XP → generate loot → manage inventory → equip items → recompute stats → unlock/use abilities → save → reload`

The work is delivered as one pull request, but remains split into deterministic internal slices so failures can be isolated and reviewed.

## Stage 3 — Runtime systems completion

- Immutable item and ability definition catalogs
- Deterministic item-instance creation and affix ownership
- Inventory container with capacity, stacking, add/remove, transfer, and serialization semantics
- Equipment validation, swapping, duplicate-instance prevention, and two-handed occupancy rules
- Equipment-driven stat modifiers with source replacement and deterministic recomputation
- RuntimeSession ownership of inventory, equipment, ability execution, and event routing
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
- Item instance IDs are stable across serialization.
- Equipment and inventory may never own the same instance simultaneously.
- Reward grants and enemy death effects occur exactly once.
- Identical seeds and inputs produce identical loot and combat results.
- Failed operations are atomic: no partial resource, inventory, equipment, XP, or persistence mutation.

## Acceptance criteria

1. Inventory rejects invalid quantities and over-capacity additions without partial mutation.
2. Stackable items merge deterministically and removals preserve correct quantities.
3. Equipping validates slots and definition rules, returns displaced items, and prevents duplicate ownership.
4. Equipment modifiers are replaced by source and recompute stats deterministically.
5. Two builds and two item instances cannot leak runtime ownership or cooldown state.
6. XP rewards can cross multiple levels in one grant and produce deterministic remaining XP.
7. Enemy rewards are granted exactly once even if death is reported repeatedly.
8. Seeded loot generation is repeatable and weighted selections are deterministic.
9. Inventory-full loot pickup leaves both the pickup and inventory unchanged.
10. Runtime snapshots preserve inventory, equipment, level, XP, and unlocked abilities.
11. A complete fight-to-loot-to-equip-to-save-to-reload test passes on real Godot 4.4.1.
12. All existing workflows remain green.

## Internal delivery slices

1. Definition catalogs and inventory semantics
2. Equipment/stat integration
3. XP and progression
4. Enemy rewards and deterministic loot
5. RuntimeSession orchestration and events
6. Persistence round trip
7. Full vertical-slice regression and documentation

## Merge gate

Do not merge until all CI is green and an independent reviewer explicitly states:

**Stages 3 and 4 durable gameplay loop approved.**
