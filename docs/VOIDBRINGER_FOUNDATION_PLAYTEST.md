ABYSSFALL — VOIDBRINGER FOUNDATION SANDBOX

BUILD IDENTITY
- Confirm the exact commit in BUILD_INFO.txt before reporting results.
- Keep AbyssFall.exe and AbyssFall.pck in the same extracted folder.

LAUNCH
1. Extract the complete ZIP.
2. Double-click "Launch Voidbringer Foundation Sandbox.bat".
3. The sandbox should open directly without loading or modifying a campaign build.
4. The upper-left panel should read "VOIDBRINGER FOUNDATION SANDBOX".

KEYBOARD CONTROLS
- 1: place an Enemy Anchor
- 2: place a Terrain Anchor
- 3: place a Corpse Anchor
- M: add 20 Mass to the newest Anchor
- I: add 20 Instability
- T: advance foundation simulation by one second
- L: toggle the sandbox between level 1 and level 5
- C: clear all transient Anchor, Fold Line, Instability, and Breach state
- F3: toggle the standard diagnostic overlay
- F8: save/copy a diagnostic report

EXPECTED FOUNDATION BEHAVIOR
- Level 1 allows two active Anchors; placing a third replaces the oldest.
- Level 5 allows three active Anchors.
- Enemy Anchors last 12 seconds, Terrain Anchors 18 seconds, and Corpse Anchors 8 seconds.
- Mass is clamped to 0–100.
- Dormant: 0–34 Mass.
- Dense: 35–69 Mass.
- Critical: 70–100 Mass.
- Every pair of active Anchors creates one visible Fold Line.
- Fold Lines are visual/query geometry only and must not block movement or create collision.
- Instability does not decay until four seconds without a spatial action, then decays at 5 per second.
- Reaching 100 Instability enters an eight-second Breach.
- During Breach, the HUD should show x1.30 Anchor Influence while Instability drains to zero.
- Clearing the sandbox removes every Anchor, Fold Line, and Breach state without stale visuals.

PLAYTEST CHECKLIST
1. Place Enemy and Terrain Anchors and confirm one Fold Line appears.
2. Add Mass repeatedly and verify the Anchor changes from Dormant to Dense to Critical.
3. At level 1, place a third Anchor and confirm deterministic oldest replacement.
4. Toggle to level 5 and confirm three Anchors can remain active.
5. Press I five times and confirm Breach begins at 100 Instability.
6. Observe the eight-second drain and return to a contained state.
7. Use C during normal state and during Breach; verify complete cleanup.
8. Leave the sandbox running for several minutes and watch for duplicate lines, stale labels, visual buildup, frame-time degradation, or Godot errors.

REPORTING
Include:
- Full commit from BUILD_INFO.txt
- Controller/keyboard setup
- Exact command sequence
- What happened versus what you expected
- Screenshot or video where useful
- F8 report text or file

This package is an isolated systems sandbox. Mass Brand, Null Shard, campaign integration, final HUD art, wider combat physics, and the polished showcase are separate dependent slices.
