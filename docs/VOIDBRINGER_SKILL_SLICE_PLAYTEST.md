# Voidbringer Mass Brand + Null Shard Owner Playtest

This isolated Windows sandbox proves the first playable Voidbringer interaction without loading campaign persistence or altering a save:

`Mass Brand -> Anchor/Fold setup -> Null Shard crossing -> committed impact -> cleanup`

## Launch

Extract the exact-head artifact and double-click:

`Launch Voidbringer Skill Slice Sandbox.bat`

The upper-left title must read:

`VOIDBRINGER MASS BRAND + NULL SHARD SANDBOX`

## Gameplay controls

- `Q` — Mass Brand the enemy fixture.
- `W` — Mass Brand the terrain fixture.
- `E` — Mass Brand the corpse fixture.
- `Space` — fire Null Shard at the live enemy fixture.
- `T` — advance simulation and recharge by one second.
- `L` — toggle level 1 / level 5 Anchor capacity.
- `C` — clear and reset Anchors, projectiles, Instability, charges and enemy health.

Foundation diagnostics remain available:

- `1` — direct enemy Anchor.
- `2` — direct terrain Anchor.
- `3` — direct corpse Anchor.
- `M` — add 20 Mass to the newest Anchor.
- `I` — add 20 Instability.

## Required owner checks

### 1. Enemy Mass Brand contact

1. Press `C`.
2. Press `Q` once.

Expected:

- enemy health changes from `100` to `92`;
- one enemy Anchor exists;
- Instability becomes `5`;
- Mass Brand charges change from `2 / 2` to `1 / 2`;
- the last impact reports `vb.skill.mass_brand`, damage `8`, and no critical;
- one contact flash appears at the enemy;
- no duplicate hit or duplicate Anchor appears.

### 2. Atomic charge rejection

1. Press `C`.
2. Press `W`, then `E`.
3. Before recharging, press `Q`.

Expected:

- the terrain and corpse Anchors remain the only two Anchors;
- the enemy remains at `100` health;
- Instability remains `10`;
- charges remain `0 / 2`;
- the HUD reports a `NO_CHARGES` rejection;
- no enemy contact flash, damage, or false Anchor appears.

### 3. Fold-enhanced Null Shard

Continue from the terrain + corpse setup above, or press `C`, then `W`, then `E`.

1. Confirm one Fold Line crosses the central firing lane.
2. Press `Space` once.

Expected:

- one visible Null Shard travels from the Voidbringer marker toward the enemy;
- it crosses exactly one Fold Line;
- the projectile visibly grows slightly after crossing;
- enemy health changes from `100` to `80`;
- the last impact reports damage `20` and one Fold crossing;
- terrain Mass becomes `7` and corpse Mass becomes `22`;
- total Instability becomes `14`;
- the projectile and its visual clean up immediately after contact.

### 4. Sequential charge recharge

1. Press `C`, then `W`, then `E` to consume both Mass Brand charges.
2. Press `T` four times.

Expected: one charge has returned.

3. Press `T` four more times.

Expected: both charges have returned. Recharge is sequential, not parallel.

### 5. Level capacity and cleanup

1. Press `C`.
2. Press `L` to reach level 5.
3. Press `Q`, `W`, then wait or use `T` until another charge is available, then press `E`.

Expected:

- level 5 retains three Anchors;
- three Anchors produce three readable Fold Lines;
- no stale line remains when an Anchor expires.

Finally press `C`.

Expected:

- zero Anchors;
- zero Fold Lines;
- zero projectiles;
- enemy health restored to `100`;
- Mass Brand charges restored to `2 / 2`;
- class state returns to `CONTAINED`;
- no stale flash, projectile, label or line remains.

## Feel/readability gate

Answer each with `YES`, `MIXED`, or `NO`:

1. Is the difference between Mass Brand placement and Null Shard travel immediately understandable?
2. Does the Fold Line clearly communicate where Null Shard should be fired?
3. Is the one-crossing payoff obvious without becoming visually noisy?
4. Does enemy damage agree with the HUD impact result every time?
5. Does the interaction already feel promising enough for the full savage-impact presentation pass?

This is a gameplay/readability slice, not the final Diablo IV / Mortal Kombat presentation pass. Placeholder geometry and procedural effects are expected; inconsistent gameplay results, duplicate hits, false cues, stale state, or confusing Fold behavior are not.
