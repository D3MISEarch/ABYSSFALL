# AbyssFall — Current Production Slice

**Status date:** 28 July 2026  
**Authoritative branch:** `main`  
**Approved main baseline:** `7b4bde25940d1941c54857471efdc581c6b9b150`  
**Active human-gated candidate:** [PR #82](https://github.com/D3MISEarch/ABYSSFALL/pull/82) at frozen head `8d5958e51f499d966a790cc9feb479b339b29964`  
**Next dependent slice:** [Issue #83](https://github.com/D3MISEarch/ABYSSFALL/issues/83), blocked until PR #82 passes owner playtest and merges  
**Owner-authorized sequence:** [Issue #96](https://github.com/D3MISEarch/ABYSSFALL/issues/96)  
**Engine:** Godot 4.4.1

## Current gate

PR #82 is draft, unmerged, technically verified, and waiting for the owner Windows playtest. Its frozen head is not approved `main` and must not be used as a dependency base until the owner records PASS and the PR merges.

Issue #83 may be refined as implementation-ready preproduction, but no implementation branch may be created until the exact post-merge `main` SHA is recorded.

After Issue #83 passes and merges, the locked sequence is: architecture gate [Issue #97](https://github.com/D3MISEarch/ABYSSFALL/issues/97), isolated foundation sandbox [Issue #89](https://github.com/D3MISEarch/ABYSSFALL/issues/89), foundational skill work through [Issue #95](https://github.com/D3MISEarch/ABYSSFALL/issues/95), then Hollow King [Issue #86](https://github.com/D3MISEarch/ABYSSFALL/issues/86) unless the owner explicitly reprioritizes. No implementation branch in that chain may start from an unmerged dependency head.

## Active production target

Build the first polished **Voidbringer** combat vertical slice. The current game foundation is stable enough that new work must improve player-facing combat quality rather than add another broad system.

Penitent mechanics remain preserved and regression-tested, but all further Penitent graphical, content, balance, and progression work is deferred until the class roster milestone is intentionally reopened.

## Protected playable baseline

The following behavior is approved and must not drift without an explicit task and regression coverage:

- smooth movement, controller aiming, retained facing, and camera follow;
- controller-friendly home screen, character/build selection, pause, inventory, and class tree;
- persistent level, XP, class-point, equipment, backpack-order, and item-identity state;
- backpack-first loot with explicit equip and unequip;
- complete Sunken Crypts route, decorative-only Art Pass 0, and current Voidbringer VFX;
- safe save/continue and save/exit lifecycle;
- both class launch smokes and canonical class-ID gates.

## Priority order

1. Voidbringer combat and build identity.
2. Boss quality, beginning with Hollow King after the foundational Voidbringer core loop is proven.
3. Art direction and atmosphere.
4. Meaningful build-changing loot.
5. One focused repeatable endgame loop.

## Current micro-sprint

**Voidbringer impact and payoff pass**

Player-facing loop:

`cast Void Bolt → readable hit and enemy reaction → satisfying death feedback → visible Corruption payoff → Grasping Rift creates an intentional setup → follow-up cast feels stronger because of the setup`

Current sequence:

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
- the foundational Voidbringer kit supports credible ranged-geometry and close-range Worldshear directions before broader class expansion;
- every discovered gameplay defect receives a focused regression.

Explicitly out of scope:

- new playable classes or Penitent production work;
- co-op or networking;
- a second realm;
- broad item-generation expansion;
- final imported character/environment art;
- Dead Star, the full level-1–50 production tree, and broad discipline expansion;
- Godot-to-Unreal migration;
- large refactors unrelated to the active combat slice.

## Production rules

- Start every task from current `main` and record the exact base SHA.
- One implementation agent owns a system at a time.
- Maximum one active gameplay implementation PR and one non-overlapping docs/tooling PR.
- Normal work stays one PR deep; two levels require a real dependency; deeper stacks are consolidated before more work.
- Every feature begins with a production packet: player goal, scope, exclusions, owners, ADRs, acceptance criteria, tests, manual playtest, persistence impact, performance risk, and Definition of Done.
- A feature is complete only after Godot execution, explicit PASS markers, frozen exact-head verification, a Windows artifact when player-facing, owner playtest, and explicit merge approval.
- Claude verifies frozen commits read-only. It does not co-author the implementation under review.

## Known follow-ups that do not block the slice

- Add `scripts/core/character_factory.gd` to the full-stack workflow trigger paths until that correction reaches approved `main`.
- Decide whether freeze branches should trigger workflows on push.
- Decide and document the Godot 4.4 `*.gd.uid` policy.
- Resolve or formally contain the `Docs/` and `docs/` casing overlap before a packaging path touches both.
- Keep PR frozen-head metadata synchronized after correction passes; tracked by [Issue #84](https://github.com/D3MISEarch/ABYSSFALL/issues/84).

## Deferred milestones

- Penitent graphical validation and production polish.
- Additional launch classes.
- Production Meshy/Blender character integration.
- Dead Star and the remaining Voidbringer discipline roster beyond the approved foundational proof.
- Local and online co-op.
- Engine migration decision, which remains gated behind a structured Godot playtest of the polished vertical slice.
