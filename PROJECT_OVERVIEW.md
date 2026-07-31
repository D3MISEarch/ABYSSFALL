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

The authoritative approved full-stack baseline is **`main` at `7b4bde25940d1941c54857471efdc581c6b9b150`**, running in Godot 4.4.1. Later approved work may advance `main`; the exact active human gate and branch sequence belong in [`Docs/Roadmap/CURRENT_SLICE.md`](Docs/Roadmap/CURRENT_SLICE.md), not in this long-range overview.

The owner-authorized production sequence and exact current candidates are tracked in the active roadmap and GitHub issues. An unmerged candidate is never an approved dependency base; each dependent slice begins only from the exact resulting `main` SHA after its prerequisite passes owner playtest and merges.

Implemented and verified in the approved full-stack foundation:

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

**Active production scope is Voidbringer OP1 only.** Penitent mechanics remain preserved and regression-tested, but further Penitent graphical, content, balance, progression, and Codex production is deferred until OP1 passes and the owner explicitly opens a later operation.

## Binding production model

The binding scope doctrine lives in [`Docs/Design/GAMEPLAY_BIBLE.md`](Docs/Design/GAMEPLAY_BIBLE.md). This overview applies it as follows:

- The complete AbyssFall vision is a long-term destination, not one simultaneous launch checklist.
- Production advances one bounded, player-visible operation at a time.
- OP1 is the first complete proof: one exceptional Voidbringer, one polished environment, one memorable boss, one deep progression/build foundation, meaningful loot, one focused repeatable loop, and high-end presentation supported by stable persistence, testing, performance, and packaging.
- OP1 is not disposable scaffolding before the real game. It is the first finished proof of the real game and must be strong enough to communicate the vision without explanation.
- OP2 does not open until OP1 passes owner acceptance. Its exact content is chosen from proven needs, capacity, opportunity, and player response rather than precommitted now.
- Build the active use case specifically enough to make it excellent, cleanly enough to preserve extension seams, and generalize only after a real second consumer proves the shared contract.
- Future collaborators, contractors, funding, or publishing support may accelerate later operations, but OP1 must not depend on them.
- The eight-class destination is not a committed launch roster. Launch breadth will be set from proven capacity without lowering the quality bar.

## Playable class direction

### Void Warlock / Voidbringer compatibility path

**Current prototype fantasy:** command the hungry void.

- Ranged control and burst
- Gravity, portals, soul collection, and summoning
- Current prototype resource: **Corruption**
- Corruption is living, parasitic, organic, wet, and hungry
- Visual language: obsidian black, abyss purple, and sickly neon green
- Current prototype loop: group enemies, kill them, feed Corruption, and spend it on violent void effects

The approved future class identity is Voidbringer, with the canonical `Anchor → Load → Bend → Collapse` design documented in the character Codex. Existing `void_warlock` identity and saves remain compatibility concerns until a versioned migration is approved.

### The Penitent

**Fantasy:** carve laws into flesh and force reality to obey them.

- Close-to-mid-range ritual combat
- Melee strikes are used to carve and complete magic, not replace it
- Resource: **Fervor**
- Fervor is earned by completing marks, positioning enemies, activating sigils, and sacrificing health
- Visual language: ritual black, blood crimson, bone ivory, black iron, and neon venom green
- Core loop: mark enemies, place sigils, reposition targets, complete the pattern, and activate the ritual

Penitent skill branches preserved in the prototype:

- **Brands** — spreading marks, echoed damage, and chain reactions
- **Circles** — battlefield geometry, bindings, traps, and ritual networks
- **Sacrifice** — health spending, lifesteal, mutation, and dangerous power spikes

Penitent is long-term approved direction, not active production. Its next work requires OP1 acceptance and an explicit owner decision that Penitent belongs in the newly opened operation.

## Class selection and hidden paths

The class-selection framework can present multiple durable builds and classes, but the current production operation is intentionally centered on Voidbringer. Penitent remains available as preserved prototype coverage; it is not an active content target. Future classes and Unknown Path presentation are postponed until the Voidbringer OP1 slice is fun, stable, visually coherent, replayable, and owner-approved.

## Operation roadmap

### Foundation history — established and protected

Earlier work proved the baseline required to build a real slice:

- a clean Godot 4.4.1 project and automated runtime validation;
- class-agnostic ownership seams for health, movement, resources, abilities, equipment, XP, HUD binding, and class definitions where already proven;
- persistent character continuity, inventory, class points, controller navigation, front end, save/relaunch, and packaging workflows;
- the connected Sunken Crypts route, Art Pass 0, enemies, generators, traps, hidden room, and Hollow King foundation;
- a preserved Penitent prototype used to expose early class-separation requirements without committing Penitent to current production.

Historical stage documents remain useful architectural evidence. They are not the current production queue and may not reopen broad work by implication.

### OP1 — first polished Voidbringer proof

**Goal:** manufacture the first complete, repeatable, presentation-ready AbyssFall unit.

OP1 contains several sequential passes, not one giant branch:

#### OP1-A — combat and build identity

- Prove `Anchor → Load → Bend → Collapse` through satisfying player-facing skills.
- Establish clear ranged and close-range directions before broad build expansion.
- Improve hit feel, reactions, deaths, resource payoff, movement, impact, readability, and supporting rotation.
- Develop the persistent class tree, skill evolution, resource engines, tags, and equipment interactions through bounded slices.

#### OP1-B — boss and environment quality

- Turn the Sunken Crypts foundation into one visually coherent, atmospheric environment.
- Develop Hollow King into a memorable, readable, multi-phase boss that tests the proven Voidbringer loop.
- Improve lighting, materials, set dressing, VFX, audio, telegraphs, reward presentation, and environmental storytelling.

#### OP1-C — meaningful progression and loot

- Deliver several genuinely different Voidbringer build directions.
- Add build-changing items and affixes that alter behavior rather than only magnitude.
- Make class-tree, skill, equipment, defensive, movement, and resource decisions understandable and consequential.
- Preserve durable build continuity and loadout safety.

#### OP1-D — one focused repeatable loop

- Build one Wound or equivalent repeatable endgame activity around the proven class, region, boss, loot, and progression foundation.
- Favor depth, modifiers, mastery, rewards, and replay desire over multiple shallow modes.

#### OP1-E — polished proof package

- Complete the strongest feasible lighting, atmosphere, materials, VFX, audio, camera, animation, UI, and cinematic presentation pass for the bounded slice.
- Meet controller, persistence, performance, packaging, accessibility, regression, and owner-playtest gates.
- Produce documentation and handoff workflows that make the next operation cheaper and safer.
- Create a slice credible enough to show players, collaborators, contractors, publishers, or funding partners.

OP1 passes only when the experience feels like a coherent game worth replaying, not when every planned data structure exists.

### OP2 — first expansion operation, gated

OP2 is intentionally undefined until OP1 passes.

After acceptance, the owner may choose a bounded next unit such as:

- a second class using the proven campaign and content foundation;
- a second environment and boss using the proven Voidbringer systems;
- deeper content for the successful OP1 slice;
- or another strategically valuable proof based on player response, production bottlenecks, collaborator interest, funding, and available capacity.

OP2 should reuse what OP1 genuinely proved. It is also the first legitimate point to generalize systems when a second real consumer demonstrates the common contract. It must not become a wholesale rewrite of OP1 into a speculative universal engine.

### Later operations and commercial scope

Later operations repeat the same discipline: one bounded unit, explicit acceptance, measured reuse, and no dependency on hypothetical future resources.

The long-term class roster, additional realms, regional factions, bosses, build systems, and endgame depth remain valid franchise direction. They enter production only through explicit later operations.

The first commercial release may contain OP1 plus additional proven operations, but its exact class count, realm count, boss count, endgame breadth, co-op support, and platforms are not precommitted. Release scope is chosen when proven capacity can support it at the required quality.

Local co-op comes only after the single-player core is fun and stable. Online networking comes only after local/co-located rules and encounter scaling are proven. Any Godot-to-Unreal decision remains gated behind the structured playtest of the polished OP1 slice.

## Agent workflow

Agents are narrow specialists operating on one authoritative `main` baseline.

- **Owner / Game Director:** final authority over feel, visuals, scope, and merge approval.
- **ChatGPT / Technical Director:** architecture, production packets, acceptance criteria, integration planning, and merge control.
- **Claude Code / implementation lane:** one tightly scoped gameplay feature at a time after the production packet is approved.
- **Codex / repository lane:** mechanical repository work, migrations, CI, integration, and consistency audits.
- **Claude / independent verifier:** read-only verification of frozen exact commits; never co-authors the implementation being reviewed.

Only one implementation agent edits an owning system at a time. Additional agents are added only for a genuinely separate specialty, such as Blender rigging, animation, audio, environment art, or Godot technical-art import. Adding agents does not authorize simultaneous scope expansion.

## Branch and review policy

- One focused feature or fix per branch
- Branch from current `main`; normal work stays one PR deep, with two levels allowed only for a real dependency
- Maximum one active gameplay implementation PR and one non-overlapping documentation/tooling PR
- Every branch must have explicit acceptance criteria
- Every pull request must show tests and limitations
- No feature branch may silently change another class
- Placeholder art is allowed while mechanics are being proven, but OP1 cannot pass with presentation that fails its owner-approved quality bar
- Final character art, broad networking, additional classes, and platform expansion wait until the relevant operation is proven and opened
- The user and assistant remain creative directors; agents implement and test approved designs

## Immediate next actions

The exact issue and PR sequence belongs in [`Docs/Roadmap/CURRENT_SLICE.md`](Docs/Roadmap/CURRENT_SLICE.md). Inside OP1, the standing priority is:

1. Complete and owner-approve the active Voidbringer combat slices from exact merged `main` baselines.
2. Prove the foundational ranged-geometry and close-range Worldshear loops one bounded, tested slice at a time.
3. Advance Hollow King boss quality after the relevant Voidbringer mechanics can test and exploit it.
4. Improve art direction, lighting, materials, atmosphere, VFX, audio, and cinematic presentation alongside proven gameplay rather than as an unrelated final pass.
5. Expand meaningful loot and the persistent class tree only where each addition creates a visible build decision.
6. Build one focused repeatable endgame loop after the class, boss, environment, and reward foundation is credible.
7. Keep Penitent production, additional classes, second realms, co-op, platform expansion, Dead Star, and engine migration postponed until their explicit gates open.

## Definition of success for OP1

A player can launch AbyssFall, continue a durable Voidbringer build, enter a visually coherent Sunken Crypts slice, immediately feel the difference between basic casting and intentional spatial setup, build and Collapse anchors through credible distinct build directions, make meaningful class-tree and gear choices, defeat a polished Hollow King encounter, enter a focused repeatable loop, save safely, relaunch, and want to play again.

The slice must also leave behind a stable, documented production process. Another person should be able to play it and understand what AbyssFall is becoming without being asked to imagine six future operations first.