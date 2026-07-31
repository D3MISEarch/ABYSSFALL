# Integrated Camera Director Playtest

## Exact Windows package launch

Open `PLAY_CAMERA_DIRECTOR.cmd` from the extracted exact-head package. It launches the real production route as Voidbringer:

```text
main.tscn → boot.gd → gameplay.tscn → full_stack_controller_main.gd → multiclass_main.gd → main.gd
```

This is not a camera sandbox. It retains the normal player, aiming, encounters, Hollow King, rewards, progression, persistence, and replay flow. Press `F3` in game for the existing diagnostics overlay.

## Camera owner checklist

- [ ] **Default feel:** At launch, the camera is visibly lower and closer than the previous gameplay frame while the Voidbringer, aiming direction, nearby enemies, and telegraphs remain easy to read.
- [ ] **Swarm readability:** In the authored courtyard, generator room, catacombs, or trap hall, a sustained count of five or more live enemies raises and pulls the camera back smoothly. A brief drop to two or fewer enemies does not snap it back; the return waits for the short hold.
- [ ] **Boss reveal:** Reach the Hollow King through the normal route. His one introduction frames both the player and boss at a larger cinematic scale, holds briefly, and returns smoothly to the exact prior gameplay camera frame.
- [ ] **Controls:** Mouse/keyboard aiming and a connected controller both retain their normal movement, aim, and menu behavior. The camera director does not bind or consume input.
- [ ] **Interruption and replay:** Player death, boss death, `R` restart, menu return, and scene teardown restore the camera deterministically. Replay the route and check for no accumulated position, angle, or FOV drift.
- [ ] **Gameplay equivalence:** Enemy health, damage, rewards, XP, loot, checkpoint/progression flow, cooldowns, collision, and class selection remain unchanged across all three camera states.

## Presentation boundary

`IntegratedCameraDirector` consumes only the `main.gd` player/boss transforms, live encounter state, and existing `enemies_alive` count. It writes temporary camera transform/FOV presentation only. It does not own input, damage, health/death, rewards, progression, persistence, movement, collision, AI, or encounter transitions.

## Tuning values

The small, named tuning surface is in [`../scripts/integrated_camera_director.gd`](../scripts/integrated_camera_director.gd). The production direction is intentionally low and oblique:

- **Default Gameplay:** height `9.4`, distance `11.8`, FOV `48`, and a `0.40` second transition. This is the normal dark-cinematic ARPG frame; it is not an overview state.
- **Swarm Combat:** height `12.5`, distance `15.5`, FOV `50`, and a `0.56` second transition. It expands only enough for real combat pressure while remaining lower and closer than the legacy room overview.
- **Boss Reveal:** height `6.8`, distance `25.0`, FOV `39`; approach, hold, and restore are `0.50`, `0.72`, and `0.52` seconds. It stays temporary and restores the exact pre-reveal frame.
- **State rules:** Swarm requires at least five live enemies in an authored combat route. It returns only after the count is at most two for `1.20` seconds. Entering or clearing an ordinary room alone never changes the frame.
