# Contributing

This file covers the mechanics of contributing a change. For the rules governing *what* a change is allowed to do architecturally, see [`Docs/Governance/ENGINEERING_CONSTITUTION.md`](Docs/Governance/ENGINEERING_CONSTITUTION.md). For AI-specific obligations, see [`Docs/Governance/AI_GUIDELINES.md`](Docs/Governance/AI_GUIDELINES.md) and, if you are Claude Code, [`CLAUDE.md`](CLAUDE.md).

## Before you start

1. Read [`AGENTS.md`](AGENTS.md)'s required reading order.
2. Check [`Docs/Roadmap/`](Docs/Roadmap/) for the current stage — know what's already in flight before starting related work.
3. Check [`Docs/ADR/`](Docs/ADR/) for any decision already governing the area you're touching.

## Branch and review policy

*(Migrated from the pre-restructuring root `AGENTS.md` "Project rules" and `PROJECT_OVERVIEW.md` "Branch and review policy.")*

- One focused feature or fix per branch.
- Every branch should have explicit acceptance criteria before work starts.
- Every pull request must show what tests were run and state known limitations.
- No feature branch may silently change another class's or another system's behavior.
- Keep feature work on separate branches and submit reviewable pull requests — do not commit directly to a long-lived base branch (`main`, or the active stage integration branch).

## Placeholder art and content

Placeholder geometry and placeholder art are acceptable until mechanics are validated — do not block a gameplay PR on final art. Final character art, bosses, networking, and mobile polish wait until the relevant gameplay foundation is proven (see the phase sequencing in `PROJECT_OVERVIEW.md`).

## Before requesting review

- Run the required validation in [`Docs/Standards/TESTING.md`](Docs/Standards/TESTING.md) and confirm every affected suite emits its `PASS:` marker with no script/runtime errors in the log.
- If your change alters a public system contract, update the owning document per [`Docs/Standards/DOCUMENTATION.md`](Docs/Standards/DOCUMENTATION.md) in the same PR.
- If your change required a new architectural decision, make sure the ADR exists and is linked from your PR description.

## Independent verification

Some changes go through an additional independent-verifier pass before merge (see [`Docs/Governance/AI_GUIDELINES.md`](Docs/Governance/AI_GUIDELINES.md) and `docs/IMPLEMENTER_VERIFIER_HANDOFF.md`). Provide the verifier with an exact branch or commit and a one-line change summary; do not substitute an untracked local build for the tracked verifier artifact.
