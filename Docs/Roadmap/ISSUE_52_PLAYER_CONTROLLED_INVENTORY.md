# Issue #52 — Player-Controlled Durable Inventory

Status: IMPLEMENTATION STARTED  
Parent candidate: PR #50 at `8c7730fc49a0059f5d711251ca6eef9e839362ab`  
Branch: `feature/issue52-player-controlled-inventory`

## Player finding

The PR #50 owner playtest proved that class progression survives a full relaunch, while equipped gear and backpack contents do not. The same playtest also rejected automatic equipment when an item drops into an empty slot.

## Required player loop

`loot drops → item enters backpack → player inspects it → player explicitly equips or leaves it stored → save/quit → relaunch → identical equipment and backpack state returns`

## Ownership and architecture

This slice uses the already-approved owners:

- `RuntimeSession` remains the composition root.
- `InventoryContainer` owns backpack item instances.
- `EquipmentManager` owns equipped item instances and atomic replacement.
- `ItemIdentityService` mints stable physical item IDs.
- `RuntimeCharacter.durable_snapshot()` serializes inventory, equipment, and allocator state.
- `PersistenceService` remains the only runtime-to-disk boundary.
- Playable UI dictionaries are compatibility projections only and never become a second mutable inventory ledger.

No new persistence top-level field or second save service is introduced.

## Implementation workstreams

### A. Playable item catalog

- Move the fixed prototype item definitions behind one immutable compatibility catalog.
- Register every playable definition before character binding so restored equipment can validate transactionally.
- Preserve current display name, slot, rarity, description, and gameplay stat data.

### B. Pickup policy

- Every normal pickup enters `InventoryContainer` first.
- Empty equipment slots do not auto-equip.
- Inventory-full rejection leaves the world pickup available or produces another explicit non-destructive outcome; valuable loot is never silently converted or destroyed.

### C. Explicit equip and swap

- Player selection invokes one bridge transaction.
- Validate inventory instance, equipment compatibility, capacity for the replaced item, and identity uniqueness before mutation.
- Remove the selected item from inventory, equip it, and return the replaced item to inventory atomically.
- Any failure restores the exact prior inventory/equipment state.

### D. Playable compatibility projection

- Void Warlock and Penitent bind to the same session-backed bridge.
- `get_inventory_snapshot()` projects authoritative runtime items into the existing inventory screen shape.
- Existing class-specific combat stat recalculation consumes the projected equipped items until the later production character-sheet migration.

### E. Persistence

- Item pickup, equip, and swap update the full `RuntimeSession.durable_snapshot()` through `PersistenceService`.
- Save and reload preserve stable `instance_id`, `definition_id`, rarity, item level, affixes, durability, equipped slot, backpack order, and item-identity allocator continuation.
- Tests use a unique build and delete only that build afterward.

## Required regressions

- first pickup for an empty slot remains in backpack;
- explicit equip succeeds;
- swap preserves both physical identities;
- failed equip leaves both serialized states unchanged;
- full backpack cannot consume or delete the incoming item;
- duplicate item identity is rejected;
- Void Warlock and Penitent use the same path;
- real JSON disk round trip restores equipment and backpack exactly;
- item identity minting continues without collisions after reload;
- existing developer saves and prior selected build remain untouched by tests.

## Scope boundaries

This slice does not add final inventory artwork, item comparison scoring, stash, vendors, crafting, salvage, controller presentation polish, or the front-end/save menu from Issue #53. It establishes correct player ownership and durability first.

## Merge gates

1. Parent PR #50 resolves and this PR is retargeted safely.
2. Exact-head CI passes.
3. Frozen artifact receives independent verification.
4. Owner confirms pickup, explicit equip/swap, and full relaunch persistence in a Windows build.
5. Owner explicitly authorizes merge.
