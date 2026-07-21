# ADR-018: Procedural Item Generation Boundary

## Status

Accepted for Stage 5 implementation.

## Decision

Procedural item generation is a pure runtime service built from explicit immutable inputs:

- `ItemDefinition`
- `AffixCatalog`
- item level
- rarity
- seed

`ItemGenerator` returns a complete `ItemInstance` or `null`. It never mutates inventory, equipment, persistence, catalogs, or character state.

## Consequences

- Identical inputs produce identical serialized generated items.
- Loot tables and reward services may request generated items without owning affix logic.
- Inventory and equipment continue consuming `ItemInstance` without knowing generation rules.
- Persistence requires no new service boundary because rarity, item level, and rolled affixes are serialized by the item instance.
- Generation failure is atomic and cannot leak a partial item.

## Affix representation

Rolled affixes are flattened into the existing item modifier array. Each modifier retains:

- `affix_id`
- `affix_name`
- `affix_kind`
- stat operation data

This keeps equipment stat application compatible while preserving enough durable metadata for UI, crafting, rerolling, and later migration.

## Deferred decisions

- Legendary powers use a separate effect-definition contract and are not encoded as ordinary stat modifiers.
- Crafting mutation and affix reroll ownership will receive a separate ADR.
- Network-authoritative seed ownership is deferred until multiplayer architecture begins.
