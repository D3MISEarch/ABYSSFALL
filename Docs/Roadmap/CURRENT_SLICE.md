# AbyssFall — Current Production Slice

**Queue status date:** 28 July 2026  
**Production-doctrine confirmation:** 31 July 2026  
**Authoritative branch:** `main`  
**Approved full-stack baseline:** `7b4bde25940d1941c54857471efdc581c6b9b150`  
**Active human-gated candidate at queue snapshot:** [PR #82](https://github.com/D3MISEarch/ABYSSFALL/pull/82) at frozen head `8d5958e51f499d966a790cc9feb479b339b29964`  
**Next dependent slice at queue snapshot:** [Issue #83](https://github.com/D3MISEarch/ABYSSFALL/issues/83), blocked until PR #82 passes owner playtest and merges  
**Owner-authorized sequence at queue snapshot:** [Issue #96](https://github.com/D3MISEarch/ABYSSFALL/issues/96)  
**Engine:** Godot 4.4.1

The exact live PR and issue state may advance beyond the queue snapshot above. Always verify current GitHub state before implementation. The production-scope doctrine below remains binding regardless of queue movement.

## Current gate

At the recorded queue snapshot, PR #82 is draft, unmerged, technically verified, and waiting for the owner Windows playtest. Its frozen head is not approved `main` and must not be used as a dependency base until the owner records PASS and the PR merges.

Issue #83 may be refined as implementation-ready preproduction, but no implementation branch may be created until the exact post-merge `main` SHA is recorded.

After Issue #83 passes and merges, the recorded locked sequence is: architecture gate [Issue #97](https://github.com/D3MISEarch/ABYSSFALL/issues/97), isolated foundation sandbox [Issue #89](https://github.com/D3MISEarch/ABYSSFALL/issues/89), foundational skill work through [Issue #95](https://github.com/D3MISEarch/ABYSSFALL/issues/95), then Hollow King [Issue #86](https://github.com/D3MISEarch/ABYSSFALL/issues/86) unless the owner explicitly reprioritizes. No implementation branch in that chain may start from an unmerged dependency head.

## Binding operation boundary

This file is the active work queue inside the project-wide doctrine locked in [`../Design/GAMEPLAY_BIBLE.md`](../Design/GAMEPLAY_BIBLE.md).

**The current major operation is OP1: the first polished Voidbringer proof.**

OP1 is not disposable scaffolding before the real game. It is the first complete proof of the real game: one exceptional class, one polished environment, one memorable boss, one deep progression and build foundation, meaningful loot, one focused repeatable loop, and high-end presentation supported by stable persistence, testing, performance, documentation, and packaging.

No OP2 class, realm, boss, broad system, platform, or multiplayer feature may enter production merely because it exists in the long-term vision. OP2 opens only after OP1 passes owner acceptance and receives a separate explicit scope decision.

## Active production target

Build the first polished **Voidbringer OP1** combat vertical slice. The current game foundation is stable enough that new work must improve player-facing combat quality and the coherent playable proof rather than add another broad system.

Penitent mechanics remain preserved and regression-tested, but all further Penitent graphical, content, balance, progression, and Codex work is deferred until OP1 passes and the owner explicitly opens a later operation.

## Protected playable baseline

The following behavior is approved and must not drift without an explicit task and regression coverage:

- smooth movement, controller aiming, retained facing, and camera follow;
- controller-friendly home screen, character/build selection, pause, inventory, and class tree;
- persistent level, XP, class-point, equipment, backpack-order, and item-identity state;
- backpack-first loot with explicit equip and unequip;
- complete Sunken Crypts route, decorative-only Art Pass 0, and current Voidbringer VFX;
- safe save/continue and save/exit lifecycle;
- both class launch smokes and canonical class-ID gates.

## Priority order inside OP1

1. Voidbringer combat and build identity.
2. Boss quality, beginning with Hollow King after the foundational Voidbringer core loop is proven.
3. Art direction, lighting, materials, atmosphere, VFX, audio, and cinematic presentation.
4. Meaningful build-changing loot and persistent progression.
5. One focused repeatable Wound or equivalent endgame loop.
6. Stability, performance, controller quality, persistence, packaging, and external-proof readiness across the complete slice.

These priorities are sequentially concentrated, not separate simultaneous projects. A bounded task may touch more than one when their player-facing result is inseparable, but it may not use integration as an excuse for broad scope.

## Current micro-sprint

**Voidbringer impact and payoff pass**

Player-facing loop:

`cast Void Bolt → readable hit and enemy reaction → satisfying death feedback → visible Corruption payoff → Grasping Rift creates an intentional setup → follow-up cast feels stronger because of the setup`

Recorded sequence:

1. PR #82 — Void Bolt contact, enemy reaction, death consequence, soul travel, and Corruption payoff; owner Windows playtest required.
2. Issue #83 — Grasping Rift setup/collapse readability and one isolated grouping/payoff encounter; starts only from the exact post-merge `main` SHA.
3. Issue #97 — approve the ownership ADR for transient Voidbringer combat state, force, and generic charges.
4. Issues #89–#95 — prove and migrate the foundational `Anchor → Load → Bend → Collapse` kit one verified slice at a time.
5. Issue #86 — resume Hollow King boss-quality work after Issue #95, unless the owner reprioritizes.

Required outcomes:

- Void Bolt has clear travel, contact, impact, and kill feedback without changing verified damage or collision values accidentally;
- enemies communicate light hit, heavy hit, control, and death states clearly;
- Corruption gain is readable without covering combat;
- Grasping Rift setup and collapse are understandable at a glance;
- one encounter is tuned around grouping, payoff, repositioning, and recovery rather than raw enemy count;
- the foundational Voidbringer kit supports credible ranged-geometry and close-range Worldshear directions before broader build expansion;
- every discovered gameplay defect receives a focused regression.

Explicitly out of scope:

- OP2 or any new playable class production, including Penitent polish;
- a second realm or unrelated boss production;
- co-op or networking;
- broad item-generation or endgame expansion beyond the exact active slice;
- final imported character/environment art before the relevant mechanics and pipeline are ready;
- Dead Star, the full level-1–50 production tree, and broad discipline expansion;
- Godot-to-Unreal migration;
- speculative full-roster architecture;
- large refactors unrelated to the active combat slice.

## Production rules

- Start every task from current `main` and record the exact base SHA.
- One implementation agent owns a system at a time.
- Maximum one active gameplay implementation PR and one non-overlapping documentation/tooling PR.
- Normal work stays one PR deep; two levels require a real dependency; deeper stacks are consolidated before more work.
- Every feature begins with a production packet: player goal, scope, exclusions, owners, ADRs, acceptance criteria, tests, manual playtest, persistence impact, performance risk, and Definition of Done.
- A feature is complete only after Godot execution, explicit PASS markers, frozen exact-head verification, a Windows artifact when player-facing, owner playtest, and explicit merge approval.
- Claude verifies frozen commits read-only. It does not co-author the implementation under review.
- Build the current use case specifically enough to make it excellent, cleanly enough to preserve extension seams, and generalize only when a real second consumer proves the common contract.
- A hypothetical collaborator, contractor, publisher, or funding event is never a dependency of an OP1 task.
- No task may reopen future-operation scope by calling it infrastructure, preparation, platform work, or harmless scaffolding.

## OP1 acceptance direction

Individual issues and PRs pass their own gates, but OP1 itself is not complete until the combined owner playtest demonstrates:

- an exciting and specific Voidbringer with visibly different build directions;
- a coherent Sunken Crypts environment and memorable Hollow King encounter;
- meaningful progression and loot decisions;
- one repeatable loop worth replaying;
- strong combat feedback and high-end presentation inside the bounded slice;
- safe persistence, controller play, performance, packaging, and relaunch;
- a documented workflow that can produce the next operation without rebuilding the project;
- a result that communicates the AbyssFall vision to another person without requiring promises about future classes or realms.

## Known follow-ups that do not block the slice

- Decide whether freeze branches should trigger workflows on push.
- Maintain every Godot 4.4.1 GDScript `.uid` sidecar and keep the one-to-one policy green through `tools/repository_health_check.ps1`.
- Documentation-path casing normalization is complete under the canonical `Docs/` root; package paths must use that root only.
- Keep PR frozen-head metadata synchronized after correction passes; tracked by [Issue #84](https://github.com/D3MISEarch/ABYSSFALL/issues/84).

## Deferred future operations

- Penitent graphical validation, full Codex production, and production polish.
- Any additional class; no class count is committed for the first commercial release.
- Additional realms, regional bosses, and broad campaign expansion.
- Production Meshy/Blender character integration beyond the needs of the active OP1 pipeline.
- Dead Star and the remaining Voidbringer discipline roster beyond the approved foundational proof.
- Local and online co-op.
- Platform expansion.
- Engine migration decision, which remains gated behind a structured Godot playtest of the polished OP1 slice.
