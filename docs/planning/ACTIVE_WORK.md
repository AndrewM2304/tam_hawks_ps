# P0 ordinary-play repair — 17 October 2026

## Personal soundtrack addition — 25 October 2026

The owner requests a local Apple Music playlist soundtrack for personal Mac play. **M05-008** adds opt-in Music.app control, shuffle/autoplay and live pause-menu metadata/artwork/skip. [ADR-014](../architecture/decisions/ADR-014-personal-mac-soundtrack.md) defines this isolated audio/UI addition. It does not reopen map expansion or replace the existing physics/art/hardware acceptance gates. Root owns main/export/docs integration; audio and UI specialists own the bridge and presentation. Current results and remaining target-Mac steps are in STATUS.

## Latest owner direction — gameplay hardening before area expansion

The owner now says the latest Mac build launches without errors, but the rider physics still keep rolling too quickly, shaders look messy and the UI feels buggy. Pause new districts/areas. Current work stays on this map: stable Compatibility-renderer grass/water shaders, legible HUD feedback, signed street speed and gravity response on the existing hills. Preserve the ten career goals, challenge IDs and working encounters. The first repaired-source render set is [playability-repair](../testing/screenshots/playability-repair/README.md); it is Linux/llvmpipe evidence, so final Mac feel and visual review remain open. The bounded changes and exact regression outcome are recorded in STATUS/QE. No spending or new dependencies.

At the start of this repair, the owner reported **an apparent first-person view with no visible skater, skating physics that did not deliver the intended arcade feel, and falling through the level**. Those were real core-playability failures and earlier scripted passes did not rebut them. The cold-import, wall-camera and four floor cases are now bounded and covered below; the owner's later steering continues the physics/presentation work on the current map. Treat human Mac response as the final judge, and do not infer that a Linux capture settles that gate.

Retain all **75 full task IDs**, the ten career/save identities, three implemented side acts and the no-spend rule. Continue authorized local investigation and repair without routine permission requests. No purchases, paid API, hosted CI, infrastructure, new engine or unattended work is authorized by this slice.

## Baseline and evidence boundary

The prior committed handoff is **`6ff294a7423dc581632a361390eb32830e9787c6`**, with exported runtime **`00da63a29990c0839cf15d4c9a34edc2fc167122`**. Its **1,155 scripted checks**, 44 authored routes, 22 selected screenshots and native source/archive/startup audits remain valid only for what they actually exercised. Many route drivers directly aimed the grounded heading; static captures set supported starting positions and some used authored cameras. A short successful process launch did not demonstrate ordinary gameplay after menu selection. These limitations explain why that evidence cannot certify natural control, continuous rider visibility or all walkable-looking ground.

Keep those source-bound logs, images, packages and manifests intact. The focused 44/0 and cold-source174-input checks pass. Current `./tools/check.sh` is **1,264/0** and the 19-frame source-stable Compatibility capture has zero failures. The formerly early-banking reverse Exchange→Barras combo now connects under signed slope gravity. Exact current outcomes are in STATUS/QE; the lead's [PLAYABILITY-REPAIR-BRIEF](../levels/PLAYABILITY-REPAIR-BRIEF.md) records the original bounds. Old native artifacts and captures remain historical.

## Reproduced before evidence and current repair acceptance

Independent QE reports the following baseline findings; exact traces and source identities are retained in `docs/testing/PLAYABILITY-REPAIR.md` and `tests/playability_regression_tests.gd`:

| Scenario | Actual finding and limit |
|---|---|
| Imported Linux normal main/title/free start | The normal start works and visual rigs exist; natural push/left/right input keeps the rider framed in the open court. This does not reproduce every owner condition or disprove failures elsewhere. |
| Wall-side camera fixture near **(−34,1.25,4)**, facing east | Camera distance collapses to about **1.04 m** and crops the full rider in **45 of 60 sampled frames**. Earlier chest-point visibility rays missed this; new acceptance must include head, feet and board plus camera volume/path clearance. Initial fixture placement is diagnostic, not an ordinary full-route proof. |
| Four north/south floor departures | Starting near **X±12 / Z−42** facing north and **X±12 / Z42** facing south, ordinary push input causes actual fall/bail. Route-centre success did not cover these apparent openings. Geometry must repair or visibly close the mouths, then QE repeats both directions and lateral departures. |
| Cold source without generated imports | The owner’s Mac source-launch logs and root’s exact cold-source reproduction show `GrindLine` not found plus four missing imported anatomy OBJ resources when `.godot` is absent. `Anatomy.new` then fails, leaving rider/busker construction incomplete. Root is adding automatic editor import before ordinary play in `tools/run.sh`, preserving the same user command. This confirms a source-preparation failure; it is not evidence of a Mac renderer bug or resolution of the separate wall-camera defect. |

Root owns launcher/cold-copy repair; QE owns independent full visual initialization, natural-input framing and gap regressions. The owner command remains:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/run.sh
```

Imported Linux normal-title and cold-source checks remain valid bounded evidence. Geometry now supports the four north/south closes, bringing runtime routes from 44 to **48**; the latest full run also exercises the broad topography, park hill circuit, bridge recovery, boundaries and reverse travel. The [source-bound SKATE-RESPONSE report](../testing/SKATE-RESPONSE.md) retains the old 15→12.740m/s coast baseline and documents the new 0.28g slope/rollback response, **32/0 helper** and **23/0 takeoff** results. Current ordinary coasting reaches 4.95m/s after 3s on the capture route, then stops within the observed 9s/45.55m total. The focused normal-title module passes44/0; fresh-source launch passes174 unchanged inputs. Full `./tools/check.sh` now passes **1,264/0**, and the source-stable normal-scene render passes **19/0**. The formerly failing reverse Exchange→Barras combo banks connected. These are Linux/scripted results; Mac feel and final art/UI acceptance remain open.

## Disjoint ownership and existing tickets

| Owner | Assigned files / responsibility | Ticket and required handoff |
|---|---|---|
| A01 root / A04 gameplay, with camera helper owned by art | Launcher auto-import, camera adapter, player, main and UI integration; normal-main reproduction; freeze and final source/native receipts | **M00-002 / M01-002/003/005**, M06-003, M07-001: identify actual camera/state/input causes, implement bounded repairs and retain before/after natural-input traces. |
| A05 geometry/world | Level collision, off-route terrain joins and honest reachable boundaries | **M03-002/005**, M03-007: audit visible close mouths and lateral departures, repair matched mesh/support/collision or explicitly block an intentional boundary; publish exact tested bounds. |
| A09 independent QE | New ordinary-play tests/evidence; independently replay movement, camera, off-route and recovery failures | **M01-007**, M02-008, M03-005, M06-006, M07-001: use actual mapped inputs with no per-tick heading/position/speed/state injection; preserve failed traces and report exact limits. |
| A02 lead design | New PLAYABILITY-REPAIR-BRIEF and natural-play acceptance criteria | Keep the owner’s complaint central; distinguish a useful original arcade response from unimplemented vert/wallride features; inspect normal gameplay evidence. |
| A04 physics review | Read-only review of movement/contact/camera assumptions and useful inspected free-source patterns | Report concrete findings and bounded adaptation candidates to root; no competing player implementation. |
| A02 planning | **BACKLOG, ACTIVE_WORK, RESUME only initially** | Preserve 75 complete records, promote repair priority, record before evidence and exact next actions. Capture-tool ownership is deferred until root assigns it; do not edit fingerprinted tools while other probes run. |

## Repair acceptance contracts

1. **Ordinary main and third-person visibility — M01-005 / M06-003.** Launch the real main scene through normal title/mode selection, with fresh isolated settings and a retained-settings case. The rider and board must be visible at gameplay start, after restart, through push/coast/brake, broad left/right turns, an ollie, wall/corner approach and reversal. Inspect the active production camera, actual transform/distance and rendered framing; no inspection camera or helper that moves the camera can stand in for the fix. Preserve reduced-motion settings and pause/menu behavior. A visible body at a single posed fixture is insufficient.
2. **Natural mapped-input movement — M01-002/003 / M02-008.** From a real new run, use push, steer, brake and fresh ollie inputs to complete a simple learning circuit, coast, turn both ways, deliberately miss a line and recover. No per-tick heading, position, speed or score assignment is allowed in this new evidence. Record acceleration, coast/brake behavior, turning response and outgoing/landing velocity rather than describing subjective feel as passed from counts. Retain the prior collision-adjusted takeoff/momentum fixes and score/landing rules. Human replay must still judge responsiveness and fun; do not claim exact commercial-game parity or add vert to hide a street-control problem.
3. **Off-route ground and boundaries — M03-002/005.** Cover visible close mouths, court sides, diagonal approaches, outer seams and lateral departures away from route centre lines. Sample actual support/capsule clearance and physically traverse the reachable joins in both directions. Every ordinary rideable-looking surface must have corresponding support, or a deliberate boundary must be visibly and physically clear. Intentional water/gap hazards remain identifiable. A global invisible catch slab or only teleporting after a fall is not a repair for missing apparent ground.
4. **Recovery and preserved rules.** Unexpected loss of support and intentional hazards must lead to one bounded, supported recovery with a readable result, not an endless fall or repeated bail loop. Preserve already banked score, drop only the active combo, reset gap/encounter transient state, and keep restart at its documented spawn. Do not silently move canonical goals, alter saves, remove working routes or disable the owner’s landmarks to simplify tests.
5. **Evidence and freeze.** First retain normal-main before traces/images and explicit failing scenarios; use focused checks while owners repair their disjoint files. Root runs the full ordinary suite only after a shared source freeze. Then capture a **new playability recipe** with ordinary moving input, worst camera frames and repaired collision/boundary views; do not substitute an unchanged Exchange 22-view refresh. If runtime changes, rebuild/audit the native candidate with a bounded normal-play smoke rather than process startup alone. Keep hashes, build identity and declared input/camera/clock limits. Human Mac/controller/fun acceptance stays open until actually replayed.

## First off-route investigation bounds

Lead source inspection identifies likely uncovered city edges for geometry/QE to confirm against real collision:

- North gallery strips **X−15…−9 and X9…15 / Z−56…−42**, plus the rear strip **X−9…9 / Z−56…−54**.
- South retail gaps in the same lateral X ranges at **Z42…54**.
- Ordinary lateral and diagonal exits around each corresponding mouth, including both ends and joins back to established floors.

The four north/south side mouths have reproduced push-only falls and geometry has implemented compact closes; rear/outer bounds and the broader map still require explicit coverage. These extents are not proof of a complete map audit. The lead’s broader dry-edge ray audit also finds unsupported station/market edges, civic frontage openings, park perimeter and quay ends. Its [wider boundary proposal](../levels/PLAYABILITY-REPAIR-BRIEF.md#wider-dry-edge-boundary-proposal) preserves actual port openings and the union of park/embankment terrain. Support-sampled visible ironwork/masonry, closed dry edges and open intended river hazards remain pending owner implementation and independent checks; four closes alone cannot close M03-005. Prefer compact supported connections with closed foundations and tested exits, or honest physical/visible boundaries where a connection is not intended. Protect X±22 streets, H/cone, the new gallery ledge, station overlap/ports, all goal markers, market delivery paths and Clyde/park hazards. The prior side-strip art proposal now serves collision/playability repair first; decorative expansion remains deferred.

## Resume if interrupted

Read AGENTS, STATUS, this file, the affected ticket records, interfaces and the lead repair brief. Inspect `git status --short` and preserve all in-progress files. Determine which owner has a reproduction, which fix is implemented, and which independent replay is still missing; do not restart from an older art-first plan or present an old native package as repaired.

Next: preserve the current code checkpoint and investigate the one reverse Exchange→Barras combo failure without weakening its connection assertion or changing scoring to silence it. Run/review the normal19-frame gameplay capture and the independent park/boundary/water probe; after any source changes, rerun the suite and refresh hashes. Build/audit the new native source only after those results. The owner’s Mac retry, physical controller feel, final art, listening and performance remain human gates.

After these defects are resolved and replayed, resume broader M05-001/M06-007 place/art work. M02-011 remains **Planned** with the completed [TRANSITION-SKATING](../research/TRANSITION-SKATING.md) research and isolated `transition_lab.gd` first edit; it does not supersede ordinary-play repair. Wallride, reversible-route, traffic and the two future encounters keep their existing Planned records. Target-Mac/DualSense/listening/frame-time and final realistic-art gates remain distinct from automated evidence.
