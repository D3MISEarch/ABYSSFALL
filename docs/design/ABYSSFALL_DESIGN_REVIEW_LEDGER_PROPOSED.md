# AbyssFall Design Review Ledger — PROPOSED

> Status: **PROPOSED / OWNER REVIEW REQUIRED**  
> Scope: Shared campaign framework and launch-class bibles in draft PR #40  
> Purpose: Convert a very large design package into a reviewable decision sequence without silently promoting proposals to canon.

---

## 1. Locked Direction

The following constraints are already approved and are not reopened by this ledger:

- One shared world and one campaign timeline.
- Every launch class receives a personal arc inside the shared campaign.
- Launch roster: Voidbringer, Penitent, Graftborn, Somnarch, Relic Host, Gorgon, Tidewrought, and Anachron.
- Choirborn, Echo Thief, and Plaguebringer remain reserved for later content or specialization concepts.
- Persistent ARPG progression, gear, class trees, and multiple build slots are foundational.
- No mandatory in-combat three-choice upgrade interruptions.
- Seasonal content adds to persistent characters and does not require character resets.
- Temporary run modifiers remain deferred to optional modes such as Abyss Siege.

---

## 2. Package Inventory

| ID | Document | Review State | Canon State |
|---|---|---|---|
| DOC-CAM-001 | Campaign and Systems Bible | Complete draft | Proposed |
| DOC-CLS-GRF-001 | Graftborn Class Bible | Complete draft | Proposed |
| DOC-CLS-SOM-001 | Somnarch Class Bible | Complete draft | Proposed |
| DOC-CLS-RLH-001 | Relic Host Class Bible | Complete draft | Proposed |
| DOC-CLS-GOR-001 | Gorgon Class Bible | Complete draft | Proposed |
| DOC-CLS-TID-001 | Tidewrought Class Bible | Complete draft | Proposed |
| DOC-CLS-ANA-001 | Anachron Class Bible | Complete draft | Proposed |

Voidbringer and Penitent remain established reference classes. Their current documents should be normalized against this package only after the owner approves the shared vocabulary and final class naming.

---

## 3. Recommended Owner Review Order

The package should not be reviewed document-by-document from top to bottom. Approve the decisions that affect every other document first.

### Gate A — World and product identity

1. **REV-A01 — Final playable class name:** Voidbringer versus Void Warlock.
2. **REV-A02 — Setting names:** canonical world, continent, frontier city, and major regions.
3. **REV-A03 — Campaign ending model:** one canonical stabilization or a meaningful branch with controlled post-campaign consequences.
4. **REV-A04 — Architect Below truth:** explicit identity, several competing truths, or intentional ambiguity.
5. **REV-A05 — Hollow King origin:** custodian, punished ruler, or failed usurper.

Nothing in Gate A blocks further documentation review, but it blocks final narrative copy, marketing language, voice casting, and cinematic planning.

### Gate B — Shared mechanical vocabulary

1. **REV-B01 — Primary attributes:** approve or replace Might, Finesse, Will, and Vitality.
2. **REV-B02 — Damage and resistance presentation:** expose all detailed families or consolidate player-facing resistances while retaining internal tags.
3. **REV-B03 — Class identity equipment:** universal Class Relic slot versus class-specific special slots versus normal equipment only.
4. **REV-B04 — Respec economy:** free, common-currency cost, or endgame-only reconstruction cost.
5. **REV-B05 — Endgame hierarchy:** Fracture Hunts, Anchor Depths, and Abyss Siege relationship.

Gate B should be approved before itemization tables, progression data, save schemas, or production UI are locked.

### Gate C — Class identity approval

Review each class at the fantasy-and-loop level before reviewing every skill or unique item.

1. Graftborn — authored anatomy and deliberate adaptation.
2. Somnarch — sovereign dream territory and imposed nightmare law.
3. Relic Host — negotiated possession by inherited dead intelligences.
4. Gorgon — attention, fixation, venom, reflection, and structural petrification.
5. Tidewrought — pressure, depth, current, brine, and hull strain.
6. Anachron — authored temporal sequences and delayed consequences.

For each class, the first owner decision should be one of:

- **APPROVE CORE** — fantasy, resource, signature mechanic, and combat loop are accepted.
- **REVISE CORE** — identity is promising but one foundational system must change.
- **HOLD** — do not develop further until a larger world or roster decision is made.

### Gate D — Production-facing detail

Only after Gates A–C:

- skill names and exact counts;
- progression-path names;
- keystones;
- ultimate names;
- unique-item names and rarity;
- dedicated equipment-slot details;
- campaign NPC names;
- cosmetic transformation choices;
- exact HUD presentation.

---

## 4. Cross-Class Identity Matrix

| Class | Owns | Must Not Own | Primary Mastery Expression |
|---|---|---|---|
| Voidbringer | gravity, void pressure, spatial collapse, portals, Corruption | time replay, dream law, ocean pressure | positioning, pull/push geometry, risk-managed corruption |
| Penitent | rites, brands, circles, sacramental sequencing, battlefield law | dream sovereignty, free-form spellcasting, passive holy auras | pattern sequencing, setup, commitment, judgment timing |
| Graftborn | self-authored anatomy, Biomass, Body Regions, Adaptations, Trauma Imprints | epidemic ecology, random mutation, permanent detached-part army | adaptation sequencing, body-state management, deliberate sacrifice |
| Somnarch | Sovereign Dream territory, Dream Clauses, Dread, Waking/Veiled/Dominion | generic sleep spam, copied abilities, permanent hard control | territory architecture, clause ordering, positional foresight |
| Relic Host | Reliquary Council, Accord, Investiture, Memory Conditions, Last Testaments | generic necromancy, pet army, passive aura support | presence rotation, negotiated risk, condition fulfillment |
| Gorgon | attention, Exposed prey, Fixation, petrification, venom families, reflection | disease ecology, generic poison rogue play, self-authored mutation | target reading, threshold control, counter timing, break windows |
| Tidewrought | Depth, Hull Strain, pressure, current, brine, Compression, Breach | frost wizard identity, gravity reskin, environmental-water dependency | pressure-band control, route shaping, forced movement timing |
| Anachron | own-action Temporal Imprints, Reprise, Delayed Consequence, Severance, Convergence | enemy ability copying, unrestricted rewind, permanent time stop | authored sequence planning, delayed payoff, self-position anchoring |

### Reserved-class boundary protection

- **Plaguebringer** retains disease ecology, contagion networks, epidemic propagation, and infection management.
- **Echo Thief** retains appropriation of enemy abilities, voices, identities, or authored combat expressions.
- **Choirborn** retains collective voice, harmonic law, chorus structures, and identity through coordinated resonance.

Any future mechanic crossing these boundaries must explain why it strengthens both identities rather than consuming the reserved class's design territory.

---

## 5. Shared Terminology Registry

These terms should be treated as controlled design vocabulary until approved or replaced.

### Shared terms

- Life
- Guard
- Armor
- Resource
- Status
- Mark
- Zone
- Trigger
- Conversion
- Keystone
- Ultimate
- Class Path
- Build Slot
- Unique Item
- Boss Pressure

### Boss-safe replacement pattern

Hard-control and binary mechanics must receive a boss-compatible pressure state rather than becoming nonfunctional:

- Gorgon Petrification → Monument Pressure
- Tidewrought Breach/Compression payoff → Pressure Fracture
- Anachron temporal disruption → Temporal Strain
- Somnarch control thresholds → Nightmare Pressure

Future bibles should use the same pattern: normal enemies may enter a complete state; bosses accumulate a readable pressure state that produces openings, damage amplification, stagger, rule changes, or mechanic-specific rewards without trivializing encounters.

### Proprietary class terms

Proprietary states should not be casually shared through generic loot. Cross-class uniques may reference them only through explicit, curated conversions.

- Graftborn: Biomass, Body Region, Adaptation, Trauma Imprint, Rupture
- Somnarch: Lucidity, Sovereign Dream, Dream Clause, Dread, Dominion
- Relic Host: Accord, Presence, Investiture, Memory Condition, Last Testament, Conflict, Ejection
- Gorgon: Ichor, Exposed, Fixation, Lock State, Breakable Carapace, Venom Family
- Tidewrought: Depth, Hull Strain, Abyssal Brine, Soaked, Compression, Current Line, Breach
- Anachron: Disjunction, Temporal Imprint, Reprise, Anchored Self, Delayed Consequence, Severance, Convergence

---

## 6. Shared Technical Risk Register

| Risk ID | Risk | Affected Classes | Required Mitigation Before Full Production |
|---|---|---|---|
| RSK-001 | Persistent-effect visual overload | All, especially Somnarch and Tidewrought | effect budgets, priority hierarchy, user density controls |
| RSK-002 | Proc and conversion recursion | Graftborn, Relic Host, Anachron, unique-heavy builds | event tags, conversion-depth caps, per-event trigger limits, deterministic logs |
| RSK-003 | Save migration failure | All | stable IDs, versioned migrations, refund/eject fallback behavior |
| RSK-004 | Boss mechanics nullify class identity | Somnarch, Gorgon, Tidewrought, Anachron | boss-pressure equivalents and explicit boss interaction tests |
| RSK-005 | Controller cognitive overload | Graftborn, Relic Host, Somnarch | loadout-driven targeting, contextual controls, out-of-combat radial configuration |
| RSK-006 | Modular animation explosion | Graftborn, Relic Host, Gorgon | shared geometry profiles, socket standards, limited silhouette archetypes |
| RSK-007 | Same-class state overwrite | All | source ownership, additive/shared-state rules, per-player attribution |
| RSK-008 | Forced movement damages encounter readability | Voidbringer, Tidewrought | immunity vocabulary, displacement budgets, telegraph preservation |
| RSK-009 | Temporal replay duplicates invalid effects | Anachron | curated imprint payloads; never replay arbitrary world state or unrestricted procs |
| RSK-010 | Territory systems dominate the whole screen | Somnarch, Tidewrought | bounded active structures, simplified distant rendering, hierarchy rules |

---

## 7. Prototype Validation Order

This order minimizes wasted implementation by testing the most dangerous shared assumptions early.

### P0 — Existing baseline

- Keep Voidbringer and Penitent as the gameplay and readability reference.
- Do not rewrite them from the proposed framework until shared terminology is approved.

### P1 — Graftborn vertical slice

Why first:

- validates persistent class state, body-region UI, stable-ID save requirements, deliberate transformation, and controller configuration;
- exposes animation and visual-combinatorics risk early;
- tests whether one base kit can support clearly different build identities.

Minimum slice:

- Biomass;
- Arms and Torso regions;
- two Major Adaptations per region;
- Rupture application and consumption;
- one Trauma Imprint;
- one cross-path synergy;
- one adaptation-order unique effect.

### P2 — Somnarch territory slice

Validates persistent zones, boss-safe control, AI interaction with imposed territory, and screen readability.

### P3 — Relic Host stance/council slice

Validates stateful loadouts, controlled possession, same-class interactions, trigger ownership, and controller ergonomics.

### P4 — Gorgon fixation slice

Validates attention targeting, threshold buildup, normal-enemy petrification, boss pressure, and counter readability.

### P5 — Tidewrought pressure-band slice

Validates resource bands, forced movement limits, persistent route structures, and environmental independence.

### P6 — Anachron temporal-imprint slice

Build last among the new bibles because it carries the highest systemic risk. Validate only curated own-action replay, deterministic payload capture, delayed consequences, and safe positional anchoring. Do not implement arbitrary world rewind.

---

## 8. Decision Ledger Template

Owner decisions should be recorded here or in a successor canonical ledger using the following format.

| Decision ID | Topic | Chosen Direction | Status | Date | Affected Documents | Required Follow-up |
|---|---|---|---|---|---|---|
| REV-A01 | Voidbringer naming | — | Open | — | Campaign, Voidbringer references, all roster tables | Normalize class name and stable ID |
| REV-A02 | Setting names | — | Open | — | Campaign and all class arcs | Replace temporary names consistently |
| REV-A03 | Ending model | — | Open | — | Campaign, endgame bridge | Define canonical post-campaign state |
| REV-A04 | Architect Below | — | Open | — | Campaign, bosses, future seasons | Finalize reveal structure |
| REV-A05 | Hollow King origin | — | Open | — | Opening act, Voidbringer, Penitent | Rewrite historical references |
| REV-B01 | Attributes | — | Open | — | Systems and itemization | Lock stat IDs and UI names |
| REV-B02 | Resistances | — | Open | — | Systems, loot, enemies | Lock player-facing defense model |
| REV-B03 | Class identity slot | — | Open | — | Every class bible | Normalize special-slot approach |
| REV-B04 | Respec economy | — | Open | — | Progression systems | Define currency and build-slot flow |
| REV-B05 | Endgame hierarchy | — | Open | — | Campaign and progression | Define launch versus post-launch scope |
| REV-C01 | Graftborn core | — | Open | — | Graftborn | Approve, revise, or hold |
| REV-C02 | Somnarch core | — | Open | — | Somnarch | Approve, revise, or hold |
| REV-C03 | Relic Host core | — | Open | — | Relic Host | Approve, revise, or hold |
| REV-C04 | Gorgon core | — | Open | — | Gorgon | Approve, revise, or hold |
| REV-C05 | Tidewrought core | — | Open | — | Tidewrought | Approve, revise, or hold |
| REV-C06 | Anachron core | — | Open | — | Anachron | Approve, revise, or hold |

---

## 9. Consistency Audit Result

### Direct contradictions

None found among the shared campaign proposal and the six newly completed class bibles.

### Naming inconsistency requiring owner action

The repository currently uses **Void Warlock** in existing material while the approved launch roster uses **Voidbringer**. This is not resolved in the proposed package.

### Deliberate overlaps requiring implementation discipline

- Voidbringer and Tidewrought both influence enemy position, but Voidbringer owns spatial/gravitational manipulation while Tidewrought owns pressure, current, and momentum.
- Graftborn and Gorgon both transform bodies, but Graftborn authors itself while Gorgon fixes and alters prey through attention, venom, and carapace states.
- Penitent and Somnarch both impose battlefield rules, but Penitent uses explicit ritual law and geometry while Somnarch creates hostile dream territory and clauses.
- Relic Host and Somnarch both manifest secondary presences, but Relic Host carries inherited persons while Somnarch produces dream witnesses and architecture.
- Anachron and Echo Thief may both repeat actions in broad language, but Anachron can only replay its own curated authored sequences; Echo Thief retains appropriation.
- Gorgon, Graftborn, and future Plaguebringer may all use biological payloads, but disease ecology and contagion remain reserved for Plaguebringer.

### Framework gaps intentionally left open

- final numerical curves;
- final damage coefficients;
- level cap;
- item rarity distribution;
- exact skill-point cadence;
- final skill-slot count;
- class-specific special-slot policy;
- respec cost;
- endgame launch scope;
- final campaign and region names.

These are correctly unresolved at concept-bible stage and should not be filled by guesswork.

---

## 10. Recommended Next Documentation Work

After owner review, perform these steps in order:

1. Record Gate A and Gate B decisions in this ledger.
2. Normalize terminology and stable IDs across all bibles.
3. Update or rewrite Voidbringer and Penitent bibles to the same format and depth.
4. Produce one shared skill-tag and combat-event specification.
5. Produce a class prototype acceptance-test document.
6. Build an itemization framework only after the class-slot and resistance decisions are approved.
7. Keep every unapproved narrative name or exact number marked PROPOSED.

Do not begin optional-mode modifier design until the persistent campaign, progression, equipment, and class foundations are approved.