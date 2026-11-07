# Recessed architecture integration and admission — 7 November 2026

Owner: environment architect; FID-203. Independent verifier: QE, then BA.
**Prepared, not integrated or visually accepted.** Root holds the production art
pair until the gameplay checkpoint. No engine was invoked for this packet.
The [native component](fidelity-2026-11-06/architecture/native-author-component/README.md)
owns the earlier bounded +68,086-triangle result; it cannot admit actual Main.

The [V2 addendum](fidelity-2026-11-06/architecture/tangent-v2-ready/README.md)
is now the preferred pending-native candidate. It corrects the shaft/top-cap
column UV tangent handedness only; all V1 component and file-rehearsal evidence
retains its original source. Follow the V2 adapter commands below. No production
integration or native V2 run has occurred.

## Controlled source change

Only these production paths are in the candidate:

| Path under `game/levels/art/` | Change | Preserved contract |
| --- | --- | --- |
| `facade_kit.gd` | Real upper apertures; stone lintel/reveal/sloped sill; fine sash; profiled shop joinery, panelled doors and original merchandise | Existing decoration API, shared material keys/batches, native bodies, original shop names, west threshold lift |
| `facade_shell.gd` | New cached, one-surface finite shell with explicit aperture subtraction | Back/side/top/bottom closure; original collider/transform; world-scaled UVs and tangents |
| `exchange_gallery.gd` | Four-sided upper openings, door/entablature detail and one registered profiled-column batch | All eight native column positions, radii, support and roof datums; threshold helper; original closed roof |
| `gallery_column.gd` | New shared, closed 24-sided turned column mesh | Existing maximum base/shaft envelope and square abacuses; no collision |

The exact candidate hashes are in the component's `source-before.json` and its
four preserved `.gd.txt` files. The existing pair must still match their recorded
hashes and both new helper paths must be absent. A changed file blocks stale
installation. MaterialLibrary, CityArt, shaders, HorizonBackground, physics,
layout, collision and public batching remain outside this patch.

The controlled installer and forward/reverse patches are prepared under ignored
`.local/architectural-fidelity/`. A durable copy and its 13/0 rehearsal receipt
are in [integration-ready](fidelity-2026-11-06/architecture/integration-ready/).
Every target write is individually atomic and journalled; this is not a claim
that four filesystem replacements form a single transaction. Revert validates
every installed identity and every original backup before restoring any file.
A later contributor edit or corrupt backup blocks the whole revert. Only the
two exact new helper files installed by that journal can be removed. No Git,
editor/import cache, UID, Music, service or network mutation occurs.

The rehearsal installed/restored the exact pair in a private ignored fixture,
checked all four candidate hashes, injected a later edit and corrupt backup,
verified both refusals changed no source, and checked occupied helper refusal.
It also verified production without the explicit root-release flag is refused.
All four actual production paths remained unchanged. This tests file handling,
not engine compatibility, art quality, clearance or performance.

Independent QE separately cold-read the original installer and passed nine
private controls in [its own exact receipt](fidelity-2026-11-06/architecture/installer-independent-review.json).
The V2 adapter's four author checks remain a separate scope pending independent
review; neither file-handling result admits the art into Main.

After root releases source ownership, the sequence is:

```sh
python3 .local/architectural-fidelity/controlled_install_v2.py inspect
python3 .local/architectural-fidelity/controlled_install_v2.py prepare
# Under a newly coordinated engine lease, baseline first:
python3 .local/architectural-fidelity/run_main_probe.py original-01 inventory
# Under a graphical lease, before changing the pair:
python3 .local/architectural-fidelity/run_main_probe.py original-visual-01 visual
# Root/source release is required before this production write:
python3 .local/architectural-fidelity/controlled_install_v2.py install --production
```

The installer prints the exact journal path. Preserve it; use a fresh immutable
label for each engine run. Candidate and restored-control runs use the same
probe/settings and a new label. Revert is:

```sh
python3 .local/architectural-fidelity/controlled_install_v2.py revert --production --journal EXACT_JOURNAL_PATH
```

These are prepared commands, not commands already run in Main. `main_probe.gd`
is an **unparsed, unexecuted author harness** at this stage; the Python wrapper
passed syntax parsing only. Its first root-leased headless run must establish
native compatibility before any result is cited. It extends the existing natural
`frame_post_draw` observer, builds normal Main with no preview override and
disabled persistence/personal Music, and takes 40 native settled ticks. It then
freezes descendant simulation for static inspection; shader `TIME` still exists.
An 8-view visual cohort plus three separate camera/Canvas synchronization proofs
are proposed. Main inventory and visual modes are separate; neither measures
frame pacing. Root reconciles any newly generated helper UIDs after a real import.

## Exact regression boundaries

| Existing check | Expected impact and required verification |
| --- | --- |
| `facade_bay_tests.gd`, `run` occluder assertion | Historical ordinary/fitted totals 23/22 assumed visible BoxMesh walls. Real apertures intentionally remove solid-box candidates. Independently enumerate exact owner paths, mesh classes, opacity and shell identities in both complete worlds; do not replace 23/22 with an unverified guessed count. Keep a separate unchanged bare-Box pilot control proving fitted removal of that one original candidate. Viewport occlusion stays disabled. |
| `facade_bay_tests.gd`, `_check_shell` / `_check_shadows` / `_check_lods` | Enabled fitted pilot intentionally retains its own shell/closed shadow mass and native LOD path. Preserve full strip area, rear/side closure, original mesh identity, CPU registration and all distance/transform assertions. No changed expected area or shadow bound is justified by this patch. |
| `facade_bay_tests.gd`, `_check_front` | Old whole-leaf 1.05×2.55×0.17 paint boxes at local door X −9.59/−3.75/2.09 are replaced by constructed leaves. Independently verify selected −3.75 leaf parts exist in ordinary mode and are all absent in fitted mode; both neighbouring leaves retain original distinct elevations. Use actual stiles/rails/panel/glass/threshold identity, not a lower record-count requirement. Preserve nine omitted window groups, one omitted shop, complete transformed-bounds filtering and the single retained original shop label. |
| `facade_bay_tests.gd`, neighbour closure | Preserve the full AABB from (−2.5,0.2,5.98) of size (0.12,3.1,0.66), sealed once by the opaque adjacent shared paint. Obtain that paint from the new real neighbouring stile rather than the removed monolithic leaf. Do not weaken transparency, material identity or full-coverage checks. |
| `pt24_render_repairs_tests.gd` | Existing 9.6 m² street/wall wedge repair remains below all new upper apertures. Require unchanged assertions. |
| `city_visibility_tests.gd` | Keep the original bare-Box occluder proof. Add an independent actual cut-shell rejection witness where appropriate; it must never produce a giant solid occluder across a visible opening. |
| `horizon_background_tests.gd`, `city_backdrop_tests.gd` | Explicit `horizon_frontage` masses remain BoxMesh because HorizonBackground extends them later. All lower footings, visible/collider enclosure and skyline extension checks must pass unchanged. |
| `station_railway_tests.gd` / static glass checks | Main's replacement station retains original moving-train native `glass` and the existing static `facade_glass` split. No changed shader whitelist or relaxed material identity is justified. |
| `exchange_place_tests.gd` | All eight native column ray blockers, capsule terrace sweeps, door thresholds, bypass and camera/route clearance must pass unchanged. New profiled art must fit the existing support silhouette. |
| `pt24_gallery_entrance_run_tests.gd`, `full_level_density_tests.gd` | Gallery guide IDs, native bank/apron/stair support, route runout, bypass/camera envelope and combo behavior must pass unchanged. |
| `render_budget_tests.gd`, `static_batches_tests.gd` | New custom ArrayMesh must survive primitive sharing. Preserve authored CPU transforms, existing material/render state and registered profiled-column MultiMesh ownership. No relaxed shader admission or global culling threshold. |
| `world_routes_tests.gd` and full regression | Exact canonical route, rail/grind points, gaps, terrain patch/polygon records and every native collision shape/body/layer/world transform must agree original/candidate/restored-control. Main's normal default features stay enabled. |

Concrete new door witnesses in building-local coordinates: stiles are
0.10×2.55×0.12 at X=door±0.44, Y=1.62, Z=6.23; horizontal rails are
0.98×(0.11/0.12/0.14)×0.12 at Y=(0.40/1.26/2.82), Z=6.23; the bottom panel is
0.79×0.69×0.045 at Y=0.83, Z=6.21. The existing west helper adds exactly 0.205
to the −9.59 and −3.75 door groups; +2.09 remains unraised. The native author
component verifies actual wall collision identity but does not replace these
independent fitted-pilot assertions. The production owner does not self-award
changed expected counts in QE's tests.

Source-only enumeration predicts five retained closed BoxMesh owners in both
ordinary and fitted worlds: the three `EXCHANGE ARCADE` frontages at
(−24,0,48)/(0,0,48)/(24,0,48), the marked `CIVIC CHAMBERS` mass at (0,6,−134),
and the deliberately undecorated `MARKET REPAIR HALL` at (56,0.65,7.5). Standalone
World's original 23 registrations include the two old station facades that normal
Main removes; the candidate cuts 18 standalone/16 default-Main walls. This is a
source prediction for independent native owner/class/material authentication,
**not a measured 5/5 count or permission to replace the old assertion blindly**.

After independent expectation updates and production import, root runs
`./tools/check.sh` on the frozen combined source. An error-free focused fixture
alone does not supersede that required complete check.

## Native visual benchmark

Review full 1280×800 PNGs at native output size before enlarging diagnostic crops.
Match original/candidate/control resolution, renderer, light, exposure, AA,
camera, FOV, ordinary startup and input workload. Record the actual source and
rendered frame boundaries; every image must have its own RGBA8 hash. Preserve
failed images. Independent QA reproduces current camera/Canvas pixel proofs.

| View or traversal | Observable acceptance; fail if absent |
| --- | --- |
| Ordinary production chase after 40 settled ticks | The dominant west shop row shows finer construction and actual depth as a player sees it. Repeated thick white crosses/dark picture plates do not dominate. A destination or return remains readable with the HUD present. An improvement visible only in a close crop fails this primary criterion. |
| Matched Exchange shopfront, camera (−29,2,−2) toward (−35,2.2,1), FOV 68 | Door stiles/rails/panel/handle join coherently; shop paint, brass and glass have credible relative thickness; records/books/cafe/bakery have distinguishable silhouettes rather than identical blocks. Native texture scale remains credible. |
| Upper west oblique, (−29,4,−2) toward (−35,6,5.75), FOV 68 | Real opening exposes finite stone reveal and a pane approximately 207.5 mm behind the wall face. Lintel and sloped sill meet their reveals; no floating head, open seam, penetrating sash or back-facing face. Shadow/parallax survives an adjacent camera position. |
| West raised-door shoulder and an actual chase pass | Both raised leaf groups align to the existing threshold; the third is lower as authored. Profiles remain outside the skater/camera envelope and no object appears to catch a clear landing/runout. Door-only authored stills do not prove native movement. |
| Gallery approach, column/abacus join, front and side upper windows | Smooth finite column profile reads at ordinary approach; base/shaft/capital meet existing supports and abacus, with no faceted cap, crack or floating entablature. Side opening has real depth; all eight original column collision envelopes remain visible and credible. |
| Merchant return, bright and shaded observations | Return wall treatment connects to the street-facing building rather than ending as an isolated front plate. Painted/frame detail remains readable without excessive dark AO or coarse grain on shared book/record consumers. |
| Native moving shoulder/chase traversal in both directions | No pop, sparkle, clip, z-fight, horizon gap, unexpected prop collision or culling discontinuity. Camera/landing envelopes and linked-set-piece sightlines remain clear. Existing six-area review continues; this candidate does not complete station, civic, Barras, park or Clyde placeholder remediation. |

The prepared static observer contains the first seven camera placements, not the
full moving/bright/shaded acceptance cohort. Independent QA/level design owns
the actual normal-input route and visible/native enclosure verification. A static
author screenshot does not certify those clauses or final AAA realism.

## Cost admission

Freeze all unrelated code, materials, maps, lighting and import settings across
baseline/candidate/restored-control. Collect actual Main mesh/MultiMesh nodes,
unique resources, CPU-authored registrations, rendered visible/shadow draws,
primitives and native texture/buffer memory. Count all new cut shells and the
remaining exact visible BoxMesh occluder owners. The control must restore the
original measurements within separately declared sampling tolerances.

Provisional ceiling remains zero new texture bytes or shader/material resources,
no native collision/layout change, +80,000 **source mesh triangle instances**,
+16 final static batch nodes across the complete world, +16 draws per matched
representative view, and +4 MiB actual additional geometry/instance allocation.
The component's −8 nodes and serialized-byte estimates are not substitutes for
these wholeworld/API measurements. Do not count hypothetical cylinder savings.

Frame-time admission requires a separate uncontended representative moving
workload with p50/p95/p99, long frames, per-cell draws/primitives/memory, exact
source and restored-control sampling. Fixed-60-Hz capture/readback times measure
neither normal FPS nor pacing. Linux software rendering cannot pass MacBook Air
M5 sustained thermal/memory/performance acceptance. Keep a failed or unmeasured
gate open and improve the implementation; do not raise a ceiling after failure.

Before that first timing run, the provisional relative diagnostic limits are
declared as follows: candidate p50 and p95 may increase at most 5%, p99 at most
10%, compared with the interpolated original/restored-control bracket. Original
and restored-control p50/p95 must agree within 5% and p99 within 10%; a larger
control drift makes that cell inconclusive. Record both >100 ms frames and frames
above twice the control median, normalized per 1,000 rendered samples; candidate
rates must not exceed the worse control. Use three independent matched A/B/A
repetitions, exclude capture/readback/compilation and compare each representative
Exchange approach, gallery and exposed frontage cell separately. A passing mean
cannot cancel a failed tail/cell or unstable control. Root sets the practical
bounded lease/workload before launch; insufficient samples, timeout or contention
cannot pass this gate. These relative Linux checks do not replace H1's separate
target-Mac p95≤16.7 ms, p99≤22 ms and no steady-play stall above 100 ms.
