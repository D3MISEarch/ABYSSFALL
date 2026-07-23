# AbyssFall Owner Decision Ledger

> Status: **OWNER DECISIONS RECORDED**  
> Decision date: **2026-07-23**  
> Human owner: **D3MISEarch**  
> Applies to: Draft PR #40, `design/overnight-world-class-bibles`  
> Review basis: Independent Claude review of head `b507c7c380170accf2c5d31cc97d3644c697593d`

## Authority rule

Only the human project owner may mark a decision as **OWNER APPROVED**, **REVISED**, **HELD**, or **DEFERRED**.

ChatGPT, Claude, Codex, Claude Code, or any other agent may:

- propose a decision ID;
- draft an approval record;
- verify consistency or technical feasibility;
- record a decision after the human owner explicitly gives it;
- prepare implementation issues for already approved slices.

No AI agent may independently convert proposed material into owner-approved, canonical, or implementation-authoritative material.

A pull-request merge by itself is not proof of owner approval. The decision ID and selected option must be recorded here or in a later owner-approved ADR.

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
- seasons and chapters adding to persistent characters rather than replacing them;
- build-changing unique items rather than simple numerical upgrades;
- optional temporary-modifier modes remaining deferred until the core ARPG foundation is proven.

**Unlocks:** Canonical progression principles, build-slot planning, save-continuity requirements, and bounded shared-system design.

## DEC-PR40-002 — Dark narrative and presentation identity

**Source:** Explicit human-owner direction on 2026-07-23  
**Status:** **OWNER APPROVED**

AbyssFall’s overall tone must be:

- dark;
- abysmal;
- dread-heavy;
- brutal and serious;
- mythic without becoming vague nonsense;
- cinematic without becoming a sequence of disconnected spectacle scenes;
- emotionally oppressive without becoming monotone;
- mature and visceral without relying on empty gore;
- mysterious without withholding every meaningful answer.

The quality target is the weight, dread, environmental mythology, cinematic seriousness, and campaign presence associated with top-tier dark action RPGs such as *Elden Ring* and *Diablo IV*. These are quality references only. AbyssFall must not copy their cosmology, characters, factions, plot turns, terminology, visual icons, bosses, quest structures, or lore delivery.

AbyssFall must stand out through its own:

- World-Lattice and anchoring cosmology;
- class-specific forms of damage, survival, and reality failure;
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
- No Marvel-style quipping during horror or tragedy.
- No clean heroic institutions secretly solving everything off-screen.
- No lore that exists only to imitate obscure fantasy prose.
- No villain whose complete motivation is “destroy the world because evil.”
- No class reduced to a brightly colored spell school.
- Hope may exist, but it must be costly, local, and earned.
- Victories stabilize, reclaim, expose, or delay catastrophe; they do not make the world harmless.

**Unlocks:** Narrative tone bible, dialogue standards, cinematic direction, region mood targets, boss-presentation rules, and originality checks.

---

# 2. World and campaign decisions

## DEC-PR40-003 — World-Lattice premise

**Source gate:** `REV-WORLD-01`  
**Owner selection:** REVISE AND RECONCILE  
**Status:** **REVISED — CORE RETAINED**

The World-Lattice premise is retained as the shared-world foundation, but it is not canonical until it is explicitly reconciled with the already-approved Voidbringer Codex.

Required reconciliation must preserve and map:

- the Black Measure;
- the Last Measure;
- Mass Anchors;
- Fold Lines;
- Instability;
- Breach and Clean Closure;
- Meridian Vaults;
- the Axis Vault;
- the Manifold Trials;
- Sable Marr;
- Edras Vey;
- the Stillpoint Engine;
- the Voidbringer’s role as a living Reference Body.

The campaign framework may broaden the cosmology but may not silently overwrite, genericize, or contradict those approved Voidbringer elements.

**Implementation authority:** None until reconciliation receives verification and owner acceptance.

## DEC-PR40-004 — Campaign scale

**Source gate:** `REV-WORLD-02`  
**Owner selection:** KEEP SIX ACTS AS THE COMPLETE CAMPAIGN VISION; SHIP A SMALLER FIRST PRODUCTION MILESTONE  
**Status:** **OWNER APPROVED WITH SCOPE CONDITION**

The six-act structure remains the intended complete campaign roadmap:

1. Sunken Crypts and the Hollow King
2. Red Basilica
3. Country Behind Sleep
4. Reliquary March
5. Inverted Sea
6. Hour Without End

Production must not treat six acts plus eight production-complete classes as one simultaneous first milestone.

Required production sequence:

- prove one polished campaign act and the core persistent ARPG loop;
- expand to a coherent early-campaign milestone rather than six disconnected biome demos;
- preserve the six-act narrative architecture for the complete campaign;
- avoid publicly promising all six acts for a date until measured production capacity supports it.

**Unlocks:** Act 01 production planning, six-act narrative architecture, and milestone breakdown. Does not unlock full six-act production at once.

## DEC-PR40-005 — Architect Below

**Source gate:** `REV-WORLD-03`  
**Owner selection:** KEEP DELIBERATELY AMBIGUOUS THROUGH LAUNCH  
**Status:** **OWNER APPROVED**

The launch campaign may provide evidence for multiple interpretations of the Architect Below but must not confirm a single final truth.

The Architect Below must remain distinct from Edras Vey. Edras is a specific Voidbringer class antagonist with a defined Stillpoint doctrine; the Architect Below is a larger unresolved cosmological question.

**Unlocks:** Ambiguous evidence design, competing faction interpretations, environmental storytelling, and expansion hooks.

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
- whether unusual classes such as Relic Host, Somnarch, and Anachron have meaningful scaling identities;
- whether broad attributes add buildcraft or merely imitate familiar ARPG conventions.

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

**Unlocks:** Respec UX requirements, build-slot behavior, economy assumptions, and refund-rule prototyping.

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
- A progression path may not be named Void Warlock without a separate owner decision, because that would preserve unnecessary ambiguity.

**Unlocks:** Terminology normalization plan, UI naming, campaign references, and future migration ADR planning.

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
- the beginner loop does not require managing the complete clause system immediately;
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

- Current Lines work in narrow halls, open arenas, obstacle-heavy rooms, and boss spaces;
- forced movement preserves encounter telegraphs;
- boss resistance and pressure conversion are deterministic;
- pressure remains mechanically and visually distinct from Voidbringer gravity;
- Hull Strain creates tension without punishing normal engagement with the class.

## DEC-PR40-015 — Anachron core

**Source gate:** `REV-CLS-ANA`  
**Owner selection:** HOLD IMPLEMENTATION PENDING DETERMINISTIC REPLAY SPIKE  
**Status:** **HELD**

The class bible remains preserved as a design candidate. No production implementation may begin until a narrow technical spike proves that own-action temporal replay can operate without:

- duplicate damage;
- duplicate rewards;
- recursive proc chains;
- invalid cooldown or resource restoration;
- collision-unsafe movement;
- restoration of destroyed world state;
- replaying actions against invalid or dead targets;
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

**Source:** Owner approval of the recommended response to Claude’s beginner-roster concern  
**Status:** **OWNER APPROVED**

AbyssFall will not add a generic warrior or elemental caster merely to imitate conventional launch-roster structure.

Instead, every class must provide:

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

# 9. Required PR #40 revision gates

Before PR #40 can leave draft status:

1. Reconcile the World-Lattice campaign framework with the approved Voidbringer Codex.
2. Add explicit beginner loops to all eight launch-class summaries.
3. Add explicit boss-safe behavior to every class summary.
4. Reframe six acts as the complete campaign vision with a smaller first production milestone.
5. Add Somnarch territory-readability prototype gates.
6. Add Relic Host combat-tempo prototype gates.
7. Add Tidewrought geometry and forced-movement prototype gates.
8. Mark Anachron implementation as held pending a technical spike.
9. Keep attributes and class-item-slot philosophy deferred.
10. Apply Voidbringer naming consistently while preserving `void_warlock` compatibility.
11. Encode the dark, abysmal, dread-heavy tone and originality guardrails.
12. Confirm that only the human owner may assign owner-approval status.
13. Submit the focused revision set for a narrow second independent review.

PR #40 remains draft and must not be merged until these gates are closed and the human owner authorizes the merge.