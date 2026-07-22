# Architecture

This document describes the architecture that **currently exists in code**, verified against `scripts/runtime/`, `scripts/persistence/`, and the approved ADRs at the commit this document was written against (`stage3/equipment-runtime-foundation` @ PR #35). It does not describe planned-but-unbuilt systems except where explicitly marked under "Future design."

For *why* each boundary exists, see the linked ADR. This document only describes *what exists*.

## Composition root: RuntimeSession

`RuntimeSession` (`scripts/runtime/runtime_session.gd`) is the single composition root for one play session. It constructs and owns every session-scoped runtime service, and it is the only object that wires them together:

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

`RuntimeSession` is a `Node`, but it is never an autoload — one instance exists per session, and no gameplay system is permitted to reach a session's services except through the session that owns them ([ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md), [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md)).

`bind_character()` is the only path that attaches a `RuntimeCharacter` to a session: it configures `ItemIdentityService` for that character's build ID, constructs a fresh `InventoryContainer` and `EquipmentManager`, attaches them to the character, and wires up the signal chain that republishes character/inventory/equipment changes onto `event_bus`. A failed bind leaves the session's item state cleared rather than partially wired.

## Dependency direction

```text
                          ┌───────────────────┐
                          │   RuntimeSession    │  (composition root)
                          └─────────┬──────────┘
              constructs/owns       │      constructs/owns
        ┌─────────────┬─────────────┼─────────────┬───────────────┐
        ▼             ▼             ▼             ▼               ▼
 RuntimeEventBus  AbilityExecutor  ItemCatalog  AffixCatalog  ItemIdentityService
        ▲             │                                            ▲
        │ emits to     │ reads (validate/cost/cooldown)            │ mint()/observe()
        │             ▼                                            │
        │      RuntimeCharacter ◄──── attach_item_systems() ────┐  │
        │        (class_resource,                               │  │
        │         stats: StatBlock)                              │  │
        │             ▲                                          │  │
        │             │ rebuild_stat_modifiers()                 │  │
        │      EquipmentManager ───────────────────────────────┘  │
        │             ▲                                             │
        │             │ equip()/unequip()                           │
        │      InventoryContainer ◄──────── new instance IDs ───────┘
        │             ▲
        │             │ grant()
        │      EnemyRewardService ──── uses ──── LootGenerator ──── uses ──── ItemGenerator
        │                                                                        │
        └──────────────── runtime_state_changed / item_equipped ─────────────────┘
```

Reading the diagram: arrows point from consumer to the thing it depends on / reads from. `RuntimeEventBus` is downstream of everything (things emit *to* it); nothing downstream of the event bus is allowed to depend back on a specific producer. Catalogs (`ItemCatalog`, `AffixCatalog`) have no outgoing dependencies — they are pure immutable data.

## Core runtime classes

### RuntimeCharacter (`scripts/runtime/runtime_character.gd`)

Session-scoped object constructed from one persistent `BuildData` record. Owns current health, class resource, cooldowns, temporary effects, runtime inventory/equipment state, and calculated stats. Never performs disk I/O. Emits `state_changed(reason)` after durable changes and `level_gained(new_level)`. Exposes `durable_snapshot(item_identity_snapshot)` as the only path to a serializable snapshot. ([ADR-011](../ADR/ADR-011-RUNTIME-CHARACTER-STATE.md))

### RuntimeEventBus (`scripts/runtime/runtime_event_bus.gd`)

A `Node`, constructed and owned by exactly one `RuntimeSession`. Not an autoload. Carries signals such as `build_loaded`, `runtime_state_changed`, `level_gained`, `enemy_killed`, `experience_gained`, and `item_equipped`. Separate sessions never share a bus, and no gameplay system may create a second one for the same session. This is the **only** runtime gameplay event bus — persistent services (`PersistenceService`/`SaveManager`) stay outside it and keep their own explicit mutation/save boundary. ([ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md))

### AbilityExecutor (`scripts/runtime/abilities/ability_executor.gd`)

Owned one-per-session by `RuntimeSession`, constructed with that session's `RuntimeEventBus`. Cooldown state is keyed by build ID and ability ID inside the executor, so cooldowns stay isolated per session/build without any global map. Execution follows **validate → spend cost → start cooldown → execute effects**; a rejected attempt spends no resource and emits `ability_rejected` with an explicit reason, a successful attempt spends exactly once and emits `ability_cast`. ([ADR-013](../ADR/ADR-013-ABILITY-RESOURCE-ARCHITECTURE.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md))

### ItemCatalog / AffixCatalog (`scripts/runtime/items/item_catalog.gd`, `affix_catalog.gd`)

Immutable registries of `ItemDefinition`/`AffixDefinition`, keyed by stable ID (`register`, `get_definition`, `has_definition`, `all_ids`, `size`). `AffixCatalog.eligible_definitions(tags, item_level, kind)` is the query `ItemGenerator` uses to find candidate prefixes/suffixes. Definitions are returned as defensive copies — callers cannot mutate catalog state. ([ADR-014](../ADR/ADR-014-INVENTORY-EQUIPMENT-OWNERSHIP.md), [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md))

### InventoryContainer (`scripts/runtime/items/inventory_container.gd`)

One per bound character, constructed with a capacity and the session's `ItemIdentityService`. Owns `add_item`, `remove_instance`, `has_instance`, `find_instance`, `serialize`/`restore`. Emits `item_added`/`item_removed`. Rejects empty or duplicate live instance IDs on restore. ([ADR-014](../ADR/ADR-014-INVENTORY-EQUIPMENT-OWNERSHIP.md))

### EquipmentManager (`scripts/runtime/items/equipment_manager.gd`)

One per bound character, configured with the session's `ItemCatalog` and the character's `StatBlock`. Owns `can_equip`/`equip`/`unequip`/`restore`/`serialize`/`rebuild_stat_modifiers`. Equipping is atomic: validate, replace, rebuild stats, and emit `equipment_changed(slot_id, equipped, unequipped)`. A failed equip leaves both inventory and equipment unchanged. Initial slots: head, chest, gloves, boots, belt, amulet, ring_left, ring_right, main_hand, off_hand. ([ADR-014](../ADR/ADR-014-INVENTORY-EQUIPMENT-OWNERSHIP.md))

### EnemyRewardService / LootGenerator / ItemGenerator (`scripts/runtime/rewards/`, `scripts/runtime/loot/`, `scripts/runtime/items/item_generator.gd`)

`EnemyRewardService.grant(enemy, character, inventory, item_catalog, affix_catalog, item_identity)` is invoked once per enemy death via `RuntimeSession.grant_enemy_rewards()`, and is responsible for exactly-once reward grants (experience + loot). It uses `LootGenerator` for rarity-weighted table selection and `ItemGenerator.generate(...)` (a `static` pure function) to actually build the `ItemInstance`.

`ItemGenerator.generate()` takes `ItemDefinition`, item level, rarity, an explicit seed, an explicit `instance_id`, and `AffixCatalog` — all immutable/explicit inputs, no global RNG state. It validates inputs, rolls a target affix count from the rarity's min/max budget using a **seeded** `RandomNumberGenerator`, allocates prefix/suffix counts, and delegates the actual roll to `AffixRoller`. It returns a complete `ItemInstance` or `null` — generation failure is atomic and never leaks a partially generated item. It never touches inventory, equipment, persistence, catalogs, characters, or the identity allocator. ([ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md))

### ItemIdentityService (`scripts/runtime/items/item_identity_service.gd`)

Owned one-per-active-build by `RuntimeSession`. `configure(session_id, snapshot)` scopes the allocator to a durable build ID and restores its next-unused sequence from a snapshot if one matches that build. `mint()` returns a new `"item:<session_id>:<sequence>"` token and advances the sequence — this is the **only** source of new instance IDs. `observe()`/`observe_items()`/`observe_equipment()` let the service catch up its sequence past any instance IDs already present in restored inventory/equipment, so restoration can never mint a colliding ID. `snapshot()` returns `{session_id, next_sequence}` for persistence.

Only one authoritative `RuntimeSession` may mint identities for a given build at a time — a future multiplayer architecture must move minting behind network authority before two sessions can safely mutate the same build concurrently. This is deferred design, not yet implemented (see [`Docs/Planning/TECH_DEBT.md`](../Planning/TECH_DEBT.md)). ([ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md))

### ItemInstance (`scripts/runtime/items/item_instance.gd`)

Mutable per-item state: `instance_id`, `definition_id`, quantity, `rarity`, `item_level`, `generation_seed`, and rolled `affixes` (flattened into the item's modifier array, each entry retaining `affix_id`, `affix_name`, `affix_kind`, and stat operation data). `to_dict()`/`from_dict()` is the serialization contract equipment and inventory consume without needing to know generation rules. ([ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md))

## Persistence boundaries

```text
Gameplay State (RuntimeSession/RuntimeCharacter/InventoryContainer/EquipmentManager)
        │  durable_snapshot() — explicit, versioned, build-ID-scoped
        ▼
PersistenceService (scripts/persistence/persistence_service.gd)
        │  apply_active_build_snapshot() — rejects mismatched build_id,
        │  merges dictionary-backed progression fields, marks dirty
        ▼
SaveManager (scripts/persistence/save_manager.gd)
        │  to_dict() → JSON.stringify() → write-with-backup
        │  read-with-recovery → JSON parse → migrate → from_dict()
        ▼
File Storage (user://abyssfall/profile.json, builds/build_<uuid>.json, backups/)
```

- **Runtime systems never call `SaveManager` directly.** `RuntimeSession.durable_snapshot()` is the only thing that produces a snapshot, and `PersistenceService.apply_active_build_snapshot()`/`mutate_active_build()` is the only thing that accepts one. ([ADR-015](../ADR/ADR-015-RUNTIME-PERSISTENCE-SYNCHRONIZATION.md))
- A snapshot whose `build_id` does not match `PersistenceService.active_build.build_id` is rejected outright.
- Dictionary-backed fields (`skills`, `class_tree_state`, `shared_core_state`, `build_specific_progress`, `quest_state`, `statistics`) are merged rather than replaced, so unrelated durable progress survives a partial snapshot.
- `PersistenceService` coalesces autosave (60s interval, dirty-flag gated) and flushes on `NOTIFICATION_WM_CLOSE_REQUEST`/`NOTIFICATION_APPLICATION_PAUSED`; gameplay never forces a disk write per event.
- `SaveManager` is the only code that touches `user://` — profile and build files are written through `_write_json_with_backup` and read through `_load_json_with_recovery`, so a corrupted primary file can fail over to its backup.

## Deterministic generation

Determinism is enforced by construction, not by convention:

- `ItemGenerator.generate()` is a pure `static` function — no instance state, no ambient RNG. Its only source of randomness is a `RandomNumberGenerator` seeded with the caller-supplied `seed` argument.
- The **generation seed determines rolled contents**; the **identity token determines which physical item the instance represents**. These are deliberately independent — see [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md). Two generation calls with identical seed and inputs produce identical rolled contents, but each live item still receives a distinct identity token from `ItemIdentityService.mint()`.
- `CombatResolver` and the stat pipeline (`StatBlock`/`StatModifier`) follow the same principle: final stats rebuild deterministically from `(Base + Flat) × (1 + Additive%) × Multiplicative% factors`, and damage calculations consume a frozen stat snapshot rather than reading live, possibly-changing state mid-calculation. ([ADR-012](../ADR/ADR-012-STAT-MODIFIER-PIPELINE.md))

## JSON restoration

`SaveManager` round-trips durable state through `JSON.stringify()`/`JSON.parse_string()`. This has a consequence that the runtime layer must account for explicitly: **Godot's typed arrays do not survive a JSON round trip as typed arrays.** An `Array[Dictionary]` written to disk and read back comes back as an untyped `Array`. Per [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md), serialized affix arrays are explicitly rebuilt as typed `Array[Dictionary]` after JSON parsing, so a real disk save restores through the same contract as an in-memory snapshot. This is why [`Docs/Standards/TESTING.md`](../Standards/TESTING.md) requires persistence tests to go through an actual `JSON.stringify`/`JSON.parse_string` round trip rather than only comparing in-memory objects — an in-memory-only test cannot catch this class of bug.

`ItemIdentityService.configure()` similarly re-derives its next allocation sequence from a restored snapshot (or from observing restored inventory/equipment instance IDs directly when no matching snapshot exists), so a restored session can never mint an ID that collides with one already on disk.

## Future design — not yet implemented

The following are recorded here so they are not mistaken for existing systems. Do not build against them until an ADR approves the concrete design.

- **Legendary powers.** [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md) explicitly defers this: legendary powers will use a separate effect-definition contract and will **not** be encoded as ordinary stat modifiers. [`Docs/Roadmap/STAGE_5_LOOT_AFFIXES.md`](../Roadmap/STAGE_5_LOOT_AFFIXES.md) names Stage 6 ("Begin Stage 6 Legendary Powers with an approved hook taxonomy and session-owned runtime effect registry") as the point where this gets designed. See [`Docs/Design/ITEMIZATION.md`](../Design/ITEMIZATION.md) for the design-side placeholder.
- **Crafting mutation and affix reroll ownership** — deferred to a future ADR per ADR-018.
- **Network authority over identity minting** — required before multiplayer can let two sessions mutate the same build; not designed yet.
- **Pre-indexed affix pools** — only justified once catalog scale or profiling demands it; see [`Docs/Planning/TECH_DEBT.md`](../Planning/TECH_DEBT.md).
