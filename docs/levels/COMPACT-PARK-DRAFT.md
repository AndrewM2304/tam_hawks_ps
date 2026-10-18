# Compact park draft — DENSITY-02

18 October 2026. **Proposal only: not implemented, collision-certified, rendered or admitted.** The Clyde now passes bounded automated admission; this park document remains an unsurveyed proposal. This is the durable next-slice proposal under [LEVEL-DENSITY-NEXT](../planning/LEVEL-DENSITY-NEXT.md) and the [strict density review](STRICT-DENSITY-REVIEW.md); it changes no production source and no full backlog record. Do not begin park implementation until the Clyde checkpoint is tested, captured and pushed.

| Field | Contract |
|---|---|
| Existing task IDs / milestone | M03-005, M03-012, M03-014; M03-001/003 for a shared civic/station port seam; M02-008 and M06-004/007 for movement, performance and visual admission. This refines those records rather than replacing any of the 75 full tasks. |
| Owners | A05 layout/terrain; A04 skating compatibility; A01 shared coordinate contract/integration; A09 independent physical/input/render review. A08 verifies map presentation. |
| Priority / state | P0; **draft, dependencies open**. |
| Dependencies | Accepted/pushed DENSITY-01; a source-bound survey of the proposed new station mouth and existing civic mouth; agreed DENSITY-02/DENSITY-03 port contract before any dependent code. Human Mac/DualSense and fun gates remain honest open evidence gates, not recurring permission requests. |
| Goal | Attach useful park relief to the city, retain actual hip/S-bend/coping/summit, provide two distinct returnable skating lines and safe uphill/downhill access. Cut redundant reachable landscape/commuting surface before art. |
| Cost ceiling | Existing materials/textures only; 0 new texture bytes, 0 new unique material/shader resources, 0 lights, 0 per-frame world behavior. Net meshes, collision bodies/shapes, rail candidates and tree instances non-increasing unless an explicit measured exception passes. No new district, filler props, paid tool/API or failed backdrop activation. |

## A hard constraint the sketch targets missed

The current external mouths are station `(−145,2,0)` and civic `(−42,6,−122)`, **159.665 m apart in the ground plane**. If both external approaches are at most 35 m, their local-loop mouths remain at least 89.665 m apart. A closed loop visiting both must be at least 179.331 m even with zero width, no height and no useful turns. A 100–140 m principal loop with two 20–35 m approaches is therefore impossible while those two mouths stay fixed. These are elementary distance lower bounds, not measured driving times.

The source makes the diagonal shortcut worse: `_build_city` places the west Station Approach buildings at X−136/Z±26, with a rotated footprint approximatelyX−142…−130 andZ−41…−11 for the southern block. A line from the old station mouth diagonally toward the civic mouth runs through that building footprint. The present route correctly stays west near X−151. Do not cut through a facade, steepen a seam into a wall or leave an invisible supported shortcut merely to satisfy advisory dimensions.

**Recommendation:** coordinate a limited DENSITY-02/DENSITY-03 station-mouth migration, then build one compact park pocket. Retain a fixed-port fallback as a useful partial improvement if that new seam fails. Do not claim the fallback has solved mandatory city travel.

## Option A — recommended joint port migration

Use the existing station-to-civic climbing lane as the station approach to the park. This is a relocation of the existing park connection within the existing map, not an additional district. It requires opening a precise existing boundary and closing the obsolete west exit visibly. It has not been surveyed in the engine and is not yet a placement contract.

| Piece | Current | Proposed anchor / bounded purpose |
|---|---|---|
| Station mouth | `KelvingroveWestPort`, X−130→−145/Y2/Z0, framed by the two Station Approach buildings. | Candidate mouth through the west side of existing `NorthClimbingLane`, near **`(−94,3.625,−68)`**. Existing lane centre is X−88; its source-linear board height at Z−68 is 3.625. Survey the actual sampled triangle height. Open a matched approximately10 m corridor in `ClimbingStreetOuterBoundary` at X−93.8, centredZ−68, retaining the remaining wall. |
| Station external approach |84.36 m route to the current park loop. | Candidate **`(−94,3.625,−68) → (−100,5,−80) → (−100,6,−96)`**, about29.52 m as straight3D segments. Keep a real 10 m supported approach unless the surveyed seam requires a justified narrower opening. The trip from the station arena along the existing climbing lane still exists and must be judged separately; this does not make total city-to-park travel 29.52 m. |
| Civic mouth |`(−42,6,−122)` at the end of `KelvingroveCivicPort`. | Retain that anchor. Candidate **`(−42,6,−122) → (−72,6,−122)`**,30 m, to the local lower loop. Remove the rest of the 103.04 m promenade and its obsolete broad embankment. |
| Active pocket |Rolling landscapeX−255…−140/Z−225…−60 plus two broad approach embankments. | Sketch **X−132…−67/Z−141…−86**, plus only the two actual approach ribbons/shoulders. This is a maximum planning envelope to shape around useful paths, not a rectangular floor to fill. Keep both city exits open. |
| Lower junction/checkpoint |Loop start`(−155,6,−82)`; checkpoint`(−155,6.8,−82)`. | Lower junction **`(−100,6,−96)`**, checkpoint provisionallyY6.8 at that junction, adjusted only to real clear support. It joins the station access, main climb/descent and hip return. |
| S-bend/fork |Fork near`(−208,11,−126)`; two authored S-bend rails 4.035/6.015 m. | Move the **native fork/curve sections by ΔX+94, ΔZ+11**, noY/scale change, to fork **`(−114,11,−115)`**. Preserve the actual sampled ribbon, grade, rails and separation; fit joins around these pieces. Do not globally rebake a squashed path and assume its rail curvature survives. |
| Native cutback hip |Three-point ribbon`(−224,8,−91) → (−226,9.1,−84) → (−220,8.4,−78)`, width4.5. | Rigid **ΔX+108, ΔZ−14** gives **`(−116,8,−105) → (−118,9.1,−98) → (−112,8.4,−92)`**. This is the park's existing shallow shaped hip, not the Clyde's radius4/35° curved bank. Keep its original dimensions/grade and real4.5 m ribbon. |
| Hip ledge |`kelvingrove_cutback_ledge`, endpoints`(−227.2,9.5,−84)` /`(−221.2,8.8,−78)`. | Same translation: **`(−119.2,9.5,−98)` /`(−113.2,8.8,−92)`**,8.514 m native length and stable authored ID. Preserve its physical relationship to the hip and clear landing. |
| Summit |NativeY17 with a detached coping/view terrace reached by a spur. | Candidate summit **`(−111,17,−133)`**. Preserve real 6→17 m height difference; make the summit part of a continuous supported descent, with the small terrace optional beside it. |
| View terrace/coping |18×5 m at X−179…−161/Z−185…−180, Y17; coping13 m at Z−184/Y17.4. | Candidate terrace **X−129…−111/Z−141…−133**,Y17, minimum native 18 m length, slightly deeper for real run-up/turn/camera clearance. Coping retains its 13 m length/Y17.4, provisionally **X−127…−114/Z−140**. This limited depth is functional clearance, not a reason to retain surrounding grass. |
| Pavilion |Native centre`(−174,17,−182.5)`; solid posts/roof, bench. | Reposition intact on the retained terrace, provisional centre **`(−124,17,−136)`**. Source positions put original posts directly beside/on the original coping line; survey actual capsule clearance rather than copying that conflict. ProposedZ separates posts from coping by~2.5 m. Keep the roof's actual collision, sightline and view purpose. Remove it if no placement earns the required clearance within the pocket. |

The native S-bend recipe is concrete: move all related source vertices/rails by the same transform. For reference, the translated centre samples beneath the first rail begin near`(−108.0538,9.8367,−102.6048)`, through`(−109.2120,10.1749,−104.2118)` to`(−110.2994,10.5954,−105.8674)`; the second runs near`(−113.5463,11,−120.8579)` through`(−113.0115,11.0967,−122.7629)`, `(−112.3485,11.4122,−124.6281)`, `(−111.5817,11.8578,−126.4532)`. These come from the actual source-bound rail points with the authored X+3.3 / Y−0.55 centre offset, not a survey of the future collider. Keep the full native cross-sections and derive physical joins, not just these centre samples.

### Principal path sketch and honest size

Use the following control relationships, preserving the native curve sections between them:

```text
Lower junction (−100,6,−96)
→ native first S-bend section
→ fork (−114,11,−115)
→ native second S-bend section
→ upper switchback shelf (−124,14,−135)
→ summit (−111,17,−133)
→ descent (−97,14,−130)
→ descent (−83,10,−126)
→ civic/lower mouth (−72,6,−122)
→ lower return (−85,6,−112)
→ lower junction (−100,6,−96)
```

The straight3D polyline using the listed native samples is **146.03 m** before final curve baking/cross-sections. This deliberately exceeds the advisory140 m ceiling to retain the actual native curves,11 m useful height change and a continuous descent. The steepest sketched descent is~34.2% grade, about18.9°, before smoothing. That is a test obligation, not novice safety certification. A~137 m alternative forced a much steeper direct summit-to-civic descent; reject that paper saving. Do not shorten run-up, remove a landing shelf or create blind corners merely to print 140 m. Measure final actual path/driver travel after regrading; bounds/point arithmetic alone cannot admit the candidate.

The separate cutback can run **fork `(−114,11,−115) → (−124,10,−110) → (−123,8,−103) → native hip/ledge → lower junction`**, with an independent shallow supported bypass alongside the optional hip. Its branch and landing have a purpose, unlike a second perimeter commute. Verify crossing ribbons do not overlap at differentY, expose a kerb or erase native selected curbs at the merge.

### Two genuinely different returnable lines

1. **Fork/hip figure-eight:** native S-bend capture/manual through the fork → choose the cutback → native hip/ledge capture or air → clear lower landing/manual near the junction → bank and climb back to the fork along the main path. Preserve a no-jump hip bypass. Demonstrate the actual captured IDs, tricks, landing, positive bank and ordinary-input return; a route-following lap without a capture does not prove this line.
2. **Summit/descent:** main climb → optional 13 m terrace coping → pop/grab and land on the real retained terrace/exit shelf → supported descent using a selected granite curb/manual choice → bank near the lower mouth → either city exit or continuous uphill return to the summit. This is a high-to-low line with a different decision/risk from the hip branch. It must not require a second long out-and-back viewpoint spur or a launch over a fence.

These are bankable skating circuits, not claims that a whole uphill return stays one unbroken combo. Native tap/held Ollie airtime and gravity stay unchanged. Do not invent a 10–15 m flat-air gap between features; the existing measured tap/charged equal-height travel at 10 m/s is about 4.8/6.8 m. Landings must show the next choice at normal chase height. Manual balance is a useful link, not a justification for every long empty stretch.

## Option B — fixed-port staged fallback

If the station climbing-lane seam cannot pass support/camera/boundary review, retain both current city mouths and build a smaller **local** hill loop in the current park. A concrete source-compatible sketch keeps local start`(−155,6,−82)`, moves the native fork by ΔX+10/Z+13 to`(−198,11,−113)`, retains its native curve pieces, climbs through`(−199,14,−138)` to summit`(−180,17,−151)`, descends via`(−159,15,−145)` to civic-side lower junction`(−145,6,−125)`, then`(−145,6,−104)` and back to the start. It occupies approximatelyX−214…−139/Z−166…−76, with only useful shoulders retained. Refit the hip/terrace beside that loop, preserving their native dimensions. Exact native curve joins raise the illustrative path from roughly 194 m toward 200 m; no 170–190 m acceptance claim is made.

This can remove unused outer grass and shorten the 252.42 m local loop, but **it retains roughly 84/103 m access commutes** unless the city mouths later move. Keep those as explicit unresolved P0 density failures. It is a partial playable checkpoint, not complete DENSITY-02 and not a way to claim the owner-approved compact attached pocket has been delivered. The recommendation remains Option A after a real seam survey.

## Consumer and failure inventory

| Consumer / source | Required migration and likely failure |
|---|---|
| `outdoor_routes.gd`: `_park_connector`, `_george_connector`, `_park_path`, `_park_cutback`, four published park routes | Rebuild world points, width, routes and all support snapshots from the agreed coordinates. Preserve useful logical IDs, but old points/counts are not sacred. Current branch-apron blend hardcodes forkX−208/Z−126; move the shared level fork contract or both branches develop different lips. |
| `PARK`, `PARK_LANDSCAPE`, `_surfaces`, `_local_ground`, `get_district_id` | Replace old rectangles/ownership with final exact retained footprints. The current district test only recognizes old terrain west ofX−140; Option A would otherwise report city names throughout the relocated park. No support/query may survive on removed outer ground. |
| `_park_height`, `_central_bank_height`, `_george_bank_height` | Reauthor shared physical height/triangle queries, woodland/summit flattening, support skirts and approach grades. OldY−0.25/Y−0.35 ground recesses can create the same real lip that blocked the Clyde circuit. Make runouts/joins genuinely flush and trim duplicate displays while retaining truthful support; do not offset a mesh to conceal an overlap. |
| `Surface.terrain`, `strip`, `grid_height`, `strip_height`, `smooth_points` | Exact sampled triangle support remains authoritative. Re-baked tangent overshoot, narrow inside corners and overlapping graded strips can create wrong-height jumps even if centreline queries pass. Test both sides, shared diagonals and cap edges. Preserve native curve pieces rather than allowing global smoothing to alter them silently. |
| Hip ribbon/ledge, S-bend authoring and `_path_border` | Relocate native visible/collision/query geometry and stable authored rails together. The S-bend selection currently hardcodesX<−201/Z−139…−113; it would publish no moved rails unless reauthored semantically. Branch proximity6 m can accidentally remove every curb in a compressed merge. Regenerate only supported physical edges, not ghost rails. |
| Terrace, spur and `_park_pavilion` | Move top support, coping, roofs/posts/bench together. Check original coping/post coincidence; keep real charge/landing and turning space under the roof. Skater head/camera clearance matters as well as board rays. Native terrace height17 makes an ordinary ground-level outer fence insufficient if its baseline is wrong. |
| Tree generation, `Vegetation`, `RenderBudget`, architecture batching | Remove old grid placements outside retained scenery and recompute grounded retained positions. Trees are a few framing masses, not filler for unused acres. Keep existing batching/resources, current tree split experimentsOFF and matching batch AABBs; compressing the city/park can expose more geometry together. |
| `glasgow_square.gd` port streets/routes and `ClimbingStreetOuterBoundary` | Option A is an atomic shared edit: actual source-linear road height, visible curb/wall, matched collider opening, road cap, station route identity and closed obsolete west mouth. Do not delete a whole boundary to make one seam work or close the existing Merchant Court return at X−88/Z−70. Station canopy/platform/career routes stay intact. |
| CityArt civic background facades and Station Approach buildings | Survey complete physical and art footprints near X−105/−70/Z−149 and the old west exit. Option A's summit/view terrace approaches these masses; avoid buried terrain, camera-through-wall turns or misleading roofs. Refit/remove an obsolete mass only within its explicit coordinate contract. |
| `city_backdrop.gd` protected ports, park skirts/split Z−142 and `_park_backdrop_height` | Current preview bounds/footing assertions assume old park edges and old two city mouths. Update diagnostic exclusions if port geometry changes; keep all rejected backdropsOFF. A preview must not fabricate support or hide missing edges. |
| Checkpoints, six district visit markers, `route_map.gd`, Main pickup/checkpoint consumers | Move the actual park checkpoint and maintain `kelvingrove` identity. Publish both return branches and the real city connections: Clyde's failed first map demonstrates why a safe route must not appear as a dead end. Keep all ten career goals/save IDs and three side acts. No park water hazard is added; Clyde recovery remains unchanged. |
| Generic recovery and perimeter containment | Park falls currently eventually hit generic Y−8/outside-world recovery, not the Clyde's prompt bank return. Close dry edges physically/visibly before removed terrain, including high summit/coping departures and camera views over walls. Do not add invisible catch ground. Prove worst ordinary/charged exits, honest fall behavior and return support. |
| Tests/tools/fixtures | Migrate actual purposes in `topography_tests`, `support_query_tests`, `playability_regression_tests`, route/career tests, `support_audit`, area/moving/performance/render probes, normal playability and level-design captures. Hardcoded old hip, pavilion roof, woodland taper and north-horizon positions become historical, not passing evidence for a different park. Never retain obsolete terrain to satisfy them. |

## Required acceptance and durable work order

| Subtask under existing IDs | Owner / priority / dependency | Acceptance / test strategy |
|---|---|---|
| DENSITY-02A: settle the shared port contract | A01+A05+A04, P0; DENSITY-01 accepted/pushed | Engine survey actual old/new mouth collider/art/camera volumes. Publish exact shared placement table before production edits. Select Option A only if the source-derived seam survives real support/headroom checks; record Option B honestly if not. Preserve all 75 backlog bodies. |
| DENSITY-02B: coherent terrain/feature move | A05+A04, P0;02A | Move native curve/hip/coping groups and reshape only joins/outer terrain. Two real city exits, continuous no-jump uphill/downhill access and hip bypass, usable summit/runouts, truthful closed outer ground. No source commit with a missing mandatory seam. Focused rays/capsule checks include width offsets, diagonal/cap seams, high shelves and boundary outward attempts. |
| DENSITY-02C: real line/margin proof | A09 independently, P0;02B frozen | Ordinary production inputs after explicit initial fixtures; no per-tick position/yaw/speed setting. Complete both distinct action sequences with exact captured rail IDs, real air/landings/positive banks and ordinary-input returns. Drive both ways from each city mouth and the bypass. Include early/late steering, missed coping, weak/long charge, braking descent and wrong branch. A perfect driver cannot close discovery/human fun. |
| DENSITY-02D: composition/performance admission | A09+A05+A08, P0; frozen02B/C | Actual chase entry/turn/exit, summit, hip/S-bend, miss/recovery and map captures; inspect all changed perimeter corners and newly shared city sightlines. Require visible skater/board, next action/run-up, no floating area captions, no coplanar flicker, no inviting dry-void exits and no map spur where a real return exists. Frozen baseline/candidate/baseline, sole renderer, matched preset/resolution/input, draws/primitives/memory and p50/p95/p99/long-frame gate. Net smaller terrain is not an FPS claim; 220 m skyline and offscreen gameplay remain. |
| DENSITY-02E: regression/checkpoint | A01+A09, P0;02B/C/D | Run required `tools/check.sh` on final frozen production; real career/three-side-act regression, source/input hashes and retained failed attempts. Update STATUS/task packet/resume with exact commands/results/open limits; commit/push playable checkpoint before another arena moves. Mac/DualSense, ten-minute 1080p target timing and owner fun stay open until actually tested. |

At ordinary 8–10 m/s, about 3 seconds without a skating/route decision triggers strict review. Legitimate charge, landing, recovery and a deliberate summit reveal can justify quiet space; a scenic road commute cannot be renamed a combo loop. Every retained apron gets a named skating/access/landing/return/composition purpose, and each failed route or view remains saved rather than quietly overwritten.

**Resume:** finish and preserve DENSITY-01 first. Then survey the proposed NorthClimbingLane mouth around X−94/Z−68, the unchanged civic mouth and the summit-facing background masses. Choose and record the shared port contract, inventory the native curve/hip/terrace transforms, and only then implement one park slice. This document is preparation, not admission; no park source, collider, route, visual asset, test or 75-task body was changed to produce it.
