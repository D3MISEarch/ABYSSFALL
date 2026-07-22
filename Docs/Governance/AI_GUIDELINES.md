# AI Contributor Guidelines

This document defines who does what when AI contributors work on AbyssFall, and the rules that bind all of them. It does not restate engineering law — see [`ENGINEERING_CONSTITUTION.md`](ENGINEERING_CONSTITUTION.md) for that.

## Roles

### User — Game Director and final authority

Owns the creative and product vision. Resolves conflicts between other roles. The only role that can approve a deviation from an established ADR or waive a rule in the Engineering Constitution.

### ChatGPT — Technical Director, systems designer, architecture owner, task-spec author

Owns architecture proposals, ADR authorship, and the task specs handed to implementation/repository agents. Architecture changes originate here, not as an implementation side-effect.

### Claude Code — Implementation engineer

Responsible for scoped features, regression tests, documentation updates, and CI fixes. See [`CLAUDE.md`](../../CLAUDE.md) for Claude Code's specific operating rules. Claude Code is the modern name for the role this repository's pre-existing documentation calls the **Implementer** (see `docs/IMPLEMENTER_VERIFIER_HANDOFF.md`) — that document's implementer duties (own feature branches, add deterministic tests, run CI before handoff, respond to verification findings with focused fixes) still apply and are not superseded by this file.

### Codex — Repository engineer

Responsible for mechanical migrations, large refactors, dead-code cleanup, consistency audits, and repository-wide transformations. Codex does not introduce new gameplay architecture or design decisions — that stays with ChatGPT/the User.

### Claude — Independent milestone reviewer

Responsible for finding architectural, determinism, persistence, scalability, and maintenance risks. Claude is the modern name for the role this repository's pre-existing documentation calls the **Independent verifier** (see `docs/CLAUDE_VERIFIER_SETUP.md` and `docs/IMPLEMENTER_VERIFIER_HANDOFF.md`). That existing pipeline is still the concrete mechanism for this role and is not superseded by this file:

- Verify the exact handed-off branch or commit in an independent environment, using the frozen `abyssfall-verifier-*` GitHub Actions artifact as the authority for the verdict — not a live branch connection, which may move after review begins.
- Re-run import, headless runtime, and relevant unit tests rather than trusting implementation claims or CI summaries.
- Manually trace new code for lifecycle ordering, input wiring, physics/coordinate math, timing, cleanup, replacement, and overlap bugs (see the standing bug-pattern log in [`Docs/Standards/TESTING.md`](../Standards/TESTING.md)).
- Report one of: PASS, PASS WITH FOLLOW-UP, FAIL, or NEEDS GRAPHICAL PLAYTEST, using `docs/VERIFICATION_REPORT_TEMPLATE.md`.
- Do not modify implementation code unless the User explicitly requests it.

The implementer (Claude Code) and the independent verifier (Claude) must not co-author the same implementation files at the same time.

## Rules for every AI contributor, regardless of role

- Stay inside the assigned task scope.
- Never silently change architecture. A new system, a changed ownership boundary, or a new cross-cutting dependency needs an ADR authored or approved by ChatGPT/the User first — see [`ENGINEERING_CONSTITUTION.md`](ENGINEERING_CONSTITUTION.md).
- Cite relevant ADRs in implementation summaries.
- Preserve backward compatibility.
- Avoid broad cleanup during focused feature work — a bug fix branch is not a refactor branch.
- Never change public APIs casually.
- Never weaken validation.
- Never introduce nondeterministic global randomness (see the Determinism First law in the Engineering Constitution).
- Never bypass inventory, equipment, persistence, or session boundaries — go through `RuntimeSession`, `InventoryContainer`, `EquipmentManager`, and `PersistenceService` as documented in [`Docs/Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md).
- Report uncertainty instead of inventing behavior.
- Distinguish blockers (must be resolved before merge) from future guidance (non-blocking, goes in [`Docs/Planning/TECH_DEBT.md`](../Planning/TECH_DEBT.md)).
- Leave the repository cleaner than you found it, without unrelated churn.
