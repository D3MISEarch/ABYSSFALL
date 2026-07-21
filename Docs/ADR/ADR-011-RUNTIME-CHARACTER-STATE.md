# ADR-011 — Runtime Character State

Status: PROPOSED  
Release target: CORE / Stage 2

## Decision

A runtime character is a session-scoped object constructed from one persistent `BuildData` record. It owns current health, class resource, cooldowns, temporary effects, runtime inventory/equipment state, and calculated stats.

`BuildData` remains durable data. `RuntimeCharacter` never performs disk I/O.

## Boundaries

- `PersistenceService` applies and commits durable runtime snapshots.
- `RuntimeCharacter` emits `state_changed(reason)` after durable changes.
- Temporary combat state is excluded from saves unless explicitly promoted by a future checkpoint decision.
- Definitions are referenced by stable IDs rather than serialized object graphs.
- One runtime character maps to one persistent build ID.

## Consequences

Gameplay can evolve independently from save formats while persistence receives a small, explicit snapshot contract.