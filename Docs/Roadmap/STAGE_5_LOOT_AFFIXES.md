# Stage 5 — Procedural Loot and Affixes

Status: IN PROGRESS  
Branch: `stage5/item-affix-foundation`

## Goal

Turn immutable item definitions into deterministic, persistent generated equipment with rarity-driven affix budgets.

## Current slice

- Immutable affix definitions and catalog
- Prefix and suffix eligibility pools
- Item-tag and item-level restrictions
- Weighted deterministic affix selection
- Duplicate-affix prevention
- Normal, Magic, Rare, and Legendary rarity budgets
- Deterministic generated item identity
- Persistent rarity, item level, and rolled modifiers
- Godot 4.4.1 regression coverage

## Architecture rules

- Catalog definitions remain immutable and are returned as defensive copies.
- Generation receives explicit seed and inputs; it does not use global random state.
- Generated item instances own mutable rolled state.
- Failed generation returns no partially generated item.
- Affixes are flattened into stat modifiers with durable affix metadata.
- Equipment consumes generated modifiers through the existing item-instance contract.
- Persistence continues through `ItemInstance.to_dict()` and `from_dict()`.

## Remaining Stage 5 slices

1. Integrate generated items into loot-table entries.
2. Add rarity-weight selection and monster-level propagation.
3. Add elite reward multipliers and guaranteed rarity floors.
4. Add legendary-power definitions and runtime effect hooks.
5. Add complete enemy-to-generated-item-to-save/reload vertical-slice coverage.

## Review gate

Request independent architecture review only after the complete procedural-loot and elite-reward subsystem is implemented and all CI is green.
