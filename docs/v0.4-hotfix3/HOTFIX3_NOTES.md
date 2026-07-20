# AbyssFall v0.4 Hotfix 3

Fixes the runtime issues visible in the Godot 4.4 debugger screenshots:

- Replaced invalid `MeshInstance3D.modulate` access in the void trap with a pulsing, duplicated `StandardMaterial3D`.
- Sets the camera local position before adding it to the SceneTree, preventing the `is_inside_tree()` transform error.
- Renamed the Corruption Meter variable `seed` to avoid shadowing Godot's built-in `seed()` function.
