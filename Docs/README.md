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

Approved full-depth playable-class design lives under the canonical `Docs/` tree.

- [`codex/README.md`](codex/README.md) — Codex scope and authority.
- [`codex/characters/voidbringer/README.md`](codex/characters/voidbringer/README.md) — complete approved Voidbringer design.

The character Codex owns exact game-design content inside its class: skills, progression, builds, items, presentation, encounter behavior and class narrative. It does **not** override Governance, ADRs, Architecture or Standards. A design that requires a new architecture decision must receive an ADR before implementation.

## Relationship to pre-existing documentation

This structure organizes governance, architecture, design and standards material. It does not erase existing sources:

- `Docs/ADR/` and `Docs/Roadmap/` remain the approved architectural and delivery records.
- `design/` contains detailed existing design specs such as Penitent systems and item pools.
- `Docs/` contains playtest, verification and handoff documentation, and the detailed character Codex.

## Owner playtests

- [`VOIDBRINGER_POLISHED_IMPACT_PLAYTEST.md`](VOIDBRINGER_POLISHED_IMPACT_PLAYTEST.md) — isolated Null Shard spectacle-impact loop, Windows launch route, and owner checklist.

## Canonical documentation root

`Docs/` is the repository's only documentation root. Issue #113 moved every previously lowercase documentation path through a temporary Git path to preserve history on case-insensitive filesystems. The repository-health check rejects lowercase paths, case-insensitive duplicate paths, and stale lowercase references.
