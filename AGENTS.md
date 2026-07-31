# Agent Instructions

This is the repository map for Codex, Claude Code, and any other coding agent working in AbyssFall. Keep this file concise — it points at deeper documents rather than repeating them. If something here conflicts with a linked document and the ADR it cites, stop and flag the conflict instead of guessing.

For contribution mechanics (branching, PR expectations, placeholder-art norms), see [`CONTRIBUTING.md`](CONTRIBUTING.md). For the full documentation tree and its index, see [`Docs/README.md`](Docs/README.md).

## Project identity

- **AbyssFall** — a dark-fantasy action dungeon crawler / ARPG.
- **Engine:** Godot 4.4.1, GDScript.
- **Known-good playable baseline:** `main` at `7b4bde25940d1941c54857471efdc581c6b9b150` (Godot 4.4.1). This is the approved full-stack Sunken Crypts foundation with front end, durable inventory, persistent class progression, controller reconciliation, Art Pass 0, and Voidbringer VFX. Later approved work may advance `main`; the exact active human gate and future branch sequence live in [`Docs/Roadmap/CURRENT_SLICE.md`](Docs/Roadmap/CURRENT_SLICE.md).
- **Active production operation:** OP1, the first polished Voidbringer proof. Penitent mechanics remain preserved and regression-tested, but further Penitent graphical, content, balance, progression, and Codex work is deferred until OP1 passes and the owner explicitly opens a later operation.
- **Scope doctrine:** the full AbyssFall vision is a long-term destination, not one simultaneous launch checklist. The binding operation model lives in [`Docs/Design/GAMEPLAY_BIBLE.md`](Docs/Design/GAMEPLAY_BIBLE.md).
- **Current architecture stage:** consolidated single-line production from `main`; the active milestone is the first polished Voidbringer combat vertical slice. Historical Stage 3–5 documents remain architectural background, not the current work queue.

## Required reading order

1. This file.
2. [`Docs/Governance/ENGINEERING_CONSTITUTION.md`](Docs/Governance/ENGINEERING_CONSTITUTION.md) — the non-negotiable laws of this codebase.
3. Any [`Docs/ADR/`](Docs/ADR/) entries relevant to the system you're touching.
4. [`Docs/Architecture/ARCHITECTURE.md`](Docs/Architecture/ARCHITECTURE.md) — how the ADRs became actual runtime code.
5. The relevant [`Docs/Standards/`](Docs/Standards/) document (`GDSCRIPT.md`, `TESTING.md`, `NAMING.md`, `DOCUMENTATION.md`).
6. [`Docs/Design/GAMEPLAY_BIBLE.md`](Docs/Design/GAMEPLAY_BIBLE.md) for the binding production/scope doctrine, then the relevant detailed design document.
7. [`Docs/Roadmap/CURRENT_SLICE.md`](Docs/Roadmap/CURRENT_SLICE.md), then any deeper roadmap document relevant to the task.
8. If you are an AI contributor, also read [`Docs/Governance/AI_GUIDELINES.md`](Docs/Governance/AI_GUIDELINES.md) for your specific role's obligations. Claude Code specifically must also read [`CLAUDE.md`](CLAUDE.md).

## Documentation map

| Location | Owns |
|---|---|
| [`Docs/Governance/`](Docs/Governance/) | The rules: engineering laws and AI contributor roles. |
| [`Docs/ADR/`](Docs/ADR/) | Approved architectural decisions — the source of truth for "why." |
| [`Docs/Architecture/`](Docs/Architecture/) | What currently exists in code, derived from the ADRs. |
| [`Docs/Design/`](Docs/Design/) | Gameplay pillars, production scope, combat, itemization, and class design. |
| [`Docs/Lore/`](Docs/Lore/) | World and narrative lore. |
| [`Docs/Standards/`](Docs/Standards/) | GDScript style, testing, naming, documentation conventions. |
| [`Docs/Planning/`](Docs/Planning/) | Non-blocking tech debt and its severity/milestone. |
| [`Docs/Roadmap/`](Docs/Roadmap/) | Active operation, exact gates, stage-by-stage delivery, and status. |
| `design/` and `Docs/` | Pre-existing detailed design/playtest/verification documents; still authoritative inside their approved scope. See [`Docs/README.md`](Docs/README.md) for the full index. |

## Running tests / CI

Runtime and persistence regression suites run headlessly under Godot 4.4.1 and are wired into GitHub Actions:

- [`.github/workflows/runtime-foundation-tests.yml`](.github/workflows/runtime-foundation-tests.yml) — runs every explicitly listed `scripts/runtime/tests/*.gd` suite.
- [`.github/workflows/persistence-tests.yml`](.github/workflows/persistence-tests.yml) — runs `scripts/persistence/tests/test_save_manager.gd`.
- [`.github/workflows/full-stack-controller-reconciliation.yml`](.github/workflows/full-stack-controller-reconciliation.yml) — protects the integrated controller, front-end, inventory, progression, art, VFX, and class-gate path.
- [`.github/workflows/full-stack-windows-package.yml`](.github/workflows/full-stack-windows-package.yml) — exports and audits the exact Windows playtest candidate.

Full command reference, PASS-marker convention, and failure rules live in [`Docs/Standards/TESTING.md`](Docs/Standards/TESTING.md). Do not claim a fix works without actually running Godot headlessly.

## Rules that apply to every agent

- Do not bypass, reinterpret, or "simplify away" a rule stated in an ADR or in the Engineering Constitution. If a task seems to require that, stop and ask for an ADR instead of improvising architecture.
- If your change alters a public system contract, update the relevant documentation in the same change. See [`Docs/Standards/DOCUMENTATION.md`](Docs/Standards/DOCUMENTATION.md).
- Keep CI green. A red pipeline blocks merge; fix the cause, never the test's ability to detect it.
- Keep feature work on separate branches and submit reviewable pull requests, one focused feature or fix per branch.
- Start from current `main`. Normal work stays one PR deep; two levels require an explicit dependency, and deeper stacks must be consolidated before more feature work.
- Only one implementation agent may edit an owning system at a time. Independent verification must use a frozen exact commit and must not co-author the implementation.
- Do not open OP2 scope, another class, another realm, broad endgame, multiplayer, platform expansion, or engine migration unless the owner has explicitly closed the current gate and opened that operation.
- Do not disguise future-operation work as infrastructure, harmless scaffolding, preparation, or refactoring.
- Build the active use case specifically enough to make it excellent, cleanly enough to preserve extension seams, and generalize only when a real second consumer proves the common contract.
- A hypothetical future collaborator, contractor, publisher, or funding event is never an implementation dependency.
- "AAA" means concentrated high-end presentation and polish inside the bounded active slice; it does not authorize AAA breadth.

## Detailed character Codex

Approved full-depth character design is indexed under [`Docs/codex/`](Docs/codex/). It is canonical for player-facing design inside the documented class scope, but it does not override the Engineering Constitution, ADRs, Architecture, Standards, persistence ownership, testing requirements, or the active operation boundary.

Before changing a documented class, read its folder README and any audit-resolution document before the numbered bibles. For Voidbringer, begin at [`Docs/codex/characters/voidbringer/README.md`](Docs/codex/characters/voidbringer/README.md).

A complete future class Codex preserves long-term design direction; it does not authorize that class's production. Class work begins only when the owner explicitly opens the relevant operation.

If a Codex requirement implies a new owner, event bus, persistence field, session service, or cross-system dependency not covered by an ADR, stop and request an ADR rather than treating the Codex as architectural approval. Approved design changes must update the affected Codex document and class changelog in the same pull request.
