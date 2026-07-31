# Contributing

This file covers the mechanics of contributing a change. For the rules governing *what* a change is allowed to do architecturally, see [`Docs/Governance/ENGINEERING_CONSTITUTION.md`](Docs/Governance/ENGINEERING_CONSTITUTION.md). For the binding production-scope doctrine, see [`Docs/Design/GAMEPLAY_BIBLE.md`](Docs/Design/GAMEPLAY_BIBLE.md). For AI-specific obligations, see [`Docs/Governance/AI_GUIDELINES.md`](Docs/Governance/AI_GUIDELINES.md) and, if you are Claude Code, [`CLAUDE.md`](CLAUDE.md).

## Before you start

1. Read [`AGENTS.md`](AGENTS.md)'s required reading order.
2. Read [`Docs/Design/GAMEPLAY_BIBLE.md`](Docs/Design/GAMEPLAY_BIBLE.md) and confirm the work belongs to the active operation.
3. Check [`Docs/Roadmap/CURRENT_SLICE.md`](Docs/Roadmap/CURRENT_SLICE.md) for the exact current gate and work already in flight.
4. Check [`Docs/ADR/`](Docs/ADR/) for any decision already governing the area you're touching.

If the proposed work belongs to OP2 or another future operation, do not begin it until the owner explicitly opens that operation.

## Branch and review policy

*(Migrated from the pre-restructuring root `AGENTS.md` "Project rules" and `PROJECT_OVERVIEW.md` "Branch and review policy.")*

- One focused feature or fix per branch.
- Every branch should have explicit acceptance criteria before work starts.
- Every pull request must show what tests were run and state known limitations.
- No feature branch may silently change another class's or another system's behavior.
- Keep feature work on separate branches and submit reviewable pull requests — do not commit directly to a long-lived base branch (`main`, or the active stage integration branch).
- Do not disguise future-operation work as infrastructure, preparation, cleanup, harmless scaffolding, or a generalized framework.
- A hypothetical collaborator, contractor, publisher, or funding event may not be treated as a dependency of the change.

## Placeholder art and content

Placeholder geometry and placeholder art are acceptable while mechanics and pipelines are being validated. Do not block a focused gameplay PR on unrelated final art.

That does not lower OP1's final acceptance bar. The bounded OP1 slice must eventually receive the owner-approved lighting, materials, atmosphere, VFX, audio, animation, UI, camera, and cinematic presentation needed to feel like a coherent game.

Final art for unopened classes or realms, networking, platform expansion, and other future-operation polish wait until their operation is explicitly opened. See the operation sequencing in [`Docs/Design/GAMEPLAY_BIBLE.md`](Docs/Design/GAMEPLAY_BIBLE.md) and [`PROJECT_OVERVIEW.md`](PROJECT_OVERVIEW.md).

## Before requesting review

- Run the required validation in [`Docs/Standards/TESTING.md`](Docs/Standards/TESTING.md) and confirm every affected suite emits its `PASS:` marker with no script/runtime errors in the log.
- Confirm the result advances the active player-visible operation rather than only increasing speculative infrastructure.
- If your change alters a public system contract, update the owning document per [`Docs/Standards/DOCUMENTATION.md`](Docs/Standards/DOCUMENTATION.md) in the same PR.
- If your change required a new architectural decision, make sure the ADR exists and is linked from your PR description.
- State explicitly what remains outside the active operation so the PR cannot be misread as reopening future scope.

## Independent verification

Some changes go through an additional independent-verifier pass before merge (see [`Docs/Governance/AI_GUIDELINES.md`](Docs/Governance/AI_GUIDELINES.md) and `Docs/IMPLEMENTER_VERIFIER_HANDOFF.md`). Provide the verifier with an exact branch or commit and a one-line change summary; do not substitute an untracked local build for the tracked verifier artifact.
