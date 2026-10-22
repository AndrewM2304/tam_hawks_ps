# Bail and human-motion baseline

22 October2026, current production83758c3. [Research, diagnosis and ordered implementation tasks](../../research/THPS-BAIL-AND-HUMAN-MOTION-2026-10-22.md). This checkpoint changes documentation and an observation script only. It does **not** implement fall/get-up animation or fix stretching.

`current-03`: clean native diagnostic **3/0**, frozen377inputs,31.743s;1,061physics samples,24actual1280×800 frames captured and12selected originals retained. It uses production Main, mapped keyboard/directional inputs, real support/flight and an uncorrected manual imbalance. Each action trial starts from a normal reset; no per-tick movement or pose assignment. Native AppleM5/Godot4.6.3/Compatibility/balanced. [Receipt](evidence/current-03/receipt.json), [summary](evidence/summary.json), [source/evidence audit](audit.json).

The3checks establish enough observations, exactly one real manual bail, and completion without observer errors. They do not accept the gameplay. The diagnostic records a23.157315m same-tick bail reset and up to28.16% calf extension. It reads every active physics tick after the player, including transitions. Maxima are by whole trial, not claims about the single photographed instant.

Chase images use the actual production camera. **Profile images are explicitly diagnostic views:** the observer pauses the tree, temporarily places the camera, captures the unchanged posed model, restores the camera and resumes. They do not show the player's normal camera or establish rendering performance. All image readbacks are excluded from timing admission. Twelve originals pass native decode/hash checks12/0,0.455s; no synthetic/edited frames.

- [Before manual bail, actual chase](evidence/current-03/manual-before-bail-chase.png) and [after, actual chase](evidence/current-03/after-bail-chase.png).
- Diagnostic profile: [push](evidence/current-03/push-profile.png), [brake](evidence/current-03/brake-profile.png), [melon grab](evidence/current-03/melon_grab-profile.png), [nose grab](evidence/current-03/nose_grab-profile.png).
- Additional idle/charged/method/bail profile frames are listed in the summary; all24original captures remain in ignored `.local/bail-research/current-03` on this machine.

Rejected observer runs remain: `current-01` fails parsing because its recorder owner was typed Node instead of SceneTree. `current-02` records2/1 because two diagnostic grab directions were labelled incorrectly; their rendered models/production controls were not changed. `current-03` uses the actual catalogue directions and passes. Each archived loaded observer snapshot matches its own receipt manifest; no rejected run is promoted or silently re-labelled.

Reproduce from repository root with installed `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 docs/testing/horizon-background/observers/run_checked.py .local/bail-research/current-repeat ./tools/run.sh --rendering-method gl_compatibility --windowed --resolution 1280x800 --audio-driver Dummy --script docs/testing/bail-recovery/observers/current_audit.gd -- .local/bail-research/current-repeat
python3 docs/testing/bail-recovery/observers/audit.py
```

No production changes: all375game/test/tool/project inputs match83758c3. Its complete2226/0 regression remains the existing production result, not a newly rerun suite. No new native performance admission is claimed for this research observer. Future production work must run tools/check.sh, meaningful pose/recovery regressions, matched native performance and actual motion/frame review.
