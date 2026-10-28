# Native turn/wall presentation capture preparation

Static preparation only. Root must grant the sole engine lease after focused
repairs are frozen. No parser, renderer or game has run for this harness.

Reuses the existing weighted-Ollie capture's bounded private-Xorg runner,
completed-draw nine-node pose witness, actual Skin garment sampling, fixed
diagnostic view and immutable-controller comparison. The runner is a local
copy adjusted to 960×640, a 90-second child bound and explicit baseline/source
arguments so the outer observer binds every ignored dependency.

`baseline_skater.gd` is an exact, unedited `git show
21b0e86:game/player/skater.gd` copy; BASELINE.json records its full commit/hash.
It has no class_name. Both epochs share the current rig, meshes, assets and
all other dependencies. A new wall-presentation helper is not called by the
old controller. This comparison therefore isolates the changed controller
integration while keeping actual physical wall movement identical.

Eight original PNGs:

- Before/after first caught wallride frame, with the wall on each rider side.
- Current early ordinary release on the left-side-wall fixture and early
  Wallie on the right-side-wall fixture.
- Current left/right steering-Ollie landing after eight real rollout ticks.

The mirrored wall fixture matches `wall_ride_presentation_tests`: a real
0.4×24×40m wall centered at (0,8,0), floor, one declared initial-air placement
at (side×0.90,8,8), and initial motion (−side×1.2,0,−8). Eight frozen-physics
frames prime the ordinary camera, then held Grind earns actual native support.
Both epochs use the same far-reach early-exit controls: ordinary release at
zero-based control tick5, or Ollie held from tick1 and released at5. There is no direct assignment to wall-active
state or later physical pose/velocity. All 46 samples are retained and native
position/velocity must match between controller epochs within10µm. Continuous
rows also retain both actual world pose angles and local root-offset changes,
so an early reset cannot conceal a translation snap behind a smooth roll.
Rotation uses the independent relative-matrix `atan2(sine,cosine)` formula on
the previous/current orthonormalized visual bases, retaining exact basis JSON
witnesses and the raw `Quaternion.angle_to` value beside it. This avoids using
an ill-conditioned small-angle acos result as the sole angle measurement;
it does not raise the 4.5rad/s presentation limit or discard rejected epochs.
The capture records both metrics; focused wall controls own rate admission.

Turn fixtures use ordinary Skater/floor placement at (0,0.8,12), 45 settle ticks,
30 Push ticks, 24 held Ollie ticks, release and one tick, then20 steering ticks
at the exact quarter-turn analog strength. Flight, prelanding and rollout
transforms/real Skin seam metrics remain in the continuous JSON. No other
pose/velocity/trick state is assigned. Current landings must be clean, attached
and travelling toward the corresponding world ±X direction.

Capture freezes only completed native samples, resets interpolation and waits
for two completed draws. Nine actual/interpolated node transforms must agree;
the complete rider must fit the diagnostic camera. Ordinary chase frustum,
occlusion and camera-sphere results are recorded independently using the
existing strict helper, with the observation phase stated explicitly. These
are fixed-60 presentation diagnostics, not normal-play motion/FPS, Mac, whole
Main or human-feel acceptance. No Main or personal profile is constructed.

Fresh parser, only after root grants engine:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py \
  .local/turn-wall-capture-2026-10-28/parser-01 \
  timeout 30s ./tools/run.sh --headless --check-only \
  --script .local/turn-wall-capture-2026-10-28/capture.gd -- \
  .local/turn-wall-capture-2026-10-28/baseline_skater.gd \
  .local/turn-wall-capture-2026-10-28/run_rendered.py \
  .local/turn-wall-capture-2026-10-28/BASELINE.json
```

After a clean parser, fresh native run:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py \
  .local/turn-wall-capture-2026-10-28/native-01 \
  timeout 105s python3 .local/turn-wall-capture-2026-10-28/run_rendered.py \
  --seconds 90 --script .local/turn-wall-capture-2026-10-28/capture.gd \
  --output "$PWD/.local/turn-wall-capture-2026-10-28/frames-01" \
  --baseline .local/turn-wall-capture-2026-10-28/baseline_skater.gd \
  --sources .local/turn-wall-capture-2026-10-28/BASELINE.json
```

All outputs must be fresh. Preserve the first rejection and exact source before
any harness correction. Do not loosen existing pose/contact tolerances. Inspect
all eight originals before recording visual conclusions.
