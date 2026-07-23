# Docs

Index of AbyssFall's documentation tree. See [`../AGENTS.md`](../AGENTS.md) for the required reading order and [`Standards/DOCUMENTATION.md`](Standards/DOCUMENTATION.md) for which document owns which category of truth.

```text
Docs/
├── README.md
├── Governance/
│   ├── ENGINEERING_CONSTITUTION.md
│   └── AI_GUIDELINES.md
├── Architecture/
│   └── ARCHITECTURE.md
├── Design/
│   ├── GAMEPLAY_BIBLE.md
│   ├── COMBAT.md
│   ├── ITEMIZATION.md
│   └── CLASS_DESIGN.md
├── Lore/
│   └── WORLD_LORE.md
├── Standards/
│   ├── GDSCRIPT.md
│   ├── TESTING.md
│   ├── NAMING.md
│   └── DOCUMENTATION.md
├── Planning/
│   └── TECH_DEBT.md
├── ADR/
└── Roadmap/
```

## Detailed character design Codices

Approved full-depth playable-class design lives under the pre-existing lowercase `docs/` tree until the dedicated casing-normalization migration is performed.

- [`../docs/codex/README.md`](../docs/codex/README.md) — Codex scope and authority.
- [`../docs/codex/characters/voidbringer/README.md`](../docs/codex/characters/voidbringer/README.md) — complete approved Voidbringer design.

The character Codex owns exact game-design content inside its class: skills, progression, builds, items, presentation, encounter behavior and class narrative. It does **not** override Governance, ADRs, Architecture or Standards. A design that requires a new architecture decision must receive an ADR before implementation.

## Relationship to pre-existing documentation

This structure organizes governance, architecture, design and standards material. It does not erase existing sources:

- `Docs/ADR/` and `Docs/Roadmap/` remain the approved architectural and delivery records.
- `design/` contains detailed existing design specs such as Penitent systems and item pools.
- `docs/` contains playtest, verification and handoff documentation, and now the detailed character Codex.

## Known inconsistency: `docs/` vs. `Docs/`

The repository tracks both case-distinct paths. On case-insensitive filesystems they may appear merged; on case-sensitive CI they are separate. The dedicated normalization work remains tracked in [`Planning/TECH_DEBT.md`](Planning/TECH_DEBT.md). Until that migration, do not perform partial case-only moves inside unrelated PRs; update links carefully and treat both trees according to the ownership map above.
