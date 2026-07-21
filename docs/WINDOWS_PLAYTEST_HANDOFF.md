ABYSSFALL WINDOWS PLAYTEST

1. Extract the entire ZIP to a normal folder.
2. Keep AbyssFall.exe and AbyssFall.pck together.
3. Double-click AbyssFall.exe.
4. Press F3 in game to show or hide diagnostics.
5. Press F8 after reproducing a problem to save a timestamped playtest report.

The diagnostic panel should display the same short commit shown in BUILD_INFO.txt. Confirm that before reporting results so feedback is tied to the exact build.

F8 reports are saved in the Godot user-data playtest_reports folder. The F3 panel displays the exact absolute path after a successful save. Each report includes build identity, scene, FPS, active input profile, connected controller names, and a blank player-notes section.

For controller testing:
- Connect the controller before launching the game.
- Confirm the F3 panel lists the controller name.
- Confirm the active input profile changes after using mouse/keyboard and then controller input.
- Record whether PlayStation, Xbox, or keyboard/mouse prompts appear.

For Penitent testing:
- Confirm Ritual Blade attacks on the expected input.
- Check frontal reach, step-in behavior, collision safety, slash readability, and hit pulse fade.
- Confirm rear targets are not hit.

When reporting a problem, include:
- The F8 playtest report when available
- Full commit from BUILD_INFO.txt
- Controller name from the F3 panel
- Current input profile
- Class and room
- What happened and what was expected

SHA256SUMS.txt can be used to verify that the extracted executable, PCK, build information, and this guide match the package produced by CI.
