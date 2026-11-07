# Skating motion fidelity — 6 November 2026

This work refines current main `0b62035`, preserving its native GLB skateboard, finite wheel/rim/deck/shoe/palm checks, oriented native wall/transition support, 78-trick repertoire and physical input/scoring contracts. The October alpha bank/interpolation experiments were superseded when the checkout was reconciled with main; their results are not candidate evidence.

Acceptance remains open under [AAA_BENCHMARK](../product/AAA_BENCHMARK.md), especially V1/V3 and FID-102/301/302. Native measurements prove individual defects and regressions. They cannot award commercial animation quality, owner approval or MacBook Air M5 performance.

## Reproduced push defects and correction

The old loaded push covers a fixed0.65m stroke over a speed-insensitive period. At actual board speed the sole slides through stationary pavement. Independently, torso and supporting shoe continue facing across the deck during the stroke. QA reproduced both on immutable original production source with the candidate measurement harness; see [independent baseline packet](fidelity-2026-11-06/push-baseline).

| Native ordinary Main case | Original peak sole slip per60Hz tick | Original torso/front-shoe forward dot |
| --- | ---: | ---: |
| Regular moving start6m/s | 212.532mm | 0.301 /0.0663 |
| Fakie moving start−6m/s | 212.521mm | −0.397 /−0.0699 |
| Push from rest | 161.161mm | 0.298 /0.0663 |

The candidate advances the planted phase according to actual board speed divided by the real stroke distance; its320ms return stays lifted and phase boundaries cannot be skipped at high speed. Pelvis, chest and head turn toward actual travel while pushing. The front shoe turns lengthwise on the flat grip; hand/elbow targets follow the same connected body frame. This changes presentation, not physical acceleration, steering, eligibility or scoring.

`tests/motion_fidelity_tests.gd` observes actual mapped input. Regular/fakie moving-start fixtures disclose a single signed6m/s initial velocity and initial heading; no later velocity/heading is assigned. A separate case pushes naturally from rest. Braking and6/18-tick stroke interruptions use input from rest, then check one native landing and actual sole return to GLB grip triangles. Actual four-wheel GLB vertices are compared with native world support; on the flat fixtures the existing8mm presentation skin is measured directly. Incline regressions additionally use actual native sole-support planes and full3D sole displacement; they hold the real brake during settling, then push uphill/downhill from rest without a velocity seed. Their production acceptance remains pending.

Candidate acceptance targets: planted slip below5mm per60Hz tick, actual supporting sole within5mm of grip triangles, unloaded return above100mm, continuous body-relative head step below220mm, and torso/front-shoe travel alignment above0.96. These supplement existing native contact checks. They do not replace them.

The first added20° incline diagnostic used a moving6m/s start: uphill slip peaked3.102mm; downhill peaked5.123mm with only3fully loaded intervals before the high-speed push cutoff, so it failed. Its later release also crossed the global−8m recovery threshold because the synthetic descending plane was centred atY0; that fixture failure is not a production contact defect. The revised incline fixture is elevated12m and uses actual braking/pushing from rest. Its follow-up22/0 development run had zero engine errors: both initial speeds were0; uphill20° peak slip1.942mm across7loaded intervals and downhill20°2.420mm across6intervals. Supporting sole/grip errors stayed below0.855mm, actual hips/torso forward alignment exceeded0.996/0.997 and front-shoe alignment exceeded0.989. These cover natural push-from-rest; the original marginal moving-start downhill witness is retained, not silently counted as a pass. Ordinary grounded controller speed already measures real tangent velocity; it was not retuned based on a mistaken horizontal-speed hypothesis.

## Finite raised seat support defect

Level-design's mapped two-seat relay exposed a separate error after an early second-seat exit. The native capsule landed on the seat while its centre ray missed the finite edge and hit paving49cm below. `_update_pose` then placed the connected board/rider on that lower plane. This was not an active grind or a guide-height error.

Independent once-spawn/70-native-tick reproduction at `(64.58057,3.2,63.55468)`, heading−75°, produced a current capsule floor contact `(64.58184,2.49,63.55944)` on the actual rotated seat, while the centre ray returned pavingY2.0. Two real tyre minima wereY2.008, penetrating the seat by482mm. A centre-seat control had four8mm wheel gaps. The [development diagnostic](motion-fidelity-2026-11-06/rejected-seat-edge-before.log) contains concurrent unimported environment-texture errors and is explicitly rejected as clean acceptance evidence; the geometric observations establish the fixture for a clean rerun. The original mapped [early-exit witness](line-design-2026-11-06/rejected-early-exit/README.md) remains retained separately.

The correction only allows a fresh, native-valid, currently grounded slide-floor contact to replace a centre ray lying more than1mm below that contact's plane. A fresh short ray across the actual slide point must confirm the same finite collider RID and integer shape index; moved/removed shapes cannot donate an old infinite plane. It preserves the native floor-angle limit; teleports/unsupported frames cannot reuse contacts. The original finite wheel/model queries still validate presentation. It does not move guide geometry, collision, the physical actor or a balance value.

The added independent rotated thin-seat regression checks actual support ownership and the displayed complete GLB convex shape at both the seat centre and just beyond its centre-ray edge, plus immediate restart invalidation of the old native contact. A development run then passed48 checks with zero engine/resource errors, including12 actual Manual ticks on the ordinary Main seat: the full connected model stayed clear and the loaded tyre gap was8.022mm. Its trace exposed that Godot `get_collider_shape()` returns the shape object rather than the ray-hit shape index; the final implementation uses `get_collider_shape_index()` and explicit index-type checks. The following22/0 development run also passed the final fresh finite-point/RID/integer-index guard and restart checks, with Main loaded tyre gaps8.022–8.393mm across all12manual ticks. A source-stable replay still requires verification. Actual mapped full-relay verification also remains open.

## Named grind release and fast graded-wall contact

The newly authenticated east-quay seats exposed a genuine first-frame handoff defect. The active50-50 solver and native clearance passed, but its exact exposed-edge roll was not used to seed flight. A stale cosmetic grind-balance frame was instead interpolated toward the next floor while the release offset decayed before the capsule's first physical jump movement. A real GLB extremity moved from2.849mm above the seat to26.300mm inside it. The candidate preserves the last authenticated board frame for that release pose and seeds the actual unscored support frame. The unchanged mapped relay, strict camera/receipt and bank/fakie/bypass return then passed3/0 in development.

An added every-physics no-contact query then rejected both the still-loaded active pose and identical first-air pose. Full [actual-component/native-Box SAT diagnosis](motion-fidelity-2026-11-07/loaded-contact-sat-development/README.md) distinguishes intended hanger contact from that26mm snap: maximum overlap is0.226µm, inside the unchanged100µm named loaded-contact contract. There is no strictly positive all-hit separator, so no production certificate/bypass/tolerance change was added. The new exit witness must authenticate the preceding bearing and exact capsule/rigid-board pose preservation, then require strict clearance once actual motion separates the model. An unconditional first-air skip would be invalid.

A separate real12m/s bank approach natively stops at the retained vertical wall while the longer real board nose projects24–30mm through it. The existing connected obstacle fit was deliberately limited to flat ground. The new grounded grade path moves the entire connected presentation along its actual floor tangent, authenticates a fresh native wall point/RID/shape and requires four finite tyre supports plus complete board/shoe volume clearance. Retained offsets must pass those live checks again. It changes no physical position, speed, impulse or camera assertion; the before/after native trajectory and event ticks match exactly. The strict diagnostic changes from0/1 to1/0. New focused Main regressions additionally reject floated/buried tyre proposals. The [raw development packet](motion-fidelity-2026-11-07/release-and-grade-development/README.md) explicitly lacks a frozen-source acceptance receipt; final independent verification remains open.

The focused new actual Main regression passes3/0 with no engine errors:57contact/rollback frames each retain four finite tyre witnesses and a clear connected native model. Actual tyre gaps14.105–14.113mm remain inside the existing30mm bound; maximum connected tangent correction is43.151mm. Both deliberately floated and grade-penetrating offset proposals are refused. These are development checks; frozen-source integration remains pending.

## Reproducible evidence tools

Persistent specialist workflow: [skating-motion skill](../../.agents/skills/skating-motion/SKILL.md). New tests expose `run(tree,check)`, `run_main(tree,game,check,observer=Callable())` and `run_main_support(tree,game,check)`; the observer contract is `(phase,game,step)`, matching the existing native capture pipeline. Main persistence must be disabled before tree entry.

`tools/full_fidelity_capture.sh` keeps its default complete78-trick coverage and exact native RGBA/decoded PNG, camera/Canvas synchronization, source-freeze and full movie-decode proofs. Optional `--cohort push-contact --push-view front|side|chase` captures only the seven ordinary Main push/brake/pop cases at native60Hz and encodes normal-speed60fps. Its manifest explicitly marks complete repertoire coverage false. Each view publishes to a separate `screenshots/push-contact-VIEW` directory; it cannot overwrite the default full-fidelity packet. Restarts/setup settling are omitted from clips. Authored front/side inspection cameras are labelled; chase uses the production camera and HUD.

An independent six-frame meter probe found an inherited dynamic `_snapshot` bug already present in baseline HEAD: it accessed `TransitionRide.state` and treated that helper's Dictionary feature as a Node. Its packet was rejected despite completed assertions. The tool now reads authored-feature state/Node from `_feature_transition`, and separately records the real cylindrical helper's active flag, Dictionary ID/body and theta. A new `tools/full_fidelity_capture_smoke.gd` constructs actual Main and calls `_snapshot` before costly rendering; parser-only checks cannot catch this dynamic misuse. The wrapper preserves its smoke log with the capture. Actual inactive-Main smoke passes3/0 with a clean engine log. A subsequent [actual cylindrical-active Main witness](motion-fidelity-2026-11-07/capture-cylindrical-active-native/README.md) passes4/0: initial spawn/heading plus42 mapped Push ticks earn the real clyde_half_east contact and snapshot ID/native body/theta without helper-state injection. The original Clyde route separately exercises an active authored helper. Independent QA cold-read confirms both real contracts; complete rendered capture verification remains separate.

Commands (after a clean, coordinated source/import freeze):

```sh
./tools/run.sh --headless --fixed-fps 60 --script .local/push_main_runner.gd
./tools/full_fidelity_capture.sh --private-display --cohort push-contact --push-view front
./tools/full_fidelity_capture.sh --private-display --cohort push-contact --push-view side
./tools/full_fidelity_capture.sh --private-display --cohort push-contact --push-view chase
```

The local runner is an ignored development convenience: equivalent durable suite integration calls the two public methods above. The separate support method reproduces the exact Main raised-seat edge and a moving mapped Manual, outside the seven-phase push-capture scope. Root owns the integrated suite and final source/commit receipts.

## Candidate results and limitations

Clean candidate native results, source inventory and reviewed clip receipts are pending. Development logs reporting338/0,33/0 and40/0 while resources were failing to load are rejected, not clean passes. An independent candidate27/0 with zero engine errors was also rejected because outdoor-route/test inputs changed during its23:49:34–58 source epoch; it is not a source-stable acceptance packet. The initial brake assertion atrest incorrectly expected a faded dragging pose; the corrected test measures the actual moving, fully blended13-sample brake interval. The first direct retained-relay replay failed its first catch without prior fixture input history and cannot prove or disprove the later bench fix; independent seat geometry reproduces that defect without manufactured input history.

The independent immutable `checkpoint-source-01` complete motion sequence then reported66checks/1failure: all push, incline, raised-seat and unsafe-offset checks passed, while the new fast graded-wall combined model-clear condition failed in that test order despite its isolated3/0 development result. Source hashes matched current production/test files. The whole receipt is rejected. Exact diagnosis found deck component0 hitting EndBoundary shape1 during one native-valid grounded rebound tick whose capsule wall flag had just dropped. A fresh actual hull/face contact now derives the current minimum only for an already earned fit on the same floor RID/shape, instead of dropping the connected model back through the wall.

The [retained rebound packet](motion-fidelity-2026-11-07/rebound-and-air-development/README.md) records source-stable isolated65/0 on the old wall and66/0 on the subsequent Y7 wall. The latter adds a deliberately stale different-native-floor identity and restart negative; all four wheel rays now authenticate the same actual support RID/shape. These clean, narrow native epochs still do not replace independent current-source integration or moving visual review. The subsequent same-controller native epochs pass66/0 full motion,54/0 legacy flat-wall/Ollie/Flip/Grab twins and4/0 maximum-speed bank pops with every-air actual-model/shoe/capsule proofs and adverse owner/floor checks. Their physical trajectories remain unchanged. These source-scoped packets do not establish smooth moving presentation: the maximum crown correction enters at119.816mm in one60Hz tick, requiring independent normal-speed review and possible finite swept-contact anticipation. The exact native meshes,1408tick trace and limitations are retained in that packet.

Open gates include independent candidate verification, source-stable normal-speed front/side/chase review, complete current native/regression/action coverage, raised-seat manual transitions, MacBook Air M5 frame pacing and owner assessment. No automated dot product or contact distance closes visual plausibility by itself.

Independent QA subsequently recomputed the worst actual indexed GLB mesh against the finite native wall:1199 duplicated drawn triangle corners lie inside the unfitted slab, with maximum111.820439mm intrusion. The fitted endpoint retains7.996mm clearance. This is actual rendered geometry, so the119.816mm correction cannot be reduced by calling the native hull conservative. The preserved independent review is beside the [worst-frame packet](motion-fidelity-2026-11-07/rebound-and-air-development/README.md).

QA's separate source-bound fullworld32-frame side replay and three worst-frame production-chase captures complete492/0 and314/0 native/pixel assertions respectively. Those counts concern observer checks, not additional gameplay features or visual acceptance. Actual side frames009–011 show an abrupt approximately25–30pixel connected rider/deck displacement, independently corroborated by the motion owner. D015 visible movement continuity therefore remains failed even though current finite contact endpoints pass. A proposed same-earned-owner finite native swept-contact forecast, bounded to120ms, must be developed and independently rechecked; no production anticipation change or replacement passing moving packet exists yet. Preserve the original zero-offset-above-crown negative for the reactive source; a future forecast exception requires explicit fresh finite predicted component proof and cancellation/reset/foreign-owner negatives.

The private [finite anticipation prototype](motion-fidelity-2026-11-07/air-anticipation-development/README.md) subsequently preserves all1408 physical trace rows and lowers the maximum correction step to27.198mm. It remains private and unaccepted: the original reactive oracle correctly reports1pass/3fail under its unchanged zero-offset rule, new forecast fault injections are pending, and no replacement moving review exists. The packet labels its inventory as sampled after development rather than inventing a before/after freeze.

The ordinary full-suite replay also finds a separate real Clyde coping intrusion at(-10.647394,2.014219,139.5004). A [source-frozen tiny exact production-bowl pair](motion-fidelity-2026-11-07/coping-footprint-development/README.md) reproduces a nearby native phase: one wheel sinks49.217mm because an infinite tangent-plane lift asks135.880mm and aborts before the existing finite footprint solver. An owned-bowl-only retry from the original plane clears that phase within36.618mm of the existing100mm budget, with identical22tick physical trajectories. Two diagonal tyres are loaded while the other pair unloads43mm; this is explicitly not a four-loaded-wheel claim. The initial partial retry exposes a further exact-phase failure(41pass/1fail). Fresh bounded vertical native rays subsequently authenticate real finite support instead of concave virtual rest points; the retained49/0 isolated controls include wrong owner/shape, underside, out-of-range and nonfinite negatives. However, the [unchanged ordinary Main route](motion-fidelity-2026-11-07/coping-main-current/README.md) still finishes5/1 against stable790 inputs: native PrintYard collision intentionally coincides with the annular deck, and one tyre reaches57.866mm penetration. A [matched private wheel-owner candidate](motion-fidelity-2026-11-07/coping-main-owner-development/README.md) repairs that first phase but fails at the next coping-normal frame; all530 physical trajectory rows remain exactly equal. Neither isolated controls nor physical parity close D014. No candidate owner-discovery change is promoted, and the next diagnostic identifies the exact finite-fit refusal rather than increasing its100mm cap. Passing a changed route driver would not close this actual geometry defect.

The next private diagnostic isolates the mouth transition: the first wheel-centre ray misses while coincident paving wins the centre ray. Its actual rounded tyre's full existing0.85m sweep also reports[1,1], so it is genuinely unloaded within that reach; inventing a Bowl owner from that empty query is rejected. A declared three-bearing planar candidate finds three real7.999897mm loaded gaps but correctly refuses whole-model interference. Native top/bottom rays through the actual drawn GLB then bracket15 unique material vertices inside the finite steel tube at the first unloaded phase, and114 at the next (maximum depths24.935mm/41.751mm). Original planar full-model clearance needs45mm/55mm upward translation at1mm diagnostic resolution, which cannot retain the declared three-loaded-wheel skin. These private diagnostics retain source manifests and no visual/runtime acceptance: a distinct actual model/coping support contract must be reviewed before implementation. No native shape is hidden and no loaded tyre is relabelled to pass the old rule.

Subsequent primary construction evidence identifies the inherited coping itself as disproportionate: its90mm tube and70mm deck reveal differ from the cited60mm tube/12mm deck/10mm transition profile. LD's private geometry-only correction and matching native guide datum make the [unchanged original Main Clyde route pass6/0](motion-fidelity-2026-11-07/coping-researched-profile-main/README.md), with the exact same f042controller,472 clear camera samples,250 bowl samples, zero bails, preserved100points and completed return. Both790 production inputs and LD's broader801-file held corpus remain stable. The physical trajectory changes intentionally with the actual geometry. Rejected owner-discovery/three-bearing/controller-support candidates remain unpromoted. Full profile/loaded-wheel/combined and moving gates remain open.

The strengthened PRIVATE air forecast now parses and passes its [four native bank cases](motion-fidelity-2026-11-07/air-anticipation-finite-native/README.md) with1408 exactly equal physical trajectory rows versus the durable reactive trace, all current/future strict clearance guards, and10forecast-fault plus8pure frame controls at three positive cases. Maximum presentation step is27.198mm; normal-speed moving acceptance is still required. LD subsequently finds an observer Dictionary alias at one injected foreign-owner probe, incorrectly labelling an accepted120-query forecast as an85-query refusal. This rejects that packet's query-attribution subsection; the corrected observer is held for rerun. The native contact/physical proofs retain their narrower source scope. Actual production remains reactive.

The researched profile's separate [actual-physics contact replay](motion-fidelity-2026-11-07/coping-researched-profile-physics/README.md) passes10/0. All seven consecutive original-edge ticks179–185 retain native clearance for all cached skateboard components and four tyre volumes; independently measured gaps in the4–30mm band are7.320–20.865mm. These are geometric near-contacts, not measured wheel loads; some steel normals haveY0.194653. Mixed paving/steel ray ownership and missing bounded native rays are recorded explicitly. The old deeply tilted model remains rejected. All503 trajectory rows exactly equal the preceding same-geometry Main route, and queries change no actor, velocity, board or physics time. Shared-family98/0 and primitive24/0 are separate scopes. This does not claim full-bowl per-physics coverage, final moving acceptance or Mac performance; actual profile promotion remains root-controlled.

The separate [corrected192-query forecast epoch](motion-fidelity-2026-11-07/air-anticipation-192-native/README.md) passes parser/four native cases with786 unchanged inputs. All1408 physical rows still exactly equal the reactive baseline. The independently owned observer now snapshots its receipt before faults, requires the exact192 cap and passes a reserved-current-pose refusal at157queries, leaving35 final checks. Its41 stamped attempts have query upper-bound p50/p95/p99/max66/152/152/152, with the formerly mislabelled gate78.7 success correctly retained. These bounded counts are not measured CPU cost. The27.198mm maximum offset step and131.497mm total correction still require a new source-bound normal-speed Main side/chase review. Production remains reactive; the failed earlier attribution packet is preserved.


The independent [corrected moving review](motion-fidelity-2026-11-07/air-anticipation-moving-02/README.md)
now supports narrow forecast integration: all32consecutive side frames and three
separate production-chase frames are inspected, both complete1408physical traces
equal the reactive baseline, and each788-input source corpus is unchanged. The
recorded connected crown pop is absent; largest observed silhouette displacement
is9.607pixels and maximum presentation-offset step27.198mm. The32@60Hz video is
a fully decoded review artifact, not human ordinary-play acceptance. The previous
double-readback observer epoch remains rejected. A [surgical promotion bundle](motion-fidelity-2026-11-07/air-forecast-promotion-source/manifest.json)
retains144other current controller functions byte-for-byte, including the newer
coping recovery, and leaves the actual Manual torso-axis visual repair untouched.
Root controls guarded installation and fresh combined regression; fitted-shoe
contact, panel-crossing coverage and target-M5 cost remain separate open gates.

Authentic shoe integration exposed a [source-cache under-enclosure](motion-fidelity-2026-11-07/shoe-support-development/README.md):
`get_faces` differs from rendered indexed buffers and native debug-hull reduction
omits real extrema. Source-indexed sole/full-shoe caches remain private while exact
native/integer enclosure, invalidation and whole-contact admission are corrected.
The failed native epochs are retained rather than inheriting semantic or source-only
passes as fitted contact acceptance.


A fresh45f20-source [generic grind diagnostic](motion-fidelity-2026-11-07/legacy-generic-native-01/README.md)
now records four24physics-step generic captures with no native skateboard component
overlap or bail and803stable inputs. Positive clearance coexists with about55mm
settled public hanger-to-native-plane separation on the three flat families.
Their missing tyre rays remain unknown; no physical load or named-contact
certificate is inferred. Two initial market-counter camera rays are explicitly
pre-camera-process observations, so a post-camera/draw test is required before
claiming a rendered obstruction. Actual native support authoring and visual contact
remain open; no global generic pose offset is applied.


## Native round coping catch (2026-11-07, private candidate)

The original unchanged promenade air-grind fixture physically put two actual
inner tyres 5 mm into its real rear deck after the researched 12 mm coping reveal.
The native part/RID/shape rejection, finite-cylinder solution and honest failed
predecessors are retained in [round-coping-native-01](motion-fidelity-2026-11-07/round-coping-native-01/README.md).
A current coherent actual-source snapshot with only the guarded seven-file
proposal passes 434/0: existing neighbors 344, original Main Transition 23 and
new public native round/profile/ride/release controls 67. Actual body/guide/input/
reach/tolerances remain unchanged; model-derived 2.76594° roll follows the true
cylinder and keeps both actual hanger anchors within 100 µm. Independent review,
actual installation/integration and moving appearance remain separate gates.

Root subsequently installed the guarded round solution. The first actual combined
run was [rejected at 133/1](motion-fidelity-2026-11-07/actual-round-focused-01/README.md)
for an actual Clyde landing intrusion; it also records the launcher's omitted
Player Guide binding. After the separate finite flat-landing handoff repair,
[strict actual focus02 passed 134/0](motion-fidelity-2026-11-07/actual-round-focused-02/README.md):
original Transition 23, public round contact 67, ordinary Main motion/support 32,
original Clyde 11 and Music isolation 1. Both processes exited zero, raw logs were
clean, 892 required source inputs and five independent native cache pins stayed
stable. The same already-created Main supplied the read-only registry snapshot:
8 gaps, 66 world routes, 67 HUD routes and 242 unique grind guides. This focused
result does not certify the subsequent full suite, moving appearance or M5 cost.

The later [private Manual rim recovery](motion-fidelity-2026-11-07/station-manual-native-01/README.md)
reproduces a real trailing tyre/Cylinder3 overlap for which native rest information
is empty. Reusing only the original same-callback loaded-wheel ray allows the
existing 25 mm/full-model correction to run. Clean current-source native checks
pass 22/0; all 1004 physical rows equal the rejected baseline, and 993 consecutive
ordinary board/shoe-box frames clear. The packet retains the unrelated inherited
spine capsule failure, diagnostic fixture limits and bounded-query cost. The
proposal remains private pending independent review and neighboring checks.
