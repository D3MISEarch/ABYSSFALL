# Engineering Constitution

These are the foundational laws of the AbyssFall codebase. They are derived from, and must never contradict, the approved [ADRs](../ADR/). Where a law and an ADR appear to conflict, the ADR is more specific and wins — but that itself should never happen silently; treat it as a documentation bug and reconcile the two.

**Violating one of these laws requires an explicit ADR.** Not a comment, not a TODO, not a "just this once." If a task seems to require breaking a law below, stop and propose an ADR (ChatGPT's role, approved by the User — see [`AI_GUIDELINES.md`](AI_GUIDELINES.md)) instead of writing the code.

1. **Determinism first.** Identical inputs produce identical outputs, always. Combat, stat rebuilds, and item generation are all specified this way. See [ADR-012](../ADR/ADR-012-STAT-MODIFIER-PIPELINE.md), [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md).

2. **Data-driven systems over hardcoded content.** Abilities, items, and affixes are immutable catalog definitions referenced by stable IDs, not hardcoded branches. See [ADR-013](../ADR/ADR-013-ABILITY-RESOURCE-ARCHITECTURE.md), [ADR-014](../ADR/ADR-014-INVENTORY-EQUIPMENT-OWNERSHIP.md). Where this law is not yet fully met (e.g. rarity rules), it is tracked as tech debt, not silently accepted — see [`Docs/Planning/TECH_DEBT.md`](../Planning/TECH_DEBT.md).

3. **Composition over inheritance.** Prefer reusable character, ability, resource, enemy, item, and encounter components over class-specific conditionals in shared code (e.g. `main.gd`). Multiple playable classes must share infrastructure without branching on class identity.

4. **Runtime owns mutable gameplay state.** `RuntimeCharacter` is constructed from durable `BuildData` and never performs disk I/O itself. See [ADR-011](../ADR/ADR-011-RUNTIME-CHARACTER-STATE.md).

5. **RuntimeSession owns session-scoped services.** The event bus, ability executor, item identity service, inventory, and equipment manager for one session are all owned by exactly one `RuntimeSession` composition root. See [ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md), [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md).

6. **One clear owner per responsibility.** Every piece of state and every side effect has exactly one system that owns it. Ownership is stated explicitly in the owning ADR, not inferred from usage.

7. **Catalog definitions remain immutable.** `ItemDefinition`, `AffixDefinition`, and `AbilityDefinition` are read-only and returned as defensive copies. See [ADR-014](../ADR/ADR-014-INVENTORY-EQUIPMENT-OWNERSHIP.md), [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md).

8. **Item identity is separate from generation provenance.** A generation seed determines an item's rolled contents; an identity token determines which individual physical item it is. Two calls with identical inputs may produce identical contents but must never produce colliding identities. See [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md).

9. **No hidden global gameplay state.** Gameplay state lives in objects owned by a session or a character, never in ambient globals that different sessions could accidentally share. See [ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md).

10. **No gameplay singleton shortcuts.** `RuntimeEventBus` and `AbilityExecutor` are explicitly not project autoload singletons — they are constructed and injected per session. See [ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md).

11. **Every gameplay bug receives a regression test.** See [`Docs/Standards/TESTING.md`](../Standards/TESTING.md) for the standing bug-pattern log and the regression-expectation convention.

12. **Every persistence feature receives a real JSON disk-path test.** An in-memory snapshot comparison is not sufficient — see [`Docs/Standards/TESTING.md`](../Standards/TESTING.md).

13. **Preserve save compatibility whenever practical.** Players are never required to restart a character to access new content. Snapshot conversion is explicit and versioned; unsupported fields are ignored rather than rejected outright. See [ADR-010](../ADR/ADR-010-PERSISTENT-CHARACTER-CONTINUITY.md), [ADR-015](../ADR/ADR-015-RUNTIME-PERSISTENCE-SYNCHRONIZATION.md).

14. **Major architectural changes require an ADR.** A new system, a changed ownership boundary, or a new cross-cutting dependency is an architectural change.

15. **CI must be green before merge.** See the merge gates in [`Docs/Roadmap/`](../Roadmap/) and the workflow definitions in `.github/workflows/`.

16. **Optimize only after measuring.** Affix pools stay unindexed and rarity rules stay simple until catalog scale or profiling justifies the change. See [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md) deferred decisions and [`Docs/Planning/TECH_DEBT.md`](../Planning/TECH_DEBT.md).

17. **One authoritative identity minter exists per active build/session.** Only one `RuntimeSession` may mint item identities for a build at a time. A future multiplayer implementation must move minting behind network authority before two concurrent sessions can mutate the same build. See [ADR-018](../ADR/018_PROCEDURAL_ITEM_GENERATION.md).

18. **The event bus is the only runtime gameplay event bus.** No gameplay system may create an ad-hoc second bus for the same session. See [ADR-016](../ADR/ADR-016-RUNTIME-EVENT-BUS-OWNERSHIP.md).

19. **Ability effects must use the established ability execution pipeline.** Validate → spend cost → start cooldown → execute effects, via `AbilityExecutor`. Failed validation changes no resource or cooldown state. See [ADR-013](../ADR/ADR-013-ABILITY-RESOURCE-ARCHITECTURE.md), [ADR-017](../ADR/ADR-017-ABILITY-EXECUTION-OWNERSHIP.md).

20. **Documentation must change when public system contracts change.** See [`Docs/Standards/DOCUMENTATION.md`](../Standards/DOCUMENTATION.md).
