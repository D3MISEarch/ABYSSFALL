# Claude Code Instructions

Claude Code is AbyssFall's **implementation engineer** role, as defined in [`Docs/Governance/AI_GUIDELINES.md`](Docs/Governance/AI_GUIDELINES.md). [`AGENTS.md`](AGENTS.md) is the general repository map and must be read first.

## Before writing code

1. Read [`Docs/Governance/ENGINEERING_CONSTITUTION.md`](Docs/Governance/ENGINEERING_CONSTITUTION.md).
2. Read every relevant ADR in [`Docs/ADR/`](Docs/ADR/).
3. Read [`Docs/Architecture/ARCHITECTURE.md`](Docs/Architecture/ARCHITECTURE.md) and inspect the actual implementation before adding any system.
4. Read the relevant [`Docs/Standards/`](Docs/Standards/) documents and current Roadmap stage.
5. For playable-class work, read the class's complete approved Codex. Voidbringer starts at [`docs/codex/characters/voidbringer/README.md`](docs/codex/characters/voidbringer/README.md); read `09_AUDIT_RESOLUTIONS.md` before the numbered bibles because it contains binding corrections from independent review.

## Architecture discipline

- **Never invent architecture without an ADR.** Stop when a task implies a new owner, session-scoped service, event bus, persistence field or cross-system dependency not covered by existing decisions.
- **Preserve deterministic behavior.** Gameplay output must remain reproducible from explicit inputs.
- **Preserve save compatibility.** BuildData, snapshots and serialization require a versioned migration when changed.
- **Use RuntimeSession ownership boundaries.** Do not create a second event bus or bypass RuntimeSession, AbilityExecutor, equipment, inventory or reward ownership.
- A class Codex specifies approved behavior and player-facing design. It does not authorize bypassing the existing architecture. Translate the design into current systems; where translation is impossible, stop and request an ADR.
- Do not use the old Void Warlock prototype as the design authority for future Voidbringer behavior. Preserve its compatibility ID and current playable behavior until the replacement milestone explicitly changes it.

## Testing obligations

- Every gameplay behavior and bug fix requires deterministic regression coverage under `scripts/runtime/tests/` or the appropriate persistence suite.
- Add every new runtime test suite to `.github/workflows/runtime-foundation-tests.yml` in the same PR; the workflow does not auto-discover suites.
- Persistence tests must use a real JSON stringify/parse round trip.
- Never remove or weaken a test to make CI pass.
- Update the relevant manual or graphical playtest checklist when behavior changes.

## Documentation obligations

When implementation changes an approved class behavior:

- update the affected Codex document,
- update the class `CHANGELOG.md`,
- update architecture or ADR documentation when ownership/contracts change,
- clearly mark whether the change is balance tuning, clarification or a design revision.

Do not silently reinterpret a Codex contradiction. Stop and report the conflicting files and headings.

## Reporting back

At the end of a task, report:

- files changed,
- architecture impact and relevant ADRs,
- Codex sections implemented or changed,
- tests run and PASS markers,
- unresolved risks and verification needs.

## When to stop and ask

Stop rather than guessing when:

- design conflicts with the Engineering Constitution or an ADR,
- two approved Codex sections conflict and no audit resolution settles them,
- a new architecture boundary or persistence contract is implied,
- an implementation would require breaking the `void_warlock` compatibility ID without a migration,
- the requested behavior cannot be tested deterministically under the current system.
