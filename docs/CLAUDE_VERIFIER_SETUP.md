# Claude Independent Verifier Setup

This guide prepares Claude to act as AbyssFall's independent QA and reviewer/integrator without sharing implementation ownership.

## One-time repository connection

When the GitHub connection is available, connect Claude to `D3MISEarch/ABYSSFALL` and include at minimum:

- `AGENTS.md`
- `project.godot`
- `main.tscn`
- `scripts/`
- `tests/`
- `docs/`
- `.github/workflows/`

The repository connection is for navigation, code reading, and awareness of the maintained project. It is not the authority for a formal pass/fail verdict because the connected branch may move after a review begins.

## Formal review authority

For every feature review, use the GitHub Actions artifact named like:

```text
abyssfall-verifier-pr<PR_NUMBER>-<SHORT_SHA>
```

The artifact contains a ZIP with:

- the complete source tree from the exact tested commit
- `VERIFIER_HANDOFF.md`
- `VERIFIER_CHANGED_FILES.txt`
- the current bug-pattern log and verification report template

The ZIP is the frozen build Claude certifies. The branch connection may be used to browse surrounding history or current files, but the verdict must name the ZIP's full commit SHA.

## Before each review

1. Read `VERIFIER_HANDOFF.md` inside the ZIP.
2. Confirm the requested branch and full commit SHA.
3. Read `VERIFIER_CHANGED_FILES.txt` to focus the manual trace.
4. Read the standing bug-pattern log in `AGENTS.md`.
5. Extract the ZIP into a clean folder rather than overwriting a previous review folder.
6. Use Godot 4.4.1 for import, tests, and runtime checks.

## Independent verification duties

Claude should independently:

- import and parse the exact package
- run every relevant deterministic test
- launch class selection and both playable-class runtime paths
- manually trace the changed code for scene-tree lifecycle, transform order, input routing, physics and coordinate math, timing, cleanup, replacement, and overlap behavior
- clearly separate code correctness from graphical feel
- report concrete reproduction steps for every failure

Claude should not modify implementation files unless the project owner explicitly assigns implementation work.

## Report delivery

Use `docs/VERIFICATION_REPORT_TEMPLATE.md` and return one verdict:

- PASS
- PASS WITH FOLLOW-UP
- FAIL
- NEEDS GRAPHICAL PLAYTEST

The report should identify the exact commit, commands run, tests executed, manual trace areas, findings, and remaining graphical-only questions.
