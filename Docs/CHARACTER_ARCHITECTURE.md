# AbyssFall Character Architecture

## Purpose

AbyssFall must support playable classes with fundamentally different combat loops without teaching the level controller about every ability or resource.

The first architecture pass preserves the existing Void Warlock implementation and introduces a small shared contract around it. The Penitent is represented by a deliberately limited playable prototype whose purpose is to prove that a second class can spawn, move, take damage, gain progression, expose a different resource, and bind to the existing level flow.

## Current layers

### Character contract

`scripts/core/character_contract.gd`

The contract is validated at runtime by method and signal names rather than forcing every character into one behavior-heavy superclass.

Required shared concepts:

- Class identity and metadata
- Health snapshot and health change signal
- Class-resource snapshot and resource change signal
- Progression snapshot and XP signal
- Level-up choices
- Inventory snapshot
- Skill-tree snapshot
- Damage and death
- Ability and loot messages

This allows Corruption and Fervor to remain separate implementations.

### Character factory

`scripts/core/character_factory.gd`

The factory owns the class registry and creates a character by stable class ID. The level controller requests a class without preloading a specific character script.

Registered IDs:

- `void_warlock`
- `penitent`

Unknown IDs fall back to `void_warlock`.

### Void Warlock adapter

`scripts/characters/void_warlock.gd`

The adapter inherits the validated v0.4 Warlock implementation and forwards the legacy `corruption_changed` signal into the generic `resource_changed` contract.

The underlying Warlock combat, skills, inventory, items, and visuals remain untouched in this pass.

### Penitent playable prototype

`scripts/characters/penitent_playable.gd`

The playable prototype proves the architecture only. It contains:

- Movement and dodge
- Health and death
- Fervor gain and spend
- Soul pickup compatibility
- Minimal inventory compatibility
- Three prototype skill branches
- A debug Ritual Blade strike
- Red, black, bone, and neon-green prototype geometry

It does not implement the final mark, sigil, chain, Sacrament, or health-substitution systems. Those belong to the Penitent gameplay vertical-slice task.

### Multi-class level wrapper

`scripts/multiclass_main.gd`

The wrapper inherits the existing Sunken Crypts level controller and overrides only class-facing responsibilities:

- Character creation through the factory
- Generic signal binding
- Generic resource label updates
- Dynamic skill branch rendering
- Class-specific menu copy
- Class-aware death messaging

The original `scripts/main.gd` remains intact, minimizing regression risk.

## Temporary class selection

The default class remains the Void Warlock.

The Penitent prototype can be launched through a user command-line argument:

```bash
godot --path . -- --class=penitent
```

This is a developer path only. The proper visual class-selection screen remains issue #4.

## Resource policy

Every class exposes:

```text
resource_changed(resource_id, display_name, current_value, maximum_value)
get_resource_snapshot()
add_class_resource(amount)
spend_class_resource(amount)
```

The shared layer knows that a resource has a name, value, and maximum. It does not know how Corruption or Fervor is earned, spent, decayed, contaminated, sacrificed, or rendered.

## HUD policy

The architecture pass temporarily feeds either resource into the existing Corruption meter geometry so signal binding can be proven.

This is not the final Penitent HUD. Issue #4 will provide separate visual implementations:

- Void Warlock: living biomechanical Corruption meter
- Penitent: assembling circular Fervor seal

## Compatibility policy

- Existing Warlock methods and signals remain available.
- Existing enemies continue targeting a `CharacterBody3D` with `alive` and `take_damage` behavior.
- Existing soul and item pickups remain compatible through `collect_soul` and `add_item`.
- Existing progression and inventory panels receive snapshots rather than class-specific node paths.
- The level controller does not branch on individual Warlock abilities.

## Next refactor targets

After this pass is validated:

1. Move input installation out of the Sunken Crypts level controller.
2. Move item pools into class-neutral and class-specific data resources.
3. Replace the temporary command-line class selector with the class-selection UI.
4. Split HUD visuals from HUD signal binding.
5. Implement Fervor as a dedicated component with threshold and health-substitution tests.
6. Implement Penitent marks and sigils without changing the Warlock adapter.

## Acceptance checks

- Default game still starts as the Void Warlock.
- Warlock behavior remains unchanged.
- Penitent can be instantiated through the factory with the canonical `penitent` ID.
- Both classes satisfy the shared contract.
- The level controller binds health, resource, XP, inventory, skills, messages, and death through shared names.
- Godot 4.4.1 editor/import validation passes.
- Default runtime smoke test passes.
- Penitent command-line runtime smoke test passes.
