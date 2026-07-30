# ABYSSFALL — VOIDBRINGER BALANCE AND TEST MATRIX

Status: Approved foundation  
Codex version: 1.0  
Implementation status: Test contract approved; numerical tuning provisional  
Last updated: 2026-07-22  
Canonical class ID: `voidbringer`

---

# 1. Purpose

This document separates approved mechanical relationships from provisional numbers.

The following are approved design truths:

- Anchor → Load → Bend → Collapse is the class loop.
- Instability is generated rather than spent like mana.
- Breach becomes an intentional mastery state.
- Three normal anchors form the standard network.
- Fold Lines create advanced geometry without requiring manual drawing.
- Resisted movement converts into consequence rather than immunity.
- Collision, projectile, Fold Line, Collapse and melee builds use partially separate scaling.
- Builds change behavior, not merely output.

The exact coefficients remain subject to playtesting.

A numerical change that preserves these relationships does not require a major Codex version increase. A behavioral change does.

---

# 2. Prototype constants

## Core progression

- Core level cap: 50
- Level-earned Void Points: 49
- Manifold Trial points: 8
- Maximum core-tree points: 57
- Configurable active slots: 6
- Dedicated Closure slot: 1
- Ultimate slot: 1
- Active-skill maximum investment: 4 points
- One active Grand Capstone

## Mass Anchors

- Normal maximum: 3
- Enemy duration: 12 seconds
- Terrain duration: 18 seconds
- Corpse duration: 8 seconds
- Standard Mass range: 0–100
- Dormant: 0–34
- Dense: 35–69
- Critical: 70–100

## Standard Mass gains

- Normal enemy death near anchor: +8
- Elite death near anchor: +20
- Boss phase event near anchor: +25
- Enemy collision: +4 to +18 based on size and velocity
- Projectile Fold Line crossing: +2 to each endpoint
- Event Step between anchors: +6 to each endpoint
- Heavy melee impact: +8
- Perfect Countermass: +10 to attacker anchor
- Forced movement toward anchor: +1 per meter, maximum +12 per event

## Instability and Breach

- Instability range: 0–100
- Out-of-combat decay delay: 4 seconds without spatial action
- Out-of-combat decay: 5 per second
- Automatic Breach threshold: 100
- Base Breach duration: 8 seconds
- Base anchor influence increase during Breach: 30%
- Maximum Closure-added Breach duration: 8 seconds

Closure extension:

- Dormant: 0.4 seconds
- Dense: 0.8 seconds
- Critical: 1.3 seconds

Clean Closure baseline reward:

- Barrier: 12% maximum health
- Mass Brand recharge increase: 20% for 6 seconds
- No Spatial Recoil
- Breach-Law-specific reward

Spatial Recoil baseline:

- Duration: 4 seconds
- Event Step range: -40%
- Movement speed: -15%
- Instability generation: +20%
- Remaining anchor Mass: -30

## Closure

- Cooldown: 0.7 seconds
- Dormant Instability removal: 7
- Dense Instability removal: 13
- Critical Instability removal: 21
- Dormant coefficient: 45% Weapon Power
- Dense coefficient: 105% Weapon Power
- Critical coefficient: 190% Weapon Power

These values are prototype targets, not guaranteed ship values.

---

# 3. Damage-category separation

The following categories must not collapse into one universal multiplier:

- Direct melee
- Direct projectile
- Collision
- Fold Line
- Collapse
- Orbit release
- Personal Mass
- High Instability
- Counterforce
- Dead Star

A general spatial-damage statistic may provide broad value, but specialized statistics must outperform it within their own builds.

## Protection goal

A mathematically optimal generic item should not simultaneously be best for:

- Black Sun Architect
- Orbital Executioner
- Living Singularity
- Kinetic Butcher
- One Final Point
- Mass-Body Artillery

If one affix combination dominates all six, the scaling pools are too connected.

---

# 4. Resource-goal diversity

Different viable builds should prefer different Instability behavior.

## Low-Instability builds

Prefer:

- Stable Core
- Reliable Clean Closure
- Defensive barriers
- Deliberate setup

## High-Instability builds

Prefer:

- Damage above 80–90 Instability
- Rapid Breach entry
- Redline effects
- Open or Overclocked containment

## Frequent short-Breach builds

Prefer:

- Rapid setup
- Fast Clean Closure
- Repeated Law rewards

## Extended-Breach builds

Prefer:

- Multiple Dense or Critical Closures
- Eventide-style resets
- Recirculating Mass

## Failed-Breach builds

Prefer:

- Inverted Core
- Recoverable Spatial Recoil
- Offense during failure states

## Rare deliberate-Breach builds

Prefer:

- Manual activation
- Large stored anchor networks
- Boss vulnerability windows

No one Containment Core should dominate every resource goal.

---

# 5. Build validation targets

At level 50, each approved build must demonstrate a distinct answer to these questions:

- How are anchors created?
- How are anchors loaded?
- How are enemies repositioned?
- How is Instability managed?
- What is the main payoff?
- What does Breach change?
- What defensive tool is used?
- What happens against a boss that resists movement?

## Black Sun Architect

Must be strongest through:

- Stable geometry
- Closed-area pressure
- Ordered Collapse
- Corpse and movement feeding

Must not become fastest at immediate single-target burst without setup.

## Orbital Executioner

Must be strongest through:

- Orbit preparation
- Projectile capture
- Fold Line acceleration
- Timed release

Must still function against enemies with few projectiles through Null Shards and generated ammunition.

## Living Singularity

Must be strongest through:

- Personal Mass
- Point-blank control
- Counterforce
- Self-anchor Closure

Must remain mobile through Event Step without becoming a normal fast tank.

## Kinetic Butcher

Must be strongest through:

- Relative velocity
- Movement sequencing
- Echo attacks
- Stored momentum

Immobilization should hurt without making the character nonfunctional.

## One Final Point

Must be strongest through:

- Long-term investment into one anchor
- High-risk timing
- Concentrated boss payoff

It must have meaningful early-spend decisions and should not always wait for maximum Mass.

## Mass-Body Artillery

Must be strongest through:

- Enemy composition knowledge
- Living ammunition
- Collision vectors
- Body and terrain selection

Boss encounters must supply projected Mass, adds, armor pieces or regional shock behavior so the build remains valid.

---

# 6. Beginner usability targets

Within the first hour, a new player should successfully perform:

- Mass Brand on an enemy
- Mass Brand on terrain
- Closure on both carrier types
- Two-enemy collision
- One Fold Line interaction
- Event Step to an anchor
- One uncontrolled Breach
- One Clean Closure

The player should understand the basic class without needing:

- Exact internal Mass numbers
- A community guide
- Manual line drawing
- More than the default six-slot loadout
- Advanced itemization

## Warning signs

- More than 20% of first-time players cannot identify which button performs Closure.
- Players treat Instability as a mana bar they must keep low at all times.
- Players do not notice the difference between Dormant, Dense and Critical anchors.
- Players cannot predict which anchor tap-Closure will select.
- Event Step is perceived as a generic teleport.

---

# 7. Mastery targets

At high skill, players should visibly demonstrate:

- Deliberate anchor carrier selection
- Planned Closure order
- Geometry changes during attacks
- Projectile capture prioritization
- Movement converted into damage
- Defensive force converted into offense
- Intentional Breach timing
- Clean Closure under pressure
- Boss-region targeting
- Situation-specific use of the same skill

The class is too shallow if mastery only increases damage uptime.

The class is too opaque if expert actions are impossible to understand when observed in slowed footage or through clear HUD cues.

---

# 8. Enemy response matrix

Every enemy family must pass:

## Anchor test

Can the enemy be anchored meaningfully?

## Force test

Does pull or repulsion produce a visible and useful response?

## Collision test

Can the enemy participate directly or through converted force?

## Orbit test

Does orbit have a valid translation?

## Fold Line test

Can the enemy cross, bend, disrupt or be affected by lines?

## Closure test

Does Collapse provide meaningful payoff?

## Breach test

Does each Breach Law create an interesting interaction?

## Counterplay test

Can the enemy challenge setup without switching the class off?

An enemy failing several tests should be redesigned.

---

# 9. Boss conversion expectations

Boss testing must include:

- Full-body movement when appropriate
- Partial movement
- Rotation
- Stance damage
- Armor stress
- Limb reaction
- Attack redirection
- Projectile redirection
- Arena movement
- Internal Mass
- Anchor loading

A boss interaction is not considered successful when the damage number appears but the boss visually ignores the force.

## Boss prohibition

Do not ship broad statuses such as:

- Immune to Pull
- Immune to Anchor
- Immune to Orbit
- Immune to Collision
- Immune to Displacement

Specific phase mechanics may temporarily restrict a response channel, but unused force must convert into another meaningful channel.

---

# 10. Collision protections

## Repeated collision diminishing

Suggested same-source protection window:

- First collision: 100%
- Second: 70%
- Third: 45%
- Additional: 25%

Movement, interruption and positioning may continue after damage diminishes.

## Infinite-loop checks

Test:

- Two walls
- Concave corners
- Multiple anchors
- Tidal Lock plus Convergence
- Dead Star plus living rounds
- Multiplayer overlapping pulls

No enemy should generate unlimited damage, Mass, Instability removal or cooldown reduction through a stable loop.

---

# 11. Orbit protections

Test:

- Normal orbit duration
- Resistance escalation
- Boss path translation
- Projectile capacity
- Enemy capacity
- Release timing
- Anchor replacement
- Carrier death
- Phase transition
- Camera-near visual compression

Captured and reflected projectiles cannot be recaptured indefinitely by the same player.

A boss cannot be permanently prevented from acting through repeated Tidal Lock.

---

# 12. Fold Line and geometry tests

Required geometry tests:

- One anchor creates no line.
- Two anchors create one line.
- Three compatible anchors create three lines.
- Collinear anchors do not count as meaningful closed geometry.
- Moving anchors update lines without one-frame origin errors.
- Anchor replacement removes stale lines.
- Carrier death preserves or transfers lines according to upgrade rules.
- Event Step detects crossed lines.
- Worldshear detects crossed lines.
- Black Meridian retains valid moving endpoints.
- Closed-geometry point tests work at edges and corners.
- Vertical anchor arrangements use the intended projected plane or full 3D rule.

Performance tests must include build-changing effects that exceed the normal three-anchor limit.

---

# 13. Anchor lifecycle tests

Test every carrier type:

- Enemy
- Terrain
- Corpse
- Self
- Projectile
- Orbit
- Vacancy

Test lifecycle events:

- Create
- Load
- Stage transition
- Move
- Transfer
- Carrier death
- Carrier teleport
- Carrier split
- Carrier regeneration
- Phase transition
- Expire
- Replace
- Collapse
- Cleanse stress
- Parasite attachment

No stale anchor reference may survive carrier deletion.

No replacement should briefly create invalid origin geometry.

---

# 14. Breach verification

Required cases:

- Automatic entry at threshold
- Manual entry through item rule
- Closure during Breach
- Maximum extension cap
- Two Dense Closures and no Critical remaining
- Critical anchor remaining at end
- Player incapacitated during end
- Emergency Closure notable
- Breach Law change outside combat
- Law mutation
- Law apex
- Dead Star active during Breach
- Multiplayer replication

## Warning signs

### Too easy

- Clean Closure rate above 90% without specialization
- Spatial Recoil almost never occurs
- Players ignore anchor state because Closure order never matters

### Too punishing

- One failed Breach creates repeated death spirals
- Players intentionally avoid using abilities to prevent Breach
- Spatial Recoil prevents recovery or learning
- Clean Closure requires UI calculation instead of readable combat cues

---

# 15. Anchor Command tests

Controller tests must include:

- Tap priority
- Reticle priority
- Locked-target priority
- Critical enemy priority
- Critical terrain priority
- Oldest-anchor fallback
- Directional cycling
- Rapid release
- Solo slowdown
- Multiplayer no-slowdown mode
- Accessibility hold duration
- Simplified targeting

Targets must never change after commitment without a clearly defined retarget rule.

Measure:

- Average selection time
- Wrong-anchor rate
- Player deaths while selecting
- Closure cancellation rate

More than 30% lost or wrong Closure attempts indicates a serious targeting problem.

---

# 16. Frame combat tests

Every Manifold Frame requires:

- Basic chain
- Held attack
- Moving attack
- Evade attack
- Closure follow-up
- Breach variation
- Animation-event timings
- Controller buffering
- Keyboard/mouse aiming
- Hit reaction profile

Each Frame must change moment-to-moment rhythm, not only statistics.

A player should identify the Frame family by watching combat without opening the equipment screen.

---

# 17. Itemization tests

## Distortion modularity

A Primary Distortion must alter shared rules rather than patching every skill independently.

Test Primary Distortions against:

- All compatible abilities
- All carrier types
- Each Breach Law
- Boss force conversion
- Dead Star
- Respec and unequip
- Save and load
- Multiplayer replication

## Tradeoff verification

Every build-defining effect must remove or weaken something meaningful.

Reject effects that provide a new mechanic plus unconditional best-in-slot output with no cost.

## Unique competitiveness

For every Unique:

- Compare against an ideal Rare
- Compare against an ideal Legendary
- Verify the Unique creates a playstyle
- Verify it is not mandatory for every build using the named skill

---

# 18. Accessibility tests

Validate at minimum:

- Distortion intensity at minimum and maximum
- Screen shake disabled
- FOV changes disabled
- Hitstop reduced
- Static Event Step camera
- Breach flicker reduction
- Reduced afterimages
- Simplified orbit trails
- High-contrast anchors
- Adjustable Fold Line thickness
- Pattern-based Mass stages
- Reduced low-frequency pressure
- Separate warning volumes
- Colorblind-independent Critical state
- Simplified Anchor Command

Reducing effects must not remove required gameplay information.

---

# 19. Enemy telegraph protection tests

Test every major class effect over:

- Unblockable attacks
- Ground danger zones
- Boss weak points
- Projectile lanes
- Grab telegraphs
- Aerial dive markers

Rules:

- Fold Lines become translucent over major telegraphs.
- Dead Star cannot hide danger indicators.
- Black Meridian thins where necessary.
- Orbiting visuals group near camera.
- Distortion never removes required warning shape or pattern.

A powerful visual identity does not excuse unfair readability.

---

# 20. Multiplayer tests

Validate:

- Server-issued anchor IDs
- Owner-specific anchor signatures
- Anchor Mass replication
- Fold Line replication
- Closure authority
- Projectile capture ownership
- Orbit ownership
- Enemy force authority
- Collision damage authority
- Breach timing
- Clean Closure
- Multiple Voidbringers
- Intersecting Fold Lines
- Ally displacement consent
- Build loadout replication

Other players may see important public state without receiving private tactical UI.

Two Voidbringers should not accidentally collapse or steal each other’s anchors unless a future cooperative rule explicitly allows it.

---

# 21. Performance budgets

Baseline per Voidbringer:

- Three standard anchors
- Three standard Fold Lines
- Three active spatial seams
- One Accretion Field
- One Dead Star
- Eight standard captured hostile projectiles before visual compression
- Four simultaneous normal orbiting enemies

Additional objects may use combined visual and physics representations.

Performance profiling must include:

- Four-player co-op
- Multiple Voidbringers
- Corpse Geometry
- Common Grave Engine
- Temporary excess anchors
- Projectile-heavy bosses
- Dead Star plus swarms
- Large moving terrain

Do not optimize by silently deleting approved interactions. Use aggregation, fixed update rates, pooled nodes and event-driven state.

---

# 22. Telemetry requirements

Record:

- Average anchor uptime
- Average Mass at Closure
- Carrier-type selection rate
- Breach frequency
- Breach duration
- Clean Closure rate
- Spatial Recoil rate
- Enemy displacement distance
- Force converted to rotation
- Force converted to stance
- Force converted to armor stress
- Boss interaction resistance
- Projectile capture rate
- Orbit duration
- Orbit release result
- Anchor Command selection time
- Deaths during Anchor Command
- Ability usage by enemy family
- Build and capstone distribution
- Item Distortion usage

Use stable IDs.

Do not use translated names as primary telemetry keys.

---

# 23. Important warning signs

## Too strong

- One anchor carrier type is always optimal.
- One Breach Law dominates every build.
- Boss stance is permanently suppressed.
- Projectile phases are fully neutralized.
- Swarms die before participating in Mass decisions.
- Generic spatial damage scales every build best.
- One Containment Core dominates low and high Instability.
- One Unique becomes mandatory across disciplines.

## Too weak or frustrating

- Bosses visually ignore abilities.
- Teleporters regularly erase anchors.
- Flying enemies cannot be engaged meaningfully.
- Anchor Command is too slow under pressure.
- Players avoid Breach.
- Spatial Recoil creates death spirals.
- Geometry builds require ideal empty rooms.
- Projectile builds fail completely without hostile projectiles.
- Hollow Form cannot recover mobility.
- Collision builds fail against bosses with no adds or breakable structures.

---

# 24. Regression checklist for every ability

An ability change must verify:

- Stable ID unchanged or migration provided
- Unlock level
- Point cost
- Target validation
- Commit timing
- Resolve timing
- Cancellation behavior
- Instability delta
- Anchor behavior
- Fold Line behavior
- Mass generation or consumption
- Breach behavior
- Boss conversion
- Enemy-family response
- VFX payload
- Audio payload
- HUD tooltip
- Accessibility
- Multiplayer authority
- Telemetry
- Cleanup on death, phase transition and scene exit

---

# 25. Playable foundation milestone

The first integrated Voidbringer room should contain:

- Transitional playable character satisfying the current character contract
- Mass Brand
- Closure
- Three visible anchor stages
- Fold Lines
- Instability debug display
- One light enemy
- One heavy enemy
- One stationary boss dummy

Success requires:

- All three targets are meaningfully affected.
- The light target moves substantially.
- The heavy target moves less and takes stance consequence.
- The stationary target converts force into structural or stance response.
- No target displays blanket immunity.
- Anchor selection is reliable.
- Closure is satisfying before advanced VFX are added.
- Godot headless import and runtime are clean.

---

# 26. Final completion standard

Voidbringer is ready for full production only when:

- A new player understands Mass Brand and Closure without a guide.
- Each discipline has a distinct playable loop.
- Hybrid builds are genuinely supported.
- Every major enemy family passes the interaction matrix.
- Bosses convert force visibly.
- Breach is intentionally pursued by skilled players.
- Itemization changes behavior.
- Controls work on controller and keyboard/mouse.
- Effects preserve telegraph readability.
- Accessibility settings retain information.
- Multiplayer authority is deterministic.
- Performance budgets survive real encounter stress.
- Automated tests and headless Godot validation pass.
- Independent verification confirms the exact reviewed artifact.

The verification principle is:

> **The class is not complete because its abilities exist. It is complete when every system consistently preserves the fantasy of chosen physical consequence.**