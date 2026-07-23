# VOIDBRINGER CODEX — INDEPENDENT AUDIT RESOLUTIONS

Status: Approved and binding  
Codex version: 1.1  
Audit date: 2026-07-22  
Applies to: `01_CLASS_BIBLE.md` through `08_BALANCE_AND_TEST_MATRIX.md`

## 1. Purpose and authority

An independent cross-document audit found that Voidbringer's central design was coherent, but identified governance, point-legality, naming and edge-rule contradictions.

This document resolves those findings without discarding the approved class design.

Where a ruling below names a conflicting section, this document supersedes that section. All unaffected material in the numbered bibles remains approved.

Repository Governance, ADRs, Architecture and Standards remain authoritative for engineering. This file is authoritative only for Voidbringer game-design consistency.

---

# 2. Discipline-point counting

The phrase **points invested in a discipline** has this canonical meaning:

- Points spent unlocking or upgrading an active skill belonging to that discipline count toward that discipline.
- Points spent on passive nodes, notables, bridges, keystones or other nodes explicitly assigned to that discipline count toward it.
- Foundation skills, shared passives, Breach Laws and Dead Star count toward no discipline unless a rule explicitly assigns them.
- A hybrid keystone's own purchase point does not retroactively help satisfy its prerequisites.
- A Grand Capstone's own purchase point does not help satisfy its eighteen-point prerequisite.

This rule governs hybrid-keystone and Grand-Capstone legality in `02_SKILL_TREE.md` and the `required_discipline_points` contract in `07_IMPLEMENTATION_CONTRACT.md`.

---

# 3. Corrected level-50 sample allocations

Every allocation below totals 57 points and obeys the counting rule above.

## Black Sun Architect

The published allocation remains legal and unchanged.

## Orbital Executioner

### Active and ultimate — 23

- Null Shard — Orbital route: 4
- Periapsis — Slingshot route: 4
- Trajectory Theft — Hostile Constellation route: 4
- Vector Salvo — Murder Orbit route: 4
- Event Step — Afterevent route: 4
- Dead Star — Red Orbit route: 3

### Passives and features — 34

Redshift:

- Momentum Reserve: 5
- Orbital Mechanics: 6
- Hostile Trajectory: 5
- Redline: 4

Event Horizon:

- Black Sun: 4
- Gravitational Authority: 3
- Closed Geometry: 3

Other:

- Law of Orbit mutation and apex: 2
- Orbital Execution System capstone: 1
- Closed Orbit hybrid keystone: 1

Discipline totals before purchases:

- Redshift: 12 active + 20 passive = 32
- Event Horizon: 10 passive = 10

Closed Orbit and the Redshift capstone are legal.

## Living Singularity

### Active and ultimate — 23

- Gravitic Skin — Containment route: 4
- Mass Driver — Absolute Fist route: 4
- Countermass — Standing Law route: 4
- Zero-Range Collapse — Inward Dominion route: 4
- Event Step — Exchange route: 4
- Dead Star — Star Vessel route: 3

### Passives and features — 34

Hollow Form:

- Personal Mass: 6
- Counterforce: 5
- Point-Blank Ruin: 5
- Living Center: 5
- Impact Body: 1

Event Horizon:

- Gravitational Authority: 4
- Collapse Doctrine: 4

Other:

- Law of Compression mutation and apex: 2
- Living Singularity capstone: 1
- Null Nexus hybrid keystone: 1

Discipline totals:

- Hollow Form: 16 active + 22 passive = 38
- Event Horizon: 8 passive = 8

Null Nexus and the Hollow Form capstone are legal.

## Kinetic Butcher

The published allocation becomes legal under the canonical discipline-point counting rule.

Discipline totals:

- Redshift: 8 active + 16 passive = 24
- Hollow Form: 4 active + 8 passive = 12

Impact Event, Kinetic Crucible and No Rest Frame are legal.

## Mass-Body Artillery

### Active and ultimate — 23

- Mass Brand — Carrier route: 4
- Rail Collapse — Living Round route: 4
- Tidal Lock — Satellite route: 4
- Gravitic Clamp — Flesh Weapon route: 4
- Convergence — Dominant Center route: 4
- Dead Star — Red Orbit route: 3

### Passives and features — 34

- Mass Dynamics: 6
- Gravitational Authority: 5
- Orbital Mechanics: 5
- Impact Body: 5
- Hostile Trajectory: 3
- Momentum Reserve: 6
- Catapult Doctrine: 1
- Law of Inversion mutation and apex: 2
- No Rest Frame capstone: 1

Discipline totals:

- Event Horizon: 8 active + 5 passive = 13
- Redshift: 4 active + 14 passive = 18
- Hollow Form: 4 active + 5 passive = 9

Catapult Doctrine and No Rest Frame are legal.

## One Final Point

### Active and ultimate — 27

- Mass Brand — Carrier Brand route: 4
- Crush Point — Internal Failure route: 4
- Accretion Field — Grave Accretion route: 4
- Hard Vacuum — Force Vault route: 4
- Convergence — Dominant Center route: 4
- Event Step — utility route: 4
- Dead Star — Black Star route: 3

### Passives and features — 30

- Anchorcraft: 5
- Controlled Ruin: 5
- Collapse Doctrine: 6
- Black Sun: 4
- Breachcraft: 4
- Law of Compression mutation and apex: 2
- One Final Point capstone: 1
- Mass Dynamics: 3

Event Horizon total: 12 active + 10 passive = 22. The capstone is legal.

## Breach Engine

### Active and ultimate — 27

- Mass Brand: 4
- Event Step: 4
- Crush Point: 4
- Velocity Theft: 4
- Gravitic Skin: 4
- Hard Vacuum: 4
- Dead Star: 3

### Passives and features — 30

Redshift:

- Momentum Reserve: 5
- Redline: 6
- Event Motion: 3

Shared and other:

- Breachcraft: 5
- Controlled Ruin: 5
- Manifold Integrity: 3
- Law of Inversion mutation and apex: 2
- Redline Paradox capstone: 1

Redshift total: 4 active + 14 passive = 18. The capstone is legal.

---

# 4. Anchor-cap progression

The canonical progression is:

- Levels 1–4: maximum two active Mass Anchors.
- Level 5: maximum increases permanently to three.
- Trial I does not grant the third anchor. Its rewards remain the bonus Void Point, Mass Dynamics access, calibration progress and narrative/visual rewards.

This supersedes the level-1 sentence saying two anchors remain until Trial I and the Trial-I narrative reward that grants three-anchor capacity.

---

# 5. Dead Star point cost

Dead Star's base unlock at level 30 is free after completing its class quest.

Its development costs exactly three Void Points:

1. Common refinement: 1
2. One manifestation at level 40: 1
3. That manifestation's apex at level 48: 1

The manifestation is not a free level reward. Level 40 unlocks the ability to purchase and switch the chosen manifestation outside combat.

---

# 6. Collapse, consume, sacrifice and removal taxonomy

The terms have distinct mechanical meanings.

## Collapse

A rule that says it **collapses an anchor**:

- removes the anchor,
- performs the carrier-specific Collapse output,
- applies that stage's standard Instability removal,
- applies that stage's Breach extension when Breach is active,
- counts toward Clean Closure when Dense or higher,
- triggers effects listening for an anchor Collapse.

This includes Closure, Crush Point, Rail Collapse, Failed System, Collapsing Body and any other effect explicitly using the word Collapse.

## Consume or sacrifice

A rule that **consumes** or **sacrifices** an anchor removes it for another purpose and does not automatically grant standard Closure release, Instability removal or Breach extension unless the rule explicitly says it also collapses the anchor.

## Expire, replace or cleanse

Expiration, capacity replacement and special cleanse behavior do not count as Collapse unless explicitly converted by another rule.

## Triggered release

Effects released because another effect collapsed an anchor do not apply a second standard Instability removal. One anchor produces one standard Collapse release.

## Event Cannibal exception

Event Cannibal is authoritative as defined in `03_ITEMIZATION.md`:

- Closure removes no Instability.
- The nearest surviving anchor receives 70% of the collapsed anchor's Mass.
- It inherits compatible temporary effects and one compatible orbiting object.
- The original anchor still counts as collapsed for event triggers and Clean Closure, but its zero Instability removal is the item's explicit exception.

---

# 7. Five-stage Mass rules

Effects such as One Final Point and The Empty Throne replace the normal three-stage anchor with a five-stage anchor.

## Capacity and ranges

Maximum Mass becomes 200.

- Dormant: 0–39
- Dense: 40–79
- Critical: 80–119
- Terminal: 120–159
- Impossible: 160–200

## Base Closure coefficients

- Dormant: 45% Weapon Power
- Dense: 105%
- Critical: 190%
- Terminal: 310%
- Impossible: 475%

## Standard Instability removal

- Dormant: 7
- Dense: 13
- Critical: 21
- Terminal: 28
- Impossible: 36

## Breach extension

- Dormant: 0.4 seconds
- Dense: 0.8 seconds
- Critical: 1.3 seconds
- Terminal: 1.7 seconds
- Impossible: 2.2 seconds

The global maximum of eight seconds of added Breach time still applies.

## Classification

- Terminal and Impossible count as **Critical or higher** for Clean Closure, Spatial Recoil, skill requirements and item triggers.
- Any rule written as “Critical anchor” includes Terminal and Impossible unless it explicitly says “exactly Critical.”
- Mass above 200 requires a unique explicit mechanic such as Forbidden Mass; it does not create an unnamed sixth stage.

---

# 8. Trial III requirement

Trial III — Containment Failure is the player's first mandatory Breach examination.

The canonical completion requirement is:

- deliberately enter Breach,
- experience the boss's demonstrations of Compression, Inversion and Orbit,
- collapse at least one Dense-or-higher anchor during Breach,
- end the Breach without being incapacitated,
- defeat Mara Keth.

A full Clean Closure is taught and encouraged but is not mandatory for Trial III completion. Clean Closure mastery is formally required in Trials VII and VIII.

The player selects one free Breach Law after completing Trial III.

---

# 9. Canonical display-name and stable-ID cleanup

The following duplicate or near-duplicate player-facing names are replaced before IDs freeze:

| Old name | Canonical name | Canonical ID |
|---|---|---|
| Heavy Silence passive | Muffled Violence | `vb.passive.muffled_violence` |
| Vector Salvo apex: No Rest Frame | Simultaneous Vector | `vb.skill.vector_salvo.simultaneous_vector` |
| Zero-Range Collapse branch: Living Singularity | Inward Dominion | `vb.skill.zero_range_collapse.inward_dominion` |
| Zero-Range Collapse apex: Devouring Center | All Roads Inward | `vb.skill.zero_range_collapse.all_roads_inward` |
| Gravitic Skin branch: Bone Orbit | Shard Carapace | `vb.skill.gravitic_skin.shard_carapace` |
| Accretion Field apex: Common Grave | Grave Convergence | `vb.skill.accretion_field.grave_convergence` |
| Gravitic Skin apex: Unfallen Weight | Absolute Anchorage | `vb.skill.gravitic_skin.absolute_anchorage` |
| Dead Star Red Orbit apex: Lightless Velocity | Terminal Redshift | `vb.ultimate.dead_star.terminal_redshift` |
| Law of Compression mutation: Shared Center | Composite Center | `vb.law.compression.composite_center` |
| Hard Vacuum branch: Vacancy | Vacancy Field | `vb.skill.hard_vacuum.vacancy_field` |
| Event Horizon + Hollow Form hybrid keystone: Devouring Center | Null Nexus | `vb.keystone.null_nexus` |

Null Nexus is a follow-up correction: renaming the Zero-Range Collapse apex to All Roads Inward removed the literal duplicate, but the hybrid keystone kept the disputed name. It receives a fully distinct name rather than inheriting either side of the original collision. Its requirements, mechanics and point cost are unchanged from the keystone previously called Devouring Center.

The unique items **Unfallen Weight** and **Lightless Velocity** retain their names.

Build labels may intentionally mirror the capstone that defines them. Therefore the Living Singularity build may retain its name while the Zero-Range branch is renamed.

Trial VII retains **No Stable Frame**. The No Rest Frame Grand Capstone, No Safe Frame item and World Without Rest item remain distinct approved names.

No public save format exists for these new IDs yet, so these replacements occur before the “never rename a shipped ID” rule applies.

---

# 10. Specialized-document authority

`01_CLASS_BIBLE.md` establishes fantasy and mechanical intent. Its early option lists are illustrative where later specialized documents define a fixed implementation.

Canonical specialized authority:

- `02_SKILL_TREE.md` controls final branch counts, progression, values, Clean Closure and Spatial Recoil.
- `03_ITEMIZATION.md` controls final Distortion and unique-item rules.
- `06_NARRATIVE_AND_QUESTS.md` controls final lore and quest sequence, as corrected here.
- `07_IMPLEMENTATION_CONTRACT.md` controls design-side implementation contracts, subject to repository ADRs and Architecture.

Specific rulings:

- Event Cannibal uses the itemization version stated in section 6 above.
- Terminal Brand uses the exact active-skill or item rule in the specialized document where it appears; the Class Bible summary is not an additional stacked effect.
- Clean Closure is the explicit three-condition rule in `02_SKILL_TREE.md`.
- Spatial Recoil uses the numeric rule in `02_SKILL_TREE.md`.
- Active skills use the fixed two-branch structure in `02_SKILL_TREE.md`; longer lists in the Class Bible are concept explorations, not extra purchasable branches.

---

# 11. Corpse-anchor stacking

Corpse-related effects merge rather than spawning duplicate anchors.

- One corpse may carry at most one Mass Anchor per Voidbringer owner.
- **Corpse Geometry** creates an automatic corpse anchor when an anchored enemy dies.
- **Common Grave Engine** modifies that automatic anchor's permanence and capacity-counting rules; it does not create a second anchor.
- **Funeral Geometry** allows manual Mass Brand placement on eligible corpses and grants its Mass/Closure bonuses.
- If Funeral Geometry targets a corpse already anchored through Corpse Geometry/Common Grave Engine, it refreshes or upgrades the existing anchor according to the strongest applicable duration/permanence rule.
- When Common Grave Engine makes an anchor permanent, Funeral Geometry's duration extension is irrelevant, but its other bonuses still apply.
- Chain Collapse may trigger only once per corpse anchor per originating Collapse event.

---

# 12. Velocity terminology

World Without Rest does not create a second resource named Relative Velocity.

Its movement behavior builds and consumes the existing **Velocity Reserve** pool.

“Relative velocity” may still be used descriptively in formulas comparing two bodies, but it is not a player status or saved scalar.

---

# 13. Empty Throne and One Final Point

The Empty Throne Primary Distortion and the One Final Point Grand Capstone are mutually exclusive.

- The equipment UI blocks equipping The Empty Throne while One Final Point is active.
- The skill-tree UI blocks activating One Final Point while The Empty Throne is equipped.
- Neither effect consumes a slot while disabled, and neither silently wastes the other.

The Empty Throne exists to grant the one-anchor build while allowing a different Grand Capstone.

---

# 14. Additional terminology and cross-references

- Use **remove Instability**, not “restore Instability,” for Closure effects.
- “Critical or higher” includes Terminal and Impossible.
- The Null Nexus hybrid keystone (formerly named Devouring Center; see section 9) treats the player as a valid geometry endpoint through the same player-endpoint rule established by Centered Architecture. It removes terrain-anchor placement, not all closed geometry.
- In balance documents, “Open or Overclocked containment” means **Open Harness or Overclocked Containment Core**; they are different equipment slots.
- Trial levels are canonically 8, 14, 20, 26, 32, 38, 44 and 50.

---

# 15. Existing-repository architecture bridge

The conceptual implementation contract must integrate with the approved repository architecture.

## Existing ownership wins

- `RuntimeSession` remains the session-scoped owner defined by current ADRs and Architecture.
- Ability execution routes through the existing `AbilityExecutor`/RuntimeSession contract.
- Existing inventory, equipment, reward, persistence and event ownership may not be bypassed.
- A Voidbringer-specific manager may be a per-character component when it owns only that character's transient state.
- Any proposed new session-scoped service or ownership boundary requires an ADR before implementation.

## Event bus

The conceptual `CombatEventBus` in `07_IMPLEMENTATION_CONTRACT.md` is not approval for a second global bus.

Canonical implementation direction:

- extend or publish through the existing `RuntimeEventBus` contract using namespaced Voidbringer events, or
- obtain an ADR approving a different relationship before writing it.

Suggested event namespace: `voidbringer.*`.

## Ability-definition naming

The proposed custom Resource must not use the existing global class name `AbilityDefinition`.

Canonical design-side name:

- `VoidbringerAbilitySpec`
- optional script filename: `voidbringer_ability_spec.gd`

Other data types should use similarly collision-safe names or remain non-global resources.

## Persistence mapping

Persistent Voidbringer progression belongs in the existing BuildData contract, namespaced under:

`build_specific_progress["voidbringer"]`

Suggested keys:

- `unlocked_skill_ids`
- `selected_upgrade_ids`
- `passive_ranks`
- `active_capstone_id`
- `breach_law_id`
- `breach_law_mutation_id`
- `breach_law_apex_unlocked`
- `manifold_trials_completed`
- `saved_loadouts`

Equipped items remain in the existing gear/equipment fields rather than being duplicated inside class progress.

Transient state is never persisted:

- active anchors,
- anchor Mass,
- Fold Lines,
- Instability,
- Breach timers,
- Velocity Reserve,
- Personal Mass,
- captured projectiles,
- orbit inventory.

Adding or changing actual BuildData fields still requires compliance with existing persistence ADRs, JSON round-trip tests and any required versioned migration.

---

# 16. Implementation readiness verdict

With these resolutions applied as binding authority:

- the sample allocations are legal,
- discipline counting is implementable,
- anchor progression is unambiguous,
- Dead Star costs reconcile with all totals,
- Collapse economics are globally defined,
- five-stage anchors are fully specified,
- Trial III matches the progression curve,
- player-facing names are unique enough to freeze safely,
- corpse-anchor stacking cannot duplicate state,
- the design contract no longer authorizes architecture parallel to the existing runtime.

The Voidbringer Codex is safe to use as the implementation source of truth **only when this document is read with the numbered bibles and repository Governance/ADRs/Architecture**.
