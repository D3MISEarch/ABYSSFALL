# Agent Instructions

This is the repository map for Codex, Claude Code, and any other coding agent working in AbyssFall. Keep this file concise — it points at deeper documents rather than repeating them. If something here conflicts with a linked document, the linked document and the ADR it cites win; stop and flag the conflict instead of guessing.

For contribution mechanics, see [`CONTRIBUTING.md`](CONTRIBUTING.md). For the full documentation tree and its index, see [`Docs/README.md`](Docs/README.md).

## Project identity

- **AbyssFall** — a dark-fantasy action dungeon crawler / ARPG.
- **Engine:** Godot 4.4.1, GDScript.
- **Current playable prototype:** Void Warlock v0.4 Hotfix 3 ("The Sunken Crypts"). The approved future class design that replaces this prototype is **Voidbringer**; the runtime compatibility ID remains `void_warlock` until a versioned migration is approved.
- **The Penitent** is the second class under active construction.
- **Current architecture stage:** Stage 5 deterministic procedural item generation is on `stage3/equipment-runtime-foundation`.

## Required reading order

1. This file.
2. [`Docs/Governance/ENGINEERING_CONSTITUTION.md`](Docs/Governance/ENGINEERING_CONSTITUTION.md).
3. Relevant [`Docs/ADR/`](Docs/ADR/) entries.
4. [`Docs/Architecture/ARCHITECTURE.md`](Docs/Architecture/ARCHITECTURE.md).
5. Relevant [`Docs/Standards/`](Docs/Standards/) documents.
6. The current [`Docs/Roadmap/`](Docs/Roadmap/) stage document.
7. Relevant gameplay-design documents under [`Docs/Design/`](Docs/Design/) and detailed approved character Codices under [`docs/codex/`](docs/codex/).
8. AI contributors also read [`Docs/Governance/AI_GUIDELINES.md`](Docs/Governance/AI_GUIDELINES.md); Claude Code also reads [`CLAUDE.md`](CLAUDE.md).

## Authority and ownership

| Location | Owns |
|---|---|
| [`Docs/Governance/`](Docs/Governance/) | Engineering laws and AI contributor roles. |
| [`Docs/ADR/`](Docs/ADR/) | Approved architectural decisions and the reason behind them. |
| [`Docs/Architecture/`](Docs/Architecture/) | What currently exists in code. |
| [`Docs/Design/`](Docs/Design/) | Project-level gameplay, combat, itemization and class direction. |
| [`docs/codex/`](docs/codex/) | Approved detailed character design: exact skills, builds, items, presentation, encounters and narrative. |
| [`Docs/Lore/`](Docs/Lore/) | Project-level world and narrative lore. |
| [`Docs/Standards/`](Docs/Standards/) | GDScript, testing, naming and documentation conventions. |
| [`Docs/Planning/`](Docs/Planning/) | Tracked technical debt. |
| [`Docs/Roadmap/`](Docs/Roadmap/) | Delivery stages and current status. |

The detailed character Codex is canonical **only for approved game design within that character's scope**. It does not override the Engineering Constitution, ADRs, existing runtime ownership or testing requirements. If an approved design requires architecture not covered by an ADR, stop and request an ADR before implementation.

For Voidbringer work, read [`docs/codex/characters/voidbringer/README.md`](docs/codex/characters/voidbringer/README.md) and its audit resolutions before changing code or design.

## Running tests / CI

Runtime and persistence regression suites run headlessly under Godot 4.4.1 and are wired into GitHub Actions:

- [`.github/workflows/runtime-foundation-tests.yml`](.github/workflows/runtime-foundation-tests.yml)
- [`.github/workflows/persistence-tests.yml`](.github/workflows/persistence-tests.yml)

Full commands, PASS-marker rules and failure requirements live in [`Docs/Standards/TESTING.md`](Docs/Standards/TESTING.md). Do not claim a fix works without actually running Godot headlessly.

## Rules that apply to every agent

- Do not bypass or reinterpret an ADR or the Engineering Constitution.
- Do not silently contradict an approved character Codex. Propose and document the design change in the same PR.
- Do not invent a new system owner, event bus, persistence field or cross-system dependency without an ADR when the existing decisions do not cover it.
- If a public system contract changes, update its owning documentation and relevant playtest checklist in the same PR.
- Keep CI green; fix the cause, never weaken the test.
- Keep work on focused feature branches and submit reviewable pull requests.
