# Class Design

## Confirmed

### Void Warlock — current playable compatibility prototype

- Current shipped/prototype fantasy: hungry-void ranged control and burst using Corruption, Void Bolt, Shadow Step and Grasping Rift.
- Preserve current playable behavior until a replacement milestone explicitly changes it.
- Persistent compatibility ID: `void_warlock`.
- This prototype is **not** the approved future design authority for the class.

Sources: `PROJECT_OVERVIEW.md`, current runtime implementation and existing playtest documentation.

### Voidbringer — approved future replacement design

- Canonical design identity: `voidbringer`.
- Compatibility during migration: existing saves and class selection continue using `void_warlock` until a versioned migration is approved.
- Fantasy: fused to a forbidden Manifold that assigns Mass, direction and valid location; controls physical relationships rather than casting generic void magic.
- Core loop: **Anchor → Load → Bend → Collapse**.
- Core systems: Mass Anchors, Fold Lines, Instability, Breach, Closure, Personal Mass and Velocity Reserve.
- Disciplines: Event Horizon, Redshift and Hollow Form.
- Complete approved specification: [`../../docs/codex/characters/voidbringer/README.md`](../../docs/codex/characters/voidbringer/README.md).

The detailed Codex is canonical for Voidbringer's player-facing design. Engineering implementation remains subordinate to the Engineering Constitution, ADRs and current architecture.

### The Penitent — active construction, second playable class

- Fantasy: carve laws into flesh and force reality to obey them. Close-to-mid-range ritual combat; melee carves and completes magic rather than replacing it.
- Current implemented/prototype resource: **Fervor**.
- Existing detailed sources: `design/FERVOR_SYSTEM_V1.md`, `docs/PENITENT_CLASS.md`, `design/PENITENT_ITEM_POOL_V1.md`.
- The eventual full Penitent Codex must use the shared character-bible template and reconcile existing implementation before replacing it as authority.

### Shared architecture constraint

Shared systems must not assume every class casts projectiles, uses Corruption, uses Fervor or shares one HUD. Resource interfaces, ability execution, event delivery, stat calculation and persistence must remain class-agnostic. See [`../Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md) and the relevant ADRs.

### Shared campaign and character-arc constraint

AbyssFall has one shared world, one campaign timeline and one universal central conflict for every playable class.

Every class receives a personal journey layered through that campaign:

- a class-specific origin,
- mentor or specialist faction,
- personal rivals,
- trials and mechanic-unlock quests,
- class-specific readings of shared regions and events,
- and a mastery finale with local or personal consequences.

Class stories do not become mutually incompatible replacement campaigns. Class antagonists are not automatically universal campaign villains, and class finales cannot erase shared regions, chronology or endgame infrastructure.

Binding narrative doctrine: [`../../docs/codex/SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md`](../../docs/codex/SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md).

### Approved full launch roster direction

The character Codex program will develop one class at a time to the Voidbringer depth standard:

1. Voidbringer
2. Penitent
3. Graftborn
4. Somnarch
5. Relic Host
6. Gorgon
7. Tidewrought
8. Anachron

Reserved for expansions or later specialization work:

- Choirborn
- Echo Thief
- Plaguebringer

Only Voidbringer currently has a complete approved Codex. Other roster entries remain design direction until their own folders are completed and approved.

## Character-bible standard

Every complete class must define:

- fantasy and silhouette,
- core verb and gameplay loop,
- resource and advanced risk mechanic,
- movement identity,
- complete level progression and skill tree,
- three freely mixable disciplines or paths,
- build-changing upgrades, keystones and capstones,
- equipment and unique-item interactions,
- controls, HUD, animation, VFX and audio,
- enemy and boss translations,
- lore, quests and class-specific encounters,
- shared campaign intersections,
- a class mastery finale that preserves universal campaign continuity,
- implementation, balance and verification contracts.

Template: [`../../docs/codex/characters/CHARACTER_BIBLE_TEMPLATE.md`](../../docs/codex/characters/CHARACTER_BIBLE_TEMPLATE.md).

## Open questions

- Exact schedule for replacing the current Void Warlock prototype with the approved Voidbringer implementation.
- Versioned migration from compatibility ID `void_warlock` to canonical ID `voidbringer`.
- Which class receives the next full Codex after the Voidbringer foundation enters implementation.
- Final universal campaign act structure, central antagonist and finale; these belong in a future shared campaign bible rather than any single class Codex.

## Deprecated

- Treating “Voidbringer” as an undecided working label or separate class from Void Warlock. It is now the approved future replacement design, while `void_warlock` remains only the compatibility/prototype identity during migration.
- Treating any class-specific journey as a replacement for the shared AbyssFall campaign.