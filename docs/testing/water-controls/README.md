# Water and directional controls

18 October 2026. [PLAY-01/04/05](../../planning/NEXT-PLAY-HARDENING.md), [ADR-020](../../architecture/decisions/ADR-020-classic-controls-and-water.md). Final source is pushed at **db2b28e263a5305fe0d8064a967ed645a3c3d3fa**. Native admission passes all four comparisons; required full regression replay is running. No new area, spending, hosted CI or paid dependency.

## Implemented controls

- D-pad and left stick drive movement and select directional tricks. Cross holds/releases Ollie; Square flips; Circle grabs; Triangle catches rails or holds lips.
- Up → neutral → Down enters a latched Manual; Down → neutral → Up enters a Nose Manual. Real releases between physics ticks count. Direct reversals, opposite simultaneous holds and stale/expired requests refuse entry.
- Left/Right balances manuals, rails and lips. Q/E or L1/R1 turns during manuals independently of balance. L2 remains an optional held-manual shortcut.
- Specials use right-stick up/down, once per fresh excursion; interaction uses L3. Keyboard fallback, atomic remapping and saved-profile warnings remain. Use Controls → Reset defaults to adopt defaults if old custom bindings were saved.
- Actual tree pause clears unfinished gesture history. Active manual motion, balance, identity and visible pose freeze exactly and resume without a second award.

The existing 220 ms gesture window, 120 ms eligibility buffer, 350 ms recovery, score/bank contracts and ordinary ground/air steering remain. [Manual capture](native-05/controls-manual.png) and [Controls help](native-05/controls-menu.png) show actual mapped controller input in Main, not a drawn mockup.

## Implemented water and cost

One original opaque shared material/display and the existing 18 triangles remain. Zero added textures, geometry, collision, lights, reflection/refraction/screen-copy passes or frame callbacks. Two affine wave phases are calculated at vertices and interpolated exactly. Fragment work uses two cosines, screen-space derivative attenuation and analytic world normals; constant blue-green colour, cheaper Lambert diffuse and broad native specular highlights avoid the rejected painted colour bands. Native fog/shadows, physical banks, hazard/recovery and production camera remain.

[Original comparison shader](observers/original_water.gdshader) is extracted byte-for-byte from pushed a6150d7; [baseline hash](observers/baseline.json) and final audit bind it. No external texture/asset/code licence is introduced. The final shader is [retained verbatim](observers/water-final.gdshader).

## Verification

| Run | Result | Disposition |
|---|---|---|
| focused-01 | 236/1 | Rejected: legacy exact-heading revert fixture |
| manual-debug-01 | 70/1 | Diagnostic preserving the failure |
| focused-02 | 237/0 | All 41 then-current controller checks; isolated revert fixture |
| focused-03 | 240/0 | Adds three actual pause checks: 44 controller assertions |
| combo-focused | 32/0 | Preserves the exact manual-bail and subsequent link/overtime assertions |
| ordinary-final | 2,182/1 | First required run, rejected; one stale Brake balance driver |
| ordinary-02 | Running | Required full replay on final pushed source |

These counts overlap; do not add them. Focused03 predates the final shader and the unrelated combo helper's one-input correction. Final full replay must cover the final source and all 44 controller checks together.

The first exact-heading assertion saw 1.862645e−8 rad after a preceding manual-bail trial started using horizontal input. The independent revert trial now uses normal reset/settle and its original 8 m/s setup; its exact assertion and production response are unchanged. The first full run's sole failure instead used Brake to force outward manual imbalance. Independent QE confirmed Right reproduces the original correction from positive entry balance. Only that input changed: 65 ticks, one-bail/previous-bank/no-combo assertion and later fixture reset remain intact. All failed logs are retained.

## Final native comparison

**native-05: 4/4 passes, 480 native intervals, 26 decoded 1280×800 PNGs, 34/0 world checks, 375 unchanged inputs, clean exit 0.** Four supported chase fixtures; original/candidate/original, 40 intervals per phase, native post-draw scheduling, at least 12 warm frames and settled real floor contact. Balanced Compatibility, llvmpipe, LP_NUM_THREADS=3, same 4-core quota, native 1280×800, no competing renderer. Readbacks and temporal/manual/menu demonstrations occur outside timings.

Each p95 **and** p99 must meet both unchanged caps: control midpoint + absolute repeat difference + 5% midpoint, and 1.05×worse original control. No failed view is waived or pooled into a passing average. Draws/primitives match both controls at every view, with zero buffer-byte delta. [Complete distributions, long-frame and memory counters](native-05/comparison.json), [receipt](native-05/receipt.json), [raw samples/contact/camera state](native-05/capture.json).

| View | Original A p95/p99 ms | Candidate p95/p99 ms | Original B p95/p99 ms | Gate |
|---|---|---|---|---|
| clyde-raised-deck | 521.01 / 527.10 | 519.36 / 551.30 | 520.74 / 530.64 | Pass |
| clyde-river-east | 220.37 / 224.24 | 212.18 / 217.33 | 227.95 / 240.80 | Pass |
| clyde-south-bank | 642.73 / 648.88 | 565.56 / 570.95 | 589.59 / 612.42 | Pass |
| clyde-river-west | 294.06 / 304.13 | 307.40 / 314.30 | 267.55 / 279.63 | Pass |

This admits the declared regression budget in these software-rendered views; it does not establish a universal FPS improvement. Raised-deck has only a small visible river region; [south bank](native-05/clyde-south-bank-candidate.png), [east](native-05/clyde-river-east-candidate.png), [west](native-05/clyde-river-west-candidate.png) and the diagnostic close/dolly provide the clear water views.

| Earlier native run | Timing | Disposition |
|---|---|---|
| 01: three phases/custom Fresnel | 3/4 | Rejected: west p99 |
| 02: two phases, no custom Fresnel | 2/4 | Rejected: raised deck/west p99; strong regular bands |
| 03: constant colour/Lambert | 4/4 | Limited: raised deck/corner face walls; superseded |
| 04: changed observer angles | 2/4 | Rejected: east/corner p99; corner still behind buildings |
| 05: vertex phases + actual south bank | 4/4 | Final admitted source and observers |

Complete timing/log/source receipts for these runs and exact material/observer versions are retained. All 26 final PNGs are committed. Earlier full PNG sets remain local under `.local/water-controls`; selected earlier appearance/coverage examples are committed. Do not mistake missing historical images for final evidence or reuse the obstructed views as four visible-water bearings.

## Actual image review and limits

Root inspected all four final candidate chase frames, static temporal 00/03, diagnostic moving-camera 07/11 and actual manual/menu. [00](native-05/water-motion-00.png) and [03](native-05/water-motion-03.png) show real advected ripple change with fixed camera. [07](native-05/water-motion-07.png) and [11](native-05/water-motion-11.png) show moving-camera water/bank/bridge relations. These are sparse native frames with actual capture times in capture.json, not a human tour or a native-FPS video. Soft ripples and stable bank contact are visible; regular crossing waves remain stylised, and continuous flicker is not certified.

Manual rider/board, balance metre, face-button footer and current controller help are readable. Physical DualSense comfort, Mac/M5 frame times, continuous shimmer, final realistic art, full-map horizon admission, ramp-response/grind-variant review and a broader human six-area play remain open. No new ramp physics or grind catalogue is claimed by this slice.

Reproduction observers are under [observers](observers/); their commands refer to the recorded ignored `.local` paths. Restore those paths explicitly when replaying. Serialise engines/renderers, preserve source freezes, rerun analysis with unchanged gates, and bind final ordinary/native inputs to the pushed source before acceptance. Full logs and final audit will be added after ordinary-02 completes.
