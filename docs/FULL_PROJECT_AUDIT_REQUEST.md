# AbyssFall Full-Project Independent Audit

This branch exists only to produce a frozen, self-auditing verifier package for a complete repository review before further feature development.

## Audit scope

Review the entire maintained project rather than only the one-file branch diff:

- project configuration, boot flow, class selection, and gameplay scene loading
- Void Warlock regression risk
- Penitent architecture and complete current ability loop
- Fervor, Rite Marks, Seal of Binding, Brand of Ruin, Martyr's Chain, Ashen Procession, and Sacrament
- HUD and input wiring
- scene-tree lifecycle and transform ordering
- physics and coordinate-space calculations
- cooldowns, state transitions, cleanup, replacement, overlap, and death behavior
- tests and their meaningful coverage, including blind spots or false confidence
- CI and verifier-artifact integrity
- documentation accuracy and stale claims
- architectural risks that should be corrected before Cathedral of Flesh or further content work

## Required outcome

Return one verdict using `docs/VERIFICATION_REPORT_TEMPLATE.md`:

- PASS
- PASS WITH FOLLOW-UP
- FAIL
- NEEDS GRAPHICAL PLAYTEST

Separate findings into:

1. Blocking correctness defects
2. Non-blocking engineering debt
3. Graphical/manual-playtest-only questions
4. Recommended order of fixes or next development work

Do not modify implementation files. Report concrete paths, functions, reproduction steps, and reasoning for every finding.
