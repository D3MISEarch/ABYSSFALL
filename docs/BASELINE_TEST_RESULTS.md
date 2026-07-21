# AbyssFall Validation and Verification Ledger

## Ownership and status meanings

The implementer owns this ledger. Results are separated into:

- **Automated CI:** repository-controlled Godot validation and deterministic tests.
- **Independent verification:** a separate environment rerunning the exact frozen build and manually tracing relevant code.
- **Graphical playtest:** owner judgment of controls, visuals, readability, camera, and combat feel.

## Current accepted milestone

- Milestone: Penitent combat-feel and DualSense UX baseline through Sacrament
- Engine: Godot 4.4.1 stable
- Latest accepted merge commit: `3619a54f2ebb5850c86668d4694d702f12d5cb6c`
- Full validation run: `29803287315`
- Focused combat/input run: `29803287322`

### Automated CI — PASS

The accepted build passed:

- Godot editor/import/parser/resource loading
- All ten maintained deterministic suites
- Ritual Blade geometry, integration, hit/miss feedback, and material-fade tests
- Keyboard/mouse, PlayStation-family, and Xbox-family prompt-profile tests
- Strict detection of Godot engine, script, runtime, and invalid-property errors
- Class-selection, Void Warlock, and Penitent runtime smoke tests
- Frozen verifier package creation, upload, download, and Git-blob audit

## PR #24 — Penitent combat feel and DualSense UX

- Pull request: `#24`
- Final reviewed commit: `6608fd244d3ab831d977b28bca3b8c2bea07a932`
- Merge commit: `3619a54f2ebb5850c86668d4694d702f12d5cb6c`
- Frozen artifact: `abyssfall-verifier-pr24-6608fd2`
- Artifact SHA-256: `7cfba1e31c3f82812409772f062c71b9d211482ef3bb34e9eee189cf61b25a82`
- Package integrity: all **107 tracked files** independently matched
- Independent verdict: **PASS**

The verifier confirmed:

1. Ritual Blade uses a 3.35-unit, 136-degree frontal cleave.
2. Rear targets are excluded by the arc math.
3. The step-in is bounded and collision-respecting.
4. The 10/12/18 combo remains unchanged.
5. Ritual Blade, Brand of Ruin, and Crypt Brute feedback fade valid `StandardMaterial3D.albedo_color` alpha.
6. The fade regression polls `process_frame` until near-zero alpha or a one-second timeout, avoiding headless tween-start races.
7. All ten suites and runtime paths completed without stray engine errors.

### PR #24 review history

- Initial result: **PASS WITH FOLLOW-UP** after invalid `modulate:a` tweens were found on 3D meshes.
- Follow-up gameplay fix: fade unique 3D materials and record the bug pattern in `AGENTS.md`.
- Second result: **FAIL** because the new test used a brittle fixed-duration sample in headless mode.
- Final fix: gameplay unchanged; test replaced with frame-based polling and a hard timeout.
- Final result for `6608fd2`: **PASS**.

## Graphical playtest status

The first Windows playtest confirmed smooth movement/camera, working skills/dodge, natural enemy spawning, and stronger initial playability for the ranged Void Warlock. It also found the Penitent's original basic-attack range too punishing.

PR #24 is accepted for code and automated behavior. Issues `#21` and `#22` remain open until the owner confirms on Windows with a real DualSense controller:

- Actual DualSense device-name detection
- Live prompt switching between mouse/keyboard and controller
- Subjective Ritual Blade reach, step-in, slash readability, and survivability

Use `docs/SPRINT1_PENITENT_DUALSENSE_PLAYTEST.md` for the focused retest.

## Earlier accepted milestones

### PR #20 — Canonical Seal placement

- Reviewed commit: `f8307f450dd40cb405e957e9dd198e0dc0becea0`
- Merge commit: `3f699a89572a27b36fdda4d9b884e78365fd189f`
- Validation run: `29791730406`
- Independent verdict: **PASS**
- Package integrity: **105 tracked files** independently matched

The safe position-before-attach implementation now exists once in `PenitentCharacter`, the duplicate leaf override is gone, and the origin-decoy regression tests the canonical base class.

### PR #19 — Full-project audit

- Reviewed commit: `d3b4568a03930758b24e179de7b23e0d6c5d60b8`
- Validation run: `29788549420`
- Independent verdict: **PASS WITH FOLLOW-UP**
- Package integrity: **102 tracked files** independently matched

The audit found the shadowed Seal implementation and stale Ritual Blade documentation. PR #20 closed both findings. PR #19 remained review-only and was closed without merge.

### PR #18 — Frozen verifier pipeline

- Merge commit: `6b08e360c6730c232403f0731ea097d765bbc83d`
- Validation run: `29782547735`
- Independent verdict: **PASS**
- Package integrity: **101 tracked files** independently matched

The verifier package includes hidden files, records every tracked Git blob, is downloaded back inside CI, and fails on missing paths or content mismatches.

## Standard validation commands

```bash
godot --headless --path "$PROJECT_DIR" --editor --quit
timeout 20s godot --headless --path "$PROJECT_DIR"
```

A timeout status of `124` is acceptable only when startup output contains no parser, compiler, script-loading, invalid-access, scene-tree, or runtime errors.

## Original stable baseline

- Build: Void Warlock v0.4 Hotfix 3 — The Sunken Crypts
- Branch: `import-v0.4-hotfix3`
- Validation run: `29767727869`
