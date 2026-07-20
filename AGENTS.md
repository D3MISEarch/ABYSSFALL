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

## Required validation

Run these commands from the repository root:

```bash
godot --headless --path . --editor --quit
timeout 20s godot --headless --path .
```

The first command must complete without parser, compiler, resource-loading, or import errors. The second may end through the timeout, but its startup output must contain no script or runtime errors.

## Architecture direction

The codebase must support multiple playable classes. The Void Warlock uses Corruption; The Penitent uses Fervor and a sigil network. Shared systems must not assume every class casts projectiles, uses Corruption, or has the same HUD.
