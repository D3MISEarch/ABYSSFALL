# AbyssFall Validation and Verification Ledger

## Ownership

The implementer owns this document and updates it after accepted milestones or fixes that change verification status. The independent verifier reports results and findings but does not edit this file unless the project owner explicitly requests it.

Status is recorded separately for:

- **Automated CI:** repository-controlled Godot validation and deterministic tests.
- **Independent verification:** a separate environment rerunning the exact handed-off build and manually tracing relevant code paths.
- **Graphical playtest:** human judgment of controls, visuals, readability, camera behavior, and combat feel.

## Current validated gameplay milestone

- Milestone: Penitent vertical slice through Sacrament, including canonical Seal of Binding placement and the origin-pulse regression guard
- Engine: Godot 4.4.1 stable, Linux x86_64 headless
- Latest accepted merge commit: `3f699a89572a27b36fdda4d9b884e78365fd189f`
- Latest successful validation run: `29791730406`
- Workflow: `Validate AbyssFall`

### Automated gameplay CI — passed

- Editor, parser, resource import, and scene loading
- Fervor resource tests
- Fervor seal HUD tests
- Rite Mark tests
- Seal of Binding tests
- Canonical base-class Seal initial-position regression using an origin decoy and intended placement target
- Brand of Ruin tests
- Martyr's Chain tests
- Ashen Procession tests
- Sacrament tests
- Class-selection startup smoke test
- Void Warlock runtime regression smoke test
- Fully composed Penitent runtime smoke test
- Verifier-package build, upload, download, and Git-blob audit
- Validation-log artifact upload

### Independently verified gameplay behavior

An independent verifier:

- Imported the repository in a separate sandbox.
- Re-ran all eight deterministic Penitent system suites.
- Ran the maintained scene/runtime paths headlessly under Godot 4.4.1.
- Traced ability-to-input wiring and scene-tree behavior.
- Identified the original Seal of Binding lifecycle-order bug where `_ready()` could pulse at world origin before final positioning.
- Confirmed the corrected project imports cleanly and the full automated gameplay suite remains green.

The Seal finding is now structurally closed: the safe position-before-attach implementation lives once in `PenitentCharacter`, every current and future Penitent subclass inherits it, and the origin-decoy regression test instantiates that canonical base class directly.

## Full-project independent audit

- Review pull request: `#19` — Freeze complete project for independent audit
- Reviewed commit: `d3b4568a03930758b24e179de7b23e0d6c5d60b8`
- Successful validation run: `29788549420`
- Independent verdict: **PASS WITH FOLLOW-UP**
- Package integrity: all **102 tracked files** present and byte-identical to the reviewed commit

### Confirmed project-wide results

- Godot 4.4.1 import completed cleanly.
- All eight deterministic suites passed independently.
- Maintained scenes idled headlessly without errors or warnings.
- Independent SHA-256 comparison found zero mismatches across all 102 tracked files.
- Independent `git hash-object` results matched `VERIFIER_GIT_TREE.txt` for all 102 files.
- No blocking gameplay or tooling defects were found.

### Audit follow-up resolution — passed

- Follow-up pull request: `#20` — Canonicalize Penitent Seal placement
- Independently reviewed commit: `f8307f450dd40cb405e957e9dd198e0dc0becea0`
- Merge commit: `3f699a89572a27b36fdda4d9b884e78365fd189f`
- Successful validation run: `29791730406`
- Independent verdict: **PASS**
- Package integrity: all **105 tracked files** present, byte-identical, and independently matched against `VERIFIER_GIT_TREE.txt`

The verifier confirmed that:

1. `_place_seal_of_binding()` now exists exactly once, in `penitent_character.gd`.
2. The seal's intended local position is assigned before `add_child()`, preventing the first `_ready()` pulse from occurring at world origin.
3. The shadowing override was removed from `penitent_playable.gd`, closing the future-refactor regression risk.
4. The regression test now instantiates `PenitentCharacter` directly, so every future Penitent subclass inherits the guarded behavior.
5. `docs/PENITENT_CLASS.md` now describes Ritual Blade's real three-hit 10/12/18 sequence instead of calling it a placeholder.

All PR #19 follow-up findings are closed. PR #19 was closed without merge as a review-only branch; PR #20 was independently approved and merged.

## Independent verifier artifact pipeline

- Milestone: complete, self-auditing frozen verifier packages
- Pull request: `#18` — Guarantee verifier artifact completeness
- Reviewed commit: `949a6afff355dcd972cf5c416d39d9bbeffd7b5c`
- Merge commit: `6b08e360c6730c232403f0731ea097d765bbc83d`
- Successful validation run: `29782547735`
- Independent verdict: **PASS**

### Automated artifact validation — passed

- Exact pull-request head checkout
- Complete Godot 4.4.1 parser/import/test/runtime pipeline
- Hidden files included during artifact upload
- Git-tree manifest generated for every tracked file
- Staged package audited against the exact commit
- Uploaded artifact downloaded back inside CI
- Downloaded artifact audited against every tracked Git blob
- CI failure guard for missing paths or content mismatches

### Independent artifact verification — passed

The independent verifier confirmed from scratch that:

- All **101 tracked files** were present in the frozen PR #18 package.
- `.github/pull_request_template.md` was present.
- `.github/workflows/godot-hotfix3-validation.yml` was present.
- `docs/IMPLEMENTER_VERIFIER_HANDOFF.md` was present.
- SHA-256 comparison across all 101 tracked files produced zero mismatches.
- Independent `git hash-object` results for all 101 files matched `VERIFIER_GIT_TREE.txt` exactly.
- The original PR #17 hidden-file omission could no longer be reproduced.

The verifier also corrected its own earlier false report that `docs/IMPLEMENTER_VERIFIER_HANDOFF.md` was missing; that file had been present, and the false alarm came from an over-broad local exclusion filter.

## Graphical playtest status

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
