# Clyde bowl excavation evidence

24October2026, native Godot4.6.3, Apple M5, Compatibility renderer. BOWL-01 is an
implemented owner-playtest repair with focused/native verification. Whole-game
regression acceptance remains open. No owner feel, controller or export pass.

The bowl bottom moves fromY2 toY−0.4, placing its deck at quayY2. Both overlapping
quay/yard surfaces are physically excavated. Two raised access bodies are removed;
the annular deck reuses the existing world-aligned paving material. Shape, coping
and stable IDs remain. Other recorded pose/pop/camera/lighting defects are open.

## Verification

| Check | Result |
|---|---|
| Focused collision/entry/carve/visual-contact regressions | **50 passed,0 failed**, clean/frozen |
| Native pit rays vs support queries |330 samples, maximum error0.0000079m; no Y2 cap |
| Exterior/through-lane native rays |53 retained Y2 contacts |
| Production outside approach | crosses flush rim and enters, no ongoing fixture motion |
| Production bowl lap |6.2903rad /30.231m with support, no bail, finite camera |
| Actual inventory |557 bodies/1653 shapes; protected271/720 unchanged |
| Startup display geometry |+136 paving triangles; declared cap1024 |
| First required check |4519/22; rejected, including two stale access-body expectations |
| Final required `tools/check.sh` |**4521/20**, exit1; rejected, source stable514inputs |
| Unchanged HEAD required baseline |**4517/20**, exit1; source stable514inputs |

[Comparison](comparison.json) proves identical20 failure labels, no new label.
All513 repository game/test/tool/project inputs of the temporary baseline match
`d00965a4ee1e0be6f0d5202c284edd1bb70ebf34` independently. The four additional passing
assertions cover this excavation. Two exact inventory expectations migrated for
the owner-requested removal; no production skating behavior changed to satisfy
other failures. Remaining failures cover ramp camera, repeated flip, named grind
sole contact, two Kelvingrove lip-clearance cases, rail pivot scoring/stance and
two compact-Clyde return routes. They remain open; this is not a green full suite.

Baseline uses `git archive <HEAD> game tests tools project.godot docs` extracted
to `/private/tmp/tam-hawks-clyde-baseline-20261024`, without a worktree. Its copied
[receipt wrapper](baseline-run-checked.py.txt) pins `git_head` to the archive hash
because the copy has no Git directory. All other fingerprint/check logic stays
the same. Both final full suites ran concurrently at fixed logical60Hz; these
are functional checks, never frame-time measurements. Receipts retain failures.

## Actual captured views and cost

[Before](before/overview.png), [after](after/overview.png): same camera at
(−7,22,131), target(−7,1,134.5), requested1280×720 window, actual1152×720 viewport.
Native runs are clean/frozen515inputs. [First view](rejected-obstructed-before/overview.png)
is rejected for comparison because a foreground building obscures the bowl.

| Static120-frame diagnostic | Before | After |
|---|---:|---:|
| p50 / p95 / p99 ms |6.730 /11.517 /11.645|5.892 /11.468 /11.900|
| >33.333ms frames |0|0|
| Draw calls |119|115|
| Primitives |82014|82210|
| Texture memory bytes |47623163|47623163|
| Video memory bytes |74388043|74396803|

No new material, texture, draw surface or body;8,760bytes more reported video
memory. No rebuilding per frame. Runs were separate from the full checks, but
system/render contention is not independently certified. Static samples do not
close the existing moving stutter/performance gate or establish an FPS gain.

## Commands and reproducibility

With `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`:

```
python3 docs/testing/horizon-background/observers/run_checked.py .local/clyde-sunken-bowl/focused-01 ./tools/run.sh --headless --fixed-fps 60 --script .local/clyde-sunken-bowl/focused.gd
python3 docs/testing/horizon-background/observers/run_checked.py .local/clyde-sunken-bowl/required-02 ./tools/check.sh
BOWL_CAPTURE_OUTPUT=.local/clyde-sunken-bowl/after python3 docs/testing/horizon-background/observers/run_checked.py .local/clyde-sunken-bowl/after-run ./tools/run.sh --rendering-method gl_compatibility --windowed --resolution 1280x720 --audio-driver Dummy --script .local/clyde-sunken-bowl/capture.gd
```

Exact loaded [capture](capture.gd.txt) and [focused](focused.gd.txt) recipes,
before/after input manifests, logs and receipts are retained. Focused source
precedes only the final horizon inventory migration; final required/capture
manifests bind the resulting production source. Artifact hashes are in
`artifacts.json`. No engine or automatic continuation remains running.
