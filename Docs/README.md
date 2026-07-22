# Docs

Index of AbyssFall's documentation tree. See [`../AGENTS.md`](../AGENTS.md) for the required reading order and [`Standards/DOCUMENTATION.md`](Standards/DOCUMENTATION.md) for which document owns which category of truth.

```text
Docs/
├── README.md                     — this file
├── Governance/
│   ├── ENGINEERING_CONSTITUTION.md   — the 20 non-negotiable laws
│   └── AI_GUIDELINES.md              — AI contributor roles and rules
├── Architecture/
│   └── ARCHITECTURE.md               — what currently exists in code
├── Design/
│   ├── GAMEPLAY_BIBLE.md              — pillars, index into design docs
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
├── ADR/                            — approved architectural decisions (preserved, unmodified)
└── Roadmap/                        — stage-by-stage delivery plan (preserved, unmodified)
```

## Relationship to pre-existing documentation

This structure was added to organize governance, architecture, design, and standards documentation that did not previously have a consistent home. It does **not** replace or supersede documentation that already existed:

- `Docs/ADR/` and `Docs/Roadmap/` are unchanged — every existing ADR and roadmap document is preserved exactly.
- `design/` (repository root, lowercase) holds detailed, already-shipped design specs (`FERVOR_SYSTEM_V1.md`, `PENITENT_ITEM_POOL_V1.md`, `PENITENT_HUD_AND_CLASS_SELECT_V1.md`) that `Docs/Design/` documents link to rather than duplicate.
- `docs/` (repository root, lowercase) holds playtest, verification, and handoff documentation (`PENITENT_CLASS.md`, `BASELINE_TEST_RESULTS.md`, `IMPLEMENTER_VERIFIER_HANDOFF.md`, `CLAUDE_VERIFIER_SETUP.md`, `VERIFICATION_REPORT_TEMPLATE.md`, `v0.4-hotfix3/`) that remains authoritative and is referenced from `Docs/Standards/` and `Docs/Governance/` rather than moved.

## Known inconsistency: `docs/` vs. `Docs/`

The repository's Git history contains two case-distinct top-level paths, `docs/` and `Docs/`. On a case-insensitive filesystem (e.g. Windows, default macOS) both resolve to the same folder, but Git itself tracks them as separate paths — on a case-sensitive filesystem (e.g. the Ubuntu runners used by this repository's own GitHub Actions workflows) they would appear as two distinct top-level directories. This predates this documentation restructuring and is called out here rather than silently fixed, because resolving it means moving a large number of already-referenced files (playtest checklists, verification templates, hotfix notes) and would risk breaking existing links from `.github/workflows/`, `AGENTS.md`, and other in-flight documentation. Recommended follow-up: a dedicated, narrowly-scoped cleanup task (Codex's role per [`Governance/AI_GUIDELINES.md`](Governance/AI_GUIDELINES.md)) that normalizes every reference before physically merging the two paths on a case-sensitive checkout.

`Docs/ADR/` and `Docs/Roadmap/` themselves have no such duplication — both exist only under the capitalized `Docs/` path, consistent with the requirement not to create duplicate ADR or Roadmap directories with different capitalization.
