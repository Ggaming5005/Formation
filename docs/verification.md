# Verification

Recorded against Luau 0.747, Rojo 7.7.0 and Roblox Studio 0.747.0.7471481 on Windows.

## Portable checks

- Rows, Arc and Orbit at counts 1–100: expected counts and finite coordinates.
- Mixed footprint sizes: row separation and all-pairs curved-layout spacing.
- Invalid numeric settings, unknown keys and inconsistent distance thresholds.
- Strict analysis of portable Settings and Layout modules.

The large assertion count comes from pairwise/count sweeps, not thousands of distinct behavioral scenarios.

## Studio integration

- Actual PluginManager test plugin created and App.start opened the native widget.
- Actual runtime cloned two model sizes, stepped and changed layout, removed companions and handled repeated removal.
- Destroying an Instance owner removed the controller folder; repeated Destroy was harmless.
- Included companions rendered in an Edit-mode moving preview and in the standalone Play Client demo.
- Off-center 4-stud cube templates kept conservative clearance, with source pivots/parts unchanged.
- Read-only settings, invalid non-archivable part templates, repeated Start/Stop, and failed Add cleanup passed.
- Demo handle destruction removed the course, GUI and renderer folder; repeated Destroy was harmless in Play Client.
- The real interactive Orbit control changed the layout in Play Client.
- The installed local plugin opened from its packaged `.rbxm` in a separate Studio instance.
- A 32-second 1280×720 H.264 clip was recorded from actual Play-mode rendering at 30 fps. Frames from each of its four modes were visually checked.

`tests/studio.luau` supplies the runtime integration checks when mounted as a ModuleScript and called with the runtime module. No target-device performance benchmark or production-scale load claim is made.
