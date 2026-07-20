# AbyssFall Baseline Test Results

## Baseline

- Build: Void Warlock v0.4 Hotfix 3 — The Sunken Crypts
- Engine: Godot 4.4.1 stable, Linux x86_64 headless
- Repository branch: `import-v0.4-hotfix3`
- GitHub Actions workflow: `Validate AbyssFall Hotfix 3`
- Successful validation run: `29767727869`

## Commands

Editor, parser, resource import, and main-scene load validation:

```bash
godot --headless --path "$PROJECT_DIR" --editor --quit
```

Bounded runtime smoke test:

```bash
timeout 20s godot --headless --path "$PROJECT_DIR"
```

The workflow accepts normal completion or timeout exit status `124`, but fails if output includes parser, compiler, script-loading, invalid-access, scene-tree, or runtime error patterns.

## Results

- Godot 4.4.1 installation: **passed**
- Repository checkout: **passed**
- Project discovery at repository root: **passed**
- Editor/parser/import validation: **passed**
- Runtime smoke test: **passed**
- Validation log upload: **passed**
- Overall GitHub Actions conclusion: **success**

## Verified project contents

- `project.godot` exists at the repository root.
- `main.tscn` exists at the repository root.
- Current GDScript files load under Godot 4.4.1.
- The archived source was promoted into normal repository files.
- Godot-generated UID and import metadata required by the promoted project are included.

## Limitations

Headless validation proves startup, script parsing, resource loading, and a bounded runtime launch. It does not replace a human graphical playtest for controls, camera feel, combat tuning, UI readability, progression balance, or the complete Hollow King encounter.

The next human test should use `docs/v0.4-hotfix3/PLAYTEST_CHECKLIST.md` on the home PC.
