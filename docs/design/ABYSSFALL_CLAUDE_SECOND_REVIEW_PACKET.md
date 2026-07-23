# AbyssFall PR #40 — Focused Independent Second Review

> Review target: Draft PR #40  
> Branch: `design/overnight-world-class-bibles`  
> Required target head: use the current exact PR head at review time  
> Review type: documentation consistency and authority review only  
> Merge authority: human owner only

## Reviewer role

Act as the independent verifier. Do not implement, merge, canonize, or broaden scope.

The original broad review returned **PASS WITH REQUIRED REVISIONS**. The human owner approved the recommended decision set and added an explicit tone direction: AbyssFall must be dark, abysmal, dread-heavy, brutal, serious, mythic, cinematic, and original. *Elden Ring* and *Diablo IV* are quality references only, not content templates.

Review these new files first:

1. `docs/design/ABYSSFALL_OWNER_DECISION_LEDGER.md`
2. `docs/design/ABYSSFALL_PR40_REQUIRED_REVISIONS_PROPOSED.md`

Use the existing campaign bible, class bibles, review ledger, owner packet, and approved Voidbringer Codex only as grounding material needed to validate the revisions.

## Required verification questions

1. Does the owner decision ledger accurately separate OWNER APPROVED, REVISED, DEFERRED, and HELD decisions?
2. Is it explicit that only the human owner may assign owner-approval authority?
3. Does the World-Lattice reconciliation preserve the approved Voidbringer Codex rather than overwrite or genericize it?
4. Are these approved Voidbringer elements preserved and correctly situated?
   - Black Measure
   - Last Measure
   - Mass Anchors
   - Fold Lines
   - Instability
   - Breach and Clean Closure
   - Meridian Vaults and Axis Vault
   - living Reference Body
   - Manifold Trials
   - Edras Vey and the Stillpoint Engine
5. Are Edras Vey and the Architect Below clearly distinct?
6. Is the Architect Below still deliberately ambiguous through launch?
7. Is the six-act campaign framed as the complete vision rather than a simultaneous first production milestone?
8. Does the proposed act escalation feel like one deepening crisis rather than six disconnected biome showcases?
9. Are beginner loops explicit and appropriately low-overhead for all eight launch classes?
10. Are boss-safe mechanic conversions explicit for all eight launch classes?
11. Are the Somnarch territory-readability gates sufficient to block premature full approval?
12. Are the Relic Host combat-tempo gates sufficient to prevent menu-management or passive-aura failure?
13. Are the Tidewrought geometry and forced-movement gates sufficient to protect encounter telegraphs and distinguish pressure from gravity?
14. Is Anachron correctly held behind a narrow deterministic replay spike?
15. Does the Anachron spike explicitly prevent duplicate damage, rewards, procs, cooldown/resource restoration, invalid target state, world-state restoration, and session leakage?
16. Does the Graftborn slice remain agnostic to the unresolved global class-item-slot decision?
17. Are attributes and the global class-item-slot model still correctly deferred?
18. Is Voidbringer unambiguously the player-facing class name while `void_warlock` remains compatibility-only?
19. Do the tone guardrails establish a competitive dark-action-RPG identity without encouraging imitation of reference games?
20. Are the canonization rules sufficient to prevent proposed material from quietly becoming implementation authority?

## Scope discipline

Do not request that every proposed skill, item, number, faction name, or boss title be finalized before the structural package can proceed.

Do flag:

- direct contradictions;
- authority loopholes;
- loss of approved Voidbringer content;
- generic or copied story structure;
- class-identity collisions;
- production-scope ambiguity;
- missing beginner or boss behavior;
- prototype gates that cannot actually prove their risk;
- wording that accidentally authorizes implementation.

## Required response format

### A. Verdict

Choose exactly one:

- PASS — revision layer is structurally safe for a controlled canonization pass.
- PASS WITH REQUIRED REVISIONS — list only remaining required changes.
- FAIL — identify the blocking contradiction or authority problem.

### B. Findings table

| Check | PASS / REVISE / FAIL | Evidence and exact required change |
|---|---|---|
| Owner authority |  |  |
| Decision-status accuracy |  |  |
| Voidbringer reconciliation |  |  |
| Campaign scale |  |  |
| Tone originality |  |  |
| Beginner loops |  |  |
| Boss-safe mechanics |  |  |
| Somnarch gate |  |  |
| Relic Host gate |  |  |
| Tidewrought gate |  |  |
| Anachron hold/spike |  |  |
| Graftborn slice |  |  |
| Deferred systems |  |  |
| Naming/compatibility |  |  |
| Canonization controls |  |  |

### C. Remaining required revisions

List only blocking or approval-required revisions. Separate non-blocking suggestions.

### D. Final authority confirmation

Explicitly confirm or reject this statement:

> The human owner’s recorded decisions are authoritative at the decision-gate level, while the remaining `_PROPOSED.md` documents are not canonical or implementation-authoritative. The revision layer is safe to proceed to a controlled canonization pass only after the human owner accepts this verification result.

Do not merge or mark the PR ready for review.