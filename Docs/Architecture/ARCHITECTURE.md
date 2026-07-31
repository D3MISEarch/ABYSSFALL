# Architecture

This document describes the architecture that **currently exists in code**, verified against `scripts/runtime/`, `scripts/persistence/`, the merged Stages 3–5 foundation, and the repository ADR record through ADR-021. It does not describe planned-but-unbuilt systems except where explicitly marked under **Future design**.

For *why* each boundary exists, see the linked ADR. This document describes *what exists*.

## Repository metadata policy

Godot 4.4.1 generates one `.gd.uid` sidecar for each GDScript. AbyssFall tracks every GDScript sidecar, including test scripts, so a clean import cannot leave generated UID files untracked. These files are editor metadata, not gameplay, persistence, or architecture state; the repository-health check verifies the one-to-one policy and every declared `uid://` value.

## Composition root: RuntimeSession

`RuntimeSession` (`scripts/runtime/runtime_session.gd`) is the single composition root for one play session. It constructs and owns every session-scoped runtime service and is the only object that wires them together:

```text
RuntimeSession
 ├── event_bus          : RuntimeEventBus
 ├── ability_executor    : AbilityExecutor       (constructed with event_bus)
 ├── item_catalog        : ItemCatalog
 ├── affix_catalog        : AffixCatalog
 ├── class_tree_catalog   : ClassTreeCatalog
 ├── class_progression    : ClassProgressionState (constructed on bind)
 ├── item_identity        : ItemIdentityService
 ├── reward_service       : EnemyRewardService
 ├── character            : RuntimeCharacter      (bound via bind_character())
 ├── inventory            : InventoryContainer     (constructed on bind, wired to item_identity)
 └── equipment            : EquipmentManager        (constructed on bind, wired to item_catalog + character.stats)
```

`RuntimeSession` is a `Node`, but never an autoload. One instance exists per session, and no gameplay system may reach a session's services except through the session that owns them. ([ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md), [ADR-018](../ADR/ADR-018-PROCEDURAL-ITEM-GENERATION.md))

### Transactional character binding

`bind_character()` is the only path that attaches a `RuntimeCharacter` to a session. Binding is transactional:

1. construct candidate progression, identity, inventory, and equipment services without changing the active session;
2. restore and validate the incoming character's class-tree, inventory, and equipment snapshots;
3. reject inventory/equipment identity collisions before attachment;
4. observe restored IDs so the candidate allocator cannot mint a collision;
5. reconcile exactly-once level award sources and rebuild tree effects against the incoming character only;
6. only after every step succeeds, disconnect the prior character/item/progression systems and replace the active session references;
7. connect the new signal chain and emit `build_loaded`.

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
- pending inventory, equipment, allocator, and class-tree snapshots retained for binding/fallback serialization.

Before either item system is attached, `attach_item_systems()` checks that all non-empty inventory IDs are disjoint from all non-empty equipment IDs. Inventory and equipment then validate their own snapshots into temporary state. References are assigned only after both restores succeed.

Ability cooldown state is owned by `AbilityExecutor`, not `RuntimeCharacter`. Temporary-effect ownership remains future design. ([ADR-011](../ADR/ADR-011-RUNTIME-CHARACTER-STATE.md))

### RuntimeEventBus (`scripts/runtime/runtime_event_bus.gd`)

A `Node` owned by exactly one `RuntimeSession`, never an autoload. It carries `build_loaded`, `runtime_state_changed`, `level_gained`, class-point and class-node events, `enemy_killed`, `experience_gained`, `item_equipped`, and ability events. Separate sessions never share a bus. Persistent services remain outside it. ([ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md))


### ClassTreeCatalog / ClassProgressionState (`scripts/runtime/progression/`)

`ClassTreeCatalog` stores defensive copies of immutable, versioned class-tree definitions. `ClassProgressionState` owns the mutable award ledger and node allocations for one bound build. Available points are always derived as awarded points minus allocation costs; no second mutable counter exists.

Restoration validates the entire snapshot before replacing live state: source IDs and positive award amounts, known nodes, ranks, prerequisites, exclusions, and affordability. Level awards use stable `level:<n>` sources and are reconciled on bind, so loading an existing level or replaying a signal cannot duplicate points. Purchases are atomic and failed transactions emit no success event.

Stat effects use deterministic `class_tree:<node>:<rank>:<effect>` source IDs. Rebuild first clears every source described by the active definition, then reprojects allocations in sorted node order. Rebinding and reloading therefore replace effects rather than stacking them. The current eight-node definitions are explicitly framework-proof content, not final class trees. ([ADR-020](../ADR/ADR-020-PERSISTENT-CLASS-TREE-AND-PROGRESSION-UI.md))

### AbilityExecutor (`scripts/runtime/abilities/ability_executor.gd`)

Owned one-per-session and constructed with that session's event bus. Cooldowns are keyed per build/ability inside the executor. Execution follows **validate → spend cost → start cooldown → execute effects**. A rejected attempt changes neither resources nor cooldown state. ([ADR-013](../ADR/ADR-013-ABILITY-RESOURCE-ARCHITECTURE.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md))

### Live playable outgoing-damage boundary

`PlayableCombatProjection` (`scripts/core/playable_combat_projection.gd`) is the sole live compatibility authority for a playable class's outgoing damage result. This is the narrow compatibility boundary in [ADR-021 §11](../ADR/ADR-021-VOIDBRINGER-COMBAT-STATE-ABILITY-CHARGE-AND-FORCE-OWNERSHIP.md); it does not implement the broader future Voidbringer foundation described below.

Before Issue #114, the repository contained two calculation implementations:

```text
test-only: CombatResolver.resolve_damage(request) → Dictionary
live:      CharacterFactory → PenitentPlayable / VoidWarlockCharacter
             → PlayableCombatProjection.resolve_outgoing_result*()
             → validated target.take_damage()
```

`CombatResolver` had no production preload, scene reference, factory reference, or caller. It was used only by the Stage 2 runtime-foundation test, so it could neither resolve live damage nor cause a live double application. It was removed rather than kept as a misleading second authority.

The live graph is now:

```text
CharacterFactory → PenitentPlayable / VoidWarlockCharacter
  → PlayableCombatProjection.resolve_outgoing_result*()
  → spatial/ability caller validates a hit
  → target.take_damage() / apply_damage() mutates target health and death state once

Voidbringer skill caller
  → VoidbringerDamageBridge → PlayableCombatProjection structured result
  → Mass Brand / Null Shard applies that result to the target once
  → VoidbringerImpactResult → controller impact event
```

Responsibility is intentionally split at this boundary:

- spatial ability callers own hit/target validation and reject invalid contacts before resolution;
- `PlayableCombatProjection` owns outgoing power calculation, deterministic critical determination, exactly-once critical-meter mutation for a valid positive base damage, and the one-pass structured result (`damage`, `critical`, `pre_critical_damage`, `base_damage`, `damage_multiplier`);
- `resolve_outgoing_damage()` is a legacy integer adapter that delegates once to that structured authority;
- `PlayableCombatProjection` owns only the playable source's incoming armor projection; target-specific mitigation, health mutation, and death consequences remain with the target's existing `take_damage()` / `apply_damage()` owner;
- `AbilityExecutor` retains generic ability validation/commit events, while Voidbringer's controller emits its class-specific committed impact after the target application.

This preserves the existing damage values and keeps one resolved result, one critical-meter mutation, and one target application per accepted hit. It adds no persistence state, class-ID change, or save-schema change.

The owner-playtestable Null Shard impact route in `VoidbringerFoundationSandbox` adds a scene-local `VoidbringerPolishedImpactPresentation` observer. It receives `null_shard_spawned` for the cast cue and the controller's committed `VoidbringerImpactResult` only after target application. It accepts only a positive `damage_applied` result, propagates its already-resolved critical flag, and owns one bounded inward-collapse spectacle: a violet-white shock ring, deterministic inward motes, a temporary visual ground residue, reversible decorative target compression, one bounded sandbox-camera impulse, optional light pulse, presentation audio, optional guarded haptics, and deterministic cleanup. Reduced and disabled presentation remain gameplay-equivalent. It does not own a gameplay event bus, damage calculation, hit validation, target health/death, rewards, cooldowns, movement, collision, AI, or persistent state.

### ItemCatalog / AffixCatalog

Immutable registries of `ItemDefinition`/`AffixDefinition`, keyed by stable IDs and returned as defensive copies. `AffixCatalog.eligible_definitions(tags, item_level, kind)` supplies candidate pools to item generation. ([ADR-014](../ADR/ADR-014-INVENTORY-EQUIPMENT-OWNERSHIP.md), [ADR-018](../ADR/ADR-018-PROCEDURAL-ITEM-GENERATION.md))

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

`EnemyRewardService.grant(...)` is invoked through `RuntimeSession` and owns exactly-once experience and loot grants. `LootGenerator` performs seeded table selection and requests unique physical IDs from the active allocator. `ItemGenerator.generate(...)` is a pure static function over immutable definition/catalog data, item level, rarity, generation seed, and explicit identity token. It returns a complete `ItemInstance` or `null` without mutating callers. ([ADR-018](../ADR/ADR-018-PROCEDURAL-ITEM-GENERATION.md))

### ItemIdentityService (`scripts/runtime/items/item_identity_service.gd`)

Owned one-per-active-build by `RuntimeSession`. It scopes IDs to the durable build ID and a monotonic sequence:

`item:<build_id>:<sequence>`

The next unused sequence persists in `build_specific_progress.item_identity`. Restoration observes inventory/equipment IDs before any new mint. Only one authoritative session may mint for a build at a time; multiplayer requires future network authority. ([ADR-018](../ADR/ADR-018-PROCEDURAL-ITEM-GENERATION.md))

### Playable prototype inventory adapter (`scripts/ui/playable_inventory_bridge.gd`)

The current graphical prototype still renders its inventory through legacy dictionaries, but those dictionaries are now read-only compatibility projections. `PlayableInventoryBridge` shares the already-bound `RuntimeSession` created by `PlayableProgressionBridge`; it does not create a second session, inventory, equipment set, allocator, or persistence owner.

Pickup and explicit equip requests are translated into `InventoryContainer` and `EquipmentManager` transactions. Physical identity comes only from the session's `ItemIdentityService`. The bridge then projects authoritative items back into the existing Void Warlock/Penitent inventory screen shape. Full durable saves use `RuntimeSession.durable_snapshot()` through `PersistenceService`, so equipped slots, backpack order, item identities, and allocator continuation restore through the same JSON contract as the runtime foundation.

The fixed prototype item data is centralized in `PlayableItemCatalog`. It registers immutable compatibility definitions before character binding so restoration can validate equipment transactionally. This adapter is a migration boundary for the current prototype UI, not a second item model.

### ItemInstance (`scripts/runtime/items/item_instance.gd`)

Mutable per-item data: identity, definition ID, quantity, rarity, item level, generation seed, affixes, and durability.

Construction deliberately leaves `instance_id` empty. Runtime creation paths must assign an ID minted by the active session service. `from_dict()` preserves a serialized ID when present and leaves identity empty when absent; restoration validators reject unminted physical items rather than inventing identity.

## Persistence boundaries

```text
Gameplay State (RuntimeSession/RuntimeCharacter/ClassProgressionState/InventoryContainer/EquipmentManager)
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

## ADR-021 implementation status

### Delivered scope and Future Design boundary

[ADR-021](../ADR/ADR-021-VOIDBRINGER-COMBAT-STATE-ABILITY-CHARGE-AND-FORCE-OWNERSHIP.md) is merged, accepted, and active architecture authority. PR #102 merged the ADR at `39615749d35f5849851e591ad2e5c02dd0e09ead`; `272d5101e9869fc5ed68c5c38dd284e428de913a` is the later PR #104 merge, not the resulting ADR-021 merge SHA.

The delivered scope is deliberately bounded:

- PR #106 implemented the approved Voidbringer foundation;
- PR #110 implemented only the bounded Mass Brand / Null Shard slice; and
- PR #118 reconciled the live combat calculation authority, including `PlayableCombatProjection` as the single live compatibility calculation authority documented above.

This does not claim that every ADR-021 provision is implemented. Unimplemented provisions remain **Future Design** and require their own scoped implementation, verification, owner-playtest, and merge gates.

Under the approved decision, the following broader boundary applies wherever it is not already represented by the delivered scope:

- `VoidWarlockCharacter` composes one character-combat-scoped `VoidbringerController` only after the existing `RuntimeSession`/`RuntimeCharacter` bind succeeds;
- the controller composes one `AnchorManager`, `FoldLineManager`, and `InstabilityController` and owns only Voidbringer transient state/orchestration;
- `RuntimeSession`, `RuntimeEventBus`, `AbilityExecutor`, `RuntimeCharacter`, persistence, damage targets and locomotion targets remain the existing generic authorities;
- `AbilityExecutor`/`AbilityRuntime` gain generic, backward-compatible charge, sequential recharge and source-keyed recharge-rate state;
- class command/loadout/target preflight remains outside the executor, while generic unlock/resource/cooldown/charge validation remains inside it;
- Instability mutates synchronously once after successful executor commit and is never persisted;
- a pure `ForceResolver` returns immutable results that target-owned locomotion/consequence systems apply;
- a generation token and ordered teardown reject stale effects across death, rebind, menu return and scene replacement;
- the durable compatibility ID remains `void_warlock`, and no save-schema migration is part of the foundation.

The controller/managers, charge extension, force vocabulary, and any other unimplemented ADR-021 provision remain Future Design until their own implementation PRs merge. This subsection must stay synchronized if ADR-021 is revised.

## Future design — not yet implemented

### Other deferred architecture

Do not build against these until a dedicated ADR approves them:

- Legendary powers and their session-owned effect registry;
- crafting mutation and affix reroll ownership;
- network authority over item identity minting;
- pre-indexed affix pools, only after profiling/catalog scale justifies them;
- automatic equipment UI orchestration for clearing off-hand before a two-handed equip.
