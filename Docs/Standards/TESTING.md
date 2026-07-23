# Testing Standards

Engine: **Godot 4.4.1**. All commands below run from the repository root.

## Required validation before claiming a fix works

*(Migrated verbatim from the pre-restructuring root `AGENTS.md` "Required validation" section.)*

```bash
godot --headless --path . --editor --quit
timeout 20s godot --headless --path .
```

The first command must complete without parser, compiler, resource-loading, or import errors. The second may end through the timeout, but its startup output must contain no script or runtime errors.

Do not claim a fix passes without running Godot headlessly and reading the actual output.

## CI workflow locations

| Workflow | Triggers on | Runs |
|---|---|---|
| [`.github/workflows/runtime-foundation-tests.yml`](../../.github/workflows/runtime-foundation-tests.yml) | `scripts/runtime/**`, `scripts/persistence/**`, `scripts/shared/**`, `Docs/ADR/**`, `project.godot` | every runtime suite explicitly listed in the workflow |
| [`.github/workflows/persistence-tests.yml`](../../.github/workflows/persistence-tests.yml) | `scripts/persistence/**`, `scripts/shared/**`, `scripts/boot.gd`, `project.godot` | `scripts/persistence/tests/test_save_manager.gd` |
| [`.github/workflows/godot-hotfix3-validation.yml`](../../.github/workflows/godot-hotfix3-validation.yml) | project-wide validation | headless import/parser validation |
| [`.github/workflows/playtest-tooling-validation.yml`](../../.github/workflows/playtest-tooling-validation.yml) | playtest tooling changes | tooling report/regression checks |
| [`.github/workflows/sprint1-penitent-input-validation.yml`](../../.github/workflows/sprint1-penitent-input-validation.yml) | Penitent combat/input UX | combat-feel and input-profile tests |

## Runtime test suite locations

All headless GDScript regression suites live under [`scripts/runtime/tests/`](../../scripts/runtime/tests/) (e.g. `test_runtime_foundation.gd`, `test_runtime_session.gd`, `test_ability_execution.gd`, `test_stage34_*.gd`, `test_stage5_*.gd`). Persistence-specific suites live under `scripts/persistence/tests/`.

**The runtime workflow lists its test suites manually.** [`.github/workflows/runtime-foundation-tests.yml`](../../.github/workflows/runtime-foundation-tests.yml) does not discover `scripts/runtime/tests/*.gd` automatically. Every new runtime test suite must be added to the workflow as an explicit `run_suite` line in the same pull request, otherwise it does not run in CI.

Run an individual suite directly:

```bash
godot --headless --path . --script res://scripts/runtime/tests/test_stage5_item_generation.gd
```

## Pass/fail rules

- **Every suite must emit an explicit `PASS: <suite name>` marker on stdout.** A suite with no `PASS:` line is failing even when it exits zero.
- **Script errors count as failures.** CI greps captured output for `SCRIPT ERROR`, `PARSER ERROR`, `Parse Error`, `ASSERTION FAILED`, and `^FAIL:` independently of process exit code.
- A red pipeline blocks merge. Fix the cause; never weaken the detector.

## Persistence and JSON round-trip requirements

Per [ADR-015](../ADR/ADR-015-RUNTIME-PERSISTENCE-SYNCHRONIZATION.md) and [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md), `PersistenceService`/`SaveManager` is the only disk-I/O boundary. Every persistence-affecting feature must be exercised through a real JSON path, not only an in-memory snapshot:

```gdscript
var parsed: Variant = JSON.parse_string(JSON.stringify(data))
```

Godot typed arrays return from JSON as untyped `Array`/`Dictionary` values. Restoration code must rebuild required typed structures, and tests must prove the disk-equivalent path.

## Deterministic-generation test rules

Per ADR-018's identity/provenance split:

- Compare rolled values and physical identity separately.
- Identical provenance may produce matching contents but separately minted items must have different IDs.
- `ItemIdentityService` is the only runtime source of physical IDs.
- Tests should mint normal runtime IDs through the service. Explicit fabricated IDs are allowed only in malformed-snapshot tests whose purpose is to prove rejection of duplicate, empty, foreign, or cross-container identity.
- Allocator continuation must be tested through JSON whenever identity state persists.

## Transactional ownership test rules

Any method documented as atomic must be tested against a failure that occurs **after an early sub-step would otherwise have been possible**.

Required assertions for an atomic failure include, where applicable:

- serialized state before and after is equal;
- incoming mutable arguments are unchanged;
- calculated stats are unchanged;
- signals/events did not fire;
- session references and connections did not change;
- allocator state did not advance inside the operation;
- no partial object became attached to another owner.

For inventory/equipment ownership specifically:

- test partial stack capacity, not only completely full stacks;
- test duplicate identity within equipment;
- test duplicate identity across inventory and equipment;
- test failed rebind while a valid session is already active;
- test split behavior with and without an identity service;
- test two-handed occupancy in both live-equip orders and restoration.

## Standing bug-pattern log

Keep this list short and category-level. Add an entry when review finds a reusable failure pattern.

### Scene-tree lifecycle and transform ordering

Observed failures:

- Reading or assigning global transforms before a node is inside the scene tree.
- Adding a node whose `_ready()` has gameplay side effects before configuring its final transform, causing one-frame behavior at world origin.

Prevention:

- Complete configuration before `add_child()` whenever `_ready()` can observe values or trigger gameplay.
- Compute intended world transform first, convert through the future parent, assign local transform, then attach.
- Do not access tree-dependent global transforms until the node is in the tree.

Regression expectation:

- Include a decoy at world origin and a target at the intended spawn point for immediate area effects.
- Assert the first frame/pulse affects only the intended location.

### Artifact staging and uploaded-package completeness

Observed failures:

- A staging directory contained the complete Git archive but artifact upload omitted hidden paths.
- A manifest could therefore describe files the downloaded review package did not contain.

Prevention:

- Use `include-hidden-files: true` for complete-source artifacts.
- Record exact Git tree/blob identity for tracked files.
- Download and verify the finished artifact before declaring success.

Regression expectation:

- Assert representative hidden paths survive upload/download.
- Fail on any path/hash mismatch.

### 3D material fades and invalid CanvasItem properties

Observed failures:

- Tweening `modulate`/`modulate:a` on `MeshInstance3D`.
- Assertion-only suites printing pass while Godot reports an engine/runtime error.

Prevention:

- Fade a unique `StandardMaterial3D` through `albedo_color` alpha with transparency enabled.
- Do not apply CanvasItem-only properties to Node3D-derived objects.
- Capture output and fail on parser/script/runtime/invalid-property errors.

Regression expectation:

- Spawn the real 3D feedback effect and assert material alpha changes before cleanup.
- Treat any Godot runtime error as failure even when assertion counts are green.

### Mutable ownership and mutation-before-validation

Observed failures:

- Filling part of a compatible stack before discovering the remainder cannot fit, then returning failure with mutated inventory.
- Restoring inventory and equipment independently so one physical item ID can be owned twice.
- Disconnecting the active session before the incoming replacement has passed restoration.
- Fabricating fallback IDs through time/global randomness when the authoritative allocator is absent.

Prevention:

- Preflight complete operations into temporary plans/state before mutating live objects.
- Validate uniqueness across all containers participating in one ownership domain.
- Build candidate session systems separately and commit the swap only after full success.
- Fail closed when the authoritative identity service is unavailable.

Regression expectation:

- Exercise the 19/20 stack plus incoming 5 case.
- Exercise duplicate IDs across equipment slots and across inventory/equipment.
- Attempt a corrupted rebind while a valid character is active and assert the active session is unchanged.
- Assert failed splits do not mutate quantity, emit signals, or invent identity.

## Every gameplay bug gets a regression test

Per the [Engineering Constitution](../Governance/ENGINEERING_CONSTITUTION.md), every gameplay bug found by CI, independent review, or playtest receives a regression before the fix is complete.

## Independent verification pipeline

Implementation testing and independent verification are separate gates. Frozen artifact mechanics, report format, and reviewer duties are documented in `docs/CLAUDE_VERIFIER_SETUP.md`, `docs/IMPLEMENTER_VERIFIER_HANDOFF.md`, and `docs/VERIFICATION_REPORT_TEMPLATE.md`. Role ownership is defined in [`Docs/Governance/AI_GUIDELINES.md`](../Governance/AI_GUIDELINES.md).
