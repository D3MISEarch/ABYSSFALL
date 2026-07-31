# AbyssFall Playable Class Codex Template

Status: Template  
Last updated: 2026-07-31

Every production class should eventually receive the same depth of design treatment while preserving completely different mechanics and fantasies.

This template is a long-term completeness standard, not a work queue, launch commitment, or implementation authorization. A class uses it when the owner opens that class's design or production operation. The existence of a field does not authorize speculative architecture, multiplayer, platform, campaign, item, or content work outside the active operation.

Every class narrative must also comply with [`../SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md`](../SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md): one shared world and campaign, with a distinct personal journey layered through it.

The binding operation boundary lives in [`../../Design/GAMEPLAY_BIBLE.md`](../../Design/GAMEPLAY_BIBLE.md), and the exact active work queue lives in [`../../Roadmap/CURRENT_SLICE.md`](../../Roadmap/CURRENT_SLICE.md).

## Production-use rule

Before creating or expanding a class Codex:

1. Confirm that the owner has explicitly opened the relevant design or production operation.
2. Confirm what level of completeness that operation actually requires.
3. Mark future capabilities **Deferred** instead of designing or implementing them speculatively.
4. Do not build shared infrastructure solely because multiple future Codices could hypothetically use it.
5. Prove the current class specifically, preserve clean extension seams, and generalize after a real second consumer exists.

A complete design may describe a mature destination beyond current implementation. Its implementation status must state that difference plainly.

## Document set

Create one folder per authorized class with these files:

1. `README.md`
2. `01_CLASS_BIBLE.md`
3. `02_SKILL_TREE.md`
4. `03_ITEMIZATION.md`
5. `04_COMBAT_PRESENTATION.md`
6. `05_ENCOUNTER_INTERACTIONS.md`
7. `06_NARRATIVE_AND_QUESTS.md`
8. `07_IMPLEMENTATION_CONTRACT.md`
9. `08_BALANCE_AND_TEST_MATRIX.md`
10. `CHANGELOG.md`

Add an audit-resolution document only when independent review finds contradictions that cannot be corrected immediately in the owning numbered bible.

The owner may authorize a bounded subset first. Do not create empty completeness theater merely to satisfy the folder list.

## Required metadata

Every document begins with:

```text
Status: Concept | Draft | Approved | Implemented | Partially implemented | Deprecated
Codex version: X.Y
Implementation status: ...
Production operation: OP1 | OP2 | Future direction | Deferred
Last updated: YYYY-MM-DD
Canonical class ID: ...
Compatibility IDs: ...
```

Design approval and production authority are separate. `Approved` design content is not `Implemented`, and `Future direction` is not permission to begin work.

## 01 — Class Bible

Must define, at the depth authorized for the operation:

- Core fantasy
- Player promise
- Signature combat verb
- Class silhouette
- Visual language
- Primary combat loop
- Signature mechanic
- Primary resource
- Advanced risk state
- Movement identity
- Weapon families
- Three progression disciplines
- Cross-discipline hybrids
- Ultimate
- Example endgame builds
- Mastery curve
- Non-negotiable identity rules

Use the 30-second / 30-hour test:

- A new player understands the fantasy and basic loop within 30 seconds.
- Mastery is still unfolding after 30 hours in the mature design.

Depth should come from timing, positioning, sequencing, resource control and build decisions—not from piling on unrelated meters.

## 02 — Skill Tree

Must define, when included in the opened operation:

- Level cap and point economy
- Level-by-level unlock schedule
- Dedicated class actions
- Every active skill required by the approved proof target
- Common refinement for each active skill
- Consequential mutation paths for major skills
- Apex or final mutations where appropriate
- Ultimate manifestations when appropriate
- Shared passive clusters
- Discipline passive clusters
- Bridge nodes
- Law Nodes
- Culmination Nodes
- Sample complete allocations for the approved milestone
- Respec rules
- Readability and implementation requirements

Normal skill modifiers should follow:

- Form: changes delivery
- Cost: changes what powers or risks the skill
- Payoff: changes what the skill achieves

Avoid trees dominated by small generic damage increases. Do not require the full mature level range in one PR or sprint; bounded slices must state what part of the complete proof they establish.

## 03 — Itemization

Must define, when included in the opened operation:

- Class-specific equipment slots
- Weapon families and basic identities
- Class-stat vocabulary
- Affix pools
- Affix exclusions and tradeoffs
- Legendary effect categories
- Build-defining effects
- Major and minor effects
- Unique items with real drawbacks
- Acquisition philosophy
- Endgame modification system
- Crafting rules
- Loot readability
- Gear tags
- Sample gear identities
- Anti-meta protections
- Modular implementation rules

Memorable items change relationships and behavior, not only numbers. Future item tiers or economies may be marked Deferred until their operation opens.

## 04 — Combat Presentation

Must define, at the depth needed by the active proof:

- Combat-feel target
- Input philosophy
- Controller and keyboard/mouse flow
- Dedicated class-action targeting
- Basic attacks for each weapon family in scope
- Loadout rules
- Recommended beginner loadout
- Example advanced loadouts
- Animation language
- Hit reactions
- Movement animation
- Hitstop
- Camera behavior
- VFX language
- Resource-state presentation
- Sound design
- Music interaction
- HUD
- Status icons
- Damage-number behavior
- Enemy telegraph protection
- Accessibility
- Tutorial delivery
- First-hour, ten-hour and endgame feel targets appropriate to the operation
- Multiplayer readability — **Deferred until a multiplayer operation opens**

High-end presentation is concentrated inside the bounded active slice. The template does not authorize broad art production for unopened classes or realms.

## 05 — Encounter Interactions

Must define, at the depth represented by the approved enemy and boss set:

- Non-binary resistance model
- Enemy weight or response categories
- Force conversion
- Body-region or carrier rules
- Swarms
- Shields
- Fast enemies
- Ranged enemies
- Teleporters
- Flying enemies
- Burrowers
- Spectral enemies
- Armored enemies
- Regenerators
- Splitters and clones
- Summoners
- Supports
- Chargers
- Grapplers
- Stationary enemies
- Class-specific counter-enemies
- Elite modifiers
- Boss doctrine
- Humanoid, giant, stationary, flying and multi-body boss translations when those archetypes enter scope
- Phase shifts, invulnerability, cleanses and armor phases
- Environmental interactions
- Anti-exploit protections
- Difficulty scaling
- Telemetry
- Required encounter test suite
- Co-op rules — **Deferred until a co-op operation opens**

An enemy may resist a mechanic but should not simply turn off the class fantasy. Unbuilt enemy archetypes may be documented as future translation rules without becoming current content requirements.

## 06 — Narrative and Quests

Must define the class journey **inside the universal AbyssFall campaign**, not a replacement campaign, at the depth authorized for that class's operation.

Required sections:

- Shared campaign intersections
- Class-specific narrative promise and central conflict
- Class relationship to world systems
- Class origin and the point where the character joins the shared campaign
- Why the player can use the class mechanic
- Class faction, mentor and hub or linked sub-hub
- Key class NPCs
- Personal antagonist or rival
- Class-specific enemy families
- Level-band class progression aligned with shared campaign milestones
- Every class trial in the approved scope
- Ultimate-unlock quest when included
- Class interpretation of shared locations and events
- Class mastery finale direction
- Build-influenced class resolutions where appropriate
- Local and personal consequences
- Shared-campaign constraints
- Post-story class state
- Endgame class hooks
- Trial replay system
- World interactions
- Dialogue tone
- Visual evolution
- Narrative non-negotiable rules
- Multiplayer participation rules — **Deferred until a multiplayer operation opens**

Every narrative bible must answer:

- Which events are universal campaign events?
- Which events are class-exclusive?
- Where does the class rejoin or remain inside the shared campaign?
- What can other classes perceive or assist with when multiplayer is eventually opened?
- Which consequences are personal, local, shared or account-wide?
- Does the class antagonist remain distinct from the universal campaign antagonist?
- Does the class finale preserve shared regions, timeline and endgame?
- Can the story remain coherent for a player who never uses this class?

Mechanics and story should explain each other. Different journeys must enrich the same world rather than creating different universes.

## 07 — Implementation Contract

Must define only contracts needed by the opened operation:

- Stable IDs
- Data schemas
- Runtime ownership
- Ability lifecycle
- Animation event contract
- Formula order
- Resource ownership
- Status semantics
- Tag vocabulary
- AI hooks
- Presentation payloads
- Save data
- Telemetry events
- Automated validation
- Prototype milestones
- Definition of done for one ability
- Multiplayer authority — **Deferred until a multiplayer ADR and operation open**

Do not invent an owner, event bus, persistence field, service, networking layer, or generalized class framework from template completeness. New architectural contracts require an ADR and an active production need.

## 08 — Balance and Test Matrix

Must define tests and targets for the opened operation:

- Prototype constants
- Tuning assumptions
- Build targets
- Damage-category separation
- Resource goals
- Encounter coverage
- Boss conversion expectations
- Accessibility tests
- Controller tests
- Performance budgets
- Telemetry thresholds
- Warning signs
- Regression checklist
- Completion standard
- Multiplayer tests — **Deferred until multiplayer exists**

## Cross-class rules

Every mature class direction should eventually receive:

- One clear signature combat verb
- One primary resource
- One advanced risk mechanic
- One recognizable movement ability
- Three freely mixable progression paths
- Behavior-changing upgrades
- Multiple genuine endgame builds
- One personal journey woven through the shared campaign
- One mastery finale that does not replace the universal campaign ending

All classes share, when their operations are opened:

- one world,
- one campaign timeline,
- one universal central conflict,
- major regions and campaign hubs,
- universal campaign bosses and finale,
- and a coherent transition into endgame.

Do not make every class use the same internal structure simply because the documentation structure matches.

The documents are consistent. The characters must remain radically distinct. Their stories must remain radically personal without becoming mutually incompatible campaigns. Their future depth must not become current scope until the owner opens it.
