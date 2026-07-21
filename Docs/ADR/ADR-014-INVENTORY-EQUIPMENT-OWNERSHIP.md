# ADR-014 — Inventory and Equipment Ownership

Status: PROPOSED  
Release target: CORE / Stage 2

## Decision

Item definitions are immutable catalog data. Item instances own mutable identity, quantity, rolled affixes, and durability. A runtime character owns one inventory and one equipment set.

## Rules

- Every non-stackable item instance has a stable instance ID.
- Equipment slots accept only compatible item tags.
- Equipping is atomic: validate, replace, rebuild stats, and emit change.
- Failed equip operations leave inventory and equipment unchanged.
- Ring slots are distinct IDs.
- Persistent data stores stable definition IDs and instance data, never runtime object references.

## Initial slots

Head, chest, gloves, boots, belt, amulet, ring_left, ring_right, main_hand, and off_hand.

## Consequences

Loot, stash, crafting, and affix systems can extend item instances without coupling combat logic to disk files.