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
- Respond to verification findings with focused fixes.

### Independent verifier — QA and reviewer/integrator

- Verify the exact handed-off branch or commit in an independent environment.
- Re-run import, headless runtime, and relevant unit tests rather than trusting implementation claims or CI summaries.
- Manually trace new code for lifecycle ordering, input wiring, physics/coordinate math, timing, cleanup, replacement, and overlap bugs.
- Report pass/fail with concrete findings and reproduction details.
- Do not modify implementation code unless the project owner explicitly requests it.

The implementer and verifier must not co-author the same implementation files at the same time. See `docs/IMPLEMENTER_VERIFIER_HANDOFF.md` for the full handoff packet and merge gate.

## Required validation

Run these commands from the repository root:

```bash
godot --headless --path . --editor --quit
timeout 20s godot --headless --path .
```

The first command must complete without parser, compiler, resource-loading, or import errors. The second may end through the timeout, but its startup output must contain no script or runtime errors.

## Architecture direction

The codebase must support multiple playable classes. The Void Warlock uses Corruption; The Penitent uses Fervor and a sigil network. Shared systems must not assume every class casts projectiles, uses Corruption, or has the same HUD.
