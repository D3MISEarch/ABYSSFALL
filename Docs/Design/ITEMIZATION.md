# Itemization Design

## Confirmed

- The project values high build expression (`GAMEPLAY_BIBLE.md`).
- Procedural item generation is deterministic: a generation seed determines an item's rolled contents; a separate identity token determines which physical item it is ([ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md), [`../Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md)).
- Affixes are data: `AffixDefinition` entries in `AffixCatalog`, immutable and tag/level-eligibility gated ([ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md)).
- Rarity tiers currently implemented: Normal, Magic, Rare, Legendary, each with its own affix-count budget (`Docs/Roadmap/STAGE_5_LOOT_AFFIXES.md`). Note: rarity *rules* are currently hardcoded rather than data-driven — tracked in [`../Planning/TECH_DEBT.md`](../Planning/TECH_DEBT.md).
- Equipment slots: head, chest, gloves, boots, belt, amulet, ring_left, ring_right, main_hand, off_hand ([ADR-014](../ADR/ADR-014-INVENTORY-EQUIPMENT-OWNERSHIP.md)).
- Item rarity progression by design intent (`design/PENITENT_ITEM_POOL_V1.md` drop philosophy, repository root): Common/Magic improve reliability, Rare strengthens one part of the core loop, Epic introduces a meaningful advantage with a condition or drawback, Legendary alters ability behavior, Mythic reshapes the class resource economy and should be extremely rare. Note: Epic and Mythic are design-intent tiers from this document; the currently *implemented* rarity enum ([ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md), `Docs/Roadmap/STAGE_5_LOOT_AFFIXES.md`) is Normal/Magic/Rare/Legendary only — Epic and Mythic are not yet implemented tiers.
- A concrete example item pool for one class (The Penitent) exists and is authoritative: `design/PENITENT_ITEM_POOL_V1.md` (repository root).

## Proposed — Legendary Powers (future design, not implemented)

**Legendary powers are behavior and will not be ordinary stat modifiers.** This is a locked design constraint, but the implementation is explicitly deferred:

- [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md) states legendary powers "use a separate effect-definition contract and are not encoded as ordinary stat modifiers" and lists this as a deferred decision.
- [`Docs/Roadmap/STAGE_5_LOOT_AFFIXES.md`](../Roadmap/STAGE_5_LOOT_AFFIXES.md) names this as Stage 6 scope: "Begin Stage 6 Legendary Powers with an approved hook taxonomy and session-owned runtime effect registry."
- **Nothing implementing legendary powers exists in the codebase today.** The Legendary rarity tier currently generates using the same flattened-affix path as Magic/Rare, just with a larger affix budget — it does not yet grant a unique behavioral effect. Do not build against a "legendary effect registry" until the Stage 6 ADR exists.
- Individual example Legendary items with behavior-changing effects are already sketched at the design-document level for The Penitent (`design/PENITENT_ITEM_POOL_V1.md`, e.g. "Gospel of Iron Teeth," "The Witness Without Eyes") — these are design references for what Stage 6 should be able to express, not a spec for how the effect registry works.

## Open Questions

- Crafting mutation and affix reroll ownership — explicitly deferred to a future ADR ([ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md)).
- Whether Epic and Mythic rarity tiers get implemented as-designed in `design/PENITENT_ITEM_POOL_V1.md`, or the tier list changes before implementation.
- Structured affix groups vs. the current flattened-modifier representation, before tooltip UI or crafting depends on it (see [`../Planning/TECH_DEBT.md`](../Planning/TECH_DEBT.md)).

## Deprecated

None currently.
