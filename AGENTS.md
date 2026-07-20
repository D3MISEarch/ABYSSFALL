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

## Role separation

AbyssFall separates implementation from independent verification.

### Implementer — architecture, gameplay, and UI

- Own feature branches and implementation files.
- Add or update deterministic tests for new behavior.
- Run the Godot 4.4.1 CI pipeline before handoff.
- Provide the verifier with an exact branch or commit plus a one-line change summary.
- Check the standing bug-pattern log before handoff and again after any failed review.
- Respond to verification findings with focused fixes.

### Independent verifier — QA and reviewer/integrator

- Verify the exact handed-off branch or commit in an independent environment.
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

## Documentation ownership

- The implementer owns `docs/BASELINE_TEST_RESULTS.md` and keeps it current after accepted milestones and verification-changing fixes.
- The verifier supplies independent results and findings but does not edit that document unless the project owner explicitly requests it.
- The document must clearly separate automated CI, independent verification, and graphical playtest status.

## Required validation

Run these commands from the repository root:

```bash
godot --headless --path . --editor --quit
timeout 20s godot --headless --path .
```

The first command must complete without parser, compiler, resource-loading, or import errors. The second may end through the timeout, but its startup output must contain no script or runtime errors.

## Architecture direction

The codebase must support multiple playable classes. The Void Warlock uses Corruption; The Penitent uses Fervor and a sigil network. Shared systems must not assume every class casts projectiles, uses Corruption, or has the same HUD.
