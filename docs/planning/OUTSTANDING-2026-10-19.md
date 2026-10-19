**19 October — forward chase and ramp repair:** MAP-03 now follows flat turns after a short lag, retains a rear view before collision-side fallback, and makes one skater-relative180° ramp arc from skyward to downward. Ramp airborne pose retains its local frame;22g ramp flight preserves launch velocity, flat flights remain34g. Corrected focused44/0, ordinary playability43/0, strict native timing/quality/exact1933-row physics and captured639.789m park round trip pass.101actual PNGs decode/hash successfully. First complete run2205/1 exposed station stopped-pitch/support-interpolation defects, now corrected and retained as rejected evidence. Corrected complete required suite **2207/0** passes clean/frozen; final source/PNG/backlog audit is recorded with this checkpoint. [Evidence](../testing/camera-flow/README.md), [ADR-023](../architecture/decisions/ADR-023-ramp-camera-heading-and-framing.md), [PHY-R01 four-source research](../research/THPS-PHYSICS-COMPARISON-2026-10-19.md), newest [STATUS](../STATUS.md). Older level/two-axis candidates are superseded. Central park/bowl/half-pipe/rails/downhill links, shared ports/budgets, broader world/UI and human/hardware gates remain open. All75full ticket bodies are preserved.

# Outstanding full backlog — 19 October 2026

64 of 75 full tickets remain non-Done: 1 Blocked, 22 In progress, 5 Planned, 36 QE review.

Snapshot of the recorded statuses, not a new certification audit. QE review usually means implemented with acceptance still open. Read individual acceptance/remaining fields in [BACKLOG](BACKLOG.md); task owners, dependencies and tests remain there. Current repair ordering and packet-level tasks are in [MAP-FLOW-REPAIR-2026-10-19](MAP-FLOW-REPAIR-2026-10-19.md). No remote issues were created.

**Current repair overlay:** original75full task bodies and64non-Done statuses below remain unchanged. MAP-01/02 first ground slice is verified; MAP-03 corrected focused44/0, ordinary playability43/0, strict native timing/quality/exact1933-row physics,639.789m route and101PNG checks pass; corrected complete required/source admission passes; human/wider ramp acceptance remains open. Central park and wider world/UI/hardware work remain open. [Repair packet](MAP-FLOW-REPAIR-2026-10-19.md), [STATUS](../STATUS.md).

[PHY-R01](../research/THPS-PHYSICS-COMPARISON-2026-10-19.md) source review/comparison is recorded. PHY-R02 (P1/M01, owner Codex, after MAP-03) extends actual jump/turn/launch/landing-speed measurements; PHY-R03 (P1/M06, owner Codex, after02 and accessible original-THPS3 evidence) proposes bounded tuning from observed reference timings, not guessed constants. Their dependencies, acceptance and tests are in that research record; these refine existing roadmap tickets rather than silently adding to the75-body count.

**CAM-QA01 — repeated restart diagnostic**, owner Codex, P2/M06, depends on MAP-03 evidence: reused-scene camera comparisons expose up to0.018269m physical-trace differences despite neutral settling, while fresh identical scenes match exactly. Cause remains unisolated. Acceptance: reproduce original/original and fresh/reused scene resets, identify the responsible contact/actor/cache state, and show deterministic bounded restart without per-tick forcing or changing physics to hide a test. Test strategy: input-driven repeated half-pipe restart traces with full source/fixture hashes; required checks after any production fix. This does not block independent park survey or establish a camera-caused physics defect.

| ID / task | Priority | Milestone | Recorded status |
|---|---|---|---|
| M00-002 — Pin and verify the free local Godot toolchain | P0 | M00 | In progress |
| M01-001 — Register controller and keyboard input actions | P0 | M01 | QE review |
| M01-002 — Implement stable arcade ground movement | P0 | M01 | In progress |
| M01-003 — Implement ollies and skateable ramp transitions | P0 | M01 | In progress |
| M01-004 — Implement initial aerial tricks and landing feedback | P0 | M01 | QE review |
| M01-005 — Provide a usable follow camera | P0 | M01 | In progress |
| M01-006 — Integrate prototype run, score, HUD and fast restart | P0 | M01 | QE review |
| M01-007 — Obtain independent M01 review and owner controller playtest | P0 | M01 | In progress |
| M02-002 — Implement rail acquisition, travel, release and balance | P0 | M02 | QE review |
| M02-003 — Implement manuals as combo links | P0 | M02 | QE review |
| M02-004 — Implement reverts and landing continuity windows | P0 | M02 | QE review |
| M02-005 — Complete combo scoring, banking, multiplier and bail rules | P0 | M02 | QE review |
| M02-006 — Score spins and unlock/execute special tricks | P1 | M02 | QE review |
| M02-007 — Implement reusable named-gap detection and rewards | P1 | M02 | QE review |
| M02-008 — Polish trick feedback and certify continuous combo feel | P0 | M02 | In progress |
| M02-011 — Prototype genuine transition and vert skating | P0 | M02 | QE review |
| M02-012 — Prototype bounded wallride and wallie states | P2 | M02 | Planned |
| M02-013 — Assess skitching and moving traffic through a bounded prototype | P3 | M02 | Planned |
| M03-001 — Build George Square learning and combo routes | P0 | M03 | QE review |
| M03-002 — Build Royal Exchange Square and arcade passage | P0 | M03 | In progress |
| M03-003 — Build Central Station district and elevated route | P0 | M03 | QE review |
| M03-004 — Build the Barrowland landmark and skate-through Barras market | P0 | M03 | QE review |
| M03-005 — Join districts, author secrets and validate the whole level | P0 | M03 | In progress |
| M03-006 — Verify Glasgow shopfronts, street edges and landmark relationships | P0 | M03 | In progress |
| M03-007 — Replace generic perimeter shops with recognisable Glasgow boundaries | P0 | M03 | In progress |
| M03-008 — Define the authored six-area terrain and compatibility contract | P0 | M03 | QE review |
| M03-009 — Rebuild the core squares and streets with playable elevation | P0 | M03 | QE review |
| M03-010 — Author and physically verify the fountain coping line | P0 | M03 | QE review |
| M03-011 — Build Clyde Quays with a river transfer and safe crossing | P0 | M03 | QE review |
| M03-012 — Build a hilly Kelvingrove-inspired park circuit | P0 | M03 | QE review |
| M03-013 — Audit nonlinear reference levels and prioritize original route changes | P0 | M03 | QE review |
| M03-014 — Implement nonlinear cross-links and distinct skating pockets | P0 | M03 | QE review |
| M03-015 — Prototype one original reversible changing-route event | P2 | M03 | Planned |
| M04-001 — Finalize career/free-skate lifecycle and results contract | P0 | M04 | QE review |
| M04-002 — Build data-driven objective tracking | P0 | M04 | QE review |
| M04-003 — Author and verify all ten career objectives | P0 | M04 | QE review |
| M04-004 — Implement versioned local saves and safe recovery | P0 | M04 | QE review |
| M04-005 — Implement meaningful unlocks and personal records | P1 | M04 | QE review |
| M04-006 — Balance goals and verify career replayability | P0 | M04 | In progress |
| M04-007 — Add an optional busker challenge through ordinary trick banking | P1 | M04 | QE review |
| M04-008 — Prototype Cone on a Cruise as a recoverable river stunt | P2 | M04 | Planned |
| M04-009 — Prototype Cat's Got the Beat with ordered coping captures | P2 | M04 | QE review |
| M04-010 — Prototype Gull-Proof Delivery through alternative market lines | P1 | M04 | QE review |
| M04-011 — Prototype One More Lap, Hen across park route choices | P2 | M04 | Planned |
| M05-001 — Replace blockout with detailed Glasgow environment art and lighting | P1 | M05 | In progress |
| M05-002 — Create readable original skater and trick animation | P1 | M05 | In progress |
| M05-003 — Produce and integrate local synthetic skating SFX | P1 | M05 | QE review |
| M05-004 — Add ambient NPCs and lawful free voiced reactions | P1 | M05 | QE review |
| M05-005 — Integrate district ambience and review the presentation | P1 | M05 | QE review |
| M05-006 — Replace cartoon anatomy with a believable adult skater | P0 | M05 | QE review |
| M05-007 — Research and author original Glasgow locals and playful encounters | P1 | M05 | QE review |
| M06-001 — Harden controller support, remapping and input recovery | P0 | M06 | QE review |
| M06-002 — Finish menus, goal list, results and navigation | P0 | M06 | QE review |
| M06-003 — Implement accessibility and camera comfort settings | P0 | M06 | In progress |
| M06-004 — Profile and optimize the representative full level | P0 | M06 | In progress |
| M06-005 — Verify a real standalone macOS prototype export | P0 | M06 | In progress |
| M06-006 — Complete target-hardware acceptance and tuning | P0 | M06 | In progress |
| M06-007 — Final graphics/UI cleanup and owner visual acceptance | P0 | M06 | In progress |
| M06-008 — Add a six-area route map and readable terrain navigation | P0 | M06 | QE review |
| M07-001 — Run complete regression and close release defects | P0 | M07 | In progress |
| M07-002 — Complete title, asset and dependency release audit | P0 | M07 | In progress |
| M07-003 — Package and verify the final macOS artifact | P0 | M07 | In progress |
| M07-004 — Write player instructions, release notes and support handoff | P1 | M07 | In progress |
| M07-005 — Make the evidence-based release decision and owner handoff | P0 | M07 | Blocked |
