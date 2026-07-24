# Stage 5 — Procedural Loot and Affixes

Status: IMPLEMENTED / AUTOMATED CI GREEN / INDEPENDENT VERIFICATION PENDING  
Branch: `stage3/equipment-runtime-foundation`  
Integrated pull request: #34

## Goal

Turn immutable item definitions into deterministic, persistent generated equipment with rarity-driven affix budgets and durable unique identity.

## Completed scope

- Immutable affix definitions and defensive-copy catalog
- Prefix and suffix eligibility pools
- Item-tag and item-level restrictions
- Weighted deterministic affix selection
- Duplicate-affix prevention
- Normal, Magic, Rare, and Legendary rarity budgets
- Generated loot-table entries and weighted rarity selection
- Enemy-level propagation
- Elite minimum-rarity floors
- Enemy-to-generated-item-to-save/JSON-reload vertical slice
- Session-owned monotonic item identity allocation
- Separate persistent generation-seed provenance
- Duplicate live-instance rejection in inventory and equipment
- Cross-container inventory/equipment identity-collision rejection during restoration
- Stack-split identity allocation through the active session service
- Transactional failed rebind behavior that preserves the active allocator and item systems
- Godot 4.4.1 regression coverage

## Architecture rules

- Catalog definitions remain immutable and are returned as defensive copies.
- Generation receives explicit seed, identity, and immutable inputs; it does not use global random state.
- Generation seed determines contents; identity determines the individual physical item.
- `RuntimeSession` owns the active build's `ItemIdentityService`.
- `ItemInstance.new()` does not fabricate identity.
- New item-creation and stack-split paths request identity from the session service before creating a new physical item.
- Restoration preserves serialized IDs but never invents missing IDs.
- Generated item instances own mutable rolled state.
- Failed generation, inventory addition, equipment mutation, split, restoration, or character binding returns without partial mutation.
- Affixes are flattened into stat modifiers with durable affix metadata.
- Equipment consumes generated modifiers through the existing item-instance contract.
- Persistence continues through `ItemInstance.to_dict()` and `from_dict()` plus allocator state in build-specific progress.

## Review history

Claude's first Stage 5 review returned **Approved with changes**. The blocking finding was that identity derived only from generation parameters allowed two otherwise-identical items to collide and brick restoration. Stage 5 separated deterministic contents from unique physical identity and added regressions for repeated generation, duplicate rejection, allocator restoration, and save/load safety.

The later PR #34 technical-director pass found additional ownership edges: hidden time/global-random ID fallbacks, duplicate equipment identity, cross-container restore collisions, non-atomic partial stack merging, and missing two-handed occupancy enforcement. Those paths are now corrected and covered by the Stage 3–5 runtime suites.

Non-blocking follow-up notes:

- Move rarity rules to data when map and elite modifiers need dynamic budgets.
- Pre-index affix pools only when catalog scale or profiling justifies it.
- Consider structured affix groups before crafting UI depends on flattened modifier records.

## Current automated evidence

At blocker-fix head `95a4e5ab072a329e19d57ac3c545610d9e60ea8b`, the Godot 4.4.1 runtime workflow passed the affix-catalog, deterministic item-generation, generated-reward, identity-continuation, inventory/equipment, and durable vertical-slice suites.

This is implementation evidence only. The independent frozen-artifact review remains required.

## Completion gate

1. Keep the integrated Stage 3–5 PR draft and all CI green.
2. Produce the frozen verifier artifact from the final fixed head.
3. Focused independent confirmation verifies identity, ownership, atomicity, restoration, two-handed occupancy, and JSON continuation.
4. Resolve any graphical playtest requirements.
5. Obtain explicit human-owner merge authorization.
6. Merge PR #34.
7. Begin Stage 6 Legendary Powers only after an approved hook taxonomy and session-owned runtime effect registry design.
