# Issue #46 — Persistent Class Progression Implementation Brief

- **Status:** DESIGN/HANDOFF BRIEF — NO CODE AUTHORITY
- **Parent decision:** ADR-020
- **Tracker:** Issue #46
- **Dependency:** PR #34 must merge into `main` before any implementation branch begins
- **Required working model:** separate bounded implementation PRs, independent verification, graphical playtest, owner merge authorization

> **ADR sequence note:** ADR-018 and ADR-019 belong to the pending runtime/itemization lineage. The class-tree decision is intentionally numbered ADR-020 to prevent a future collision during branch reconciliation.

## 1. Goal

Replace the legacy mandatory three-card level-up interruption with a durable, deterministic class-point progression foundation and a functional zoomable class-tree prototype.

The first delivery must prove the architecture and interaction model. It must not attempt final art or the complete production tree for every class.

## 2. Required delivery sequence

Issue #46 is a parent milestone and should be delivered through two bounded implementation slices.

### Slice 46A — Runtime progression foundation

Headless/runtime scope only:

- persistent point-award ledger;
- persistent node allocations;
- immutable class-tree definitions;
- prerequisite, rank, cost, and exclusion validation;
- atomic spending;
- JSON round-trip persistence;
- RuntimeSession ownership and event routing;
- deterministic stat/effect projection;
- no graphical tree implementation.

### Slice 46B — Graphical tree shell and legacy-flow removal

Graphical integration scope:

- remove the mandatory level-up card interruption from the current playable prototype;
- add a restrained, non-blocking level-up notification;
- add a placeholder-art zoomable/pannable tree screen;
- display points, ranks, prerequisites, available and blocked states;
- support keyboard/mouse and controller navigation;
- connect UI transactions to the runtime progression service;
- preserve gameplay continuity and save behavior;
- test multiple aspect-ratio and UI-scale profiles;
- test a deliberately dense navigation layout rather than only a sparse proof tree.

Do not combine final class-tree art production with either slice.

## 3. Durable source of truth

`BuildData.class_tree_state` is the durable source of truth for class-point awards and node allocation.

Existing durable fields must retain their responsibilities:

- `level` and `experience`: character progression;
- `class_tree_state`: point awards and class-tree allocations;
- `skills`: unlocked ability/loadout compatibility data until a later migration explicitly changes that contract;
- `equipped_gear`: equipped item state;
- `build_specific_progress`: inventory, item-identity allocator, and other class/run-specific data.

Do not store the tree only in a UI node, graphical player script, singleton, or temporary run object.

## 4. Proposed class-tree-state schema

The first schema should be versioned and duplication-resistant.

```gdscript
{
    "schema_version": 1,
    "award_ledger": {
        "level:2": 1,
        "level:3": 1,
        "trial:example_source": 1,
    },
    "allocations": {
        "node_id": 1,
        "ranked_node_id": 2,
    },
}
```

### 4.1 Award ledger

- Each award has a stable source ID.
- A source ID may be applied only once.
- Level awards use the reached level, such as `level:2`.
- Class encounters and quest rewards use stable authored IDs.
- Replaying a signal, reloading, or rebinding must not duplicate an existing source.
- Award amounts must be positive integers.

### 4.2 Available points

Available points are derived rather than independently trusted:

`total awarded points - total allocation cost`

Do not persist a second mutable `unspent_points` value that can disagree with the award ledger and allocations.

### 4.3 Allocations

- Key: stable node ID.
- Value: purchased rank.
- Zero-rank entries are omitted.
- Unknown, negative, over-ranked, unaffordable, prerequisite-invalid, or mutually exclusive allocations must not be silently accepted.
- A restore that cannot be safely migrated must fail transactionally rather than partially applying progression.

## 5. Runtime architecture

### 5.1 Immutable definitions

Add immutable data objects equivalent in discipline to item and ability definitions.

Suggested responsibilities:

#### `ClassTreeNodeDefinition`

- `node_id`;
- `node_type`;
- `display_name`;
- `description`;
- `maximum_rank`;
- `point_cost_per_rank` or explicit rank costs;
- prerequisite node/rank requirements;
- mutually exclusive group when needed;
- effect descriptors;
- UI metadata that does not contain live state.

Shared functional node types should use AbyssFall-native terminology from ADR-020, including **Law Node** for major rule-changing nodes and **Culmination Node** for build-defining endpoints. Class-specific display aliases may be added later without changing durable type semantics.

#### `ClassTreeDefinition`

- canonical/compatibility class ID;
- schema/version identity;
- node catalog;
- root/start nodes;
- level-point award schedule;
- optional class-specific point display name;
- validation of definition integrity.

Definitions are immutable after registration.

### 5.2 Mutable progression state

Add a mutable progression state object responsible for:

- restoring validated award and allocation snapshots;
- deriving available points;
- awarding a stable source atomically;
- validating a proposed purchase;
- purchasing one rank atomically;
- previewing refunds without mutation;
- serializing durable state;
- rebuilding progression effects deterministically.

### 5.3 Session composition

`RuntimeSession` remains the composition root.

It should own or configure the active class-progression service alongside inventory, equipment, ability execution, and item identity.

Required bind behavior:

1. construct temporary progression state;
2. select the immutable tree definition for the character class;
3. restore and validate the pending tree snapshot;
4. rebuild effects into temporary/replaceable state;
5. only after full success attach it to the active character/session;
6. failed binding preserves the previously active session and signal wiring.

No autoload or hidden global progression registry may be added.

### 5.4 Character integration

`RuntimeCharacter.gain_experience()` already emits one `level_gained` signal for every level reached. The progression service must convert those reached levels into idempotent award-source entries.

Multiple-level gains must award every eligible point exactly once.

The durable runtime snapshot must include `class_tree_state` without dropping inventory, equipment, item identity, level, XP, or abilities.

## 6. Effect application

Tree effects must be rebuilt from allocations, not cumulatively stacked every time a build loads.

Rules:

- stat effects use stable source IDs and replacement/recomputation semantics;
- rebinding the same build cannot duplicate modifiers;
- refunding removes only the affected node/rank sources;
- active-skill unlock effects must be deterministic and compatible with the existing unlocked-ability contract;
- failed purchases emit no success event and apply no stat, resource, or ability change;
- first slice may limit its proof nodes to passive/stat effects if active-skill projection would widen scope.

The tree state is the source for allocation. UI labels and graphical highlights are projections only.

## 7. First proof content and navigation stress fixture

### 7.1 Framework-proof gameplay tree

Use one compact framework-proof tree rather than the full level-1-to-50 production tree.

Recommended proof characteristics:

- one root/core node;
- two readable early directions;
- at least one ranked minor node;
- at least one notable node;
- one cross-path bridge;
- one prerequisite chain;
- one Law Node or tradeoff rule only if it can be implemented without widening the slice;
- one Culmination Node only if it improves proof coverage rather than pretending the proof is final content;
- approximately 7–12 nodes total.

Existing Abyss/Corruption/Soulbinding prototype data may be reused as temporary scaffolding, but the proof content must be marked non-final and must not silently overwrite the approved definitive Voidbringer bible.

### 7.2 Dense controller-navigation stress fixture

The 7–12-node gameplay tree is sufficient for persistence and allocation architecture but is not sufficient by itself to prove controller navigation at scale.

Slice 46B must also include a non-production navigation stress fixture or test scene containing approximately 20–30 placeholder nodes with:

- at least one deliberately dense cluster;
- two or more nearly equidistant directional candidates;
- nodes that begin outside the initial viewport;
- crossing or closely parallel visual paths;
- a long-distance jump that must not steal ordinary directional focus;
- nodes near safe-area and side-panel boundaries;
- at least one non-radial arrangement.

This fixture does not need durable gameplay effects and must not be mistaken for a production class tree. It exists to expose ambiguous neighbor selection, focus loss, pan/zoom coupling, overlap, and off-screen navigation failures before final content scales up.

### 7.3 Player-facing terminology

- use **Voidbringer** rather than Void Warlock in new UI;
- use **Void Points** for the Voidbringer proof;
- use **Law Node** and **Culmination Node** as shared functional terminology unless a separately approved class-local display name is shown;
- keep runtime/save ID compatibility isolated behind shared class-ID authority;
- do not invent a final Penitent point name without owner approval.

## 8. Slice 46A acceptance criteria

### 8.1 Awarding

1. Level 1 to 2 awards exactly one `level:2` source.
2. A multi-level XP grant records each reached level exactly once.
3. Reprocessing an already recorded level source adds nothing.
4. Invalid or non-positive award amounts change nothing.
5. Award events identify build ID, source ID, amount, and resulting available points.

### 8.2 Spending

1. A valid node purchase deducts derived availability by the exact cost.
2. Insufficient points reject without mutation.
3. Missing prerequisites reject without mutation.
4. Maximum rank cannot be exceeded.
5. Mutually exclusive rules are enforced when present.
6. Unknown node IDs reject without mutation.
7. Failed spending emits no success event and changes no effect state.

### 8.3 Persistence

1. Award ledger and allocations survive real `JSON.stringify` / `JSON.parse_string` / `BuildData.from_dict` round trip.
2. Runtime durable snapshot includes `class_tree_state` while preserving all PR #34 durable fields.
3. Rebinding restores identical points, allocations, stats, inventory, equipment, abilities, and item identity.
4. Invalid progression restoration leaves the active session untouched.
5. Rebinding does not duplicate effects or point awards.

### 8.4 Determinism

1. Same definition and same state produce identical derived availability and effects.
2. Definition iteration order cannot change results.
3. Serialization order differences cannot change gameplay state.

## 9. Slice 46B graphical behavior

### 9.1 Level-up flow

- remove the full-screen three-card panel from ordinary level gain;
- do not pause the scene tree;
- show a restrained message such as `LEVEL 5 — VOID POINT AVAILABLE`;
- allow points to remain unspent;
- no automatic allocation occurs.

### 9.2 Tree screen

The placeholder tree must provide:

- T/menu action to open and close;
- visible available points;
- zoom and pan;
- purchased, available, blocked, focused, and max-rank states;
- node name, rank, cost, effect, and prerequisite explanation;
- confirmation or immediate-purchase behavior chosen explicitly and tested;
- controller focus and deterministic neighbor movement;
- mouse click selection;
- safe return to gameplay;
- no stale pause after close.

### 9.3 Commitment-depth readability

Radial and non-radial layouts must communicate:

- the origin/start;
- immediately reachable nodes;
- path depth;
- major rule-changing commitment;
- terminal build direction.

A non-radial proof must use at least two independent visual channels for commitment depth, such as path distance, region bands, node scale, frame weight, connection treatment, or explicit depth labels.

### 9.4 Resolution, aspect-ratio, and UI-scale behavior

The graphical proof must test more than one ideal desktop configuration.

At minimum, validate representative profiles for:

- standard 16:9;
- 16:10;
- ultrawide;
- a narrow or legacy fallback profile;
- at least two UI-scale or OS display-scaling settings.

Point counters, side panels, tooltips, confirmation controls, focused nodes, and search/result indicators must remain visible and reachable. Changing resolution, aspect ratio, or scale while the tree is open must not lose controller focus or strand required controls off-screen.

### 9.5 UI boundaries

- placeholder geometry and icons are acceptable;
- no final World-Lattice art is required in Slice 46B;
- no production hundreds-node tree;
- the dense navigation stress fixture is test infrastructure, not production content;
- no final search system unless the proof tree genuinely needs it;
- no universal attribute screen;
- no unrelated HUD redesign;
- no camera change.

## 10. Graphical acceptance checklist

1. Gain a level during active combat.
2. Combat continues uninterrupted.
3. Notification appears without hiding major telegraphs.
4. Open the tree after combat or at the player's chosen moment.
5. Spend a point with mouse.
6. Verify the effect and point count update.
7. Spend or navigate with controller.
8. Navigate the dense fixture without focus ambiguity, focus loss, unintended long-distance jumps, or unreachable nodes.
9. Pan and zoom while controller focus remains visible and stable.
10. Verify a non-radial layout clearly communicates origin, next reach, depth, and major commitment.
11. Close and immediately resume play.
12. Save, quit fully, relaunch, and reload.
13. Confirm points, allocation, effect, inventory, equipment, XP, and abilities persist.
14. Confirm no card popup appears anywhere in the normal level-up path.
15. Confirm no duplicated notification, modifier, or point award after reload/rebind.
16. Repeat the tree interaction at representative aspect-ratio and UI-scale profiles.
17. Confirm critical controls and focused nodes remain visible after live resolution/scale changes where the platform supports them.

## 11. Required tests and workflows

### Slice 46A

Add focused real-engine suites for:

- definition integrity;
- award-ledger idempotency;
- multi-level point awards;
- atomic purchases;
- prerequisite/rank/exclusion validation;
- JSON persistence;
- failed rebind preservation;
- effect recomputation;
- compatibility with all PR #34 runtime suites.

### Slice 46B

Add focused tests for:

- level gain does not pause;
- legacy card panel is not opened;
- notification is emitted once;
- tree opening/closing restores correct pause state;
- controller focus remains valid;
- deterministic neighbor selection in dense and ambiguous layouts;
- focus remains visible during pan, zoom, and viewport changes;
- side panels and critical controls remain inside supported safe areas;
- graphical adapter calls runtime progression transactions rather than mutating local counters.

Run Godot 4.4.1 import, startup smoke, runtime foundation, persistence, Penitent UX, canonical class smokes, and playtest-tooling workflows.

## 12. Out of scope

- final universal attributes;
- final full Voidbringer tree;
- all eight class trees;
- final art, animation, audio, or VFX;
- final respec economy;
- optional roguelite modifier modes;
- combat rebalance;
- camera work;
- campaign quest implementation;
- PR #45 changes;
- rewriting PR #34 history.

## 13. Implementation return packet

Each implementation slice must return:

- exact base and final head;
- changed-file list;
- architecture summary;
- schema and migration notes;
- test commands and results;
- workflow run IDs;
- graphical evidence when applicable;
- tested aspect-ratio and UI-scale profiles when applicable;
- dense-navigation fixture results when applicable;
- known limitations;
- frozen verifier artifact ID and digest;
- explicit statement that no merge or independent-verification claim was made.

## 14. Merge gates

Each slice remains draft and unmerged until:

1. exact-head CI is green;
2. frozen artifact is independently verified;
3. graphical playtest is completed when applicable;
4. no unresolved blocker remains;
5. the human owner explicitly authorizes merge.

No implementation should begin merely because this brief exists. PR #34 must first merge, and the owner must explicitly authorize the selected implementation slice.
