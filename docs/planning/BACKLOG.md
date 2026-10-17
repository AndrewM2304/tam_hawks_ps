# Full Release 1 task backlog

Title: **Tam Hawks Pro Skater**. Baseline date: 17 October 2026. This is the durable local source of task truth; these entries are not claims that GitHub issues have been published. Latest implementation and command evidence is in [STATUS](../STATUS.md). Product scope maps through [requirements](../product/requirements.md).

There are **54 tickets** across eight dependency-based milestones. M00–M03 follow the supplied document. Its text stops after M03; **M04–M07 are a proposed continuation derived from the document's complete Release 1 scope**, not supplied missing text. Nothing below implies unattended development or paid work.

## How to use this backlog

- Priorities: **P0** blocks a core milestone or release; **P1** is still required for Release 1 but can follow its prerequisites. No release feature is silently optional because it is P1.
- Statuses: Planned → Ready → In progress → QE review → Done. Blocked records the missing dependency and responsible role. Move to Done only when acceptance evidence is linked; update STATUS at the same time.
- Owners are logical roles: A01 orchestration, A02 product, A03 research/licences, A04 gameplay, A05 world/art, A06 missions/progression, A07 audio/narrative, A08 UI/UX, A09 independent QE. Owner = the human owner when a hardware/creative gate requires them.
- Dependency ranges include every task between the listed IDs. Planning/research may proceed while an earlier human gate is pending, but its dependent milestone cannot be certified complete.
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

M00 foundation is complete: pinned engine reuse, source startup, 94 automated assertions, a deliberate harness-failure probe, three rendered captures and durable documentation are verified in STATUS. M01-001–006 are implemented and in QE review: automated checks pass; physical input and human feel/camera checks remain with M01-007. M01 cannot be closed without the owner's physical DualSense/target-Mac playtest. M01-008 momentum fixes and M02-001 specification are complete; first playable rail grinding is in M02-002 QE review, while manuals/reverts and M03–M07 remain planned; a basic aerial scoring loop does not complete grinds, manuals, reverts or career progression.

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

### M01-002 — Implement stable arcade ground movement

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-001
- **Acceptance criteria:** Acceleration, maximum speed, braking and steering are consistent; floor contact remains stable; no non-finite transforms or uncontrolled reverse motion; restart restores a safe spawn.
- **Test strategy / evidence:** Simulate acceleration/braking/turn/reset and floor contact; document central tuning constants and a repeatable hands-on route.

### M01-003 — Implement ollies and skateable ramp transitions

- **Owner:** A04 / A05
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-002
- **Acceptance criteria:** Fresh grounded ollie input launches and lands reliably; air control remains bounded; ordinary ramp collision supports ascent/descent/launch at intended speeds without snagging or falling through.
- **Test strategy / evidence:** Run grounded/airborne jump checks and a ramp traversal simulation; inspect rendered ramp contact and record manual approach angles.

### M01-004 — Implement initial aerial tricks and landing feedback

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-003
- **Acceptance criteria:** Flip, grab and spin actions produce identifiable original movement and one eligible award each; landing transitions signal once; unsafe recovery/bail behaviour is explicit rather than silently awarding invalid tricks.
- **Test strategy / evidence:** Test input edges, air/ground eligibility, landing transition count and reset; manual sequence: ollie, flip/grab/spin, land, repeat and compare HUD.

### M01-005 — Provide a usable follow camera

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-002
- **Acceptance criteria:** Camera tracks and looks ahead of the skater with controllable smoothing; spawn/restart has a useful frame; ordinary turns and jumps do not obscure the entire landing area.
- **Test strategy / evidence:** Inspect captured frames at spawn, turn and jump; play a route and log camera/comfort defects. Full occlusion/accessibility work remains M06.

### M01-006 — Integrate prototype run, score, HUD and fast restart

- **Owner:** A01 / A08
- **Priority:** P0 · **Milestone:** M01 · **Status:** QE review
- **Dependencies:** M01-004, M01-005
- **Acceptance criteria:** A 120-second active-play run and free skate work; pause freezes time; basic tricks accumulate and bank once on landing with repeat degradation; HUD shows score/combo/timer and results; restart clears transient state.
- **Test strategy / evidence:** Unit-test score/bank/drop/reset and integration-test timer/pause/mode/restart; capture actual HUD; do not label this M02 continuous combo completion.

### M01-007 — Obtain independent M01 review and owner controller playtest

- **Owner:** A09 / Owner
- **Priority:** P0 · **Milestone:** M01 · **Status:** Blocked
- **Dependencies:** M01-001–M01-006, M00-004
- **Acceptance criteria:** Owner plays the prototype on the target Mac with a real DualSense and records feel feedback; A09 verifies core loop and identifies regressions; material responsiveness/landing/camera issues are fixed and replayed.
- **Test strategy / evidence:** Follow docs/testing/STRATEGY.md M01 checklist; record device/connection/macOS/build and observations. Blocker: physical target hardware and owner feedback; A01 coordinates. Linux tests cannot close this ticket.

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
- **Test strategy / evidence:** Review a transition/edge-case table with A08/A09; test trick data validation, unknown IDs and illegal transitions. Implemented ADR-006 and game/tricks/trick_catalog.gd; 27 focused assertions cover records, unknown IDs, transition guards, defensive copies and scoring compatibility. The future 0.35-second landing window remains specified, not implemented. Controls remain provisional pending physical QA.

### M02-002 — Implement rail acquisition, travel, release and balance

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M02 · **Status:** QE review
- **Dependencies:** M02-001, M01-003, M02-010
- **Acceptance criteria:** Integrate the adopted GrindLine geometry helper with capture/travel/balance; authored rail metadata supports forgiving but bounded snap; speed/direction persist along rails; jump release and end release are reliable; balance risk can bail; unrelated ledges do not award rail points.
- **Test strategy / evidence:** Simulate approach angle/speed bounds, adjacent rails, reverse travel, ends, jumps, balance extremes and no-rail cases; human DualSense line trial. Implemented game/tricks/grind_ride.gd plus skater/world/main/input/HUD integration; two actual rails, held L/R2 capture, bidirectional travel, balance, swept obstacle rejection, release/ollie/end, cooldown, one entry award and pending-combo continuity. Pure helper and production-scene tests plus a real rendered ground-approach capture verify the local slice; see docs/testing/GRINDING.md. Human DualSense line trial remains open; no complete M02 acceptance is claimed.

### M02-003 — Implement manuals as combo links

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M02 · **Status:** Planned
- **Dependencies:** M02-001
- **Acceptance criteria:** Deliberate input enters an eligible ground manual, balance feedback is visible, travel sustains an active combo, and release/failure resolve consistently; cannot start while in an incompatible state.
- **Test strategy / evidence:** Test entry windows, hold duration, balance drift, clean exit, bail and state conflict; play repeated landing-to-manual links.

### M02-004 — Implement reverts and landing continuity windows

- **Owner:** A04
- **Priority:** P0 · **Milestone:** M02 · **Status:** Planned
- **Dependencies:** M02-001, M02-003
- **Acceptance criteria:** Revert is accepted only within a documented landing window; visual turn and speed cost are readable; valid revert/manual sequences maintain combos; repeated input cannot preserve a combo forever.
- **Test strategy / evidence:** Boundary-test window timing, early/late input, duplicate events and speed limits; manual ramp-to-revert-to-manual trial.

### M02-005 — Complete combo scoring, banking, multiplier and bail rules

- **Owner:** A04 / A06
- **Priority:** P0 · **Milestone:** M02 · **Status:** Planned
- **Dependencies:** M02-002, M02-003, M02-004
- **Acceptance criteria:** A single authoritative system links all eligible moves, applies documented multipliers and repeat degradation, banks exactly once on resolution, and loses only unbanked points on bail; exploit bounds are explicit.
- **Test strategy / evidence:** Deterministic mixed-trick sequences, zero/large values, repeated move abuse, simultaneous events, timeout and restart cases; replay a scored reference line.

### M02-006 — Score spins and unlock/execute special tricks

- **Owner:** A04 / A06
- **Priority:** P1 · **Milestone:** M02 · **Status:** Planned
- **Dependencies:** M02-001, M02-005
- **Acceptance criteria:** Completed rotation is scored consistently; meter gain/use and special eligibility are communicated; at least two original special tricks have distinct input/animation/value; meter cannot be farmed while inactive.
- **Test strategy / evidence:** Test rotation thresholds/direction, meter bounds/reset, unavailable special input and consumption once; controller execution test with HUD feedback.

### M02-007 — Implement reusable named-gap detection and rewards

- **Owner:** A04 / A06
- **Priority:** P1 · **Milestone:** M02 · **Status:** Planned
- **Dependencies:** M02-005
- **Acceptance criteria:** Data defines start/end, direction, airborne/route conditions and original gap names; valid traversal awards once; invalid approaches, teleport/reset and overlapping triggers do not duplicate points.
- **Test strategy / evidence:** Simulate valid, reverse, repeated and interrupted crossings; author a test gap and verify its displayed name/value during an actual route.

### M02-008 — Polish trick feedback and certify continuous combo feel

- **Owner:** A08 / A09
- **Priority:** P0 · **Milestone:** M02 · **Status:** Planned
- **Dependencies:** M02-002–M02-007, M01-007
- **Acceptance criteria:** Trick history, multiplier, balance and bail cues remain readable; A09 completes exploit/regression checks; owner can deliberately link air, rail, revert and manual in a repeatable line and accepts feel.
- **Test strategy / evidence:** Run full scoring/state tests, five-minute controller combo playtest, screenshot/video review and fresh-player readability notes; unresolved feel defects block M02 exit.

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
- **Test strategy / evidence:** tests/rail_geometry_tests.gd covers42 assertions. Initial duplicate-bake and endpoint-tangent failures were corrected without weakening checks; the complete suite covers136 assertions. Source/modifications/licence in research and provenance records.

## M03 — Glasgow grey-box

**Source:** Supplied roadmap. **Exit gate:** Four distinct connected districts, landmark silhouettes, viable lines, shortcuts, named gaps and secret areas are traversable and enjoyable with the accepted controller.

### M03-001 — Build George Square learning and combo routes

- **Owner:** A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** Planned
- **Dependencies:** M01-003, M02-007
- **Acceptance criteria:** Expand the prototype into a deliberate district with civic silhouettes, safe beginner loop, advanced line, statue/cone interaction space and stable collision; route choices work at supported speeds.
- **Test strategy / evidence:** Play and record both loops, obstacle contacts, boundary recovery and camera sightlines; inspect collision and gap placements with A04/A09.

### M03-002 — Build Royal Exchange Square and arcade passage

- **Owner:** A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** Planned
- **Dependencies:** M02-002, M02-007
- **Acceptance criteria:** Original gallery-inspired court, circular ledge route, precision gaps and arcade passage are skateable; at least two connections and a secret hook exist; signs and assets use original design.
- **Test strategy / evidence:** Traverse all routes in both intended directions, test grind acquisition/exit, inspect camera clearance and provenance entries.

### M03-003 — Build Central Station district and elevated route

- **Owner:** A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** Planned
- **Dependencies:** M02-002, M02-007
- **Acceptance criteria:** Original station/canopy silhouettes, long approaches, bank-to-rail links and an elevated line with safe exits exist; reserve the platform gap/goal triggers without copying a real station plan.
- **Test strategy / evidence:** Record approach/landing speeds, rail continuity, recovery from missed transfers and checkpoint reachability; review collision/render cost.

### M03-004 — Build Barras / Barrowlands district and market route

- **Owner:** A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** Planned
- **Dependencies:** M02-002, M02-007
- **Acceptance criteria:** Original market stalls, venue-inspired silhouette and technical route establish the district; collectible positions and hidden recording route are reachable; narrow turns do not snag the skater.
- **Test strategy / evidence:** Traverse beginner/technical paths, test stall collisions and secret access/exit; inspect original signage and line readability.

### M03-005 — Join districts, author secrets and validate the whole level

- **Owner:** A05 / A09
- **Priority:** P0 · **Milestone:** M03 · **Status:** Planned
- **Dependencies:** M03-001–M03-004, M03-007, M02-008
- **Acceptance criteria:** All four districts form one continuous level; at least three cross-district combo links, one shortcut and one hidden area work; no transition breaks combos; all named gaps and respawns are valid; owner accepts traversal.
- **Test strategy / evidence:** Run a full four-checkpoint circuit and every authored line; log route times, collision/camera defects and missing returns; human exploration playtest and rendered overview.

### M03-006 — Verify Glasgow shopfronts, street edges and landmark relationships

- **Owner:** A03 / A05
- **Priority:** P0 · **Milestone:** M03 · **Status:** Blocked
- **Dependencies:** M00-005; current reference-site access
- **Acceptance criteria:** Build a dated reference register for all four districts using official venue/business sources and public maps/Street View where accessible. Verify at least three distinctive boundary anchors per district, street/corner relationships, approximate frontage proportions and adjacent entrances. Separate stable architecture from changing tenancies; distinguish inspected facts, dated secondary leads and unverified candidates. No paid API, imagery scraping or map assets bundled in the game.
- **Test strategy / evidence:** Cross-check source URLs and capture dates, review an annotated district/block sketch against inspected references, record source licensing separately for any imported asset. Initial leads/access evidence: docs/research/GLASGOW_REFERENCES.md. Blocker: proxy HTTP 403 for official/map sites; narrow domain additions are now present in the saved base configuration, but current-instance requests still fail. Retry in a fresh environment using that configuration; do not ask the owner to repeat the same edit without evidence. Dated GitHub address data does not establish current storefront geometry.

### M03-007 — Replace generic perimeter shops with recognisable Glasgow boundaries

- **Owner:** A05 / A03
- **Priority:** P0 · **Milestone:** M03 · **Status:** Planned
- **Dependencies:** M03-006, M03-001–M03-004
- **Acceptance criteria:** Use verified shops/venues and street-edge relationships to give each district a recognisable perimeter; retain characteristic entrances, corners, facade rhythm and landmark sightlines while compressing travel for gameplay. Reproduce architecture with authored/licensed assets and factual signage references; do not substitute the same generic shop row in every district. Border buildings need not have enterable interiors. Keep collision simple and clear of accepted skating routes.
- **Test strategy / evidence:** Compare blockout and later detailed facade captures against the source register; verify each district's three anchors and deliberate geography changes; replay border-adjacent lines and inspect camera occlusion, collision and asset provenance.

## M04 — Missions and progression

**Source:** Proposed continuation. **Exit gate:** Career and free skate are complete, ten objectives work, goals/records/unlocks persist safely and balancing supports repeated two-minute attempts.

### M04-001 — Finalize career/free-skate lifecycle and results contract

- **Owner:** A06 / A08
- **Priority:** P0 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M02-005, M01-006
- **Acceptance criteria:** Mode eligibility, 120-second active timer, final combo resolution, pause and results follow a documented rule; restart is immediate; career completion events cannot fire accidentally in free skate.
- **Test strategy / evidence:** Integration-test timeout during each trick state, pause at boundaries, mode switches, rapid restart and double results; controller navigation smoke.

### M04-002 — Build data-driven objective tracking

- **Owner:** A06
- **Priority:** P0 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M04-001, M02-007
- **Acceptance criteria:** Goal data validates IDs, descriptions, prerequisites and event conditions; tracking supports score, combo, collectibles, route gaps and interactions; completion is once per eligible goal and reports to UI.
- **Test strategy / evidence:** Validate missing/duplicate IDs and event types; test duplicate/out-of-order events, run resets, completed goals and mode eligibility.

### M04-003 — Author and verify all ten career objectives

- **Owner:** A06 / A05
- **Priority:** P0 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M04-002, M03-005
- **Acceptance criteria:** Implement the ten design goals including three score tiers, combo, letters, cone event, platform gap, market items, four-district route and secret recording; descriptions and world placements are accurate.
- **Test strategy / evidence:** Complete each goal through gameplay, test near-miss/partial progress and reset, and record triggers/locations; review discoverability with a player.

### M04-004 — Implement versioned local saves and safe recovery

- **Owner:** A06 / A01
- **Priority:** P0 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M04-002
- **Acceptance criteria:** Records, goals, unlocks and settings serialize locally with a schema version; write failure/corruption recovers without crashing; safe replacement preserves a usable prior file; no cloud account is required.
- **Test strategy / evidence:** Temporary-dir round trip, missing/truncated/invalid/old schema, permissions/write failure and interrupted-save scenarios; relaunch on target macOS and verify persistence.

### M04-005 — Implement meaningful unlocks and personal records

- **Owner:** A06 / A08
- **Priority:** P1 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M04-003, M04-004, M02-006
- **Acceptance criteria:** Goals award documented cosmetic/secret/special rewards once; records update only on improvement; unlock state is visible and survives restart; core movement is available from the start.
- **Test strategy / evidence:** Test repeated completion, reward dependency order, save reload, score ties and record updates; check locked/unlocked UI and new-player path.

### M04-006 — Balance goals and verify career replayability

- **Owner:** A06 / A09
- **Priority:** P0 · **Milestone:** M04 · **Status:** Planned
- **Dependencies:** M04-003–M04-005
- **Acceptance criteria:** Three score thresholds and combo targets are based on observed run distributions; all goals fit the intended run/mode rules; no impossible dependency or duplicate reward exists; owner accepts replay loop.
- **Test strategy / evidence:** Collect novice/intermediate/experienced run evidence, verify all-goals save and fresh profile, and play repeated career/free-skate sessions with recorded tuning rationale.

## M05 — Art, audio and ambient characters

**Source:** Proposed continuation. **Exit gate:** Believable, detailed, realistic-but-fun environments/characters, skating audio, ambience and captioned NPC reactions support the accepted skating loop; blocky placeholder art is not the release target. Complete provenance and no additional spend remain required.

### M05-001 — Replace blockout with detailed Glasgow environment art and lighting

- **Owner:** A05
- **Priority:** P1 · **Milestone:** M05 · **Status:** Planned
- **Dependencies:** M03-005
- **Acceptance criteria:** After M02-008, A05 coordinates with A08 to produce one representative facade/skating approach, skater and polished HUD treatment; obtain owner review and capture frame cost before repeating the treatment across the world. Follow docs/product/ART_DIRECTION.md: replace generic cuboids and flat placeholder surfaces with believable facade proportions, bevelled architectural detail, varied windows/doors, authored or free licensed stone/brick/paving/glass materials, coherent lighting and recognisable shopfront edges. Keep ramps/rails readable and preserve accepted collision. No voxel/blocky final aesthetic; no paid assets or engine switch without evidence.
- **Test strategy / evidence:** Representative scene/HUD review and measured frame cost, then matched before/after captures in all districts; replay reference lines and compare frame cost; audit all assets/procedural sources in the provenance register.

### M05-002 — Create readable original skater and trick animation

- **Owner:** A05 / A04
- **Priority:** P1 · **Milestone:** M05 · **Status:** Planned
- **Dependencies:** M02-008
- **Acceptance criteria:** Replace the primitive rider/board with believable proportions, detailed clothing/board materials and a coherent rig. Push, ollie, flip, actual hand-to-board grab, grind, manual, revert, special and bail must show convincing weight/contact and readable motion. Reuse suitable free licensed models/animations with provenance; visuals follow gameplay without adding input delay.
- **Test strategy / evidence:** Inspect every trick at slow and normal speed, verify state sync and camera readability, then rerun action timing and combo regression tests.

### M05-003 — Produce and integrate local synthetic skating SFX

- **Owner:** A07
- **Priority:** P1 · **Milestone:** M05 · **Status:** Planned
- **Dependencies:** M02-005
- **Acceptance criteria:** Original reproducible sounds cover wheel roll, jump, landing, grind, bail, combo and UI; event mapping prevents overlap spam; sound parameters reflect surface/speed where useful; no paid API is used.
- **Test strategy / evidence:** Record generator/source provenance; test event counts, mute/volume, pause/reset, rapid landing and long grind; listen for clipping and fatigue.

### M05-004 — Add ambient NPCs and lawful free voiced reactions

- **Owner:** A07 / A05 / A03
- **Priority:** P1 · **Milestone:** M05 · **Status:** Planned
- **Dependencies:** M03-005, M00-005
- **Acceptance criteria:** Original ambient NPCs react briefly without blocking routes; captions accompany every bark; approved free local voice source has redistribution evidence and no identity imitation. If unavailable, document the blocker and ask for a scope decision rather than claiming voice completion.
- **Test strategy / evidence:** Test trigger range/cooldown, simultaneous reactions, subtitles and collision clearance; audit voice model/output rights and listen on actual hardware. Paid voice services are prohibited.

### M05-005 — Integrate district ambience and review the presentation

- **Owner:** A07 / A08 / A09
- **Priority:** P1 · **Milestone:** M05 · **Status:** Planned
- **Dependencies:** M05-001–M05-004
- **Acceptance criteria:** Ambience varies smoothly by district; separate levels and captions are accessible; skating feedback remains audible; NPC humour is original and readable; no missing assets/licences remain.
- **Test strategy / evidence:** Play the full route with speakers/headphones, mute channels, pause/restart and save settings; compare visual/audio event timing and review complete provenance.

## M06 — UX, hardware and performance

**Source:** Proposed continuation. **Exit gate:** Menus and accessibility work with controller and keyboard; real DualSense/macOS play passes; representative Apple Silicon performance meets the declared 1080p/60 fps target.

### M06-001 — Harden controller support, remapping and input recovery

- **Owner:** A04 / A08
- **Priority:** P0 · **Milestone:** M06 · **Status:** Planned
- **Dependencies:** M02-008
- **Acceptance criteria:** Final controls are documented; mappings, sensitivity/deadzones and keyboard equivalents work; focus survives wired/Bluetooth reconnect; disconnect pauses safely and shows useful guidance; no action is mouse-only.
- **Test strategy / evidence:** Automate action/settings bounds and manually test real DualSense wired/Bluetooth, unplug/reconnect, alternate device index, remap conflicts and keyboard-only play.

### M06-002 — Finish menus, goal list, results and navigation

- **Owner:** A08
- **Priority:** P0 · **Milestone:** M06 · **Status:** Planned
- **Dependencies:** M04-006
- **Acceptance criteria:** Main menu, mode choice, HUD, goals, pause, settings and results use a cohesive polished typography/spacing/icon/motion system and contextual DualSense prompts per ART_DIRECTION. Score/combo feedback is lively but legible at 1080p; all screens are fully focus-navigable; restart remains fast and saving/record feedback is accurate. Remove temporary debug/template presentation.
- **Test strategy / evidence:** Traverse every screen using controller and keyboard, test long text/large scores, focus return and rapid input; capture representative screen evidence.

### M06-003 — Implement accessibility and camera comfort settings

- **Owner:** A08 / A04
- **Priority:** P1 · **Milestone:** M06 · **Status:** Planned
- **Dependencies:** M06-001, M06-002, M05-005
- **Acceptance criteria:** High-contrast legible text, captions, UI scaling, separate audio levels, reduced shake/nonessential motion and camera sensitivity are available and persistent; camera avoids ordinary geometry occlusion; visual cues do not rely only on colour.
- **Test strategy / evidence:** Test settings round trip/default reset, muted play, increased UI scale, reduced shake/motion and high-contrast scenes; human legibility/motion review on target display.

### M06-004 — Profile and optimize the representative full level

- **Owner:** A05 / A04 / A09
- **Priority:** P0 · **Milestone:** M06 · **Status:** Planned
- **Dependencies:** M03-005, M05-005
- **Acceptance criteria:** Declare baseline Apple Silicon model; record frame-time distributions at 1080p over a ten-minute full-district route; address sustained misses and visible stutters; optimizations preserve gameplay and visual requirements.
- **Test strategy / evidence:** Capture build/hardware/power mode, frame/physics metrics and peak cases; compare before/after and rerun collision/score tests. Linux timings do not certify this target.

### M06-005 — Verify a real standalone macOS prototype export

- **Owner:** A01 / A09
- **Priority:** P0 · **Milestone:** M06 · **Status:** Planned
- **Dependencies:** M00-002, M04-004, M06-002
- **Acceptance criteria:** Use matching official export templates; produce a self-contained Apple Silicon-capable app; launch it on a target Mac, play offline and persist saves; document unsigned first-run behaviour without purchasing enrollment.
- **Test strategy / evidence:** Inspect architecture/package resources; perform fresh-copy launch, controller session, quit/relaunch and save-path tests on macOS. Block when hardware/templates are unavailable; never claim a tested export from settings alone.

### M06-006 — Complete target-hardware acceptance and tuning

- **Owner:** A09 / Owner
- **Priority:** P0 · **Milestone:** M06 · **Status:** Planned
- **Dependencies:** M06-001–M06-005, M06-007, M04-006
- **Acceptance criteria:** Owner plays career/free skate and continuous combos on the real Mac/DualSense; all high-severity input, UX and performance defects are resolved and replayed; accessibility decisions are recorded.
- **Test strategy / evidence:** Full controller checklist, goal completion samples, long session and performance report; document remaining low-severity issues with explicit release disposition.

### M06-007 — Final graphics/UI cleanup and owner visual acceptance

- **Owner:** A05 / A08 / A09 / Owner
- **Priority:** P0 · **Milestone:** M06 · **Status:** Planned
- **Dependencies:** M02-008, M03-007, M05-001, M05-002, M06-002, M06-003, M06-004
- **Acceptance criteria:** After core skating/combo acceptance, audit and replace every visible placeholder in world, skater, animation, lighting, signage and menus/HUD. Deliver realistic-but-fun Glasgow presentation and polished controller-first UI matching the owner's direction, with no generic blockout used as final art. Close visible clipping, flat/shiny material defects, repetitive facades, camera obstruction and UI layout/focus issues. Owner approves matched final captures and a playable visual build; untested screenshots alone cannot close the gate.
- **Test strategy / evidence:** Follow docs/testing/VISUAL_ACCEPTANCE.md: maintain a placeholder/defect inventory, matched before/after views and motion recordings for every district and UI state, provenance audit, gameplay regression and target-Mac 1080p/60 fps evidence. Capture pass/fail and owner comments. If time/credits end first, leave the job open with the exact unfinished asset/screen list; release M07 cannot bypass it.

## M07 — Release readiness and delivery

**Source:** Proposed continuation. **Exit gate:** All Release 1 requirements have evidence or an explicit approved scope change; a tested macOS artifact, instructions, provenance and future handoff are ready for owner review with no paid publication.

### M07-001 — Run complete regression and close release defects

- **Owner:** A09
- **Priority:** P0 · **Milestone:** M07 · **Status:** Planned
- **Dependencies:** M04-006, M05-005, M06-006
- **Acceptance criteria:** Every release requirement maps to passing evidence; no critical/high defect remains; full career/free-skate, all ten goals, save recovery, every trick and all four districts are checked on the candidate build.
- **Test strategy / evidence:** Run local suite and target hardware matrix; record build identifier, test counts and manual evidence; independently verify prior fixes rather than relying on implementation claims.

### M07-002 — Complete title, asset and dependency release audit

- **Owner:** A03 / A01 / Owner
- **Priority:** P0 · **Milestone:** M07 · **Status:** Planned
- **Dependencies:** M05-005, M00-005
- **Acceptance criteria:** All shipped files have provenance and required notices; final title/signage is reviewed; project code/content licence decision is recorded by the owner before granting public rights; no unapproved voice/music/branding remains.
- **Test strategy / evidence:** Audit packaged file list against register and licence texts; inspect engine notices and voice permissions; document unresolved title/licence decisions as blockers.

### M07-003 — Package and verify the final macOS artifact

- **Owner:** A01 / A09
- **Priority:** P0 · **Milestone:** M07 · **Status:** Planned
- **Dependencies:** M07-001, M07-002, M06-005
- **Acceptance criteria:** Reproducible local export produces a versioned app/archive with checksum and required notices; fresh-copy macOS launch, offline play, controller and save persistence pass; any unsigned limitations are described accurately.
- **Test strategy / evidence:** Export from recorded commit/engine/templates, verify artifact checksum, test fresh extraction and launch on target Mac. Do not buy signing enrollment or upload to paid distribution.

### M07-004 — Write player instructions, release notes and support handoff

- **Owner:** A02 / A08 / A01
- **Priority:** P1 · **Milestone:** M07 · **Status:** Planned
- **Dependencies:** M07-001, M07-003
- **Acceptance criteria:** Instructions cover install/first launch, full controls, modes/goals, save location/reset, accessibility and known issues; release notes distinguish shipped scope; remaining backlog and recovery steps are durable.
- **Test strategy / evidence:** Have a reviewer follow instructions from the packaged artifact without development context; verify links/paths/version and compare controls against actual mappings.

### M07-005 — Make the evidence-based release decision and owner handoff

- **Owner:** A01 / A09 / Owner
- **Priority:** P0 · **Milestone:** M07 · **Status:** Planned
- **Dependencies:** M07-001–M07-004
- **Acceptance criteria:** A09 recommends readiness with complete evidence, A01 checks architecture/scope, and owner reviews the playable artifact and distribution decision; no unapproved publication, purchase or hosted job occurs; future work is recorded.
- **Test strategy / evidence:** Review requirement coverage and defects; verify artifact identity against tested build; record owner feedback and any approved exceptions. A release decision is distinct from a local build or an uploaded file.
