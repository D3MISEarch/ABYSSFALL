# Issue #53 — Front End, Build Selection, and Visible Save UX

Status: IMPLEMENTATION STARTED  
Parent stack: PR #50 + PR #54  
Base exact head: `ced346a576dd0df912b3730b8c338d31cedde3cb`  
Branch: `feature/issue53-front-end-save-ux`

## Player finding

The owner playtest proved that the current executable silently auto-launches the previously selected build and gives no clear save, continue, or character-management flow. Persistence exists, but the player cannot see or control it.

## Required player loop

`launch → home screen → Continue / New Character / Select Character → gameplay → visible save feedback → Save & Continue or Save & Exit to Menu → return later to the correct build`

## Scope

### Home screen

- Always show a front end for normal launches.
- Continue loads the currently selected valid build and displays its class, name, level, and last-played summary.
- New Character opens class selection and creates a separate build.
- Select Character lists all valid builds and safely selects one.
- Quit flushes dirty state before exiting.
- First launch with no builds routes directly to New Character/class selection.

### In-game pause/save menu

- Escape opens a dedicated pause menu when inventory/tree are closed.
- Save & Continue flushes the complete active runtime snapshot and shows Saving / Saved / Save Failed feedback.
- Save & Exit to Menu flushes first, then tears down gameplay and returns to the front end.
- Resume closes the menu and restores gameplay.
- Mouse, keyboard, and controller use the same actions and focus order.

### Persistence and safety

- Build selection never mutates another build.
- Invalid or corrupt selected builds are skipped safely and surfaced as unavailable.
- Leaving gameplay cannot claim success before persistence completes.
- Existing lifecycle and interval autosave remain active as a safety net.
- No save-root deletion or broad test cleanup is allowed.

## Regression requirements

- normal launch with builds shows the home screen instead of auto-launching;
- first launch with no builds opens class selection;
- Continue loads the correct selected build;
- New Character creates a distinct build;
- selecting another build loads its exact class and durable state;
- Save & Continue persists current runtime state;
- Save & Exit flushes before returning to menu;
- save failure remains in gameplay and shows failure feedback;
- controller focus is valid on every front-end and pause-menu transition;
- corrupt or missing selected build falls back without trapping startup;
- unrelated canary builds survive all tests unchanged.

## Deliberate boundaries

This slice does not add final menu art, settings implementation, character deletion confirmation, renaming UI, cloud saves, cinematics, or final audio. It establishes a correct and visible player-facing shell before the art-direction pass.

## Merge gates

1. Parent PRs resolve and this PR is retargeted to `main` without source drift.
2. Exact-head CI passes.
3. Frozen artifact receives independent verification.
4. Owner confirms front-end, build selection, visible saving, and full relaunch behavior in Windows.
5. Owner explicitly authorizes merge.
