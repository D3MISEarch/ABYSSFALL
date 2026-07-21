# ADR-015 — Runtime-to-Persistence Synchronization

Status: PROPOSED  
Release target: CORE / Stage 2

## Decision

Runtime systems never call `SaveManager`. Durable runtime changes are converted into a serializable snapshot and handed to `PersistenceService`, which validates the build identity, updates `BuildData`, marks it dirty, and applies the approved save policy.

## Durable changes

Level, experience, unlocked abilities, inventory, equipment, permanent stat allocations, and build progression.

## Non-durable changes

Current combat health, temporary buffs, enemy state, cooldown time remaining, and transient room state unless a future checkpoint decision promotes them.

## Rules

- Snapshot conversion is explicit and versioned.
- A snapshot with a mismatched build ID is rejected.
- Unsupported fields are ignored.
- Dictionary-backed progression is merged so unrelated durable data survives.
- Autosave is coalesced; gameplay does not force disk writes per event.
- Session exit requests a final flush.
- Failed saves preserve dirty state for retry.

## Consequences

Gameplay state can change frequently while Stage 1 retains the only disk-I/O boundary.