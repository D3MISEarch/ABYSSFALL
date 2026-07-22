# Stage 5 — Procedural Loot and Affixes

Status: REVIEW FIX / CI PENDING  
Branch: `stage5/item-affix-foundation`

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
- Enemy-to-generated-item-to-save/reload vertical slice
- Session-owned monotonic item identity allocation
- Separate persistent generation-seed provenance
- Duplicate live-instance rejection
- Godot 4.4.1 regression coverage

## Architecture rules

- Catalog definitions remain immutable and are returned as defensive copies.
- Generation receives explicit seed, identity, and immutable inputs; it does not use global random state.
- Generation seed determines contents; identity determines the individual physical item.
- `RuntimeSession` owns the active build's `ItemIdentityService`.
- New item-creation paths request identity before constructing a physical item.
- Generated item instances own mutable rolled state.
- Failed generation returns no partially generated item.
- Affixes are flattened into stat modifiers with durable affix metadata.
- Equipment consumes generated modifiers through the existing item-instance contract.
- Persistence continues through `ItemInstance.to_dict()` and `from_dict()` plus allocator state in build-specific progress.

## Independent review

Claude returned **Approved with changes**. The blocking finding was that identity derived only from generation parameters allowed two otherwise-identical items to collide and brick restoration. Stage 5 now separates deterministic contents from unique identity and adds regressions for repeated generation, duplicate rejection, allocator restoration, and save/load safety.

Non-blocking follow-up notes:

- Move rarity rules to data when map and elite modifiers need dynamic budgets.
- Pre-index affix pools only when catalog scale or profiling justifies it.
- Consider structured affix groups before crafting UI depends on flattened modifier records.

## Completion gate

1. Runtime CI passes at the review-fix head.
2. Focused independent confirmation verifies the identity blocker is closed.
3. Merge Stage 5.
4. Build the Developer Bible, Engineering Constitution, AI guidelines, Claude Code guidance, and Codex guidance.
5. Begin Stage 6 Legendary Powers with an approved hook taxonomy and session-owned runtime effect registry.
