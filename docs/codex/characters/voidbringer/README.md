# Voidbringer Codex

Status: Approved  
Codex version: 1.0  
Implementation status: Design approved; production foundation prepared; playable migration pending  
Last updated: 2026-07-22  
Canonical class ID: `voidbringer`  
Production-system ID: `class.voidbringer`  
Compatibility ID: `void_warlock`

## Identity

Combat verb: **Fold**  
Primary resource: **Instability**  
Advanced risk state: **Breach**  
Signature mechanic: **Mass Anchors connected by Fold Lines**  
Movement ability: **Event Step**

Core statement:

> Nothing has weight, distance or direction unless the Voidbringer permits it.

The Voidbringer does not cast generic dark magic or throw ordinary black holes. The class changes relationships between position, direction, momentum and Mass. Enemies become counterweights, terrain becomes an anchor network, projectiles become orbiting ammunition and the player's body can become a living collapse point.

## Required reading by task

### Class fantasy or general design

Read:

- `01_CLASS_BIBLE.md`

### Skills, progression, builds or balance

Read:

- `01_CLASS_BIBLE.md`
- `02_SKILL_TREE.md`
- `08_BALANCE_AND_TEST_MATRIX.md`

### Weapons, loot, crafting or uniques

Read:

- `01_CLASS_BIBLE.md`
- `03_ITEMIZATION.md`
- `07_IMPLEMENTATION_CONTRACT.md`

### Controls, animation, VFX, audio, HUD or accessibility

Read:

- `04_COMBAT_PRESENTATION.md`
- Relevant skill sections in `02_SKILL_TREE.md`

### Enemy, encounter or boss work

Read:

- `05_ENCOUNTER_INTERACTIONS.md`
- `08_BALANCE_AND_TEST_MATRIX.md`

### Lore, characters, quests or class trials

Read:

- `06_NARRATIVE_AND_QUESTS.md`
- Mechanic definitions in `01_CLASS_BIBLE.md`

### Code, data, networking, AI or testing

Read:

- `02_SKILL_TREE.md`
- `05_ENCOUNTER_INTERACTIONS.md`
- `07_IMPLEMENTATION_CONTRACT.md`
- `08_BALANCE_AND_TEST_MATRIX.md`
- Root `AGENTS.md`
- Root `CLAUDE.md` when using Claude Code

## Approved disciplines

### Event Horizon

Anchor architecture, grouping, Fold Line geometry and catastrophic Collapse.

### Redshift

Velocity theft, projectile manipulation, orbit and high-speed repositioning.

### Hollow Form

Personal Mass, close-range force, counters and self-anchor builds.

These are freely mixable disciplines, not locked subclasses.

## Approved example builds

- Black Sun Architect
- Orbital Executioner
- Living Singularity
- Kinetic Butcher
- Mass Driver / Mass-Body Artillery
- Breach Engine
- One Final Point

## Non-negotiable rules

- Never turn the class into a generic shadow mage.
- Every major ability must interact with Mass, momentum, anchors, Fold Lines, Instability, position or collision.
- Control remains physical: drag, launch, orbit, compress, redirect and crush.
- Breach becomes an intentional mastery state, not a punishment meter.
- Bosses convert resisted force rather than displaying blanket immunity.
- Builds change behavior, not only damage output.
- A beginner can use Anchor → Load → Bend → Collapse immediately.
- Mastery comes from geometry, sequencing, force conversion and deliberate Breach resolution.

## Current implementation warning

The existing repository still contains the older `Void Warlock` prototype using Corruption, Void Bolt, Grasping Rift and the Abyss/Corruption/Soulbinding branches.

During migration:

- Preserve compatibility ID `void_warlock` until save migration is explicitly implemented.
- Do not treat prototype behavior as approved Voidbringer design.
- Replace gameplay incrementally through reviewable pull requests.
- Keep the playable-character contract working throughout the transition.

## Files

- `01_CLASS_BIBLE.md` — complete identity and class architecture
- `02_SKILL_TREE.md` — level 1–50 progression and every skill branch
- `03_ITEMIZATION.md` — Frames, class equipment, Distortions and uniques
- `04_COMBAT_PRESENTATION.md` — controls, feel, animation, VFX, sound and HUD
- `05_ENCOUNTER_INTERACTIONS.md` — enemy and boss response rules
- `06_NARRATIVE_AND_QUESTS.md` — origin, factions, trials and final boss
- `07_IMPLEMENTATION_CONTRACT.md` — data and runtime architecture
- `08_BALANCE_AND_TEST_MATRIX.md` — constants, telemetry and verification
- `CHANGELOG.md` — approved design changes

## Approval rule

Any change that contradicts these files requires an explicit Codex amendment in the same pull request. An implementation agent must not silently simplify, reinterpret or replace approved mechanics.