# Full Release 1 task backlog

Title: **Tam Hawks Pro Skater**. Baseline date: 17 October 2026. This is the durable local source of task truth; these entries are not claims that GitHub issues have been published. Latest implementation and command evidence is in [STATUS](../STATUS.md). Product scope maps through [requirements](../product/requirements.md).

There are **54 tickets** across eight dependency-based milestones. M00–M03 follow the supplied document. Its text stops after M03; **M04–M07 are a proposed continuation derived from the document's complete Release 1 scope**, not supplied missing text. The owner has authorized implementation of all remaining work within the no-spend constraint. “Proposed continuation” identifies the roadmap text’s source, not a requirement to seek routine permission before those tasks. Nothing below implies unattended development or paid work.

## How to use this backlog

- Priorities: **P0** blocks a core milestone or release; **P1** is still required for Release 1 but can follow its prerequisites. No release feature is silently optional because it is P1.
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

M00 foundation and the recorded momentum/reuse/specification work are complete. The current implementation now includes grinds, manuals, reverts, a 0.35-second combo continuation window, specials, named gaps, a connected four-district world, ten career goals, local saves/unlocks, original environment/rider art, synthesized audio with licensed local speech, settings and input remapping. Implemented systems remain in **QE review** where integration, controller or acceptance work is outstanding; the first environment/rider presentation and final cleanup remain **In progress**.

The final integrated Linux suite passed **717 assertions, 0 failures**, exit 0, with clean import/engine logs. Fifteen actual rendered gameplay/menu/district captures passed and were reviewed; screenshots and exact scenarios are in STATUS/QE-REPORT. Native packages were generated from clean commit `13e76ac`, both isolated main-scene/audio checks passed and universal Mac architecture/ZIP notices were verified; actual Mac launch remains open. Standalone Linux normal headless and 1920×1080 rendered launch both exited 0; evidence is recorded in EXPORT.md.

No physical DualSense, target-Mac launch/performance, human listening, subjective skating feel or final realistic/fun visual acceptance is claimed. The supplied first-release scope remains intact, including voiced NPC reactions and the mandatory final art/UI cleanup. Static bystanders, synthesized speech and procedural architectural detail are implemented first passes, not automatically the finished quality target.

## Remaining acceptance and reference work

| Tickets / accountable roles | Concrete next evidence or work | Current boundary |
|---|---|---|
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
- **Current implementation / remaining:** All four districts connect through paired streets and outer back lanes; nine ramps, six rails, three gaps, shortcuts and a returnable secret alcove exist. Eighty-nine focused world checks cover production collision/markers/cone pause/reset. Human full-circuit/three cross-district combo-line acceptance and verified facade dependency M03-007 remain open.

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
- **Current implementation / remaining:** Initial thresholds are 1,000/5,000/15,000 total and 3,000 for one combo. Functional route and model tests are not balance data: A06/A09 must gather timed full-career runs at multiple skill levels, tune with recorded distributions and obtain replay-loop feedback.


## M05 — Art, audio and ambient characters

**Source:** Proposed continuation. **Exit gate:** Believable, detailed, realistic-but-fun environments/characters, skating audio, ambience and captioned NPC reactions support the accepted skating loop; blocky placeholder art is not the release target. Complete provenance and no additional spend remain required.

### M05-001 — Replace blockout with detailed Glasgow environment art and lighting

- **Owner:** A05
- **Priority:** P1 · **Milestone:** M05 · **Status:** In progress
- **Dependencies:** M03-005
- **Acceptance criteria:** After M02-008, A05 coordinates with A08 to produce one representative facade/skating approach, skater and polished HUD treatment; obtain owner review and capture frame cost before repeating the treatment across the world. Follow docs/product/ART_DIRECTION.md: replace generic cuboids and flat placeholder surfaces with believable facade proportions, bevelled architectural detail, varied windows/doors, authored or free licensed stone/brick/paving/glass materials, coherent lighting and recognisable shopfront edges. Keep ramps/rails readable and preserve accepted collision. No voxel/blocky final aesthetic; no paid assets or engine switch without evidence.
- **Test strategy / evidence:** Representative scene/HUD review and measured frame cost, then matched before/after captures in all districts; replay reference lines and compare frame cost; audit all assets/procedural sources in the provenance register.
- **Current implementation / remaining:** city_art.gd adds generated masonry/paving/slate materials, batched detailed windows, cornices/roof/chimney detail, civic clock, gallery portico, arched canopy, dressed stalls and rounded foliage. Real district captures and 89 collision checks exist. Repeating materials, stylized forms, unsurveyed shopfronts, frame-cost review and owner visual acceptance remain unfinished.

### M05-002 — Create readable original skater and trick animation

- **Owner:** A05 / A04
- **Priority:** P1 · **Milestone:** M05 · **Status:** In progress
- **Dependencies:** M02-008
- **Acceptance criteria:** Replace the primitive rider/board with believable proportions, detailed clothing/board materials and a coherent rig. Push, ollie, flip, actual hand-to-board grab, grind, manual, revert, special and bail must show convincing weight/contact and readable motion. Reuse suitable free licensed models/animations with provenance; visuals follow gameplay without adding input delay.
- **Test strategy / evidence:** Inspect every trick at slow and normal speed, verify state sync and camera readability, then rerun action timing and combo regression tests.
- **Current implementation / remaining:** skater_visual.gd replaces the cuboid rider with rounded articulated anatomy/clothing/face/hair and a curved deck with wheels/trucks/hardware. Push, landing compression, air tuck and a hand-to-board grab exist (measured 1.1cm target reach); 39 gameplay plus 21 momentum checks passed during review. Final animation weight/contact, variation and hardware/owner presentation acceptance remain open.

### M05-003 — Produce and integrate local synthetic skating SFX

- **Owner:** A07
- **Priority:** P1 · **Milestone:** M05 · **Status:** QE review
- **Dependencies:** M02-005
- **Acceptance criteria:** Original reproducible sounds cover wheel roll, jump, landing, grind, bail, combo and UI; event mapping prevents overlap spam; sound parameters reflect surface/speed where useful; no paid API is used.
- **Test strategy / evidence:** Record generator/source provenance; test event counts, mute/volume, pause/reset, rapid landing and long grind; listen for clipping and fatigue.
- **Current implementation / remaining:** Original locally synthesized contact/grind loops and bounded ollie/landing/grind/bail/bank/UI sounds are integrated. Audio state/PCM tests cover debounce, pause, speed/pitch, mute and crossfade; no human listening or fatigue/clipping acceptance has run. See docs/testing/AUDIO.md.

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
- **Current implementation / remaining:** The title screen/career-free-skate selection, HUD, ten-goal list, pause/results/settings, records/unlocks/cosmetics, contextual prompts and remapping controls have an implemented visual/interaction pass. Twenty-eight independent UI integration checks pass for Enter/Tab/Escape, controls conflict/cancel/rebind/reset, rebound physical ollie, settings, cosmetics, goals/pause origins, synthetic disconnect and results/replay. Actual 1280×800 and 1.4× UI-scale captures were reviewed; final recapture confirmed the wrapped-label/numeric-value fixes, and independent QE found no blocking overlap/clipping in nine reviewed frames. Physical controller traversal, target-Mac 1080p legibility and owner presentation acceptance remain open.

### M06-003 — Implement accessibility and camera comfort settings

- **Owner:** A08 / A04
- **Priority:** P1 · **Milestone:** M06 · **Status:** QE review
- **Dependencies:** M06-001, M06-002, M05-005
- **Acceptance criteria:** High-contrast legible text, captions, UI scaling, separate audio levels, reduced shake/nonessential motion and camera sensitivity are available and persistent; camera avoids ordinary geometry occlusion; visual cues do not rely only on colour.
- **Test strategy / evidence:** Test settings round trip/default reset, muted play, increased UI scale, reduced shake/motion and high-contrast scenes; human legibility/motion review on target display.
- **Current implementation / remaining:** Persisted captions, master/SFX/ambience levels, UI scale 1–1.4, camera sensitivity 0.5–2 and reduced motion are implemented with validated defaults/bounds. Independent UI integration verifies settings wiring into audio/camera/reduced motion/captions; actual display readability, muted play and motion comfort still need human evidence.

### M06-004 — Profile and optimize the representative full level

- **Owner:** A05 / A04 / A09
- **Priority:** P0 · **Milestone:** M06 · **Status:** Blocked
- **Dependencies:** M03-005, M05-005
- **Acceptance criteria:** Declare baseline Apple Silicon model; record frame-time distributions at 1080p over a ten-minute full-district route; address sustained misses and visible stutters; optimizations preserve gameplay and visual requirements.
- **Test strategy / evidence:** Capture build/hardware/power mode, frame/physics metrics and peak cases; compare before/after and rerun collision/score tests. Linux timings do not certify this target.
- **Current implementation / remaining:** Material sharing/MultiMesh batching and bounded audio/resource work are implemented optimizations, but no declared Apple Silicon baseline or ten-minute 1080p frame-time run exists. Target-performance certification is blocked on access to that Mac; local profiling and defect correction can continue independently.

### M06-005 — Verify a real standalone macOS prototype export

- **Owner:** A01 / A09
- **Priority:** P0 · **Milestone:** M06 · **Status:** In progress
- **Dependencies:** M00-002, M04-004, M06-002
- **Acceptance criteria:** Use matching official export templates; produce a self-contained Apple Silicon-capable app; launch it on a target Mac, play offline and persist saves; document unsigned first-run behaviour without purchasing enrollment.
- **Test strategy / evidence:** Inspect architecture/package resources; perform fresh-copy launch, controller session, quit/relaunch and save-path tests on macOS. Block when hardware/templates are unavailable; never claim a tested export from settings alone.
- **Current implementation / remaining:** Unsigned macOS universal and Linux presets plus tools/export.sh are prepared; official Godot 4.6.3 templates and required notices were downloaded/verified into ignored local storage. Clean commit `13e76ac` now produces both standalone ZIPs; isolated main-scene/audio loads, universal Mac architecture and actual ZIP notice checks pass. Real Mac first launch, controller/audio/save round trip remain unverified. See docs/testing/EXPORT.md.

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
- **Current implementation / remaining:** Environment/rider/UI cleanup has begun and real captures show the first improvement. Preserve the open inventory: repeated/stylized materials, unsurveyed shopfronts, rider/NPC motion quality, every screen at supported scale (including final verification of wrapped labels/values at 1.4×), current visual defects, target performance and owner realistic/fun presentation acceptance. No final-art or release clearance is claimed.


## M07 — Release readiness and delivery

**Source:** Proposed continuation. **Exit gate:** All Release 1 requirements have evidence or an explicit approved scope change; a tested macOS artifact, instructions, provenance and future handoff are ready for owner review with no paid publication.

### M07-001 — Run complete regression and close release defects

- **Owner:** A09
- **Priority:** P0 · **Milestone:** M07 · **Status:** In progress
- **Dependencies:** M04-006, M05-005, M06-006
- **Acceptance criteria:** Every release requirement maps to passing evidence; no critical/high defect remains; full career/free-skate, all ten goals, save recovery, every trick and all four districts are checked on the candidate build.
- **Test strategy / evidence:** Run local suite and target hardware matrix; record build identifier, test counts and manual evidence; independently verify prior fixes rather than relying on implementation claims.
- **Current implementation / remaining:** The final integrated suite passed 717 checks with no failures, including independent gameplay/career/UI regressions; all fifteen final captures succeeded and were reviewed. Final candidate, all-goals play, target hardware matrix and closure of release-level defects remain outstanding; use latest STATUS/QE totals.

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
- **Current implementation / remaining:** Reproducible local unsigned export tooling, verified official templates and package/architecture/checksum checks are prepared. Actual unsigned Linux/macOS artifacts now exist from clean commit `13e76ac`, with successful resource/notice/architecture inspection and recorded SHA-256 digests in EXPORT.md. Linux headless and rendered normal startup passed with exit 0; Mac launch remains unverified. Paid signing, hosting and release publication remain outside this preparation.

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
