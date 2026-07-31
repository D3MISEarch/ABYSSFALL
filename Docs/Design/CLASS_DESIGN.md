# Class Design

## Confirmed

### Void Warlock — current playable compatibility prototype

- Current shipped/prototype fantasy: hungry-void ranged control and burst using Corruption, Void Bolt, Shadow Step and Grasping Rift.
- Preserve current playable behavior until a replacement milestone explicitly changes it.
- Persistent compatibility ID: `void_warlock`.
- This prototype is **not** the approved future design authority for the class.

Sources: `PROJECT_OVERVIEW.md`, current runtime implementation and existing playtest documentation.

### Voidbringer — approved future replacement design

- Canonical design identity: `voidbringer`.
- Compatibility during migration: existing saves and class selection continue using `void_warlock` until a versioned migration is approved.
- Fantasy: fused to a forbidden Manifold that assigns Mass, direction and valid location; controls physical relationships rather than casting generic void magic.
- Core loop: **Anchor → Load → Bend → Collapse**.
- Core systems: Mass Anchors, Fold Lines, Instability, Breach, Closure, Personal Mass and Velocity Reserve.
- Disciplines: Event Horizon, Redshift and Hollow Form.
- Complete approved specification: [`../../Docs/codex/characters/voidbringer/README.md`](../../Docs/codex/characters/voidbringer/README.md).

The detailed Codex is canonical for Voidbringer's player-facing design. Engineering implementation remains subordinate to the Engineering Constitution, ADRs and current architecture.

### The Penitent — active construction, second playable class

- Fantasy: carve laws into flesh and force reality to obey them. Close-to-mid-range ritual combat; melee carves and completes magic rather than replacing it.
- Current implemented/prototype resource: **Fervor**.
- Existing detailed sources: `design/FERVOR_SYSTEM_V1.md`, `Docs/PENITENT_CLASS.md`, `design/PENITENT_ITEM_POOL_V1.md`.
- The eventual full Penitent Codex must use the shared character-bible template and reconcile existing implementation before replacing it as authority.

### Shared architecture constraint

Shared systems must not assume every class casts projectiles, uses Corruption, uses Fervor or shares one HUD. Resource interfaces, ability execution, event delivery, stat calculation and persistence must remain class-agnostic. See [`../Architecture/ARCHITECTURE.md`](../Architecture/ARCHITECTURE.md) and the relevant ADRs.

### Shared campaign and character-arc constraint

AbyssFall has one shared world, one campaign timeline and one universal central conflict for every playable class.

Every class receives a personal journey layered through that campaign:

- a class-specific origin,
- mentor or specialist faction,
- personal rivals,
- trials and mechanic-unlock quests,
- class-specific readings of shared regions and events,
- and a mastery finale with local or personal consequences.

Class stories do not become mutually incompatible replacement campaigns. Class antagonists are not automatically universal campaign villains, and class finales cannot erase shared regions, chronology or endgame infrastructure.

Binding narrative doctrine: [`../../Docs/codex/SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md`](../../Docs/codex/SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md).

### Approved full launch roster direction

The character Codex program will develop one class at a time to the Voidbringer depth standard:

1. Voidbringer
2. Penitent
3. Graftborn
4. Somnarch
5. Relic Host
6. Gorgon
7. Tidewrought
8. Anachron

Reserved for expansions or later specialization work:

- Choirborn
- Echo Thief
- Plaguebringer

Only Voidbringer currently has a complete approved Codex. Other roster entries remain design direction until their own folders are completed and approved.

## Character-bible standard

Every complete class must define:

- fantasy and silhouette,
- core verb and gameplay loop,
- resource and advanced risk mechanic,
- movement identity,
- complete level progression and skill tree,
- three freely mixable disciplines or paths,
- build-changing upgrades, Law Nodes and Culmination Nodes,
- equipment and unique-item interactions,
- controls, HUD, animation, VFX and audio,
- enemy and boss translations,
- lore, quests and class-specific encounters,
- shared campaign intersections,
- a class mastery finale that preserves universal campaign continuity,
- implementation, balance and verification contracts.

Template: [`../../Docs/codex/characters/CHARACTER_BIBLE_TEMPLATE.md`](../../Docs/codex/characters/CHARACTER_BIBLE_TEMPLATE.md).

## Binding build-depth doctrine

### Status and authority

**OWNER APPROVED — BINDING SHARED CLASS-DESIGN DOCTRINE**

- **Decision date:** 2026-07-31
- **Human owner:** D3MISEarch
- **Scope:** every playable AbyssFall class and every production build system
- **Relationship to ADR-020:** this doctrine defines buildcraft outcomes and class-design requirements; ADR-020 remains authoritative for persistent class-point progression, board interaction, shared node grammar and progression UI architecture.
- **Change control:** this doctrine may be replaced only by an explicit owner-approved design revision. A prototype shortcut, temporary implementation limitation or isolated balance patch does not silently weaken it.

The target is not merely a large number of skills or passive nodes. AbyssFall must produce deep character authorship through multiple systems that alter and reinforce one another. Two players using the same class and even the same core skill must be able to create characters with materially different combat rhythms, positioning requirements, resource loops, defenses, equipment priorities, visual behavior, strengths and weaknesses.

The intended balance is:

> **Path of Exile-style experimentation + Diablo-style tactile readability + AbyssFall's brutal class identity — mandatory guide dependence — meaningless passive clutter — one-button automated play.**

A new player must be able to assemble a functional build by following clear fantasy and mechanical signals. A dedicated player must still be able to discover unusual hybrid interactions after extensive play.

### The required build equation

A legitimate endgame build is assembled from interacting layers:

> **Core Skill + Skill Evolution + Resource Engine + Mastery Path + Law Node + Equipment Rule-Breaker + Defensive Engine + Movement Tech + Supporting Rotation + Content Specialization**

No single layer may carry the entire build system. Changing several layers must produce a visibly and mechanically different build rather than the same rotation with larger percentages.

### Persistent class-board requirements

Every complete class board must provide:

- three recognizable discipline or progression regions;
- shared bridge routes that enable intentional hybrid builds;
- Law Nodes that change rules, priorities, sequencing, positioning, resource behavior or risk;
- Culmination Nodes that complete a major build direction;
- attributes, efficiencies and utility choices that matter because skills, equipment and thresholds reference them;
- deeper commitment routes for specialized endgame builds;
- enough local readability that a new player can follow one fantasy without understanding the entire board;
- enough cross-region interaction that expert players can create coherent hybrids.

Minor nodes may support a build, but they may not dominate the board with filler. The board must not become difficult merely because it contains excessive low-impact choices.

### Individual skill evolution

Every major active skill must support meaningful evolution. Skill progression should prioritize a small number of consequential choices over long rank ladders filled with negligible increases.

A mature skill should expose some combination of:

- **Behavior evolution:** changes what the skill physically does, how it travels, targets, persists or occupies space.
- **Damage evolution:** changes scaling, damage type, status behavior, conversion or payoff condition.
- **Utility evolution:** changes mobility, defense, control, setup or resource generation.
- **Final mutation:** a major commitment that defines the skill's endgame role and may exclude another mutation unless an approved rule-breaker permits both.

A skill mutation must be readable in play through animation, VFX, sound, targeting or rotation—not only through tooltip text.

Example: the same Void Lance foundation could become a piercing precision projectile, a slow gravitational drill, a tether between the Voidbringer and a target, a close-range execution impalement or an orbiting lance stored and released later. These are different tactical roles, not cosmetic variants.

### Mechanical tags as buildcraft language

Abilities, effects and equipment must use stable, data-owned tags that other systems can reference. Tags create a shared interaction language without hard-coding every possible combination.

Representative Voidbringer tags include:

- `Void`
- `Gravity`
- `Execution`
- `Rupture`
- `Orbit`
- `Channel`
- `Movement`
- `Wound`
- `Construct`

The final global vocabulary must remain controlled and documented. Tags may be added when they unlock meaningful interaction families; they may not proliferate as decorative synonyms.

Passives, Law Nodes, equipment, enemy states and content modifiers may add, remove, transform or reference tags. A rule-breaker may, for example, make Gravity skills also count as Execution skills while disabling critical strikes and converting excess critical chance into execution threshold. That item would establish a new build family rather than grant a flat damage bonus.

### Equipment influence and rule-breaking

Equipment must participate in build authorship at several levels:

- **Rare equipment:** optimizes stats, breakpoints, defenses, cooldowns, resource flow and damage.
- **Legendary equipment:** alters an individual skill, mechanic or interaction.
- **Relics and unique items:** create new rules, engines, conversions or rotations.
- **Corrupted equipment:** offers dangerous endgame conversions with explicit drawbacks or instability.

A powerful item may establish an engine, but the player must decide how to complete and support it. AbyssFall rejects mandatory full-set uniforms where equipping a prescribed collection causes the game to choose the entire build for the player.

Build-defining equipment must obey the following laws:

1. It changes behavior, relationships or constraints—not only magnitude.
2. Its tradeoff or opportunity cost remains meaningful.
3. It interacts with the class board, skill evolution, tags or resource engine.
4. It does not become the only viable way to use the underlying skill.
5. Its effect is understandable enough to inspire experimentation.

### Resource engines

A class resource may not function as generic mana with a thematic name. Every complete class must support multiple coherent methods of generating, spending, preserving, converting or weaponizing its resource.

Voidbringer Mass may support builds that:

- generate and spend Mass rapidly;
- hoard Mass for major singularity detonations;
- spend health or another cost instead of Mass;
- convert stored Mass into armor, poise or stagger resistance;
- preserve maximum Mass while consuming orbiting objects;
- intentionally enter Mass debt for unstable power;
- generate Mass through perfect dodges, executions, forced movement or enemy displacement.

The resource engine is part of the build's identity and rotation. It must not collapse into one universally mandatory regeneration affix.

### Defensive engines and movement identity

Damage output alone does not define a build. Every production build must establish how it survives and repositions.

Defensive engines may include avoidance, mitigation, conversion, barriers, recovery, crowd control, stagger resistance, resource-as-defense, execution recovery or conditional invulnerability. Movement tech may include dodges, teleports, lunges, folds, pulls, anchors, momentum storage or class-specific traversal interactions.

Defense and movement should interact with offense where appropriate, but no class may be forced into one universal defensive package. A build's survival method must create real tactical consequences rather than an invisible checklist of capped statistics.

### Supporting rotation and specialization

A core skill does not excuse one-button automated gameplay. Strong builds should have supporting actions that establish, transform, maintain or cash out the main engine.

A build may specialize for boss execution, dense enemy control, speed clearing, survivability, stagger, Wounds, a particular endgame modifier or another approved content role. Specialization must create advantages and tradeoffs without making ordinary content nonfunctional.

Automation may reduce repetitive maintenance, but it may not erase the sequencing, positioning or judgment that gives the build its identity.

### Multiple gameplay verbs per class

Every class must support several gameplay verbs. Its build system decides which verbs dominate, combine or transform.

Voidbringer's approved verb family includes:

- Pull
- Crush
- Orbit
- Impale
- Execute
- Anchor
- Collapse
- Redirect
- Sacrifice
- Weaponize the environment

Voidbringer may not collapse into the generic instruction “cast gravity spells.” Other classes must receive equally specific verb families in their own Codices.

### Approved Voidbringer build families

The following families are binding direction for Voidbringer build breadth. Names and exact balance may evolve, but the distinct gameplay identities must be preserved or replaced by owner-approved equivalents.

#### Event Horizon

A deliberate ramp-and-collapse caster. Pull enemies together, assign Mass, establish Anchors or Wounds and collapse the assembled field in one major singularity payoff. Excellent burst and control, but setup time and survival during the ramp matter.

#### Gravitic Executioner

A close-range executioner-mage. Heavy attacks and gravity actions apply Weight or equivalent execution pressure. Movement and forced-positioning tools create execution angles; high commitment enables brutal chain ruptures. This build values proximity, timing and target selection.

#### Orbiting Arsenal

A mobile orbit-and-projectile build. Weapons, stones, armor fragments, environmental debris and enemy remains may become stored orbiting objects. The player chooses whether to preserve the orbit for defense and utility or launch and sacrifice it for offense.

#### Living Singularity

A slow, oppressive tank-controller. Stored Mass becomes mitigation, poise and local gravitational pressure. Mobility or dodge quality is reduced in exchange for becoming a walking environmental hazard that slows, drags and crushes nearby enemies.

#### Rupture Engine

A fast combo build. Repeated small gravity impacts plant fractures or Wounds inside enemies. Teleporting through targets, colliding them, crossing Fold Lines or executing a prepared target detonates stored ruptures. Sequencing and movement create the payoff.

#### Starved Void

A dangerous low-resource or negative-resource build. Skills become stronger while Mass is empty, overdrawn or in debt. The player deliberately overspends and must recover through executions, precision or another aggressive condition before instability consumes the advantage.

These families must not resolve into six versions of purple damage scaling. They require different rhythms, positioning, equipment priorities, defenses, animations, VFX, strengths, weaknesses and mastery demands.

### Solo-development production proof

The complete architecture should be designed for the full roster, but production proof begins with Voidbringer. The first polished build-depth proof should target:

- six combat-ready active skills;
- two movement or defensive skills;
- one ultimate;
- three interconnected mastery regions;
- four meaningful Law Nodes;
- at least two consequential evolution choices for every implemented major skill;
- eight build-defining items across the approved equipment tiers;
- a stable affix and tag foundation;
- four genuinely playable and visibly distinct build archetypes selected from the approved Voidbringer families;
- build-loadout saving;
- a readable combat-stat and interaction breakdown.

This is a production target, not permission to implement the entire system in one pull request. Each slice remains subject to architecture, persistence, testing, graphical-playtest and owner-approval gates.

The proof succeeds only when the four builds feel different during play—not merely when data definitions exist or automated tests pass.

### Build-depth acceptance tests

A proposed production build should be rejected or revised when any of the following is true:

- swapping its defining item changes only damage magnitude;
- its resource engine matches every other build for the class;
- its rotation is effectively one held button;
- its Law Node could be replaced by a percentage bonus without changing play;
- it has no distinct defensive or movement logic;
- its skill mutation is invisible during normal combat;
- it requires a guide because local choices communicate poorly rather than because advanced optimization is deep;
- it is viable only because one mandatory set or unique package supplies the entire design;
- two advertised archetypes use the same rotation, positioning and survival plan;
- the build's fantasy is described by damage color rather than gameplay verbs.

A build-depth milestone is accepted only when player-facing playtests demonstrate distinct feel, readable causality, meaningful tradeoffs and more than one coherent route through the class's systems.

### Inspiration boundary

Owner-provided reference videos dated 2026-07-31 demonstrated the desired depth of interlocking skills, passives, gear, stat thresholds, resource management, defensive conversion, movement technology, supporting rotations and alternate variants.

Those references establish an experiential benchmark. AbyssFall will not copy another game's protected names, exact tree topology, item text, abilities, artwork, numerical balance or progression economy. The doctrine above translates the desired depth into AbyssFall's own systems and identity.

## Open questions

- Exact schedule for replacing the current Void Warlock prototype with the approved Voidbringer implementation.
- Versioned migration from compatibility ID `void_warlock` to canonical ID `voidbringer`.
- Which class receives the next full Codex after the Voidbringer foundation enters implementation.
- Final universal campaign act structure, central antagonist and finale; these belong in a future shared campaign bible rather than any single class Codex.
- Exact production values, node counts, affix ranges, item counts and balance thresholds beyond the bounded Voidbringer proof target remain prototype and milestone outputs.

## Deprecated

- Treating “Voidbringer” as an undecided working label or separate class from Void Warlock. It is now the approved future replacement design, while `void_warlock` remains only the compatibility/prototype identity during migration.
- Treating any class-specific journey as a replacement for the shared AbyssFall campaign.
- Treating build depth as a large passive-node count, a pile of flat percentage bonuses or a mandatory equipment set.
- Treating a class resource as generic mana with a renamed presentation layer.
- Advertising multiple builds that share the same rotation, positioning, defense and movement while differing only in damage type or color.
