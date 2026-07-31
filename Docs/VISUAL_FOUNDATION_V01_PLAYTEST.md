# AbyssFall Visual Foundation v0.1 — Combined Owner Playtest

## Purpose

This stacked candidate combines the revised integrated camera director with the first real-route visual foundation pass. It is a presentation-only owner candidate for the live Voidbringer route from the Collapsed Catacombs through Hollow King.

It does **not** claim final environment art, final PBR textures, final Meshy assets, final character models, final boss art, or Unreal parity. It establishes the reusable Godot-side workflow and a visibly stronger authored baseline.

## Included visual work

### Camera composition

- Default gameplay retains the approved low, close, oblique framing from PR #130.
- Swarm framing expands only for meaningful pressure.
- Hollow King reveal remains temporary and restores the exact gameplay camera state.
- Visual Foundation observes these camera facts; it does not create a second camera owner.

### Lighting quality

- Five authored shadowed spot keys shape the Generator Chamber, Collapsed Catacombs, Hungry Hall, and Abyssal Throne.
- Two restrained local fills preserve gameplay readability without flattening the route.
- Hollow King receives a pale silhouette key and restrained violet rim rather than uniform room illumination.
- Swarm, boss-route, reveal, and death presentation alter light energy only; gameplay state is unchanged.

### Post-processing and atmosphere

The existing `WorldEnvironment` is tuned rather than replaced:

- filmic tone mapping and restrained exposure/white point;
- lower flat ambient energy;
- bounded glow for violet-white focal effects;
- depth fog with a cold violet-black color;
- route-wide low-density dust emitters with a hard particle budget.

The pass must remain readable at 1280×720 and must not crush enemies, pickups, exits, or boss telegraphs into black.

### Material workflow

Shared runtime material slots are applied once to existing route geometry:

- `stone` — cracked charcoal structural surfaces;
- `wet_stone` — selective floor, drain, and channel reflections;
- `obsidian` — altars, coffins, slabs, and throne focal pieces;
- `iron` / `rusted_iron` — restraints, chains, cages, clamps, and machinery;
- `violet_emissive` — void fractures and ritual geometry;
- `pale_emissive` — gravitational-white cores and focal accents;
- `corruption_trace` — restrained contamination only.

The pass changes `MeshInstance3D.material_override` only. Collision and navigation remain owned by the original route nodes.

### VFX pipeline and reactive debris

The shared route VFX service provides:

- dust bursts;
- restrained violet-white floor pulses;
- inward-pulling decorative fragments;
- skitter-and-settle debris aftermath;
- one global active-effect budget of 18;
- no more than 12 fragments per burst;
- deterministic timer cleanup and scene-reset clearing.

Confirmed Grasping Rift collapse, Hollow King Nova release, Hollow King death, room transitions, and the existing boss reveal can feed this presentation pipeline. The effects never apply damage, movement, collision, rewards, or encounter progression.

## Higher-end environment workflow

Use this convention for future Meshy or authored environment imports:

1. Export modular props with separate material slots named by function, not by generated asset name: `stone`, `wet_stone`, `obsidian`, `iron`, `rusted_iron`, `violet_emissive`, `pale_emissive`, or `corruption_trace`.
2. Keep glow out of baked albedo wherever practical. Engine emissive materials should control supernatural intensity.
3. Keep collision as a separate authored child or simplified sibling. Never reuse decorative debris geometry as gameplay collision.
4. Preserve real-world scale and orient forward consistently before import.
5. Prefer modular pillar, arch, gate, altar, restraint, rubble, and trim pieces over one giant room mesh.
6. Place imported visual roots under the existing art-pass route hierarchy so the shared material workflow can classify them once.
7. Treat generated topology as a starting point. Hero silhouettes, boss gates, and close-camera props still require cleanup and art direction.

## Launch

Extract the exact-head Windows artifact and run:

`PLAY_VISUAL_FOUNDATION.cmd`

The launcher enters the real Voidbringer route.

## Owner checklist

### 1. Default gameplay camera

- Does the majority of gameplay retain the preferred low, close boss-area feel?
- Is the player large enough on screen without hiding navigation or attacks?
- Do walls, pillars, cages, and machinery show more vertical scale?

### 2. Swarm camera

- Does meaningful pressure pull back smoothly without returning to the old tactical-board view?
- Does it avoid oscillating as enemies cross the threshold?

### 3. Lighting and post-processing

- Is the route immediately darker, deeper, and more directional?
- Are enemies, pickups, doors, attacks, and Voidbringer effects still readable?
- Is bloom restrained rather than fogging the whole image?
- Are black levels deep without looking crushed or muddy?

### 4. Fog and dust

- Does haze add depth between foreground, player, enemies, and architecture?
- Is dust visible when moving through light without becoming particle noise?
- Does atmosphere remain stable through pause, death, restart, and room transitions?

### 5. Materials

- Do floors read wetter and darker than walls?
- Do iron restraints and cages read differently from stone?
- Are violet-white focal materials controlled and green limited to contamination?

### 6. Reactive ground debris

- On Grasping Rift collapse, does dust lift and debris pull inward before settling?
- Does Hollow King Nova or death produce a stronger environmental response?
- During repeated events, do effects remain bounded without runaway fragments or stuck residue?

### 7. Hollow King cinematic presentation

- Does the reveal combine camera, silhouette lighting, fog, pulse, and debris into one authored beat?
- Does gameplay resume cleanly with no camera drift or permanent lighting spike?

## Verdict format

Use one result:

`PASS — Visual Foundation v0.1 is a noticeable improvement and may proceed to final unchanged-head verification.`

or

`PASS WITH REQUIRED REVISION —` followed by the exact room, event, and visual defect.

or

`FAIL —` followed by reproduction steps and the player-facing blocker.

Do not merge from automated evidence alone. This candidate requires owner visual and gameplay-readability approval.
