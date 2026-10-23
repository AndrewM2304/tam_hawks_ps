**23 October checkpoint / new owner steering:** bail/pose/HUD/ramp refinement passes required2,295/0, strict native comparisons and60PNG/source audit. Next: reduce excessive flat ollies while preserving ramp pop, stage front/rear-foot lift, and audit all trick styles including angled grinds, wallrides, straight-on plants, reverts and landing assistance. [STATUS](../STATUS.md) owns exact evidence; new request remains pending at this checkpoint. Existing75full bodies remain intact.

**22 October owner refinement:** unnatural ramp body turn, speed-gauge removal/classic HUD and dramatic separated-board bails take priority. [Tracked refinement tasks](BAIL-HUD-REFINEMENT-2026-10-22.md) own dependencies, acceptance and honest candidate status; [STATUS](../STATUS.md) owns final checks. Existing full ticket bodies and all park/world/hardware gates remain intact.

**22 October implementation follow-up — BAIL-R02/R03:** reachable contact poses and local fall/slide/get-up/ready are implemented candidates; focused pose44/0 and recovery19/0 pass earlier frozen candidates. Final native/full-suite/source admission remains pending in [current evidence](../testing/bail-pose/README.md). No human, independent-QE, ragdoll/loose-board, stutter or final-art acceptance claimed. Existing park/world/UI work and75full task bodies remain.

**22 October — next owner priority: bail recovery and human movement.** [Pinned research and implementation packet](../research/THPS-BAIL-AND-HUMAN-MOTION-2026-10-22.md), [native diagnosis](../testing/bail-recovery/README.md). BAIL-R01 is complete: the reference separates bail recovery from restart nodes; ours resets23.157m in one observed physics tick. Actual pose trials show up to28.16% calf and18.76% forearm extension. BAIL-R02 is Ready (reachable contact/limb poses); R03 staged recovery and R04 full movement/camera/feel admission follow. These are local overlays on M01/M02/M05/M06, with owners, dependencies, acceptance and tests in the packet. No production change or human-quality pass in this research checkpoint;83758c3 remains the2226/0 gameplay baseline. Keep all75full ticket bodies/64non-Done statuses and park/world/UI work intact.

**22 October playtest follow-up — MAP-03B:** owner finds smoother play but rejects lingering ramp side view, weak charged pop and camera bouncing during normal ollies/tricks. The candidate corrects rear-sweep endpoint clearance, holds ordinary-jump camera height, and adds deliberate ramp pop with stronger full charge. Focused **71/0** and strict native compare-03 pass, with actual ramp/quiet-jump frames. Complete required **2226/0**, delivery52/0 and41PNG decode/hash checks pass after retained negative runs and corrected observation/input timing. Source/evidence binding is recorded in [current evidence](../testing/camera-pop/README.md). Previous00fc616/2207/0 certifies the preceding build only. This stays ahead of park construction and unrelated work; all75 complete task bodies and64 non-Done statuses remain unchanged.

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
