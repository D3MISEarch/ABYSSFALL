# Claude Code Instructions

Claude Code is AbyssFall's **implementation engineer** role, as defined in [`Docs/Governance/AI_GUIDELINES.md`](Docs/Governance/AI_GUIDELINES.md). This file states the specific obligations that role carries in this repository. [`AGENTS.md`](AGENTS.md) is the general repository map — read it first if you haven't.

## Before writing any code

1. Read [`Docs/Governance/ENGINEERING_CONSTITUTION.md`](Docs/Governance/ENGINEERING_CONSTITUTION.md) — these are the non-negotiable laws of this codebase.
2. Read every ADR in [`Docs/ADR/`](Docs/ADR/) relevant to the system you're about to touch. Do not skim — the ownership boundaries they define (who owns what mutable state, who is allowed to call whom) are exactly the boundaries you must not cross.
3. **Inspect the existing implementation before adding a system.** Read [`Docs/Architecture/ARCHITECTURE.md`](Docs/Architecture/ARCHITECTURE.md) and the actual class it describes under `scripts/runtime/` or `scripts/persistence/`. If a task looks like it needs a new owner, a new event, or a new cross-system dependency, check whether an existing class already owns that responsibility before writing a new one.

## Architecture discipline

- **Never invent architecture without an ADR.** If a task requires a decision the Engineering Constitution or an existing ADR doesn't already cover — a new ownership boundary, a new session-scoped service, a new persistence field — stop and ask for an architectural decision rather than making the call yourself. See "When to stop" below.
- **Preserve deterministic behavior.** Any function that produces gameplay-relevant output (damage, stat rebuilds, item generation) must remain reproducible from its explicit inputs. Never introduce ambient/global randomness — see [ADR-012](Docs/ADR/ADR-012-STAT-MODIFIER-PIPELINE.md), [ADR-018](Docs/ADR/018_PROCEDURAL_ITEM_GENERATION.md).
- **Preserve save compatibility.** Changes to `BuildData`, snapshot fields, or serialization must not break existing saves without an explicit, versioned migration path — see [ADR-010](Docs/ADR/ADR-010-PERSISTENT-CHARACTER-CONTINUITY.md), [ADR-015](Docs/ADR/ADR-015-RUNTIME-PERSISTENCE-SYNCHRONIZATION.md).
- **Use `RuntimeSession` ownership boundaries.** Don't reach into another session's state, don't create a second event bus, don't bypass `RuntimeSession.bind_character()`/`grant_enemy_rewards()`/`execute_ability()` to touch inventory, equipment, or the ability executor directly. See [`Docs/Architecture/ARCHITECTURE.md`](Docs/Architecture/ARCHITECTURE.md) for the exact ownership map.

## Testing obligations

- **Write regression tests for gameplay changes.** Every gameplay bug fix and every new gameplay behavior needs a test in `scripts/runtime/tests/` (or a new suite wired into `.github/workflows/runtime-foundation-tests.yml`). See [`Docs/Standards/TESTING.md`](Docs/Standards/TESTING.md) for the PASS-marker convention and the standing bug-pattern log — check the log before and after any change that touches lifecycle, transforms, or material fades.
- **When persistence is affected, push durable snapshots through a real JSON round trip**, not just an in-memory comparison — `JSON.stringify()` then `JSON.parse_string()` on the actual data, per the established pattern in `scripts/runtime/tests/test_stage5_generated_rewards.gd`. In-memory-only tests cannot catch typed-array/JSON round-trip bugs (see [`Docs/Architecture/ARCHITECTURE.md`](Docs/Architecture/ARCHITECTURE.md) "JSON restoration").
- **Never remove or weaken a test to make CI pass.** If a test is failing, the code is wrong, the test is testing the wrong thing, or a genuine architectural decision changed (which needs its own ADR) — not "the test is inconvenient." Deleting or loosening an assertion to turn a red pipeline green is treated as a policy violation, not a fix.

## Reporting back

At the end of a task, summarize:

- **Files changed** — a real list, not a description.
- **Architecture impact** — which ADRs/ownership boundaries were touched, if any; state "none" explicitly if none.
- **Tests run** — which suites, and whether they emitted their PASS marker.
- **Unresolved risks** — anything you're not confident about, anything you deferred, anything that needs independent verification (see [`Docs/Governance/AI_GUIDELINES.md`](Docs/Governance/AI_GUIDELINES.md) on the Claude independent-review role).

## When to stop and ask

Stop and ask for an explicit architectural decision — do not guess — when:

- A requirement conflicts with something stated in the Engineering Constitution or an ADR.
- A task implies a new system boundary (a new kind of session-scoped service, a new event-bus contract, a new persistence field) that no existing ADR covers.
- Two existing ADRs appear to conflict with each other, or with the code as it currently exists.

Report the conflict plainly and wait for direction rather than picking a side yourself.

## Detailed character Codex

Before implementing or changing a playable class, read its approved detailed Codex in addition to the required engineering documents above. For Voidbringer, start with [`docs/codex/characters/voidbringer/README.md`](docs/codex/characters/voidbringer/README.md) and read `09_AUDIT_RESOLUTIONS.md` before the numbered bibles.

The Codex specifies approved player-facing behavior; it does not authorize new architecture. Translate its requirements through the existing `RuntimeSession`, event, ability, equipment and persistence boundaries. If that translation requires a new system owner, global event bus, durable field or dependency not already covered by an ADR, stop and ask for an ADR.

Do not use the current Void Warlock prototype as the future Voidbringer design authority. Preserve the `void_warlock` compatibility ID and existing playable behavior until a specific migration milestone changes them. When approved class behavior changes, update the affected Codex document and its `CHANGELOG.md` in the same pull request.
