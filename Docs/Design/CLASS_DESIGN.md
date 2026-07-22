# Class Design

## Confirmed

### Void Warlock (currently playable)

- Fantasy: commands the hungry void. Ranged control and burst; gravity, portals, soul collection, summoning.
- Resource: **Corruption** — living, parasitic, organic, wet, hungry. Collected and fed, not performed.
- Visual language: obsidian black, abyss purple, sickly neon green.
- Confirmed kit: Void Bolt, Shadow Step, Grasping Rift.
- Preserve current Void Warlock gameplay unless a task explicitly requests a balance change — this was a standing project rule prior to this documentation restructuring and remains in force.

Source: `PROJECT_OVERVIEW.md`, `README.md` (repository root).

### The Penitent (in active construction, second playable class)

- Fantasy: carve laws into flesh and force reality to obey them. Close-to-mid-range ritual combat; melee carves and completes magic rather than replacing it.
- Resource: **Fervor** — performed and earned, not collected. Full specification: `design/FERVOR_SYSTEM_V1.md` (repository root).
- Visual language: ritual black, blood-crimson sigils, neon venom-green corruption accents, bone/ivory mask.
- Skill branches: Brands (spreading marks, echoed damage, chain reactions), Circles (battlefield geometry, bindings, traps), Sacrifice (health spending, lifesteal, mutation, power spikes).
- Full class blueprint: `docs/PENITENT_CLASS.md` (repository root, lowercase `docs/`). Full item pool: `design/PENITENT_ITEM_POOL_V1.md`.

Source: `PROJECT_OVERVIEW.md`, `docs/PENITENT_CLASS.md`, `design/FERVOR_SYSTEM_V1.md`.

### Shared architecture constraint

Shared systems (`main.gd` and runtime infrastructure) must not assume every class casts projectiles, uses Corruption, or has the same HUD — the resource interface, ability execution pipeline, and stat pipeline are class-agnostic by design (see [`../Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md), [ADR-013](../ADR/ADR-013-ABILITY-RESOURCE-ARCHITECTURE.md)).

### Visual identity direction

Dark reds, black, and neon green accents are the confirmed cross-class visual direction. This is consistent with, and slightly broadened by, the per-class palettes above (Penitent adds bone/ivory and blood-crimson; Void Warlock adds abyss purple as a class-specific accent alongside the shared black/neon-green language).

## Proposed

The following classes are project direction, not yet represented in any repository design document, ADR, or roadmap stage. They are recorded here so agents don't rediscover or contradict them, but nothing about their mechanics is locked.

### Void Warlock / Voidbringer direction

A possible evolution or naming direction for the Void Warlock identity. Not yet reflected in `PROJECT_OVERVIEW.md`, `docs/PENITENT_CLASS.md`, or any ADR. Treat "Voidbringer" as a working label for future Void Warlock direction, not a confirmed second class.

### Sigil Cultist

A third planned class concept, distinct from The Penitent. Emphasizes ritual/sigil magic combined with **selective** melee interaction — explicitly not a pure caster and not a blade-only archetype. Given the Penitent already occupies "ritual combat carved by melee," the Sigil Cultist's differentiation from the Penitent (resource, sigil mechanics, melee-selectivity rules) is undecided and should be resolved before implementation begins, to avoid the two classes converging on the same fantasy.

`PROJECT_OVERVIEW.md`'s class-selection design already anticipates this: future classes appear as chained silhouettes with a lore hint and unlock requirement, and "potential future archetypes remain intentionally undecided until the first two classes prove the shared architecture" — the Sigil Cultist is one candidate for that slot, not a committed one.

## Open Questions

- How the Sigil Cultist differentiates its resource and melee rules from The Penitent's Fervor/Rite Mark system.
- Whether "Voidbringer" is a rename, a mechanical evolution, or a separate future class from Void Warlock.
- Timing: `PROJECT_OVERVIEW.md` explicitly defers deciding future archetypes until the Warlock/Penitent shared architecture is proven — no committed order exists yet for a third class.

## Deprecated

None currently.
