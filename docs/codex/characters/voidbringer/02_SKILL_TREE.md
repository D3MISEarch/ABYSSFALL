# ABYSSFALL — VOIDBRINGER IMPLEMENTATION BIBLE
## Complete Level 1–50 Skill Tree, Active Skills, Passives, Keystones and Capstones

Status: Approved  
Codex version: 1.0  
Implementation status: Design approved  
Last updated: 2026-07-22  
Canonical class ID: `voidbringer`

---

# 1. Progression framework

## Core level cap

The Voidbringer’s primary class tree runs from **level 1 through level 50**.

Post-level-50 progression should exist in a separate endgame system so the class tree remains readable and foundational builds are complete before endgame amplification begins.

## Void Point economy

The player receives:

- One Void Point at every level from 2–50: **49 points**
- One bonus point from each of eight Manifold Trials: **8 points**
- Maximum core-tree total: **57 Void Points**

The eight Manifold Trials occur around levels:

- 8
- 14
- 20
- 26
- 32
- 38
- 44
- 50

These are class-specific encounters teaching advanced mechanics such as anchor geometry, projectile redirection and controlled Breach resolution.

## Combat loadout

The Voidbringer has:

- Six configurable active-skill slots
- One dedicated **Closure** class-mechanic button
- One universal evade
- One weapon basic attack determined by the equipped Manifold Frame
- One ultimate slot

Mass Brand is treated as a normal active skill after the tutorial. A player may eventually remove it if another ability or item provides reliable anchor generation.

## Point costs

### Active skills

- Unlock active skill: 1 point
- Common refinement: 1 point
- Choose one mutation branch: 1 point
- Purchase that branch’s apex upgrade: 1 point
- Maximum normal investment per active skill: 4 points

The two mutation branches are mutually exclusive unless an endgame item explicitly breaks that rule.

### Passive nodes

- Minor passive rank: 1 point per rank
- Most minor passives have three ranks
- Cluster notable: 1 point
- Keystone: 1 point
- Grand capstone: 1 point

## Build expectations

A level-50 character should be able to afford approximately:

- Five fully developed active skills
- One developed ultimate
- One Grand Capstone
- Twelve to twenty meaningful passive ranks
- One or two hybrid keystones

A player cannot purchase everything. The tree should force identity without trapping players inside a rigid subclass.

---

# 2. Mechanical constants

These values are the first functional prototype values. Damage coefficients will require tuning after combat testing, but the mechanical relationships should remain.

## Mass Anchors

Base maximum: **3**

Anchor duration:

- Enemy anchor: 12 seconds
- Terrain anchor: 18 seconds
- Corpse anchor: 8 seconds
- Certain upgrades may refresh or remove these durations

Anchors internally store **0–100 Mass**.

### Mass stages

**Dormant: 0–34 Mass**

- Minor visual distortion
- Weak pull influence
- Basic Closure effect

**Dense: 35–69 Mass**

- Stronger distortion
- Moderate local pull
- Increased Collapse damage and Instability release

**Critical: 70–100 Mass**

- Violent local distortion
- Strong environmental effects
- Maximum Collapse behavior
- Generates dangerous interactions during Breach

Mass cannot normally exceed 100.

## Standard Mass gains

These values provide a consistent development language:

- Normal enemy death near anchor: +8
- Elite death near anchor: +20
- Boss phase event near anchor: +25
- Enemy collision: +4 to +18 based on size and velocity
- Projectile crossing Fold Line: +2 at each endpoint
- Event Step between anchors: +6 at both endpoints
- Heavy melee impact: +8
- Successful Countermass: +10 to the attacker’s anchor
- Enemy forcibly moved toward anchor: +1 per meter, maximum +12 per movement event

## Instability

Instability ranges from **0–100**.

Abilities generate Instability rather than consuming mana.

Instability does not decay naturally outside Breach until the player has avoided spatial abilities for four seconds. It then decays at five points per second.

## Breach

Reaching 100 Instability automatically triggers Breach.

Base duration: **8 seconds**

During Breach:

- Instability drains from 100 to 0
- Anchor influence is increased by 30%
- Fold Lines inflict minor spatial-shear damage
- Selected abilities gain secondary origins from anchors
- Closure slows the Breach drain depending on consumed Mass

Closure extension:

- Dormant anchor: +0.4 seconds
- Dense anchor: +0.8 seconds
- Critical anchor: +1.3 seconds

Maximum Breach extension from Closure: 8 additional seconds.

## Clean Closure

A Clean Closure occurs when:

- The Voidbringer collapses at least two Dense or Critical anchors during Breach
- No Critical anchors remain when Breach ends
- The player is not incapacitated when the Breach closes

Clean Closure grants:

- Barrier equal to 12% maximum health
- 20% faster Mass Brand recharge for six seconds
- Immunity to Spatial Recoil
- A benefit determined by the equipped Breach Law

## Spatial Recoil

If Breach ends with one or more Critical anchors remaining:

- Event Step range is reduced by 40%
- Movement speed is reduced by 15%
- Instability generation is increased by 20%
- Remaining anchors lose 30 Mass
- Duration: 4 seconds

Spatial Recoil should be painful enough to matter but not so severe that one mistake destroys the character.

---

# 3. Dedicated class mechanic: Closure

Closure is always available and does not occupy an active-skill slot.

## Base Closure

Target one active Mass Anchor and collapse it.

Cooldown: 0.7 seconds  
Instability generated: 0  
Instability removed:

- Dormant: 7
- Dense: 13
- Critical: 21

Base Collapse damage:

- Dormant: 45% Weapon Power
- Dense: 105% Weapon Power
- Critical: 190% Weapon Power

The effect depends on the anchor carrier:

### Enemy anchor

Collapses inside the enemy and deals concentrated damage.

### Terrain anchor

Creates an area implosion and pulls nearby enemies toward the point.

### Corpse anchor

Destroys the corpse and adds part of its physical mass to the explosion.

### Self-anchor

Releases force around the Voidbringer and scales with Personal Mass.

## Closure tree

Closure is upgraded through the shared **Controlled Ruin** passive cluster rather than an active-skill branch.

This prevents the dedicated class button from consuming an excessive number of active-skill points.

---

# 4. Level-by-level progression

## Level 1

Automatically unlock:

- Mass Brand
- Closure
- One Dormant terrain-anchor tutorial
- Maximum of two anchors until the first Manifold Trial is completed

The player learns to brand an enemy and collapse the anchor.

## Level 2

Automatically unlock:

- Null Shard

Gain first Void Point.

Active-skill refinements become purchasable.

## Level 3

Automatically unlock:

- Worldshear

Gain one Void Point.

The player is introduced to melee loading and enemy collision.

## Level 4

Automatically unlock:

- Event Step

Gain one Void Point.

Fold Lines become visible between active anchors.

## Level 5

Automatically unlock:

- Hard Vacuum

Gain one Void Point.

Maximum anchors increase from two to three.

## Level 6

Gain one Void Point.

Shared Foundation passive clusters unlock:

- Anchorcraft
- Controlled Ruin
- Fold Geometry
- Manifold Integrity

## Level 7

Gain one Void Point.

Mutation branches unlock for the five foundational active skills.

## Level 8

Gain one Void Point plus one Manifold Trial point.

First Manifold Trial: **The Weightless Cell**

Teaches:

- Terrain anchors
- Enemy-to-wall collisions
- Clean anchor replacement

Unlocks:

- Mass Dynamics passive cluster

## Level 9

Gain one Void Point.

Apex upgrades for foundational skill branches become purchasable.

## Level 10

Gain one Void Point.

Manifold Frame affinities unlock:

- Shear Frame
- Vector Array
- Well Core

These are equipment categories, not permanent class choices.

## Level 11

Gain one Void Point.

The player may preview all three disciplines.

No discipline is permanently selected.

## Level 12

Gain one Void Point.

First discipline actives unlock:

- Event Horizon: Convergence
- Redshift: Velocity Theft
- Hollow Form: Gravitic Skin

First passive clusters in all three disciplines become available.

## Level 13

Gain one Void Point.

Discipline active-skill refinements unlock.

## Level 14

Gain one Void Point plus one Manifold Trial point.

Second Manifold Trial: **Three Bodies, One Point**

Teaches:

- Multi-enemy collision
- Fold Line midpoint control
- Mass differences between enemy sizes

## Level 15

Gain one Void Point.

Unlock:

- Anchor Command

Holding Closure pauses normal targeting briefly and allows the player to select a specific anchor with directional input.

Controller targeting prioritizes:

1. Aimed anchor
2. Critical anchor
3. Enemy anchor
4. Terrain anchor
5. Oldest anchor

## Level 16

Gain one Void Point.

Second discipline actives unlock:

- Event Horizon: Crush Point
- Redshift: Periapsis
- Hollow Form: Mass Driver

## Level 17

Gain one Void Point.

Mutation branches unlock for level-12 and level-16 discipline skills.

## Level 18

Gain one Void Point.

Unlock:

- Breach Preview

At 85 Instability, the interface displays the currently projected Breach Law behavior and remaining Critical anchors.

## Level 19

Gain one Void Point.

Breachcraft shared passive cluster unlocks.

## Level 20

Gain one Void Point plus one Manifold Trial point.

Third Manifold Trial: **Containment Failure**

The player must deliberately enter and resolve Breach.

Unlock one free Breach Law choice:

- Law of Compression
- Law of Inversion
- Law of Orbit

The selected Law can be changed outside combat.

## Level 21

Gain one Void Point.

Apex upgrades unlock for level-12 and level-16 skills.

## Level 22

Gain one Void Point.

Third discipline actives unlock:

- Event Horizon: Tidal Lock
- Redshift: Rail Collapse
- Hollow Form: Countermass

## Level 23

Gain one Void Point.

Second passive-cluster tier unlocks in all three disciplines.

## Level 24

Gain one Void Point.

Breach Law mutation branches become visible but cannot yet be purchased.

## Level 25

Gain one Void Point.

Unlock:

- Critical Anchor command cues
- Anchor duration timers
- Fold Line tension indicators

These are interface upgrades earned through progression, not passive bonuses.

## Level 26

Gain one Void Point plus one Manifold Trial point.

Fourth Manifold Trial: **A Wall Is Only Direction**

Teaches:

- Directional terrain impacts
- Projectile bending
- Reversing force

## Level 27

Gain one Void Point.

Apex upgrades unlock for level-22 active skills.

## Level 28

Gain one Void Point.

Fourth discipline actives unlock:

- Event Horizon: Black Meridian
- Redshift: Trajectory Theft
- Hollow Form: Zero-Range Collapse

## Level 29

Gain one Void Point.

The Dead Star class quest begins.

## Level 30

Gain one Void Point.

Complete **The Mass That Should Not Exist** to automatically unlock:

- Dead Star

The ultimate does not cost a Void Point to unlock.

Its refinements and manifestations do cost points.

## Level 31

Gain one Void Point.

Dead Star common refinement becomes purchasable.

## Level 32

Gain one Void Point plus one Manifold Trial point.

Fifth Manifold Trial: **Hostile Trajectories**

Teaches:

- Projectile capture
- Projectile orbit
- Releasing stored attacks safely

## Level 33

Gain one Void Point.

First hybrid keystone tier unlocks.

Requirements:

- At least six points in each of two connected disciplines

## Level 34

Gain one Void Point.

Fifth discipline actives unlock:

- Event Horizon: Accretion Field
- Redshift: Vector Salvo
- Hollow Form: Gravitic Clamp

## Level 35

Gain one Void Point.

Cross-discipline bridge passives unlock.

## Level 36

Gain one Void Point.

The selected Breach Law’s mutation branch becomes purchasable.

## Level 37

Gain one Void Point.

Apex upgrades unlock for level-28 and level-34 active skills.

## Level 38

Gain one Void Point plus one Manifold Trial point.

Sixth Manifold Trial: **The Moving Center**

Teaches:

- Self-anchor builds
- Mobile geometry
- Personal Mass

## Level 39

Gain one Void Point.

Second hybrid keystone tier unlocks.

Requirements:

- At least eight points in each connected discipline

## Level 40

Gain one Void Point.

Choose one Dead Star manifestation:

- Black Star
- Red Orbit
- Star Vessel

The choice can be changed outside combat.

## Level 41

Gain one Void Point.

Grand passive clusters unlock inside all disciplines.

## Level 42

Gain one Void Point.

Unlock:

- Breach Extension display
- Closure chain preview
- Dead Star projected mass indicator

## Level 43

Gain one Void Point.

All remaining active-skill apex upgrades become purchasable.

## Level 44

Gain one Void Point plus one Manifold Trial point.

Seventh Manifold Trial: **No Stable Frame**

The player must complete three different Clean Closures under changing Breach Laws.

## Level 45

Gain one Void Point.

Grand Capstone tier becomes visible.

## Level 46

Gain one Void Point.

Grand Capstones become purchasable.

Requirements:

- Eighteen points invested in the associated discipline
- One Grand Capstone maximum

## Level 47

Gain one Void Point.

Breach Law apex upgrades become purchasable.

## Level 48

Gain one Void Point.

Dead Star manifestation apex upgrades become purchasable.

## Level 49

Gain one Void Point.

Unlock:

- Final hybrid keystone access
- Full respec access through the Manifold Chamber
- Saved skill-tree loadouts

## Level 50

Gain one Void Point plus one final Manifold Trial point.

Final Trial: **Clean Closure**

The player must defeat a class-specific boss by:

- Entering Breach at least twice
- Executing one Clean Closure
- Destroying the boss through Mass, collision, Fold Line or Collapse damage

Completing the trial unlocks:

- The full 57-point total
- Grand Capstone activation
- Endgame Manifold Imprints
- A second saved equipment-and-skill loadout

---

# 5. Foundational active skills

## Mass Brand

### Base skill

Fire or drive a Null Shard into an enemy or surface, creating a Mass Anchor.

Charges: 2  
Recharge: 4 seconds per charge  
Damage: 35% Weapon Power  
Instability: 5  
Mass on placement:

- Enemy: 8
- Terrain: 5
- Critical hit placement: additional 5

Mass Brand does not interrupt movement when used with a Vector Array or Well Core.

### Common refinement: Deep Placement

Mass Brand gains:

- One additional charge
- 20% faster projectile speed
- Enemy anchors persist two seconds longer

### Branch A: Carrier Brand

Anchors attached to enemies gain:

- +1 Mass for every meter the target moves
- +6 Mass when the target uses a movement ability
- 15% stronger pull influence

#### Apex A: Grave Relay

When a branded enemy dies:

- The anchor remains on the corpse for four seconds
- If another enemy passes within four meters, the anchor transfers to it
- The transferred anchor retains 70% of its stored Mass

This route supports mobile targets, pursuit and corpse interactions.

### Branch B: World Nail

Terrain anchors gain:

- 40% larger influence radius
- 30% longer duration
- Increased Fold Line stability
- Immunity to weak enemy displacement effects

#### Apex B: Foundation Theft

Placing World Nail on:

- A wall increases directional collision damage
- A floor increases pull strength
- A ceiling increases downward force
- A destructible object allows the anchor to inherit the object’s mass when destroyed

This route supports battlefield architecture.

---

## Null Shard

### Base skill

Launch a sharp Null fragment.

Damage: 75% Weapon Power  
Instability: 4  
No cooldown

Whenever Null Shard crosses a Fold Line:

- Projectile speed increases by 25%
- Damage increases by 12%
- Both anchors gain 2 Mass

Maximum base Fold Line bonuses: three crossings.

### Common refinement: Accelerated Absence

Null Shard:

- Retains speed after penetrating an enemy
- Gains 10% critical chance after crossing a Fold Line
- Can be redirected once by strong anchor influence

### Branch A: Rail Splinter

Null Shard becomes narrower and faster.

- Penetrates two enemies
- Deals increased damage based on travel distance
- Adds 5 Mass to the first anchored enemy struck
- Cannot orbit

#### Apex A: Event Lance

After crossing two Fold Lines, Null Shard becomes an Event Lance:

- Pierces all normal enemies
- Breaks 20% enemy armor
- Creates a temporary Fold Line along its path
- Striking a boss loads 12 Mass into its anchor

### Branch B: Orbital Shard

Null Shard entering an anchor’s influence begins orbiting instead of striking immediately.

- Can orbit for up to two seconds
- Gains speed and damage while orbiting
- Releases toward the aimed target when the skill is pressed again
- Maximum three orbiting shards per anchor

#### Apex B: Funeral Orbit

When an anchor collapses:

- All orbiting shards fire toward the nearest anchored enemy
- Each shard inherits part of the collapsed anchor’s Mass as damage
- Shards released from a Critical anchor explode after impact

---

## Worldshear

### Base skill

Form a close-range spatial blade and cut forward.

Damage: 110% Weapon Power  
Instability: 7  
Attack range: 3.5 meters

If Worldshear crosses a Fold Line:

- The line repeats the cut along its entire length
- Both endpoints gain 5 Mass
- Each line can repeat one cut per use

### Common refinement: Split Matter

Worldshear:

- Deals 25% increased damage to enemies currently being pulled
- Has increased impact against Dense or Critical anchored enemies
- Can rupture two nearby Fold Lines instead of one

### Branch A: Pressure Edge

Worldshear becomes a heavier committed strike.

- Damage increases by up to 60% based on combined Mass at the crossed Fold Line’s endpoints
- Pulls enemies slightly into the blade
- Attack speed is reduced by 15%

#### Apex A: Guillotine Event

Against an enemy attached to a Critical anchor:

- Worldshear consumes 25 Mass
- Repeats a second time from the opposite direction
- Both cuts occur nearly simultaneously
- The anchor remains active

### Branch B: Open Wound

Worldshear leaves a spatial seam for three seconds.

Enemies crossing the seam:

- Take 45% Weapon Power
- Are briefly pulled backward into the cut
- Add 2 Mass to the nearest anchor

Maximum active seams: three.

#### Apex B: Unhealed World

When two seams intersect:

- Their intersection becomes a temporary micro-anchor
- The micro-anchor cannot be targeted by Closure
- It pulls enemies toward the crossing point
- It ruptures when either original seam expires

---

## Event Step

### Base skill

Fold the distance to a targeted anchor.

Cooldown: 6 seconds  
Instability: 10  
Maximum anchor range: 15 meters

Without an anchor target, Event Step performs a six-meter directional displacement.

Enemies crossing the folded path:

- Are dragged toward the path’s midpoint
- Take 40% Weapon Power
- Add 6 Mass to both endpoint anchors

### Common refinement: Shortened World

Event Step gains:

- 20% increased range
- Brief immunity during the fold
- 25% cooldown reduction after traveling through two Fold Lines

### Branch A: Exchange

Targeting an enemy anchor swaps the Voidbringer and enemy positions.

Normal enemies are fully exchanged.

Bosses and immovable enemies instead:

- Pull the Voidbringer behind or beside them
- Rotate the enemy slightly
- Add 10 Mass to the target’s anchor

#### Apex A: Smuggled Violence

The Voidbringer carries the nearest normal enemy through the Exchange.

On arrival:

- The carried enemy collides with the anchored target
- Both receive collision damage
- The carried enemy inherits 20 Mass for two seconds

### Branch B: Afterevent

Event Step leaves a spatial echo at the starting location.

After 0.8 seconds, the echo repeats:

- The last basic attack
- Null Shard
- Worldshear
- Mass Brand

The echo deals 65% normal damage.

#### Apex B: Event Recursion

If Event Step travels between two Critical anchors:

- A second echo appears at the destination
- One echo repeats the prior attack
- The other repeats the next compatible attack
- Each echo can trigger Fold Line interactions at 50% effectiveness

---

## Hard Vacuum

### Base skill

Compress air and loose matter around the Voidbringer for 1.5 seconds.

Cooldown: 12 seconds  
Instability: 8

During the effect:

- Hostile projectiles are slowed by 70%
- Nearby light enemies are pulled inward
- 40% of incoming impact force is stored
- The Voidbringer gains 20% damage reduction

When the effect ends, stored force is released outward.

### Common refinement: Sealed Pressure

Hard Vacuum:

- Can be ended early
- Stores 60% impact force
- Adds 5 Mass to nearby anchors when absorbing a heavy attack

### Branch A: Force Vault

The release is removed.

Stored force remains for five seconds and empowers the next:

- Mass Driver
- Worldshear
- Rail Collapse
- Closure
- Event Step collision

#### Apex A: Hostile Reserve

A perfectly timed activation against an incoming heavy hit:

- Stores 100% of that hit’s impact
- Prevents displacement
- Creates a temporary barrier
- Causes the empowered release to originate from both the Voidbringer and the attacker’s anchor

### Branch B: Vacancy

Hard Vacuum leaves behind an empty region for four seconds.

The Vacancy:

- Continues pulling enemies
- Slows projectiles
- Adds one Mass per second to anchors inside
- Does not move with the player

#### Apex B: Nothing Escapes

Collapsing an anchor inside the Vacancy:

- Pulls the Vacancy into the collapse
- Increases Collapse radius by 50%
- Causes surviving enemies to be dragged back toward the empty point after the initial explosion

---

# 6. Event Horizon active skills

## Convergence

Unlock level: 12

### Base skill

Select two anchors and pull affected enemies toward their midpoint.

Cooldown: 8 seconds  
Instability: 9  
Damage: primarily collision-based

Enemies arriving from opposing directions collide.

Collision damage scales with:

- Combined enemy weight
- Distance traveled
- Velocity
- Mass stored in both anchors

### Common refinement: Violent Agreement

Convergence:

- Increases movement speed toward the center
- Adds 4 Mass to each anchor per collision
- Briefly staggers enemies that reach the center without colliding

### Branch A: Dominant Center

Choose one anchor as dominant.

All affected enemies are dragged toward that anchor instead of the midpoint.

#### Apex A: Sovereign Weight

If the dominant anchor is Critical:

- It cannot lose Mass during Convergence
- Enemies are unable to use movement abilities
- Heavy enemies pull lighter enemies with them

### Branch B: False Center

The player manually places a temporary center between the anchors.

The center:

- Exists for two seconds
- Has no anchor
- Can be positioned away from the Fold Line
- Enables curved or angled convergence

#### Apex B: Murdered Geometry

When enemies collide at the False Center:

- A temporary micro-collapse occurs
- Both real anchors gain Mass
- The False Center becomes a damaging spatial fracture for three seconds

---

## Crush Point

Unlock level: 16

### Base skill

Instantly collapse a targeted anchor into an extremely concentrated implosion.

Cooldown: 7 seconds  
Instability: 4  
Collapse Instability release still applies  
Damage:

- Dormant: 90% Weapon Power
- Dense: 190%
- Critical: 340%

Radius is smaller than normal Closure.

### Common refinement: Refined Failure

Crush Point:

- Deals 30% increased armor damage
- Gains increased critical chance against the anchor’s carrier
- Reduces cooldown by one second when consuming a Critical anchor

### Branch A: Internal Failure

When used on an enemy anchor:

- Radius is reduced further
- Direct-target damage increases by 70%
- A percentage of damage bypasses armor
- Normal enemies may rupture violently

#### Apex A: Organ of Nothing

If Internal Failure kills the target:

- The corpse collapses inward
- Nearby enemies are pulled into the corpse
- The dead target’s weight is added to the nearest anchor

### Branch B: Vacancy Well

Crush Point leaves behind a compact pull field for four seconds.

The field:

- Deals low repeated damage
- Drags enemies through nearby Fold Lines
- Gains strength based on consumed Mass

#### Apex B: Collapse Again

When Vacancy Well expires:

- It performs a second smaller implosion
- Enemies still inside are treated as though anchored
- The second implosion adds Mass to surviving nearby anchors

---

## Tidal Lock

Unlock level: 22

### Base skill

Bind an enemy into an orbital path around an anchor.

Cooldown: 10 seconds  
Instability: 11  
Duration: 4 seconds

Normal enemies fully orbit.

Elites orbit more slowly.

Bosses are pulled laterally and have their facing disrupted rather than fully orbiting.

### Common refinement: Decaying Orbit

Each completed orbit:

- Deals 45% Weapon Power
- Adds 5 Mass to the anchor
- Increases orbital speed by 10%

### Branch A: Satellite Body

One enemy can be placed into a powerful close orbit.

The orbiting enemy:

- Blocks projectiles
- Collides with nearby targets
- Takes repeated impact damage
- Can be launched by reactivating Tidal Lock

#### Apex A: Extinction Sling

Launching the satellite:

- Converts all completed orbital velocity into collision damage
- Causes the enemy to penetrate lighter targets
- Adds the satellite’s remaining health percentage as additional Impact

### Branch B: Captive System

Up to four normal enemies may orbit simultaneously.

Each deals reduced individual damage but creates a wider control zone.

#### Apex B: Failed System

Collapsing the central anchor:

- Throws all orbiting enemies outward
- Each enemy becomes a temporary Mass-bearing projectile
- Collisions between thrown enemies cause secondary implosions

---

## Black Meridian

Unlock level: 28

### Base skill

Intensify one Fold Line for five seconds.

Cooldown: 12 seconds  
Instability: 12

Enemies crossing the Meridian take 40% Weapon Power.

Enemies forcibly dragged through it take 110% Weapon Power.

The same enemy can be damaged once every 0.6 seconds.

### Common refinement: Dividing Line

Black Meridian:

- Cuts armor
- Adds 3 Mass to both anchors whenever an enemy is forcibly dragged through
- Remains active if one endpoint moves

### Branch A: Execution Meridian

The line becomes thinner and more dangerous.

- Deals increased damage to injured enemies
- Damage scales with Mass difference between endpoints
- Critical hits briefly prevent healing

#### Apex A: World Guillotine

Dragging an enemy through the Meridian three times marks it for Division.

The next forced crossing:

- Deals massive execution damage
- Immediately kills weak normal enemies
- Removes 20 Mass from each endpoint instead of collapsing them

### Branch B: Transit Meridian

The line becomes a spatial transfer channel.

Projectiles or enemies entering near one endpoint may exit near the other.

#### Apex B: Hostile Transfer

The Voidbringer can redirect:

- Enemy projectiles
- Charging enemies
- Certain ground hazards

Anything transferred gains speed and causes Mass at the exit anchor.

---

## Accretion Field

Unlock level: 34

### Base skill

Create a large field around a chosen anchor for six seconds.

Cooldown: 16 seconds  
Instability: 14

Within the field:

- Enemy movement generates Mass
- Deaths generate additional Mass
- Loose projectiles curve toward the anchor
- Corpses slowly slide inward

The field does not directly deal significant damage.

### Common refinement: Hungry Region

The field:

- Is 25% larger
- Loads 20% more Mass
- Extends by one second whenever an elite dies inside

### Branch A: Grave Accretion

Corpses entering the center are consumed.

Each corpse:

- Adds Mass based on enemy size
- Increases the next Collapse’s damage
- Briefly strengthens the field’s pull

#### Apex A: Common Grave

When the field ends:

- Every consumed corpse briefly manifests as compressed body mass
- The field performs a final collapse
- Enemy anchors inside inherit part of the accumulated corpse Mass

### Branch B: Kinetic Accretion

Movement becomes the primary fuel.

The field gains Mass from:

- Dodges
- Dashes
- Knockback
- Charges
- Projectile movement
- Event Step

#### Apex B: Motion Is Weight

When the field ends:

- All movement recorded inside is replayed inward as force
- Enemies are dragged along the reverse of their recent movement
- The central anchor gains Mass based on total distance reversed

---

# 7. Redshift active skills

## Velocity Theft

Unlock level: 12

### Base skill

Strip momentum from enemies and hostile projectiles in a targeted area.

Cooldown: 9 seconds  
Instability: 8

Affected enemies are slowed by 45%.

Affected projectiles are slowed by 80%.

Stolen momentum becomes **Velocity Reserve** for four seconds.

Velocity Reserve empowers the next movement, projectile or impact skill.

### Common refinement: Conserved Motion

Velocity Theft:

- Stores 30% more Reserve
- Can slow boss attacks without affecting animation timing
- Converts prevented knockback into Reserve

### Branch A: Wide Arrest

The affected area becomes larger and persists for three seconds.

Objects entering it are gradually drained.

#### Apex A: Still World

When the field reaches maximum stored Reserve:

- All normal projectiles stop completely
- Normal enemies briefly lose movement
- The Voidbringer gains movement speed while inside the field

### Branch B: Perfect Theft

Target one enemy or projectile.

- Nearly all momentum is stolen instantly
- The area effect is removed
- Reserve is much stronger
- Cooldown is reduced against elite or boss attacks

#### Apex B: Stolen Attack

Perfectly stealing a charge, leap or projectile:

- Records its direction
- Allows the next Event Step, Rail Collapse or Mass Driver to reproduce that vector
- Doubles collision Impact

---

## Periapsis

Unlock level: 16

### Base skill

Rush around a selected anchor in a curved path.

Cooldown: 7 seconds  
Instability: 9  
Damage: 65% Weapon Power along the path

The closer the path passes to the anchor:

- The faster the exit speed
- The greater the Velocity Reserve generated
- The more Mass added to the anchor

### Common refinement: Tight Orbit

Periapsis:

- Gains brief immunity near the closest orbital point
- Adds 8 Mass to the anchor
- Reduces Event Step cooldown by one second

### Branch A: Cutting Orbit

Worldshear is automatically performed along part of the orbital path.

#### Apex A: Perihelion Blade

Passing within minimum distance of a Critical anchor:

- Repeats the orbital cut
- Creates a full circular spatial seam
- Causes the next Worldshear to inherit exit velocity

### Branch B: Slingshot

Periapsis deals less damage during the orbit but grants extreme exit momentum.

The next:

- Null Shard
- Rail Collapse
- Event Step
- Mass Driver

gains range and impact.

#### Apex B: Escape Velocity

At maximum exit speed:

- The empowered action originates from the anchor instead of the Voidbringer
- An afterimage performs a second weaker version from the player’s position

---

## Rail Collapse

Unlock level: 22

### Base skill

Collapse a selected anchor by launching its condensed Mass forward.

Cooldown: 8 seconds  
Instability: 7

Damage scales with:

- Anchor Mass
- Travel distance
- Fold Lines crossed
- Enemies penetrated
- Velocity Reserve

An enemy carrying the anchor is launched as the projectile.

A terrain anchor produces a condensed spatial projectile.

### Common refinement: Hyperdense Payload

Rail Collapse:

- Penetrates one additional enemy
- Deals 20% increased collision damage
- Gains accuracy and speed from Fold Lines

### Branch A: Living Round

Enemy anchors always launch the enemy body.

- Normal enemies can penetrate lighter targets
- Elites knock targets aside
- Bosses cannot be launched but emit a point-blank rail shockwave

#### Apex A: Body Through Body

Every enemy penetrated:

- Adds blood and physical matter to the projectile
- Increases its Mass and impact
- Creates an anchor on the final surviving enemy struck

### Branch B: Null Accelerator

Terrain anchors produce a pure condensed shot.

- Narrower projectile
- Higher direct damage
- Ignores some armor
- Cannot launch enemies

#### Apex B: Fold Rail

Crossing a Fold Line:

- Teleports the projectile to that line’s other endpoint
- Preserves velocity
- Increases damage
- Allows impossible firing angles

---

## Trajectory Theft

Unlock level: 28

### Base skill

Capture hostile projectiles within a forward field.

Cooldown: 14 seconds  
Instability: 10  
Maximum captured projectiles: 8

Captured projectiles enter orbit around the Voidbringer.

Reactivate to release them toward the aimed target.

Boss projectiles may count as multiple captures.

### Common refinement: Stolen Intent

Captured projectiles:

- Deal at least 50% Weapon Power even if their original damage was low
- Gain the Voidbringer’s damage modifiers
- Can cross Fold Lines
- Remain stored for six seconds

### Branch A: Hostile Constellation

Transfer captured projectiles to a selected anchor.

They orbit that anchor instead of the player.

#### Apex A: Enemy Astronomy

Each full orbit:

- Increases projectile speed
- Adds Mass to the anchor
- Improves release damage

Collapsing the anchor automatically releases the constellation.

### Branch B: Reversal Field

Instead of storing projectiles, immediately reverse them.

- Lower maximum projectile count
- Faster cooldown
- Applies strong enemy-facing pressure

#### Apex B: Author Returned

A perfectly timed reversal:

- Returns the projectile through its original path
- Deals increased damage to its source
- Creates a Fold Line between the Voidbringer and the attacker
- Brands the source if no anchor is present

---

## Vector Salvo

Unlock level: 34

### Base skill

Release six Null Shards in a configurable fan.

Cooldown: 10 seconds  
Instability: 11  
Damage: 45% Weapon Power per shard

Shards curve toward anchors and anchored enemies.

### Common refinement: Calculated Spread

Vector Salvo:

- Fires two additional shards
- Allows the player to narrow or widen the fan by holding the skill
- Gains 8% damage per Fold Line crossed

### Branch A: Murder Orbit

Shards do not immediately seek enemies.

They spread among nearby anchors and enter short orbit.

Reactivating the skill releases all shards simultaneously.

#### Apex A: System Execution

If three anchors each hold at least one shard:

- Release causes all shards to cross the network
- Each anchor fires toward both other anchors
- Enemies inside the geometry are struck from several directions

### Branch B: Single Vector

All shards combine into one unstable projectile.

- High damage
- High impact
- Lower area coverage
- Gains more benefit from Velocity Reserve

#### Apex B: No Rest Frame

The projectile exists simultaneously at several points along its path.

It damages enemies:

- At launch
- At the midpoint
- At impact

Each occurrence can trigger Fold Line effects separately.

---

# 8. Hollow Form active skills

## Gravitic Skin

Unlock level: 12

### Base skill

Increase Personal Mass and draw Null Shards into defensive orbit.

Cooldown: 14 seconds  
Duration: 6 seconds  
Instability: 12

While active:

- Gain 25% damage reduction
- Resist 80% displacement
- Pull nearby light enemies inward
- Count as a Mass Anchor
- Event Step may target the player’s prior location

Personal Mass begins at 30 and increases through absorbed impacts.

### Common refinement: Dense Body

Gravitic Skin:

- Lasts two seconds longer
- Begins with 45 Personal Mass
- Adds Mass when enemies strike the Voidbringer

### Branch A: Containment Armor

Defensive focus:

- Damage reduction increases
- Orbiting shards intercept projectiles
- Personal Mass decays more slowly

#### Apex A: Unfallen Weight

Prevented displacement becomes Personal Mass.

At maximum Personal Mass:

- The Voidbringer cannot be knocked down
- Heavy attacks create localized shockwaves
- Movement speed is reduced by 15%

### Branch B: Bone Orbit

Offensive focus:

- Shards orbit closer and faster
- Enemies pulled into the orbit take repeated damage
- Melee attacks launch shards through nearby targets

#### Apex B: Skin of Blades

When Gravitic Skin ends:

- Every orbiting shard embeds into a nearby enemy or surface
- Each creates a temporary low-Mass anchor
- Maximum anchors may briefly exceed the normal limit

---

## Mass Driver

Unlock level: 16

### Base skill

Form a massive gravitational limb and strike forward.

Cooldown: 7 seconds  
Instability: 9  
Damage: 170% Weapon Power  
High Impact

The primary target temporarily becomes extremely heavy.

Everything around the target is pushed away.

Against bosses, the Voidbringer is pulled toward the impact point instead.

### Common refinement: Unequal Collision

Mass Driver:

- Deals 30% increased damage to moving enemies
- Adds 10 Mass to anchored targets
- Produces stronger terrain collisions

### Branch A: Absolute Fist

The target’s Mass is increased dramatically.

- Direct damage increased
- Area push reduced
- Target becomes difficult to move briefly

#### Apex A: Weight Sentence

A second heavy hit against the weighted target:

- Causes the target to collapse downward
- Produces an area impact based on target size
- Adds Mass to every nearby anchor

### Branch B: Scatter Event

The target remains lighter, but surrounding enemies are violently launched.

#### Apex B: Human Shrapnel

Normal enemies struck by the shockwave:

- Become temporary projectiles
- Damage anything they collide with
- Gain short-lived anchors when hitting terrain

---

## Countermass

Unlock level: 22

### Base skill

Briefly oppose incoming force.

Cooldown: 8 seconds  
Instability: 5  
Perfect timing window: 0.3 seconds

A normal activation:

- Reduces damage by 35%
- Prevents most displacement

A perfect activation:

- Reduces damage by 80%
- Stores Impact
- Adds 10 Mass to the attacker’s anchor
- Creates a Fold Line to the attacker
- Empowers the next melee ability

### Common refinement: Equal Opposition

Countermass:

- Has a slightly longer timing window
- Stores more Impact
- Can respond to ground slams and charges

### Branch A: Violent Return

Stored force empowers the next attack.

#### Apex A: Equal and Opposite

The empowered attack repeats the enemy’s original force in reverse.

A charge becomes a launch.

A slam becomes an upward rupture.

A projectile impact becomes a focused spatial shot.

### Branch B: Standing Law

Countermass becomes a one-second braced stance.

- Lower perfect mitigation
- Can resist multiple hits
- Builds Personal Mass continuously

#### Apex B: Nothing Moves Me

If the Voidbringer remains in place for the full stance:

- All prevented force is released through the ground
- Nearby enemies are knocked toward active anchors
- Gravitic Skin cooldown is reduced

---

## Zero-Range Collapse

Unlock level: 28

### Base skill

Collapse all local spatial pressure directly around the Voidbringer.

Cooldown: 11 seconds  
Instability: 13  
Damage: 140% Weapon Power plus Personal Mass scaling

Enemies are first pulled against the character and then crushed.

Nearby enemy anchors are not consumed, but each loses 15 Mass.

### Common refinement: Inward Violence

Zero-Range Collapse:

- Has increased pull strength
- Gains damage from nearby corpses
- Reduces Instability based on enemies struck

### Branch A: Living Singularity

The implosion remains centered on the player for two seconds.

The Voidbringer can move slowly while enemies continue being dragged inward.

#### Apex A: Devouring Center

During the effect:

- The Voidbringer counts as Critical
- Fold Lines connect every active anchor to the player
- Enemies crossing those lines are dragged into melee range
- Closure may target the self-anchor at the end

### Branch B: Pressure Release

The pull duration is shorter.

Stored Personal Mass is released as a violent outward blast after the implosion.

#### Apex B: Collapse and Rebound

Enemies first pulled inward are then launched outward.

Terrain collisions:

- Deal increased damage
- Create temporary anchors
- Reduce Mass Driver cooldown

---

## Gravitic Clamp

Unlock level: 34

### Base skill

Form a gravitational limb and seize an anchored enemy.

Cooldown: 13 seconds  
Instability: 12

Normal enemies can be:

- Held as a shield
- Swung into other enemies
- Thrown
- Crushed against terrain

Elites resist full control but are dragged.

Bosses become tethered to the player, changing movement rather than being grabbed.

### Common refinement: Hostile Counterweight

While holding an enemy:

- Gain frontal damage reduction
- The held enemy absorbs projectiles
- Moving the enemy adds Mass to its anchor

### Branch A: Flesh Weapon

The held enemy becomes an improvised melee weapon.

#### Apex A: Borrowed Anatomy

The attack behavior changes based on the held enemy:

- Heavy enemies produce slams
- Armored enemies break defenses
- Explosive enemies detonate on impact
- Spined enemies create projectile bursts
- Parasitic enemies spread infestation effects

### Branch B: Deadlock

Against elites and bosses, Gravitic Clamp creates a two-way tether.

- Neither side can move beyond a maximum distance
- Enemy movement pulls the Voidbringer
- Voidbringer movement loads the enemy anchor
- Damage dealt strengthens the tether

#### Apex B: Shared Catastrophe

When the tether ends:

- Stored movement is released between both bodies
- The heavier participant drags the lighter one
- If neither moves, the midpoint violently collapses

---

# 9. Ultimate: Dead Star

Unlock level: 30

## Base Dead Star

Create a miniature dead star above the targeted area.

Cooldown: 90 seconds  
Initial duration: 10 seconds  
Initial Instability: 20

During Dead Star:

- Enemies are pulled toward it
- Projectiles begin entering orbit
- Dead enemies contribute Mass
- Collapsed anchors feed the star
- Fold Lines curve toward its center
- The star may be repositioned by sacrificing an anchor

The player may reactivate Dead Star to detonate it early.

Damage scales with accumulated Star Mass.

## Common refinement: Accreting End

Dead Star:

- Lasts two seconds longer
- Gains additional Mass from elites and bosses
- Displays three visible power stages
- Grants the player partial resistance to its pull

At level 40, choose one manifestation.

## Manifestation A: Black Star

Dead Star becomes slower, heavier and more controllable.

- Larger pull radius
- Stronger anchor consumption
- Greater area control
- Lower projectile release

### Apex: The Last Center

If Dead Star consumes three Critical anchors:

- It becomes fixed in place
- All enemies are treated as anchored to it
- Fold Lines form from every nearby corpse and terrain anchor
- Detonation produces a prolonged inward collapse rather than one explosion

Best for Event Horizon builds.

## Manifestation B: Red Orbit

Dead Star creates a violent orbital system.

- Projectiles and Null Shards orbit rapidly
- Enemies circle rather than moving directly inward
- Periapsis and Tidal Lock gain additional orbital speed
- Early detonation launches stored objects outward

### Apex: Lightless Velocity

Every full orbit increases stored velocity.

On detonation:

- Captured projectiles are released first
- Orbiting enemies become living ammunition
- The star then fires its own Mass along the player’s aimed vector

Best for Redshift builds.

## Manifestation C: Star Vessel

The star descends into the Voidbringer’s containment harness.

For ten seconds:

- The player becomes the star
- Personal Mass becomes maximum
- Nearby enemies are pulled inward
- Melee attacks create localized collapses
- Event Step becomes a crushing arrival
- Normal movement is slower

### Apex: Body of the End

During Star Vessel:

- Closure may consume nearby enemy anchors without animation delay
- Each consumed anchor extends the form
- Zero-Range Collapse has no cooldown but rapidly generates Instability
- When the form ends, all accumulated force is released around the player

Best for Hollow Form builds.

---

# 10. Shared passive clusters

Each minor passive has three ranks unless noted.

## Cluster: Anchorcraft

### Deep Nails

Mass Brand placement Mass:

- +2 per rank

### Persistent Error

Anchor duration:

- +8% per rank

### Distant Placement

Mass Brand range and projectile speed:

- +7% per rank

### Notable: Stable Triangle

While exactly three anchors are active:

- All anchors gain 10% increased duration
- Fold Lines become more resistant to disruption
- Replacing an anchor refunds one Mass Brand charge

## Cluster: Controlled Ruin

### Efficient Closure

Closure removes:

- +2 Instability per rank

### Dense Failure

Closure damage:

- +8% per rank

### Afterpressure

Enemies surviving Closure take:

- 5% increased collision and Fold Line damage per rank for three seconds

### Notable: Ordered Collapse

Collapsing anchors from lowest Mass to highest Mass causes each Collapse to deal 15% more damage than the previous one.

The chain resets if the order is broken.

## Cluster: Fold Geometry

### Tensioned Space

Fold Line damage:

- +10% per rank

### Shortened Distance

Abilities traveling along Fold Lines gain:

- +6% range and speed per rank

### Crossing Pressure

Enemies crossing Fold Lines add:

- +1 Mass per rank to both endpoints

### Notable: Non-Euclidean

The longest active Fold Line gains:

- A slight curve toward nearby enemies
- Increased pull interaction
- One additional skill interaction per second

## Cluster: Manifold Integrity

### Containment Plate

Damage reduction during Breach:

- +2% per rank

### Null Barrier

Clean Closure barrier:

- +4% maximum health per rank

### Harness Recovery

After Spatial Recoil ends:

- Heal 2% maximum health per rank

### Notable: Emergency Closure

The first time the Voidbringer would be incapacitated during Breach:

- The nearest Critical anchor automatically collapses
- The player gains a brief barrier
- Can occur once per encounter

## Cluster: Mass Dynamics

### Collision Theory

Collision damage:

- +9% per rank

### Applied Force

Forced movement strength:

- +6% per rank

### Weight Differential

Damage when a heavier enemy collides with a lighter enemy:

- +12% per rank

### Notable: Equal and Opposite

Whenever the Voidbringer prevents forced movement:

- The source receives stored Impact
- The next forced movement applied to that source is 30% stronger

## Cluster: Breachcraft

### Rising Error

Instability generated:

- -3% per rank

This does not reduce Instability generated by capstones below their stated minimum.

### Extended Failure

Base Breach duration:

- +0.4 seconds per rank

### Recoil Discipline

Spatial Recoil duration:

- -12% per rank

### Notable: Operate Past Redline

At 90 or more Instability:

- Deal 15% increased spatial damage
- Gain 10% increased movement speed
- Closure removes 20% less Instability

This encourages deliberate high-risk play.

---

# 11. Event Horizon passive clusters

## Cluster: Accretion

### Feeding Field

Enemy deaths near anchors add:

- +2 Mass per rank

### Elite Weight

Elite deaths add:

- +5 Mass per rank

### Corpse Drift

Corpses are pulled toward anchors:

- 15% faster per rank

### Notable: Weight of the Dead

Nearby corpses count as temporary environmental Mass.

Collapsing a terrain anchor consumes nearby corpses for increased damage.

## Cluster: Closed Geometry

### Line Pressure

Enemies inside a closed three-anchor shape take:

- 4% increased pressure damage per rank

### Stable Angles

Fold Lines in a closed shape gain:

- +10% duration and stability per rank

### Internal Drag

Enemies moving inside closed geometry are slowed:

- 4% per rank

### Notable: Murder Polygon

When exactly three anchors form a closed shape:

- The interior gradually loads all three anchors
- Enemies touching an edge are dragged inward
- The effect ends if an anchor is removed

## Cluster: Gravitational Authority

### Stronger Center

Anchor pull strength:

- +7% per rank

### Movement Denial

Anchored enemies have:

- 5% reduced movement-skill distance per rank

### Heavy Silence

Enemies actively being pulled deal:

- 4% less damage per rank

### Notable: No Escape Vector

Enemies moving away from an anchor add Mass based on distance traveled.

Movement abilities add double Mass.

## Cluster: Collapse Doctrine

### Critical Failure

Critical-anchor Collapse damage:

- +10% per rank

### Expanding Ruin

Collapse radius:

- +6% per rank

### Surviving Pressure

Enemies surviving a Critical Collapse lose:

- 5% armor per rank

### Notable: Chain Failure

Collapsing a Critical anchor causes nearby Dense anchors to lose 20 Mass and produce smaller secondary implosions without being destroyed.

## Cluster: Black Sun

### Projectile Hunger

Critical anchors absorb:

- One weak projectile every six seconds, reduced by one second per rank

### Dense Darkness

Enemies near Critical anchors have reduced attack speed:

- 3% per rank

### Breach Gravity

Anchor influence during Breach:

- +8% per rank

### Notable: Event Consumption

Projectiles absorbed by Critical anchors are released during Closure as hostile fragments aimed at nearby enemies.

---

# 12. Redshift passive clusters

## Cluster: Momentum Reserve

### Preserved Speed

Velocity Reserve duration:

- +0.8 seconds per rank

### Kinetic Yield

Velocity Theft Reserve generation:

- +10% per rank

### Moving Damage

Damage while the Voidbringer is moving:

- +4% per rank

### Notable: No Stable Frame

Damage increases based on the difference between the Voidbringer’s velocity and the target’s velocity.

Maximum bonus: 30%.

## Cluster: Event Motion

### Repeated Step

Event Step cooldown:

- -4% per rank

### Arrival Force

Event Step collision damage:

- +10% per rank

### Fold Momentum

Traveling between two anchors grants movement speed:

- +5% per rank for three seconds

### Notable: Stolen Distance

Distance traveled by slowed enemies reduces Event Step cooldown and increases its next range.

## Cluster: Orbital Mechanics

### Accelerated Orbit

Orbital speed:

- +8% per rank

### Stored Revolution

Damage gained per completed orbit:

- +6% per rank

### Stable Satellite

Orbiting projectiles and enemies remain controlled:

- +0.5 seconds per rank

### Notable: Perihelion

Anything released from orbit deals increased damage based on how closely it passed to the anchor.

## Cluster: Hostile Trajectory

### Capture Capacity

Trajectory Theft maximum captures:

- +1 per rank

### Reflected Violence

Captured enemy projectile damage:

- +9% per rank

### Curved Intent

Projectile turning strength near anchors:

- +7% per rank

### Notable: Return Address

Projectiles returned to their original source:

- Brand the source
- Add 10 Mass
- Reduce Trajectory Theft cooldown

## Cluster: Redline

### Rapid Error

Instability generated by movement abilities:

- +5% per rank

Movement skill damage:

- +8% per rank

### Third Action

Using three different movement or trajectory skills within four seconds grants:

- +6% attack speed per rank

### Afterimage Force

Echo and afterimage damage:

- +10% per rank

### Notable: Redline Sequence

The third movement or projectile skill used in rapid sequence originates from both the starting and ending position at 55% effectiveness.

---

# 13. Hollow Form passive clusters

## Cluster: Personal Mass

### Dense Flesh

Starting Personal Mass:

- +5 per rank

### Slow Decay

Personal Mass decay:

- -10% per rank

### Heavy Strike

Melee damage per 25 Personal Mass:

- +4% per rank

### Notable: Absolute Body

Remaining stationary for one second begins building Personal Mass.

The first movement or impact releases part of that Mass offensively.

## Cluster: Counterforce

### Wider Timing

Countermass perfect window:

- +0.04 seconds per rank

### Stored Impact

Countermass Impact storage:

- +10% per rank

### Brace Recovery

Successful Countermass reduces defensive cooldowns:

- 3% per rank

### Notable: Opposing Law

A perfect Countermass temporarily reverses the attacker’s local gravity, interrupting follow-up movement.

## Cluster: Point-Blank Ruin

### Inner Pressure

Damage within four meters:

- +5% per rank

### Close Gravity

Pull strength toward the Voidbringer:

- +7% per rank

### Contact Mass

Melee hits add:

- +2 Mass per rank to enemy anchors

### Notable: Bone Orbit

At least three nearby enemies cause Null Shards to orbit the Voidbringer automatically, damaging enemies at point-blank range.

## Cluster: Impact Body

### Terrain Sentence

Enemy terrain-collision damage:

- +10% per rank

### Heavy Arrival

Event Step arrival Impact:

- +8% per rank

### Broken Ground

Heavy impacts create short-lived fracture zones:

- Radius increased by 8% per rank

### Notable: Walking Disaster

Every third heavy impact causes a localized ground collapse that pulls enemies toward the impact point.

## Cluster: Living Center

### Self-Anchor Strength

Abilities treating the player as an anchor gain:

- +8% influence per rank

### Body Closure

Self-anchor Closure damage:

- +10% per rank

### Corpse Weight

Nearby corpses grant Personal Mass:

- +2 per corpse per rank

### Notable: Weight of Witnesses

Each nearby enemy and corpse increases the Voidbringer’s effective Mass.

The bonus disappears gradually after leaving the group.

---

# 14. Cross-discipline bridge passives

These smaller nodes connect disciplines and allow hybrid builds to function before obtaining a keystone.

## Event Horizon ↔ Redshift

### Curved Collapse

Projectiles released by collapsing an anchor curve toward another active anchor.

### Moving Geometry

Repositioning an anchor preserves its current Fold Line bonuses for two seconds.

### Orbital Accretion

Orbiting objects add Mass each time they complete a revolution.

## Event Horizon ↔ Hollow Form

### Centered Architecture

The Voidbringer can serve as one endpoint of a closed three-anchor shape.

### Body Accretion

Personal Mass contributes to nearby anchor loading.

### Internal Collapse

Enemy anchors deal increased damage when collapsed within melee range.

## Redshift ↔ Hollow Form

### Kinetic Flesh

Velocity Reserve increases melee Impact.

### Heavy Momentum

Personal Mass is partially converted into exit velocity during Event Step.

### Counterlaunch

Perfect Countermass grants a free short Periapsis around the attacker’s anchor.

---

# 15. Hybrid keystones

A player may purchase multiple hybrid keystones if requirements are met.

## Event Horizon + Redshift: Catapult Doctrine

Requirements:

- Eight Event Horizon points
- Eight Redshift points

Anchored normal enemies can be fired through Fold Lines.

They become living projectiles and inherit:

- Anchor Mass
- Travel speed
- Part of their remaining health as Impact

Bosses instead release a projected Mass copy.

## Event Horizon + Redshift: Closed Orbit

Requirements:

- Ten Event Horizon points
- Ten Redshift points

Projectiles cannot directly strike Critical anchored enemies.

They must orbit an anchor at least once.

In return:

- Each orbit greatly increases speed and damage
- The projectile cannot be destroyed during its first orbit
- Closure releases all orbiting projectiles

## Event Horizon + Hollow Form: Devouring Center

Requirements:

- Eight Event Horizon points
- Eight Hollow Form points

Ground anchors can no longer be placed.

The Voidbringer permanently counts as one anchor.

Benefits:

- Increased Personal Mass
- All Fold Lines connect through the player
- Closure on enemy anchors causes point-blank secondary implosions

## Event Horizon + Hollow Form: Collapsing Body

Requirements:

- Ten Event Horizon points
- Ten Hollow Form points

Self-anchor Closure:

- Damages the Voidbringer’s barrier
- Collapses every nearby enemy anchor
- Adds remaining Mass to Personal Mass
- Generates severe Instability

This creates explosive self-centered networks.

## Redshift + Hollow Form: Impact Event

Requirements:

- Eight Redshift points
- Eight Hollow Form points

Event Step no longer damages enemies along its path.

Instead:

- All compressed force is stored
- The next melee attack releases it
- Damage scales with distance traveled and targets crossed

## Redshift + Hollow Form: Kinetic Crucible

Requirements:

- Ten Redshift points
- Ten Hollow Form points

Velocity Reserve and Personal Mass become one combined resource.

Moving builds Mass.

Standing converts Mass into stored velocity.

The player cycles between:

- Heavy stationary preparation
- Violent high-speed release

---

# 16. Breach Laws

The player selects one Breach Law at level 20.

Each Law receives one mutation choice at level 36 and one apex at level 47.

## Law of Compression

During Breach:

- Enemies are pulled toward the nearest anchor
- Anchor pull strength increases
- Collisions load additional Mass

Clean Closure reward:

- The next anchor begins Dense

### Mutation A: Singular Priority

Critical anchors override all weaker anchors.

Everything nearby is drawn toward the strongest point.

### Mutation B: Shared Center

Enemies caught between multiple anchors are drawn toward the network’s combined center.

### Apex: Continental Pressure

During the final three seconds of Breach:

- Every active Fold Line acts as a pull surface
- Enemies are compressed into the geometry itself
- Clean Closure deals a final network-wide implosion

## Law of Inversion

During Breach:

- Pull abilities may be reactivated to become repulsions
- Fold Line force directions reverse
- Terrain impacts load increased Mass

Clean Closure reward:

- The next forced movement deals increased collision damage

### Mutation A: Violent Reversal

Reactivating a pull immediately launches affected enemies outward.

### Mutation B: Negative Center

Anchors repel enemies but pull projectiles toward themselves.

### Apex: Inverted World

Once per Breach, Closure on a Critical anchor reverses every active force simultaneously.

Orbit becomes launch.

Pull becomes blast.

Incoming projectiles are thrown back outward.

## Law of Orbit

During Breach:

- Enemies and projectiles circle anchors
- Orbital speed increases over time
- Releasing orbiting objects extends Breach slightly

Clean Closure reward:

- The next projectile or movement skill begins at maximum Velocity Reserve

### Mutation A: Tight System

Objects orbit closer, faster and deal repeated contact damage.

### Mutation B: Wide System

Objects orbit farther away, creating larger control zones and stronger release velocity.

### Apex: Terminal Revolution

Completing three full orbits marks an object Terminal.

When released:

- Projectiles pierce
- Normal enemies become unstoppable living ammunition
- Elites create impact shockwaves
- Bosses suffer major stagger

---

# 17. Grand Capstones

Grand Capstones unlock at level 46.

Requirements:

- Eighteen points in the associated discipline
- Only one Grand Capstone may be active

## Event Horizon capstones

### Black Sun Architect

Exactly three anchors form a **Black Structure**.

While the structure remains complete:

- Movement inside loads all three anchors
- Deaths distribute Mass evenly
- Fold Lines cannot be disrupted by normal enemies
- Closure may target the entire structure

Collapsing the structure:

- Begins at the weakest anchor
- Cascades toward the strongest
- Pulls everything toward the final point

This supports deliberate three-anchor architecture.

### One Final Point

Maximum anchors are reduced to one.

That anchor gains five Mass stages instead of three:

- Dormant
- Dense
- Critical
- Terminal
- Impossible

Benefits:

- Greatly increased influence
- Massive duration
- Unique skill behavior at Terminal and Impossible stages
- Closure becomes a major singular event

The player sacrifices geometry for one terrifying center.

### Common Grave Engine

Corpses may become permanent anchors until collapsed.

Corpse anchors:

- Do not count against the normal anchor maximum until they become Dense
- Gain Mass from nearby deaths
- Cannot move
- Can chain-collapse through other corpses

This enables battlefield burial networks and corpse-fed catastrophe builds.

## Redshift capstones

### No Rest Frame

The Voidbringer and enemies are treated as existing in relative motion.

Damage scales with velocity difference.

Additional effects:

- Standing enemies take increased damage from a moving Voidbringer
- Moving enemies take increased damage from stationary projectiles
- Opposing movement directions provide maximum benefit
- Full bonus can reach 55%

This capstone rewards reading motion rather than stacking generic speed.

### Redline Paradox

Every third compatible action within four seconds is repeated.

Compatible actions:

- Event Step
- Periapsis
- Null Shard
- Rail Collapse
- Vector Salvo
- Worldshear after movement

The repeated action:

- Originates from the previous position
- Deals 65% damage
- Generates no Instability
- Cannot itself trigger another repeat

### Orbital Execution System

All projectile skills may be held to enter orbit around the nearest anchor.

While orbiting:

- Projectiles accumulate speed
- Anchors accumulate Mass
- The player can release all orbiting objects simultaneously
- Excessive orbit duration risks forcing an uncontrolled release

This creates a full orbital weapons-platform playstyle.

## Hollow Form capstones

### The Unmovable Object

At maximum Personal Mass:

- The Voidbringer cannot use normal movement
- Cannot be displaced
- Gains major damage reduction
- Event Step range is doubled
- Event Step always produces a heavy arrival collapse

The character alternates between immovable preparation and impossible spatial relocation.

### Living Singularity

The Voidbringer permanently counts as a Dense self-anchor.

Benefits:

- Nearby light enemies are always slightly pulled inward
- Melee attacks load Personal Mass
- Closure can target the self-anchor
- Gravitic Skin pushes the self-anchor to Critical
- Zero-Range Collapse no longer drains enemy anchors

The player becomes the center of every encounter.

### Hostile Body

Gravitic Clamp can permanently hold one normal enemy until:

- Thrown
- Killed
- Replaced
- Used by a skill

The held enemy becomes a build component.

Its traits alter:

- Basic attacks
- Blocking
- Movement
- Mass Driver
- Dead Star

Elites provide reduced but stronger temporary traits.

This creates a brutal enemy-as-equipment playstyle.

---

# 18. Sample complete level-50 allocations

These validate that the 57-point budget creates distinct characters.

## Black Sun Architect

### Active skills

- Mass Brand: World Nail route — 4
- Convergence: False Center route — 4
- Black Meridian: Execution route — 4
- Accretion Field: Grave route — 4
- Event Step: Exchange route — 4
- Dead Star: Black Star route — 3

Active total: 23

### Passives and features

- Anchorcraft: 5
- Controlled Ruin: 5
- Closed Geometry: 6
- Accretion: 5
- Collapse Doctrine: 5
- Black Sun: 4
- Law of Compression mutation and apex: 2
- Black Sun Architect capstone: 1
- Remaining utility nodes: 1

Total: 57

Playstyle:

Build a controlled three-anchor enclosure, feed it corpses and movement, drag enemies through Black Meridian, then collapse the entire structure.

## Orbital Executioner

### Active skills

- Null Shard: Orbital route — 4
- Periapsis: Slingshot route — 4
- Trajectory Theft: Constellation route — 4
- Vector Salvo: Murder Orbit route — 4
- Event Step: Afterevent route — 4
- Dead Star: Red Orbit route — 3

Active total: 23

### Passives and features

- Fold Geometry: 4
- Momentum Reserve: 5
- Orbital Mechanics: 6
- Hostile Trajectory: 5
- Redline: 4
- Event Motion: 3
- Law of Orbit mutation and apex: 2
- Orbital Execution System capstone: 1
- Closed Orbit hybrid keystone: 1
- Utility: 3

Total: 57

Playstyle:

Capture enemy projectiles, build several orbital systems and release everything through carefully aligned Fold Lines.

## Living Singularity

### Active skills

- Gravitic Skin: Containment route — 4
- Mass Driver: Absolute Fist route — 4
- Countermass: Standing Law route — 4
- Zero-Range Collapse: Living Singularity route — 4
- Event Step: Exchange route — 4
- Dead Star: Star Vessel route — 3

Active total: 23

### Passives and features

- Manifold Integrity: 5
- Personal Mass: 6
- Counterforce: 5
- Point-Blank Ruin: 5
- Living Center: 5
- Impact Body: 3
- Law of Compression mutation and apex: 2
- Living Singularity capstone: 1
- Devouring Center keystone: 1
- Utility: 1

Total: 57

Playstyle:

Become the central anchor, absorb enemy impacts, drag entire groups into melee range and collapse the battlefield around the body.

## Kinetic Butcher

### Active skills

- Worldshear: Pressure Edge route — 4
- Event Step: Afterevent route — 4
- Velocity Theft: Perfect Theft route — 4
- Periapsis: Cutting Orbit route — 4
- Countermass: Violent Return route — 4
- Dead Star: Star Vessel or Red Orbit — 3

Active total: 23

### Passives and features

- Mass Dynamics: 5
- Momentum Reserve: 5
- Event Motion: 6
- Redline: 5
- Counterforce: 4
- Impact Body: 4
- Impact Event keystone: 1
- Kinetic Crucible keystone: 1
- No Rest Frame capstone: 1
- Law of Inversion mutation and apex: 2

Total: 57

Playstyle:

Steal motion, orbit anchors at extreme speed, store entire movement sequences inside the next Worldshear and counter enemy attacks with their own force.

## Mass-Body Artillery

### Active skills

- Mass Brand: Carrier route — 4
- Rail Collapse: Living Round route — 4
- Tidal Lock: Satellite route — 4
- Gravitic Clamp: Flesh Weapon route — 4
- Convergence: Dominant Center route — 4
- Dead Star: Red Orbit route — 3

Active total: 23

### Passives and features

- Mass Dynamics: 6
- Gravitational Authority: 5
- Orbital Mechanics: 5
- Impact Body: 5
- Hostile Trajectory: 3
- Catapult Doctrine: 1
- Law of Inversion mutation and apex: 2
- No Rest Frame capstone: 1
- Utility and defense: 6

Total: 57

Playstyle:

Use enemies as shields, orbital weapons and railgun ammunition. Enemy composition directly changes how the build fights.

---

# 19. Respec and experimentation rules

The tree is meant to encourage experimentation rather than punish it.

## Levels 1–20

- Passive refunds are free outside combat
- Active-skill mutation branches may be swapped freely
- Breach Laws are not yet permanently committed

## Levels 21–40

- Small resource cost for passive refunds
- Mutation swaps remain inexpensive
- Complete saved loadouts unlock through class quests

## Levels 41–50

- Grand Capstone changes require the Manifold Chamber
- Full respecs have a meaningful but reasonable cost
- No build should require restarting a character

The game should reward mastering choices, not hiding them behind punishment.

---

# 20. Implementation and readability requirements

## Anchor visuals

Every anchor must communicate:

- Carrier
- Mass stage
- Duration
- Whether Closure can currently target it
- Which Fold Lines connect to it
- Which Breach Law is affecting it

The player should never need to read tiny numbers during combat.

## Controller usability

Anchor Command must allow:

- Fast target cycling
- Directional selection
- Priority targeting
- Holding Closure for a brief tactical slowdown in solo play
- No tactical slowdown during multiplayer or competitive modes

## Enemy resistance

Bosses should resist displacement without ignoring the class mechanic.

Instead of full movement:

- Their body rotates
- Individual limbs shift
- Attacks are redirected
- Their stance meter takes Mass damage
- Nearby enemies move relative to them
- Anchors alter boss-area geometry

“Immune” is the lazy solution. Bosses should respond differently, not refuse interaction.

## Multiplayer rules

Each Voidbringer’s anchors use a distinct subtle visual signature.

Other players may interact with anchor effects but cannot normally collapse another Voidbringer’s anchors.

Two Voidbringers can create intersecting Fold Lines, enabling rare cooperative effects without merging their resources.

## Performance rules

The engine should limit:

- Three standard anchors per player
- Three active spatial seams
- One Accretion Field
- One Dead Star
- Eight standard orbiting hostile projectiles before visual compression
- Four simultaneous normal orbiting enemies

Additional objects may be represented through combined visual clusters rather than individual full-physics entities.

---

# 21. Voidbringer completion standard

The Voidbringer tree is successful when all of the following are true:

- A new player can build around Mass Brand and Closure without studying a guide.
- A melee player can ignore projectile mechanics without feeling incomplete.
- A projectile player can avoid becoming a stationary caster.
- An Event Horizon player can solve encounters through geometry.
- A Hollow Form player feels like a spatial catastrophe, not a barbarian with gravity-colored attacks.
- Breach is a state skilled players intentionally pursue.
- Bosses remain meaningfully affected by Mass and direction.
- Gear changes behavior rather than merely multiplying damage.
- Two level-50 Voidbringers can share only one active skill and both remain effective.
- Expert play is visibly different from beginner play without requiring more than six active skills.

The completed class identity is:

> **The Voidbringer does not cast destruction. It decides where weight, distance and direction are permitted to exist—and then revokes permission.**