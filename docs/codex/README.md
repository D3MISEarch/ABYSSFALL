# AbyssFall Design Codex

Status: Active source of truth  
Last updated: 2026-07-22

## Purpose

This directory is the canonical design source for AbyssFall. It exists so the project owner, ChatGPT, Claude, Claude Code, Codex, contributors, implementers and independent verifiers all work from the same approved information.

Chat transcripts, temporary prompts and local notes may inspire changes, but they are not authoritative after an approved decision has been recorded here.

## Authority order

When sources disagree, use this order:

1. Approved documents in `docs/codex/`
2. Accepted pull-request decisions and amendments
3. Implementation contracts and machine-readable data
4. Existing gameplay code
5. Prototype behavior
6. Temporary AI prompts or chat history

Existing code is not proof that an old design remains approved. When implementation and Codex conflict, either update the implementation or explicitly amend the Codex in the same pull request.

## Playable-class standard

Every launch class receives a complete class Codex covering:

- Core fantasy and silhouette
- Signature combat verb
- Primary resource and advanced risk mechanic
- Weapons and class equipment
- Core combat loop
- Active skills and branching upgrades
- Passive clusters, notables, keystones and capstones
- Cross-discipline builds
- Itemization, legendary rules and unique items
- Controls, animation, VFX, audio, HUD and accessibility
- Enemy and boss interactions
- Narrative origin, factions, rivals, quests and trials
- Implementation architecture, formulas, IDs and tests
- Balance telemetry and completion standards

The standard is not merely equal document length. Every class must be understandable quickly, mechanically original, capable of multiple genuine endgame identities and deep enough to reward long-term mastery.

## Approved launch roster

| Class | Design status | Implementation status |
|---|---|---|
| Voidbringer | Approved Codex v1.0 | Production foundation planned; current compatibility prototype is `void_warlock` |
| Penitent | Core concept approved; full Codex pending | Existing prototype |
| Graftborn | Core concept approved; full Codex pending | Not started |
| Somnarch | Core concept approved; full Codex pending | Not started |
| Relic Host | Core concept approved; full Codex pending | Not started |
| Gorgon | Core concept approved; full Codex pending | Not started |
| Tidewrought | Core concept approved; full Codex pending | Not started |
| Anachron | Core concept approved; full Codex pending | Not started |

Reserved for future expansions or specializations:

- Choirborn
- Echo Thief
- Plaguebringer

## Directory structure

```text
docs/codex/
├── README.md
├── characters/
│   ├── CHARACTER_BIBLE_TEMPLATE.md
│   └── voidbringer/
│       ├── README.md
│       ├── 01_CLASS_BIBLE.md
│       ├── 02_SKILL_TREE.md
│       ├── 03_ITEMIZATION.md
│       ├── 04_COMBAT_PRESENTATION.md
│       ├── 05_ENCOUNTER_INTERACTIONS.md
│       ├── 06_NARRATIVE_AND_QUESTS.md
│       ├── 07_IMPLEMENTATION_CONTRACT.md
│       ├── 08_BALANCE_AND_TEST_MATRIX.md
│       └── CHANGELOG.md
└── systems/
```

## Change rules

A meaningful class change must update the relevant Codex file in the same pull request.

Examples:

- Changing an ability's fundamental behavior requires a skill-tree amendment.
- Changing Breach, Mass, Anchor or Fold Line rules requires class and implementation documentation updates.
- Adding a build-defining item requires the itemization document to be updated.
- Making a boss immune to a class mechanic requires encounter-document approval and should almost always be rejected in favor of force conversion.
- Renaming a stable implementation ID requires a save-data migration plan.

## Document status labels

Use one of:

- `Concept`
- `Draft`
- `Approved`
- `Implemented`
- `Partially implemented`
- `Deprecated`

Approval means the design should not be silently reinterpreted by an implementation agent.

## AI workflow

Before modifying a class:

1. Read its folder `README.md`.
2. Read every document named by that README as required for the task.
3. Inspect current implementation and tests.
4. State any conflict between code and Codex.
5. Preserve stable IDs and compatibility keys unless the task explicitly includes migration.
6. Update Codex and code together when changing approved behavior.

The goal is one shared AbyssFall brain, not several assistants inventing incompatible versions of the same game.