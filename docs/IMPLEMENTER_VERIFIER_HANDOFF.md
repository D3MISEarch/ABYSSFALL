# Implementer–Verifier Handoff

AbyssFall uses a role-separated development workflow so implementation and independent verification remain additive rather than colliding.

## Roles

### Implementer

Owns architecture, gameplay, UI, documentation updates, automated test additions, and feature branches.

Responsibilities:

- Work on a dedicated branch.
- Keep changes focused and reviewable.
- Add or update deterministic tests for new logic.
- Run the repository's Godot 4.4.1 CI pipeline.
- Do not merge solely because the implementation's own CI passed when independent review is requested.
- Prepare a handoff package or branch link for the verifier.
- Include a one-line change summary and the exact branch or commit being reviewed.

### Independent verifier

Owns QA, code-path review, and integration recommendations.

Responsibilities:

- Verify the exact handed-off branch or commit.
- Run Godot import/editor validation independently.
- Run the relevant headless runtime paths independently.
- Re-run existing and new unit tests independently.
- Trace the new code manually for bugs that automated tests may miss, especially:
  - scene-tree lifecycle and ordering
  - input routing and controller mappings
  - physics and coordinate-space math
  - timing, cooldown, and state-transition edges
  - cleanup, death, replacement, and overlapping-effect behavior
- Report pass or fail with concrete findings.
- Do not write implementation code into the repository unless the project owner explicitly requests it.

## Handoff packet

Every implementation handoff should contain:

1. **Change:** one sentence describing what was added or changed.
2. **Branch/commit:** the exact branch name and commit SHA.
3. **Files changed:** a short list of the main implementation and test files.
4. **Expected behavior:** the player-facing result.
5. **Automated validation:** the CI run and which suites passed.
6. **Known unverified areas:** graphical feel, readability, controller interaction, or other items requiring manual play.
7. **Build access:** a repository branch ZIP, source archive, or exact branch link.

Example:

> Change: Added Cathedral of Flesh as the Penitent's ritual-network ultimate.
>
> Review: `agent/cathedral-of-flesh` at `<commit-sha>`.

## Merge gate

The project owner decides the outcome after independent verification:

- **Pass:** merge or retain the already-merged change.
- **Pass with follow-up:** merge, then open focused issues for non-blocking findings.
- **Fail:** return the branch to the implementer with specific reproduction details.
- **Needs graphical playtest:** keep implementation status explicit and do not claim feel/readability is verified.

## Collision rule

The implementer and verifier do not co-author the same implementation files at the same time. The verifier reports findings; the implementer owns fixes unless the project owner explicitly changes that assignment.
