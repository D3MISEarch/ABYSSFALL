# Claude Code Instructions for AbyssFall

## Required project context

AbyssFall targets **Godot 4.4.1** and GDScript.

Read the root `AGENTS.md` before implementation. Its architecture, verification, artifact and bug-pattern rules are mandatory.

## Design Codex

`docs/codex/` is the canonical source of approved design.

Before changing a playable class:

1. Open `docs/codex/README.md`.
2. Open the class folder `README.md`.
3. Read every document listed as relevant to the requested task.
4. Inspect the current implementation and tests.
5. Report conflicts between implementation and Codex before changing behavior.

Do not treat old prototype code as design authority when an approved Codex exists.

## Voidbringer

Before any Voidbringer or current Void Warlock task, read:

- `docs/codex/characters/voidbringer/README.md`

Then read the task-specific files referenced there.

The approved class is **Voidbringer**.

The repository currently uses `void_warlock` as a compatibility and persistence ID. Preserve that ID until a dedicated save-migration task explicitly replaces it.

Do not silently restore or preserve old Void Warlock concepts that conflict with the Codex, including generic shadow-mage identity, Corruption-centered design or the Abyss/Corruption/Soulbinding branches.

## Approved-change rules

- Do not simplify, rename or replace an approved mechanic without explicit project-owner approval.
- A meaningful behavior change must update the relevant Codex document and class `CHANGELOG.md` in the same pull request.
- Preserve stable implementation IDs unless migration is part of the task.
- Keep implementation changes on feature branches.
- Add deterministic tests for new behavior.
- Run Godot headlessly before claiming success.
- Never claim CI or runtime success without actual command output.

## Implementation style

Prefer:

- Reusable Resources for immutable definitions
- Focused runtime managers for mutable state
- Signals or a combat event bus for presentation and telemetry
- Shared force, status, projectile, item and encounter systems
- Composition over giant class-specific scripts

Avoid:

- Class conditionals scattered through global gameplay code
- Abilities directly controlling damage, UI, VFX, audio and AI at once
- Binary boss immunity when a mechanic can convert into stance, rotation, armor stress or another response
- Hard-coded display names as save or telemetry keys
- Introducing all class abilities in one oversized pull request

## Verification

Run from the repository root:

```bash
godot --headless --path . --editor --quit
timeout 20s godot --headless --path .
```

Also run all task-specific tests and existing CI workflows.

A green assertion count does not override Godot parser, runtime, invalid-property or engine errors in the logs.

## Handoff

For implementation work, provide:

- Exact branch or commit
- Concise change summary
- Files changed
- Commands run
- Test results
- Known risks
- Required manual playtest

Use the repository's implementer/verifier handoff workflow. Do not substitute an untracked local ZIP for the frozen verifier artifact.