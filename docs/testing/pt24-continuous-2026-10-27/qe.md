# Independent QE — continuing accepted work

Reviewed on 27 October 2026 from main `700e304861c282bb11dcd762c0cae04a06ec2642`
plus the exact changed source retained with each focused receipt. This is a
source/focused review with root's required combined admission appended below;
it does not claim blanket ticket closure.
Root owns shared engine leases, integration, commits and non-force pushes.
No engine was run by this reviewer. Receipts and raw observations below were
independently read, not inferred from agents' status messages.

## Reviewed behavior and focused evidence

| Slice | Independent finding | Exact focused admission |
| --- | --- | --- |
| C03/C07 connected tow body | The existing initial horizontal tow lean and the exact existing five-iteration torso reach delta now also move the pelvis before leg fitting. Upper-body path, blend weights, iteration counts, contact limits and limb limits stay intact. The direct two-yaw rig fixtures use actual native Skin/bind samples and original head/hand/foot marker, palm, visible-hand, shoe and limb controls. Ordinary default Main independently samples caught towing, pause, Ollie, Grab and landing. Deliberately requested bail/restart checks are labelled interruptions. | [Candidate](attachment/focused/candidate/receipt.json) **195/0**, clean/stable 644 inputs: 25 attachment/native assertions plus 170 unchanged AuthenticPose assertions. [Exact old-visual negative](attachment/focused/old-visual-negative/receipt.json) **18/7**, stable 649 inputs; its seven original native skitch controls still pass while the new attachment failures remain visible. |
| C03 finite wall-to-trick fit | Kickflip may retain only the already armed flat-Ollie finite fit. Late Grab first tries the existing decay/prior candidates, then can derive one bounded correction along the prior axis. Three ceiling volumes, native casts, a live limiting contact and a short same-collider face ray authenticate the current finite vertical face. Full board/two-shoe volumes validate the final proposal. The 18 cm ceiling, existing 8 mm skin, native motion and local rider/board poses stay bounded; shared query/ray fields restore before reuse. | [Flip](wall/focused/flip-admitted/receipt.json) **39/0** and [old-controller negative](wall/focused/flip-old-controller/receipt.json) **5/1**. [Flip plus Grab/current retained controls](wall/focused/grab-admitted/receipt.json) **54/0**, clean/stable 644 inputs. This includes 33 retained, six Flip and 15 Grab assertions, not 54 new assertions. |
| C10 camera parameter reuse | One retained visibility-ray parameter object rewrites endpoints/exclusions on every native call. Original flags, masks, query order/counts, same-update cache and solver results remain. Native moved-blocker, hit-dictionary independence, exclusion, endpoint, layer and tiny-floor controls address stale-parameter risks. | [Current](runtime/focused/current/receipt.json) **76/0**, clean/stable 638 inputs; [immutable original camera](runtime/focused/immutable-parent/receipt.json) **5/0**, clean/stable 639. Forty paired updates retain exact state/FOV/transform and **11,264 native rays** while parameter constructions change from 11,264 to one retained object. |
| C10 local metadata/HUD labels | Four pose fields reuse the definition already obtained earlier in the same synchronous pose update. Two independent current raw-ID/string slots cache only HUD labels, preserving first-empty and unknown fallbacks, aliases and immediate changes. No catalog dictionary is globally retained or mutated. Temporary test IDs and the full real HUD restore before another frame. | [Current](runtime/labels/focused/current/receipt.json) **33/0**, clean/stable 644 inputs; [counted immutable Main](runtime/labels/focused/immutable-parent/receipt.json) **6/0**, clean/stable 646. Full HUD state matches across 122 paired refreshes. Thirty-one unchanged known-ID refreshes use 62 original label reads versus two current reads. |

The [grab-fallback metadata cache](runtime/grab/README.md) also passes independent
source and [native review](runtime/grab/focused/current/receipt.json): **8/0**,
clean/stable 646 inputs. One per-rig raw-ID slot retains only the pure
fallback dictionary; live state/catalog overrides remain current. Reset keeps
its original neutral animation. The paired actual-rig comparison covers
all node/bone/blend-shape/weighted-cloth outputs, authored/unknown/empty IDs,
override changes, fading/reset and a deliberately corrupted-tuck negative. The
248 paired updates plus build/reset preserve exact outputs; 14 cached dictionary
objects replace 250 fresh objects across this deliberately changing-ID fixture.
The sixty ordinary updates create zero new fallbacks versus sixty. No
production math, global catalog cache or timing conclusion is added.

The attachment native observation contains 228 samples, including 79 caught
frames. Maximum clothed waist-centre separation improves from 142.1 to 64.7 mm;
torso/pelvis separation improves from 120.0 to 32.9 mm. Direct entry/release
marker steps remain below the original 220 mm criterion. The explicitly assigned
tow-to-Melon fixture changes the rider setup transform, so its initial marker
discontinuity is not presented as a continuous native transition.

The reviewer also inspected all four [matched native attachment frames](attachment/README.md#four-matched-native-garment-controls)
and independently verified their manifest hashes/dimensions: four 960×800 PNGs,
zero capture failures, clean/stable 650 inputs. The before control reverses only
the attachment hunks while preserving the later fallback cache/current controller.
Held and six-call released views visibly correct the displaced trouser waist
while keeping torso/hands/planted shoes coherent. These are explicitly assigned
native rig poses with a handle marker, not a running vehicle or motion acceptance.
Draws/primitives/textures are equal; the first-frame video-memory difference is
retained rather than presented as identical memory or timing improvement.

The actual wall Grab has 12 active ticks, minimum measured wall clearance
7.99999 mm, and maximum offset 134.563 mm; the unfitted twin reaches
−126.417 mm. Native physical state and local rider/deck geometry remain equal.
Catalog Ollie 100 plus Melon Grab 250 banks **700 once** through actual trick and
landing signals. Negative controls independently cover unarmed flight, an unsafe
ceiling, a clear-ceiling intersecting oblique face, an obstructing side corner,
finite-wall removal, no accumulation and all reused query fields. This accepts
the demonstrated Kickflip/Melon path, not every trick variant or every corner.
The rare Grab fallback has a stated maximum of 17 native calls including the
earlier candidate checks; ordinary clear skating does not enter it.

Four [matched wall frames](wall/README.md) are also independently inspected and
SHA/dimension-verified: two actual input-earned Flip poses and two Grab poses,
960×640, zero capture failures. Their separate execution receipts are
clean/stable 648 inputs; these capture receipts report no assertion total.
Drawn board-tip clearance changes from −124.320 to +8.000 mm for Flip and
−125.949 to +8.614 mm for Grab. The restored rounded board tip is visible;
physics/camera remain matched and objects/draws/primitives are equal within each
pair. **Upper-arm wall clipping remains visible in the after-Flip frame.** This
is an open C03 body-contact issue, outside the bounded board/shoe acceptance.
Connected clothes and deck do not establish complete body/wall clearance.

## Menu boundary: focused acceptance passes

Actual default Circle Back was shown to change the next north-modified launch
from Nollie to Ollie and briefly suppress steering spin through a legacy Grab
request. Saved Circle mappings additionally reproduced spontaneous Ollie,
unwanted Manual/Revert and dropping an actually caught rail. A Cross press and
release within one physics tick could award Ollie after Start or Resume.
Released-during-pause Space could leave a stale charge; an independent held
keyboard binding could also be cleared by the consumed controller action.

The admitted source waits for all consumed physical presses to release while
the modal stays paused, restores independently held keyboard bindings, then
crosses a paused physics pass and its following idle boundary. Serial,
nonempty expected page/revision, state, visibility and recorder-input guards
reject obsolete callbacks. Any new consumed press increments an input revision
and rearms after its release. Unique one-shot callbacks use typed WeakRefs;
focus/device-loss cancels pending transitions. Nested Back stays immediate when
it remains paused; holding Back now deliberately holds the modal until release.
Unpause cancels only an Ollie charge no longer physically held, preserving a real
charge and accepted jump buffer. The live trick sampler is unchanged; the earlier
family-only queue API/guards were removed.

Independently verified [actual integrated controls](ui/focused/accepted/receipt.json)
pass **33/0**, clean/stable 646 inputs. The additional
[30-step](ui/focused/render30/receipt.json) and
[120-step](ui/focused/render120/receipt.json) controls each pass **6/0**, also
clean/stable 646 inputs with 60 Hz physics. These cover the four actual Cross
transitions, duplicate Back and later input between physics and idle. The full
33 also retains Nollie/spin parity, genuine directional families,
Manual→Pogo→Ollie metadata, four saved Circle mappings, held M/Space, paused
release cancellation, fresh genuine Circle reuse and five invalidations.
The raw log's `fixed_render_hz` value is accelerated `get_frames_per_second()`;
receipt command arguments establish the deterministic 30/60/120 step values,
not physical display refresh or performance.

All [rejected candidates and causal observations](ui/README.md) remain intact,
including the actual held-Space jump at 30/2, duplicate registration at 32/1,
two explicit-type failures and the initial wrong Flip-label fixture. The queue
fixture now checks only consumed Grab membership, preserving an unrelated Manual
entry. No passing result is assigned to a parse failure or unhealthy causal run.
Physical simultaneous-device and target-Mac timing/feel remain separate work.

## Fountain source review; rendering timing rejected

The original indexed lathed ornament replaces the same three display slots,
transforms, labels and existing materials. The hollow cup/annular lip and nozzle
foot stay inside the old combined ornament envelope. Source review finds the
clockwise winding, analytic inner/outer normals, tangent handedness and connected
cup/nozzle construction coherent. The declared change is 288 triangles/259
vertices versus 360/270, with no new display slots, materials, texture, light or
collision resource.

The decorative hollow cup is explicitly not new playable support: the existing
two native fountain cylinders and 2.7 m physical pedestal top are preserved.
The design is original; no claim of replicating a real Exchange fountain is made.

The first strict 1e-4 tangent-dot assumption is rejected by unchanged native
CylinderMesh packing controls as well as the candidate. The
[packing diagnostic](fountain/focused/packing-control/receipt.json) exits clean
and source-stable but reports no assertion total; it is a precision observation,
not feature acceptance. Existing controls reach about 0.00753 degrees of decoded
tangent/normal nonorthogonality. The candidate's approximately 0.00960-degree
maximum fits the explicit 0.02-degree angular allowance. Nonfinite, unit length,
handedness, winding, bounds and resource checks remain unchanged. This criterion
correction is justified by native packing evidence, not by changing geometry to
hide a failure.

The [corrected native receipt](fountain/focused/native-current/receipt.json)
passes **16/0**, clean/stable 644 inputs. The
[fresh-process A/B/A execution](fountain/render/receipt.json) is clean/stable
644 inputs and reports **12/0, 19/0 and 12/0** for semantic/image/source assertions.
Those counts exclude the separate [cost comparison](fountain/render/comparison.json).
Every resource cell passes: matching draws/objects/textures, 72 fewer visible
primitives, and 740 fewer buffer/video bytes. Two declared timing cells fail:
overhead p99 **157.450 > 151.33755 ms**, and approach p95
**494.563 > 494.49645 ms**. The latter remains a failure despite its small margin.
No waiver or replacement run is admitted. Render timing admission is rejected.

This reviewer inspected actual candidate overhead/court images and the original
overhead control. The low court view shows the annular rim and flared finial;
the shallow cup recess remains subtle overhead with the existing stone mapping.
These are actual changed-place frames, not human final-art approval. Lower
medians or resource counts cannot override either failed timing cell.

## Remaining integration and the next accepted work

The focused receipts each certify their recorded source maps. Do not add their
overlapping assertion counts or promote them to a final combined result.
The ornament's rejected timing admission remains open. Production
`tools/check.sh`, cold launch and source-bound current packages remain root's
integration checkpoint until their actual receipts are linked. The required
combined suite now passes on strictly frozen source; its exact receipt is linked below.

The next independent C02 witness is prepared under ignored
`.local/civic_shadow_witness.{gd,sh,md}` and has not run. It uses ordinary
default-on Main, persistence disabled before tree entry, the exact owner
position/orientation/FOV from captures 2/3 and their original 1440×900 viewport.
Near/far come from current Main; the actor stays at its ordinary setup location.
Each witness records six stationary and twelve authored one-metre moving
completed native frames, preserving normal shadows and all merged content.
The optional process-local directional-shadow-off diagnostic is for classifying
an observed defect only. It never bypasses the whole repair helper or proposes
shipping with shadows disabled. Readbacks and draw-wait intervals are not target
frame-time evidence. Moving-image differences also contain ordinary parallax.

Do not repeat completed required-wall-span audits or the selected six connected
route representatives. Further traffic/skitch features, cone polish and the
extra park-lap challenge stay deferred; the connected tow repair is core body
maintenance. No old ticket body or raw failure was rewritten. Prior Pogo prose
now correctly calls its rejected 274.6 mm measurement a sampled head/hand/foot
marker step, not proven knee movement.

Actual Mac source/standalone execution, saves/relaunch, personal Music/TCC,
physical wired/Bluetooth controls/reconnect, moving-Mac shadows, target stutter
and final human art/listening/fun acceptance remain open. They do not hide merged
trial features or stop independent accepted work. Allocation counts, Linux
verification durations and polygon reductions cannot certify target performance.

## Required combined admission

Root completed `./tools/check.sh` under the unchanged-source wrapper:
**5,340 passed / 0 failed**, plus the actual short-script Music guard **2/0**.
Exit0, clean log,645stable inputs,558.534seconds; manifest
`12c1afc0b17cdfa6fa5e1d75926095283acaabe3ff168d9b9fb063e1dc49ccb5`.
[Raw receipt](validation/combined/receipt.json), exact changed snapshots and raw
line traces retain the integrated source. This does not override the rejected
fountain timing comparator, remaining upper-arm/Manual scope or target/human gates.
Push and continued source work remain root-owned checkpoints.
