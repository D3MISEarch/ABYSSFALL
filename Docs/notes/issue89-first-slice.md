# Issue #89 — First implementation slice

This branch begins the Voidbringer foundation with the smallest dependency-unlocking runtime change: generic ability charges and deterministic recharge.

## Included

- Backward-compatible `AbilityDefinition` metadata for slot type, charges, recharge, Instability delta, and tags.
- Deterministic sequential charge recharge in `AbilityRuntime`.
- Charge-aware, loadout-aware, rejection-atomic execution results in `AbilityExecutor`.
- Focused Godot regression proving cooldown compatibility, two-charge exhaustion/recharge, equipped-state validation, and no resource/charge liability on rejected casts.
- Focused Godot 4.4.1 workflow with exact PASS-marker enforcement.

## Explicitly not included yet

- Anchor, Fold Line, or Instability/Breach ownership.
- Campaign input changes or final loadout UI.
- Mass Brand, Null Shard, or other dependent skill gameplay.
- Combat physics or presentation changes.

Those follow only after this exact candidate is green and reviewed.
