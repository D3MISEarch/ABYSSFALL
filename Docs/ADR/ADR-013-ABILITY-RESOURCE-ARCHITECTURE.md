# ADR-013 — Ability and Class-Resource Architecture

Status: PROPOSED  
Release target: CORE / Stage 2

## Decision

Abilities are immutable definitions referenced by stable IDs. Runtime ability state owns cooldowns and charges. Class-resource components own generation, spending, capacity, and regeneration behavior.

## Rules

- Ability execution follows validate → spend cost → start cooldown → execute effects.
- Failed validation changes no resource or cooldown state.
- Costs are paid by a class-resource component, not by the definition.
- Penitent uses Fervor; Void Warlock uses Corruption.
- Abilities emit runtime events and never save directly.
- Effects are tagged for damage type, delivery type, and status interactions.

## Consequences

Classes can use distinct resource loops while sharing cooldown, cost, and execution infrastructure.