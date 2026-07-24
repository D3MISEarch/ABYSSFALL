# AbyssFall Playable Class Codex Template

Status: Template  
Last updated: 2026-07-22

Every playable class should receive the same depth of design treatment while preserving completely different mechanics and fantasies.

Every class narrative must also comply with [`../SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md`](../SHARED_CAMPAIGN_AND_CHARACTER_ARCS.md): one shared world and campaign, with a distinct personal journey layered through it.

## Document set

Create one folder per class with these files:

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

## Required metadata

Every document begins with:

```text
Status: Concept | Draft | Approved | Implemented | Partially implemented | Deprecated
Codex version: X.Y
Implementation status: ...
Last updated: YYYY-MM-DD
Canonical class ID: ...
Compatibility IDs: ...
```

## 01 — Class Bible

Must define:

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
- Mastery is still unfolding after 30 hours.

Depth should come from timing, positioning, sequencing, resource control and build decisions—not from piling on unrelated meters.

## 02 — Skill Tree

Must define:

- Level cap and point economy
- Level-by-level unlock schedule
- Dedicated class actions
- Every active skill
- Common refinement for each active skill
- Two mutually exclusive mutation paths for normal skills
- Apex upgrade for each mutation
- Three ultimate manifestations when appropriate
- Shared passive clusters
- Discipline passive clusters
- Bridge nodes
- Hybrid keystones
- Grand capstones
- Sample complete level-cap allocations
- Respec rules
- Readability and implementation requirements

Normal skill modifiers should follow:

- Form: changes delivery
- Cost: changes what powers or risks the skill
- Payoff: changes what the skill achieves

Avoid trees dominated by small generic damage increases.

## 03 — Itemization

Must define:

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

Memorable items change relationships and behavior, not only numbers.

## 04 — Combat Presentation

Must define:

- Combat-feel target
- Input philosophy
- Controller and keyboard/mouse flow
- Dedicated class-action targeting
- Basic attacks for each weapon family
- Six-slot loadout rules
- Recommended beginner loadout
- Example endgame loadouts
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
- Multiplayer readability
- Accessibility
- Tutorial delivery
- First-hour, ten-hour and endgame feel

## 05 — Encounter Interactions

Must define:

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
- Humanoid, giant, stationary, flying and multi-body bosses
- Phase shifts, invulnerability, cleanses and armor phases
- Environmental interactions
- Anti-exploit protections
- Difficulty scaling
- Co-op rules
- Telemetry
- Required encounter test suite

An enemy may resist a mechanic but should not simply turn off the class fantasy.

## 06 — Narrative and Quests

Must define the class journey **inside the universal AbyssFall campaign**, not a replacement campaign.

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
- Every class trial
- Ultimate-unlock quest
- Class interpretation of shared locations and events
- Class mastery finale
- Build-influenced class resolutions where appropriate
- Local and personal consequences
- Shared-campaign constraints
- Multiplayer participation rules
- Post-story class state
- Endgame class hooks
- Trial replay system
- World interactions
- Dialogue tone
- Visual evolution
- Narrative non-negotiable rules

Every narrative bible must answer:

- Which events are universal campaign events?
- Which events are class-exclusive?
- Where does the class rejoin or remain inside the shared campaign?
- What can other classes perceive or assist with?
- Which consequences are personal, local, shared or account-wide?
- Does the class antagonist remain distinct from the universal campaign antagonist?
- Does the class finale preserve shared regions, timeline and endgame?
- Can the story remain coherent for a player who never uses this class?

Mechanics and story should explain each other. Different journeys must enrich the same world rather than creating different universes.

## 07 — Implementation Contract

Must define:

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
- Multiplayer authority
- Save data
- Telemetry events
- Automated validation
- Prototype milestones
- Definition of done for one ability

## 08 — Balance and Test Matrix

Must define:

- Prototype constants
- Tuning assumptions
- Build targets
- Damage-category separation
- Resource goals
- Encounter coverage
- Boss conversion expectations
- Accessibility tests
- Controller tests
- Multiplayer tests
- Performance budgets
- Telemetry thresholds
- Warning signs
- Regression checklist
- Completion standard

## Cross-class rules

Every class receives:

- One clear signature combat verb
- One primary resource
- One advanced risk mechanic
- One recognizable movement ability
- Three freely mixable progression paths
- Behavior-changing upgrades
- Multiple genuine endgame builds
- One personal journey woven through the shared campaign
- One mastery finale that does not replace the universal campaign ending

All classes share:

- one world,
- one campaign timeline,
- one universal central conflict,
- major regions and campaign hubs,
- universal campaign bosses and finale,
- and a coherent transition into endgame.

Do not make every class use the same internal structure simply because the documentation structure matches.

The documents are consistent. The characters must remain radically distinct. Their stories must remain radically personal without becoming mutually incompatible campaigns.