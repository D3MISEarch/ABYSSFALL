# AbyssFall — Project Synopsis, Roadmap, and Agent Plan

## Elevator pitch

**AbyssFall** is a dark-fantasy action dungeon crawler inspired by the immediate co-op chaos, readable classes, enemy generators, pickups, and realm progression of classic arcade dungeon crawlers, rebuilt with an original universe focused on the Abyss, forbidden rituals, biomechanical corruption, build-defining gear, and unlockable character paths.

The target experience is fast, readable, controller-friendly combat where players clear hordes, destroy generators, explore dangerous levels, collect equipment, level up during runs, shape a class build, defeat multi-phase bosses, and eventually play locally or online with friends.

## Core game pillars

1. **Arcade horde combat** — large groups, quick attacks, clear danger, satisfying crowd control, and little downtime.
2. **Distinct playable classes** — each class has its own resource, visual language, combat loop, skill tree, gear, and risk profile.
3. **Build progression** — XP choices, skill nodes, equipment, relics, consumables, and legendary effects that change ability behavior.
4. **Exploration and realms** — connected levels with generators, traps, secrets, optional relic rooms, bosses, and unlockable paths.
5. **Dark original identity** — cracked obsidian, ritual metal, blood sigils, void portals, wet organic corruption, bone masks, chains, and neon contamination.
6. **Expandable co-op foundation** — single-player first, then local co-op, then online multiplayer after the core combat and architecture are stable.

## Current playable prototype

The latest local build is **Void Warlock v0.4 Hotfix 3: The Sunken Crypts**.

Implemented or prototyped locally:

- Fixed-camera 3D action combat
- Void Bolt, Shadow Step, and Grasping Rift
- Living biomechanical Corruption meter
- Soul pickups and Corruption Essence
- Enemy generators
- Skeleton Reavers, Bone Archers, and Crypt Brutes
- XP, level-ups, three-choice upgrades, and a skill tree
- Inventory, equipment slots, rarity tiers, and named items
- Connected Sunken Crypts level flow
- Traps, gates, hidden relic room, and objectives
- Three-phase Hollow King boss encounter

The project has progressed beyond compiler errors into runtime testing, but Hotfix 3 still needs to be launched and verified on the home PC.

## Playable class direction

### Void Warlock

**Fantasy:** command the hungry void.

- Ranged control and burst
- Gravity, portals, soul collection, and summoning
- Resource: **Corruption**
- Corruption is living, parasitic, organic, wet, and hungry
- Visual language: obsidian black, abyss purple, and sickly neon green
- Core loop: group enemies, kill them, feed Corruption, and spend it on violent void effects

### The Penitent

**Fantasy:** carve laws into flesh and force reality to obey them.

- Close-to-mid-range ritual combat
- Melee strikes are used to carve and complete magic, not replace it
- Resource: **Fervor**
- Fervor is earned by completing marks, positioning enemies, activating sigils, and sacrificing health
- Visual language: ritual black, blood crimson, bone ivory, black iron, and neon venom green
- Core loop: mark enemies, place sigils, reposition targets, complete the pattern, and activate the ritual

Penitent skill branches:

- **Brands** — spreading marks, echoed damage, and chain reactions
- **Circles** — battlefield geometry, bindings, traps, and ritual networks
- **Sacrifice** — health spending, lifesteal, mutation, and dangerous power spikes

## Class selection and hidden paths

The class-selection screen presents heroes as large fantasy-first character cards. The Void Warlock and The Penitent are selectable. Future classes remain visible as chained silhouettes labeled as unknown paths, with a lore hint and unlock requirement rather than being completely hidden.

This gives players something to chase and makes the roster feel larger before every class is playable.

Potential future archetypes remain intentionally undecided until the first two classes prove the shared architecture.

## Roadmap

### Phase 0 — Stable baseline

**Goal:** prove that the existing v0.4 Hotfix 3 project launches cleanly in Godot 4.4.1.

- Upload the complete Godot project to GitHub
- Put `project.godot` at the repository root
- Run headless parser/import validation
- Run a bounded runtime smoke test
- Fix all startup, scene-tree, resource, and runtime errors
- Record final commands and outputs
- Freeze this as the clean baseline

### Phase 1 — Multi-class architecture

**Goal:** stop the project from being hard-coded around the Void Warlock.

- Reusable character controller foundation
- Separate health, movement, resource, ability, equipment, XP, and HUD responsibilities
- Resource interface with separate Corruption and Fervor implementations
- Data-driven class definitions
- Signal-driven HUD binding
- Temporary class-selection screen
- Preserve current Void Warlock gameplay

### Phase 2 — Penitent vertical slice

**Goal:** prove the Penitent's mark-to-ritual combat loop using placeholder visuals.

Prototype kit:

- Ritual Blade
- Brand of Ruin
- Seal of Binding
- Martyr's Chain
- Ashen Procession
- Sacrament

Prototype systems:

- Partial and completed Rite Marks
- Ground sigils and active-sigil capacity
- Fervor gain, spend, thresholds, and out-of-combat decay
- Safe health substitution with clear preview
- Six starter skill nodes
- Temporary character selection
- Penitent-specific HUD and playtest checklist

### Phase 3 — First polished vertical slice

**Goal:** turn the prototype into a short section that looks and feels like a real game.

- Tune movement, hit feel, enemy density, resource economy, XP pacing, and drops
- Improve Sunken Crypts room flow
- Refine Hollow King mechanics and reward
- Add class-specific sound language
- Add stronger VFX and screen feedback
- Replace the roughest placeholder geometry
- Add pause, settings, accessibility, and save support

### Phase 4 — Progression and content expansion

- Expanded skill trees
- Larger class-specific and neutral item pools
- Legendary and Mythic build-changing gear
- Persistent hub progression
- Unlock requirements for hidden class paths
- Additional enemies, elites, generators, traps, and minibosses
- Second realm and boss
- Difficulty modifiers and replay systems

### Phase 5 — Final characters and additional classes

- Production-quality Warlock and Penitent models
- Animation sets and ability-specific casting/attack animation
- Character skins and visual progression
- Third playable class revealed from an Unknown Path slot
- Class-specific story moments and unlock quests

### Phase 6 — Co-op and platform work

- Local controller co-op first
- Shared camera and encounter scaling
- Revive and drop-sharing rules
- Online networking after local co-op is stable
- Lobby, reconnect, authority, synchronization, and latency handling
- PC optimization and controller certification pass
- Android controls, UI scaling, performance, and packaging

### Phase 7 — Release candidate

- Multiple complete realms
- Full boss roster for launch scope
- Balanced class trees and item economy
- Save migration and settings stability
- Tutorials and onboarding
- Accessibility pass
- Performance targets met on PC and supported Android devices
- Closed testing, bug triage, store assets, and release preparation

## Agent workflow

Agents are used as narrow specialists, not as an unsupervised studio.

### Agent 1 — Runtime and QA

Responsibilities:

- Reproduce errors in Godot 4.4.1
- Run headless validation and runtime smoke tests
- Fix parser, compiler, resource, scene-tree, and startup errors
- Document every command and final result
- Add no gameplay features

This agent must finish first.

### Agent 2 — Character architecture

Responsibilities:

- Refactor the existing Warlock-centric code into reusable systems
- Create clear interfaces/components for resources, abilities, stats, equipment, XP, and HUD data
- Keep Warlock behavior unchanged
- Prove a second placeholder class can spawn without modifying the main level controller

This agent starts only after the clean baseline passes.

### Agent 3 — Penitent gameplay

Responsibilities:

- Implement the Penitent vertical slice on its own branch
- Build marks, sigils, Fervor, chains, Sacrament, and the first six nodes
- Use placeholder art
- Preserve the Void Warlock
- Add focused playtest documentation

This agent starts after the architecture is ready.

### Agent 4 — UI and class selection

Responsibilities:

- Build the reusable class-selection screen
- Add selectable Warlock and Penitent cards
- Add chained Unknown Path slots for future characters
- Create signal-driven resource and ability HUD framework
- Implement Penitent Fervor seal, Rite Mark indicators, sigil capacity, and health-sacrifice preview
- Support controller, keyboard/mouse, and future mobile focus/input

### Agent 5 — Reviewer and integrator

Responsibilities:

- Review pull requests for regressions, hard-coded assumptions, and duplicate systems
- Verify acceptance criteria and test outputs
- Reject claims that are not backed by Godot runs
- Check that branches remain focused
- Merge only approved, tested work in dependency order

## Branch and review policy

- One focused feature or fix per branch
- Every branch must have explicit acceptance criteria
- Every pull request must show tests and limitations
- No feature branch may silently change another class
- Placeholder art is allowed until mechanics are fun and stable
- Final character art, bosses, networking, and mobile polish wait until the relevant foundation is proven
- The user and assistant remain creative directors; agents implement and test approved designs

## Immediate next actions

1. At home, copy v0.4 Hotfix 3 into the cloned GitHub repository.
2. Commit and push the full Godot project.
3. Run Agent 1 against issue #1 until the baseline passes.
4. Review and merge the QA pull request.
5. Run Agent 2 for multi-class architecture.
6. Run Agent 4 for the class-selection and HUD framework.
7. Run Agent 3 for The Penitent vertical slice.
8. Playtest both classes before expanding the realm or adding a third character.

## Definition of success for the first major milestone

A player can launch AbyssFall, choose either the Void Warlock or The Penitent, clear a short Sunken Crypts run, make meaningful level-up and gear choices, defeat the Hollow King, and immediately understand why the two classes feel fundamentally different.
