# Gameplay Bible

The top-level index for AbyssFall's design documentation. This document states the pillars and points to the detailed documents that own each area — it does not restate their content. See [`Docs/Standards/DOCUMENTATION.md`](../Standards/DOCUMENTATION.md) for why.

Every section below uses the same convention: **Confirmed** (verifiable from repository documentation), **Proposed** (directional intent, not yet built or locked), **Open Questions** (genuinely undecided), **Deprecated** (superseded, kept for history). Do not treat a Proposed item as implemented.

## Confirmed

- AbyssFall is a dark ARPG / dark-fantasy action dungeon crawler.
- Combat should be weighty, dangerous, and readable.
- The project values high build expression.
- Core pillars per `PROJECT_OVERVIEW.md`: arcade horde combat, distinct playable classes, build progression, exploration and realms, a dark original identity, and an expandable co-op foundation (single-player first).
- The current playable prototype is Void Warlock v0.4 Hotfix 3 ("The Sunken Crypts").
- Persistent character continuity is a locked product rule: players are never required to restart a character to access new content ([ADR-010](../ADR/ADR-010-PERSISTENT-CHARACTER-CONTINUITY.md)).

## Proposed

- The long-term roadmap phases in `PROJECT_OVERVIEW.md` (multi-class architecture → Penitent vertical slice → polish → progression/content expansion → final characters → co-op/platform work → release candidate) describe intent, not committed scope or dates.
- Additional playable classes beyond Void Warlock and The Penitent — see [`CLASS_DESIGN.md`](CLASS_DESIGN.md).

## Open Questions

- Exact scope and timing of local vs. online co-op (Phase 6 in `PROJECT_OVERVIEW.md` is explicitly sequenced after core combat/architecture stabilize, with no date attached).
- Android release scope and performance targets are named as goals in `README.md`/`PROJECT_OVERVIEW.md` without a committed technical plan yet.

## Owning documents

| Area | Document |
|---|---|
| Combat feel and the ability execution model | [`COMBAT.md`](COMBAT.md) |
| Items, affixes, and procedural generation | [`ITEMIZATION.md`](ITEMIZATION.md) |
| Playable classes | [`CLASS_DESIGN.md`](CLASS_DESIGN.md) |
| World and narrative lore | [`../Lore/WORLD_LORE.md`](../Lore/WORLD_LORE.md) |
| Stage-by-stage delivery plan | [`../Roadmap/`](../Roadmap/) |
| Detailed, already-shipped design specs (Fervor system, Penitent item pool, HUD/class-select) | `design/` at the repository root — still authoritative, not superseded by this document |
