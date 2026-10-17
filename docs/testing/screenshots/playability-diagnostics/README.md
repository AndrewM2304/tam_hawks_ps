# Normal native gameplay baseline — 17 October 2026

These five unedited 1280×800 window captures show the **frozen Linux export** from `builds/tam-hawks-20261017T185223Z-00da63a29990/linux/`, run at 19:02:46 UTC using its own PCK. They are comparison evidence for the owner's report of an always-invisible skater when launching the source on a Mac. They do not verify that Mac path or the later source fix.

The executable ran normally with `--windowed --resolution 1280x800 --position 0,0 --audio-driver Dummy`, on a private Xorg display with llvmpipe and isolated profile directories. No Godot script was supplied, no frame loop was disabled, no fixed FPS was imposed, and no skater/camera method or transform was called. `xdotool` was unavailable; installed X11/XTest libraries delivered synthetic keyboard/mouse events through the native window. ImageMagick captured that window without image alteration.

| Image | Observed state / preceding input |
|---|---|
| `baseline-01-title.png` | Normal title, career button focused. Earlier Tab/Return opened goals; Escape returned to the title. |
| `baseline-02-free-skate-spawn.png` | Clicked the visible Free Skate button at window coordinate (520,435), then waited 3 wall-clock seconds. Full skater and board visible; HUD Free Skate and 0 km/h. |
| `baseline-03-forward.png` | Held W for 2 wall-clock seconds and released. Full skater/board visible in the moving chase view; HUD 19 km/h. |
| `baseline-04-left-turn.png` | Held W+A for 1 wall-clock second and released. Full skater/board visible; HUD 23 km/h. |
| `baseline-05-turn-facing-frontage.png` | After holding S for 2 seconds, held W+A for 4 seconds and S for 2 seconds. Stopped facing the retail frontage; full skater/board visible and HUD 0 km/h. This is a frontage approach, not proof of direct wall contact. |

The captured Linux baseline does not reproduce an always-missing avatar. Its complete startup/run stderr contains the Godot 4.6.3 version and one unsupported V-Sync warning, with no script, visual-construction or resource errors. It does not rule out the source-import failure being investigated separately, a different engine/renderer, or camera occlusion during direct wall contact. Software rendering is slow; wall-clock input durations are not simulation timing or a target-performance measurement.

Ignored diagnostic files remain in `.local/native-playability-baseline/`: `drive_native.py`, `receipt.json`, `inputs.json`, `game.log`, Xorg logs and the original captures (including the early splash/goals frames). In the raw input log, `seconds` on hold/wait commands is the requested duration; capture/other event `seconds` is elapsed run time. No in-engine positions or camera values were queried. Both the game and private Xorg were stopped after this bounded 231-second session.

| Frozen input | SHA-256 |
|---|---|
| Linux executable | `2c78919325d7f29fa7607287c7c1eeac367ea4c94e7b8b6f5f4c6b20492f73d0` |
| PCK | `6447f96516e715e1d4881e934175c137f28dcc7283895e611b1b51e4b38b76cc` |

No production files, packages or test suites were changed/run by this diagnostic pass. Physical Mac/DualSense behavior and human camera comfort remain unverified here.
