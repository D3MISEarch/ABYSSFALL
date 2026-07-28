# Issue #59 — Sunken Crypts Art Pass 0 Implementation Brief

## Goal

Transform the existing playable courtyard into a recognizable early AbyssFall environment without changing combat layout, collision, progression, encounter sequencing, persistence, or input.

## Starting point

Exact stacked base:

`bff092654589e0bf16952020c34b54e1035102bb`

This branch sits above PRs #50, #54 and #56. It must remain isolated until the lower stack resolves.

## Approved target

The visual language is:

- drowned crypt stone;
- fractured obsidian;
- rusted restraint machinery;
- cold gravitational-white light;
- restrained violet fractures;
- localized corruption-green residue;
- blood, bone, chains, cages and broken ritual hardware;
- readable darkness with combat silhouettes preserved.

The approved concept boards from the owner review are implementation targets. They are not claims of final production art. Repository copies will be added as part of the frozen visual handoff after the first playable pass is proven.

## Phase 0A implementation

The first implementation is procedural and replaceable:

- central material palette helper;
- visual-only courtyard tile overlay;
- subdued ritual rings and fracture lines;
- crypt wall bays and sealed slabs;
- restraint machines;
- hanging cages and chains;
- localized corruption residue;
- rubble and bone dressing;
- controlled courtyard lighting;
- retinted base floor, walls and courtyard pillars.

All added geometry is decorative. The art controller must not add collision objects or mutate gameplay state.

## Follow-up phases

### Phase 0B

Upgrade Void Bolt, Grasping Rift and Shadow Step while preserving gameplay constants.

### Phase 0C

Add lightweight atmosphere helpers, loot presentation and the first interface skin pass after the environment shell is proven readable and performant.

## Tests

`tests/test_art_pass0_visual_contract.gd` proves:

- the visual controller installs exactly once;
- required visual groups exist;
- a meaningful modular shell is produced;
- controlled lights are installed;
- no collision objects are introduced.

Existing project workflows remain authoritative for all gameplay and persistence regressions.
