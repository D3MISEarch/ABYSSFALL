# GDScript Standards

## Linting

`gdlintrc` at the repository root governs `gdlint`. Currently disabled checks: `max-file-lines`, `max-line-length`, `class-definitions-order`. Do not broadly disable further warnings to hide legitimate errors — a disabled check must be a deliberate, narrow, documented exception, not a way to silence a real problem.

## Composition over inheritance

*(Migrated from the pre-restructuring root `AGENTS.md` "Project rules" section; see the Engineering Constitution's law 3 for the binding rule.)*

Prefer reusable character, ability, resource, enemy, item, and encounter components over class-specific conditionals in shared code such as `main.gd`. If you find yourself writing `if class_id == "penitent"` in shared code, that's a signal the responsibility belongs in a component the class injects or configures, not a branch shared code must know about.

## Class and file layout

- One `class_name` per file; the file name is the snake_case form of the class name (e.g. `class_name RuntimeSession` lives in `runtime_session.gd`).
- Runtime gameplay logic lives under `scripts/runtime/`, organized by subsystem (`abilities/`, `combat/`, `items/`, `loot/`, `rewards/`, `stats/`, `enemies/`, `resources/`, `tests/`). Persistence-only code lives under `scripts/persistence/` and must not be reached from `scripts/runtime/` except through `PersistenceService` (see [`Docs/Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md)).
- Prefer `RefCounted` for pure data/logic objects with no scene-tree lifecycle needs; reserve `Node` for objects that genuinely need scene-tree membership, signals routed through the tree, or `_process`/`_ready` lifecycle hooks (e.g. `RuntimeSession`, `RuntimeEventBus`, `PersistenceService`).

## Scene-tree and lifecycle discipline

See the "Scene-tree lifecycle and transform ordering" and "3D material fades and invalid CanvasItem properties" entries in the standing bug-pattern log in [`Docs/Standards/TESTING.md`](TESTING.md) before writing any code that assigns transforms, adds children, or fades materials. Both are real, previously-shipped bug categories, not hypothetical concerns.

## Determinism

Never introduce ambient/global randomness. Any function whose output should be reproducible takes its `RandomNumberGenerator` (seeded explicitly by the caller) as an argument — see `ItemGenerator.generate()` in [`Docs/Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md) for the established pattern.
