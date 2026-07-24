# ABYSSFALL — VOIDBRINGER PRODUCTION CONTRACT
## Stable IDs, Data Schemas, Runtime Ownership, Formulas, AI Hooks and Godot Integration

Status: Approved  
Codex version: 1.0  
Implementation status: Architecture approved; package foundation prepared  
Last updated: 2026-07-22  
Target engine: Godot 4.4.1 / GDScript  
Canonical class ID: `voidbringer`  
Production-system ID: `class.voidbringer`  
Compatibility ID: `void_warlock`

---

# 1. Purpose

This contract converts the Voidbringer design into stable implementation boundaries.

The system is split into:

- Immutable definitions
- Runtime state managers
- Formula services
- Animation events
- Combat events
- AI-readable spatial state
- Presentation listeners

The central rule is:

> An ability definition describes what should happen. Runtime managers decide what is currently possible and execute the portions they own.

An ability must not privately own every subsystem it touches.

For example, Rail Collapse requests:

1. Anchor selection
2. Anchor removal
3. Projectile or living-body launch
4. Mass conversion
5. Instability change
6. Collision resolution

The Anchor Manager, Instability Controller, Force Resolver, projectile system and collision system each execute their own portion.

---

# 2. Repository migration rule

The current repository uses `void_warlock` as a persistent playable-class ID.

Initial Voidbringer integration must preserve:

- Compatibility ID: `void_warlock`
- Existing saved builds
- Existing class-selection route
- Existing playable-character contract

During transition:

- Display name may change to Voidbringer.
- Approved mechanics come from this Codex, not the old prototype.
- New systems are introduced behind a compatibility adapter.
- Permanent ID migration occurs only through a dedicated save-migration pull request.

Do not delete the existing Void Warlock prototype in the first foundation import.

---

# 3. Stable ID convention

IDs are permanent save-data, telemetry, itemization and networking keys.

Format:

`vb.<category>.<snake_case_name>[.<variant>]`

Categories:

- `vb.action` — dedicated class actions
- `vb.skill` — normal active skills
- `vb.ultimate` — ultimate skills
- `vb.status` — statuses
- `vb.passive` — ranked passive nodes
- `vb.notable` — notable nodes
- `vb.keystone` — hybrid keystones
- `vb.capstone` — grand capstones
- `vb.law` — Breach Laws
- `vb.item` — class items
- `vb.distortion` — legendary rules
- `vb.event` — combat-event IDs
- `vb.ai` — AI reaction IDs

Rules:

- Never rename an ID after public save files exist.
- Change display names through localization, not ID replacement.
- If behavior is completely replaced, deprecate the old ID and migrate it.
- Save selected branches by ID, never by array index.
- Telemetry records IDs, not translated names.

---

# 4. Approved ability IDs

## Dedicated class action

- `vb.action.closure`

## Foundation

- `vb.skill.mass_brand`
- `vb.skill.null_shard`
- `vb.skill.worldshear`
- `vb.skill.event_step`
- `vb.skill.hard_vacuum`

## Event Horizon

- `vb.skill.convergence`
- `vb.skill.crush_point`
- `vb.skill.tidal_lock`
- `vb.skill.black_meridian`
- `vb.skill.accretion_field`

## Redshift

- `vb.skill.velocity_theft`
- `vb.skill.periapsis`
- `vb.skill.rail_collapse`
- `vb.skill.trajectory_theft`
- `vb.skill.vector_salvo`

## Hollow Form

- `vb.skill.gravitic_skin`
- `vb.skill.mass_driver`
- `vb.skill.countermass`
- `vb.skill.zero_range_collapse`
- `vb.skill.gravitic_clamp`

## Ultimate

- `vb.ultimate.dead_star`

Every skill mutation and apex uses a child ID, for example:

- `vb.skill.mass_brand.carrier_brand`
- `vb.skill.mass_brand.grave_relay`
- `vb.skill.mass_brand.world_nail`
- `vb.skill.mass_brand.foundation_theft`

---

# 5. Runtime ownership

## VoidbringerController

Owns:

- Selected Breach Law
- Aggregate class statistics
- Active rule flags from passives and items
- High-level skill requests
- Closure orchestration
- Compatibility adapter to the playable-character contract

Does not own:

- Physics movement
- Status ticking
- Animation playback
- VFX spawning
- AI decisions

## AnchorManager

Owns:

- Anchor IDs
- Anchor carriers
- Carrier types
- Mass values
- Mass stages
- Durations
- Capacity replacement
- Anchor metadata
- Anchor creation and removal events

## FoldLineManager

Owns:

- Valid pairs of anchors
- Fold Line IDs
- Line length
- Line direction
- Mass difference
- Tension
- Line intersections
- Closed geometry
- Segment-crossing queries
- Temporary impossible lines

Does not apply force or damage.

## InstabilityController

Owns:

- Current Instability
- Breach entry
- Breach duration
- Closure extensions
- Clean Closure validation
- Spatial Recoil
- Out-of-combat decay

## ForceResolver

Owns the conversion contract between requested force and enemy response:

- Translation
- Rotation
- Stance damage
- Armor stress
- Internal Mass
- Anchor loading

It returns a result. Enemy locomotion and animation controllers apply that result.

## StatusController

Shared combat service owning:

- Status stacks
- Source ownership
- Duration
- Decay
- Dispel rules
- Periodic effects
- Serialization

## OrbitController

Required service owning:

- Orbit carrier
- Orbit radius
- Angular speed
- Completed revolutions
- Capacity
- Release rules
- Resistance escalation
- Captured-object ownership

## CombatEventBus

Publishes gameplay facts to:

- VFX
- Audio
- HUD
- Camera
- AI
- Tutorials
- Telemetry
- Achievements

Presentation systems may listen to combat. They must not decide combat.

---

# 6. Data-resource structure

Godot custom Resources should define editor-friendly immutable content.

## AbilityDefinition

Stores:

- Stable ID
- Display name
- Description
- Slot type
- Discipline
- Unlock level
- Cooldown
- Charge count
- Recharge
- Instability delta
- Cast time
- Recovery time
- Targeting profile
- Animation profile
- Tags
- Base effects
- Common refinement
- Mutation branches
- Metadata

## AbilityUpgrade

Stores:

- Upgrade ID
- Display name
- Description
- Exclusive branch group
- Prerequisites
- Added tags
- Removed tags
- Added effects
- Scalar overrides
- Rule flags

## EffectSpec

Supports modular effects such as:

- Damage
- Apply status
- Remove status
- Add Mass
- Remove Mass
- Add Instability
- Remove Instability
- Apply force
- Move actor
- Create anchor
- Collapse anchor
- Create Fold Line
- Create field
- Spawn projectile
- Capture projectile
- Orbit object
- Modify cooldown
- Grant barrier
- Emit combat event

## StatusDefinition

Stores:

- Stable status ID
- Display name
- Description
- Stack model
- Maximum stacks
- Duration rule
- Base duration
- Dispel behavior
- Tags
- Periodic effects
- Metadata

## PassiveDefinition

Supports:

- Minor passives
- Notables
- Keystones
- Capstones
- Bridge nodes
- Breach Laws
- Law mutations
- Law apexes

Stores:

- Stable ID
- Discipline
- Rank limit
- Point cost
- Unlock level
- Prerequisites
- Required discipline points
- Exclusive group
- Modifiers per rank
- Rule flags

---

# 7. Ability lifecycle

Every cast follows the same states:

1. `requested`
2. `validated`
3. `started`
4. `committed`
5. `resolved`
6. `recovery`
7. `completed`

Possible exits:

- `rejected`
- `cancelled_pre_commit`
- `cancelled_post_commit`
- `interrupted`
- `target_lost`
- `owner_disabled`

## Validation

Checks:

- Skill unlocked
- Skill equipped
- Cooldown or charge available
- Valid target type
- Valid range
- Required anchors or Fold Lines
- Movement state
- Current rule flags
- Resource consequences
- Multiplayer authority

## Commit event

At commit:

- Charge is consumed
- Instability is generated
- Cooldown liability begins
- Target snapshot is recorded when required
- Animation may no longer cancel for free

## Resolve event

At resolve:

- Hitboxes spawn
- Projectiles launch
- Anchor is placed
- Force is requested
- Closure executes
- Field begins
- Status is applied

A skill may contain several resolve events.

## Recovery

Recovery controls input buffering and cancel permissions. It does not delay server-authoritative damage that has already resolved.

---

# 8. Animation event contract

Animation method tracks use stable event names:

- `commit`
- `resolve_primary`
- `resolve_secondary`
- `movement_start`
- `movement_arrive`
- `hitbox_on`
- `hitbox_off`
- `capture_open`
- `capture_close`
- `counter_open`
- `counter_perfect_close`
- `orbit_release`
- `closure_absence`
- `recovery_start`
- `complete`

Prototype timing targets may move during combat testing, but event order is contractual.

Animation is presentation and timing authority for local feel. It does not directly calculate final damage or force.

---

# 9. Formula order

All damage uses this order:

1. Base source statistic
2. Ability coefficient
3. Additive category total
4. Ordered multiplicative modifiers
5. Critical or weak-point multiplier
6. Target mitigation
7. Encounter-specific conversion
8. Final clamping and rounding

Do not add every percentage to one bucket.

Recommended modifier categories:

- `damage.all`
- `damage.spatial`
- `damage.melee`
- `damage.projectile`
- `damage.collision`
- `damage.fold_line`
- `damage.collapse`
- `damage.high_instability`
- `damage.personal_mass`
- `damage.orbit_release`
- `damage.target_moving`
- `damage.target_anchored`

Only one modifier from a named exclusive family applies unless a rule explicitly permits stacking.

---

# 10. Collision formula

Prototype formula:

`collision = 0.5 × reduced_mass × relative_velocity² × impact_scalar × diminishing`

Where:

`reduced_mass = (source_mass × target_mass) / (source_mass + target_mass)`

This produces the intended behavior:

- A heavy body striking a light body still hurts.
- Two heavy bodies produce the largest impact.
- Velocity matters strongly.
- Repeated pinball loops can be diminished.
- Bosses can convert excess force without being launched.

The player-facing game does not expose literal kilograms. Effective Mass is a tuned combat statistic.

Recommended repeated-collision scaling within the protection window:

- First collision: 100%
- Second: 70%
- Third: 45%
- Additional: 25%

Control and movement remain useful after damage diminishes.

---

# 11. Force conversion contract

Every force request includes:

- Direction
- Desired distance
- Force strength
- Force mode
- Source ability
- Source anchor
- Collision permission
- Terrain permission
- Orbit permission
- Boss conversion profile

Every target provides:

- Weight class
- Displacement resistance
- Rotational resistance
- Stance integrity
- Armor conversion
- Internal Mass conversion
- Anchor-Mass conversion
- Translation permission
- Region hit

If translation is resisted, unused force converts in this order:

1. Rotation
2. Stance damage
3. Armor stress
4. Internal Mass
5. Anchor Mass

No enemy returns a bare `immune` result.

---

# 12. Anchor contract

Base anchor capacity: 3

Base durations:

- Enemy: 12 seconds
- Terrain: 18 seconds
- Corpse: 8 seconds

Base Mass stages:

- Dormant: 0–34
- Dense: 35–69
- Critical: 70–100

Every anchor records:

- Stable integer ID
- Owner
- Carrier
- Carrier type
- Body region or local offset
- Mass
- Maximum Mass
- Expiration
- Orbit inventory
- Failure Stacks
- Anchor Stress
- Item and passive metadata

Supported carrier types:

- Enemy
- Terrain
- Corpse
- Self
- Projectile
- Orbit
- Vacancy

Anchor changes emit events. HUD, AI and FoldLineManager should not poll the complete system every frame when an event-driven update is available.

---

# 13. Fold Line contract

A line exists when:

- Two valid anchors belong to the same Voidbringer
- Neither blocks automatic connection
- The selected geometry rule permits the pair

Every line records:

- Line ID
- Endpoint IDs
- Length
- Normalized direction
- Mass difference
- Tension
- Active Meridian state
- Transit permissions
- Damage cooldown per target
- Intersections
- Closed-geometry ownership

Required queries:

- Nearest line to a point
- Lines crossed by a segment
- Point inside closed three-anchor geometry
- Line intersection points
- Longest line
- Highest-tension line
- Path from anchor A to anchor B
- Projected line after anchor movement

## Standard connection mode

At normal three-anchor capacity:

- One anchor: no line
- Two anchors: one line
- Three anchors: three lines and a possible closed triangle

Build-changing items may switch to manual or alternative connection modes.

## Closed geometry

Standard closed geometry requires:

- Exactly three active anchors
- All three pair connections
- Minimum non-zero triangle area

The manager emits a state-change event when the structure opens or closes.

---

# 14. Instability and Breach contract

Base range: 0–100.

At 100:

- Automatic Breach begins unless a rule enables manual activation.

Base Breach duration: 8 seconds.

Closure extension:

- Dormant: 0.4 seconds
- Dense: 0.8 seconds
- Critical: 1.3 seconds

Maximum added time: 8 seconds.

Clean Closure requires:

- At least two Dense-or-higher Closures during the current Breach
- Zero Critical anchors when it ends
- Player not incapacitated

Spatial Recoil:

- Four-second base duration
- Event Step range reduction
- Movement reduction
- Increased Instability generation
- Remaining anchor Mass loss

The Instability Controller publishes state. Skills query it but never edit internal timers directly.

---

# 15. Status semantics

Approved status IDs include:

- `vb.status.anchored`
- `vb.status.anchor_stress`
- `vb.status.compressed`
- `vb.status.orbiting`
- `vb.status.velocity_reserve`
- `vb.status.personal_mass`
- `vb.status.breach`
- `vb.status.clean_closure_ready`
- `vb.status.spatial_recoil`
- `vb.status.divided`
- `vb.status.tidal_lock`
- `vb.status.grounding_pressure`
- `vb.status.unclosed_space`
- `vb.status.failure_stack`
- `vb.status.internal_mass`

## Anchored

Not a normal debuff. It is a view of an AnchorManager-owned relationship.

A normal cleanse may reduce Mass or stress the anchor, but cannot erase it without a specific rule.

## Compressed

Short control state indicating active spatial reduction. Used by damage bonuses and hit reactions.

## Orbiting

Owned by the orbit controller. Removing the status without ending the controller is illegal.

## Velocity Reserve

Scalar pool from 0–100. Consumed by compatible movement, impact or projectile events.

## Personal Mass

Scalar pool from 0–100. Alters movement, Impact, defense and self-anchor behavior.

## Breach

Resource-driven state owned only by InstabilityController.

## Spatial Recoil

Timed penalty. Cannot be normally dispelled.

## Divided

Three-stack execution setup for Black Meridian.

## Grounding Pressure

Scalar pool for flying targets. At 100, emits a grounding request to the enemy controller.

## Unclosed Space

Spatial wound applied by Worldshear or Black Meridian. Regeneration performed while active can create malformed Mass rather than simple healing.

---

# 16. Tags

Core tags:

- `anchor`
- `mass`
- `closure`
- `collapse`
- `fold`
- `geometry`
- `movement`
- `momentum`
- `force`
- `collision`
- `projectile`
- `orbit`
- `counter`
- `defense`
- `melee`
- `personal_mass`
- `self_anchor`
- `corpse`
- `terrain`
- `spatial_shear`
- `armor_break`
- `grab`
- `ultimate`
- `breach`

Tags serve:

- Modifier matching
- UI search
- AI awareness
- Telemetry
- Item-affix legality

Tags do not implement behavior by themselves.

---

# 17. AI hooks

Enemies receive a compact `SpatialThreatSnapshot`.

Suggested fields:

- Anchored
- Anchor Mass stage
- Anchor Stress
- Distance to nearest anchor
- Number of Dense anchors nearby
- Number of Critical anchors nearby
- Inside closed geometry
- Distance to dangerous Fold Line
- Current pull vector
- Current orbit threat
- Projected Closure radius
- Voidbringer Instability tier
- Voidbringer currently in Breach
- Active Breach Law

AI reactions are capabilities, not universal behavior:

- Leave geometry
- Attack terrain anchor
- Stress own anchor
- Fake movement
- Consume Mass
- Break line of sight
- Switch projectile pattern
- Pressure Voidbringer during Breach
- Delay phase until Closure
- Use player pull to reposition intentionally

Difficulty increases awareness and decision quality, not immunity.

---

# 18. Presentation event payloads

## Anchor created

Must include:

- Anchor ID
- Carrier type
- World position
- Body region
- Starting Mass
- Duration
- Owner color signature

## Anchor stage changed

Must include:

- Old stage
- New stage
- Mass percentage
- Carrier velocity
- Breach Law

## Force resolved

Must include:

- Requested distance
- Actual distance
- Rotation
- Stance damage
- Armor stress
- Internal Mass
- Anchor Mass
- Collision prediction

## Closure

Must include:

- Carrier type
- Mass
- Stage
- Damage
- Radius
- Force mode
- Released projectiles
- Breach extension
- Clean Closure projection

## Breach

Must include:

- Law
- Duration
- Critical anchor count
- Selected rule flags
- Current presentation-intensity setting

---

# 19. Combat event bus

The shared event bus publishes:

- Ability started
- Ability committed
- Ability resolved
- Ability cancelled
- Damage resolved
- Force resolved
- Collision resolved
- Anchor created
- Anchor Mass changed
- Anchor stage changed
- Anchor collapsed
- Fold Line created
- Fold Line removed
- Instability changed
- Breach started
- Breach extended
- Breach ended
- Spatial Recoil started
- AI spatial threat changed

This prevents one giant character script from controlling combat, UI, VFX, sound and AI.

---

# 20. Multiplayer authority

Server or host owns:

- Anchor creation
- Anchor IDs
- Anchor Mass
- Closure
- Fold Line validity
- Projectile capture
- Orbit state
- Forced movement results
- Instability
- Breach
- Damage
- Clean Closure

Client predicts:

- Cast animation
- Aiming
- Simple Mass Brand projectile
- Event Step presentation
- HUD previews

Client may never authoritatively decide:

- Enemy launch
- Boss rotation
- Clean Closure
- Captured projectile ownership
- Collision damage

Anchor IDs are server-issued and replicated.

---

# 21. Save data

Save only choices and persistent progression:

- Unlocked skill IDs
- Selected skill IDs
- Selected mutation IDs
- Passive ranks by ID
- Active capstone ID
- Active Breach Law ID
- Selected Law mutation and apex
- Equipped item instance IDs
- Loadout names
- Manifold Trial completion

Do not save temporary combat data:

- Anchors
- Instability
- Orbit inventory
- Breach timer
- Current Velocity Reserve

Schema migrations map deprecated IDs.

Initial migration must continue accepting `void_warlock` as a compatibility class ID.

---

# 22. Telemetry events

Recommended events:

- `vb.cast`
- `vb.anchor.created`
- `vb.anchor.stage_changed`
- `vb.anchor.collapsed`
- `vb.fold.crossed`
- `vb.collision`
- `vb.breach.started`
- `vb.breach.clean_closed`
- `vb.breach.recoil`
- `vb.projectile.captured`
- `vb.orbit.released`
- `vb.dead_star.detonated`
- `vb.player.death`

Useful fields:

- Ability ID
- Build hash
- Level
- Encounter ID
- Enemy family
- Anchor carrier
- Mass
- Instability
- Law
- Result
- Time since previous cast

Never log player-readable names as primary keys.

---

# 23. Automated validation

Catalog validation fails on:

- Duplicate IDs
- Empty IDs
- Invalid unlock levels
- Active skill without exactly two branches
- Ultimate without three manifestations
- Branch missing apex
- Prerequisite cycle
- Unknown tag
- Unknown status
- Cooldown below zero
- Ability with no animation profile
- Capstone without discipline requirement
- Conflicting exclusive groups
- Loadout exceeding six active skills

Combat tests cover:

- Anchor replacement
- Carrier death
- Carrier teleport
- Phase transition
- Three-anchor geometry
- Clean Closure
- Failed Closure
- Repeated-collision diminishing
- Boss force conversion
- Projectile recapture prevention
- Orbit expiration
- Multiplayer anchor ownership

Godot validation must include:

```bash
godot --headless --path . --editor --quit
timeout 20s godot --headless --path .
```

The package self-test, once imported, should also run headlessly.

---

# 24. Prototype milestones

## Milestone A — Anchor sandbox

Implement:

- Mass Brand
- Closure
- Three anchor carriers
- Mass stages
- Simple Fold Lines
- Instability
- One dummy with movement resistance

Success:

The player can create, load and collapse anchors with readable feedback.

## Milestone B — Physical combat

Implement:

- Event Step
- Worldshear
- Convergence
- Collision damage
- Terrain collision
- Boss force conversion

Success:

Light, heavy and immovable targets all respond differently but meaningfully.

## Milestone C — Breach

Implement:

- Automatic Breach
- Law of Compression
- Closure extension
- Clean Closure
- Spatial Recoil

Success:

Players intentionally approach 100 Instability and understand success versus failure without a tutorial popup.

## Milestone D — Build fork

Implement one skill from each discipline:

- Convergence
- Velocity Theft
- Gravitic Skin

Success:

Three builds already feel different while sharing the same base class.

## Milestone E — Loot rule

Implement one transformative Distortion:

- The Last Orbit or Grave of Distance

Success:

Equipment changes the class’s physical logic without editing every ability script.

---

# 25. Definition of done for one ability

An ability is not complete until it has:

- Stable ID
- Data resource
- Input validation
- Target profile
- Animation profile
- Commit event
- Resolve events
- Recovery and cancel rules
- Formula tests
- Status interactions
- Anchor interactions
- Breach interaction
- Boss conversion
- AI threat output
- VFX and audio event payload
- HUD tooltip data
- Multiplayer authority
- Telemetry
- Accessibility behavior
- Three enemy-family tests
- One boss test

---

# 26. Architecture non-negotiable

The implementation must preserve the design truth:

> **Every skill changes a physical relationship.**

A Voidbringer ability that only deals damage and has no relationship to Mass, momentum, geometry, position, collision, Closure or Breach does not belong in the class.