# Independent fidelity, motion and line review

Reviewer: `/root/independent_qa` (technical QE and BA). Programme opened 6 November 2026. **Overall acceptance: Fail / incomplete.** A source-stable baseline is complete; the combined candidate is still changing. No AAA, owner, physical-controller or MacBook Air M5 pass is awarded.

## Source and evidence boundary

The initial checkout was the October 17 alpha. The integrator reconciled it with actual main `0b620358767c9c647dde66945377d99702c85d0b`. Old screenshots, attempted probes and map diagnoses are historical; they do not describe this baseline. The initially proposed `fidelity_capture` replacement was withdrawn and is not a supported recipe.

The [baseline packet](fidelity-2026-11-06/baseline/README.md) contains 17 original 1280×800 PNGs, exact observer/runner text, actual executed-source inventories, native pixel hashes, independent decoded-pixel checks and an engine log. It rendered an isolated `git archive` copy of current main so specialist edits could not contaminate it. Result: **61 checks,0 failures,engine exit 0,no changed inputs**. Independently decoded RGBA8 hashes match all 17 native buffers. This passes capture integrity, not visual quality.

The narrow observer extends `tools/full_fidelity_capture.gd`, retaining its natural `frame_post_draw` fence and projected 3D-marker/current-Canvas proof. Manual `force_draw` can return the previous camera's pixels and is not equivalent. Godot 4.6.3, Compatibility/OpenGL, Mesa 25.0.7 llvmpipe LLVM 19.1.7, Linux, private Xorg, fixed 60 Hz and dummy audio were used. The 40-tick ordinary spawn has no pose/camera assignment; overviews and 3.3 m rider/environment inspections are authored cameras, with movement frozen during inspections. Normal Main keeps station/train and pond enabled; persistence and personal Music control are disabled and checked. Static/fixedfps diagnostics establish neither real-time performance nor input-driven line completion.

The [independent renderer comparison](fidelity-2026-11-06/renderers/README.md)
retains all 17 Compatibility and 17 Forward+ original native frames from the same
781-input copy. All PNG/native hashes, six Canvas swatches, eight projected
head/board markers and 17 matched view records independently agree. Both backends
render cleanly; the unchanged scene still shows angular garment/hip forms,
repeated paving and flat-looking window panels. The room shader is already bound;
the finding concerns its visible result. Later garment, bank and glass-ownership
changes are outside that copy. No current visual result demonstrates a need for
an engine/default-renderer switch. Software/JIT and permitted CPU diagnostic
overlap exclude comparative performance claims; Metal and M5 remain unmeasured.

The [independent surface-allocation audit](fidelity-2026-11-06/environment-allocation-independent.json)
passes its completed native subset: 787 unchanged inputs; 15 live compressed maps;
actual resident increase 32,768,403 bytes (31.250384 MiB), within the declared
32 MiB budget by 786,029 bytes; unchanged eight draws/96 primitives. Exact native
payload arithmetic agrees. All 43 preserved originals and hashes validate. The
full water workload was intentionally interrupted and remains rejected (exit
−15, zero timing cells). Six 2K/1K normal originals show no conspicuous static loss
in three inspected views, and Clyde water banding visibly improves, but the
interrupted process did not flush per-frame native hashes/cameras. Those images
cannot receive final natural-pixel/moving/cost acceptance from a reconstructed
receipt. This allocation pass is neither whole-game memory nor Mac performance.

The later [isolated water epoch](fidelity-2026-11-06/environment/isolated-water-01/independent-review.json)
has independently verified capture integrity: 784 unchanged inputs, six native
PNG/RGBA matches and all nine cells' raw-duration, sample and percentile/resource
arithmetic. Cost is **not admitted**: high-coverage candidate p50/p95/p99 exceeds
both controls; other views have substantial control drift. All six originals were
opened. Broader bands soften, but glint and fine stipple/striation remain. This
640×400 plane/daylight diagnostic establishes neither full-world timing nor
temporal/M5 acceptance.

The [native line development packet](line-design-2026-11-06/focused-native-2026-11-07/README.md)
has a source-scoped 326/0 author checkpoint. Independent reading confirms named
seat captures and an actual manual-to-second-catch interval of 159 native frames
(2.65 s), plus a 570-frame (9.50 s) safe return without a trick. That long return
is transport and does not satisfy a meaningful closed trick circuit. Post-run
hashes and team-held source are disclosed; final immutable visual acceptance is
still absent. D012 now passes its narrower native containment/contact retest.
Current coping penetration D014 and the independently rendered crown snap D015
remain blockers; a successful no-jump return cannot close them.

The [current bank motion packet](fidelity-2026-11-06/bank-crown-motion-01/README.md)
retains 45 exact full world PNGs, a 32-frame clip at 60 fps and two stable copied
source inventories. Separate side and chase captures pass 492/0 and 314/0 for
capture integrity. The side sequence exposes a visible 28.627-pixel rider/deck
step around the required 119.816 mm correction: D015 remains a visual failure.
The [independently parsed coping witness](fidelity-2026-11-06/clyde-coping-contact-01/README.md)
records a separate 35.716 mm tyre penetration, D014. The complete combined suite
and current technical/visual checkpoint are not accepted.
The completed [required-01 integration gate](fidelity-2026-11-06/integrated-required-01-rejected/independent-review.json)
reports 6,311 passing assertions and 25 failures, exit 1, with 800 unchanged source
inputs. All failure lines and preservation hashes independently match. The later
CLI Music stage did not run. This is a rejected checkpoint, not a combined pass.

## Direct findings and defects

All six district overviews, sunken-park overview, ordinary spawn, three rider angles, three environment close views and synchronization frames were opened directly. Existing recognisable rooflines, window surrounds, station canopy, market hub and bowl facility are useful foundations; their presence does not meet the higher finish requirement.

| ID / priority | Reproduction and actual finding | Expected / affected requirement | Owner / state / exact retest |
| --- | --- | --- | --- |
| FID-D001 / P1 | Clean-main [front](fidelity-2026-11-06/baseline/rider-front.png), [side](fidelity-2026-11-06/baseline/rider-side.png) and [rear](fidelity-2026-11-06/baseline/rider-rear.png): pointed shoulder/sleeve caps, rectangular shirt/hip silhouette, simple face/hair/cloth forms. | V1 continuous believable anatomy/surfaces; FID-101/102. Materials alone cannot close silhouette defects. | Rider artist; candidate in progress. Matched views, ordinary chase, actual deformed joints and worst-bend moving frames. |
| FID-D002 / P1 | [Ordinary spawn](fidelity-2026-11-06/baseline/ordinary-spawn.png), Exchange/George/Central/Barras overviews and [shopfront](fidelity-2026-11-06/baseline/exchange-shopfront.png): conspicuous repeated paving/masonry, flat shop glazing/interiors and uniform bright window rectangles. | V2 physical material scale/architecture; FID-201/202. Preserve readable landings/collision. | Environment artist; candidate in progress. Matched close/chase views, moving bright/shaded detail and resource admission. |
| FID-D003 / P1 | [East quay](fidelity-2026-11-06/baseline/clyde-east-quay.png): large repeated paved corridor, sparse small props, weak next-feature staging. Archived route runs x−78…+78,z69. Bridge x20→arrival x78 spans 58 m, 7.25 s at 8 m/s reference; bench x70,z59 is off centreline. This is geometric reference, not actual traversal or a claim the entire quay is featureless. | L1 density/enclosure/discoverability; FID-402/403. Retain safe transport bypass beside useful demonstrated trick choices. | Level designer; existing-resource recompose in progress. Real-input bridge→choice→arrival/return both ways, clear bypass and misses. |
| FID-D004 / P2 | [Clyde overview](fidelity-2026-11-06/baseline/overview_clyde.png): river reads as broad regular colour bands; fountain/river stills show little natural variation. | V2 water response; FID-201/203. Stills cannot decide temporal shimmer. | Environment artist. Matched still plus normal-speed shore/water review; preserve hazards/recovery. |
| FID-D005 / P1 | Original-source manual balance receives lateral `_steering`; HUD uses horizontal marker/Left–Right prompts for all modes. Candidate [85/0 actual-world checks](fidelity-2026-11-06/controls-sign-01/README.md) now verify genuine W/S pitch correction and separate A/D steering across ten ordinary/nose/fakie/style variants. | New owner requirement/FID-304: actual manual fore/aft controls and nose/tail meter agree with stance; rail balance stays lateral. Relabelling alone does not satisfy it. | Combo engineer. Physical-axis subset passes on the exact copied epoch; final HUD/remap/lateral-mode/moving review remains open. |
| FID-D006 / P1 | Independent [real-input landing matrix](fidelity-2026-11-06/manual-baseline/README.md): request held 100 ms before actual floor enters a manual, but requests held 200/300/450 ms before expire and the earned 800-point ollie/flip combo banks. A request 400 ms after contact starts a new manual after the old combo has banked. | FID-304 admitted prelanding timing must be deliberately tuned/documented for reliable links. This reproduces the reported difficulty; it is not a score-ordering failure. | Combo engineer. Independent [checkpoint47/0, fifteen cases](fidelity-2026-11-06/controls-landing-01/README.md) verifies actual100–333ms early links, exclusive350ms expiry, release/stale rejection and single original bank. Timing subset passes; full interruption/threshold/linked-run and HUD gates remain open. |
| FID-D007 / P1 | Independent original-source [native push diagnostic](fidelity-2026-11-06/push-baseline/README.md): planted rear sole slides 2.004 m during ten loaded regular samples, peak 212.53 mm/tick; fakie is equivalent; from-rest peak is 161.16 mm/tick. | V3 credible loaded contact/FID-301/303; target under 5 mm/tick on stationary support. | Motion engineer. Source-stable [checkpoint66/1](fidelity-2026-11-06/motion-checkpoint-01-rejected/README.md) passes regular/fakie/rest sole peaks2.892/4.017/0.162mm and incline cases, but the aggregate fails graded-wall clearance. Native push subset improves; normal-speed plant/return remains open. |
| FID-D008 / P1 | Same native baseline: torso/front-shoe forward dot actual travel is 0.301/0.066 in regular and −0.397/−0.070 in fakie; motion is strongly side-on despite head looking ahead. | Explicit forward-facing natural push/FID-303. Foot slip alone cannot satisfy whole-body stance. | Motion/rider. Same source-stable checkpoint passes actual torso/hips/lead-shoe signed orientation; front/side/chase normal-speed cycle and worst transition still required. |
| FID-D009 / P1 | LD's [rejected native presentation](line-design-2026-11-06/rejected-native-presentation/README.md) catches both intended long seat bearings, enters Manual, lands on native paving and banks 6,496 once with zero bails. During second release a real visible extremity is at Y2.485132 while the actual seat top is Y2.49; the strict chase ray hits the seat. QA inspected the exact failed log/driver, not a final immutable positive run. | V1/V3 supported model and takeoff must clear actual finite seat geometry; FID-102/301/403. Correct physical capsule or earned score cannot excuse a penetrating board/rider. | Motion engineer. Keep guide identity, whole-model/two-truck checks and strict camera guard; reproduce support→Ollie on the finite rotated seat, then rerun continuous relay and inspect native frames. Post-run source inventory is diagnostic only. |
| FID-D010 / P1 | Same packet's fast bank case reaches 11.7714 m/s, remains natively contained and rolls back, but a visible marker reaches X84.72358 past the actual wall plane X84.7 (23.58 mm). Strict camera/model review fails; bank result is 12/1. Slower successful entries cannot close this failure. QA inspected the actual failed log/driver. | V1/V3/L1 model must remain clear at legitimate full-speed bank/backing contact; FID-102/301/403/404. Native slope support and capsule containment remain authoritative. | Motion engineer. Immutable [full motion checkpoint](fidelity-2026-11-06/motion-checkpoint-01-rejected/README.md) still fails connected-board clearance at the fast bank, despite correct57-frame native rollback and14.105–14.113mm wheel gaps. Diagnose exact component and retest all speed/seam/miss/return neighbours; no weaker bound. |
| FID-D011 / P1 | [Native meter investigation](fidelity-2026-11-06/manual-meter-01-rejected/README.md): at 1280×800/UI1.4 the central panel intersects the upper rendered head; its centre-only overlap flag misses this. At both scales the large panel masks the next approach and the actual multiline correction label renders only `MANUAL...`. Six original native buffers and three Canvas proofs independently match; the whole packet remains rejected for an unrelated inherited snapshot error. | FID-304 C/E: legible effective correction, rider/landing visibility and supported UI scales. Viewport containment alone is insufficient. | Root HUD correction independently [passes34/0 native retest](fidelity-2026-11-06/manual-meter-02/README.md): full glyphs, actual head/board bounds and centre approach clear at1.0/1.4; release clears panel. Static D011 subset passes on declared overlay. Full moving/risk/remap/other-resolution and integrated scope remains open. |
| FID-D012 / P1 | Independent reading of [four native charged-bank inputs](line-design-2026-11-06/rejected-top-escape/README.md) confirms two naturally accelerated 15m/s Ollies cross the upper quay boundary at X85.24483/Y5.58666 and X85.26863/Y5.51718 with no native support, travelling beyond X100 before a bail. A third contained case has actual board-marker/camera obstruction. Post-run source hashes are diagnostic, not immutable acceptance. | FID-403/404 and V3/L1: legitimate maximum-speed inputs must remain within coherent visible/native enclosure and recover with clear model/camera support. Successful slower no-jump returns are insufficient. | Level/motion engineers. Same visible/native backing now reaches Y7; independent [current-order158/0 source/log review](line-design-2026-11-06/current-order-native-2026-11-07/independent-review.json) passes bounded native containment, actual landing, strict capsule/model/shoe/camera and loaded-floor negatives for all four inputs. Native D012 subset passes; ensuing119.816mm visible correction is separately FID-D015. Whole visual/full-game acceptance remains open. |
| FID-D013 / P1 | Independent [nine-cell water cost audit](fidelity-2026-11-06/environment/isolated-water-01/independent-review.json): at 640×400 high coverage, the three-wave candidate p50/p95/p99 is 66.751/102.100/115.008ms, above both controls (58.608/88.097/95.056 and 46.096/70.167/87.129ms). Six PNG/native buffers, 784 inputs and raw percentile/resource arithmetic independently match. Control drift prevents strong causal attribution; it does not produce an admission pass. | FID-202 E/Q1.7: added surface cost needs measured admission; equal draws/triangles/texture memory cannot substitute for frame cost. This is an isolated Linux failure to admit, not measured M5 performance. | Root/environment rendering. Keep the rejected three-wave epoch intact; evaluate the prepared cheaper two-wave candidate in a new warmed, repeated matched control/candidate/control epoch with raw percentiles, long frames and process conditions. Preserve visible still/temporal review; no new allocation or world-geometry workaround. |
| FID-D014 / P1 | [Full-suite first-contact witness](fidelity-2026-11-06/clyde-coping-contact-01/README.md): actual grounded tyre penetrates finite NativeBowlSteelCoping35.716mm. The later [original live Main retest](motion-fidelity-2026-11-07/coping-main-current/independent-review.json) still fails5/1 with790 source bytes stable: at X−10.601124, tyre penetration57.866mm and mesh penetration32.562mm while other tyres choose actual ClydePrintYardGround. | FID-301/403/404,V1/V3/L1: actual finite tyre/deck/mesh and chase must clear throughout affected crossing/coast/return. | Motion engineer. [Isolated49/0 helper/source review](motion-fidelity-2026-11-07/coping-footprint-development/independent-cold-read.json) is insufficient for the real mixed-ground route. Derive bowl authority from fresh actual tyre support, preserve remaining finite faces and whole-model proof, then rerun original crossing/coast/return, neighbours and final integrated gate. D014 remains open; required-01 and live retest remain rejected. |
| FID-D015 / P1 | [Immutable fullworld motion](fidelity-2026-11-06/bank-crown-motion-01/README.md) clean492/0 side and314/0 chase:32consecutive native side frames expose an abrupt connected rider/deck pop; darkblue shirt centroid shifts28.627px in side010→011. Required native offset changes119.816mm in one physics step. Actual uncorrected board triangles intrude111.820mm, so reducing clearance is invalid. | FID-301/302/403,V3: finite contact correction must preserve credible continuous motion and rendered attachment, beyond a no-overlap count. | Motion engineer. The [corrected192-call private native audit](motion-fidelity-2026-11-07/air-anticipation-192-native/independent-review.json) passes40/0: all1408 physical rows equal reactive and41 per-invocation incremental bounds have p50/p95/p99/max66/152/152/152. Maximum offset step is27.198mm. The [independent full-prefix moving packet](motion-fidelity-2026-11-07/air-anticipation-moving-02/README.md) now preserves32 consecutive side/three chase frames: all35 inspected, recorded crown snap absent, no obvious new deck/wall penetration. All1408 physical rows match reactive; integration is recommended for a fresh combined regression. All66 positive/rejected native buffers are preserved exactly; no elapsed-cost/whole-game/AAA closure. D012 native enclosure pass remains separate. |
| FID-D016 / P2 | [Independent actual native skinning witness](fidelity-2026-11-06/skinning-operation-order-01/README.md),48/0: decoded native weights sum0.9999847114. Inherited production/helper-test world-per-influence formula scales model translation, disagreeing with the official local-skin-then-model equation by1.712mm at modelZ112m. Actual nonidentity GPU Skin gives encoded red153 at meshZ0/100/1000; detached-Skin gives128, while the inherited formula predicts114/0 far away. | FID-301/V1/V3: finite deformed cloth/arm bounds must describe the actual native indexed Skin, including valid quantized weights and real model frame. An inherited CPU oracle cannot validate its own numerical error. | Contact/rigging engineer. The [corrected private120/0 subset](fidelity-2026-11-06/deformed-contact-epoch05-review/independent-review.json) independently passes source/log review with674 stable inputs and63376B cache, preserving query/wrist/contact limits. The [exact actual promotion and witness diff](deformed-contact-2026-11-07/independent-promotion-witness-review.json) now pass independent cold-read; the [clean actual-source two-module execution](deformed-contact-2026-11-07/current-02/independent-review.json) independently passes10/0 over native139/0 and797 stable inputs. Fitted-rider/moving and full-source regression remain required. No rendered rider defect or final admission is inferred from this numerical witness. |
| FID-D017 / P1 | Independent [actual-input torso-axis A/B](manual-body-axis-2026-11-07/README.md): old visual source passes100 and fails4 of104 checks. In Pogo and Hang Ten, W leans the connected torso away from real travel and S leans toward it despite correct board/meter direction. | FID-304/V3: actual fore/aft body response must agree with travel in torso-turned styles; local Euler-axis names are insufficient. | Rendering/motion integrator. Exact one-file deck-space correction passes104/0 with999 unchanged source/import-cache inputs; all original84 board/control checks stay passing. Root has applied the independently matched hunk to actual source. Narrow sign regression passes; final integrated gate, natural moving pose and fitted-body/contact remain open. |
| FID-D018 / P2 | Independent [actual native Skin bind witness](fidelity-2026-11-06/native-bind-precedence-01/README.md),18/0 plus15/0 receipt/pixel audit: a Skin with valid index0 and nonempty name selecting bone1 selects bone1 in the actual native palette and pixels, while the inherited bounds helper selects0. | FID-301/V1/V3: deformed bounds must follow actual native Skin binding authority. This is a demonstrated mixed-binding edge case, not an asserted current canonical rendered defect. | Contact/rigging engineer. Held name-first resolver77f2 matches allthree native palette/pixel cases and rejects missing names/invalid indices/bind bounds. Narrow correction recommended; actual integration/fitted/full regression remain required. |

Close rider frames appear weakly grounded. Independent native measurement now finds actual retained GLB wheel minima exactly 8 mm above native flat support in all 48 samples per case, within the existing contact bounds; supporting sole error is 0.854 mm. This is not a proven wheel-support violation. Stronger contact lighting still needs rendered review. Native baseline also passes brake dragging support (0.931 mm maximum), release and six-/18-tick push-to-pop interruptions. Normal-speed candidate appearance remains separate.

The later [two-wave, 48-warm-frame water diagnostic](fidelity-2026-11-06/environment/two-wave-48warm-01/README.md)
passes independent source/pixel/measurement integrity only: 786 stable copied inputs,
exact two overlays, six originals and all 189 percentile/resource values match.
Controls still drift and the candidate does not consistently meet both brackets;
cost is not admitted. An unclassified one-sample identical-command second PID is
disclosed, with no process-exclusive claim. Broad waves soften but fine specular
striation remains. D013 and the original three-wave rejection remain open.

The subsequent [static normal/material controls](fidelity-2026-11-06/environment/visual-controls-02/README.md)
pass an independent 88/0 source/pixel audit: 791 unchanged private inputs, nine
native originals, 18 projected 3D markers and nine Canvas samples. Fine bands
remain in both a constant-world-normal shader and native Lambert material; their
three clear-water regions agree within one RGB8 level. The wave-gradient normal
is not necessary for that residual artifact; its precise cause remains unknown.
The rejected cyan-marker epoch is preserved. This deliberately concurrent,
isolated static diagnostic has no timing or moving-water acceptance.
The [Godot 4.6.3 GLES counter correction](fidelity-2026-11-06/environment/shadow-counter-interpretation-addendum.json)
retracts the earlier inference that zero reported shadow draws weakens a caster
explanation: this implementation attributes shadow draw calls to the visible
category while counting shadow primitives separately. Original reports and
measurements remain unchanged.

The later [direct caster controls](fidelity-2026-11-06/environment/shadow-caster-controls-01/independent-review.json)
pass108/0 independent checks across793 unchanged inputs and nine originals.
Disabling only water shadow casting visibly removes the fine bands in high and
grazing views while retaining the bright reflection. Actual shadow primitives
change2→0; matched cameras, per-image lighting flags and allocation verify the
intervention. This supports a water self-shadow explanation in the isolated native
material fixture. The production wave shader, full Main, temporal appearance and
cost remain separate admission work; D013 is not closed by these static controls.

The [private fitted-rider V8 review](rider-fit-2026-11-07/independent-v8/README.md) independently verifies 33 instrumentation checks without failures, including six exact native clean/proof hashes and nine recomputed camera-marker projections. All three current originals were opened; skin triangles still protrude through the lower collar, so the garment remains rejected. Unlisted stale output images are excluded. Single counter samples, internally asserted pose parity and absent source-after records limit the evidence; this is no Main or moving-rider pass.

The later [V9 fourteen-view private epoch](rider-fit-2026-11-07/independent-v9-fourteen/README.md) independently passes 175 capture-integrity checks and a separate 27-check raw-GLB delta audit. All fourteen originals were opened. The earlier lower-collar islands are absent; neck/waist appear connected in those static views. A conspicuous faceted grabbed-knee silhouette, soft footwear, hairline aliasing and26 internal folded-lapel crossing pairs remain open. Authored states are not actual Main or motion/contact acceptance. Fresh source-after/readback brackets are present; earlier incomplete epochs retain their limits.

An independent [coping design-source review](line-design-2026-11-06/coping-proportion-source-review-2026-11-07/README.md) verifies the existing90mmOD/70mm deck/45mm face projections and the private60mmOD/12mm deck/10mm face proposal against the exact constructor arithmetic and directly inspected construction sources. Visible/native geometry and grind/lip crown paths change together. This is an independently justified physical-design candidate; actual native routes/contact/render cost and original D014 still require fresh acceptance.

The later [researched-profile component audit](line-design-2026-11-06/coping-proportion-private-development-2026-11-07/independent-review.json) passes25 read-only checks over the source-bound native24/0 component result. Actual Quarter/Bowl/Sunken steel,60mm section,12mm-up/10mm-inward reveal, guide crowns and retained old70mm negative agree. The separate [original Main return audit](motion-fidelity-2026-11-07/coping-researched-profile-main/independent-review.json) passes23 source/log checks over native6/0 with the controller unchanged. These are private geometry candidates and distinct scopes. The [shared-family audit](line-design-2026-11-06/coping-proportion-private-development-2026-11-07/profile-family-01/independent-review.json) independently passes17/0 over unchanged native98/0. The [actual seven-frame physics audit](motion-fidelity-2026-11-07/coping-researched-profile-physics/independent-review.json) passes91/0: cached board-component/four-tyre volumes clear at zero extra margin and503 recorded trajectory rows match the same-profile Main replay. Signed4–30mm native face proximity is not physical loading; two steep steel normals yield37.608/107.194mm vertical separation. Missing rays remain unknown. Whole-source routes, moving support/flotation, visible profile and actual promotion remain separately required; old D014 failures stay retained.

The private [finite forecast audit](motion-fidelity-2026-11-07/air-anticipation-finite-native/independent-review.json) passes24 read-only checks: all1,408 actual physics rows exactly equal the retained reactive trajectory, and independently recomputed maximum offset step falls119.816→27.198mm. Endpoint/control proof remains source-bound. Query attribution is explicitly rejected because a synchronous fault cleared an aliased receipt; a new observer epoch is required. No query-count cost, rendered anticipation or D015 closure follows.

A fresh [corrected192 forecast audit](motion-fidelity-2026-11-07/air-anticipation-192-native/independent-review.json) passes40 independent checks. The held controller and duplicate-capture observer are exact; direct raw invocation records repair the former alias attribution, all41 incremental query bounds stay under192, and every1408 physical row still equals the reactive trace. The largest offset increment is27.198mm. The separate [full-prefix native moving review](motion-fidelity-2026-11-07/air-anticipation-moving-02/README.md) is complete:32 consecutive side/three ordinary chase frames, all35 inspected, all1408 physical rows equal reactive in each replay, source788 unchanged. The recorded pop is absent; native offset step is27.198mm and side010→011 shirt-mask shift2.602px. The old28.627px film used a standalone input, so the pixel comparison is diagnostic rather than matched-prefix A/B. Narrow integration is supported, with fresh combined regression and elapsed CPU/M5 cost still open. The old aliased epoch remains unchanged and rejected for query attribution.

The [actual-Main water A/B/A independent review](fidelity-2026-11-06/environment/actual-main-water-01/independent-review.json) passes95 read-only integrity checks over12 originals and794 stable source inputs. All nine water views were opened. The pond’s fine bands disappear with water casting off and return in controls; the fountain remains banded and river views are bridge-obstructed. Full matrices/tick brackets/per-view marker proofs are absent from these nine views; inherited startup proofs cannot fill that gap. Later corrected river/basin diagnosis is separate pending independent review. No water policy promotion, motion or cost admission follows.

The [independent manual torso-direction regression](manual-body-axis-2026-11-07/README.md) reproduces D017 in actual default Main: old100/4, proposed104/0,999 stable source/import-cache inputs per epoch and exactly one visual-file difference. Twenty new independent world-axis assertions cover the existing ten actual-input cases; Pogo/Hang Ten’s four reversed W/S responses become correct while all original84 board/control assertions remain passing. Root has applied the exact independently matched hunk to actual source. This admits the narrow direction repair only, with natural body movement and final integration open.

## Benchmark clause matrix

Results concern the stated source/scope. **Fail** records observed deficiencies; **Unmeasured** records absent required current evidence. Independent reviewer: gameplay QA/BA, except where named.

The [complete clause map](fidelity-2026-11-06/acceptance-clause-matrix.md) and
[exact-criterion JSON](fidelity-2026-11-06/acceptance-clause-matrix.json) enumerate
44 benchmark requirements and all 104 clauses of the 20 active tickets. Each has
its own bounded result, independently observed evidence/limit and next action.
The compact tables below are a checkpoint index, not a substitute for that map.

| Clause | Evidence / actual finding | Result | Next action |
| --- | --- | --- | --- |
| V1 continuous forms | Front/side/rear; D001. | Fail | Rider topology/deformation candidate, matched close/chase review. |
| V1 adult proportions | Independent current height/limb/board dimensions absent. | Unmeasured | Measure against world scale. |
| V1 character surfaces | Simple skin/hair/cloth finish; D001. | Fail | New original assets under production lighting and budget. |
| V1 deformation | Idle omits crouch/landing/grab/specials. | Unmeasured | Normal-speed action cohort and worst bends. |
| V1 board construction/grounding | Native floor true; actual finite deck/wheel/sole geometry not independently remeasured here. | Unmeasured | Native contacts plus visible support review. |
| V2 physical materials | All-area stills/spawn; D002/D004. | Fail | Matched candidate and moving response. |
| V2 scale/resolution | Independent raw-source/import BA and four-map derivative rebuild/reflection pass; full apparent-scale/all-material coverage remains open. | Unmeasured, full clause | Inspect adjacent apparent scale and final resident allocations. |
| V2 stable moving detail | No moving material route in packet. | Unmeasured | UV/seam/shimmer and bright/shaded review. |
| V2 architecture | Existing surrounds/rooflines; repeated flat glazing/shop faces D002. | Fail | Ordinary-route windows/doors/roof joins. |
| V2 light/contact | Full bright/shaded/contact criteria not demonstrated. | Unmeasured | Wheels/rails/bases and moving shadows. |
| V2 composition | East-quay D003; authored overviews do not prove line viewpoints. | Fail | Real primary-line decision-point chase views. |
| V3 input/timing | Stills cannot establish input latency or event agreement. | Unmeasured | Native input/state/contact-event trace. |
| V3 pose/camera continuity | D015 current full-world side sequence exposes a 28.627-pixel connected rider/deck pop around the 119.816 mm correction. The complete action/camera cohort remains absent. | Fail, observed crown transition | Finite contact anticipation, exact native frame/video retest, then complete action/camera coverage. |
| V3 feet/grabs/wheels | Native push subsets improve D007; current live-Main D014 tyre penetrates actual finite coping by 57.866 mm, with a 32.562 mm mesh intrusion. | Fail, current contact witness | Repair exact finite mixed support, full affected coast/return and contact neighbours; inspect final action reel. |
| V3 forward-facing push | Independent native original-source orientation confirms D008; candidate not accepted yet. | Fail, baseline | Travel-aligned pelvis/shoulders/feet/knee and lifted return in motion. |
| V3 interruptions | Pause/restart/reverse/stale-pose matrix absent. | Unmeasured | Native interruption checks and rendered transitions. |
| V3 manual landing input | Baseline narrow window reproduced; independent immutable candidate47/0 over fifteen cases verifies fresh100–333ms, expiry350ms, release/stale/gesture and actual single-bank event order. All96-observation traces have consecutive native ticks. | Pass, timing subset; full clause Unmeasured | Complete full linked run, threshold/cooldown/pause/restart/bail neighbours and current integration. |
| V3 manual physical direction | Independent [world-sign cohort](fidelity-2026-11-06/controls-sign-01/README.md), 85/0 on 785 stable copied inputs. Ten actual-input ordinary/nose/fakie/style variants: W/S change real board-leading-end pitch correctly; same coasting loss, no unintended heading; A/D steer separately. | Pass, bounded copied-candidate epoch | Current integrated retest plus HUD/moving/target review remain required. |
| L1 research | Independently opened developer testimony and Warehouse/School II/Marseille guide passages; observed feature descriptions support the short dossier, inference is labelled. | Pass, source-coverage scope | Actual game opportunity/return timing and original candidate remain separate. |
| L1 useful density | East-quay geometric/visual deficiency D003. | Fail | Actual opportunities and empty return legs with native traversal. |
| L1 two lines/arena +three circuits | Routes implemented; metadata/stills do not prove requirement. | Unmeasured | Distinct returnable input-driven runs per arena and cross-area circuits. |
| L1 enclosure/discoverability | East-quay staging D003. | Fail | Both-direction next-choice sightlines/return. |
| L1 landings/bypass/support/misses | D012 four-input native containment passes its source/log scope. Current D014 coping contact and D015 rendered crown snap remain; whole-map landing/bypass/miss coverage is incomplete. | Fail, observed contact/recovery scope | Preserve native safety while fixing contact continuity; complete landing, bypass, shoulder and miss coverage. |
| L1 existing game/IDs/Music/defaults | Snapshot checks normal station/pond/Music, not every goal/encounter/save. | Unmeasured | Integrated regression and affected-goal/rail/gap replay. |
| L1 resource budget | Resource-neutral recomposition proposed, candidate totals not independently checked. | Unmeasured | Exact before/after totals/exceptions. |
| Q1.1 matched before/after | Clean-main BEFORE and earlier matched GL/Forward candidate frames retained; latest final production comparison pending. | Unmeasured, final scope | Same observer/cameras/backend/resolution on frozen final candidate. |
| Q1.2 identity/current pixel integrity | All 17 baseline and 34 renderer PNG/native buffers independently match; source stable, exact code/log retained. Renderer Canvas and projected markers independently rechecked. | Pass, these exact epochs | Require identical native/source identity on final production captures. |
| Q1.3 fixtures/isolation | Authored/frozen views disclosed; personal Music checked. | Pass, baseline only | Disclose moving-start/reset/full-meter fixtures later. |
| Q1.4 integrated regression | Current required-01 already records actual native/integration failures, including D014. Root owns its complete count, exit and source-after receipt. | Fail, current required run | Repair failures and independently validate changed oracles, then repeat the full stable-source gate and CLI Music. |
| Q1.5 defects | D001–016 record owner/criterion/retest; asset BA separately owns D801–803. New seat/bank/HUD/escape failed logs or native frames were independently inspected, with source limits retained. | Pass, triage scope | Retest failures/neighbours, retain failed evidence. |
| Q1.6 independent mapping | First matrix exists; candidate and subjective judgment pending. | Unmeasured | Final independent BA plus actual owner review. |
| Q1.7 cost admission | Surface allocation passes the32MiB increment, but independently verified isolated water high coverage exceeds both controls at p50/p95/p99: D013, cost not admitted. Full Main/M5 pacing remains absent. | Fail, isolated water admission; full world Unmeasured | Cheaper candidate in warmed repeated matched controls, then whole-game percentiles/stalls/memory/draw/geometry. |
| H1 device identity | Actual M5 RAM/OS/display/thermal configuration absent. | Unmeasured | Actual operator records hardware/engine/preset. |
| H1 launch/controls/save | Linux is not Mac/DualSense evidence. | Unmeasured | Mac cold/offline launch/save/menus/reconnect/reduced motion. |
| H1 sustained 1080p pacing | No actual M5 ten-minute/p95/p99/memory/stall results. | Unmeasured | Actual target route/timing and failure repair. |
| H1 engine/migration | Matched native GL/Forward review retains Godot and default Compatibility; asset defects dominate. Actual Metal/M5 and export/parity gates remain unmeasured. | Unmeasured, full target scope | Preserve documented decision and working game; verify actual target launch/pacing and parity. |

## Studio cold-read — FID-002

This reviews persistent production setup, not game fidelity. Final independent reading and [structural audit](fidelity-2026-11-06/studio-structure-audit.json) find nine role briefs, nine skills, 141 valid local links across 24 checked documents, 20 detailed tickets and no missing metadata fields. The ninth combo-controls role/skill was added for the owner's later steering. Repository files are explicitly loaded instructions; no automatic runtime registration, billed worker or unattended scheduler is claimed. **FID-002 passes this bounded production-setup review.** Subsequent implementation owners do not independently accept their own code.

The later [ten-role extension audit](fidelity-2026-11-06/studio-structure-audit-extension.json)
finds ten role briefs, ten skills and 152 valid local links across 26 documents,
with the same twenty metadata-complete tickets. Independent cold-read of the new
environment-architect brief and architectural-fidelity skill passes: ordinary-view
construction depth, route/native-collision retention, declared and measured cost,
private prototypes during shared leases, natural-frame pixel proof and separate
QE/BA acceptance are explicit. This extends the process pass; it does not accept
the architectural prototype or supersede the source scope of the nine-role audit.

The [eleven-role extension audit](fidelity-2026-11-06/studio-structure-audit-rigging-extension.json)
checks 28 documents, 157 valid local links and the same twenty metadata-complete
tickets. The new rigging brief/skill independently pass their production-setup
cold-read: actual source-edge identity, weighted native deformation, unchanged
attachment bounds and meaningful negative controls, real head-crop continuity,
source leases and independent visual acceptance are explicit. This accepts the
persistent instructions, not a future fitted-mesh adapter or garment.

The [twelve-role extension audit](fidelity-2026-11-06/studio-structure-audit-contact-extension.json)
verifies twelve role briefs/skills and 160 valid local links across 30 documents.
The contact-rigging brief specifies actual indexed native deformation, bind/cache
invalidation, unchanged contact/query limits and declared CPU/cache budgets.
STUDIO ownership/discoverability matches the roster. This passes the bounded
process extension; it does not accept the private contact helper or fitted rig.

An [independent private installer review](fidelity-2026-11-06/architecture/installer-independent-review.json)
passes nine offline checks for the four-file architectural candidate, with zero
engine calls or production writes. Exact retained candidate hashes, guarded
install/revert, later-edit and corrupt-backup refusal, and occupied-helper refusal
are verified. The installer still requires explicit source ownership; its journal
supports recovery from partial writes rather than an atomic four-file transaction.
Main geometry, native collision, rendered cost and visual finish stay open.

| Clause | Evidence / finding | Result / reviewer | Next action |
| --- | --- | --- | --- |
| A nine roles | Director/rider/environment/motion/level/rendering/combo/QE/BA with ownership/independence. | Pass / independent QA | Preserve actual assignment coordination. |
| B nine skills | Eight production-owned skills read; current native authority, 78 tricks, Music/defaults and pixel proofs explicit. Combo skill requires actual fore/aft behavior. | Pass for eight / independent QA. Supporting gameplay-qa skill independently passed by `/root/studio_production`; this reviewer authored it. | Explicitly load the assigned skill in future sessions. |
| C discoverability | AGENTS and current RESUME link roster/benchmark/tickets/renderer evaluation; role briefs link exact skills. | Pass / QA | Preserve current entry points through integration. |
| D ticket contracts | All 20 detailed tickets have owners/priorities/milestones/deps/clauses/strategies/honest states. FID-304 now requires actual fore/aft behavior. | Pass, structure / QA | Keep acceptance aligned with later user steering. |
| E fresh-agent reproduction | RESUME→ledger→independent review→D006 baseline yields exact next defect, owner, source, observer and native command. STUDIO supplies dispatch, evidence and triage contracts. | Pass, cold-read / QA | Root still owes final source/ref/test handoff for the game candidate. |

## Active-ticket matrix — checkpoint

Each ticket remains open while a required dimension is absent. A production-process pass cannot close fidelity.

| Ticket | Verified scope / gap | Result | Next action/owner |
| --- | --- | --- | --- |
| FID-001 | Current source/pixel baseline and static diagnosis retained; moving/cost/comparison incomplete. | Unmeasured, partial evidence done | Root/QE moving/cost baseline. |
| FID-002 | Nine-role/skill structure, C/E cold-read and final 20-ticket metadata audit pass above. | Pass, bounded production setup | Root integrates these durable files; game acceptance remains separate. |
| FID-010 | Both 17-view GL/Forward outputs independently inspected and pixel/source verified; no observed form/material benefit justifies switching. Target Metal/export/pacing remain unmeasured. | Unmeasured, full ticket | Final ADR decision and target portability/timing. |
| FID-101/102 | Baseline D001; candidate mesh/contact/motion not independently accepted. | Fail, baseline | Rider candidate then native/visual QE. |
| FID-201/202/203 | Baseline D002/D004; candidate art/water/light/cost pending. | Fail, baseline | Environment +asset BA/QE. |
| FID-301/302 | Native baseline D007, narrower wheel/brake/pop checks pass; candidate/adverse/camera review pending. | Fail, baseline | Motion/native/moving QE. |
| FID-303 | Native orientation confirms D008; complete candidate cycle still needed. | Fail, baseline | Coordinated motion/rider candidate then reel. |
| FID-304 | Immutable85/0 physical signs,47/0 landing-window matrix and34/0 static native meter correction pass their distinct source scopes. D011 original negatives remain preserved. Full linked run/moving/risk/remap scope remains open. | Unmeasured, full ticket; bounded subsets pass | Current integrated linked/interruption/risk/remap and normal-speed body/meter review. |
| FID-401 | Source-fresh diagnosis and independently checked three-level research pass A/B/D and research-only E; actual opportunity/return-event intervals C remain open. | Unmeasured, partial research pass | Native line timings and return opportunities. |
| FID-402/403 | D003; recompose/native circuits pending. | Fail, baseline | LD then independent mapped-input review. |
| FID-404 | Snapshot checks default station/pond/Music; whole-game/ID preservation incomplete. | Unmeasured | Integrated suite/affected goals. |
| FID-501 | No final combined freeze. | Unmeasured | Root freeze/check/capture, QE adverse cases. |
| FID-502 | Exact 44-requirement/104-ticket-clause matrix and defects done; baseline/renderer/native subsets independently inspected. Final integrated motion/routes/main ref remain open. | Unmeasured, full ticket | Final source-bound per-clause BA and main integration audit. |
| FID-503 | Actual Mac/controls/pacing/owner response absent. | Unmeasured | Actual operator; independent work continues. |
| FID-601 | Root owns integration/push; dirty changes are not verified remote commit. | Unmeasured | Actual local/remote refs and handoff. |

Independent [paving component review](fidelity-2026-11-06/environment/paving-native-01/independent-review.json) verifies 115 checks with no failures: all nine original frames, eighteen projected-marker proofs, Canvas/RGBA/native-source identity, matched A/B/A camera/counters and byte-identical return pixels outside the declared moving proofs. A separate fresh allocation records fifteen compressed maps and 31.250384 MiB additional surface allocation within the original 32 MiB ceiling. The candidate removes fan arcs but creates a stronger bright mortar grid; actual Main chase/court readability, moving shimmer and full-world cost remain open. No final paving art acceptance follows.

Next independent work: current-source push/stance and native line replay, then frozen matched candidate visual/cost review. Benchmark criteria remain intact. Screenshots, assertion counts, elapsed hours and Linux software rendering cannot close owner quality or target-device gates.

## Independent reference-source check

On 6 November this reviewer independently opened all four references in [THPS-LINE-DESIGN](../research/THPS-LINE-DESIGN.md), not only the author's summaries. The [Mick West interview](https://corecursive.com/game-programming-with-mick-west/) directly describes the downhill-to-local-level change, school planning around specific skating spots and immediate feedback. The [Warehouse guide](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-warehouse-all-park-goals-gaps-and-challenges) identifies central rail/deck/channel connections; [School II](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-school-ii-all-park-goals-gaps-and-challenges) identifies stair rails, library access and roof transfer; [Marseille](https://www.pushsquare.com/guides/tony-hawks-pro-skater-1-plus-2-marseille-all-gaps-and-collectibles) explicitly describes reciprocal ledge/rail connections. These support the dossier's bounded factual observations. Compact sightlines, purposeful next choices and return emphasis are our design inferences, not measured universal franchise spacing. No commercial-game playtest, copied layout or actual current-game line acceptance follows from this source check.


The [actual-Main architecture A/V2/A archive audit](fidelity-2026-11-06/architecture/main-headless-01/independent-structural-review.json) passes22 independent read-only checks. The candidate changes65,854 source triangle instances and16 real aperture shells; all1755 native shape records agree after removing only generated suffixes from their first path field, and all other route/grind/gap/terrain records remain exact. Guarded restore recovers the complete original source and native inventory. These are CPU/native source records, not GPU draws/allocation or a visual pass.

The [actual current researched-coping four-module run](line-design-2026-11-06/coping-proportion-private-development-2026-11-07/actual-current-01/independent-review.json) independently confirms190 native PASS lines, zero errors, exit0 and792 unchanged inventoried inputs. Its two ignored entrypoints were preserved after execution only; that limitation is recorded explicitly. This scoped current-source regression joins the separate original Main10/0 defect-window proof; physical loading, moving profile presentation, a new combined full-suite gate and M5 remain open.

The [architecture native contracts](fidelity-2026-11-06/architecture/main-contracts-02/independent-review.json) independently pass76 checks, including actual53/28/53 Main and precise FacadeBay41/0. The [matched static Main art/resource review](fidelity-2026-11-06/architecture/main-graphics-03/independent-review.json) independently passes158 checks: all21 native images/proofs, canonical collision/layout/source restoration,34 map-resource identities and per-view submitted counters. Eight original/candidate real-view images were personally inspected. Recessed upper windows, layered shop joinery/stock and smoother gallery columns improve; maximum draw delta is+4, process-local buffer delta250160B, texture delta0. This supports exact four-file integration and its reviewed fixture, followed by a fresh combined regression. Moving shoulders/culling, sparse displays, whole-city art, pacing and M5 remain open; CPU triangles and native all-pass primitives are reported separately.

The [V12 matched hand/sleeve subset](rider-fit-2026-11-07/independent-v12-hand-sleeve/README.md) independently passes102 integrity/projection/pose checks. The packed512 material atlas preserves comparable visible hand detail to the exact1024 control at this angle and removes the drummer sleeve stripe. The steward vest edge remains ragged. All14 native clean/proof buffers are retained exactly; four selected originals were personally inspected. This is private authored art, not fitted Main/contact/motion acceptance.

The [native rendered-model clock witness](fidelity-2026-11-06/rendered-model-clock-01/README.md),13 native assertions plus15 independent receipt/pixel checks, directly encodes actual GPU MODEL_MATRIX. An OFF visible child retains ON ancestor interpolation: GPU X61.176/38.431/61.961mm matches rendered API61.036/38.420/61.860mm withinRGB8, while current globals are30/70/30mm. Thus a rendered seam observer cannot substitute current globals based only on the child interpolation flag. This diagnostic10Hz64px proof supports clock attribution; actual60Hz fitted neck/body/moving acceptance remains open.

The [private fitted neck-clock A/B review](rider-fit-2026-11-07/independent-clock-01/README.md) passes104 independent source/pixel/palette/model checks. All eight native originals were personally inspected. Four default60Hz fractional samples preserve identical current actor/component/native11-bone state and outer rendered frames; only local Rider+Board interpolation differs. The largest captured baseline seam estimate20.569mm becomes4.95–5.73µm, and independent source-vertex/native-palette arithmetic reproduces20.565mm. Head placement changes most clearly in the post-grab-low pair; no dramatic visible crack or earlier83/224mm worst-gap claim follows. This supports coherent local clocks pending original fitted/contact/moving regression, with first-in-band selection and projection/readback-counter limitations retained.

The separate [maximum-selected fitted clock epoch](rider-fit-2026-11-07/independent-clock-02/README.md) passes300 independent checks:18 native buffers/stamps,732 source identities, equal current native palettes/physical state and numerical endpoint projections. Eight selected originals were personally inspected. Four eligible-band maxima are2.656/13.876/36.672/11.962mm baseline versus4.84–7.18µm coherent; independent source/palette/model arithmetic reproduces36.671mm. Head placement differs visibly in recovery-low and post-grab-high, with no83/224mm or consecutive-motion claim. Exact local-policy admission still requires the original fitted/contact/moving gate.

The [shared-leg-plane still review](rider-fit-2026-11-07/independent-common-leg-plane-01/README.md) passes57 integrity/comparison checks and personally inspects four matched originals. The grab's far-thigh slab rounds with unchanged source mesh/weights/UVs; only four leg palettes differ and rigid hands/feet/camera plus seven other bones remain exact. Segment endpoints differ by at most82.1nm. Promotion remains rejected because per-frame bend-plane sign/fallback lacks transported continuity; extension/rebend and reference-plane crossing must be tested before fitted contact/moving admission.
