# AbyssFall Detailed Design Codex

Status: Active, scoped design authority  
Last updated: 2026-07-31

## Purpose

This directory preserves approved full-depth character design so the project owner, ChatGPT, Claude, Claude Code, Codex, implementers and independent verifiers work from the same information.

Chat transcripts and local notes are not authoritative after an approved decision is recorded here.

A complete Codex preserves the long-term design destination for a class. It does **not** place that class into production, commit it to launch, or authorize infrastructure for it. Production authority comes only from the active operation and owner-approved work queue.

## Scope and authority

The repository uses one coordinated knowledge system, not two competing systems.

Authority order:

1. [`../../Docs/Governance/ENGINEERING_CONSTITUTION.md`](../../Docs/Governance/ENGINEERING_CONSTITUTION.md) and approved ADRs govern engineering, architecture, ownership, persistence and testing.
2. [`../../Docs/Architecture/ARCHITECTURE.md`](../../Docs/Architecture/ARCHITECTURE.md) describes the current implementation.
3. [`../../Docs/Standards/`](../../Docs/Standards/) governs code, testing, naming and documentation practice.
4. [`../../Docs/Design/GAMEPLAY_BIBLE.md`](../../Docs/Design/GAMEPLAY_BIBLE.md) owns the binding production-scope and operation doctrine.
5. [`../../Docs/Design/`](../../Docs/Design/) owns project-level gameplay, campaign and class direction.
6. [`SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md`](SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md) owns the narrative boundary between the universal campaign and class-specific journeys.
7. This Codex owns approved **detailed game design** inside its documented character scope.
8. Within a character folder, an approved audit-resolution document supersedes only the exact sections it names.

A character Codex cannot authorize a second event bus, a new persistence owner, another architectural boundary, another production class, or another active operation by itself. When approved design needs architecture not covered by an ADR, implementation stops until an ADR is approved. When approved design belongs to a future operation, implementation stops until the owner opens that operation.

## Production boundary

The current operation is OP1, centered on the first polished Voidbringer proof.

- Voidbringer is the only active production class.
- Penitent remains a preserved prototype and future-operation candidate.
- All other class entries preserve long-term direction only.
- A future class may receive design work without receiving implementation authority, but even design expansion must not distract from OP1's active work queue.
- A complete future-class Codex is not a launch commitment.
- General shared-class architecture is created only from proven active needs and a real second consumer, not from the existence of future Codices.

Exact gates and queue state live in [`../../Docs/Roadmap/CURRENT_SLICE.md`](../../Docs/Roadmap/CURRENT_SLICE.md).

## Shared campaign doctrine

AbyssFall uses one shared world, campaign timeline and central conflict for every playable class. Character Codices add origins, mentors, trials, personal rivals, mastery finales and class-specific readings of shared events; they do not create replacement campaigns.

Every class narrative must comply with [`SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md`](SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md).

## Character index

| Class | Design status | Production status | Location |
|---|---|---|---|
| Voidbringer | Complete approved design, audit-corrected | Active OP1 class; exact implementation status belongs in the current-slice roadmap | [`characters/voidbringer/README.md`](characters/voidbringer/README.md) |
| Penitent | Existing prototype/design sources; full Codex not yet reconciled | Preserved and regression-tested; future operation only | Existing `design/` and `Docs/` sources |
| Graftborn | Core concept approved; full Codex not started | Long-term direction only | Pending |
| Somnarch | Core concept approved; full Codex not started | Long-term direction only | Pending |
| Relic Host | Core concept approved; full Codex not started | Long-term direction only | Pending |
| Gorgon | Core concept approved; full Codex not started | Long-term direction only | Pending |
| Tidewrought | Core concept approved; full Codex not started | Long-term direction only | Pending |
| Anachron | Core concept approved; full Codex not started | Long-term direction only | Pending |

## Required workflow

Before changing a class:

1. Read [`../../Docs/Design/GAMEPLAY_BIBLE.md`](../../Docs/Design/GAMEPLAY_BIBLE.md) and confirm the class is inside the active operation.
2. Read [`../../Docs/Roadmap/CURRENT_SLICE.md`](../../Docs/Roadmap/CURRENT_SLICE.md) and confirm the exact work is authorized.
3. Read this Codex README.
4. Read [`SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md`](SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md) for any lore, quest, faction or campaign work.
5. Read the class folder README.
6. Read any audit resolutions first.
7. Read every numbered bible relevant to the task.
8. Read the Engineering Constitution, relevant ADRs, Architecture and Standards.
9. Inspect current code before proposing implementation.
10. Update the Codex and class changelog in the same PR when approved design changes.
11. Update architecture/ADR documentation when system ownership or contracts change.

If the class or capability is outside the active operation, stop. Do not reinterpret a complete Codex as implementation permission.

## Shared template

Every complete playable class may use [`characters/CHARACTER_BIBLE_TEMPLATE.md`](characters/CHARACTER_BIBLE_TEMPLATE.md) when its design operation is opened.

The template is a completeness standard, not a demand to design or implement every class now, and not a requirement that classes share mechanics. Every future class narrative must join the same shared campaign and clearly separate universal events from its personal journey.

Fields for multiplayer, platforms, or other unopened capabilities may be marked deferred. Their presence in the template does not authorize speculative implementation.

## Directory-casing note

This Codex lives under the canonical `Docs/` root. Do not introduce alternate documentation roots or partial case-only moves in unrelated class work.
