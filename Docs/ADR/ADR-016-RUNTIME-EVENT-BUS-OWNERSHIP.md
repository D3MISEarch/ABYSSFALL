# ADR-016 — Runtime Event Bus Ownership

Status: PROPOSED  
Release target: CORE / Stage 3

## Decision

`RuntimeEventBus` is a dependency-injected, session-scoped object owned by one `RuntimeSession` composition root. It is not a project autoload singleton.

## Rules

- One runtime session owns exactly one event bus.
- Runtime producers receive or are bound to the session-owned bus.
- Consumers subscribe through the same session instance.
- Separate sessions must never receive each other's events.
- Persistent services remain outside the event bus and keep their explicit mutation/save boundary.
- No gameplay system may create an ad-hoc second bus for the same session.

## Rationale

A session-scoped bus avoids hidden global mutable state, keeps headless tests isolated, supports future parallel simulations, and makes producer/consumer ownership visible at the composition root.

## Consequences

Stage 3 ability, inventory, progression, and combat orchestration must be wired through `RuntimeSession.event_bus`. Systems that only perform pure calculations remain independent of the bus.
