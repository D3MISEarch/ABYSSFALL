# Documentation Standards

## The core rule

**Documentation must change when a public system contract changes.** If your change alters what a class owns, what an ADR's rules require, what an event means, or what a save field contains, the change is not done until the relevant document is updated in the same pull request. See the Engineering Constitution's final law.

**When a behavior change affects manual or graphical playtesting, update the relevant playtest checklist in the same pull request, in addition to updating the owning system document.** (e.g. `docs/v0.4-hotfix3/PLAYTEST_CHECKLIST.md`, `docs/PENITENT_PLAYTEST.md`, `docs/UI_PLAYTEST.md` — whichever checklist covers the affected class or system.) A system document describes the contract; the playtest checklist is what an independent verifier or the User actually walks through by hand, and it goes stale just as fast as any other documentation if a behavior change doesn't update it.

## Ownership by category

Don't duplicate a rule in more than one document — link to the document that owns it instead.

| Category of truth | Owning document |
|---|---|
| Why an architectural decision was made | [`Docs/ADR/`](../ADR/) |
| What currently exists in code | [`Docs/Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md) |
| Non-negotiable engineering rules | [`Docs/Governance/ENGINEERING_CONSTITUTION.md`](../Governance/ENGINEERING_CONSTITUTION.md) |
| AI contributor roles and obligations | [`Docs/Governance/AI_GUIDELINES.md`](../Governance/AI_GUIDELINES.md) |
| Gameplay/combat/itemization/class design | [`Docs/Design/`](../Design/) |
| World and narrative lore | [`Docs/Lore/`](../Lore/) |
| GDScript style, testing, naming conventions | [`Docs/Standards/`](.) |
| Non-blocking known issues | [`Docs/Planning/TECH_DEBT.md`](../Planning/TECH_DEBT.md) |
| Stage-by-stage delivery plan and status | [`Docs/Roadmap/`](../Roadmap/) |
| Automated CI / independent verification / graphical playtest status per milestone | `docs/BASELINE_TEST_RESULTS.md` |

## Baseline test results ledger ownership

*(Migrated from the pre-restructuring root `AGENTS.md` "Documentation ownership" section.)*

- The implementer (Claude Code, per [`Docs/Governance/AI_GUIDELINES.md`](../Governance/AI_GUIDELINES.md)) owns `docs/BASELINE_TEST_RESULTS.md` and keeps it current after accepted milestones and verification-changing fixes.
- The independent verifier (Claude) supplies independent results and findings but does not edit that document unless the User explicitly requests it.
- The document must clearly separate automated CI, independent verification, and graphical playtest status.

## Writing conventions

- Use relative Markdown links between documents in this repository.
- Prefer linking to an authoritative document over restating its content.
- Do not claim an unimplemented system already exists — mark it under a clearly labeled future-design or "Proposed" section instead (see [`Docs/Design/GAMEPLAY_BIBLE.md`](../Design/GAMEPLAY_BIBLE.md) for the section convention used across design and lore docs).
- Do not silently replace or contradict an existing ADR. If a change requires it, propose a new or superseding ADR instead of editing history.
