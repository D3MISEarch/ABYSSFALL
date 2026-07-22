# ABYSSFALL — VOIDBRINGER COMBAT PRESENTATION BIBLE
## Controls, Frame Attacks, Animation Language, VFX, Audio, HUD and Moment-to-Moment Feel

Status: Approved  
Codex version: 1.0  
Implementation status: Design approved  
Last updated: 2026-07-22  
Canonical class ID: `voidbringer`

---

# 1. Combat-feel target

Voidbringer should feel like operating a damaged machine that bends physics faster than reality can repair itself.

The class should not feel:

- Floaty
- Wizard-like
- Overly elegant
- Constantly explosive
- Covered in unreadable effects
- Dependent on long casting animations
- Like every button produces the same black-purple shockwave

The class should feel:

- Heavy when manipulating Mass
- Sharp when cutting space
- Violently fast when using Redshift movement
- Deliberate when building geometry
- Dangerous when entering Breach
- Physically brutal even when attacking at range
- Precise enough for mastery
- Readable enough for a new player

The ideal sensation is:

> **You are not casting powers at enemies. You are operating the battlefield under unsafe pressure.**

---

# 2. Input philosophy

Voidbringer has deep mechanics, but the control scheme must remain clean.

The player should never need:

- A separate button for each anchor
- A radial menu during normal combat
- Complex directional combinations
- Manual Fold Line drawing
- More than six equipped active skills
- Constant lock-on management

Depth comes from what the player targets and when abilities are sequenced.

---

# 3. Standard combat controls

The exact button labels can change by platform, but the functional layout should remain consistent.

## Controller baseline

### Right trigger

Basic attack.

Behavior changes with equipped Manifold Frame.

### Left trigger

Aim modifier and Anchor Command.

Holding it:

- Highlights all active anchors
- Improves Mass Brand placement
- Allows precise Closure targeting
- Displays Fold Line geometry
- Slightly slows time in solo play only

### Face button 1

Active skill slot 1.

Recommended default:

- Mass Brand

### Face button 2

Active skill slot 2.

Recommended default:

- Event Step

### Face button 3

Active skill slot 3.

Player-selected offensive skill.

### Face button 4

Active skill slot 4.

Player-selected control or defensive skill.

### Right bumper

Active skill slot 5.

Usually a secondary offensive or movement skill.

### Left bumper

Active skill slot 6.

Usually Hard Vacuum, Countermass or another defensive tool.

### Right stick click

Closure.

Tap:

- Collapse highest-priority anchor

Hold briefly:

- Enter Anchor Command selection

### Left stick click

Target-lock toggle or contextual camera focus.

### Universal evade button

Standard dodge.

Voidbringer evade behavior changes slightly with Personal Mass.

### Both bumpers

Ultimate.

Prevents accidental activation.

---

# 4. Anchor Command

Anchor Command is the main interface between simple and advanced play.

## Tap Closure

Closure targets the best available anchor automatically.

Priority depends on context:

1. Anchor directly under reticle
2. Anchor on locked target
3. Critical enemy anchor
4. Critical terrain anchor
5. Dense enemy anchor
6. Oldest anchor

This makes casual play fast.

## Hold Closure

Holding Closure for 0.25 seconds enters Anchor Command.

In solo play:

- Time slows to 35%
- Active anchors become strongly outlined
- Fold Lines brighten
- Each anchor displays its current Mass stage
- Directional input cycles between anchors
- The Closure result preview appears

In multiplayer:

- No time slowdown
- Selection remains fast and directional
- Anchors receive stronger outlines

## Closure preview

The preview does not show exact damage numbers.

It shows:

- Implosion radius
- Pull or repulsion direction
- Expected Breach extension
- Whether Clean Closure conditions will be met
- Orbiting objects that will be released
- Nearby Fold Lines that will react

The player understands consequence without stopping to calculate.

---

# 5. Universal evade behavior

Voidbringer uses the standard AbyssFall evade, but Personal Mass modifies it.

## Low Personal Mass

- Fast directional step
- Medium distance
- Minimal recovery
- Slight spatial distortion

## Moderate Personal Mass

- Shorter distance
- Stronger shoulder impact
- Can shove light enemies
- More grounded animation

## Maximum Personal Mass

Normal evade becomes **Mass Shift**:

- Very short displacement
- Brief damage resistance
- Ground fractures at starting position
- Cannot pass through enemies
- Generates a small outward force

Event Step remains the class’s true long-range mobility.

This ensures heavy Hollow Form builds feel physically different without removing defensive options.

---

# 6. Basic attack system

Every Manifold Frame has:

- A three-step basic chain
- A held heavy attack
- A moving attack
- An evade attack
- A Closure follow-up
- A Breach variation

Basic attacks should remain useful throughout the game.

They generate positioning, Mass or momentum rather than serving only as filler.

---

# 7. Shear Frame attacks

## Rift Cleaver

### Combat identity

Measured, heavy spatial cuts.

It feels like each swing briefly removes a section of the enemy rather than merely cutting through flesh.

### Basic chain

#### Attack 1: Horizontal Sever

- Wide left-to-right cut
- 70% Weapon Power
- Moderate Impact
- Adds 3 Mass to anchored enemies

#### Attack 2: Returning Fracture

- Reverse upward cut
- 80% Weapon Power
- Pulls struck enemies slightly inward
- Strong against enemies displaced by attack 1

#### Attack 3: Missing Arc

- The blade vanishes during the swing
- The cut appears one meter beyond normal reach
- 115% Weapon Power
- Strong Impact
- Creates a brief spatial seam

The delay between the visual swing and distant cut should feel unsettling but remain readable.

### Held attack: Cleaving Absence

Charge for up to 1.1 seconds.

The blade widens into a dark spatial plane.

On release:

- Heavy forward cut
- Crosses all nearby Fold Lines
- Loads Mass based on charge time
- Full charge causes a short directional implosion

### Moving attack: Advancing Cut

- Short step forward
- Diagonal cleave
- Maintains movement momentum
- Strong opener after Event Step

### Evade attack: Reversal Slice

- Immediate backward or sideways cut
- Low damage
- High interruption
- Can sever weak projectiles

### Closure follow-up: Burial Stroke

Using basic attack within one second after Closure:

- Performs a downward cleave into the collapsing point
- Sends a narrow shock through the ground
- Damage scales with consumed Mass

### Breach variation

During Breach:

- The third basic attack occurs from the nearest anchor as well
- Anchor-originated cut deals 45% damage
- Both cuts load Mass independently

---

## Null Talons

### Combat identity

Rapid, predatory, aggressive.

The hands never hold solid claws. Shards flicker into place only during contact.

### Basic chain

#### Attack 1: Left Rend

- Fast diagonal claw
- 45% Weapon Power
- Adds 1 Mass

#### Attack 2: Right Rend

- Opposite diagonal
- 45% Weapon Power
- Adds 1 Mass

#### Attack 3: Twin Compression

- Both hands strike inward
- 80% Weapon Power
- Pulls small enemies between the claws
- Applies strong contact Mass

#### Attack 4: Shard Burst

- Rapid outward release
- 95% Weapon Power
- Fires two close-range fragments
- Gains damage from movement speed

Null Talons use a four-hit chain to emphasize speed.

### Held attack: Predatory Fold

The Voidbringer crouches briefly and folds to a nearby anchored enemy.

- Short automatic gap close
- Crosses through target
- Performs twin back cut
- Cannot target distant terrain anchors

### Moving attack: Raking Pursuit

- Two running swipes
- Maintains full movement
- Gains Mass when striking enemies moving away

### Evade attack: Low Orbit

- Shards sweep around the body at knee height
- Trips light enemies
- Builds Personal Mass from contact

### Closure follow-up: Feeding Talons

After Closure:

- Talons absorb loose fragments
- Gain increased speed for three seconds
- First strike brands an unanchored target

### Breach variation

During Breach:

- Every fourth attack leaves an afterimage
- Afterimage repeats the second attack
- Attack chain no longer resets after Event Step

---

## Event Maul

### Combat identity

Slow, obscene impact.

The maul does not visibly travel through a full arc. It materializes at the point where force is required.

### Basic chain

#### Attack 1: Weight Drop

- Short overhead strike
- 95% Weapon Power
- High stagger
- Small ground fracture

#### Attack 2: Counterweight Sweep

- Wide side swing
- 110% Weapon Power
- Launches light enemies sideways

#### Attack 3: Terminal Impact

- Maul disappears
- Reappears inside the impact point
- 165% Weapon Power
- Temporarily increases target Mass
- Strong terrain-collision setup

### Held attack: Impossible Weight

Charge while stationary.

Personal Mass increases during charge.

On release:

- Massive downward impact
- Damage scales with Personal Mass
- Creates a temporary terrain anchor
- Full charge briefly prevents normal movement

### Moving attack: Dragging Head

- Maul scrapes across the ground
- Builds stored force while moving
- Release produces an upward launch

### Evade attack: Counterweight Slam

- Short hop or Mass Shift
- Maul strikes behind the player
- Knocks pursuers toward active anchors

### Closure follow-up: Coffin Strike

Strike a collapsing point:

- Collapse becomes directional
- Force travels downward and outward
- Strong against armored enemies

### Breach variation

During Breach:

- Each heavy hit creates a low-damage echo impact one second later
- Echo impact pulls before striking

---

## Meridian Blade

### Combat identity

Precise Fold Line duelist.

Long reach, thinner hitboxes and less raw Impact.

### Basic chain

#### Attack 1: Line Cut

- Long thrusting slash
- 65% Weapon Power
- Increased reach

#### Attack 2: Cross Meridian

- Diagonal cut
- 70% Weapon Power
- Extends along nearest Fold Line

#### Attack 3: Divided Horizon

- Two shards separate
- A blade forms between them
- 105% Weapon Power
- Strikes enemies between both points

### Held attack: Meridian Draw

Aim along one active Fold Line.

Release to cut its full length.

- Damage increases with line length
- Reduced close-range damage
- Strong anchor loading at endpoints

### Moving attack: Sliding Division

- Fast lateral step
- Horizontal line cut
- Excellent while circling groups

### Evade attack: Backward Meridian

- Leaves a thin line where the player stood
- Line cuts pursuing enemies after a short delay

### Closure follow-up: Final Division

After Closure:

- Nearest surviving Fold Line briefly becomes a damaging Meridian
- Basic attack teleports its hit along that line

### Breach variation

During Breach:

- Every basic attack briefly intensifies the nearest Fold Line
- Striking from inside closed geometry causes attacks from two edges

---

# 8. Vector Array attacks

## Needle Array

### Combat identity

Rapid spatial marksmanship.

Projectiles should feel like invisible needles punching through sections of space.

### Basic chain

Needle Array uses a continuous three-shot pattern.

#### Shot 1

- 38% Weapon Power
- High speed
- Low Impact

#### Shot 2

- 38% Weapon Power
- Curves slightly toward anchors

#### Shot 3

- 55% Weapon Power
- Penetrates one enemy
- Gains a bonus after crossing a Fold Line

Holding the trigger continues the pattern.

### Held attack: Needle Rail

Charge several shards into one narrow shot.

- High penetration
- Increased Fold Line scaling
- Low area damage
- Full charge creates a temporary line along its path

### Moving attack

Needle Array can fire at 85% movement speed.

Accuracy decreases slightly while moving unless under high Velocity Reserve.

### Evade attack: Parting Needle

- Fires one shard from the starting position
- One shard from the ending position
- Both aim at the same target

### Closure follow-up: Fragment Release

Closure causes the next three basic shots to originate from the collapsed anchor’s position.

### Breach variation

During Breach:

- Shot 3 originates from both player and nearest anchor
- Projectiles bend aggressively around obstacles

---

## Orbital Array

### Combat identity

Controlled buildup and release.

The player feels like assembling a weapon system around the battlefield.

### Basic attack

Each trigger press launches one shard into orbit around the nearest suitable anchor.

Maximum basic orbit:

- Three shards by default
- Modified by gear

Pressing the trigger while at maximum orbit releases the oldest shard.

### Held attack: Orbital Discharge

Hold to select an anchor.

Release all shards orbiting that anchor toward the aimed target.

Damage scales with:

- Orbit duration
- Angular speed
- Anchor Mass
- Fold Lines crossed after release

### Moving attack

The player may continue loading orbit while moving.

Shards launched during a sprint enter wider, faster orbit.

### Evade attack: Orbit Transfer

Evading near an anchor transfers one orbiting shard to the next anchor passed.

### Closure follow-up: Funeral Release

Closure automatically releases all orbiting shards before the anchor implodes.

### Breach variation

During Breach:

- Orbit speed increases continuously
- Unreleased shards become unstable
- Shards may complete additional attack passes before disappearing

---

## Vector Cannon

### Combat identity

Slow spatial artillery.

Every shot should sound and feel like reality was punched through a tube.

### Basic attack

#### Shot 1: Condensed Round

- 105% Weapon Power
- High penetration
- High Instability
- Moderate recoil

#### Shot 2: Stabilizing Round

- 75% Weapon Power
- Lower Instability
- Adds Mass to anchors crossed

The cannon alternates between these two shots.

### Held attack: Zero-Length Shot

Charge to remove the distance between muzzle and target point.

At full charge:

- Projectile appears at target immediately
- Damage is based on normal travel distance
- Shot leaves a spatial channel behind
- Severe Instability generation

### Moving attack

Cannot fire while sprinting.

Walking fire is possible but has greater recoil and reduced accuracy.

### Evade attack: Recoil Step

- Fire a short-range blast opposite the evade direction
- Blast launches the player slightly
- Stores Velocity Reserve

### Closure follow-up: Collapsed Ammunition

Closure loads condensed Mass into the cannon.

Next shot gains:

- Increased Impact
- Larger projectile
- Carrier-specific effects

### Breach variation

During Breach:

- Condensed shots create miniature secondary trajectories
- Each Critical anchor emits a reduced copy toward the same target

---

## Scatter Manifold

### Combat identity

Aggressive mid-range space shotgun.

Strong at controlling groups without becoming a traditional firearm.

### Basic attack

Fire five shards in a fan.

- 24% Weapon Power each
- Strong close-range total
- Each shard may add Mass separately
- Wide recoil distortion

### Held attack: Converging Spread

Hold to narrow the fan.

At full focus:

- All shards converge at one point
- Strong single-target damage
- Point becomes a temporary micro-collapse

### Moving attack

Maintains full movement but spread widens.

### Evade attack: Rear Scatter

- Fires backward during forward evade
- Excellent for retreating while loading pursuers

### Closure follow-up: Shard Coffin

After Closure:

- Next blast forms around the target from several directions
- Shards converge inward rather than traveling outward

### Breach variation

During Breach:

- Each shot briefly orbits nearby anchors before striking
- Point-blank blasts produce stronger repulsion or pull depending on Breach Law

---

# 9. Well Core attacks

## Accretion Core

### Combat identity

Low direct damage, constant anchor feeding.

### Basic attack

Pulse from the nearest active anchor.

- 42% Weapon Power
- Small pull
- Adds 3 Mass
- If no anchor exists, pulse originates from the player

### Three-pulse pattern

#### Pulse 1

Normal Mass pulse.

#### Pulse 2

Wider pull pulse.

#### Pulse 3

Compressed pulse dealing 65% Weapon Power and adding 6 Mass.

### Held attack: Feed the Center

Channel toward one anchor.

- Adds Mass over time
- Pulls loose projectiles and corpses
- Generates escalating Instability
- Cannot directly push beyond Critical without specific effects

### Moving attack

Player movement does not interrupt anchor-originated basic attacks.

### Evade attack: Shed Mass

Evading causes the previous pulse to repeat at reduced strength.

### Closure follow-up: Inheritance

The next basic pulse originates from the surviving anchor with the greatest Mass and inherits part of the collapsed effect.

### Breach variation

During Breach:

- Pulses originate from all anchors at reduced power
- Repeated pulses create overlapping pull rhythms

---

## Collapse Core

### Combat identity

Marks anchors for deliberate execution.

### Basic attack

Fire a low-damage compression mark.

- 30% Weapon Power
- Applies one **Failure Stack**
- Maximum five stacks per anchor

Closure consumes Failure Stacks for:

- Increased damage
- Larger radius
- More Instability removal

### Held attack: Premature Failure

Consume all Failure Stacks without destroying the anchor.

- Produces a small implosion
- Removes some Mass
- Allows controlled damage without full Closure

### Moving attack

Marks can be fired while walking.

### Evade attack: Failure Echo

The last marked anchor receives one additional stack after the evade.

### Closure follow-up: Secondary Failure

After collapsing a fully marked anchor:

- Nearest anchor gains two Failure Stacks
- Small chain implosion occurs

### Breach variation

During Breach:

- Failure Stacks build faster
- Maximum stacks increase
- A fully marked Critical anchor emits warning pulses before catastrophic Closure

---

## Geometry Core

### Combat identity

Distributed line-based attacks.

### Basic attack

Fire along the nearest Fold Line.

If no Fold Line exists:

- Weak direct pulse from player

With one or more Fold Lines:

- Attack travels from one endpoint to another
- Deals damage along the full line
- Can strike enemies behind cover

### Three-attack pattern

#### Line Pulse

Basic line damage.

#### Reversed Pulse

Travels opposite direction.

#### Triangle Pulse

If three anchors exist, attacks along all three sides at reduced damage.

### Held attack: Selective Geometry

Hold aim to select a Fold Line.

Release sends a stronger attack along that line.

### Moving attack

The player can move independently while attacks originate from anchors.

### Evade attack: Broken Angle

Evading causes the selected line to bend briefly through the player’s new position.

### Closure follow-up: Missing Edge

After one anchor collapses:

- The remaining two anchors keep a temporary Fold Line
- Basic attacks continue along the impossible line for two seconds

### Breach variation

During Breach:

- Fold Lines gain thickness
- Basic attacks can strike enemies near the line, not only touching it
- Triangle Pulse gains stronger inward pressure

---

## Vacancy Core

### Combat identity

Positioning and empty-space control.

### Basic attack

Create a small pulse of absence at target point.

- 32% Weapon Power
- Low direct damage
- Pulls enemies slightly
- Lasts 0.8 seconds

Only two basic Vacancies may exist simultaneously.

### Held attack: Hollow Point

Charge one larger Vacancy.

- Stronger pull
- Slows projectiles
- Can be targeted by certain movement effects
- High Instability

### Moving attack

Can place Vacancies while moving.

### Evade attack: Left Behind

Evading leaves a Vacancy at the starting point.

### Closure follow-up: Collapse Into Nothing

After Closure:

- Next Vacancy inherits part of the Collapse pull
- Enemies entering it are briefly compressed

### Breach variation

During Breach:

- Vacancies connect to nearby anchors with temporary Fold Lines
- Enemies can be pulled through one Vacancy and released from another

---

# 10. Six-slot loadout philosophy

A complete loadout should usually contain:

- One anchor-generation method
- One Closure or Mass payoff
- One movement tool
- One defensive or counter tool
- One build-specific engine
- One flexible damage or control ability

Closure itself is always available separately.

The player should not be required to equip:

- Mass Brand
- Event Step
- Hard Vacuum

But the class must provide replacements through gear, passives or alternate abilities.

---

# 11. Recommended beginner loadout

## Purpose

Teach the full class loop without overwhelming the player.

### Slot 1: Mass Brand

Creates anchors.

### Slot 2: Event Step

Teaches anchor-based movement.

### Slot 3: Worldshear

Simple close-range damage and Fold Line interaction.

### Slot 4: Convergence

Teaches enemy collision and geometry.

### Slot 5: Crush Point

Teaches deliberate anchor payoff.

### Slot 6: Hard Vacuum

Provides survivability and force storage.

### Ultimate: Dead Star

Straightforward battlefield control.

## Beginner loop

1. Brand two enemies.
2. Use Convergence.
3. Worldshear through the Fold Line.
4. Collapse one anchor.
5. Event Step to the survivor.
6. Use Hard Vacuum when pressured.
7. Detonate remaining anchor.

This sequence teaches every core mechanic naturally.

---

# 12. Black Sun Architect loadout

### Frame

Geometry Core

### Slot 1

Mass Brand — World Nail

### Slot 2

Event Step — Exchange or base utility

### Slot 3

Convergence — False Center

### Slot 4

Black Meridian — Execution Meridian

### Slot 5

Accretion Field — Grave Accretion

### Slot 6

Hard Vacuum — Vacancy

### Ultimate

Dead Star — Black Star

## Moment-to-moment feel

- Establish triangle
- Herd enemies inside
- Feed Mass through deaths and movement
- Drag enemies through lethal lines
- Collapse the network in sequence

The player feels methodical and oppressive.

---

# 13. Orbital Executioner loadout

### Frame

Orbital Array

### Slot 1

Mass Brand — Carrier Brand

### Slot 2

Periapsis — Slingshot

### Slot 3

Trajectory Theft — Hostile Constellation

### Slot 4

Vector Salvo — Murder Orbit

### Slot 5

Tidal Lock — Captive System

### Slot 6

Event Step — Afterevent

### Ultimate

Dead Star — Red Orbit

## Moment-to-moment feel

- Build several orbiting systems
- Steal enemy projectiles
- Circle anchors constantly
- Release stored objects at the correct angle
- Chain movement through collapsing geometry

The player feels fast, surgical and barely contained.

---

# 14. Living Singularity loadout

### Frame

Event Maul

### Slot 1

Gravitic Skin — Containment Armor

### Slot 2

Event Step — Exchange

### Slot 3

Mass Driver — Absolute Fist

### Slot 4

Countermass — Standing Law

### Slot 5

Zero-Range Collapse — Living Singularity

### Slot 6

Gravitic Clamp — Deadlock

### Ultimate

Dead Star — Star Vessel

## Moment-to-moment feel

- Enter the center of combat
- Absorb force
- Increase Personal Mass
- Pin heavy enemies
- Drag everything inward
- Release point-blank catastrophe

The player feels like a walking disaster rather than a conventional tank.

---

# 15. Kinetic Butcher loadout

### Frame

Null Talons or Meridian Blade

### Slot 1

Mass Brand — Carrier Brand

### Slot 2

Event Step — Afterevent

### Slot 3

Velocity Theft — Perfect Theft

### Slot 4

Periapsis — Cutting Orbit

### Slot 5

Worldshear — Pressure Edge

### Slot 6

Countermass — Violent Return

### Ultimate

Dead Star — Red Orbit or Star Vessel

## Moment-to-moment feel

- Steal motion
- Accelerate around anchors
- Cross enemy groups
- Store movement inside the next cut
- Repeat attacks from prior positions
- Punish interruption with counters

The player feels ferocious and technical.

---

# 16. One Final Point loadout

### Frame

Collapse Core

### Slot 1

Mass Brand — Terminal Brand

### Slot 2

Accretion Field — Grave Accretion

### Slot 3

Crush Point — Internal Failure

### Slot 4

Hard Vacuum — Force Vault

### Slot 5

Convergence — Dominant Center

### Slot 6

Event Step — utility

### Ultimate

Dead Star — Black Star

## Moment-to-moment feel

- Build one terrifying anchor
- Feed it through the entire encounter
- Protect and reposition around it
- Decide whether to spend Mass early or gamble for more
- Collapse it at the perfect moment

The player feels patient, dangerous and deliberate.

---

# 17. Mass-Body Artillery loadout

### Frame

Scatter Manifold or Vector Cannon

### Slot 1

Mass Brand — Carrier Brand

### Slot 2

Tidal Lock — Satellite Body

### Slot 3

Rail Collapse — Living Round

### Slot 4

Gravitic Clamp — Flesh Weapon

### Slot 5

Convergence — Dominant Center

### Slot 6

Velocity Theft — Perfect Theft

### Ultimate

Dead Star — Red Orbit

## Moment-to-moment feel

- Identify the heaviest enemy
- Use smaller enemies as ammunition
- Orbit a body
- Fire it through groups
- Hold explosive enemies as temporary weapons
- Turn boss summons against their owner

The player feels inventive and vicious.

---

# 18. Animation language

Voidbringer animation should follow a strict physical language.

## Anchor placement

The Null Shard should not fly like a magical dart.

It should:

- Snap into alignment
- Disappear for several frames
- Reappear already embedded
- Cause the target’s body or surface to deform around it

Impact should feel invasive.

## Pulls

Enemies should not slide cleanly across the ground.

Their movement should include:

- Feet losing traction
- Limbs trailing behind the torso
- Armor plates vibrating
- Blood and loose clothing pulling first
- Sudden acceleration near the endpoint

## Repulsion

Repulsion begins with compression.

The enemy should briefly fold inward before launching outward.

## Orbit

Orbiting enemies retain some agency:

- Swing weapons while spinning
- Attempt to stabilize
- Fire in changing directions
- Collide awkwardly
- Scrape against terrain

They are not frozen dolls attached to an invisible circle.

## Collapse

Collapse uses three stages:

1. **Compression**
   - Sound narrows
   - Air and debris pull inward
   - Target silhouette stretches
2. **Absence**
   - One to three nearly silent frames
   - Target center becomes visually empty
3. **Consequence**
   - Blood, debris and pressure erupt according to Collapse type

This rhythm makes Collapse recognizable without relying on screen-filling explosions.

---

# 19. Movement animation

## Event Step

Event Step should never look like a standard teleport.

Sequence:

1. The destination and origin visually lean toward one another.
2. The space between both points shortens.
3. The Voidbringer performs one physical step.
4. The world unfolds behind them.
5. Enemies caught in the path slam toward the midpoint.

The character moves normally. The world does the impossible part.

## Periapsis

The Voidbringer should visibly fight centrifugal force:

- Torso angled inward
- Feet skidding or briefly leaving the ground
- Null Shards trailing behind
- Sudden forward snap at release

## High Personal Mass

Movement becomes:

- Shorter
- Heavier
- More deliberate
- Ground-reactive

The character should never become comically slow.

## Redshift movement

At high velocity:

- Afterimages do not copy the entire model
- Only key body fragments remain visible
- Weapon and harness echoes appear at displaced intervals
- Blood and debris follow curved paths

---

# 20. Hit reactions

Voidbringer’s satisfaction depends heavily on enemies reacting correctly.

## Light enemies

Can be:

- Dragged fully
- Launched
- Spun in orbit
- Used as projectiles
- Folded into groups
- Crushed against surfaces

## Medium enemies

Can be:

- Shifted several meters
- Rotated
- Staggered through collision
- Partially orbited
- Dragged by stronger anchors

## Heavy enemies

Respond through:

- Foot sliding
- Body rotation
- Limb displacement
- Armor buckling
- Stance damage
- Nearby object movement

## Bosses

Bosses should never display “IMMUNE” to the class fantasy.

Instead:

- Pulls rotate or lean the boss
- Anchors shift attack origin
- Fold Lines cut appendages or armor
- Mass attacks damage stance
- Orbit effects alter projectiles around them
- Event Step changes player-to-boss geometry
- Collapse damages specific body regions

A giant boss may remain in place while the entire arena moves relative to it.

---

# 21. Hitstop and impact timing

Voidbringer should use selective hitstop.

Too much hitstop makes spatial abilities feel like conventional melee attacks.

## Light spatial cuts

- 20–35 milliseconds

## Heavy Worldshear or Mass Driver

- 60–90 milliseconds

## Enemy collision

- 70 milliseconds on first body
- Additional shorter pulses for secondary bodies

## Critical Closure

- Brief pre-impact slowdown
- Near-silent absence frame
- 80–110 millisecond consequence hitstop

## Dead Star detonation

- No full freeze
- Time compresses gradually during the final pull
- Sudden restoration at detonation

The player should feel pressure building rather than seeing constant freeze frames.

---

# 22. Camera behavior

Camera effects must add weight without causing nausea.

## Standard Collapse

- Subtle inward camera compression
- Minimal shake
- Quick recovery

## Heavy collision

- Directional shake based on impact angle
- Stronger if terrain is involved

## Event Step

- Camera remains primarily attached to player
- Background briefly compresses
- Avoid rapid snap zoom

## Dead Star

- Slightly wider camera
- Star remains visible when practical
- Camera should not continuously tilt or orbit

## Maximum Personal Mass

- Camera lowers slightly
- Field of view narrows subtly
- Footstep vibration increases

Accessibility settings must allow:

- Reduced shake
- Reduced field-of-view change
- Reduced distortion
- Reduced hitstop
- Static Event Step camera

---

# 23. Visual-effects language

## Core colors

Voidbringer should not be locked to one neon color.

Primary visuals:

- Black reflective Null material
- Distorted environmental colors
- Pale desaturated edge light
- Deep red only during severe Instability
- White pressure lines during Clean Closure

## Instability stages

### 0–24

- Stable harness
- Minimal distortion
- Null Shards close to body

### 25–49

- Shards drift farther
- Small afterimages
- Light bends around hands

### 50–74

- Harness seams separate
- Background warping becomes visible
- Fold Lines brighten

### 75–99

- Body occupies slightly different positions
- Red-shifted edges appear
- Environmental debris begins orbiting
- Audio develops low interference

### Breach

- Character silhouette splits into offset versions
- Anchors become visually dominant
- Fold Lines look physically dangerous
- Spatial effects gain sharp black voids
- No generic aura surrounding the entire character

---

# 24. Anchor visual states

## Dormant

- Small embedded black shard
- Thin distortion ring
- Quiet low pulse

## Dense

- Larger distortion field
- Loose debris moves toward anchor
- Carrier posture subtly warps
- Deeper pulse

## Critical

- Surface folds around the anchor
- Blood or particles move against gravity
- Strong rhythmic pressure sound
- Fold Lines become visibly tense
- Anchor threatens to collapse without looking like a bomb timer

## Impossible Mass

Used by specific builds.

- Anchor center becomes visually absent
- Environment behind it is no longer visible
- Nearby geometry bends severely
- Sound loses high frequencies
- HUD warns through shape, not flashing red text

---

# 25. Fold Line readability

Fold Lines need to communicate function without filling the screen.

## Default state

- Very thin environmental distortion
- Only clearly visible near player or reticle

## When targeted

- Brightened edges
- Flow direction becomes visible
- Endpoint Mass stages display

## When dangerous

- Black Meridian becomes wider and sharper
- Small fragments travel along direction of force
- Enemy-crossing damage zone becomes readable

## When part of closed geometry

- Interior receives faint pressure texture
- Edges pulse in sequence
- No giant floor decal covering the arena

Players should see the geometry, not a glowing triangle painted on the ground.

---

# 26. Breach audiovisual sequence

Entering Breach should be one of the class’s signature moments.

## 90 Instability warning

- Harness emits a low double pulse
- Screen edges distort slightly
- Anchors briefly flicker

## 100 Instability

Sequence lasting roughly 0.6 seconds:

1. Ambient audio cuts sharply.
2. Null Shards stop moving.
3. Character silhouette splits.
4. Harness opens.
5. Fold Lines snap into visibility.
6. Low-frequency pressure returns violently.

The sequence should not remove player control for long.

## During Breach

- Audio gains doubled environmental reflections
- Some footsteps occur before the animation
- Anchor sounds shift based on Breach Law
- Music may add a temporary low rhythmic layer
- UI pulses with the draining Instability ring

## Clean Closure

- Pressure suddenly stabilizes
- White fracture lines seal across the harness
- Audio returns cleanly
- Barrier appears as bent space rather than a glowing bubble

## Spatial Recoil

- Character position snaps slightly
- Shards fall out of alignment
- Movement feels heavy
- Audio becomes dull and compressed
- No cartoon stun stars or exaggerated wobbling

---

# 27. Breach Law presentation

## Law of Compression

Visual behavior:

- Dust and blood move toward anchors
- Fold Lines bow inward
- Enemy bodies compress slightly
- Deep pressure audio

The player should feel the whole arena tightening.

## Law of Inversion

Visual behavior:

- Pull effects briefly fold inward before exploding outward
- Fold Lines reverse their particle flow
- Shards rotate in opposite directions
- Audio includes reversed impact tails

The world feels physically incorrect, not merely explosive.

## Law of Orbit

Visual behavior:

- Debris curves around anchors
- Projectiles leave circular distortion trails
- Enemy orientation changes constantly
- Audio uses accelerating rotational pulses

The battlefield feels like a violent mechanical system.

---

# 28. Sound design

Voidbringer should have one of the most recognizable sound identities in the game.

Avoid:

- Sparkly magic
- Generic bass drops on every hit
- Constant metallic whooshes
- Overused cosmic choir sounds
- Sci-fi laser effects

## Core sound materials

Use combinations of:

- Strained metal
- Concrete under pressure
- Submarine hull groans
- Bowed steel
- Reversed impact transients
- Deep breath pulled through machinery
- Stone scraping without visible movement
- Low-frequency air displacement
- Sudden total silence

## Mass Brand

- Sharp mechanical puncture
- Brief sucking sound
- Deep pulse after embedding

## Fold Line

- Quiet tension wire
- Low distant hum
- Sharper tone as Mass difference increases

## Event Step

- Space inhaling
- One physical footstep
- Delayed environmental crack behind player

## Collision

- Actual enemy-material sound
- Armor, bone, flesh or stone
- Followed by pressure consequence

## Closure

- Increasing inward suction
- Silence
- Dense wet or structural consequence depending on carrier

## Dead Star

- Distant hull groan
- Layered environmental absorption
- No triumphant musical blast
- Final detonation should feel like pressure leaving the room too quickly

---

# 29. Music interaction

Voidbringer abilities may subtly interact with the combat score.

During Breach:

- Low percussion can synchronize with anchor pulses
- Clean Closure may briefly remove one musical layer before it returns
- Dead Star can filter high frequencies during its final stage
- Spatial Recoil may distort the score for one beat

This should remain subtle.

Gameplay audio must never depend on music being enabled.

---

# 30. HUD architecture

The Voidbringer HUD should provide information in layers.

## Instability ring

Located around the class portrait or central class indicator.

Shows:

- Current Instability
- Breach threshold
- High-risk zone above 85
- Breach duration once active
- Projected Spatial Recoil danger

No large mana orb is needed.

## Anchor indicators

Three compact anchor symbols.

Each shows:

- Carrier icon
- Mass stage
- Remaining duration
- Whether it is targeted
- Whether orbiting objects are attached
- Whether it is part of closed geometry

Example carrier symbols:

- Enemy silhouette
- Terrain spike
- Corpse mark
- Self symbol
- Vacancy circle
- Orbit ring

## Fold geometry miniature

When holding Anchor Command, a small network diagram appears near the reticle.

It shows:

- Anchor connections
- Relative Mass
- Selected Closure target
- Closed-shape status

It should resemble a functional tactical diagram, not a mini-map.

## Personal Mass meter

Only appears when relevant.

Used by:

- Gravitic Skin
- Hollow Form passives
- Specific Harnesses
- Star Vessel

It appears beneath health as a segmented weight bar.

## Velocity Reserve

Only appears when generated.

Displayed as a directional arc that fills according to stored momentum.

## Dead Star meter

Appears only while Dead Star is active.

Shows three visible stages:

- Forming
- Dense
- Terminal

No exact numerical Mass required.

---

# 31. Status icons

Voidbringer-specific statuses should use clear names and symbols.

## Anchored

Target carries a Mass Anchor.

## Dense

Anchor has reached Dense stage.

## Critical

Anchor has reached Critical stage.

## Compressed

Target is currently being pulled or spatially reduced.

## Orbiting

Target or projectile is locked into orbit.

## Velocity Reserve

Player has stored movement force.

## Personal Mass

Player has increased effective weight.

## Breach

Containment is open.

## Clean Closure Ready

Current conditions can produce a Clean Closure.

## Spatial Recoil

Containment has closed improperly.

## Divided

Target is primed for Black Meridian execution.

## Tidal Lock

Target is bound to an orbital path.

Icons should communicate state without requiring players to memorize a wall of text.

---

# 32. Damage-number behavior

Damage numbers should not overwhelm the geometry.

## Standard attacks

Use normal damage-number rules.

## Fold Line damage

Numbers appear near the line’s midpoint or combine into one value over a short interval.

## Orbit damage

Repeated contact damage combines into rolling totals.

## Collision damage

Display one prominent Impact value followed by smaller secondary values.

## Closure

Use one strong number for direct collapse and smaller values for secondary debris or chain effects.

## Dead Star

Accumulate damage during pull and display a final major total at detonation if the player enables combined numbers.

Players can choose:

- Full numbers
- Combined numbers
- Critical-only
- Status-only
- No damage numbers

---

# 33. Enemy telegraph protection

Voidbringer effects must not hide enemy attacks.

Rules:

- Fold Lines become translucent over major enemy telegraphs.
- Dead Star pull fields cannot cover danger indicators.
- Black Meridian visually thins when crossing boss attack zones.
- Orbiting projectiles compress into grouped visuals near the camera.
- Critical anchors on large enemies move to readable body positions.
- Distortion must never obscure unblockable-attack colors or symbols.

A visually powerful class cannot come at the expense of fair combat.

---

# 34. Multiplayer readability

Other players need to understand what Voidbringer is doing without seeing the full private HUD.

## Other players can see

- Anchor positions
- Critical Mass state
- Major Fold Lines
- Black Meridian
- Dead Star
- Enemy orbit paths
- Collapse warning
- Breach state

## Other players do not need to see

- Exact anchor timers
- Clean Closure conditions
- Velocity Reserve
- Personal Mass numerical state
- Closure target preview
- Full Fold geometry diagram

## Co-op interactions

Other players can exploit Voidbringer control.

Examples:

- Strike enemies while Convergence groups them
- Trigger effects on enemies passing through Black Meridian
- Use orbiting enemies as predictable targets
- Detonate environmental hazards pulled by anchors
- Attack enemies during Dead Star compression

The Voidbringer should create opportunities without becoming mandatory support.

---

# 35. Accessibility requirements

Voidbringer uses distortion heavily, so accessibility cannot be an afterthought.

## Visual settings

- Distortion intensity
- Screen shake intensity
- Breach flicker reduction
- Reduced afterimages
- Simplified orbit trails
- High-contrast anchor outlines
- Fold Line thickness
- Critical-anchor pattern overlay
- Colorblind-independent Mass stages

## Audio settings

- Anchor warning volume
- Breach warning volume
- Closure cue volume
- High-Instability warning option
- Reduced low-frequency pressure

## Input settings

- Closure tap priority customization
- Anchor Command hold duration
- Automatic anchor cycling
- Optional target snap
- Toggle or hold aim modifier
- Simplified Event Step targeting
- Separate sensitivity while using Anchor Command

## Cognitive readability

Optional interface assistance:

- Recommended Closure target
- Clean Closure notification
- Anchor-expiration warning
- Breach tutorial reminders
- Simplified Fold Line display

Experts can disable these.

---

# 36. Tutorial presentation

Voidbringer should not begin with every system active.

## First combat room

Teach:

- Mass Brand
- Closure

One enemy and one terrain surface.

## Second room

Teach:

- Two anchors
- Pulling enemies together
- Collision

## Third room

Teach:

- Event Step
- Fold Lines

## First mini-boss

Teach:

- Bosses resist movement differently
- Anchors still affect stance and attack direction

## First Manifold Trial

Teach:

- Three anchors
- Clean replacement
- Basic geometry

## Breach Trial

Player is intentionally pushed to 100 Instability.

The game pauses only once to explain:

> **Breach increases your power. Collapse your anchors before containment closes.**

The rest is learned through play.

---

# 37. First-hour feel

The class should feel capable immediately.

Within the first hour, the player should experience:

- Pulling two enemies together
- Launching one enemy into another
- Folding across the battlefield
- Cutting along a Fold Line
- Collapsing an anchor inside an enemy
- Triggering one uncontrolled Breach
- Successfully performing one Clean Closure

The player should already say:

> “Oh, this class can do some disgusting stuff.”

They should not yet understand how deep the system goes.

---

# 38. Ten-hour feel

By ten hours, the player should begin recognizing:

- Which enemies make good anchors
- When terrain anchors are superior
- How enemy weight changes collision
- Which Fold Line angles improve attacks
- How to enter Breach intentionally
- When to leave a Critical anchor active
- How Frame choice changes the basic combat rhythm

The player stops reacting and begins constructing fights.

---

# 39. Endgame feel

At mastery, combat should look choreographed without being scripted.

An expert Voidbringer may:

1. Brand an elite and a wall.
2. Use Periapsis to build velocity.
3. Capture an incoming projectile.
4. Exchange positions with the elite.
5. Redirect the projectile through the Fold Line.
6. Launch a smaller enemy into the elite.
7. Enter Breach intentionally.
8. Collapse the wall anchor.
9. Use the released Mass to empower Worldshear.
10. Achieve Clean Closure while already setting the next anchor network.

A new player sees chaos.

The expert sees a precise physical sequence.

---

# 40. Combat personality by build

## Black Sun Architect

Feels:

- Patient
- Controlling
- Oppressive
- Calculated

Visual signature:

- Stable geometry
- Long Fold Lines
- Enemies trapped inside structures
- Massive ordered Collapse

## Orbital Executioner

Feels:

- Fast
- Technical
- Reactive
- Predatory

Visual signature:

- Curved projectile paths
- Orbiting ammunition
- Constant movement
- High-speed releases

## Living Singularity

Feels:

- Heavy
- Brutal
- Unavoidable
- Defiant

Visual signature:

- Enemies sliding inward
- Dense body distortion
- Ground fractures
- Point-blank implosions

## Kinetic Butcher

Feels:

- Aggressive
- Precise
- Unstable
- Violent

Visual signature:

- Afterimages
- Sudden spatial cuts
- Repeated attacks from prior positions
- Extreme movement changes

## One Final Point

Feels:

- Patient
- Ominous
- Risk-focused
- Catastrophic

Visual signature:

- One increasingly impossible anchor
- Battlefield bending around a single location
- Long buildup
- Encounter-ending Collapse

## Mass-Body Artillery

Feels:

- Improvised
- Cruel
- Physical
- Unpredictable

Visual signature:

- Enemy bodies in orbit
- Living projectiles
- Directional collisions
- Held enemies used as weapons

---

# 41. Non-negotiable combat-presentation rules

## Do not hide weak mechanics behind visual spectacle

If an ability looks powerful, it must meaningfully affect:

- Position
- Mass
- Momentum
- Geometry
- Collision
- Breach

## Do not use generic magic casting poses

Voidbringer should:

- Brace
- Pull
- Cut
- Lock
- Drag
- Strike
- Force machinery open

They do not wave their arms and summon glowing circles.

## Do not make every Collapse enormous

Small targeted collapses make large ones feel special.

## Do not make movement weightless

Even Redshift builds should look like they are fighting extreme force.

## Do not make heavy builds slow and boring

Personal Mass trades ordinary movement for:

- Event Step
- Impact
- Control
- Resistance
- Crushing arrival

## Do not let bosses ignore the class

Translate displacement into:

- Rotation
- Stance damage
- Attack redirection
- Arena movement
- Limb reaction
- Projectile distortion

## Do not overload the HUD

Advanced information appears contextually.

The player sees only the systems their build currently uses.

---

# 42. Final combat-feel standard

Voidbringer is successful when players can recognize a build before opening its equipment screen.

They should be able to watch another Voidbringer and say:

- “That one is making the whole room into a kill box.”
- “That one is stealing the boss’s projectiles.”
- “That one literally turned himself into the anchor.”
- “That one is using enemies as railgun ammo.”
- “That one hasn’t collapsed the anchor in thirty seconds—something horrible is coming.”

The class should feel brutal because its mechanics produce brutal consequences, not because every attack sprays excessive blood or shakes the entire screen.

The final tactile identity is:

> **Every button changes the physical situation. Every anchor creates a future decision. Every Collapse feels like the player personally chose where reality would fail.**