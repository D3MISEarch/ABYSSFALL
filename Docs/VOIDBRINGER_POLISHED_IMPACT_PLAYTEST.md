# Voidbringer Spectacle Impact Owner Playtest

## Exact package route

Use the Windows artifact named `AbyssFall-Voidbringer-Spectacle-Impact-<head-sha>` and run:

`Launch Voidbringer Spectacle Impact Sandbox.bat`

The launcher starts only the isolated `--sandbox=voidbringer_anchor` route. It does not enter campaign gameplay.

## 20–30 second repeat loop

1. Press `R` to reset and immediately fire one Null Shard at the sandbox target.
2. Watch the brace cue, projectile contact, inward-collapse spectacle, target compression, short camera impulse, and aftermath.
3. Repeat `R` as soon as the target response has settled. `Space` fires without resetting; `C` clears and resets without firing.

## Owner checklist

- Feel: the cast reads as a short brace, then the target and nearby debris seem pulled toward one brief singularity before the room settles; it feels heavier than ordinary projectile travel without stalling control.
- Readability: the violet-white shock ring expands, turns inward, and collapses distinctly from a simple sphere. Fixed motes curve into the same point, and a brief residue disc marks the impact location. No cue appears for invalid or dead contacts.
- Target response: the target visually compresses and pulls toward the impact, then returns exactly to its original transform. It must not slide, collide, lose additional health, or change AI behavior.
- Critical: a confirmed critical has a visibly broader, brighter ring/residue/light profile. It is a presentation of the displayed critical result, not a second roll.
- Audio: enabled presentation plays one short pressure-impact cue per accepted hit; reduced or disabled presentation may omit detail without changing damage.
- Haptics: with a controller, enabled presentation requests one short vibration; with no controller, the loop stays silent and safe.
- Reset/replay: `R` restores camera and temporary target presentation before launching one fresh Null Shard; no old rings, motes, residue, light, recoil, audio state, or projectile visuals remain.
- Gameplay equivalence: enabled, reduced, disabled, and no-controller paths preserve the same damage, critical result, target health/death ownership, cooldown behavior, and rewards.

## Boundaries

This playtest observes the authoritative `VoidbringerImpactResult` only after the validated target has applied damage. `PlayableCombatProjection` remains the sole outgoing calculation authority; the presentation layer never rolls criticals, recalculates damage, changes target state, force, movement, collision, AI, rewards, cooldowns, or persistence state. One active spectacle is bounded to one shock ring, at most eight motes, one residue disc, one light pulse, one audio player, and one target-feedback object.
