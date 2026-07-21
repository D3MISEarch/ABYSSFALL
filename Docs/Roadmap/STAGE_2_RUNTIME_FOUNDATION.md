# Stage 2 — Runtime Character and Combat Foundation

Status: IMPLEMENTED / PENDING INDEPENDENT REVIEW  
Release target: CORE  
Branch: `stage2/runtime-character-foundation`

## Goal

Deliver the reusable runtime kernel for the first playable ARPG loop without allowing gameplay systems to write directly to disk.

## Vertical-slice target

`Load build → construct runtime character → fight enemy → gain XP/loot → equip item → apply durable snapshot → save → reload`

## Included in this stage

- Session-scoped `RuntimeCharacter`
- Deterministic stat/modifier pipeline
- Class-resource pool and atomic ability cost/cooldown handling
- Item-instance and equipment ownership foundations
- Deterministic combat resolution
- Enemy death signaling exactly once
- Runtime event-bus contract
- Runtime-to-persistence snapshot boundary
- Disk round-trip runtime smoke test
- Godot 4.4.1 CI validation

## Architecture rules

- Persistent `BuildData` is the durable source of truth.
- Runtime state is constructed from `BuildData` and discarded with the session.
- Runtime systems never call `SaveManager`.
- `PersistenceService` is the only runtime-to-save synchronization boundary.
- Definitions are immutable; instances own mutable state.
- Identical combat inputs produce identical results.
- A runtime snapshot must match the active build ID.

## Acceptance criteria

1. Flat, additive-percent, and multiplicative-percent stat operations are deterministic.
2. Removing a modifier source rebuilds correctly.
3. Failed ability casts spend no resource and start no cooldown.
4. Armor and resistance resolution are deterministic.
5. Enemy death emits exactly once.
6. Penitent and Void Warlock runtime class resources remain isolated.
7. Runtime snapshots preserve level, experience, equipment, inventory, and unlocked abilities.
8. Mismatched build snapshots are rejected.
9. Existing unrelated build progression survives snapshot merging.
10. Runtime changes persist through disk save and reload.
11. No runtime class references `SaveManager`.
12. All pull-request workflows pass under Godot 4.4.1.

## Deferred follow-on work

- Final inventory container and removal semantics
- Definition catalogs for items and abilities
- Equipment-driven stat modifiers
- XP/loot event orchestration in a playable room
- Class-specific starter kits
- Production HUD and combat presentation

## Merge gate

Do not merge until an independent reviewer explicitly states: **Stage 2 runtime architecture approved.**