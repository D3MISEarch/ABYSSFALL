# ADR-010 — Persistent Character Continuity

Status: APPROVED  
Release target: CORE  
Verification: Pending Stage 1 implementation

## Context

Many seasonal ARPGs require players to restart characters to access new content. AbyssFall is intended to preserve player attachment, build history, gear history, and long-term progression.

## Decision

AbyssFall will use persistent character progression across future content chapters and seasonal releases.

Players will not be required to create a new character to access new gameplay content.

Future chapters may add zones, bosses, enemies, loot, story, activities, and reward tracks to the persistent game. Optional fresh-start challenge modes may be added later, but they will never be the only path to new gameplay content.

## Architectural consequences

- Build data is permanent and never owned by a season.
- Chapter/season progress is additive and stored separately from core build data.
- Save migrations must preserve existing profiles and builds.
- New systems must avoid invalidating or deleting previous progression.
- Major content should remain available whenever technically practical.

## Verification requirement

This ADR becomes VERIFIED only after Stage 1 demonstrates that content chapter data can be added, updated, and migrated without resetting or replacing BuildData.
