# AbyssFall Validation and Verification Ledger

## Ownership

The implementer owns this document and updates it after accepted milestones or fixes that change verification status. The independent verifier reports results and findings but does not edit this file unless the project owner explicitly requests it.

Status is recorded separately for:

- **Automated CI:** repository-controlled Godot validation and deterministic tests.
- **Independent verification:** a separate environment rerunning the exact handed-off build and manually tracing relevant code paths.
- **Graphical playtest:** human judgment of controls, visuals, readability, camera behavior, and combat feel.

## Current validated gameplay milestone

- Milestone: Penitent vertical slice through Sacrament, including the Seal of Binding spawn-order regression fix
- Engine: Godot 4.4.1 stable, Linux x86_64 headless
- Gameplay merge commit: `f9a0e5fdec1acd77e8df924d36b52b4205b04104`
- Successful GitHub Actions run: `29778284122`
- Workflow: `Validate AbyssFall`

### Automated CI — passed

- Editor, parser, resource import, and scene loading
- Fervor resource tests
- Fervor seal HUD tests
- Rite Mark tests
- Seal of Binding tests
- Seal initial-position regression using an origin decoy and intended placement target
- Brand of Ruin tests
- Martyr's Chain tests
- Ashen Procession tests
- Sacrament tests
- Class-selection startup smoke test
- Void Warlock runtime regression smoke test
- Fully composed Penitent runtime smoke test
- Validation-log artifact upload

### Independently verified behavior

An independent verifier previously:

- Imported the repository in a separate sandbox.
- Re-ran the available deterministic test suites.
- Ran class-selection and gameplay scenes headlessly.
- Traced ability-to-input wiring.
- Identified the Seal of Binding lifecycle-order bug where `_ready()` could pulse at world origin before final positioning.

The finding was fixed by assigning the seal's local transform before attaching it to the scene tree, and an exact regression test now covers the failure pattern.

### Independent re-verification status

- Exact merged spawn-order fix: **pending independent re-verification**
- Repository CI after the fix: **passed**

### Graphical playtest status

Still required on a graphical desktop build. Headless validation cannot establish:

- Ritual Blade hit feel and attack readability
- Seal boundary and chain readability
- Brand targeting confidence
- Martyr's Chain pull and collision feel
- Ashen Procession trail visibility and natural recross routing
- Sacrament blood-payment tension and cathedral-effect clarity
- Controller navigation and focus behavior
- Camera feel, combat pacing, progression balance, and complete Hollow King encounter quality

Use `docs/PENITENT_PLAYTEST.md` for the current Penitent checklist and `docs/v0.4-hotfix3/PLAYTEST_CHECKLIST.md` for the original run-wide checks.

## Standard commands

Editor, parser, resource import, and main-scene load validation:

```bash
godot --headless --path "$PROJECT_DIR" --editor --quit
```

Bounded runtime smoke test:

```bash
timeout 20s godot --headless --path "$PROJECT_DIR"
```

A timeout exit status of `124` is acceptable for the bounded runtime when startup output contains no parser, compiler, script-loading, invalid-access, scene-tree, or runtime errors.

## Original stable baseline

- Build: Void Warlock v0.4 Hotfix 3 — The Sunken Crypts
- Repository branch: `import-v0.4-hotfix3`
- Successful validation run: `29767727869`

Original baseline results:

- Godot 4.4.1 installation: **passed**
- Repository checkout: **passed**
- Project discovery at repository root: **passed**
- Editor/parser/import validation: **passed**
- Runtime smoke test: **passed**
- Validation-log upload: **passed**
- Overall GitHub Actions conclusion: **success**

The original archive was promoted into normal repository files with `project.godot`, `main.tscn`, scripts, required UID/import metadata, documentation, and concept assets at their maintained repository locations.
