# AbyssFall Detailed Design Codex

Status: Active, scoped design authority  
Last updated: 2026-07-22

## Purpose

This directory preserves approved full-depth character design so the project owner, ChatGPT, Claude, Claude Code, Codex, implementers and independent verifiers work from the same information.

Chat transcripts and local notes are not authoritative after an approved decision is recorded here.

## Scope and authority

The repository uses one coordinated knowledge system, not two competing systems.

Authority order:

1. [`../../Docs/Governance/ENGINEERING_CONSTITUTION.md`](../../Docs/Governance/ENGINEERING_CONSTITUTION.md) and approved ADRs govern engineering, architecture, ownership, persistence and testing.
2. [`../../Docs/Architecture/ARCHITECTURE.md`](../../Docs/Architecture/ARCHITECTURE.md) describes the current implementation.
3. [`../../Docs/Standards/`](../../Docs/Standards/) governs code, testing, naming and documentation practice.
4. [`../../Docs/Design/`](../../Docs/Design/) owns project-level gameplay and class direction.
5. This Codex owns approved **detailed game design** inside its documented character scope.
6. Within a character folder, an approved audit-resolution document supersedes only the exact sections it names.

A character Codex cannot authorize a second event bus, a new persistence owner or another architectural boundary by itself. When approved design needs architecture not covered by an ADR, implementation stops until an ADR is approved.

## Character index

| Class | Status | Location |
|---|---|---|
| Voidbringer | Complete approved design, audit-corrected; implementation foundation not yet merged | [`characters/voidbringer/README.md`](characters/voidbringer/README.md) |
| Penitent | Existing prototype/design sources; full Codex not yet reconciled | Existing `design/` and `docs/` sources |
| Graftborn | Core concept approved; full Codex not started | Pending |
| Somnarch | Core concept approved; full Codex not started | Pending |
| Relic Host | Core concept approved; full Codex not started | Pending |
| Gorgon | Core concept approved; full Codex not started | Pending |
| Tidewrought | Core concept approved; full Codex not started | Pending |
| Anachron | Core concept approved; full Codex not started | Pending |

## Required workflow

Before changing a class:

1. Read its folder README.
2. Read any audit resolutions first.
3. Read every numbered bible relevant to the task.
4. Read the Engineering Constitution, relevant ADRs, Architecture and Standards.
5. Inspect current code before proposing implementation.
6. Update the Codex and class changelog in the same PR when approved design changes.
7. Update architecture/ADR documentation when system ownership or contracts change.

## Shared template

Every complete playable class uses [`characters/CHARACTER_BIBLE_TEMPLATE.md`](characters/CHARACTER_BIBLE_TEMPLATE.md).

The template is a completeness standard, not a requirement that classes share mechanics.

## Directory-casing note

This Codex currently lives under the pre-existing lowercase `docs/` tree. The repository separately tracks uppercase `Docs/`; normalization is already recorded as dedicated technical debt. Do not perform partial case-only moves in unrelated class work.
