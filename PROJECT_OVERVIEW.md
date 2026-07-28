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

## Current playable baseline

The authoritative approved build is **`main` at `7b4bde25940d1941c54857471efdc581c6b9b150`**, running in Godot 4.4.1. It contains the consolidated owner-approved full-stack Sunken Crypts foundation.

Draft PR #82 at frozen head `8d5958e51f499d966a790cc9feb479b339b29964` is a technically verified but unmerged Voidbringer impact/payoff candidate. It is waiting for the owner Windows playtest and is not an approved dependency base. After it passes and merges, Issue #83 completes the Grasping Rift micro-sprint from the exact resulting `main` SHA.

The owner-authorized roadmap is tracked by Issue #96. After Issue #83, Issue #97 must approve the transient combat-state/force/charge ownership ADR; Issues #89 through #95 then prove and migrate the foundational `Anchor → Load → Bend → Collapse` kit one slice at a time. Hollow King Issue #86 resumes only after Issue #95 unless the owner explicitly reprioritizes.

Implemented and verified in the approved baseline:

- smooth fixed-camera 3D movement, controller aiming, retained facing, and camera follow;
- Void Bolt, Shadow Step, and Grasping Rift with procedural Voidbringer VFX;
- living biomechanical Corruption resource;
- persistent XP, levels, class points, and manually opened graphical class tree;
- backpack-first loot, explicit equip/unequip, stable item identity, and full save/relaunch persistence;
- controller-friendly inventory navigation, scrolling, focus restoration, and wrapped item descriptions;
- home screen, Continue, New Character, Select Character, Start/Options pause, visible save, and safe return-to-menu;
- connected Sunken Crypts route with traps, generators, enemies, hidden relic room, objectives, and Hollow King encounter;
- complete-route procedural Art Pass 0 with decorative-only collision boundaries;
- automated regression coverage for runtime, persistence, progression, inventory, front end, controller behavior, art, VFX, and class gates.

**Active production scope is Voidbringer only.** Penitent mechanics remain preserved and regression-tested, but further Penitent graphical, content, and balance work is deferred until the class roster milestone is intentionally reopened.

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

Penitent skill branches (preserved prototype; production deferred):

- **Brands** — spreading marks, echoed damage, and chain reactions
- **Circles** — battlefield geometry, bindings, traps, and ritual networks
- **Sacrifice** — health spending, lifesteal, mutation, and dangerous power spikes

## Class selection and hidden paths

The class-selection framework can present multiple durable builds and classes, but the current production milestone is intentionally centered on Voidbringer. Penitent remains available as preserved prototype coverage; it is not an active content target. Future classes and Unknown Path presentation are postponed until the Voidbringer vertical slice is fun, stable, and visually coherent.

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
- Prove the foundational Voidbringer `Anchor → Load → Bend → Collapse` combat identity
- Refine Hollow King mechanics and reward after that class loop is proven
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

Agents are narrow specialists operating on one authoritative `main` baseline.

- **Owner / Game Director:** final authority over feel, visuals, scope, and merge approval.
- **ChatGPT / Technical Director:** architecture, production packets, acceptance criteria, integration planning, and merge control.
- **Claude Code / implementation lane:** one tightly scoped gameplay feature at a time after the production packet is approved.
- **Codex / repository lane:** mechanical repository work, migrations, CI, integration, and consistency audits.
- **Claude / independent verifier:** read-only verification of frozen exact commits; never co-authors the implementation being reviewed.

Only one implementation agent edits an owning system at a time. Additional agents are added only for a genuinely separate specialty, such as Blender rigging and Godot technical-art import.

## Branch and review policy

- One focused feature or fix per branch
- Branch from current `main`; normal work stays one PR deep, with two levels allowed only for a real dependency
- Maximum one active gameplay implementation PR and one non-overlapping docs/tooling PR
- Every branch must have explicit acceptance criteria
- Every pull request must show tests and limitations
- No feature branch may silently change another class
- Placeholder art is allowed until mechanics are fun and stable
- Final character art, bosses, networking, and mobile polish wait until the relevant foundation is proven
- The user and assistant remain creative directors; agents implement and test approved designs

## Immediate next actions

1. Owner Windows-playtest the exact PR #82 package and record PASS or actionable findings; merge only after explicit approval.
2. Implement Issue #83 from the exact `main` SHA produced after PR #82 merges, then complete its verification and owner playtest.
3. Write, independently review, owner-approve, and merge Issue #97's architecture ADR without overlapping the active PR #88 documentation lane.
4. Build Issues #89 through #95 sequentially from the exact `main` produced by each prior merge, proving the foundational ranged-geometry and close-range Worldshear loops.
5. Resume Hollow King Issue #86 after Issue #95 unless the owner explicitly reprioritizes.
6. Expand meaningful loot and one focused repeatable endgame loop after the class combat foundation is proven.
7. Keep co-op, additional classes, Dead Star, engine migration, and broad content expansion postponed.

## Definition of success for the current major milestone

A player can launch AbyssFall, continue a durable Voidbringer build, enter a visually coherent Sunken Crypts slice, immediately feel the difference between basic casting and intentional spatial setup, build and Collapse anchors through a credible ranged or close-range direction, make meaningful class-tree and gear choices, defeat a polished Hollow King encounter, save safely, and want to repeat the run.
