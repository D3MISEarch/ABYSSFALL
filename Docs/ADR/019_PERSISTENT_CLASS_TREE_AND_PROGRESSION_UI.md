# ADR-019 — Persistent Class Tree and Progression UI

- **Status:** OWNER APPROVED AT DESIGN-FOUNDATION LEVEL
- **Decision date:** 2026-07-23/24
- **Human owner:** D3MISEarch
- **Implementation authority:** NONE BY DEFAULT
- **Implementation dependency:** PR #34 durable runtime/persistence foundation must merge before production work begins
- **Primary implementation tracker:** Issue #46

## 1. Context

The current graphical prototype still uses an older roguelite-style level-up flow:

1. combat pauses;
2. a full-screen panel presents three branch cards;
3. the player must choose immediately before play continues.

That behavior was useful as early prototype scaffolding, but it conflicts with AbyssFall's approved product identity:

- persistent characters;
- persistent equipment;
- persistent class-specific progression;
- deep pre-combat buildcraft;
- no mandatory in-combat pick-one-of-three upgrade interruption;
- no seasonal character resets.

During the owner graphical playtest of PR #34, the owner reaffirmed that leveling should feel closer to a persistent action-RPG model: gain a point, then decide where to spend it in a dedicated class tree rather than being interrupted by a temporary randomized choice.

The owner also approved the long-term presentation target: a premium, large-scale, zoomable class tree with strong visual hierarchy and class-specific AbyssFall art, inspired by the usability and commitment of leading action-RPG progression boards without copying another game's artwork, topology, node language, economy, or exact interaction design.

## 2. Decision

AbyssFall will use a **persistent class-point progression model** presented through a **large, zoomable, pannable, class-specific progression board**.

The shared framework must feel consistent across classes, while every class receives its own visual language, spatial composition, node motifs, and thematic presentation.

The tree must look complex from a distance but become understandable when the player focuses on one local cluster.

## 3. Leveling law

### 3.1 Point awards

1. Each eligible character level grants one persistent class progression point unless a separately approved class rule changes the award schedule.
2. Multiple levels gained from one reward grant award every expected point exactly once.
3. Unspent points may be carried indefinitely.
4. Unspent and spent points survive save, quit, reload, and character rebinding.
5. Leveling displays a brief, restrained, non-blocking notification.
6. Leveling must never pause combat or force immediate tree interaction.

### 3.2 Class-flavored point names

Classes may use distinct player-facing point names while sharing safe underlying contracts.

Examples:

- Voidbringer: **Void Points**;
- other class names remain subject to their own approved design work.

The underlying persistence and validation model should remain reusable where possible.

### 3.3 Primary attributes remain deferred

This decision does **not** approve a universal Might/Finesse/Will/Vitality-style attribute system.

Primary attribute names, scaling, equipment requirements, and character-sheet presentation remain deferred pending the focused itemization prototype. ADR-019 concerns class progression points and class-tree allocation only.

## 4. Tree interaction framework

The class tree must support:

- zooming;
- panning;
- mouse interaction;
- controller navigation;
- clear focus state;
- visible available-point count;
- visible node costs and ranks;
- prerequisite highlighting;
- unavailable-node explanation;
- confirmation and error feedback;
- search or keyword filtering when tree scale requires it;
- a dedicated respec/refund mode;
- immediate return to play without stale pause state.

Tree interaction belongs in a dedicated menu or explicitly safe state. It is not an in-combat interruption.

## 5. Shared node grammar

All class trees should use a consistent functional language even when their artwork differs.

### 5.1 Minor nodes

Small numerical or efficiency improvements that support a nearby mechanic. They must not dominate the board with meaningless filler.

### 5.2 Notables

Meaningful mechanical improvements that materially strengthen or combine a local cluster.

### 5.3 Active-skill nodes

Unlock a player-usable active skill or a major class action.

### 5.4 Refinement and mutation nodes

Change how an active skill behaves. Mutation branches may be mutually exclusive unless an approved item, keystone, or class rule breaks that restriction.

### 5.5 Keystones

Powerful rule changes with real tradeoffs. A keystone should change priorities, sequencing, positioning, resource behavior, or risk—not merely add a large percentage.

### 5.6 Capstones

Build-defining endpoints that complete a major progression direction.

### 5.7 Trial or class-encounter nodes

Rewards earned through class-specific progression content such as Manifold Trials. These should communicate that the point came from mastery or narrative progression rather than ordinary leveling.

### 5.8 Bridge nodes

Connections that enable hybrid builds between major clusters without allowing every character to purchase everything.

## 6. Spatial hierarchy

The exact topology remains prototype-bound, but the intended hierarchy is:

### 6.1 Central core

The class's foundational identity and non-optional mechanic live near the center.

### 6.2 Inner progression

Readable early directions introduce the main play patterns without overwhelming a new player.

### 6.3 Middle transformation clusters

Build-changing mechanics, skill mutations, cross-cluster combinations, and serious specialization appear here.

### 6.4 Outer keystones and capstones

High-commitment rule changes and defining endpoints sit at the outer reaches or other visually significant positions.

The board may use rings, branches, organs, territories, timelines, reliquaries, pressure contours, sightlines, or another class-specific composition. It must not force every class into one recolored radial template.

## 7. Voidbringer visual direction

The Voidbringer tree should resemble a damaged **World-Lattice / Manifold engineering schematic**, not a generic magical constellation.

Approved visual ingredients include:

- a fractured central coordinate representing the Reference Body;
- bent spatial axes;
- Mass Anchor clusters;
- Fold Lines connecting mechanics and paths;
- nodes slightly displaced from their expected coordinates;
- black restraint metal and warped machinery;
- pale coordinate-white measurement marks;
- restrained purple fractures and spatial wounds;
- clamps, bolts, plates, harness anatomy, and Meridian engineering language;
- subtle local distortion that never harms readability.

The board may react subtly to cursor or focus movement, and purchased paths may visually tighten, align, or stabilize. Motion must remain restrained and comfort-safe.

## 8. Class-specific visual identity

The shared interaction framework should transform around each class.

Non-binding visual examples:

- **Penitent:** cathedral geometry, carved flesh, Brands, Circles, nails, wax seals, reliquaries, and blood channels;
- **Graftborn:** anatomical diagrams, nerves, tendons, organs, surgical seams, and body-region structures;
- **Somnarch:** sovereign dream territories, clauses, constellations, and controlled visual rearrangement;
- **Relic Host:** reliquary networks and a dead council of inherited intelligences;
- **Gorgon:** sightlines, reflected gaze geometry, mineral veins, Fixation patterns, and forming monuments;
- **Tidewrought:** pressure maps, depth contours, ruptured hull geometry, trenches, and impossible currents;
- **Anachron:** fractured timelines, authored sequences, delayed consequences, and mutually exclusive histories.

These examples guide art exploration. They do not canonize final layouts, names, node counts, or visual assets.

## 9. Readability and accessibility laws

1. Purchased, available, blocked, highlighted, refunded, and previewed states must be distinguishable without relying only on hue.
2. Text and icons must remain readable at intended gameplay resolutions.
3. Controller navigation must have deterministic neighboring-node behavior.
4. Focus must never disappear off-screen during zoom or pan.
5. Search results must clearly indicate their location and path requirements.
6. The tree may be visually dense, but local prerequisite flow must be legible.
7. Decorative animation must not obscure node connections or cause motion discomfort.
8. Respec mode must clearly communicate cost, affected nodes, and resulting refunds before confirmation.
9. Failed purchases or refunds must leave progression state unchanged and explain the failure.
10. The player may close the tree at any time when no confirmation transaction is active.

## 10. Respec direction

The previously approved philosophy remains:

- early experimentation is free or nearly free;
- later respec uses an existing common progression currency rather than a bespoke respec token;
- costs remain low and understandable;
- no respec action occurs during combat;
- multiple saved builds reduce repetitive rebuilding.

Exact costs and refund rules remain prototype and economy outputs.

## 11. Prototype sequence

Implementation must proceed in bounded stages:

1. merge and preserve PR #34's durable runtime/persistence foundation;
2. remove the mandatory three-card interruption;
3. award and persist class progression points;
4. implement data-driven node definitions, prerequisites, ranks, and atomic spending;
5. build a functional zoomable/pannable tree using placeholder shapes;
6. prove mouse and controller navigation;
7. prove save/reload, rebinding, and respec-safe contracts;
8. run a graphical readability and comfort test;
9. only then invest in final class-specific art, animation, audio, and VFX.

The first implementation slice must remain compact. It must not attempt the complete level-1-to-50 production tree for all launch classes in one pull request.

## 12. Non-authoritative details

The following remain open until prototype evidence exists:

- exact board topology;
- exact node count;
- exact point costs;
- exact zoom limits and pan speed;
- exact controller neighbor graph;
- final skill and passive names;
- final node icons;
- final class-tree art assets;
- final animation and sound treatment;
- final respec costs;
- final universal attribute system;
- whether every class uses identical structural geometry;
- exact search/filter behavior;
- final level cap and post-cap progression for classes without an approved bible.

## 13. Rejected direction

The campaign's core progression will not use mandatory randomized one-of-three cards on every level-up.

Optional temporary modifier systems may be explored later for specifically approved game modes, but they may not replace the persistent class tree or interrupt normal campaign combat by default.

## 14. Implementation gate

ADR-019 grants design authority only.

No production code may begin until:

1. PR #34 is merged into `main`;
2. Issue #46 receives a bounded implementation brief;
3. the implementation branch is isolated from unrelated work;
4. deterministic persistence and spending tests are specified;
5. graphical acceptance criteria are specified;
6. the human owner authorizes the implementation pass.

Any implementation PR remains draft and unmerged until CI, independent verification, graphical playtesting, and explicit owner merge authorization are complete.

## 15. Consequences

### Positive

- aligns leveling with AbyssFall's persistent ARPG identity;
- removes combat-flow interruption;
- supports meaningful long-term build investment;
- creates a reusable framework without flattening class identity;
- allows premium visual presentation after usability is proven;
- preserves future optional modes without corrupting campaign progression.

### Costs and risks

- requires a real progression data model and allocation UI;
- increases controller-navigation and accessibility complexity;
- requires careful persistence and atomic transaction handling;
- class-specific art will be expensive and must be sequenced after framework proof;
- visual complexity can become unreadable if node grammar and hierarchy are not enforced.

These costs are accepted because the persistent class tree is central to the intended game rather than optional polish.