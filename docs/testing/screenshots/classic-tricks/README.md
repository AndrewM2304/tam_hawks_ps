# Classic trick and quay transition captures

17 October 2026. `./tools/classic_tricks_capture.sh` completed **22 records / 42 rendered PNGs / zero capture errors**, using Godot 4.6.3 Compatibility/llvmpipe at 1280×800, fixed 60 Hz and disabled persistence. **25 representative images** are retained here; [manifest.json](manifest.json) records hashes and retained flags for all 42. Every generated PNG was fully decoded/validated before selecting the retained set.

[recipe.json](recipe.json) records actual input sequences, runtime state, board angles, body/normal frame, velocity and camera position. Only the initial fixture is placed; subsequent admission/movement uses production controls and physics. Saved admitted poses are frozen for inspection. `*-chase.png` uses the production camera; `*-close.png` and the overview use explicitly authored inspection cameras. This is action/pose evidence, not a continuous motion video, timing benchmark or played-controller result.

Representative views:

- [Crouch](01-crouch-chase.png), six `flip-*-close.png` views, five `grab-*-close.png` views, [Manual](manual-close.png) and [Nose Manual](nose_manual-close.png).
- [Actual mid-wall chase](quarterpipe-mid-wall-chase.png), [natural vert aerial](quarterpipe-natural-vert-air-chase.png), [half-pipe wall](halfpipe-east-wall-chase.png) and [feature overview](quarter-and-halfpipe-overview.png).
- [Axle Stall](lip-axle_stall-close.png), [Nose Stall](lip-nose_stall-close.png), [Tail Stall](lip-tail_stall-close.png) and [Disaster](lip-disaster-close.png).

Root inspected the current mid-wall chase, Disaster and Method close views, alongside the prior same-geometry overview/vert inspection. Curved support visibly turns the skater and board; the mineral concrete surface avoids the rejected bright flat material. Hands, clothing, texture repetition and overall environment still need the planned final art/animation work.

The runtime/tool checkpoint is `ede191b3d75a28bf308d09a1b66a55cbcb0409c3`. All **137 recorded inputs** match that commit and remain unchanged after recording. Root froze production before launch; hashes were recorded during the capture, so this package does not claim an automated before-launch fingerprint. The strict before/after fingerprint packages are the separate normal-play capture and cold-source receipt.

Manifest SHA-256: `edb860b86e59941682d487e12f4974e6e24e6f74edd28d4faf271bd4f7d95f01`. Linux fixed-clock images do not establish Mac shaders, human fun, physical DualSense behavior, repeated high-speed aerial cycles or target frame times.
