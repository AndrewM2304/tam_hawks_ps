# Owner playtest repairs —24 October2026

Implemented on review/owner-playtest-20261024 against ad0f95f. Required full check
**4555 passed/0 failed**, exit0, clean import/log and516 unchanged inputs. All20
previous failure labels now pass;14 additional assertions cover the reported
path/air/limb defects, rigid rail frame and valid native curved fixtures.
[Final receipt](full-06/receipt.json), [complete log](full-06/console.log),
[tasks](../../planning/PLAYTEST-REPAIRS-2026-10-24.md),
[ADR-031](../../architecture/decisions/ADR-031-owner-playtest-repairs.md).

## Repair evidence

- **Legs/body:** keep the knee pole with the rider, preserve fixed anatomical
  lengths and normalize rigid frames. Three actual bowl jump/return/transfer
  cases supply328 measured leg samples, maximum length error0.000000086m,
  no knee inside the defined chest core. Full repertoire/grab/palm/bail tests
  remain intact. These sampled geometric checks do not certify every animation
  or the final realistic art gate.
- **Path:**25 native overlap rays and support queries agree atY17; four real
  no-jump diagonal traversals pass at3/12m/s in both directions. The73mm raised
  seam and27mm crossing kerb crown are removed without new collision bodies.
- **Bowl:**2/24-frame releases with held approach Push return; a fresh in-air
  release/repress transfers out. Peaks4.15/4.29m in these different release
  positions are not a controlled charge-height comparison. No flat ollie boost.
  Steep vert air retains upward/lateral carry; actual collision owns return.
- **Camera:** legacy normal/reduced runs each complete four departures, four
  returns and four one-way approximately180° apex arcs; zero unsafe frames,
  zero supported side-view frames. Max camera update0.995/0.986m, angle24.98°;
  quiet ordinary ollies and real new-park lip/hip/port checks pass. Landing head
  movement relative to body falls from0.359m to0.136m, below the unchanged0.30m
  limit; wheel/sole native-contact bands remain unchanged.
- **Pivots:** a long native trick sequence leaves an exactly rigid board and
  performs the real180° unweight/turn/reseat, changes stance, preserves tangent
  travel with its existing15% speed cost and banks exactly once. Clearance
  against rail steel and world solids is retained.
- **Finishes:** the installed park reuses existing grey mineral concrete,
  paving, masonry and steel. The Clyde bowl stays excavated/flush. No new asset,
  texture, material resource, draw surface or mesh topology. The new shared
  material key reuses the existing TransitionPark allocation.
- **Shadows:** the owner clarified that shadows flicker. Matched moving native
  on/off/PCF/bias/split diagnostics support improving shadow-edge sampling,
  rather than offsetting paving. Balanced/High now use13-tap PCF; Performance
  retains5. Same sun, atlas, bias, normal bias, opacity and shadow ranges; contact
  shadows remain. Split shadows and increased bias are not adopted.

Shadow research: Godot's [lighting documentation](https://docs.godotengine.org/en/latest/tutorials/3d/lights_and_shadows.html)
and [Compatibility source at4.6-stable](https://github.com/godotengine/godot/blob/4.6-stable/drivers/gles3/rasterizer_scene_gles3.cpp)
were inspected24October. Its filter selection uses5/13 fixed PCF samples. No engine
code was imported. Runtime tests use installed4.6.3, OpenGL4.1 Metal91.7, AppleM5.
Existing concrete is the pinned CC0 material in
[the texture manifest](../../../game/art/assets/zc_textures/manifest.json).
THPS research remains reference material, with no imported franchise code/assets
or claim that these local tuning values are verified THPS3 constants.

The shadow diagnostic samples609 fixed floor points over60 moving frames per
variant.259 remain visible in the no-shadow control. Subtracting that control,
mean temporal luminance standard deviation changes0.024516→0.022635 (7.7% lower),
p95 changes0.065711→0.060695. This is an observed targeted-dolly improvement,
not proof of eliminating every shadow artifact. [Samples](shadows/samples.json),
[comparison](shadows/comparison.json), [original](shadows/original.png),
[13-tap](shadows/pcf13.png), [no-shadow diagnostic](shadows/off.png).
Owner visual acceptance remains open.

## Actual captured frames

All images are unmodified native PNGs, actual1152×720 from the project viewport;
requested window1280×720. [Final park](after/park.png),
[baseline park](before/park.png), [summit](after/summit.png),
[flush Clyde bowl](after/clyde.png), [opening shadows](after/opening.png).

Primary gameplay views use the production chase:
[charged ascent](motion/charged-015-chase.png),
[charged descent](motion/charged-031-chase.png),
[return](motion/charged-047-chase.png),
[flip/catch](motion/flip-097-chase.png).
[Side inspection](motion/charged-023-profile.png) and
[catch inspection](motion/flip-109-profile.png) use a separately labelled diagnostic
camera while simulation is frozen; they do not show the gameplay camera.
32 final motion PNGs were captured;10 representative originals and the full
[130-frame motion trace](motion/trace.json) are retained here. All32 remain in
.local/playtest-fixes-20261024/motion-final. [Source-bound native log](motion-final-run/console.log).

## Rendering cost and limits

[Exact comparisons](comparison.json) retain raw frame arrays, counters and motion
traces. Before is a source archive of ad0f95f, not a worktree;513 repository inputs
independently match that revision. [Audit](baseline-source-audit.json).
The archive receipt wrapper records the known revision without assuming a.git
folder; its exact changed recipe is retained. No game input differs in the
archive. Runs were sequential with no other diagnostic rendering/full-suite job.
External desktop contention is not certified.

Four views use identical camera paths and fixed60Hz initial scene ticks, then
freeze every processing node;360 measured frames each. They assert that the
review camera is not overwritten. Three actual Main workloads use identical
initial position/momentum, mapped input schedules and fixed60Hz;330 measured
frames each. Camera/trajectory differences in charged air are the intended
behavior, not matched-renderer performance proof for that segment.

| View | Before p50/p95/p99 ms | After p50/p95/p99 ms | >33.333ms before/after |
|---|---|---|---|
| Opening |9.633/16.724/22.144|9.991/16.721/21.449|0/0|
| Park |7.217/11.342/12.440|7.355/10.246/11.914|0/0|
| Summit |6.042/11.620/12.744|6.353/11.110/12.616|0/0|
| Clyde |6.564/11.921/12.108|7.307/11.933/12.232|0/0|
| Actual opening Push |8.087/9.996/10.238|8.224/10.013/10.964|0/0|
| Actual bowl carve |11.462/19.188/27.944|9.363/13.825/24.878|0/0|
| Actual charged bowl |8.861/13.725/24.372|8.643/11.652/18.803|0/0|

All seven limited frame gates pass: p95 increase<=max(2ms,15%), p99 increase<=3ms,
no additional >33.333ms frames. All four matched views have identical maximum
reported draws/primitives (1559/982507 opening,299/645416 park,310/644824 summit,
126/86704 Clyde). Texture bytes47623163 unchanged; video bytes74396803→74395991.
No added geometry beyond the1024-triangle/256KiB ceiling; existing topology is
retained. Camera caches mesh extrema once; support fitting adds four rays only
on supported transitions, with no per-frame mesh rebuild. These are frame-latency
samples, not an FPS guarantee, an uncontended target certification, an export
check or a physical DualSense test. Broader moving-map stutter stays a release gate.

## Retained negative evidence and fixture corrections

| Run | Result | Why rejected |
|---|---|---|
| full-01 |4488/61|First overlarge pelvis correction damaged grabs; removed. Source set gained the generated test.uid, so receipt also rejects source stability.|
| full-02 |4537/12|Remaining camera, pivot, landing and feature-air regressions.|
| full-03 |4540/9|Two toe camera jumps, landing snap and six pivots.|
| full-04 |4538/11|Nonrigid presentation basis produced interpolation errors; all retained.|
| full-05 |4548/1|Too-short feature camera clipped the hip rider; separate finite-feature arm fixes it.|
| focused-16 |69/2|Two explicit curved placements drew their old flat reset pose on the first sample.|
| focused-17 |19/0|One native acquisition and interpolation priming complete each declared placement; all subsequent checks remain live.|
| focused-18 |11/0|Summit, bowl intent and actual limb-core regressions.|
| full-06 |4555/0|Final production and test source, clean/frozen; admitted.|

Each retained full/focused directory contains its console, exact source manifests
and receipt. The original full baseline4521/20 is retained in the previous
[Clyde repair evidence](../clyde-sunken-bowl-2026-10-24/README.md).

The named-grind fixture expected procedural-board axle foot positions; it now
expects the actual GLB inboard stance while retaining real sole/deck assertions.
The overlap flip fixture requests a valid double upgrade; fresh sequential flips
use a separate single-flip flight and actual catch completion. Compact return
routes now steer around the existing cart end-turn and excavated bowl; physics,
score and capture assertions remain unchanged. Curved placement initialization
primes only one actual acquired contact before render sampling; it does not skip
any played route input or force later support/poses. The first failed rendered
placement is retained in focused-16. A new assertion proves acquisition before
priming; actual departure/contact sampling remains contiguous thereafter.

The first archive renderer completed but its receipt wrapper failed because the
archive has no.git folder; it is not an admission. An initial supposedly frozen
camera capture was overwritten by Skater's explicit pausable processing mode;
[incorrect park image](rejected-camera-capture/incorrect-park-view.png) and its
logs/metrics are rejected despite a clean tool receipt. Recursive freezing and
an actual-camera assertion repair the observer. A subsequent non-fixed initial
scene-tick comparison missed the opening p95 gate and differed by one draw;
[before](rejected-unmatched-static-before/metrics.json)/[after](rejected-unmatched-static-after/metrics.json)
are rejected. Corrected fixed-input captures are the four admitted rows above.
The earlier sand-coloured material trial and pre-final moving run are not final
visual admission; final grey concrete and all current source are captured.

## Commands and resumption

Set GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot.
Required: `python3 docs/testing/horizon-background/observers/run_checked.py .local/playtest-fixes-20261024/full-06 ./tools/check.sh`.
All native receipts contain exact argv; REPAIR_CAPTURE_OUTPUT supplies the output
folder. Native options: `--rendering-method gl_compatibility --windowed --resolution 1280x720 --fixed-fps 60 --audio-driver Dummy`.
Recipes are preserved as capture.gd.txt, moving.gd.txt, motion-capture.gd.txt,
focused.gd.txt and shadow-motion.gd.txt; restore to their recorded.local paths to
replay. Shadow-motion sets its own five filter variants. Baseline wrapper is
baseline-run-checked.py.txt; no production changes are required for replay.

All75 full backlog bodies/statuses are preserved. No spend, export, push, hosted
CI, new third-party asset, agent or background loop. Next is owner manual review
of knees/landings, both summit directions, tap/charged bowl return versus a fresh
transfer, ramp camera and opening shadows. Keep physical-controller/final art,
export and full stutter acceptance open. Do not resume unrelated work merely
because this automated checkpoint passes.
