# Issue 64 — Voidbringer Ability VFX Art Pass 0B

## Purpose

Apply a coherent, procedural first visual pass to the existing Void Warlock compatibility prototype's three signature combat actions without changing gameplay values or runtime ownership:

- Void Bolt;
- Grasping Rift;
- Shadow Step.

This slice is stacked on the owner-approved complete-route Sunken Crypts environment head `ced03f31f5dfa8c8d9fa7377c902d0bf064f50f4` from PR #60.

## Visual direction

### Void Bolt

The projectile should read as compressed gravity rather than a purple ball:

- pale gravitational-white core;
- fractured violet shell;
- asymmetric tapered wake;
- sharp compression-and-release impact;
- a visible but restrained outer tell for the splash-capable variant.

### Grasping Rift

The field should communicate inward force and imminent collapse:

- dark gravitational lens;
- pale-white compression edge;
- restrained violet fracture rings;
- inward streaks;
- deterministic orbiting debris accelerating toward the center;
- controlled collapse flash.

### Shadow Step

The dodge should communicate departure, direction, and arrival without hiding combat:

- departure fracture mark;
- stretched black-violet afterimages following the player's real path;
- directional streak;
- arrival compression mark.

## Non-negotiable safety boundaries

- Preserve Void Bolt speed, damage, lifetime, collision shape, splash radius, and splash damage inputs.
- Preserve Rift radius, duration, pull strength, collapse damage, dual-rift behavior, and generator damage.
- Preserve Shadow Step speed, duration, cooldown, invulnerability, collision response, and infected-step damage.
- Add no new gameplay collision objects.
- Add no persistence fields, runtime services, event contracts, or random gameplay behavior.
- Keep all VFX deterministic from local elapsed time and authored indices.

## Automated contract

`tests/test_voidbringer_vfx_pass0b.gd` verifies:

- required visual hierarchy for all three abilities;
- explosive Void Bolt tell visibility;
- exact setup values remain unchanged;
- Void Bolt retains exactly one collision shape;
- Rift debris moves inward during its pull window;
- Rift and Shadow Step add no collision objects;
- Shadow Step produces departure, real-path afterimages, direction, and arrival marks.

The suite is wired into `.github/workflows/persistent-level-flow-tests.yml` and runs before both playable-class smoke paths.

## Deliberate boundaries

This is procedural Art Pass 0B, not final shaders, final production animation, final sound design, final camera effects, or a migration decision between Godot and Unreal. Human Windows review remains required for readability, performance, and visual approval.
