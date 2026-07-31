# Hollow King Nova Readability Playtest

This checklist covers Issue #123's boss-local presentation pass for the Hollow King's existing Nova. It does not change Nova's gameplay contract: phase 2 starts with a `4.2s` timer and resets to `5.2s`; phase 3 resets to `3.7s`; Nova emits `10`/`14` evenly radial bolts at `10.8`/`11.8` speed for `11`/`13` bolt damage; and the existing `4.4`-radius direct contact remains `16`/`19` damage.

## Package and route

Use the exact-head `AbyssFall-Hollow-King-Nova-<short-sha>` Windows artifact. `BUILD_INFO.txt` identifies the reviewed commit. Launch `AbyssFall.exe` through the normal playable route and reach the Hollow King encounter; this slice intentionally does not add a second campaign, boss, or global launch framework.

## Owner checklist

- Can Nova be recognized before release without looking at the HUD?
- Is the violet/white danger boundary readable but not visually dominant?
- Is imminent detonation clearly more urgent than early anticipation?
- Does the existing release feel powerful while remaining legible?
- Can the player, enemy projectiles, Anchors, Fold Lines, and exits still be seen?
- Does it remain readable while using Mass Brand and Null Shard?
- Does killing the boss during Nova remove all effects?
- Does a phase transition during Nova remove all effects?
- Do repeated Nova cycles remain clean, with no accumulated rings, lights, or fragments?
- Does reduced mode preserve the warning while reducing light and fragments?
- Does disabled mode leave the authoritative Nova gameplay unchanged?

## Presentation lifecycle and accessibility modes

`HollowKingNovaPresentation` is a boss-local observer. Hollow King forwards only its existing countdown, existing `4.4` radius, and a post-release confirmation. The helper creates at most one transaction, danger boundary, imminent set, aftermath set, residue node, local light, and helper; enabled mode has at most six motes, reduced mode at most two, and disabled mode creates no presentation nodes. Optional audio and camera hooks are intentionally unused in this slice, so their active count remains zero and no camera or audio state is changed.

The helper never receives a target and never calculates damage, selects attacks, mutates timers/phases, spawns bolts, moves objects, changes rewards, or writes persistence. Hollow King still owns health, phase, movement, Nova cadence/release, and death; `EnemyBolt` still owns travel, collision, damage, and projectile cleanup; `main.gd` still owns encounter coordination, rewards, progression, and checkpoints.

Cleanup is deterministic on phase transition, boss death, invalid target, scene teardown, and the focused regression's replay/reset path. The helper owns only its temporary decorative nodes and never changes the boss transform, boss materials, collision, camera, or gameplay state.
