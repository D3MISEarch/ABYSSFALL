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
| [`.github/workflows/runtime-foundation-tests.yml`](../../.github/workflows/runtime-foundation-tests.yml) | `scripts/runtime/**`, `scripts/persistence/**`, `scripts/shared/**`, `Docs/ADR/**`, `project.godot` | every `scripts/runtime/tests/*.gd` suite |
| [`.github/workflows/persistence-tests.yml`](../../.github/workflows/persistence-tests.yml) | `scripts/persistence/**`, `scripts/shared/**`, `scripts/boot.gd`, `project.godot` | `scripts/persistence/tests/test_save_manager.gd` |
| [`.github/workflows/godot-hotfix3-validation.yml`](../../.github/workflows/godot-hotfix3-validation.yml) | project-wide validation | headless import/parser validation |
| [`.github/workflows/playtest-tooling-validation.yml`](../../.github/workflows/playtest-tooling-validation.yml) | playtest tooling changes | tooling report/regression checks |
| [`.github/workflows/sprint1-penitent-input-validation.yml`](../../.github/workflows/sprint1-penitent-input-validation.yml) | Penitent combat/input UX | combat-feel and input-profile tests |

## Runtime test suite locations

All headless GDScript regression suites live under [`scripts/runtime/tests/`](../../scripts/runtime/tests/) (e.g. `test_runtime_foundation.gd`, `test_runtime_session.gd`, `test_ability_execution.gd`, `test_stage34_*.gd`, `test_stage5_*.gd`). Persistence-specific suites live under `scripts/persistence/tests/`.

**The runtime workflow currently lists its test suites manually.** [`.github/workflows/runtime-foundation-tests.yml`](../../.github/workflows/runtime-foundation-tests.yml) does not discover `scripts/runtime/tests/*.gd` automatically — each suite is invoked by an explicit `run_suite res://scripts/runtime/tests/<file>.gd <log-name>` line in the workflow. **Every new `scripts/runtime/tests/*.gd` suite must also be added to that workflow file as its own `run_suite` line, in the same pull request that adds the suite** — otherwise the suite exists in the repository but never actually runs in CI, and a red or silently-broken suite would go unnoticed. This document does not itself change the workflow; adding the suite there is part of the change that introduces it.

Run an individual suite directly:

```bash
godot --headless --path . --script res://scripts/runtime/tests/test_stage5_item_generation.gd
```

## Pass/fail rules

- **Every suite must emit an explicit `PASS: <suite name>` marker on stdout.** A suite with no `PASS:` line is treated as failing, even if it exits with code 0.
- **Script errors count as failures.** CI greps captured output for `SCRIPT ERROR`, `PARSER ERROR`, `Parse Error`, and `ASSERTION FAILED`/`^FAIL:` and fails the job if any are present, independent of the process exit code. A test suite is not considered passing when assertion counts are green but the Godot log contains runtime errors.
- A red pipeline blocks merge. Fix the underlying cause — never weaken or remove the check that caught it (see [`Docs/Governance/AI_GUIDELINES.md`](../Governance/AI_GUIDELINES.md)).

## Persistence and JSON round-trip requirements

Per [ADR-015](../ADR/ADR-015-RUNTIME-PERSISTENCE-SYNCHRONIZATION.md) and [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md), `PersistenceService`/`SaveManager` (`scripts/persistence/`) is the only disk-I/O boundary. Every persistence-affecting feature must be exercised through a **real JSON disk-path test**, not just an in-memory snapshot comparison:

```gdscript
var parsed: Variant = JSON.parse_string(JSON.stringify(data))
```

(see `scripts/runtime/tests/test_stage5_generated_rewards.gd` for the established pattern). This matters because Godot's typed arrays (e.g. `Array[Dictionary]`) do not survive a JSON stringify/parse round trip as the same typed structure — they come back as untyped `Array`/`Dictionary` values. ADR-018 requires serialized affix arrays to be explicitly rebuilt as typed `Array[Dictionary]` after JSON parsing so a real disk save restores through the same contract as an in-memory snapshot. **Tests may not rely only on in-memory typed-array preservation** — that passes even when the real disk path would silently corrupt or drop data.

## Deterministic-generation test rules

Per ADR-018's identity/provenance split:

- Deterministic tests must compare **both** rolled values (contents) **and** identity (physical instance ID) — and apply different equality rules to each.
- **Identical generation provenance (same seed, same inputs) may legitimately produce matching contents but must produce distinct physical instance IDs** for two separately-minted items. A test asserting full object equality between two generated items is wrong by construction; assert content equality and identity inequality separately.
- `ItemIdentityService` is the only source of instance IDs during a session (see [`Docs/Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md)); do not fabricate instance IDs in a test.

## Standing bug-pattern log

*(Migrated verbatim from the pre-restructuring root `AGENTS.md`. Keep this list short and category-level. Add an entry only when independent review finds a repeatable failure pattern.)*

### Scene-tree lifecycle and transform ordering

Observed failures:

- Reading or assigning global transforms before a node is inside the scene tree.
- Adding a node whose `_ready()` has gameplay side effects before configuring its final transform, causing one-frame behavior at world origin.

Prevention:

- Complete configuration before `add_child()` whenever `_ready()` can observe the values or trigger gameplay.
- Compute the intended world transform first, convert it through the future parent with `to_local()`, assign the local transform, then attach the node.
- Do not access tree-dependent global transforms until the node is inside the tree.

Regression expectation:

- Include a decoy at world origin and a target at the intended spawn point when testing immediate area effects.
- Assert that the first frame or first pulse affects only the intended location.

### Artifact staging and uploaded-package completeness

Observed failures:

- A staging directory contained the complete Git archive, but `actions/upload-artifact` omitted dotfiles and dot-directories from the downloaded artifact.
- A changed-file manifest could therefore claim files that the formal review package did not actually contain.

Prevention:

- Set `include-hidden-files: true` whenever a complete source tree is uploaded.
- Record the exact Git tree and blob SHA for every tracked file inside the package.
- Download the finished artifact inside CI and verify every uploaded file against the exact commit before declaring the workflow successful.

Regression expectation:

- Assert that representative hidden paths such as `.github/workflows/` survive upload and download.
- Fail CI on any missing tracked path or blob-hash mismatch between Git and the downloaded verifier artifact.

### 3D material fades and invalid CanvasItem properties

Observed failures:

- Tweening `modulate` or `modulate:a` on `MeshInstance3D`. Those properties belong to `CanvasItem`/2D nodes, so Godot logs a runtime error and drops the tween track.
- Assertion-only test scripts can still print `passed` and exit zero while Godot has emitted an engine-level runtime error.

Prevention:

- Fade a unique `StandardMaterial3D` resource through `albedo_color` alpha, with material transparency enabled.
- Do not apply CanvasItem-only visual properties to Node3D-derived objects.
- Avoid tweening a shared material unless every mesh using it is intended to fade together.
- Capture headless test output and fail CI on Godot parser, script, runtime, invalid-property, or engine error lines.

Regression expectation:

- Spawn the real 3D feedback effect under test and assert that its material alpha decreases before cleanup.
- A test suite is not considered passing when assertion counts are green but the Godot log contains runtime errors.

## Every gameplay bug gets a regression test

Per the [Engineering Constitution](../Governance/ENGINEERING_CONSTITUTION.md), every gameplay bug found (by CI, by independent review, or by playtest) receives a regression test before the fix is considered complete — usually by extending an existing suite in `scripts/runtime/tests/` with the failing case, or by adding an entry to the bug-pattern log above if the failure represents a repeatable category rather than a one-off.

## Independent verification pipeline

AbyssFall separates implementation testing (this document) from independent verification. The concrete handoff mechanics — frozen `abyssfall-verifier-*` GitHub Actions artifacts, the verification report template, and the reviewer's required checks — are documented in `docs/CLAUDE_VERIFIER_SETUP.md`, `docs/IMPLEMENTER_VERIFIER_HANDOFF.md`, and `docs/VERIFICATION_REPORT_TEMPLATE.md`. Role ownership for this pipeline is defined in [`Docs/Governance/AI_GUIDELINES.md`](../Governance/AI_GUIDELINES.md).
