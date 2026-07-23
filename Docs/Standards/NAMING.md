# Naming Standards

These conventions are descriptive of the current codebase (`scripts/runtime/`, `scripts/persistence/`), not aspirational — every rule below is verified against existing files.

## Classes and files

- `class_name` — `PascalCase` (e.g. `RuntimeSession`, `ItemIdentityService`, `AbilityExecutor`).
- File name — `snake_case` form of the class name (e.g. `runtime_session.gd`, `item_identity_service.gd`, `ability_executor.gd`).
- Test suite files — `test_<subject>.gd`, `extends SceneTree`, living in `scripts/runtime/tests/` or `scripts/persistence/tests/`.

## Members and functions

- Public methods and properties — `snake_case` (e.g. `bind_character`, `execute_ability`, `durable_snapshot`).
- Private/internal methods — leading underscore, `snake_case` (e.g. `_disconnect_character`, `_on_inventory_changed`, `_apply_item_modifiers`).
- Signal handlers — `_on_<source>_<event>` (e.g. `_on_character_state_changed`, `_on_equipment_changed`).
- Constants — `SCREAMING_SNAKE_CASE` (e.g. `AUTOSAVE_INTERVAL_SECONDS`, `SNAPSHOT_FIELDS`, `ID_PREFIX`).

## Signals

`snake_case`, named as a past-tense event or a clear state description, not a command: `state_changed`, `level_gained`, `item_added`, `item_removed`, `equipment_changed`, `build_loaded`, `ability_cast`, `ability_rejected`. A signal name should read naturally as "X happened," matching the event-bus convention in [`Docs/Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md).

## Stable IDs

- Definition IDs and slot IDs use `StringName` literals (`&"main_hand"`, `&"inventory"`), not plain `String`, since they are compared frequently and never mutated.
- Item instance IDs are minted exclusively by `ItemIdentityService.mint()` in the form `"item:<session_id>:<sequence>"`. Never hand-construct an instance ID elsewhere.
- Build IDs, class IDs, and definition IDs are treated as opaque stable strings — never parsed for meaning outside the system that owns them.

## Documentation file naming

- ADRs: `ADR-0NN-TITLE-IN-CAPS.md` (the two current exceptions, `018_PROCEDURAL_ITEM_GENERATION.md` and `Docs/Stage3/ABILITY-EXECUTION-REVIEW.md`, are pre-existing and preserved as-is — see [`Docs/README.md`](../README.md) for the note on this inconsistency).
- Roadmap stage documents: `STAGE_<N>_<TOPIC>.md`.
- Everything under the new `Docs/Governance/`, `Docs/Architecture/`, `Docs/Standards/`, `Docs/Planning/` tree: `SCREAMING_SNAKE_CASE.md`, one document per concern named after that concern.
