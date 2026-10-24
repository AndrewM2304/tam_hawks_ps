# City Chambers east edge and opening shadow investigation —24 October2026

SURFACE-01 implemented; SHADOW-01 remains open. No production light, renderer,
filter, bias, shadow range or atlas setting changes in this checkpoint.
Baseline76e43f1; feature branch `fix/spawn-civic-surfaces-20261024`.

The owner identified the **right side facing Chambers**. Existing civic support
ended atx35 while the east frontage starts atx36. Extending the existing floor,
forecourt and graded bank by1m retains their heights, materials and body IDs.
The short east rear fence now reachesx36, preventing entry behind the unsupported
north edge. West boundaries and all other street mouths are unchanged.

`tests/civic_edge_tests.gd` independently checks27 native rays/height queries,
27 actual visible triangle samples, standing-capsule clearance and a native
rear-guard sweep. A mapped Push traversal then drives the real skater along the
setback into the guard for90 frames, with no airborne, fall or bail state.
The native east rear guard is independently bounded atx31…36,y5.8…9,
z−127.9…−127.7 with exactly3 convex panels.
Old source: **1 passed/3 failed**; repaired final: **5/0**, nonzero on failures.
The first old-source attempt had an invalid triangle-helper API and was stopped;
its log is retained and is not admitted evidence. Focused receipts are in
[civic-before-fixed](civic-before-fixed/receipt.json) and
[civic-final](civic-final/receipt.json).

Native AppleM5/Godot4.6.3/Compatibility captures, actual1152×720 viewport:
[before civic strip](before-civic-strip.png), [repaired strip](after-civic-strip.png),
[extended rear guard](after-rear-guard.png). The constrained space still shows
existing decorative frontage projections; this is collision/coverage repair,
not final-art acceptance. The before strip recipe was subsequently edited for
other views; its source hash/receipt remain, but that exact earlier recipe is
not retained. Final capture recipe and all current native source receipts are
retained. No screenshot has been reconstructed.

## Rendering cost

Declared budget in [task record](../../planning/SPAWN-CIVIC-REPAIRS-2026-10-24.md).
No new texture/material/body/draw surface; startup fence subdivision adds84
reported primitives in this view and one native panel shape. No per-frame work.
Same150-frame analytic camera workload,120 retained frame intervals, frozen
world; before baseline from shadow-final-variants, final ordinary source after.
The old source and final recipes share the same camera sequence, warm interval,
settings and rider placement. No concurrent render test.

| Native observation | Before | After |
| --- | ---: | ---: |
| p50 ms | 8.2885 | 8.2385 |
| p95 ms | 9.937 | 10.559 |
| p99 ms | 10.179 | 11.029 |
| Frames over33.333ms | 0/120 | 0/120 |
| Last-frame draws | 992 | 992 |
| Last-frame primitives | 782496 | 782580 |
| Texture bytes | 47623163 | 47623163 |
| Video bytes | 74395991 | 74396327 |

Recorded local gate passes (<20% tail increase, no added long frame, no texture
increase). These are limited native frame-latency observations, not a full
uncontended performance benchmark or closure of the broader stutter gate.
[Raw counters](final-counters.json), [comparison](performance-comparison.json),
[final native receipt](final-native/receipt.json).

## Opening shadows: still unresolved

The closer road towards Chambers matches the owner's screenshot:
[ordinary source](before-opening.png), [shadow-off diagnostic](opening-shadow-off-control.png),
[final ordinary source](after-opening.png). The dark asphalt remains when shadows
are off. No positive-area paving overlap was demonstrated there. Do not label
this a proven coplanar-ground bug, or claim the earlier13-tap change fixed it.

Bounded native controls tested2/4 splits, lower/zero/higher normal bias, depth/
atlas variants, terrain-only/detail shadow suppression, reverse culling,
pancake size, larger ranges and culling margins. All settings were diagnostic
only. No reliable repair passed admission: e.g. lower bias reduced one temporal
standard-deviation statistic but increased adjacent-frame variation and visibly
introduced fine self-shadow stripes. Larger range/margins added submission cost
without eliminating the reported symptom. Split variants did not establish an
acceptable fix. Do not interpret changing a runtime atlas option as proof that
the Compatibility backend honored it.

Each recipe samples221 fixed world points over60 camera positions;125 stay
inside the image in all shadow-off frames. Raw sample arrays (`samples.json.gz`)
and aggregate comparisons are retained under the matching `shadows*` folders.
Standard deviation mixes shadow-edge/fade movement with shimmer; it is not an
objective flicker or human-acceptance metric. Counter arrays are separate120-frame
interval runs without image readback. The initial pancake run is **rejected**:
source changed while it was running (civic edit), despite exit0 and clean log.
Its results do not support production acceptance. Other rejected runs remain
explicit in their receipts. Shadow root cause and owner visual acceptance remain
open; no invisible ground, disabled normal shadows or higher-cost workaround is
shipped to suggest completion.

Reference checked24October2026: Godot's official
[light/shadow guidance](https://docs.godotengine.org/en/latest/tutorials/3d/lights_and_shadows.html),
[DirectionalLight3D4.6 reference](https://docs.godotengine.org/en/4.6/classes/class_directionallight3d.html),
and [4.6 Compatibility shader](https://github.com/godotengine/godot/blob/4.6-stable/drivers/gles3/shaders/scene.glsl).
These explain available controls; they do not verify this project's root cause.
No third-party code/assets imported.

## Reproduction and next action

Set `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`. Restore recipe.txt
to its original `.local/spawn-civic-20261024/*.gd` path if needed; diagnostic scripts
are deliberately not production scripts. Prefix commands with:
`python3 docs/testing/horizon-background/observers/run_checked.py <receipt-dir>`.

- Required: `./tools/check.sh` (final receipt in `full-final/`).
- Focused: `./tools/run.sh --headless --fixed-fps 60 --script .local/spawn-civic-20261024/focused.gd`.
- Native final: `./tools/run.sh --rendering-method gl_compatibility --windowed --resolution 1280x720 --audio-driver Dummy --script .local/spawn-civic-20261024/final.gd`.

Next bug work is SHADOW-01: reproduce the owner's current ordinary-play shadow
pulse with the real chase/input sequence and isolate the large caster/receiver
interaction before changing more settings. Keep manual-test reserve and all
human/hardware/export/art gates open. Do not resume unrelated features/polish.

## Required-suite inventory migration

First full check: **4556 passed/4 failed**, exit1, clean import and frozen source;
retained/rejected in `full/`. All four labels share two old exact shape totals:
the east rear guard length4→5m needs3 graded panels instead of2. Native inventory
is557 bodies/1654 shapes, protected271/721; bench identities12/44 and all named
addition categories remain unchanged. Updated only those explicit expected
counts and labels. The new guard test independently verifies its actual three
convex panel envelope and capsule stop, rather than accepting arbitrary extra
collision. Production code did not change to hide a failing test.

Final required check: **4560 passed/0 failed**, exit0, clean import/log,518 frozen
inputs,233.137s. [Receipt](full-final/receipt.json); source manifest SHA256
`6eaeca38e749cc51a2ca75a6a54457bc63a48ef6bc5292867d2ebec9d4877a73`.
All production game/project hashes in the native capture still match this final
check; only the explicit regression fixtures changed afterwards. No engine run
was repeated for documentation-only updates. No shadow-fix completion claimed.
