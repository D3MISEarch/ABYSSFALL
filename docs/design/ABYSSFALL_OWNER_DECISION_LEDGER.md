# AbyssFall Owner Decision Ledger

> Status: **OWNER DECISIONS RECORDED / SECOND REVIEW ACCEPTED / CONTROLLED CANONIZATION AUTHORIZED**  
> Decision date: **2026-07-23**  
> Human owner: **D3MISEarch**  
> Applies to: Draft PR #40, `design/overnight-world-class-bibles`  
> Initial review basis: independent review of head `b507c7c380170accf2c5d31cc97d3644c697593d`  
> Focused second-review basis: independent **PASS** at head `aa316861d2ef42b5ecc06e266be0c8d3f36737a3`  
> Owner acceptance event: **“Accepted, keep working.”** on 2026-07-23

## Authority rule

Only the human project owner may mark a decision as **OWNER APPROVED**, **REVISED**, **HELD**, or **DEFERRED**.

ChatGPT, Claude, Codex, Claude Code, or another agent may:

- propose a decision ID;
- draft an approval record;
- verify consistency or technical feasibility;
- record a decision after the human owner explicitly gives it;
- prepare implementation issues for already approved slices.

No AI agent may independently convert proposed material into owner-approved, canonical, or implementation-authoritative material.

A pull-request merge by itself is not proof of owner approval. The decision ID and selected option must be recorded here or in a later owner-approved ADR.

## Approval event record

### EVT-PR40-001 — Focused second review accepted

- **Reviewed head:** `aa316861d2ef42b5ecc06e266be0c8d3f36737a3`
- **Independent verdict:** PASS
- **Blocking revisions:** None
- **Owner response:** “Accepted, keep working.”
- **Authority granted:** controlled canonization of the approved decision-gate material
- **Authority not granted:** merge, gameplay implementation, scene changes, test changes, workflow changes, save-schema changes, or full-class production
- **PR state requirement:** PR #40 remains draft and unmerged until a later explicit owner merge authorization

---

# 1. Product and tone decisions

## DEC-PR40-001 — Persistent ARPG foundation

**Source gate:** `REV-SYS-01`  
**Owner selection:** APPROVE AS NON-NEGOTIABLE PRODUCT IDENTITY  
**Status:** **OWNER APPROVED**

AbyssFall is built on:

- persistent characters;
- persistent equipment;
- persistent class-specific trees;
- multiple saved builds;
- no mandatory in-combat “pick one of three” upgrade interruptions;
- no seasonal character resets;
- seasons and content chapters adding to persistent characters rather than replacing them;
- build-changing unique items rather than simple numerical upgrades;
- optional temporary-modifier modes remaining deferred until the core ARPG foundation is proven.

**Unlocks:** canonical progression principles, build-slot planning, save-continuity requirements, and bounded shared-system design.

## DEC-PR40-002 — Dark narrative and presentation identity

**Source:** explicit human-owner direction on 2026-07-23  
**Status:** **OWNER APPROVED**

AbyssFall’s overall tone must be:

- dark;
- abysmal;
- dread-heavy;
- brutal and serious;
- mythic without becoming vague nonsense;
- cinematic without becoming disconnected spectacle;
- emotionally oppressive without becoming monotone;
- mature and visceral without relying on empty gore;
- mysterious without withholding every meaningful answer.

The quality target includes the weight, dread, environmental mythology, cinematic seriousness, and campaign presence associated with top-tier dark action RPGs. Reference works are quality references only. AbyssFall must not copy another property’s cosmology, characters, factions, plot turns, terminology, visual icons, bosses, quest structures, combat systems, or lore delivery.

AbyssFall stands apart through its own:

- World-Lattice and incompatible anchoring cosmology;
- class-specific forms of damage, survival, duty, and reality failure;
- engineered body horror;
- ritual law;
- nightmare sovereignty;
- inherited dead intelligences;
- fixation and petrification;
- impossible pressure;
- authored temporal violence;
- Black Measure and Manifold mythology;
- persistent-character campaign structure.

### Tone guardrails

- No chosen-one worship.
- No tension-breaking quips during horror or tragedy.
- No clean heroic institution secretly solving everything off-screen.
- No lore written merely to imitate obscure fantasy prose.
- No villain whose complete motivation is “destroy the world because evil.”
- No class reduced to a brightly colored spell school.
- Hope may exist, but it must be costly, local, and earned.
- Victories stabilize, reclaim, expose, or delay catastrophe; they do not make the world harmless.

**Unlocks:** narrative tone standards, dialogue standards, cinematic direction, region mood targets, boss-presentation rules, soundtrack direction, and originality checks.

## DEC-PR40-019 — Creative north star synthesis

**Source:** explicit human-owner direction and confirmation on 2026-07-23  
**Status:** **OWNER APPROVED**

AbyssFall combines four quality targets while remaining an original universe:

1. **Physical brutality:** combat must feel violent, heavy, fast enough to remain aggressive, and materially destructive. Impact, execution, deformation, stagger, blood, debris, and enemy reaction must communicate force rather than decorative particles.
2. **Heavy soundtrack identity:** combat music should draw from crushing modern metal, industrial pressure, ritual ambience, hostile low-frequency design, catastrophic percussion, and selective choral or synthetic texture. The soundtrack must support pacing and dread rather than becoming an uninterrupted wall of noise.
3. **Dark campaign storytelling:** the campaign should carry tragedy, mystery, environmental history, memorable characters, oppressive regions, and mythic consequences without copying another game’s gods, demons, factions, map logic, dialogue style, or plot reveals.
4. **Deep action-RPG play:** responsive combat, meaningful loot, persistent progression, broad build diversity, class mastery, boss readability, and endgame depth are required. Complexity must produce real player choice rather than imitate another game’s passive tree, item economy, or skill structure.

These references define ambition and quality, not content. Every mechanic, faction, region, class, boss, item, visual motif, and musical identity must be translated through AbyssFall’s own cosmology.

---

# 2. World and campaign decisions

## DEC-PR40-003 — Reconciled World-Lattice foundation

**Source gate:** `REV-WORLD-01`  
**Owner selection:** APPROVE THE RECONCILED WORLD-LATTICE FOUNDATION  
**Status:** **OWNER APPROVED AT STRUCTURAL LEVEL AFTER FOCUSED REVIEW**

The World-Lattice is the shared world’s layered, continent-scale containment architecture. It is not a replacement name for the Black Measure, the Last Measure, or the Meridian Vaults.

The approved relationship is:

- **World-Lattice:** the global family of incompatible containment systems built, inherited, repaired, weaponized, and partly forgotten across multiple civilizations;
- **Black Measure:** the approved spatial failure domain of rejected positions, unresolved locations, distances never traveled, and impossible Mass;
- **Last Measure:** the specialist engineering order that discovered impossible Mass and developed Manifold practice;
- **Meridian Vaults:** the Last Measure’s spatial-reference subsystem within the wider Lattice;
- **Axis Vault:** the Last Measure’s attempt to create a universal coordinate;
- **Integrated Manifold Harness:** the living interface that makes a Voidbringer a Reference Body capable of choosing which position matters;
- **Mass Anchors, Fold Lines, Instability, Breach, and Clean Closure:** protected Voidbringer vocabulary and functions, never genericized into ordinary gravity magic;
- **Manifold Trials:** load-bearing Voidbringer class progression integrated as optional class-specific content inside the one shared campaign;
- **Edras Vey and the Stillpoint Engine:** the complete Voidbringer personal-antagonist arc, distinct from the Architect Below.

The shared campaign may broaden the cosmology but may not silently overwrite, genericize, or contradict the approved Voidbringer Codex.

**Implementation authority:** structural narrative planning only. No gameplay or save-system authority is granted by this decision.

## DEC-PR40-004 — Campaign scale

**Source gate:** `REV-WORLD-02`  
**Owner selection:** KEEP SIX ACTS AS THE COMPLETE CAMPAIGN VISION; SHIP A SMALLER FIRST PRODUCTION MILESTONE  
**Status:** **OWNER APPROVED WITH SCOPE CONDITION**

The intended complete campaign roadmap is:

1. Sunken Crypts and the Hollow King
2. Red Basilica
3. Country Behind Sleep
4. Reliquary March
5. Inverted Sea
6. Hour Without End

Production must not treat six acts plus eight production-complete classes as one simultaneous first milestone.

Required production sequence:

- prove one polished campaign act and the core persistent ARPG loop;
- expand to a coherent early-campaign milestone rather than disconnected biome demos;
- preserve the six-act narrative architecture for the complete campaign;
- avoid publicly promising a full six-act delivery date until measured production capacity supports it.

**Unlocks:** Act 01 planning, six-act narrative architecture, and milestone breakdown. Does not unlock full six-act production at once.

## DEC-PR40-005 — Architect Below

**Source gate:** `REV-WORLD-03`  
**Owner selection:** KEEP DELIBERATELY AMBIGUOUS THROUGH LAUNCH  
**Status:** **OWNER APPROVED**

The launch campaign may provide evidence for multiple interpretations of the Architect Below but must not confirm a single final truth.

The Architect Below remains distinct from Edras Vey. Edras is a specific Voidbringer class antagonist with a defined Stillpoint doctrine; the Architect Below is a larger unresolved cosmological question.

**Unlocks:** ambiguous evidence design, competing faction interpretations, environmental storytelling, and expansion hooks.

## DEC-PR40-020 — Milestone A class-personal mission

**Source:** owner acceptance of the focused second-review follow-up  
**Status:** **OWNER APPROVED FOR CAMPAIGN-PLANNING SCOPE**

The first Act 01 vertical-campaign milestone will use **Penitent** for the required class-personal mission integration because Penitent is the most production-ready playable class in the current build.

Voidbringer remains the deeper flagship class integration and should follow once the shared campaign structure and existing runtime loop have been proven together.

This decision:

- avoids using an unimplemented proposed class to prove campaign integration;
- does not reduce the importance or depth of Voidbringer’s approved Codex arc;
- does not authorize a new Penitent gameplay implementation branch;
- requires any actual mission implementation to receive its own issue, acceptance criteria, branch, playtest requirements, and owner authorization.

---

# 3. Shared-system decisions

## DEC-PR40-006 — Primary attributes

**Source gate:** `REV-SYS-02`  
**Owner selection:** DEFER UNTIL ITEMIZATION PROTOTYPE  
**Status:** **DEFERRED**

`Might / Finesse / Will / Vitality` remains non-authoritative placeholder language.

No final attribute names, scaling model, equipment requirements, or character-sheet layout may be locked before a focused itemization prototype demonstrates:

- how offensive and defensive scaling works across multiple class fantasies;
- whether Vitality becomes universally mandatory;
- whether unusual classes have meaningful scaling identities;
- whether broad attributes add buildcraft or merely imitate familiar conventions.

## DEC-PR40-007 — Class-item-slot philosophy

**Source gate:** `REV-SYS-03`  
**Owner selection:** PROTOTYPE ONE CLASS FIRST BEFORE CHOOSING  
**Status:** **DEFERRED PENDING PROTOTYPE**

The project does not yet approve:

- one universal dedicated class slot;
- eight unrelated bespoke slot systems;
- mandatory use of normal equipment slots;
- removal of class-item concepts.

The Graftborn vertical slice must remain slot-agnostic and test identity value, UI cost, loot-table complexity, save behavior, and cross-class fairness before a global rule is chosen.

## DEC-PR40-008 — Respec philosophy

**Source gate:** `REV-SYS-04`  
**Owner selection:** MULTIPLE SAVED BUILDS + LOW-COST COMMON-CURRENCY RESPEC  
**Status:** **OWNER APPROVED**

Rules:

- multiple saved builds reduce repetitive rebuilding;
- respec uses existing common progression currency rather than a bespoke respec currency;
- early experimentation should be free or nearly free;
- endgame changes may have a low, understandable cost;
- the system must not force repetitive farming simply to correct or test a build;
- no respec action occurs during combat.

**Unlocks:** respec UX requirements, build-slot behavior, economy assumptions, and refund-rule prototyping.

---

# 4. Naming decision

## DEC-PR40-009 — Voidbringer naming

**Source gate:** `REV-NAME-01`  
**Owner selection:** VOIDBRINGER IS THE FINAL PLAYER-FACING CLASS NAME; `void_warlock` IS COMPATIBILITY-ONLY  
**Status:** **OWNER APPROVED**

Rules:

- Player-facing class name: **Voidbringer**.
- Canonical design ID: `voidbringer`.
- Existing runtime/save ID `void_warlock` remains only where required for compatibility until a versioned migration is separately approved.
- “Void Warlock” must not be presented as the final class name in new player-facing documentation, marketing, UI, or lore.
- A progression path may not be named Void Warlock without a separate owner decision.

**Unlocks:** terminology normalization planning, UI naming, campaign references, and future migration ADR planning.

---

# 5. Class-core decisions

## DEC-PR40-010 — Graftborn core

**Source gate:** `REV-CLS-GRF`  
**Owner selection:** APPROVE CORE  
**Status:** **OWNER APPROVED**

Protected identity:

- authored anatomy;
- Biomass;
- Body Regions;
- Major Adaptations;
- Trauma Imprints;
- Rupture;
- deliberate bodily commitment rather than random mutation.

Approval covers the class thesis and owned design territory. It does not canonize every skill, item, number, path name, lore name, or full animation matrix.

## DEC-PR40-011 — Gorgon core

**Source gate:** `REV-CLS-GOR`  
**Owner selection:** APPROVE CORE  
**Status:** **OWNER APPROVED**

Protected identity:

- attention as a combat resource;
- Exposed prey;
- Fixation;
- Lock States;
- deliberate petrification;
- Monument Pressure against bosses;
- reflection and counterplay;
- venom families without disease ecology.

Approval covers the class thesis and owned design territory. It does not authorize full implementation.

## DEC-PR40-012 — Somnarch core

**Source gate:** `REV-CLS-SOM`  
**Owner selection:** REVISE PENDING TERRITORY-READABILITY PROTOTYPE  
**Status:** **REVISED / NOT IMPLEMENTATION APPROVED**

Required proof:

- Sovereign Dream works in irregular arenas;
- Dream Clauses remain readable in dense packs;
- controller inputs remain understandable;
- enemy and boss telegraphs remain visible;
- the beginner loop does not require complete Clause management immediately;
- boss interaction remains meaningful without permanent hard control.

## DEC-PR40-013 — Relic Host core

**Source gate:** `REV-CLS-RLH`  
**Owner selection:** REVISE PENDING COMBAT-TEMPO PROOF  
**Status:** **REVISED / NOT IMPLEMENTATION APPROVED**

Required proof:

- Council composition is long-term buildcraft, not constant menu interruption;
- Presence rotation is fast, tactile, and usable during combat;
- Memory Conditions reward active play;
- Investiture visibly changes combat posture and skill behavior;
- the player never loses agency to possession;
- the class does not collapse into passive aura stacking.

## DEC-PR40-014 — Tidewrought core

**Source gate:** `REV-CLS-TID`  
**Owner selection:** REVISE PENDING ARENA-GEOMETRY AND FORCED-MOVEMENT PROOF  
**Status:** **REVISED / NOT IMPLEMENTATION APPROVED**

Required proof:

- Current Lines work across narrow, open, obstacle-heavy, and boss arenas;
- forced movement preserves encounter telegraphs;
- boss resistance and pressure conversion are deterministic;
- pressure remains mechanically and visually distinct from Voidbringer gravity;
- Hull Strain creates tension without punishing normal engagement.

## DEC-PR40-015 — Anachron core

**Source gate:** `REV-CLS-ANA`  
**Owner selection:** HOLD IMPLEMENTATION PENDING DETERMINISTIC REPLAY SPIKE  
**Status:** **HELD**

The class bible remains preserved as a design candidate. No production implementation may begin until a narrow technical spike proves own-action temporal replay without:

- duplicate damage;
- duplicate rewards;
- recursive proc chains;
- invalid cooldown or resource restoration;
- collision-unsafe movement;
- restoration of destroyed world state;
- replay against invalid or dead targets;
- cross-session or co-op desynchronization.

Anachron may replay only the player’s curated authored actions. Enemy ability, voice, identity, or behavior appropriation remains Echo Thief territory.

---

# 6. Graftborn vertical-slice decision

## DEC-PR40-016 — First new-class vertical slice

**Owner selection:** APPROVE GRAFTBORN AS THE FIRST NEW-CLASS PROTOTYPE DIRECTION  
**Status:** **OWNER APPROVED FOR BOUNDED PLANNING**

Minimum slice:

- Biomass;
- Arms and Torso Body Regions only;
- two Major Adaptations per region;
- Rupture application and consumption;
- one Trauma Imprint;
- one cross-path interaction;
- one build-changing unique effect;
- explicit beginner-loop tutorial and controller readability;
- explicit boss-safe Rupture behavior;
- item-slot implementation remains agnostic pending `DEC-PR40-007`.

This decision unlocks an implementation brief and issue proposal. It does not authorize code changes until a separate implementation issue, acceptance criteria, branch, and owner go-ahead exist.

---

# 7. Beginner-accessibility requirement

## DEC-PR40-017 — Low floor, high ceiling

**Source:** owner approval of the recommended response to the beginner-roster concern  
**Status:** **OWNER APPROVED**

AbyssFall will not add a generic warrior or elemental caster merely to imitate conventional launch-roster structure.

Every class must provide:

- a one-sentence beginner promise;
- a simple starter combat loop;
- gradual introduction of secondary systems;
- a viable starter build without external research;
- advanced mastery through sequencing, positioning, synergy, and build knowledge;
- readable boss interaction;
- depth that is earned rather than front-loaded.

Complexity is allowed. Immediate administrative overload is not.

---

# 8. Canonization and implementation authority

## DEC-PR40-018 — Approval hierarchy

**Status:** **OWNER APPROVED**

The authority hierarchy is:

1. explicit human-owner decision;
2. owner decision ledger or approved ADR;
3. canonical normalized design documentation;
4. approved bounded implementation issue;
5. code, assets, tests, and playtest evidence.

Below that hierarchy are:

- AI recommendations;
- verification reports;
- chat summaries;
- proposed documents;
- unmerged drafts.

No proposed document may quietly become implementation authority.

---

# 9. PR #40 revision-gate result

The focused second review at head `aa316861d2ef42b5ecc06e266be0c8d3f36737a3` returned **PASS** with no blocking revisions. The human owner accepted that result and authorized a controlled canonization pass.

Closed revision gates:

1. World-Lattice reconciled with the approved Voidbringer Codex.
2. Beginner loops defined for all eight launch-class summaries.
3. Boss-safe behavior defined for all eight class summaries.
4. Six acts reframed as complete vision with smaller production milestones.
5. Somnarch territory-readability gate defined.
6. Relic Host combat-tempo gate defined.
7. Tidewrought geometry and forced-movement gate defined.
8. Anachron implementation held pending a deterministic replay spike.
9. Attributes and class-item-slot philosophy remain deferred.
10. Voidbringer naming normalized while `void_warlock` compatibility remains protected.
11. Dark, abysmal, dread-heavy tone and originality rules encoded.
12. Human-only owner-approval authority encoded.
13. Focused second independent review completed and accepted.

PR #40 remains draft and must not be merged until the owner separately reviews the canonization diff and explicitly authorizes merge.