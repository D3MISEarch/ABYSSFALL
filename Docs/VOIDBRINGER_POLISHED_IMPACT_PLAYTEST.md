# Voidbringer Polished Impact Owner Playtest

## Exact package route

Use the Windows artifact named `AbyssFall-Voidbringer-Polished-Impact-<head-sha>` and run:

`Launch Voidbringer Polished Impact Sandbox.bat`

The launcher starts only the isolated `--sandbox=voidbringer_anchor` route. It does not enter campaign gameplay.

## 20–30 second repeat loop

1. Press `R` to reset and immediately fire one Null Shard at the sandbox target.
2. Watch the brace cue, projectile contact, directional target response, short camera impulse, and aftermath.
3. Repeat `R` as soon as the target response has settled. `Space` fires without resetting; `C` clears and resets without firing.

## Owner checklist

- Feel: the cast reads as a short brace and the impact feels heavier than ordinary projectile travel without stalling control.
- Readability: one contact flash and one directional target response identify the accepted hit; no cue appears for invalid or dead contacts.
- Audio: enabled presentation plays one short pressure-impact cue per accepted hit; reduced or disabled presentation may omit it without changing damage.
- Haptics: with a controller, enabled presentation requests one short vibration; with no controller, the loop stays silent and safe.
- Reset/replay: `R` restores camera and temporary target presentation before launching one fresh Null Shard; no old flashes, recoil, or projectile visuals remain.
- Gameplay equivalence: enabled, reduced, disabled, and no-controller paths preserve the same damage, critical result, target health/death ownership, cooldown behavior, and rewards.

## Boundaries

This playtest observes the authoritative `VoidbringerImpactResult` only after the validated target has applied damage. `PlayableCombatProjection` remains the sole outgoing calculation authority; the presentation layer never rolls criticals, recalculates damage, changes target state, or creates persistence state.
