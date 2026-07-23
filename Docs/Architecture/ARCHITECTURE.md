# Architecture

This document describes the architecture that **currently exists in code**, verified against `scripts/runtime/`, `scripts/persistence/`, and the approved ADRs on draft PR #34 (`stage3/equipment-runtime-foundation`). It does not describe planned-but-unbuilt systems except where explicitly marked under **Future design**.

For *why* each boundary exists, see the linked ADR. This document describes *what exists*.

## Composition root: RuntimeSession

`RuntimeSession` (`scripts/runtime/runtime_session.gd`) is the single composition root for one play session. It constructs and owns every session-scoped runtime service and is the only object that wires them together:

```text
RuntimeSession
 ├── event_bus          : RuntimeEventBus
 ├── ability_executor    : AbilityExecutor       (constructed with event_bus)
 ├── item_catalog        : ItemCatalog
 ├── affix_catalog       : AffixCatalog
 ├── item_identity        : ItemIdentityService
 ├── reward_service       : EnemyRewardService
 ├── character            : RuntimeCharacter      (bound via bind_character())
 ├── inventory            : InventoryContainer     (constructed on bind, wired to item_identity)
 └── equipment            : EquipmentManager        (constructed on bind, wired to item_catalog + character.stats)
```

`RuntimeSession` is a `Node`, but never an autoload. One instance exists per session, and no gameplay system may reach a session's services except through the session that owns them. ([ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md), [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md))

### Transactional character binding

`bind_character()` is the only path that attaches a `RuntimeCharacter` to a session. Binding is transactional:

1. construct a candidate `ItemIdentityService`, inventory, and equipment manager without changing the active session;
2. restore and validate the incoming character's pending inventory/equipment snapshots;
3. reject inventory/equipment identity collisions before attachment;
4. observe restored IDs so the candidate allocator cannot mint a collision;
5. only after every step succeeds, disconnect the prior character/item systems and replace the active session references;
6. connect the new signal chain and emit `build_loaded`.

A failed initial bind leaves the session unbound. A failed rebind preserves the previously active character, inventory, equipment, allocator state, stats, and signal connections. Candidate equipment is validated without a live `StatBlock`; modifiers are applied to the incoming character only after the full bind succeeds.

## Dependency direction

```text
                          ┌───────────────────┐
                          │  RuntimeSession   │  (composition root)
                          └─────────┬─────────┘
              constructs/owns       │      constructs/owns
        ┌─────────────┬─────────────┼─────────────┬───────────────┐
        ▼             ▼             ▼             ▼               ▼
 RuntimeEventBus  AbilityExecutor  ItemCatalog  AffixCatalog  ItemIdentityService
        ▲             │                                            ▲
        │ emits to     │ reads validate/cost/cooldown               │ mint()/observe()
        │             ▼                                            │
        │      RuntimeCharacter ◄──── attach_item_systems() ────┐  │
        │        (class_resource, stats)                         │  │
        │             ▲                                          │  │
        │             │ deterministic modifier rebuild           │  │
        │      EquipmentManager ───────────────────────────────┘  │
        │             ▲                                             │
        │             │ explicit equip()/unequip()                  │
        │      InventoryContainer ◄──────── new split IDs ──────────┘
        │             ▲
        │             │ grant()
        │      EnemyRewardService ── LootGenerator ── ItemGenerator
        │
        └──────── runtime_state_changed / item_equipped ────────────
```

Arrows point from a consumer to the object it depends on or reads from. `RuntimeEventBus` is downstream of gameplay producers; nothing downstream of the bus depends back on a specific producer. Catalogs are pure immutable data registries.

## Core runtime classes

### RuntimeCharacter (`scripts/runtime/runtime_character.gd`)

Session-scoped object constructed from one durable `BuildData` record through `configure_from_build()`. It never performs disk I/O.

It owns:

- build/class identity;
- level, experience, and required experience;
- current health;
- `StatBlock`;
- `ClassResourcePool`;
- unlocked abilities;
- attached inventory/equipment references;
- pending inventory, equipment, and allocator snapshots retained for binding/fallback serialization.

Before either item system is attached, `attach_item_systems()` checks that all non-empty inventory IDs are disjoint from all non-empty equipment IDs. Inventory and equipment then validate their own snapshots into temporary state. References are assigned only after both restores succeed.

Ability cooldown state is owned by `AbilityExecutor`, not `RuntimeCharacter`. Temporary-effect ownership remains future design. ([ADR-011](../ADR/ADR-011-RUNTIME-CHARACTER-STATE.md))

### RuntimeEventBus (`scripts/runtime/runtime_event_bus.gd`)

A `Node` owned by exactly one `RuntimeSession`, never an autoload. It carries `build_loaded`, `runtime_state_changed`, `level_gained`, `enemy_killed`, `experience_gained`, `item_equipped`, and ability events. Separate sessions never share a bus. Persistent services remain outside it. ([ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md))

### AbilityExecutor (`scripts/runtime/abilities/ability_executor.gd`)

Owned one-per-session and constructed with that session's event bus. Cooldowns are keyed per build/ability inside the executor. Execution follows **validate → spend cost → start cooldown → execute effects**. A rejected attempt changes neither resources nor cooldown state. ([ADR-013](../ADR/ADR-013-ABILITY-RESOURCE-ARCHITECTURE.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md))

### ItemCatalog / AffixCatalog

Immutable registries of `ItemDefinition`/`AffixDefinition`, keyed by stable IDs and returned as defensive copies. `AffixCatalog.eligible_definitions(tags, item_level, kind)` supplies candidate pools to item generation. ([ADR-014](../ADR/ADR-014-INVENTORY-EQUIPMENT-OWNERSHIP.md), [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md))

### InventoryContainer (`scripts/runtime/items/inventory_container.gd`)

One per bound character. It owns `add_item`, `remove_instance`, `has_instance`, `find_instance`, `serialize`, and `restore`, and emits `item_added`/`item_removed` only after successful mutations.

`add_item()` performs a complete preflight before touching live stacks or the incoming item:

- reject null, unminted, duplicate-ID, mismatched-definition, non-positive, or oversize input;
- calculate compatible-stack capacity and whether a remainder needs an empty slot;
- reject the entire operation when the full quantity cannot fit;
- commit the precomputed merge plan only after success is guaranteed.

A failed add leaves inventory serialization, existing quantities, incoming quantity, signals, and allocator state unchanged.

Partial stack removal creates a second physical item and therefore requires the session's `ItemIdentityService`. Without a configured service, the split fails unchanged. There is no time/random fallback. Full-stack removal preserves the existing physical identity.

`restore()` validates capacity, entry shape, non-empty definitions/IDs, positive quantities, and duplicate IDs into temporary state before replacing live inventory.

### EquipmentManager (`scripts/runtime/items/equipment_manager.gd`)

One per bound character, configured with the session's item catalog and the character's stat block after binding succeeds.

It enforces:

- valid slot and definition compatibility;
- quantity exactly one;
- non-empty physical identity;
- one physical identity in at most one equipment slot;
- atomic live equip/replace/unequip behavior;
- atomic full-snapshot restoration;
- deterministic source-based stat rebuilding.

The data tag `two_handed` is an occupancy rule: a tagged item may equip only in `main_hand`, requires an empty `off_hand`, and blocks later off-hand equipment. Restoration rejects a two-handed main hand plus any off-hand item. This milestone does not auto-eject off-hand equipment; player-facing orchestration must explicitly unequip it first. ([ADR-014](../ADR/ADR-014-INVENTORY-EQUIPMENT-OWNERSHIP.md))

### EnemyRewardService / LootGenerator / ItemGenerator

`EnemyRewardService.grant(...)` is invoked through `RuntimeSession` and owns exactly-once experience and loot grants. `LootGenerator` performs seeded table selection and requests unique physical IDs from the active allocator. `ItemGenerator.generate(...)` is a pure static function over immutable definition/catalog data, item level, rarity, generation seed, and explicit identity token. It returns a complete `ItemInstance` or `null` without mutating callers. ([ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md))

### ItemIdentityService (`scripts/runtime/items/item_identity_service.gd`)

Owned one-per-active-build by `RuntimeSession`. It scopes IDs to the durable build ID and a monotonic sequence:

`item:<build_id>:<sequence>`

The next unused sequence persists in `build_specific_progress.item_identity`. Restoration observes inventory/equipment IDs before any new mint. Only one authoritative session may mint for a build at a time; multiplayer requires future network authority. ([ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md))

### ItemInstance (`scripts/runtime/items/item_instance.gd`)

Mutable per-item data: identity, definition ID, quantity, rarity, item level, generation seed, affixes, and durability.

Construction deliberately leaves `instance_id` empty. Runtime creation paths must assign an ID minted by the active session service. `from_dict()` preserves a serialized ID when present and leaves identity empty when absent; restoration validators reject unminted physical items rather than inventing identity.

## Persistence boundaries

```text
Gameplay State (RuntimeSession/RuntimeCharacter/InventoryContainer/EquipmentManager)
        │ durable_snapshot() — explicit, build-ID-scoped
        ▼
PersistenceService
        │ apply_active_build_snapshot() — validates build identity, merges durable dictionaries
        ▼
SaveManager
        │ to_dict() → JSON.stringify() → write-with-backup
        │ read-with-recovery → JSON parse → migration → from_dict()
        ▼
File Storage (user://abyssfall/...)
```

Runtime systems never call `SaveManager`. `RuntimeSession.durable_snapshot()` produces the runtime snapshot; `PersistenceService` is the only runtime-to-disk boundary. Dictionary-backed progress is merged so unrelated durable fields survive focused snapshots. `SaveManager` alone touches `user://` and uses backup recovery. ([ADR-015](../ADR/ADR-015-RUNTIME-PERSISTENCE-SYNCHRONIZATION.md))

## Deterministic generation

Determinism is enforced by construction:

- item contents depend on explicit generation seed and immutable inputs;
- physical identity depends on the session allocator, not the generation seed;
- identical content inputs may yield identical rolled contents while separately minted items retain distinct IDs;
- stack splitting uses the same allocator and persists the continued sequence;
- combat and stat calculation use explicit inputs and deterministic modifier ordering.

## JSON restoration

Godot typed arrays do not survive JSON stringify/parse with their static type. `ItemInstance.from_dict()` rebuilds affix arrays as `Array[Dictionary]`, and tests must exercise a real `JSON.stringify()`/`JSON.parse_string()` path rather than relying only on in-memory snapshots.

Allocator snapshots also round-trip through JSON. A restored service resumes from the next unused sequence and observes live restored IDs as a collision safety net.

## Future design — not yet implemented

Do not build against these until a dedicated ADR approves them:

- Legendary powers and their session-owned effect registry;
- crafting mutation and affix reroll ownership;
- network authority over item identity minting;
- pre-indexed affix pools, only after profiling/catalog scale justifies them;
- automatic equipment UI orchestration for clearing off-hand before a two-handed equip.
