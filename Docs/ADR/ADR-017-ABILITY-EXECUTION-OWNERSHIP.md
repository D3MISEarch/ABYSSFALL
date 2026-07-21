# ADR-017: Ability Execution Ownership

## Status

Proposed

## Context

Ability execution needs one authoritative runtime path for unlock validation, class-resource costs, cooldown state, and gameplay events. Those concerns must remain isolated between runtime sessions and must not become global singleton state.

## Decision

`RuntimeSession` owns one `AbilityExecutor` and injects its session-scoped `RuntimeEventBus` into it. Ability definitions are immutable runtime inputs. Cooldown state is keyed by build ID and ability ID inside the executor.

An execution attempt returns a structured result with an explicit reason. Successful attempts spend resource, begin cooldown, and emit `ability_cast`. Rejected attempts do not spend resource and emit `ability_rejected`.

## Consequences

- Ability cooldowns remain isolated by runtime session and build.
- UI and combat systems can react to explicit success and rejection events.
- Failed execution is deterministic and side-effect free.
- Future targeting and effect resolution can extend the executor without moving ownership into an autoload.
