# ADR-012 — Stat and Modifier Pipeline

Status: PROPOSED  
Release target: CORE / Stage 2

## Decision

Final stats are rebuilt deterministically from ordered operations:

`(Base + Flat) × (1 + Additive Percent) × Multiplicative Percent Factors`

Each modifier has a stable source ID, target stat, operation, value, and priority.

## Rules

- Base values are never mutated by equipment or effects.
- Removing a source removes every modifier from that source.
- Final values rebuild after dirty changes rather than being incrementally patched.
- Identical inputs produce identical outputs.
- Caps and floors are applied after modifier calculation when a stat defines them.
- Damage calculations consume a frozen stat snapshot.

## Consequences

Equipment, talents, skills, buffs, and debuffs share one calculation path and cannot silently drift into incompatible formulas.