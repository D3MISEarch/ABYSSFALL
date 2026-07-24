# ADR-018: Procedural Item Generation Boundary

## Status

Accepted for Stage 5 implementation. Amended after independent architecture review to separate item identity from generation provenance.

## Decision

Procedural item generation is a pure runtime service built from explicit immutable inputs:

- `ItemDefinition`
- `AffixCatalog`
- item level
- rarity
- generation seed
- unique item identity token

`ItemGenerator` returns a complete `ItemInstance` or `null`. It never mutates inventory, equipment, persistence, catalogs, characters, or the identity allocator.

The generation seed determines item contents. The identity token determines which individual physical item the instance represents. Two calls may intentionally use identical generation inputs and produce identical contents, but each live item must receive a different identity token.

## Identity ownership

`RuntimeSession` owns one `ItemIdentityService` for the active build. Loot, crafting, vendors, stack splitting, and future item-creation services request identities from this service before creating a new physical item.

The allocator uses the durable build ID as its scope and a monotonic sequence as its local identity source. Its next unused sequence is stored in `build_specific_progress.item_identity`. During legacy restoration, the service also observes restored inventory and equipment IDs before minting new ones.

`InventoryContainer` rejects empty or duplicate live instance IDs. Persistence continues rejecting duplicate IDs during restoration.

Only one authoritative `RuntimeSession` may mint identities for a build at a time. A future multiplayer implementation must move minting behind network authority before two concurrent sessions can mutate the same build.

## Consequences

- Identical generation seed and item inputs produce identical rolled contents independently from identity.
- Identical complete inputs, including the identity token, produce identical serialized generated items.
- Two otherwise-identical physical items can coexist, save, and restore safely because their IDs differ.
- The generation seed is serialized separately for provenance, replay verification, and debugging.
- Loot tables and reward services may request generated items without owning affix logic.
- Inventory and equipment continue consuming `ItemInstance` without knowing generation rules.
- Generation failure is atomic and cannot leak a partial item.
- Identity sequences may contain gaps when a valid creation attempt later fails; uniqueness is more important than contiguous numbering.
- Serialized affix arrays are rebuilt as typed `Array[Dictionary]` values after JSON parsing so real disk saves restore through the same contract as in-memory snapshots.

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
- Network authority will own identity minting when multiplayer architecture begins.
- Affix pools may be pre-indexed when catalog scale or profiling justifies the optimization.
