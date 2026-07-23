# Voidbringer Codex Changelog

Canonical class ID: `voidbringer`  
Compatibility ID: `void_warlock`

## 1.3 — 2026-07-22

Status: Audit corrections folded into the numbered bibles

- Fixed `09_AUDIT_RESOLUTIONS.md`'s One Final Point allocation: replaced the nonexistent "Mass Brand — Terminal Brand route" with the legal "Mass Brand — Carrier Brand route." Point total, discipline totals and capstone legality are unchanged.
- Folded all ten approved renames from `09_AUDIT_RESOLUTIONS.md` § 9 directly into `01_CLASS_BIBLE.md` and `02_SKILL_TREE.md` as primary headings, including internal cross-references in sample builds. The old terms no longer appear as headings in either file.
- Resolved the remaining Devouring Center naming collision: renamed the Event Horizon + Hollow Form hybrid keystone (previously sharing its name with the now-renamed Zero-Range Collapse apex) to **Null Nexus**, `vb.keystone.null_nexus`. Mechanics, requirements and point cost are unchanged. Recorded in `09_AUDIT_RESOLUTIONS.md` § 9.
- Corrected a stray "restores" to "removes" in `01_CLASS_BIBLE.md`'s Event Cannibal entry to match the approved Collapse-taxonomy verb.
- Added a `Docs/Planning/TECH_DEBT.md` tracking entry for the remaining `09_AUDIT_RESOLUTIONS.md` rules not yet folded into their owning numbered bibles.

## 1.2 — 2026-07-22

Status: Approved shared-campaign integration

Clarified that the Voidbringer narrative is a class-specific journey woven through one universal AbyssFall campaign.

### Narrative architecture

- Added the binding shared campaign and character-arc doctrine.
- Confirmed one shared world, timeline, central conflict, campaign progression and universal finale for every playable class.
- Reclassified the Last Measure, Gaugehouse, Manifold Trials, Dead Star quest, Axis Vault and Edras conflict as the Voidbringer personal arc and mastery finale.
- Confirmed Edras is not automatically the universal final villain.
- Preserved Architect, Redshift, Hollow and hybrid conclusions as local or personal class outcomes.
- Prevented class endings from destroying shared campaign regions, chronology or endgame infrastructure.
- Added mixed-class party participation and quest-state separation rules.
- Updated the reusable class template so every future class distinguishes shared events from its personal journey.

## 1.1 — 2026-07-22

Status: Independently audited and corrected

- Added binding audit resolutions for discipline-point counting, legal level-50 allocations, Dead Star cost, five-stage Mass, Collapse semantics, naming collisions, corpse-anchor stacking and implementation-architecture bridging.
- Preserved the complete approved class design while correcting contradictions found during independent review.

## 1.0 — 2026-07-22

Status: Approved initial Codex

Established the complete Voidbringer design source of truth.

### Class architecture

- Approved combat verb: Fold
- Approved loop: Anchor → Load → Bend → Collapse
- Approved primary resource: Instability
- Approved advanced state: Breach
- Approved dedicated action: Closure
- Approved signature system: Mass Anchors and Fold Lines
- Approved disciplines: Event Horizon, Redshift and Hollow Form
- Approved ultimate: Dead Star

### Progression

- Approved level 1–50 tree
- Approved 57-point economy
- Approved six active slots, one Closure action and one ultimate
- Approved every active skill, refinement, branch and apex
- Approved shared and discipline passive clusters
- Approved bridge passives, hybrid keystones and Grand Capstones
- Approved Breach Laws and Dead Star manifestations

### Itemization

- Approved Manifold Frames, Containment Cores, Null Arrays and Harness Assemblies
- Approved affix philosophy and exclusions
- Approved Primary, Major and Minor Distortions
- Approved fifteen Unique artifacts
- Approved Manifold Imprints and crafting rules
- Approved anti-meta protections

### Presentation

- Approved controller flow and Anchor Command
- Approved basic attack kits for every Frame subtype
- Approved loadout philosophy and example loadouts
- Approved animation, hitstop, camera, VFX, sound and HUD language
- Approved accessibility and telegraph-protection requirements

### Encounters

- Approved non-binary spatial resistance and force conversion
- Approved enemy weight categories and anchor anatomy
- Approved interactions for every major enemy family
- Approved boss Stance and Structural Stress model
- Approved anti-exploit, co-op, telemetry and encounter-test rules
- Approved example bosses: The Bellower Beneath, The Saint of Fixed Direction and The Hollow Flock

### Narrative

- Approved the Black Measure, Last Measure, Meridian Vaults and Gaugehouse
- Approved Sable Marr, Hadrik Coil, Ilyra Nham and Edras Vey
- Approved The Unmeasured and The Displaced
- Approved Voidbringer-specific enemy families
- Approved all eight Manifold Trials
- Approved Dead Star quest
- Approved final boss and Architect, Redshift, Hollow and hybrid resolutions

### Implementation

- Approved stable ID format
- Approved data-resource and runtime ownership boundaries
- Approved ability lifecycle and animation events
- Approved formula order and collision model
- Approved AI hooks, event payloads, multiplayer authority and save rules
- Approved milestone order and definition of done

### Migration note

The current game still uses `void_warlock` as a compatibility and persistence ID. Do not remove or rename it until an explicit save-data migration is implemented and verified.