# Agent Instructions

## Project rules

- Target **Godot 4.4.1** and GDScript.
- Do not claim a fix passes without running Godot headlessly.
- Preserve current Void Warlock gameplay unless a task explicitly requests a balance change.
- Keep feature work on separate branches and submit reviewable pull requests.
- Prefer reusable character, ability, resource, enemy, item, and encounter components over class-specific conditionals in `main.gd`.
- Do not broadly disable warnings to hide legitimate errors.
- Placeholder geometry is acceptable until mechanics are validated.
- Update the relevant systems document and playtest checklist when behavior changes.

## Design Codex authority

- `docs/codex/` is the canonical source for approved game and playable-class design.
- Before changing a playable class, read that class folder's `README.md` and every Codex document relevant to the task.
- Existing prototype behavior does not override an approved Codex document.
- When code and the Codex disagree, identify the conflict before implementation. Update the code to match, or amend the Codex in the same pull request when the project owner explicitly approves a design change.
- Do not silently simplify, rename, replace, or reinterpret approved mechanics.
- Stable IDs and compatibility IDs must be preserved unless the task explicitly includes a migration and regression coverage.
- Meaningful class-behavior changes require the relevant Codex file and class `CHANGELOG.md` to be updated in the same pull request.
- The current `void_warlock` ID is a compatibility and persistence key during the Voidbringer migration. Do not remove or rename it without an approved save-data migration.
- For Voidbringer work, begin with `docs/codex/characters/voidbringer/README.md`.

## Role separation

AbyssFall separates implementation from independent verification.

### Implementer — architecture, gameplay, and UI

- Own feature branches and implementation files.
- Add or update deterministic tests for new behavior.
- Run the Godot 4.4.1 CI pipeline before handoff.
- Provide the verifier with an exact branch or commit plus a one-line change summary.
- Use the successful PR workflow's frozen `abyssfall-verifier-*` artifact for formal review; do not substitute an untracked local ZIP.
- Check the standing bug-pattern log before handoff and again after any failed review.
- Respond to verification findings with focused fixes.

### Independent verifier — QA and reviewer/integrator

- Verify the exact handed-off branch or commit in an independent environment.
- Use the frozen verifier ZIP as the authority for the verdict even when GitHub-connected source is available.
- Re-run import, headless runtime, and relevant unit tests rather than trusting implementation claims or CI summaries.
- Manually trace new code for lifecycle ordering, input wiring, physics/coordinate math, timing, cleanup, replacement, and overlap bugs.
- Report pass/fail with concrete findings and reproduction details.
- Do not modify implementation code unless the project owner explicitly requests it.

The implementer and verifier must not co-author the same implementation files at the same time. See `docs/IMPLEMENTER_VERIFIER_HANDOFF.md` for the full handoff packet and merge gate.

## Standing bug-pattern log

Keep this list short and category-level. Add an entry only when independent review finds a repeatable failure pattern.

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

## Documentation ownership

- The implementer owns `docs/BASELINE_TEST_RESULTS.md` and keeps it current after accepted milestones and verification-changing fixes.
- The verifier supplies independent results and findings but does not edit that document unless the project owner explicitly requests it.
- The document must clearly separate automated CI, independent verification, and graphical playtest status.
- Approved class-design ownership lives under `docs/codex/characters/<class_id>/`.
- A class's Codex `CHANGELOG.md` records approved design amendments; it is not a substitute for implementation release notes.

## Required validation

Run these commands from the repository root:

```bash
godot --headless --path . --editor --quit
timeout 20s godot --headless --path .
```

The first command must complete without parser, compiler, resource-loading, or import errors. The second may end through the timeout, but its startup output must contain no script or runtime errors.

## Architecture direction

The codebase must support multiple playable classes. Shared systems must not assume every class casts projectiles, uses Corruption, or has the same HUD.

The current `Void Warlock` implementation is a compatibility prototype. The approved replacement design is the Voidbringer Codex under `docs/codex/characters/voidbringer/`. The Penitent uses its own resource and ritual-network identity. Future classes must use reusable shared interfaces without being forced into either prototype's internal assumptions.