# Hollow King Memorable Death Playtest

## Purpose

This owner playtest covers the presentation-only Hollow King death payoff. It is intentionally a short observation pass over the existing Sunken Crypts boss kill: it does not introduce a new encounter, reward, control path, or gameplay state.

## Windows package route

The `Exact-head Hollow King memorable death package` job in `.github/workflows/full-stack-windows-package.yml` creates `AbyssFall-Hollow-King-Death-<short-sha>`. Launch `AbyssFall.exe`, play the existing level to the Hollow King, and use a normal lethal hit. `BUILD_INFO.txt` identifies the exact reviewed commit; this checklist is copied into the artifact as `README_HOLLOW_KING_DEATH.txt`.

## Owner checklist

- [ ] A confirmed lethal hit immediately preserves the existing victory, XP, crown-drop, gate, and progression readability.
- [ ] Any active green Nova intent, boundary, motes, and aftermath clear at the confirmed death without a lingering ring.
- [ ] The visible body appears to pull inward toward the chest/core while the authoritative boss body does not move.
- [ ] Six or fewer enabled-mode decorative fragments briefly suspend around the core, then collapse/fall/dissolve without clipping into gameplay space.
- [ ] The final violet-white core vacancy is restrained, readable, and does not cover the reward or victory UI.
- [ ] At most one short-lived floor scar remains after the fragments resolve, then clears before a replay/reset.
- [ ] Reduced presentation remains readable with lower density; disabled presentation leaves the same kill, reward, and progression outcome with no death effect.
- [ ] Repeating the encounter or returning through the menu leaves no stale light, fragment, mote, scar, or visual drift.
- [ ] Keyboard-only/headless-safe paths complete without requiring a controller; no controller haptic event is required.

## Authority contract

`scripts/hollow_king.gd` remains the sole owner of health, phase, alive/dead state, death signal, attack cleanup, and lifecycle. `scripts/main.gd` remains the sole owner of XP, loot, rewards, checkpoint, progression, and post-boss flow. `HollowKingDeathPresentation` receives one already-confirmed death fact and chest position only; it has no damage, reward, persistence, movement, attack, projectile, summon, or spawn authority.

## Deterministic bounds

Each confirmed death has a maximum of one transaction, one singularity, one scar, one local light, one audio-player slot, one camera-impulse slot, one haptic-event slot, six fragments, six motes, and one presentation helper. Temporary nodes self-clean within the bounded aftermath; no new gameplay collision descendants are created.
