# Full Release 1 task backlog

Title: **Tam Hawks Pro Skater**. Baseline date: 17 October 2026. This is the durable local source of task truth; these entries are not claims that GitHub issues have been published. Latest implementation and command evidence is in [STATUS](../STATUS.md). Product scope maps through [requirements](../product/requirements.md).

There are **75 tickets** across eight dependency-based milestones: the original 54 task records, eight terrain/character redesign groups, five nonlinear-layout/local-encounter groups, four classic-mechanics continuation tasks and four later local-encounter prototypes added on 17 October 2026. M00–M03 initially follow the supplied document. Its text stops after M03; **M04–M07 are a proposed continuation derived from the document's complete Release 1 scope**, not supplied missing text. The later work is recorded in [ADR-007](../architecture/decisions/ADR-007-authored-glasgow-terrain-redesign.md) and [ADR-008](../architecture/decisions/ADR-008-nonlinear-glasgow-playground-and-local-encounters.md). The owner has authorized implementation of all remaining work within the no-spend constraint. “Proposed continuation” identifies the roadmap text’s source, not a requirement to seek routine permission before those tasks. Nothing below implies unattended development or paid work.

## How to use this backlog

- Priorities: **P0** blocks a core milestone or release; **P1** is required work that can follow its prerequisites. The additional **P2** feature prototypes and **P3** feasibility assessment explicitly record later classic-mechanics work; they are not claimed as delivered features or hidden inside the current route/encounter slice. No original release feature becomes optional through this extension.
- Statuses: Planned → Ready → In progress → QE review → Done. Blocked records the missing dependency and responsible role. Move to Done only when acceptance evidence is linked; update STATUS at the same time.
- Owners are logical roles: A01 orchestration, A02 product, A03 research/licences, A04 gameplay, A05 world/art, A06 missions/progression, A07 audio/narrative, A08 UI/UX, A09 independent QE. Owner = the human owner when a hardware/creative gate requires them.
- Dependency ranges include every task between the listed IDs. The owner explicitly authorizes independent implementation, research, tests and corrections while earlier human gates are pending. Continue that work without routine permission stops; dependent milestone acceptance still requires its actual evidence.
- No purchases, billing changes, paid APIs, hosted CI, infrastructure provisioning or unattended agent loops. Use local checks and original or compatible free licensed assets. Keep the no-cost voice and macOS constraints visible.
- Before pausing, record exact changes/results/defects and the next concrete action in STATUS. [Resume instructions](RESUME.md) explain how to restart without chat history.

## Milestone map

| Milestone | Source | Outcome |
|---|---|---|
| M00 | Supplied roadmap | Project foundation |
| M01 | Supplied roadmap | Skating proof of concept |
| M02 | Supplied roadmap | Complete trick and combo system |
| M03 | Supplied roadmap | Glasgow grey-box |
| M04 | Proposed continuation | Missions and progression |
| M05 | Proposed continuation | Art, audio and ambient characters |
| M06 | Proposed continuation | UX, hardware and performance |
| M07 | Proposed continuation | Release readiness and delivery |

## Current acceptance boundary

M00 foundation and the recorded momentum/reuse/specification work are complete. The previous cleanup implemented grinds, manuals, reverts, a 0.35-second combo continuation window, specials, named gaps, a connected four-district world, ten career goals, local saves/unlocks, original environment/rider art, synthesized audio with licensed local speech, settings and input remapping. Implemented systems remain in **QE review** where integration, controller or acceptance work is outstanding; the environment/rider presentation and final cleanup remain **In progress**.

**Active redesign:** the owner subsequently requested recognisable Glasgow-inspired skating terrain with meaningful elevation, a fountain grind, a Clyde jump, hilly grassy Kelvingrove and an adult skater. [DESIGN-BRIEF](../levels/DESIGN-BRIEF.md) supplies authored route criteria and agreed ports/heights. M03-008–M03-012, M05-006, M06-008 and M07-006 track implementation. This explicitly authorizes revising old flat collision geometry; it does not permit silently changing the ten career goals or saved identities. Four career districts plus two exploration areas require fresh physical and rendered evidence. The previous **778 checks**, old career-route timings and old four-view performance captures are historical baselines, not a pass for the new source.

**Additional owner direction:** M03-013/M03-014 audit and improve the nonlinear playground using inspected principles from the named San Francisco/London/Los Angeles/School reference levels. M04-007/M05-007 add an optional busker challenge and original fictional local characters/cultural humour. M07-007 verifies those changes alongside the unfinished M07-006 capture/export handoff. The ordinary **871 passed / 0 failed** redesign checkpoint predates later outdoor visual corrections and this extension; it does not certify untested new geometry or encounters. Audit suggestions and intended rewards are not claimed as implemented.

**Current verified checkpoint:** the final ordinary `./tools/check.sh` passed **955 checks, 0 failures, exit 0**, with a clean import/error scan. The corrected 21-frame capture set and refreshed 222-frame rider motion are source-stable. Native package/export smoke and the final root handoff remain in progress; real hardware, human fun/listening and final art are still open. Full logs: [suite](../testing/logs/glasgow-nonlinear-final.log) and [import](../testing/logs/glasgow-nonlinear-import.log).

The latest integrated count, rendered evidence and package source identity are recorded in STATUS/QE/EXPORT. The second cleanup adds verified CC0 materials, skinned clothing, UI feedback/navigation fixes, physical surface audio, a continuous all-ten-goal route and reusable rendered profiling. Dedicated evidence includes matched world views, rider actions and UI stress/normal startup. Native Linux/macOS packaging audits scene, voice, texture and provenance resources; actual Mac launch remains open.

No physical DualSense, target-Mac launch/performance, human listening, subjective skating feel or final realistic/fun visual acceptance is claimed. The supplied first-release scope remains intact, including voiced NPC reactions and the mandatory final art/UI cleanup. Static bystanders, synthesized speech and procedural architectural detail are implemented first passes, not automatically the finished quality target.

## Remaining acceptance and reference work

| Tickets / accountable roles | Concrete next evidence or work | Current boundary |
|---|---|---|
| M03-008–012, M05-006, M06-008, M07-006 — A01/A02/A04/A05/A08/A09 | Implement/verify graded core terraces, fountain coping, Clyde transfer/recovery, hilly park connections, adult anatomy and the six-area runtime map; rerun the ten-goal career route and capture real terrain/rider/menu evidence. | Owner-authorized redesign is in progress. Preserve canonical career/save IDs; do not reuse the old 778-check result as new-geometry acceptance. |
| M03-013/014, M04-007, M05-007, M07-007 — A02/A03/A05/A06/A07/A09 | Finish inspected reference audit; implement supported alternate paths/cross-links and original local encounters; physically verify new routes and challenge scoring; refresh map/NPC images and final candidate evidence. | New authorized work is in progress. Keep proposals separate from source changes and preserve all previous unfinished release checks. |
| M02-011/012/013, M03-015 — A04/A05/A02/A09 | After the current candidate is verified, prototype transition/vert (P1), wallride/wallie and a reversible route event (P2), and assess skitch/traffic value (P3). | These mechanics are not implemented by the low 35° curved bank. Their bounded prototypes must not displace final verification/export of the accepted current slice. |
| M04-008–011 — A06/A07/A05/A09 | Prototype the original foam-cone river stunt, mechanical-cat coping sequence, market parcel line and park circuit with visible payoffs and physical success/failure evidence. | Planned continuation ideas, not enabled missions or new canonical career requirements. Finish the implemented busker/candidate first. |
| M01-007, M02-008 — Owner + A09/A04 | Play a real Mac with wired and Bluetooth DualSense; perform air→manual→air, rail exit, revert links, both specials, pause/restart, then record sensitivity, timing, camera comfort and replay appeal. | Human feel/controller gates remain open. Independent coding and regressions continue. |
| M03-006, M03-007 — A03/A05 | In a fresh environment using saved network settings, retry the recorded official/map URLs; inspect current street/corner/frontage relationships, dates and at least three verified boundary anchors per district, then replace unsurveyed shop edges. | Current proxy HTTP 403 remains a reference-access blocker. Do not claim Street View/current frontage inspection from historical address data. |
| M03-005, M04-003, M04-006 — A05/A06/A09 + Owner | Skate the complete four-district circuit, every authored gap/secret and all ten goals; collect novice/intermediate/experienced run scores to tune provisional 1,000/5,000/15,000 and 3,000-combo thresholds. | Collision/event tests and implementation exist; full human traversal/discoverability/balance evidence is still needed. |
| M05-003–005 — A07/A09 + listener | Listen to roll/grind/impacts, district transitions and all three captioned barks using speakers/headphones; check mute, overlap, intelligibility and fatigue. | Generated waveforms/event contracts passed local checks; no human listening certification. |
| M05-001/002, M06-007 — A05/A08/A09 + Owner | Continue material/facade/rider variation, inspect every trick in motion, remove remaining placeholders and obtain matched district/UI captures plus owner visual feedback. | The first art pass is a visible improvement; stylized repetition, unsurveyed shopfronts and final polish remain open. |
| M06-001/003/004/005/006 — A04/A08/A09 + Owner | Verify real reconnect/remapping, UI scale/captions/comfort, fresh app launch/save reload and a ten-minute 1080p route on a declared Apple Silicon baseline with frame-time metrics. | Synthetic input and Linux rendering do not certify physical input, Mac launch or 60 fps. |
| M07-001–005 — A01/A03/A09 | Freeze and test a candidate, generate/inspect local artifacts and notices, record checksums/launch results, complete the release checklist and player instructions. | Template/preset preparation is complete; final artifact and release acceptance are still in progress or gated. No paid signing or publication is authorized by preparation alone. |

## M00 — Project foundation

**Source:** Supplied roadmap. **Exit gate:** Reproducible project import/start and meaningful local checks; provenance and durable task records exist. Hardware certification is not part of this gate.

### M00-001 — Record the product and complete resumable roadmap

- **Owner:** A02 / A01
- **Priority:** P0 · **Milestone:** M00 · **Status:** Done
- **Dependencies:** None
- **Acceptance criteria:** Preserve the supplied source; capture all Release 1 requirements and exclusions; every implementation ticket has owner, dependencies, acceptance and tests; record a concrete current handoff. Identify M04–M07 as a proposed continuation.
- **Test strategy / evidence:** Review requirements-to-ticket coverage, source fidelity, local links and the end-of-session STATUS record. Evidence: docs/product, docs/planning, docs/STATUS.md.

### M00-002 — Pin and verify the free local Godot toolchain

- **Owner:** A01 / A03
- **Priority:** P0 · **Milestone:** M00 · **Status:** Done
- **Dependencies:** None
- **Acceptance criteria:** A repeatable setup script verifies the existing Godot 4.6.3 engine and runs project checks; missing-engine instructions point to official verified downloads; setup does not edit credentials or purchase services; project uses compatible settings and starts.
- **Test strategy / evidence:** Run setup to record engine version and project checks, then smoke-start the project. No download is needed when the pinned engine is preinstalled; verify official artifacts if future installation is necessary. Report platform blockers accurately.

### M00-003 — Define module boundaries and integration contracts

- **Owner:** A01
- **Priority:** P0 · **Milestone:** M00 · **Status:** Done
- **Dependencies:** M00-001
- **Acceptance criteria:** Document skater/world/scoring/session/HUD responsibilities, coordinates, input actions and signal contracts; implementation agrees with those interfaces; parallel owners do not overlap files.
- **Test strategy / evidence:** Review docs/architecture/interfaces.md against scripts and exercise scene creation/signal connections in the smoke/integration check.

### M00-004 — Build meaningful local verification and evidence capture

- **Owner:** A09
- **Priority:** P0 · **Milestone:** M00 · **Status:** Done
- **Dependencies:** M00-002, M00-003
- **Acceptance criteria:** One local command imports and runs focused tests; failures return nonzero and counts are reported; a rendered frame can be captured or the blocker recorded; no hosted workflow is triggered.
- **Test strategy / evidence:** Run tools/check.sh; demonstrate that a deliberate test assertion failure is detected without changing production behaviour; inspect an actual frame if available.

### M00-005 — Establish cost, provenance and licence controls

- **Owner:** A03 / A01
- **Priority:** P0 · **Milestone:** M00 · **Status:** Done
- **Dependencies:** M00-001
- **Acceptance criteria:** List engine, original code, procedural assets and future audio provenance; record no purchases, paid APIs, hosted CI or unattended compute; distinguish engine MIT licensing from game licensing.
- **Test strategy / evidence:** Review docs/licences/REGISTER.md and ADR-001 against the actual dependency/asset list; inspect repository for accidental external assets or workflows.

### M00-006 — Prepare local collaboration and reliable handoff process

- **Owner:** A01
- **Priority:** P0 · **Milestone:** M00 · **Status:** Done
- **Dependencies:** M00-001, M00-004
- **Acceptance criteria:** Feature branch, AGENTS instructions, README, local issue/PR templates and resume guide exist; STATUS records tested commands, current defects and next tasks; generated files are ignored. Do not claim local tickets are remote issues.
- **Test strategy / evidence:** Check branch/status/ignore patterns and local documentation links; perform a paper resume using only repository instructions; verify no billable workflow exists.

## M01 — Skating proof of concept

**Source:** Supplied roadmap. **Exit gate:** A playable grey-box loop with movement, jumps, aerial tricks and camera; local checks pass and the owner has played the DualSense build and accepted basic skating feel.

### M01-001 — Register controller and keyboard input actions

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M00-003
- **Acceptance criteria:** Push, brake, steer, ollie, flip, grab, spin, pause, restart and free-skate actions exist with keyboard and standard gamepad mapping; fresh action edges avoid repeat awards; pause gates input.
- **Test strategy / evidence:** Automate action presence, edge handling and gated controls; manually smoke keyboard. Real DualSense mapping remains M01-007 evidence.
- **Current implementation / remaining:** Keyboard and standard gamepad actions now include manual, revert, specials, interaction and goals; input remapping and recovery are tracked in M06-001. Synthetic events pass locally; physical DualSense evidence remains M01-007.

### M01-002 — Implement stable arcade ground movement

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-001
- **Acceptance criteria:** Acceleration, maximum speed, braking and steering are consistent; floor contact remains stable; no non-finite transforms or uncontrolled reverse motion; restart restores a safe spawn.
- **Test strategy / evidence:** Simulate acceleration/braking/turn/reset and floor contact; document central tuning constants and a repeatable hands-on route.
- **Current implementation / remaining:** The stable controller remains active across the expanded world; the separately completed M01-008 momentum corrections are retained. Current integrated regressions are in STATUS; target-controller feel remains open.

### M01-003 — Implement ollies and skateable ramp transitions

- **Owner:** A04 / A05
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-002
- **Acceptance criteria:** Fresh grounded ollie input launches and lands reliably; air control remains bounded; ordinary ramp collision supports ascent/descent/launch at intended speeds without snagging or falling through.
- **Test strategy / evidence:** Run grounded/airborne jump checks and a ramp traversal simulation; inspect rendered ramp contact and record manual approach angles.
- **Current implementation / remaining:** Nine authored ramps and preserved original launch/return routes now support the four-district world. Actual collision/ramp tests exist; human approach/landing comfort still needs the M01/M03 playtest.

### M01-004 — Implement initial aerial tricks and landing feedback

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-003
- **Acceptance criteria:** Flip, grab and spin actions produce identifiable original movement and one eligible award each; landing transitions signal once; unsafe recovery/bail behaviour is explicit rather than silently awarding invalid tricks.
- **Test strategy / evidence:** Test input edges, air/ground eligibility, landing transition count and reset; manual sequence: ollie, flip/grab/spin, land, repeat and compare HUD.
- **Current implementation / remaining:** Fresh aerial actions and scored spins remain integrated with the expanded combo system; the rider now has articulated visual poses. Real timing/animation readability still needs controller and motion review.

### M01-005 — Provide a usable follow camera

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-002
- **Acceptance criteria:** Camera tracks and looks ahead of the skater with controllable smoothing; spawn/restart has a useful frame; ordinary turns and jumps do not obscure the entire landing area.
- **Test strategy / evidence:** Inspect captured frames at spawn, turn and jump; play a route and log camera/comfort defects. Full occlusion/accessibility work remains M06.
- **Current implementation / remaining:** The chase camera and obstacle avoidance are implemented, with persisted camera-sensitivity/reduced-motion controls. Static captures and automated checks do not close comfort review on a real display.

### M01-006 — Integrate prototype run, score, HUD and fast restart

- **Owner:** A01 / A08
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-004, M01-005
- **Acceptance criteria:** A 120-second active-play run and free skate work; pause freezes time; basic tricks accumulate and bank once on landing with repeat degradation; HUD shows score/combo/timer and results; restart clears transient state.
- **Test strategy / evidence:** Unit-test score/bank/drop/reset and integration-test timer/pause/mode/restart; capture actual HUD; do not label this M02 continuous combo completion.
- **Current implementation / remaining:** Run/free-skate/pause/results/restart remain implemented; M02 now owns the deliberate 0.35-second landing resolution rather than the earlier immediate-bank prototype. Expanded main-scene regression evidence is in STATUS.

### M01-007 — Obtain independent M01 review and owner controller playtest

- **Owner:** A09 / Owner
- **Priority:** P0 · **Milestone:** M01 · **Status:** Blocked
- **Dependencies:** M01-001–M01-006, M00-004
- **Acceptance criteria:** Owner plays the prototype on the target Mac with a real DualSense and records feel feedback; A09 verifies core loop and identifies regressions; material responsiveness/landing/camera issues are fixed and replayed.
- **Test strategy / evidence:** Follow docs/testing/STRATEGY.md M01 checklist; record device/connection/macOS/build and observations. Blocker: physical target hardware and owner feedback; A01 coordinates. Linux tests cannot close this ticket.
- **Current implementation / remaining:** A01 coordinates the owner’s real Mac/DualSense playtest. No physical device or subjective feel result exists; this does not stop independent implementation or local defect fixes.

### M01-008 — Measure ramp takeoff momentum before changing air control

- **Owner:** A04 / A09
- **Priority:** P1 · **Milestone:** M01 · **Status:** Done
- **Dependencies:** M01-003 implementation; current baseline is available for measurement
- **Acceptance criteria:** Reproduce or disprove the code-review risk that full surface speed is reapplied as horizontal speed after slope departure; record outgoing/in-air velocity for uphill, downhill, flat and collided takeoffs. If confirmed, preserve intended momentum while retaining bounded arcade steering and existing jump feel; document intentional boosts separately.
- **Test strategy / evidence:** Add deterministic slope-lip velocity assertions at fixed physics steps and compare requested/real velocity; run existing 136-check suite and representative rendered/manual routes if behavior changes. Confirmed uphill/flat boosts, downhill damping and restored wall-collision momentum were fixed. Independent real-physics tests: 21 passed, 0 failed, with before/after results in docs/testing/TAKEOFF-MOMENTUM.md. Integrated final check evidence is in STATUS. Source: docs/research/SKATING_REUSE.md.

## M02 — Complete trick and combo system

**Source:** Supplied roadmap. **Exit gate:** Every core trick type works, continuous combos are understandable and satisfying, exploit checks pass, and the owner accepts controller combo flow.

### M02-001 — Specify trick states, timing windows and data definitions

- **Owner:** A04 / A02
- **Priority:** P0 · **Milestone:** M02 · **Status:** Done
- **Dependencies:** M00-003, M01-004, M02-009
- **Acceptance criteria:** Use the inspected upstream state/input and scoring references to decide adaptation boundaries; document states and permitted transitions for air, grind, manual, revert and bail; define trick IDs, base values and repetition rules; agree final input combinations and timeout handling in an ADR.
- **Test strategy / evidence:** Review a transition/edge-case table with A08/A09; test trick data validation, unknown IDs and illegal transitions. Implemented ADR-006 and game/tricks/trick_catalog.gd; 27 focused assertions cover records, unknown IDs, transition guards, defensive copies and scoring compatibility. The 0.35-second landing window is now implemented under M02-004/005; this ticket records the original contract and catalog validation. Controls remain provisional pending physical QA.

### M02-002 — Implement rail acquisition, travel, release and balance

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M02 · **Status:** QE review
- **Dependencies:** M02-001, M01-003, M02-010
- **Acceptance criteria:** Integrate the adopted GrindLine geometry helper with capture/travel/balance; authored rail metadata supports forgiving but bounded snap; speed/direction persist along rails; jump release and end release are reliable; balance risk can bail; unrelated ledges do not award rail points.
- **Test strategy / evidence:** Simulate approach angle/speed bounds, adjacent rails, reverse travel, ends, jumps, balance extremes and no-rail cases; human DualSense line trial. Implemented game/tricks/grind_ride.gd plus skater/world/main/input/HUD integration; initially two actual rails, now expanded to six by M03, held L/R2 capture, bidirectional travel, balance, swept obstacle rejection, release/ollie/end, cooldown, one entry award and pending-combo continuity. Pure helper and production-scene tests plus a real rendered ground-approach capture verify the local slice; see docs/testing/GRINDING.md. Human DualSense line trial remains open; no complete M02 acceptance is claimed.
- **Current implementation / remaining:** The world now supplies six authored rail paths; existing signed travel, capture, balance, clearance and release checks remain in the expanded suite. Physical R2/balance ergonomics and line enjoyment remain unverified.

### M02-003 — Implement manuals as combo links

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M02 · **Status:** QE review
- **Dependencies:** M02-001
- **Acceptance criteria:** Deliberate input enters an eligible ground manual, balance feedback is visible, travel sustains an active combo, and release/failure resolve consistently; cannot start while in an incompatible state.
- **Test strategy / evidence:** Test entry windows, hold duration, balance drift, clean exit, bail and state conflict; play repeated landing-to-manual links.
- **Current implementation / remaining:** Manual entry, push/brake balance, visible nose-up pose, release/low-speed exit, fresh-input cooldown, ollie continuity and balance bail are implemented. tests/manual_revert_tests.gd and combo_integration_tests.gd exercise actual player/main physics; human line feel remains open.

### M02-004 — Implement reverts and landing continuity windows

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M02 · **Status:** QE review
- **Dependencies:** M02-001, M02-003
- **Acceptance criteria:** Revert is accepted only within a documented landing window; visual turn and speed cost are readable; valid revert/manual sequences maintain combos; repeated input cannot preserve a combo forever.
- **Test strategy / evidence:** Boundary-test window timing, early/late input, duplicate events and speed limits; manual ramp-to-revert-to-manual trial.
- **Current implementation / remaining:** A fresh eligible revert scores once, turns the visible stance 180 degrees and applies a 15% speed cost without refreshing the original 0.35-second landing deadline. Early/late/held/repeated input, pause and overtime boundaries are tested; final controller timing remains provisional.

### M02-005 — Complete combo scoring, banking, multiplier and bail rules

- **Owner:** A04 / A06
- **Priority:** P0 · **Milestone:** M02 · **Status:** QE review
- **Dependencies:** M02-002, M02-003, M02-004
- **Acceptance criteria:** A single authoritative system links all eligible moves, applies documented multipliers and repeat degradation, banks exactly once on resolution, and loses only unbanked points on bail; exploit bounds are explicit.
- **Test strategy / evidence:** Deterministic mixed-trick sequences, zero/large values, repeated move abuse, simultaneous events, timeout and restart cases; replay a scored reference line.
- **Current implementation / remaining:** ScoreSession owns pending banking, exact 0.35-second resolution, continuation, repeat degradation, bounded values and bail loss; main uses fixed physics steps and bounded three-second overtime. Independent 32-check combo integration includes a real air→manual→air line banking 3,200 once; see combo_resolution_tests.gd/combo_integration_tests.gd and latest STATUS.

### M02-006 — Score spins and unlock/execute special tricks

- **Owner:** A04 / A06
- **Priority:** P1 · **Milestone:** M02 · **Status:** QE review
- **Dependencies:** M02-001, M02-005
- **Acceptance criteria:** Completed rotation is scored consistently; meter gain/use and special eligibility are communicated; at least two original special tricks have distinct input/animation/value; meter cannot be farmed while inactive.
- **Test strategy / evidence:** Test rotation thresholds/direction, meter bounds/reset, unavailable special input and consumption once; controller execution test with HUD feedback.
- **Current implementation / remaining:** Clyde Carousel and Tenement Tumble have distinct actions/poses/values, career unlocks and a bank-earned meter. Unit and actual mapped-input checks reject locked, uncharged, grounded and duplicate-airtime attempts without spending charge; human execution/readability review remains open.

### M02-007 — Implement reusable named-gap detection and rewards

- **Owner:** A04 / A06
- **Priority:** P1 · **Milestone:** M02 · **Status:** QE review
- **Dependencies:** M02-005
- **Acceptance criteria:** Data defines start/end, direction, airborne/route conditions and original gap names; valid traversal awards once; invalid approaches, teleport/reset and overlapping triggers do not duplicate points.
- **Test strategy / evidence:** Simulate valid, reverse, repeated and interrupted crossings; author a test gap and verify its displayed name/value during an actual route.
- **Current implementation / remaining:** GapTracker validates ordered authored crossings, air eligibility, direction, reset, teleport and repeat behavior. Three world gaps exist; independent career integration physically pushes onto the Central platform and ollies its gap for one award/bank/goal. All authored routes still need player review.

### M02-008 — Polish trick feedback and certify continuous combo feel

- **Owner:** A08 / A09
- **Priority:** P0 · **Milestone:** M02 · **Status:** Blocked
- **Dependencies:** M02-002–M02-007, M01-007
- **Acceptance criteria:** Trick history, multiplier, balance and bail cues remain readable; A09 completes exploit/regression checks; owner can deliberately link air, rail, revert and manual in a repeatable line and accepts feel.
- **Test strategy / evidence:** Run full scoring/state tests, five-minute controller combo playtest, screenshot/video review and fresh-player readability notes; unresolved feel defects block M02 exit.
- **Current implementation / remaining:** Trick/multiplier/balance/landing-window feedback and local exploit regressions are implemented; A09’s 28 focused UI checks cover real mapped navigation/settings/rebinding flows. Final acceptance is blocked on the owner’s real controller combo-flow/readability trial, coordinated by A01.

### M02-009 — Inspect reusable skating foundations and record source decisions

- **Owner:** A03 / A01
- **Priority:** P0 · **Milestone:** M02 · **Status:** Done
- **Dependencies:** M00-003, M00-005
- **Acceptance criteria:** Inspect actual free source, engine versions and licence files; compare controller, grind, state/input and scoring approaches; identify assets separately; pin sources and record which code is imported versus reference-only. Update operating rules to prefer suitable reuse.
- **Test strategy / evidence:** Four-project shortlist and official engine XML inspection in docs/research/SKATING_REUSE.md; full imported MIT notice/provenance; ADR-004 and AGENTS reuse rule. Unread blocked articles are labelled as leads.

### M02-010 — Adapt and verify a reusable rail-geometry building block

- **Owner:** A04 / A09
- **Priority:** P0 · **Milestone:** M02 · **Status:** Done
- **Dependencies:** M02-009, M00-004
- **Acceptance criteria:** Adapt the pinned MIT GrindLine helper under Godot4.6.3 with world-space length/closest point/full3D tangents; correctly handle transformed authored points, open endpoints, duplicates and invalid data; retain attribution/modifications. No claim that rail riding is finished until M02-002 acceptance.
- **Test strategy / evidence:** tests/rail_geometry_tests.gd covers42 assertions. Initial duplicate-bake and endpoint-tangent failures were corrected without weakening checks; the integrated suite covered136 assertions at that helper checkpoint; current totals are in STATUS. Source/modifications/licence in research and provenance records.

### M02-011 — Prototype genuine transition and vert skating

- **Owner:** A04 controller / A05 test geometry, with A02 design and A09
- **Priority:** P1 · **Milestone:** M02 · **Status:** Planned
- **Dependencies:** M03-014, M07-007, M02-009; current state/takeoff/camera regressions
- **Requirements:** Assess a central missing classic-skating capability through one bounded, original bowl/quarter-pipe prototype. The current low curved bank uses the existing floor controller and is not full vert, lip tricks or bowl carving.
- **Acceptance criteria:** Inspect compatible free approaches before choosing native/adapted code; record licences and a bounded isolated test scene. Match visible mesh and collision. Specify grounded approach→transition→vert/air→re-entry/landing, intended low-speed rollback, camera behavior, revert compatibility and bail/recovery. Demonstrate a playable repeatable transition both ways without phantom launches or invisible support, and preserve a beginner bank bypass. Any unimplemented lip/bowl/spine variant remains explicitly open; integration must preserve the existing ten-goal career and save contracts.
- **Test strategy / evidence:** Actual slow/normal/fast/diagonal approaches, apex, exit, re-entry, landing/revert, rollback, obstruction and bail tests; contact/normal/velocity traces and real chase/side motion evidence. Human controller/camera/flow playtest plus full regressions before promoting the prototype into required routes.
- **Current implementation / remaining:** Planned after the accepted route/encounter checkpoint. The Clyde yard has a real ≤35° low bank/rounded hip only. No vert state, near-vertical takeoff, lip trick or dedicated transition camera is claimed.

### M02-012 — Prototype bounded wallride and wallie states

- **Owner:** A04 gameplay / A05 optional route, with A02 and A09
- **Priority:** P2 · **Milestone:** M02 · **Status:** Planned
- **Dependencies:** M07-007, M02-011 state/camera review, M02-005
- **Requirements:** Build a bounded isolated wallride/wallie experiment before authoring a required wall-based shortcut. Define why it adds a useful line to this city.
- **Acceptance criteria:** Document eligible wall surface, approach angle/speed, contact entry, bounded travel, intentional ollie/exit, momentum, landing/bail and camera behavior. Awards occur through the ordinary score pipeline once per valid entry; repeated wall contact cannot farm points or create permanent attachment. Demonstrate an original optional close-wall line beside a supported bypass; preserve existing career/save/input contracts.
- **Test strategy / evidence:** Actual approach at angle/speed boundaries, held/repeated input, wall corners/ends, release/ollie, interruption/pause/restart, obstacle clearance, bad landing and recovery. Capture continuous motion and perform controller feel review; run score/takeoff/route regressions before integration.
- **Current implementation / remaining:** Not implemented. Existing walls are scenery/collision and must not be described as wallride opportunities until the state/exit/reward behavior is proven.

### M02-013 — Assess skitching and moving traffic through a bounded prototype

- **Owner:** A02 design / A04 gameplay / A05 world, with A09
- **Priority:** P3 · **Milestone:** M02 · **Status:** Planned
- **Dependencies:** M07-007, M03-013; current collision/camera/performance evidence
- **Requirements:** Decide whether a moving-vehicle interaction improves this compact level before adding traffic complexity. Do not buy vehicle assets or add traffic solely to resemble a reference title.
- **Acceptance criteria:** Record route benefit, conflicts with existing skating/side challenges, resource cost and an explicit implement/defer decision. If worthwhile, build one original vehicle/path in an isolated scene with attachment/balance/release, bounded momentum, obstruction, safe recovery and reset rules. Demonstrate a readable optional interaction with a permanent pedestrian/skating alternative. Only verified implementation may be advertised; a negative feasibility result is documented as such, not as working skitching.
- **Test strategy / evidence:** Actual catch/release at speed/angle limits, balance/bail, moving obstacles, corner/camera clearance, stuck-vehicle and pause/restart cases; physics traces, continuous rendered motion and representative frame-cost measurements. Human fun review and integration regressions follow any decision to ship it.
- **Current implementation / remaining:** Assessment not started. No moving traffic, skitch input, vehicle attachment or related reward exists in the current candidate.

## M03 — Glasgow grey-box

**Source:** Supplied roadmap. **Exit gate:** Four distinct connected districts, landmark silhouettes, viable lines, shortcuts, named gaps and secret areas are traversable and enjoyable with the accepted controller.

### M03-001 — Build George Square learning and combo routes

- **Owner:** A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M01-003, M02-007
- **Acceptance criteria:** Expand the prototype into a deliberate district with civic silhouettes, safe beginner loop, advanced line, statue/cone interaction space and stable collision; route choices work at supported speeds.
- **Test strategy / evidence:** Play and record both loops, obstacle contacts, boundary recovery and camera sightlines; inspect collision and gap placements with A04/A09.
- **Current implementation / remaining:** George Square has civic/clock silhouettes, its own routes/rail, paired entrances and a supported checkpoint; Exchange retains the cone statue interaction and learning routes. Production collision/marker evidence is in docs/levels/glasgow.md and world_routes_tests.gd; subjective route quality remains open.

### M03-002 — Build Royal Exchange Square and arcade passage

- **Owner:** A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M02-002, M02-007
- **Acceptance criteria:** Original gallery-inspired court, circular ledge route, precision gaps and arcade passage are skateable; at least two connections and a secret hook exist; signs and assets use original design.
- **Test strategy / evidence:** Traverse all routes in both intended directions, test grind acquisition/exit, inspect camera clearance and provenance entries.
- **Current implementation / remaining:** The expanded Exchange district preserves original ramps/rails/spawn, adds gallery-portico architectural detail and open paired district connectors. Collision openings and supported routes are tested; actual full-speed line/camera play remains to be reviewed.

### M03-003 — Build Central Station district and elevated route

- **Owner:** A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M02-002, M02-007
- **Acceptance criteria:** Original station/canopy silhouettes, long approaches, bank-to-rail links and an elevated line with safe exits exist; reserve the platform gap/goal triggers without copying a real station plan.
- **Test strategy / evidence:** Record approach/landing speeds, rail continuity, recovery from missed transfers and checkpoint reachability; review collision/render cost.
- **Current implementation / remaining:** Central has a transparent arched canopy, raised station platforms, approach/descent banks, rail and a real four-metre break. Actual player input traverses the approach and scored platform gap in career integration; visual/route comfort still needs human review.

### M03-004 — Build Barras / Barrowlands district and market route

- **Owner:** A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M02-002, M02-007
- **Acceptance criteria:** Original market stalls, venue-inspired silhouette and technical route establish the district; collectible positions and hidden recording route are reachable; narrow turns do not snag the skater.
- **Test strategy / evidence:** Traverse beginner/technical paths, test stall collisions and secret access/exit; inspect original signage and line readability.
- **Current implementation / remaining:** Barras has dressed market aisles, striped awnings, a venue-inspired silhouette, market pickups and a reachable recording alcove. Supported markers, entrances and collision paths are tested; player discoverability and technical-line feel remain open.

### M03-005 — Join districts, author secrets and validate the whole level

- **Owner:** A05 / A09
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M03-001–M03-004, M03-007, M02-008
- **Acceptance criteria:** All four districts form one continuous level; at least three cross-district combo links, one shortcut and one hidden area work; no transition breaks combos; all named gaps and respawns are valid; owner accepts traversal.
- **Test strategy / evidence:** Run a full four-checkpoint circuit and every authored line; log route times, collision/camera defects and missing returns; human exploration playtest and rendered overview.
- **Current implementation / remaining:** The previous cleanup connected four districts and CAREER-ROUTES recorded a continuous 1,085.69m circuit plus three bidirectional cross-district combo links. M03-008–M03-012 now intentionally revise the ground and add two exploration areas; rerun physical route/career evidence before treating those old results as applicable. Automated direct ground aiming remains an explicit idealization; human turning/discovery/recovery remain open.

### M03-006 — Verify Glasgow shopfronts, street edges and landmark relationships

- **Owner:** A03 / A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** Blocked
- **Dependencies:** M00-005; current reference-site access
- **Acceptance criteria:** Build a dated reference register for all four districts using official venue/business sources and public maps/Street View where accessible. Verify at least three distinctive boundary anchors per district, street/corner relationships, approximate frontage proportions and adjacent entrances. Separate stable architecture from changing tenancies; distinguish inspected facts, dated secondary leads and unverified candidates. No paid API, imagery scraping or map assets bundled in the game.
- **Test strategy / evidence:** Cross-check source URLs and capture dates, review an annotated district/block sketch against inspected references, record source licensing separately for any imported asset. Initial leads/access evidence: docs/research/GLASGOW_REFERENCES.md. Blocker: proxy HTTP 403 for official/map sites; narrow domain additions are now present in the saved base configuration, but current-instance requests still fail. Retry in a fresh environment using that configuration; do not ask the owner to repeat the same edit without evidence. Dated GitHub address data does not establish current storefront geometry.
- **Current implementation / remaining:** A03/A05 must retry only after a meaningful runtime access change, then record actual source/capture dates and geometry confidence. Saved domain settings and historical address leads are not evidence of current map/Street View access; no duplicate configuration request is needed without new evidence.

### M03-007 — Replace generic perimeter shops with recognisable Glasgow boundaries

- **Owner:** A05 / A03
- **Priority:** P0 · **Milestone:** M03 · **Status:** Blocked
- **Dependencies:** M03-006, M03-001–M03-004
- **Acceptance criteria:** Use verified shops/venues and street-edge relationships to give each district a recognisable perimeter; retain characteristic entrances, corners, facade rhythm and landmark sightlines while compressing travel for gameplay. Reproduce architecture with authored/licensed assets and factual signage references; do not substitute the same generic shop row in every district. Border buildings need not have enterable interiors. Keep collision simple and clear of accepted skating routes.
- **Test strategy / evidence:** Compare blockout and later detailed facade captures against the source register; verify each district's three anchors and deliberate geography changes; replay border-adjacent lines and inspect camera occlusion, collision and asset provenance.
- **Current implementation / remaining:** Original architectural facade modules and differentiated district silhouettes are implemented, but current shops/corners/entrances remain unsurveyed. Completion is blocked by M03-006’s verified reference inputs; A05 can continue independent material/detail work without inventing frontage facts.


### M03-008 — Define the authored six-area terrain and compatibility contract

- **Owner:** A02 / A01, with A05/A06/A09
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M00-003, M04-002; owner's explicit redesign request
- **Requirements:** Turn the requested Glasgow places, elevation, fountain, Clyde and park into one coherent skating design. Preserve four career districts/ten goals while adding two labelled exploration areas; identify deliberate geographic compression and current-reference limits.
- **Acceptance criteria:** DESIGN-BRIEF and ADR-007 specify six-area identity, ground/route/checkpoint/recovery contracts, connector ports, beginner/technical/return criteria, fountain/river/park behavior and adult scale. Final source agrees with shared interfaces. All goal/event/save IDs are unchanged; optional new areas cannot make `across_toon` require six visits. Geometry-preservation guidance is explicitly superseded only for this tracked redesign.
- **Test strategy / evidence:** Cross-review world/outdoor/main/map interfaces and compare the canonical goal/event ID set with the previous save model. Check new task fields/links and route ownership; inspect actual data after integration, not just the planning table.
- **Current implementation / remaining:** The terrain work groups, DESIGN-BRIEF and ADR-007 are authored; ADR-008 and the lead audit extend them with nonlinear routes and original local encounters. Runtime exposes six checkpoints and ordered route data at the agreed heights/ports, and physical fixtures preserve all ten career goals/four required districts. Final capture review and A01's shared-interface/STATUS reconciliation remain integration work; human place/route acceptance stays open.

### M03-009 — Rebuild the core squares and streets with playable elevation

- **Owner:** A05 core world / A04, with A09 verification
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M03-008, M01-003, M02-005
- **Requirements:** Replace flat disconnected-feeling courts with a coherent lower Exchange/market, raised gallery/station, higher civic square and graded connecting streets. Terrain must change traversal and sightlines while keeping every original goal reachable.
- **Acceptance criteria:** Exchange court Y0/gallery Y2, George square Y4/civic Y6, Central concourse Y2/platform Y5 and Barras market Y0/loading edge Y1.5 have rideable approaches and returns. Visible ramps match collision; all intended seams support the real capsule both ways. Original career IDs/markers and `central_gap` remain valid; no obligatory path crosses an unmarked jump. Spawn faces a clear northbound route. Shared terrain/route data match the final geometry.
- **Test strategy / evidence:** Ray/capsule support probes plus actual push-driven ascent/descent and full core circuit; retain at least three cross-district combo links and rerun the physical Central gap. Capture normal chase views uphill/downhill/under canopy and inspect floating props, occlusion and silhouette.
- **Current implementation / remaining:** Terraces, streets, relocated markers and height/route queries are implemented. Root's focused 49 checks pass the default ascent/descent and flat trick/bank behavior. Final static world-route checks pass 157/0; the expanded topography suite passes 60/0 with expected heights, real slope motion, fountain, nonlinear branches and outdoors; career integration passes 23/0 on the rebuilt 5 m station platform. The final 21-frame source-stable set was inspected; undercroft/Close labels and the specific terrain-edge defects were corrected. The final ordinary aggregate passes 955/0; human line enjoyment remains open. See TOPOGRAPHY.md.

### M03-010 — Author and physically verify the fountain coping line

- **Owner:** A05 core world / A04, with A09 verification
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M03-008, M03-009, M02-002
- **Requirements:** A visible fountain becomes a deliberate curved grind opportunity with a usable approach, exit and outside return, rather than decorative water on a flat court.
- **Acceptance criteria:** Exchange fountain at authored centre (0,0,10) has a visible 6.2 m-radius rim matching the 64-segment closed `Grind_Coping_ExchangeFountain` path at Y0.92. A ground push/ollie/descending tangent approach captures it; actual travel changes direction with the curve, handles the closure seam and exits/lands/banks once. Obstruction and balance failure behave consistently; nearby geometry does not trap the rider. Its placement is labelled a skating adaptation, not a claimed real fountain survey.
- **Test strategy / evidence:** Independent actual-input capture/travel/exit in intended directions, path-to-visible-rim checks, seam/clearance/duplicate-award/bail cases, and real chase/close captured frames. Human capture forgiveness and repeated-line feel remain a later acceptance check.
- **Current implementation / remaining:** Fountain basin/pedestal/coping and route metadata are implemented. The expanded independent 33-check topography run includes actual ground push→ollie→curved capture→release→bank. Actual source-stable court/gallery images show the rim and approaches. Full closure/direction/obstruction coverage and controller capture feel remain required; the focused pass and stills do not close all acceptance criteria.

### M03-011 — Build Clyde Quays with a river transfer and safe crossing

- **Owner:** A05 outdoors / A01 integration / A09
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M03-008, M03-009, M02-007
- **Requirements:** Add a distinct waterside exploration area south of the core, an optional clearable bridge gap, a continuous alternative route and reliable water-miss recovery without expanding the career goal count.
- **Acceptance criteria:** Clyde connects at (-94,2,45)/(94,0,45); quay surface Y2 and water Y-2 form readable edges. The authored bridge near X35 has an actual 8 m opening Z94…102 and a supported landing/run-out; `clyde_bridge_transfer` awards once through existing gap rules. The X-98 alternate bridge is continuous. Water entry emits one bail, drops only the active combo, preserves banked score and returns to supported ground. `clyde`/CLYDE QUAYS appears on the map; existing career/save IDs remain unchanged.
- **Test strategy / evidence:** Real approach/takeoff/full-gap/landing and score trace; missed-jump, repeated water-contact, pause/restart and preserved-bank tests; both safe-crossing directions and port seams. Capture chase takeoff/landing, water edge and a topology overview. Review gap comfort on actual controls later.
- **Current implementation / remaining:** Outdoor geometry and root hazard recovery are implemented. Independent topography verifies a real 8 m bridge ollie banking 2,000 once; a missed jump emits one bail, drops the pending Flip and preserves an already earned 100-point bank before supported recovery. Focused quay/checkpoint and continuous bridge routes pass in 16.08s/4.57s. Final static routes reached 157/0 and the expanded topography suite contains 60 checks; actual bridge/yard/overview images were reviewed. The final ordinary aggregate passes 955/0; human gap comfort remains a separate open gate. These are authored gameplay dimensions and idealized automated approaches.

### M03-012 — Build a hilly Kelvingrove-inspired park circuit

- **Owner:** A05 outdoors / A04, with A09 verification
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M03-008, M03-009
- **Requirements:** Add recognisable grassy, rolling outdoor terrain and a paved climbing/descending loop northwest of the city. Hills must be actual supported terrain or visibly bounded scenery, with two continuous city connections.
- **Acceptance criteria:** Within the authored main riding bounds X[-220,-140], Z[-185,-75], a visible S-path climbs approximately Y6→17 and returns; surrounding woodland completes the landscape edges. Central-side (-145,2,0) and civic-side (-42,6,-122) connections meet supported grades. Uphill/downhill movement and every seam work without hidden flat floors, unintended stalls/bails or camera traps. Grass/trees frame the path; terrace/S-bend grind metadata match visible edges. `kelvingrove`/KELVINGROVE PARK is exploration/map data, not a fifth/sixth career requirement.
- **Test strategy / evidence:** Real push-driven full climb/descent/return through both ports, height/collision probes, path/rail matching and reduced-motion camera checks; chase views at bottom/crest/descent plus overview. Record idealized automated steering and keep subjective hill/grass feel open.
- **Current implementation / remaining:** Rolling ground, paved switchbacks, terraces, both connectors and leaf/twig foliage are implemented. The final focused physical fixture travels from Central through the complete hill loop and back to the same port in 29.30s, reaches the actual park checkpoint and records zero stalls/bails. Static routes pass 157/0; the expanded topography suite contains 60 checks. Final 21-frame review confirms the open fork and supported shoulder. The final ordinary aggregate passes 955/0; human path/grass feel remains open and direct ground-heading control is explicitly idealized.

### M03-013 — Audit nonlinear reference levels and prioritize original route changes

- **Owner:** A02 lead level design / A03 research, with A05 and A09
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M03-008, M03-009, M03-011, M03-012; owner's additional level-design direction
- **Requirements:** Inspect the named San Francisco, London, Los Angeles and School reference levels for useful skating-space principles; assess this level's actual geometry, sightlines, route graph and captures against them.
- **Acceptance criteria:** Record inspectable source/date/confidence and distinguish direct observation from remembered or unavailable material. Identify specific weaknesses and a prioritized original response for connected loops, nonrectangular corridors, forks, vertical overlaps, landmark orientation and forgiving returns. Each accepted recommendation states intended player choice, geometry ownership, risk and verification. Do not copy a proprietary map or describe an audit proposal as a built feature.
- **Test strategy / evidence:** Cross-review sources and the actual production world/captures; trace each recommendation to M03-014 or an explicitly deferred follow-up. Compare route alternatives before/after using real metadata and physical verification, then retain human discoverability/fun feedback as an open gate.
- **Current implementation / remaining:** LEAD-DESIGN-REVIEW and CLASSIC-LEVEL-DESIGN record inspected reference/source facts, candid feature coverage and the four accepted route changes. The lead inspected actual source and both 21-frame sets, then accepted the corrected topology slice: station overlap, Merchant service court/return banks, open park fork/shoulder and yard hip are visible. Missing transition/vert, wallride, reversible set piece and skitch assessment now have M02-011/012/013 and M03-015. The final post-fix review clears the concrete topology blockers; human fun and final place/art acceptance remain open.

### M03-014 — Implement nonlinear cross-links and distinct skating pockets

- **Owner:** A05 geometry / A04, with A02 design and A09 independent verification
- **Priority:** P0 · **Milestone:** M03 · **Status:** QE review
- **Dependencies:** M03-013, M03-009, M03-011, M03-012; current controller and route-map contracts
- **Requirements:** Turn the connected courts into a less rectangular playground with meaningful alternate routes, short technical choices, different heights and spaces that reconnect. Preserve the career circuit and accessible return paths.
- **Acceptance criteria:** Implement the accepted feasible subset explicitly: a genuinely suspended station upper walk above a supported undercroft; an angled Merchant Close with connected ends and a distinct pocket; a second park route reconnecting to the station approach; and a south-Clyde landing/yard/quay loop if included. Every implemented link has stable route metadata, supported surfaces, sufficient player/head clearance, readable entry/exit and a safe return or marked jump. Avoid routes that depend on unimplemented wallride/vertical-pipe mechanics. Preserve original goal/save IDs and all ten goals' physical reachability.
- **Test strategy / evidence:** Independent actual player travel in both directions, support/capsule/underdeck clearance probes, no-stall/no-bail seam checks, missed-line recovery and cross-link combo attempts; rerun the complete career circuit. Inspect production chase/overview/map images against real route metadata and record which recommendations remain unbuilt. Human discovery, turning and line enjoyment remain open.
- **Current implementation / remaining:** All four branches and an actual ≤35° curved bank/rounded hip are implemented. Stable route IDs are station_low_level_close, merchant_close_cutthrough, kelvingrove_cutback_return, clyde_print_yard_loop and clyde_print_yard_hip; get_support_height preserves the intended lower station floor. Final static checks pass 157/0. Independent real-motion checks pass 30/0 for seven new routes in both directions, stacked clearance, bank profile and existing outdoor returns; a new ledge→rail→flip/grab→manual combo banks exactly 5,000 once. The source-stable 21-frame repeat at 15:42:35 UTC clears the Merchant pit/return and park fork/shoulder blockers in lead/root/geometry review. Remaining broad-court shaping/material/perimeter work is explicit under M06-007. The bank does not implement full vert/lip mechanics.

### M03-015 — Prototype one original reversible changing-route event

- **Owner:** A05 world / A06 events / A07 narrative, with A04/A08/A09
- **Priority:** P2 · **Milestone:** M03 · **Status:** Planned
- **Dependencies:** M07-007, M03-014, M04-007; stable route-map/hazard contracts
- **Requirements:** Give one Glasgow-inspired place an original setup/payoff that changes a skating choice, such as a fictional service gate or bridge mechanism. Do not copy a commercial game's scripted disaster, dialogue or layout.
- **Acceptance criteria:** Define activation, visible/physical route changes, cooldown/repeat, reset and career/free-skate/save behavior before coding. Keep an always-available safe exit and prevent trapping the player during collision changes. Implement one bounded reversible test scene; the route map and ground/hazard queries follow the actual active geometry. State whether the event is run-local or persisted; preserve schema and canonical career IDs unless a separately recorded migration is designed.
- **Test strategy / evidence:** Real activation before/on/after the moving boundary, both route directions, repeated activation, pause/bail/restart, trapped-player prevention, map updates and save reload if applicable. Capture the actual before/transition/after states and a playable optional line; run all career/route/persistence regressions before integration.
- **Current implementation / remaining:** Not implemented. The existing statue/cone interaction changes a local visual and does not constitute a changing traversable route.

## M04 — Missions and progression

**Source:** Proposed continuation. **Exit gate:** Career and free skate are complete, ten objectives work, goals/records/unlocks persist safely and balancing supports repeated two-minute attempts.

### M04-001 — Finalize career/free-skate lifecycle and results contract

- **Owner:** A06 / A08
- **Priority:** P0 · **Milestone:** M04 · **Status:** QE review
- **Dependencies:** M02-005, M01-006
- **Acceptance criteria:** Mode eligibility, 120-second active timer, final combo resolution, pause and results follow a documented rule; restart is immediate; career completion events cannot fire accidentally in free skate.
- **Test strategy / evidence:** Integration-test timeout during each trick state, pause at boundaries, mode switches, rapid restart and double results; controller navigation smoke.
- **Current implementation / remaining:** Career/free skate and results now integrate pending combos, fixed-step countdown, blocked overtime entries and persisted progress. Main-scene tests cover restart, mode gating and bounded timeout; controller menu/results traversal remains an acceptance check.

### M04-002 — Build data-driven objective tracking

- **Owner:** A06
- **Priority:** P0 · **Milestone:** M04 · **Status:** QE review
- **Dependencies:** M04-001, M02-007
- **Acceptance criteria:** Goal data validates IDs, descriptions, prerequisites and event conditions; tracking supports score, combo, collectibles, route gaps and interactions; completion is once per eligible goal and reports to UI.
- **Test strategy / evidence:** Validate missing/duplicate IDs and event types; test duplicate/out-of-order events, run resets, completed goals and mode eligibility.
- **Current implementation / remaining:** CareerProgress defines ten stable goal IDs and per-run duplicate-safe event collections; ObjectiveTracker supplies proximity/explicit-interaction events and UI snapshots. Sixty focused career checks cover model/persistence/settings behavior; actual scene tests cover mapped collection/cone input and free-skate isolation.

### M04-003 — Author and verify all ten career objectives

- **Owner:** A06 / A05
- **Priority:** P0 · **Milestone:** M04 · **Status:** QE review
- **Dependencies:** M04-002, M03-005
- **Acceptance criteria:** Implement the ten design goals including three score tiers, combo, letters, cone event, platform gap, market items, four-district route and secret recording; descriptions and world placements are accurate.
- **Test strategy / evidence:** Complete each goal through gameplay, test near-miss/partial progress and reset, and record triggers/locations; review discoverability with a player.
- **Current implementation / remaining:** All ten goal definitions, HAWKS letters, cone interaction, Central gap, three market items, four checkpoints and recording marker are implemented. Geometry and event tests plus actual Central/cone/letter play cover key routes; completing every goal in a normal human run and discoverability review remain required.

### M04-004 — Implement versioned local saves and safe recovery

- **Owner:** A06 / A01
- **Priority:** P0 · **Milestone:** M04 · **Status:** QE review
- **Dependencies:** M04-002
- **Acceptance criteria:** Records, goals, unlocks and settings serialize locally with a schema version; write failure/corruption recovers without crashing; safe replacement preserves a usable prior file; no cloud account is required.
- **Test strategy / evidence:** Temporary-dir round trip, missing/truncated/invalid/old schema, permissions/write failure and interrupted-save scenarios; relaunch on target macOS and verify persistence.
- **Current implementation / remaining:** Versioned local JSON, verified temporary writes, previous-generation backup, corrupt fallback, v0 migration, future-version protection and explicit archive-before-reset recovery are implemented. Sixty focused tests include records/settings/bindings/cosmetics and failure preservation; target-Mac save-path/relaunch validation remains open. See docs/testing/PROGRESSION.md.

### M04-005 — Implement meaningful unlocks and personal records

- **Owner:** A06 / A08
- **Priority:** P1 · **Milestone:** M04 · **Status:** QE review
- **Dependencies:** M04-003, M04-004, M02-006
- **Acceptance criteria:** Goals award documented cosmetic/secret/special rewards once; records update only on improvement; unlock state is visible and survives restart; core movement is available from the start.
- **Test strategy / evidence:** Test repeated completion, reward dependency order, save reload, score ties and record updates; check locked/unlocked UI and new-player path.
- **Current implementation / remaining:** Banked personal records, one-time goal completion, three colour IDs and two special unlocks persist. Unknown/locked specials reject; selected known-but-unearned colours fall back to blue on load. HUD/visual application is integrated; new-player reward pacing still needs review.

### M04-006 — Balance goals and verify career replayability

- **Owner:** A06 / A09
- **Priority:** P0 · **Milestone:** M04 · **Status:** In progress
- **Dependencies:** M04-003–M04-005
- **Acceptance criteria:** Three score thresholds and combo targets are based on observed run distributions; all goals fit the intended run/mode rules; no impossible dependency or duplicate reward exists; owner accepts replay loop.
- **Test strategy / evidence:** Collect novice/intermediate/experienced run evidence, verify all-goals save and fresh profile, and play repeated career/free-skate sessions with recorded tuning rationale.
- **Current implementation / remaining:** The previous cleanup and intermediate redesign timings are historical. The final ordinary-scheduler 955/0 aggregate includes 13 career-route checks: all ten goals in 75.20s, return at 88.00s over 1,199.52m, 20,000 points/3,200 best combo and zero bails/stalls. The independent fixed-60-Hz fixture separately records 75.20s/88.00s. Thresholds and all ten IDs stay stable; idealized direct ground aiming is feasibility evidence, not human score distributions or fun acceptance. See CAREER-ROUTES and M07-006.


### M04-007 — Add an optional busker challenge through ordinary trick banking

- **Owner:** A06 missions / A07 local encounters, with A01 integration and A09
- **Priority:** P1 · **Milestone:** M04 · **Status:** QE review
- **Dependencies:** M03-013, M05-007, M02-005, M04-001; stable career/save contract
- **Requirements:** Give the player an original, readable local challenge: accept the busker's offer, perform a varied line and bank at least 1,000 points. This is an optional side activity, distinct from the ten canonical career goals.
- **Acceptance criteria:** Define stable encounter ID, eligible trick-family set, active area/timing, offer/start/success/failure/retry behavior and repeat/reward limits. Success requires real qualifying trick events and an actual bank of at least 1,000; injected pending score, repeated one-family spam, bail or an unrelated bank cannot complete it. Prompts/captions and any reward are clear with keyboard/controller navigation; preserve free-skate career restrictions, original goals/unlocks and schema. Pause/restart, leaving/re-entering and repeated interactions cannot duplicate rewards or trap the state.
- **Test strategy / evidence:** Focused state tests plus an input-driven accepted offer→three-family line→valid bank; negative cases for insufficient points/families, bail, unrelated bank and repeated events. Verify reset/mode/persistence boundaries and inspect actual offer/progress/success UI. Human humour/discoverability and real listening remain open.
- **Current implementation / remaining:** Mo's Big Finish (busker_big_finish) is implemented in both modes at (28,0,31): interact within 4.2 m with no pending combo; bank at least 1,000 using three distinct real trick families in one clean line within the 34 m court and 35-second attempt. Leaving invalidates that line until resolution; bail/timeout/career expiry fail; retry is immediate and restart resets it. No extra points, unlock or profile write is created. Independent production-input/encounter tests pass 30/0, including real 1,950-point ollie/flip/grab success, spin-family replay and audio data checks. The source-stable offer/active/success images show that same actual bank and one win; reviewed actor/contact corrections are included. The final ordinary aggregate passes 955/0; human challenge balance/tone/listening remains open. See GLASGOW-FUN.

### M04-008 — Prototype Cone on a Cruise as a recoverable river stunt

- **Owner:** A06 encounters / A05 props/physics / A07 narrative, with A09
- **Priority:** P2 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M07-007, M04-007, M03-011; existing water recovery and interaction contracts
- **Requirements:** Create an original Clyde festival-steward encounter using a fictional floating foam-cone mascot and a marked river target. A skating approach and visible prop trajectory provide the joke and challenge.
- **Acceptance criteria:** In a bounded prototype, accept the offer, build actual speed, launch the cone from a marked stunt point, physically cross the target ring and land a valid trick on the quay. Completion depends on both trajectory and real landing/bank evidence, not a button or timer alone. Show the cone recover onto its own raft; misses, water entry, leaving, pause and repeat attempts recover promptly. No person/animal is used as the projectile. Keep rules/reward run-local unless a separately designed save contract is recorded; no canonical goal or paid asset/service is added.
- **Test strategy / evidence:** Real approach/launch/target/landing success plus low-speed, off-angle, missed ring, failed landing, bail, water recovery, double activation and restart cases. Inspect continuous rendered prop motion and readable target/return; human control feel and comic timing remain required.
- **Current implementation / remaining:** Design only in GLASGOW-FUN. No cone projectile, target physics, steward actor or enabled challenge exists yet.

### M04-009 — Prototype Cat's Got the Beat with ordered coping captures

- **Owner:** A06 encounters / A05 original mechanical prop / A07 narrative, with A04/A08/A09
- **Priority:** P2 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M07-007, M04-007, M02-002, M03-010
- **Requirements:** An original fictional tinkerer invites the player to power a geometric mechanical-cat dance stage by grinding three marked coping segments in a short indicated order.
- **Acceptance criteria:** Actual segment capture events, in the stated order, advance the challenge; proximity, duplicate callbacks and wrong-order attempts cannot satisfy it. Show a small original movement payoff, immediate retry and a non-flashing reduced-motion alternative. Provide legible sequence prompts/captions and supported approaches/returns. Do not copy the researched performer's cat, routine, music, voice or likeness. Keep canonical goals/saves unchanged and define mode/reset/repeat behavior explicitly.
- **Test strategy / evidence:** Play the full ordered route; test reverse/wrong order, repeated same segment, bail, missed transfer, pause/restart and repeated success. Capture the real sequence indicators and final prop animation; inspect keyboard/controller clarity, flashing/motion settings and original asset/audio provenance.
- **Current implementation / remaining:** Design only in GLASGOW-FUN. No mechanical-cat asset, coping sequence or dance-stage state is enabled.

### M04-010 — Prototype Gull-Proof Delivery through alternative market lines

- **Owner:** A06 encounters / A05 market props / A07 narrative, with A04/A09
- **Priority:** P2 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M07-007, M04-007, M03-004, M02-003, M02-007
- **Requirements:** An original breakfast-stall owner offers a sealed parcel delivery through a choice of Barras lanes. A comic gull targets a spare parcel while the player commits to a clean manual-to-gap line and arrival.
- **Acceptance criteria:** Define two supported route choices with meaningful time/trick tradeoffs and an explicit delivery deadline. Success requires pickup, a real manual/gap sequence with a valid bank, and physical arrival; elapsed time or a synthetic score cannot win. A bail returns the parcel to the stall for immediate retry. Gull behavior is bounded, concerns props, and cannot block the camera or mandatory skating route. Record rewards/replay/mode behavior without expanding the ten-goal career or introducing paid audio/assets.
- **Test strategy / evidence:** Actual successful transit on both routes; wrong/missing gap, low or bailed line, timeout, dropped parcel, repeated pickup/arrival, pause and reset tests. Capture readable fork/parcel/delivery feedback and the comic payoff. Human route understanding and time balance remain open until played.
- **Current implementation / remaining:** Design only in GLASGOW-FUN. Parcel state, delivery route, gull animation and challenge timing are not implemented.

### M04-011 — Prototype One More Lap, Hen across park route choices

- **Owner:** A06 encounters / A05 park route / A07 narrative, with A04/A09
- **Priority:** P2 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M07-007, M04-007, M03-012, M03-014
- **Requirements:** An original park regular times a community skating circuit that links coping, downhill path and a supported grass-bank transfer, with a safe return and harder shortcut.
- **Acceptance criteria:** Specify a coherent route wholly supported by implemented geometry, physical start/finish gates, required trick/transfer events and readable landmarks. Both route choices reach a safe finish and allow uphill return; missed gates/bails cannot finish silently. Original dialogue reacts to real attempts/replay, with bounded cooldowns and an explicit local reward/reset contract. Preserve career/save IDs and avoid requiring unimplemented vert/wallride mechanics.
- **Test strategy / evidence:** Actual complete circuits through each branch, ordered gate/trick checks, missed transfer, out-of-order finish, bail, timeout if used, pause/restart and safe return. Render branch/finish feedback and record human navigation, hill feel and comic timing separately from deterministic feasibility.
- **Current implementation / remaining:** Design only in GLASGOW-FUN. No additional park challenge, timer/gates or speaking regular is enabled.

## M05 — Art, audio and ambient characters

**Source:** Proposed continuation. **Exit gate:** Believable, detailed, realistic-but-fun environments/characters, skating audio, ambience and captioned NPC reactions support the accepted skating loop; blocky placeholder art is not the release target. Complete provenance and no additional spend remain required.

### M05-001 — Replace blockout with detailed Glasgow environment art and lighting

- **Owner:** A05
- **Priority:** P1 · **Milestone:** M05 · **Status:** In progress
- **Dependencies:** M03-005
- **Acceptance criteria:** After M02-008, A05 coordinates with A08 to produce one representative facade/skating approach, skater and polished HUD treatment; obtain owner review and capture frame cost before repeating the treatment across the world. Follow docs/product/ART_DIRECTION.md: replace generic cuboids and flat placeholder surfaces with believable facade proportions, bevelled architectural detail, varied windows/doors, authored or free licensed stone/brick/paving/glass materials, coherent lighting and recognisable shopfront edges. Keep ramps/rails readable and preserve accepted collision. No voxel/blocky final aesthetic; no paid assets or engine switch without evidence.
- **Test strategy / evidence:** Representative scene/HUD review and measured frame cost, then matched before/after captures in all districts; replay reference lines and compare frame cost; audit all assets/procedural sources in the provenance register.
- **Current implementation / remaining:** The second cleanup added distinct civic/retail/station/warehouse modules, smoother arches, door/display/roof variation and verified CC0 brick/concrete textures. Its matched captures/draw-call evidence remain in VISUAL_PASS. ADR-007 now authorizes substantial terrain changes under M03-008–M03-012, superseding this ticket's old collision freeze for those tracked routes. Retain useful licensed materials/detail while rebuilding the world; current references and final realistic/owner acceptance remain open.

### M05-002 — Create readable original skater and trick animation

- **Owner:** A05 / A04
- **Priority:** P1 · **Milestone:** M05 · **Status:** In progress
- **Dependencies:** M02-008
- **Acceptance criteria:** Replace the primitive rider/board with believable proportions, detailed clothing/board materials and a coherent rig. Push, ollie, flip, actual hand-to-board grab, grind, manual, revert, special and bail must show convincing weight/contact and readable motion. Reuse suitable free licensed models/animations with provenance; visuals follow gameplay without adding input delay.
- **Test strategy / evidence:** Inspect every trick at slow and normal speed, verify state sync and camera readability, then rerun action timing and combo regression tests.
- **Current implementation / remaining:** Original ten-bone Skeleton3D and continuous skinned jacket/trousers replace separate joint surfaces; body/board proportions, push/brake, feet, grab, balance/revert/special poses are refined. Long-route Basis normalization errors and the tumble pivot were fixed. Action captures and a reproducible 30fps motion clip document actual input with explicit fixtures/cuts; final weight, anatomy, hand detail, bail/grind motion and owner/hardware acceptance remain open.

### M05-003 — Produce and integrate local synthetic skating SFX

- **Owner:** A07
- **Priority:** P1 · **Milestone:** M05 · **Status:** QE review
- **Dependencies:** M02-005
- **Acceptance criteria:** Original reproducible sounds cover wheel roll, jump, landing, grind, bail, combo and UI; event mapping prevents overlap spam; sound parameters reflect surface/speed where useful; no paid API is used.
- **Test strategy / evidence:** Record generator/source provenance; test event counts, mute/volume, pause/reset, rapid landing and long grind; listen for clipping and fatigue.
- **Current implementation / remaining:** Original locally synthesized contact/grind loops and bounded events are integrated. Main now selects stone/asphalt/metal from actual supporting collisions; production integration checks traverse each material. Waveform/event/mute tests remain. Human listening for mix, timbre and fatigue is still required; see AUDIO.md.

### M05-004 — Add ambient NPCs and lawful free voiced reactions

- **Owner:** A07 / A05 / A03
- **Priority:** P1 · **Milestone:** M05 · **Status:** QE review
- **Dependencies:** M03-005, M00-005
- **Acceptance criteria:** Original ambient NPCs react briefly without blocking routes; captions accompany every bark; approved free local voice source has redistribution evidence and no identity imitation. If unavailable, document the blocker and ask for a scope decision rather than claiming voice completion.
- **Test strategy / evidence:** Test trigger range/cooldown, simultaneous reactions, subtitles and collision clearance; audit voice model/output rights and listen on actual hardware. Paid voice services are prohibited.
- **Current implementation / remaining:** Four original off-route bystanders and three short captioned reactions are integrated. Speech was generated free from the already installed, inspected Flite/KAL16 voice; licence notices, source/library/output hashes and local generator are recorded. Human intelligibility/tone review and richer NPC animation remain open; no paid voice service was used.

### M05-005 — Integrate district ambience and review the presentation

- **Owner:** A07 / A08 / A09
- **Priority:** P1 · **Milestone:** M05 · **Status:** QE review
- **Dependencies:** M05-001–M05-004
- **Acceptance criteria:** Ambience varies smoothly by district; separate levels and captions are accessible; skating feedback remains audible; NPC humour is original and readable; no missing assets/licences remain.
- **Test strategy / evidence:** Play the full route with speakers/headphones, mute channels, pause/restart and save settings; compare visual/audio event timing and review complete provenance.
- **Current implementation / remaining:** Four synthesized district beds, separate mix controls, captions, bounded reaction cooldowns and pause behavior are implemented; 75 focused audio assertions pass. A07/A09 still need a real speakers/headphones listening route and complete visual/audio timing review before acceptance.


### M05-006 — Replace cartoon anatomy with a believable adult skater

- **Owner:** A05 rider / A04 / A03, with A09 and owner review
- **Priority:** P0 · **Milestone:** M05 · **Status:** QE review
- **Dependencies:** M03-008, M05-002, M00-005
- **Requirements:** The rider must visibly read as an adult with plausible anatomy, clothing volume, hands/face and motion, at a coherent scale against the redesigned streets and obstacles. Reuse an appropriate free anatomical source when its terms are inspected.
- **Acceptance criteria:** Target approximately 1.75 m standing height, 0.25 m head and 0.44 m shoulder width, natural wrist/hand/foot proportions, restrained skate clothing and shaped shoes; remove oversized hat/mitten/cartoon face cues. Any imported anatomy has pinned source/licence/notices and documented adaptation. Preserve board/contact origin, collision/controller timing, native rig/pose interfaces and credible hand/deck/sole contact across all actions. Owner visual acceptance remains explicit; passing rig math cannot certify realism.
- **Test strategy / evidence:** Source/licence review; front/profile/full-body/head and normal chase frames; real-input coast/push/brake/ollie/flip/grab/grind/manual/revert/special/landing/bail clips with contact/clipping/transition review; focused pose/action checks followed by aggregate regression. Actual Mac/controller feel remains unverified.
- **Current implementation / remaining:** Verified CC0 MakeHuman head/five-finger hands, restrained native clothing, stable bone orientation, shaped cupsole shoes, fitted neck/collar, palm contact and GripCurl are implemented with source/asset provenance. Final action capture reached all 11 requested states without errors; 17 actual frames and independent six-frame review are recorded in RIDER-REALISM. The model has 62 mesh instances, 37,304 triangles and ten clothing bones. The final motion refresh is verified at 222 frames/7.4 seconds, zero errors, clean full decode and 97 unchanged pinned inputs; the ordinary aggregate passes 955/0. Real motion weight, material refinement and owner adult-realism acceptance remain open.

### M05-007 — Research and author original Glasgow locals and playful encounters

- **Owner:** A03 culture/reference research / A05 characters / A07 narrative, with A02 and A09
- **Priority:** P1 · **Milestone:** M05 · **Status:** QE review
- **Dependencies:** M03-013, M05-004, M00-005; owner's Glasgow-fun direction
- **Requirements:** Use inspected Glasgow cultural context to create original fictional busker/dancer/local characters and cheeky side activities. The owner's cited real locals are research leads; they are not automatically licensed NPC likenesses or endorsements.
- **Acceptance criteria:** Record source/date/confidence for factual inspiration and identify every invented character, line and interaction. A distinct busker presence supports M04-007; additional dancer/slapstick ideas are clearly implemented or deferred. Use original dialogue, gestures and compatible free visuals/audio; no copied real voice, likeness, catchphrase or licensed song. Characters have readable in-world placement/prompts and bounded repeat/cooldown behavior. Any playful knockabout uses an explicit fictional, recoverable interaction without silently changing career goals or adding paid services.
- **Test strategy / evidence:** Source/licence and originality review; inspect character silhouette/placement and actual encounter prompts from normal chase distance, check captions, overlap/mute and interaction reachability. Test repeated/paused/restarted interactions and any implemented physical recovery. Record actual human listening/cultural-tone review separately from automated checks.
- **Current implementation / remaining:** GLASGOW-CHARACTERS records inspected dated local-performance sources and separates them from original fiction. Mo is implemented with cleared anatomy/garments, an original guitar/case, readable captions and a quiet synthesized spatial plucked chord controlled by master/ambience/pause. Actual medium review corrected collar, fret-hand contact, soundboard, sign size and case text. Independent encounter checks pass 30/0 and final actual actor/offer/progress/success frames were reviewed; waveform/cache checks do not establish human listening. The four other ideas are explicitly Planned under M04-008–011; no real-person NPC endorsement, copied voice/song or enabled extra mission is claimed.

## M06 — UX, hardware and performance

**Source:** Proposed continuation. **Exit gate:** Menus and accessibility work with controller and keyboard; real DualSense/macOS play passes; representative Apple Silicon performance meets the declared 1080p/60 fps target.

### M06-001 — Harden controller support, remapping and input recovery

- **Owner:** A04 / A08
- **Priority:** P0 · **Milestone:** M06 · **Status:** QE review
- **Dependencies:** M02-008
- **Acceptance criteria:** Final controls are documented; mappings, sensitivity/deadzones and keyboard equivalents work; focus survives wired/Bluetooth reconnect; disconnect pauses safely and shows useful guidance; no action is mouse-only.
- **Test strategy / evidence:** Automate action/settings bounds and manually test real DualSense wired/Bluetooth, unplug/reconnect, alternate device index, remap conflicts and keyboard-only play.
- **Current implementation / remaining:** Nineteen action snapshots, independent keyboard/controller remapping, signed-axis capture, collision rejection, reserved menu recovery and saved overrides are implemented; 27 focused input checks pass, including injected alternate device index. Root adds disconnect pause/feedback. Wired/Bluetooth DualSense disconnect/reconnect and full keyboard-only navigation remain physical/manual checks.

### M06-002 — Finish menus, goal list, results and navigation

- **Owner:** A08
- **Priority:** P0 · **Milestone:** M06 · **Status:** QE review
- **Dependencies:** M04-006
- **Acceptance criteria:** Main menu, mode choice, HUD, goals, pause, settings and results use a cohesive polished typography/spacing/icon/motion system and contextual DualSense prompts per ART_DIRECTION. Score/combo feedback is lively but legible at 1080p; all screens are fully focus-navigable; restart remains fast and saving/record feedback is accurate. Remove temporary debug/template presentation.
- **Test strategy / evidence:** Traverse every screen using controller and keyboard, test long text/large scores, focus return and rapid input; capture representative screen evidence.
- **Current implementation / remaining:** Second UI pass separates goal notices from live combo/link feedback, uses current device/remapped interaction prompts, persists save warnings, preserves nested page history/focus/scroll and fits long scores/text. Focused tests and real 1080p/960 captures cover large UI scale and edge states. Standard capture now checks menu readiness before accepting evidence. Final physical-controller traversal and target-display/owner acceptance remain open; aggregate results belong in STATUS/QE.

### M06-003 — Implement accessibility and camera comfort settings

- **Owner:** A08 / A04
- **Priority:** P1 · **Milestone:** M06 · **Status:** QE review
- **Dependencies:** M06-001, M06-002, M05-005
- **Acceptance criteria:** High-contrast legible text, captions, UI scaling, separate audio levels, reduced shake/nonessential motion and camera sensitivity are available and persistent; camera avoids ordinary geometry occlusion; visual cues do not rely only on colour.
- **Test strategy / evidence:** Test settings round trip/default reset, muted play, increased UI scale, reduced shake/motion and high-contrast scenes; human legibility/motion review on target display.
- **Current implementation / remaining:** Persisted captions, separate mix levels, UI scale 1–1.4, camera sensitivity 0.5–2 and reduced motion remain validated. New bounds/navigation checks and rendered long-score/notice/caption/save-warning fixtures extend coverage at 1920×1080, 960×600 and640×480. Real target-display legibility, muted play and motion comfort remain open.

### M06-004 — Profile and optimize the representative full level

- **Owner:** A05 / A04 / A09
- **Priority:** P0 · **Milestone:** M06 · **Status:** Blocked
- **Dependencies:** M03-005, M05-005
- **Acceptance criteria:** Declare baseline Apple Silicon model; record frame-time distributions at 1080p over a ten-minute full-district route; address sustained misses and visible stutters; optimizations preserve gameplay and visual requirements.
- **Test strategy / evidence:** Capture build/hardware/power mode, frame/physics metrics and peak cases; compare before/after and rerun collision/score tests. Linux timings do not certify this target.
- **Current implementation / remaining:** The earlier cleanup's unit-mesh batching reduced its matched chase-view draw calls by approximately 18%, 12%, 27%, 9% across the former four-district workload. Those numbers predate the six-area/nonlinear redesign and are not current performance results. tools/profile.sh records bounded real-rendered fixed-view 1080p frame distributions and provenance; headless runs reject. See PERFORMANCE.md. A declared Apple Silicon model and ten-minute moving route are still unavailable; target certification remains blocked while local optimization can continue.

### M06-005 — Verify a real standalone macOS prototype export

- **Owner:** A01 / A09
- **Priority:** P0 · **Milestone:** M06 · **Status:** In progress
- **Dependencies:** M00-002, M04-004, M06-002
- **Acceptance criteria:** Use matching official export templates; produce a self-contained Apple Silicon-capable app; launch it on a target Mac, play offline and persist saves; document unsigned first-run behaviour without purchasing enrollment.
- **Test strategy / evidence:** Inspect architecture/package resources; perform fresh-copy launch, controller session, quit/relaunch and save-path tests on macOS. Block when hardware/templates are unavailable; never claim a tested export from settings alone.
- **Current implementation / remaining:** Unsigned macOS universal and Linux presets plus tools/export.sh are prepared; official Godot 4.6.3 templates and required notices were downloaded/verified into ignored local storage. Clean runtime `a99f993` produces both standalone ZIPs with isolated scene/voice/texture checks, mipmaps, source/import/licence provenance, CRC and architecture audits. Normal Linux headless and 1920×1080 startup both exit 0; exact package identities and harness diagnostics are in EXPORT. Real Mac first launch, controller/audio/save round trip remain unverified. See docs/testing/EXPORT.md.

### M06-006 — Complete target-hardware acceptance and tuning

- **Owner:** A09 / Owner
- **Priority:** P0 · **Milestone:** M06 · **Status:** Blocked
- **Dependencies:** M06-001–M06-005, M06-007, M04-006
- **Acceptance criteria:** Owner plays career/free skate and continuous combos on the real Mac/DualSense; all high-severity input, UX and performance defects are resolved and replayed; accessibility decisions are recorded.
- **Test strategy / evidence:** Full controller checklist, goal completion samples, long session and performance report; document remaining low-severity issues with explicit release disposition.
- **Current implementation / remaining:** A01/A09 must coordinate actual Mac/DualSense career/free-skate, reconnect, accessibility, save and performance checks with the owner. Linux tests/captures cannot certify this gate. Continue remaining implementation/packaging work while target evidence is unavailable.

### M06-007 — Final graphics/UI cleanup and owner visual acceptance

- **Owner:** A05 / A08 / A09 / Owner
- **Priority:** P0 · **Milestone:** M06 · **Status:** In progress
- **Dependencies:** M02-008, M03-007, M05-001, M05-002, M06-002, M06-003, M06-004
- **Acceptance criteria:** After core skating/combo acceptance, audit and replace every visible placeholder in world, skater, animation, lighting, signage and menus/HUD. Deliver realistic-but-fun Glasgow presentation and polished controller-first UI matching the owner's direction, with no generic blockout used as final art. Close visible clipping, flat/shiny material defects, repetitive facades, camera obstruction and UI layout/focus issues. Owner approves matched final captures and a playable visual build; untested screenshots alone cannot close the gate.
- **Test strategy / evidence:** Follow docs/testing/VISUAL_ACCEPTANCE.md: maintain a placeholder/defect inventory, matched before/after views and motion recordings for every district and UI state, provenance audit, gameplay regression and target-Mac 1080p/60 fps evidence. Capture pass/fail and owner comments. If time/credits end first, leave the job open with the exact unfinished asset/screen list; release M07 cannot bypass it.
- **Current implementation / remaining:** Terrain/adult-rider redesign now builds on the earlier environment/UI cleanup and verified free materials. Anatomical adult face/hands replace the old cartoon geometry; final art remains open for material repetition, skin/hair detail, NPCs, current Glasgow shopfront references, motion/transition quality, bright/shaded readability, target performance and owner realistic/fun acceptance. VISUAL_ACCEPTANCE and current terrain/rider/UI evidence retain exact unfinished work; this mandatory gate stays open.
- **Next bounded world/art subtask — A05/A02, after M07-007:** Reshape the remaining four broad core-court edges and long empty approaches into architectural islands/graded corners with nearby low-ledge/bank chains and readable exits. Fill or mask inappropriate perimeter voids while retaining water, intentional gaps and safe returns. Verify new collision/route/camera boundaries and matched chase/overview images. The accepted Close/undercroft/cutback/yard improve choices but do not certify commercial-reference density, coherent landscaping or final place quality.


### M06-008 — Add a six-area route map and readable terrain navigation

- **Owner:** A01 / A08, with A05 world data and A09
- **Priority:** P0 · **Milestone:** M06 · **Status:** QE review
- **Dependencies:** M03-008, M03-009, M03-011, M03-012, M06-002
- **Requirements:** Help players understand the connected city, its elevation and optional jump/return choices using the actual authored routes, without adding another gameplay input binding or changing career progress.
- **Acceptance criteria:** CITY MAP & ROUTES is reachable from pause and goals with existing controls. It draws final runtime route polylines and all six checkpoints, readable labels, current rider position/heading, elevation cues and distinguishable jump versus safe links. Data follows changed geometry; no static illustration falsely depicts unsupported connections. Open/close/back preserves pause, focus and page history. Captions/prompts and 1–1.4 UI scale remain usable; exploration labels do not imply new career goals.
- **Test strategy / evidence:** Compare map data to world route/checkpoint queries; inject real keyboard/gamepad navigation; test nested focus/pause return and long labels at normal/increased scale. Capture the actual ready production map page before/after a changed rider position and inspect route/legend readability.
- **Current implementation / remaining:** The production map is implemented from runtime routes/checkpoints with pause/goals access, player heading, elevation cues and jump links. The source-stable 21-frame set shows all six readable area labels and the new cross-links; help text wraps inside the scrollable page. Main/menu integration passes in the final 955/0 aggregate; the corrected 15:42:35 UTC capture is ready and its labels/branches were reviewed. Physical controller/target-display readability stays open.

## M07 — Release readiness and delivery

**Source:** Proposed continuation. **Exit gate:** All Release 1 requirements have evidence or an explicit approved scope change; a tested macOS artifact, instructions, provenance and future handoff are ready for owner review with no paid publication.

### M07-001 — Run complete regression and close release defects

- **Owner:** A09
- **Priority:** P0 · **Milestone:** M07 · **Status:** In progress
- **Dependencies:** M04-006, M05-005, M06-006
- **Acceptance criteria:** Every release requirement maps to passing evidence; no critical/high defect remains; full career/free-skate, all ten goals, save recovery, every trick and all four districts are checked on the candidate build.
- **Test strategy / evidence:** Run local suite and target hardware matrix; record build identifier, test counts and manual evidence; independently verify prior fixes rather than relying on implementation claims.
- **Current implementation / remaining:** Independent gameplay/career/UI regressions now include the continuous all-ten-goal route; final aggregate counts and real capture results are in STATUS/QE. Human all-goals play, final release candidate, target hardware matrix and closure of release-level defects remain outstanding.

### M07-002 — Complete title, asset and dependency release audit

- **Owner:** A03 / A01 / Owner
- **Priority:** P0 · **Milestone:** M07 · **Status:** In progress
- **Dependencies:** M05-005, M00-005
- **Acceptance criteria:** All shipped files have provenance and required notices; final title/signage is reviewed; project code/content licence decision is recorded by the owner before granting public rights; no unapproved voice/music/branding remains.
- **Test strategy / evidence:** Audit packaged file list against register and licence texts; inspect engine notices and voice permissions; document unresolved title/licence decisions as blockers.
- **Current implementation / remaining:** Original art/SFX and inspected rail/Flite/Godot sources have provenance records and retained notices; packaging includes required notice files. A03/A01 still need the actual shipped-file audit and final title/licensing disposition. No public licence grant or final package audit is inferred from development notices.

### M07-003 — Package and verify the final macOS artifact

- **Owner:** A01 / A09
- **Priority:** P0 · **Milestone:** M07 · **Status:** In progress
- **Dependencies:** M07-001, M07-002, M06-005
- **Acceptance criteria:** Reproducible local export produces a versioned app/archive with checksum and required notices; fresh-copy macOS launch, offline play, controller and save persistence pass; any unsigned limitations are described accurately.
- **Test strategy / evidence:** Export from recorded commit/engine/templates, verify artifact checksum, test fresh extraction and launch on target Mac. Do not buy signing enrollment or upload to paid distribution.
- **Current implementation / remaining:** Reproducible local unsigned export tooling, verified official templates and package/architecture/checksum checks are prepared. Unsigned Linux/macOS cleanup artifacts from `a99f993` pass resource, notice/provenance, CRC and architecture checks; their source identity/digests are recorded in EXPORT.md. Linux headless and rendered normal startup passed with exit 0; Mac launch remains unverified. Paid signing, hosting and release publication remain outside this preparation.

### M07-004 — Write player instructions, release notes and support handoff

- **Owner:** A02 / A08 / A01
- **Priority:** P1 · **Milestone:** M07 · **Status:** In progress
- **Dependencies:** M07-001, M07-003
- **Acceptance criteria:** Instructions cover install/first launch, full controls, modes/goals, save location/reset, accessibility and known issues; release notes distinguish shipped scope; remaining backlog and recovery steps are durable.
- **Test strategy / evidence:** Have a reviewer follow instructions from the packaged artifact without development context; verify links/paths/version and compare controls against actual mappings.
- **Current implementation / remaining:** docs/PLAYER-GUIDE.md and export instructions provide source/native-play controls, goals/settings/save guidance; current status and backlog support resumption. Refresh them against the actual packaged candidate and have a reviewer follow them before calling release instructions complete.

### M07-005 — Make the evidence-based release decision and owner handoff

- **Owner:** A01 / A09 / Owner
- **Priority:** P0 · **Milestone:** M07 · **Status:** Blocked
- **Dependencies:** M07-001–M07-004
- **Acceptance criteria:** A09 recommends readiness with complete evidence, A01 checks architecture/scope, and owner reviews the playable artifact and distribution decision; no unapproved publication, purchase or hosted job occurs; future work is recorded.
- **Test strategy / evidence:** Review requirement coverage and defects; verify artifact identity against tested build; record owner feedback and any approved exceptions. A release decision is distinct from a local build or an uploaded file.
- **Current implementation / remaining:** Release acceptance awaits the candidate/regression/licence/package evidence plus real Mac/DualSense, listening and final visual gates. The owner’s authorization to continue implementation remains active; do not ask for routine next-ticket approval or treat a local build as a completed release decision.

### M07-006 — Verify and preserve the terrain/adult-rider redesign checkpoint

- **Owner:** A09 independent QE / A01 integration, with A05/A08 evidence
- **Priority:** P0 · **Milestone:** M07 · **Status:** QE review
- **Dependencies:** M03-008–M03-012, M05-006, M06-008; existing scoring/save/input regressions
- **Requirements:** Produce a concrete, reproducible redesign checkpoint with physical routes, intact career/saves, actual terrain/character/map imagery, compatible assets and explicit remaining human/hardware gates. Old geometry results cannot certify this build.
- **Acceptance criteria:** Clean import/aggregate suite passes after source settles. Real movement validates core slopes, fountain curve/exit, Clyde takeoff/landing/miss recovery and park uphill/downhill/return. All ten original goals complete through physical core routes within 120 seconds with profile writes disabled; all six areas are explored separately and four career visits remain distinct. Capture real chase/overview/map/rider evidence with source/fixtures; audit new assets and update six-area render cost. Rebuild any distributed candidate from the tested source, and preserve exact open defects/tasks if time/credits end. No Mac/physical-controller/final visual acceptance is invented.
- **Test strategy / evidence:** A09 runs focused independent route/hazard/career checks and the final aggregate once integrated; capture runners reject headless and verify ready scenes/menus. Inspect PNGs and real-input motion, record source hashes/fixture limits, compare frame-time evidence only under matching settings, and verify export resources/provenance if packages change. A01 records results in STATUS/ACTIVE_WORK/INTERFACES and keeps M06-006/M06-007 open pending actual acceptance.
- **Current implementation / remaining:** The final ordinary check/import completes exit 0 with 955 passed/0 failed and a clean error scan. Static routes 157/0, topography 60/0, career integration 23/0 and the real ten-goal route are included; all goals complete at 75.20s and the rider returns at 88.00s over 1,199.52m with 20,000/3,200 and zero bails/stalls. The corrected capture passes 21/21 and lead/root/geometry review clears the bounded topology defects; manifest SHA-256 is f0b3a30987a7731371ebb4b74102751dfbdfd192194a7db7b574669ba5b0674b. Final rider motion is verified at 222 frames/7.4s, zero errors and stable source. Both native exports/audits and bounded normal Linux headless/rendered startup now pass exit 0 from clean runtime a30127940eacd4d2fe56d07a34ee1af4bacf95e5; source, video, hashes and the final handoff are preserved in STATUS/EXPORT. Package inputs match the final capture sources. Previous package/performance identities remain historical; this ticket stays in QE review for the new workload/render-cost and recorded acceptance evidence still open below. Current-reference access, hardware, human route enjoyment/listening, new workload profiling and owner visual acceptance remain outstanding.

### M07-007 — Verify nonlinear routes and local encounters with a complete handoff

- **Owner:** A09 independent QE / A01 integration, with A02/A05/A07 capture and review
- **Priority:** P0 · **Milestone:** M07 · **Status:** QE review
- **Dependencies:** M03-013, M03-014, M04-007, M05-007, M07-006; existing gameplay/save/input regressions
- **Requirements:** Complete the new route/Glasgow-fun work alongside every unfinished terrain/adult-rider capture, check, export and handoff obligation. Preserve precise built/deferred scope so another session can continue without this chat.
- **Acceptance criteria:** Final source passes new independent physical-route and encounter checks plus the full regression suite. All ten original career goals and protected save/free-skate rules remain intact. Actual source-stable chase/overview/map/NPC/challenge images and refreshed rider motion show the final candidate with documented fixtures, hashes and limits. Local packages are rebuilt/audited from the tested source and launch evidence is distinguished by platform. Close concrete rendered defects, retain all unimplemented suggestions and remaining human/hardware/reference work with owners and commands; no paid publication or false final-fun acceptance.
- **Test strategy / evidence:** Run focused routes/clearance/encounter negative and successful-play cases, then the final ordinary scheduler suite. Render after owners freeze source, inspect every retained image and readiness/layout of map/encounter pages, verify source hashes and re-export/launch locally as root directs. Recheck costs only with valid rendered profiling; screenshots and headless tests do not certify 60 fps.
- **Current implementation / remaining:** Final ordinary tools/check.sh passes 955/0, exit 0, with clean import/error scan; full logs are preserved under docs/testing/logs/glasgow-nonlinear-final*.log. Current focused evidence includes static 157/0, physical correction 30/0, local 5,000-point combo 3/0 and encounters 30/0. The same aggregate completes all ten original goals at 75.20s and returns at 88.00s over 1,199.52m, with 20,000/3,200 and zero bails/stalls. Source-stable captures are complete and reviewed: 21/21 at 15:42:35 UTC. Refreshed rider motion is verified at 222 frames/7.4s with zero errors, clean decode and unchanged pinned source. Both native exports/audits and normal Linux headless/rendered startup pass exit 0 from clean runtime a30127940eacd4d2fe56d07a34ee1af4bacf95e5. Source/video/checksum refresh and the durable root handoff are complete; exact identities and tracked native-redesign receipts are in STATUS/EXPORT. This ticket remains in QE review with M07-006/new-workload profiling and human/hardware/final-art evidence open. Existing M07-006 is retained, not replaced.
