# Implementer–Verifier Handoff

AbyssFall uses a role-separated development workflow so implementation and independent verification remain additive rather than colliding.

## Roles

### Implementer

Owns architecture, gameplay, UI, documentation updates, automated test additions, and feature branches.

Responsibilities:

- Work on a dedicated branch.
- Keep changes focused and reviewable.
- Add or update deterministic tests for new logic.
- Check the standing bug-pattern log in `AGENTS.md` before handoff and after any failed review.
- Run the repository's Godot 4.4.1 CI pipeline.
- Do not merge solely because the implementation's own CI passed when independent review is requested.
- Prepare a handoff package or branch link for the verifier.
- Include a one-line change summary and the exact branch or commit being reviewed.
- Own and update `docs/BASELINE_TEST_RESULTS.md` whenever an accepted milestone or verification-changing fix changes project status.

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
- Check new work against the standing bug-pattern log without assuming the implementation already handled those categories.
- Report pass or fail with concrete findings.
- Do not write implementation code or update the shared baseline ledger unless the project owner explicitly requests it.

## Automatic frozen package

Every successful pull-request validation run creates a GitHub Actions artifact named:

```text
abyssfall-verifier-pr<PR_NUMBER>-<SHORT_SHA>
```

The artifact contains one ZIP built from `git archive` at the exact tested commit. It includes:

- the complete tracked source tree
- `VERIFIER_HANDOFF.md` with branch, commit, pull request, CI run, and review instructions
- `VERIFIER_CHANGED_FILES.txt` with the exact diff file list
- `AGENTS.md` and its standing bug-pattern log
- `docs/VERIFICATION_REPORT_TEMPLATE.md`

The frozen ZIP is the authority for the independent verdict. A GitHub-connected repository may be used for convenient navigation, but it must not replace the exact package because the live branch can move after review begins.

Artifacts are retained for 30 days. A refreshed commit produces a new artifact and invalidates any unfinished verdict on the previous package unless the project owner explicitly accepts the older scope.

## Handoff packet

Every implementation handoff should contain:

1. **Change:** one sentence describing what was added or changed.
2. **Branch/commit:** the exact branch name and commit SHA.
3. **Files changed:** a short list of the main implementation and test files.
4. **Expected behavior:** the player-facing result.
5. **Automated validation:** the CI run and which suites passed.
6. **Known unverified areas:** graphical feel, readability, controller interaction, or other items requiring manual play.
7. **Bug-pattern check:** which standing patterns were relevant and how they were prevented or tested.
8. **Build access:** the successful workflow's `abyssfall-verifier-*` artifact.

Example:

> Change: Added Cathedral of Flesh as the Penitent's ritual-network ultimate.
>
> Review: `agent/cathedral-of-flesh` at `<commit-sha>`.
>
> Artifact: `abyssfall-verifier-pr17-<short-sha>`.
>
> Bug-pattern check: All spawned ritual nodes receive configuration and local transforms before entering the scene tree.

## Verifier report

The verifier returns `docs/VERIFICATION_REPORT_TEMPLATE.md` completed with one verdict:

- **PASS**
- **PASS WITH FOLLOW-UP**
- **FAIL**
- **NEEDS GRAPHICAL PLAYTEST**

Every report names the full commit SHA and ZIP artifact. Findings include concrete code paths and reproduction steps rather than general impressions.

## Merge gate

The project owner decides the outcome after independent verification:

- **Pass:** merge or retain the already-merged change.
- **Pass with follow-up:** merge, then open focused issues for non-blocking findings.
- **Fail:** return the branch to the implementer with specific reproduction details.
- **Needs graphical playtest:** keep implementation status explicit and do not claim feel/readability is verified.

After the decision, the implementer updates `docs/BASELINE_TEST_RESULTS.md` so automated CI, independent verification, and graphical playtest status remain visibly separate.

## Collision rule

The implementer and verifier do not co-author the same implementation files at the same time. The verifier reports findings; the implementer owns fixes unless the project owner explicitly changes that assignment.
