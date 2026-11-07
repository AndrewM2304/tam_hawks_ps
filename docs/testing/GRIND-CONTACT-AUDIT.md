# Native grind-contact audit — 7 November 2026

Scope: FID-102 and the current high-fidelity benchmark. This audit distinguishes authored `contact_verified` metadata from actual successful native board/truck/deck contact. Metadata counts cannot certify a ride, and an unchanged generic Rail Grind cannot substitute for a verified 50-50. No global flag conversion or tolerance change is authorised by this report.

A clean-engine ordinary Main development inventory now reports242 unique runtime guide IDs:86 have authored contact verification and156 do not. No duplicate IDs occur. These counts are **pending a frozen-source inventory receipt**; the development raw JSON/log/tool are retained in [the inventory packet](motion-fidelity-2026-11-07/guide-inventory-development/README.md). The historical October23 total of159 generic semantic edges is not a current-world count. The November maps have moved/extended props and added supported features.

| Runtime metadata source group | Guides |
| --- | ---: |
| `legacy.semantic_edges` |120 |
| `legacy.unverified` |33 |
| `legacy.body_profile_only` |3 |
| `glasgow.lowered_cylinder_envelope` |38 |
| `feature.native_coping_crown` |11 |
| `glasgow.box_bar_top` |6 |
| `skate_edges.native_box_top` |6 |
| `sunken.native_box_top` |6 |
| `surface.native_box_top` |5 |
| `outdoors.square_beam_normal_top` |4 |
| `transition.cylinder_top` |3 |
| `clyde.existing_red_cable_native_crown` |2 |
| `sunken.lowered_cylinder_crown` |2 |
| `actual_raised_hubba_coping` |1 |
| `pond.native_flat_square_perimeter` |1 |
| `pt24.recording_court_steel_top` |1 |

## Source audit during the exclusive measurement lease

No Godot, editor import, renderer or shared import-cache mutation was run for this phase. The following are source observations, not new visible-defect claims.

| Runtime source/provider | Contact authoring contract | Remaining inspection |
| --- | --- | --- |
| `glasgow_square._rail` | Actual BoxShape top, `glasgow.box_bar_top`, under an exact unit-yaw frame | Keep existing native named/capsule/board checks; identify actual owners in runtime inventory. |
| `glasgow_square._grind_path` | Lowered native/visible cylinders; vertical/radial offsets `glasgow.lowered_cylinder_envelope` | Changing-grade radial joints deliberately refuse verification. Flat turns can retain a common upward crown, but finite chord/corner admission still needs its native checks. |
| `outdoor_routes._rail` | Exact ordinary square-beam normal crown on supported frames | A changing-grade path can retain only an inspected body-profile radius. That permits body clearance without certifying the named board pose. Audit these explicitly as `legacy.body_profile_only`. |
| `skate_edges._commit` | Plain semantic guide constructor remains generic for legacy source families | Whitelisted benches, planters, seats, counters, civic/station/quay/ribbon edges need per-family finite support and connected-model inspection. Source name/shape alone does not grant named contact. |
| Two reauthored east-quay seats | LD is authoring actual top−4cm skin, rotated outward face and actual owner RID, preserving guide coordinates/IDs | Require exact unit-yaw/no-shear frame, successful edge configuration, real mapped catches and finite native model/capsule positives/negatives before acceptance. Do not carry generic success through a rejected named fit. |
| `surface_audit._box_ledges` | Selected older labels may still publish a plain generic Line with authored cap offsets | Court seating can use visible cap/proxy dimensions beyond the native box. Inspect actual mesh/collision alignment; do not declare all caps authentic. |
| `surface_audit._commit_native_ledge` | Actual finite BoxShape top, explicit outward face and owner RID, `surface.native_box_top` | Preserve independent clear-interval screening and live finite admission. Semantic provider-owned bodies intentionally do not receive a second fallback edge across their exclusions. |
| Transition features, park rails/ledges, pond/cable, recording court | Explicit inspected crown/top sources when their supported frame checks pass | Keep individual source groups in inventory. A nonempty source string does not bypass live native crown or connected board sweeps. |

The player deliberately preserves compatibility admission in `_grind_candidate_supported`: an unverified guide selects generic `rail_grind`. Verified guides select the named style from actual entry direction/board heading, solve its geometry and check native clearance. An explicitly authenticated box edge cannot fall back after a rejected named fit. A verified guide without an exposed-edge datum can still fall back to generic Rail Grind when its neutral 50-50 chord/clearance solve fails; this must be inventoried separately from actual named-contact acceptance. The existing `GrindLine` documentation forbids silently certifying unknown legacy geometry. This compatibility contract is not evidence that generic presentation is polished.

## Confirmed new defect and bounded correction

The east-quay early-exit rider burial was **after the grind**, while natively standing/manualing just beyond the finite seat's centre ray. Its correction is documented in [MOTION-FIDELITY](MOTION-FIDELITY.md). It does not by itself prove grind contact. LD's separate semantic-seat authoring addresses the guide's previously generic contact model; neither correction changes the actual seat/guide geometry to hide a failed query.

## Runtime inventory and follow-up protocol

The read-only tool is `tools/grind_contact_audit.gd`:

```sh
./tools/run.sh --headless --audio-driver Dummy --script tools/grind_contact_audit.gd -- .local/grind-contact-audit.json
```

It creates ordinary Main with persistence disabled before tree entry, records every runtime guide's ID, source, verification flag, neutral generic-fallback eligibility, offsets, body-only profile, outward face, native RID count, actual surface-owner association and points, and reports duplicate IDs. It changes no contact metadata, pose, input, score or guide. Run with a clean import and a conservative source inventory/receipt before and after; retain exact command, engine output and source scope. The current development counts above do not supply the pending frozen JSON/source receipt.

Then perform a bounded actual-input inspection, preserving strict assertions:

1. Finish the two newly authenticated seat catches, exits and returns, including reversed travel and real native board/capsule clearance. Retain any rejection rather than lowering a guide or weakening a camera ray.
2. Pick representative remaining unverified thin-seat, broad planter/cap, counter and changing-grade beam families from the actual inventory. Rank observed board burial/hover, shoe separation, discontinuous turns and blocked approaches; do not label all generic guides defective by inference.
3. For each reproduced defect, retain the real mapped-input witness and actual rendered GLB component/finite owner measurements. Author support only from inspected native geometry. Test a clear positive plus broad-ledge/board-obstacle negatives, preserve historical IDs and ordinary approaches, then obtain independent QA and normal-speed visual review.
4. Keep unverified or visually unreviewed families explicitly open under FID-102/G01-06 until their individual evidence is complete. Source inspection and inventory are audit progress, not contact acceptance.

## Current bounded follow-up status

The real active cylindrical Main snapshot now passes4/0, recorded separately in
[capture-cylindrical-active-native](motion-fidelity-2026-11-07/capture-cylindrical-active-native/README.md).
It verifies observer metadata, not grind presentation. The first four-family
generic-contact observer attempt is rejected after a tooling reference to a
nonexistent Main bail counter; it supplies no generic-contact result. The repaired
private observer uses actual Skater `bailed`/`recovered` signals, perphysics
`bail_active`/`recovery_fade`, actual indexed GLB positions, finite native Box/Cylinder
geometry and fullprecision numeric records. It remains unparsed/unexecuted after
those corrections and needs a fresh current-source native epoch.

Its declared one-start airborne/momentum fixtures then use mapped Grind for24ticks
per representative seat, planter, counter and changing-grade bridge rail. It
records actual captured identity, component/native RID+shape, real vertex intrusion
over1mm, bounded signed/vertical hanger/tyre rays and completed-frame camera checks.
Those setup fixtures cannot establish an ordinary approach or wheel load, and a
convex hit alone does not prove actual material penetration. Saturated/unsupported
queries remain unknown. No family is accepted from a missing catch or an observer
exit code. Root queues the corrected bounded native audit after the active source
integration/contact work.

The subsequent fresh-current-source [native four-family epoch](motion-fidelity-2026-11-07/legacy-generic-native-01/README.md)
executes cleanly with803stable inputs and24physics samples per family. No actual
skateboard component overlap or bail is found, but last-eight public hanger gaps
are about55mm over native bench/planter/counter UPfaces and15.34–15.46mm signed
over the graded bridge. The native tyre ray distributions and missing-ray unknowns
are retained. This identifies a grounding follow-up rather than accepting generic
presentation. The raw camera field has a documented phase-label correction:
two initial counter rays hit the awning before the camera process update; this
does not certify a rendered ordinary-play obstruction. No runtime fix is included.
