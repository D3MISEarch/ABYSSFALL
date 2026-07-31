# Visual Foundation v0.1 Architecture Boundary

## Status

DRAFT — STACKED OWNER PLAYTEST CANDIDATE

## Dependency

This slice is stacked on the exact revised camera-director head from PR #130:

`f286661d9f17bed4fc63f7a0585faafb50df360b`

It must not be merged independently ahead of the camera dependency. The stacked branch is for one combined owner playtest only.

## Ownership

- The existing gameplay route remains the owner of encounter state, enemies, Hollow King, damage, death, rewards, persistence, movement, collision, navigation, and progression.
- `IntegratedCameraDirector` remains the sole production camera-presentation owner.
- `VisualFoundationLightingService` installs authored lights, atmosphere, and post-processing against the existing route and `WorldEnvironment`.
- `VisualFoundationMaterials` applies shared presentation materials once to visual descendants and existing route surface meshes.
- `VisualFoundationVFXService` owns bounded decorative dust, pulses, and non-colliding debris only.
- `VisualFoundationCinematicService` observes existing camera, room, boss, Rift, Nova, and death presentation facts and composes lighting/fog/VFX responses without owning those facts.

## Hard limits

- 18 active route effects maximum.
- 12 decorative debris fragments per burst maximum.
- Five ambient dust emitters with a combined amount no greater than 138.
- Five authored shadowed spot keys and two non-shadowed fills.
- No new `CollisionObject3D`, `CollisionShape3D`, navigation, damage, reward, movement, persistence, or encounter authority.
- No per-frame scene-tree scans; event nodes are registered once and tracked through weak references.
- All temporary effects clean up through bounded timers, reset clearing, invalid-reference pruning, and scene teardown.

## Material and imported-asset workflow

Future Meshy or authored props should use functional material-slot names and modular visual roots. Collision remains a separate simplified gameplay asset. Engine emissive materials control violet-white supernatural energy so generated albedo does not permanently bake the wrong glow intensity.

## Merge gate

Automated import, audits, focused regressions, inherited route regressions, exact-head Windows packaging, and hidden-error scans are required. They do not replace owner visual/readability approval.
