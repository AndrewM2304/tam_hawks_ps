# Playtest repair tickets — reviewed 25 October 2026

Planning only. The owner will start implementation in a separate cloud session;
this review does not launch agents, change gameplay, or certify any fix.
These are **30 local tickets**, not published GitHub issues. All are **Planned**.
They refine the existing roadmap; the 75 full backlog records remain intact.

Evidence: [portable review packet](../testing/debug-session-2026-10-24/README.md),
[all 38 captures and exact comments](../testing/debug-session-2026-10-24/INDEX.md).
Every capture is assigned below, including blank captures 1, 13 and 37.
Repeated symptoms share tickets, but every location remains a required witness.

## Findings and evidence limits

Reviewed all 38 screenshots, individual JSON records, their history/input records,
and all 38 engine logs. The completed session manifest matches the individual
reports exactly. Godot 4.6.3 / Apple M5 / Compatibility / Balanced; logical viewport
1440×900, original images 2851×1782. All ten recorded source hashes match the
current local candidate. This is the **uncommitted candidate over 7e4d263**, not
proof that main already contains the recorder or these candidate world changes.
The portable packet includes a patch to recover that source for cloud diagnosis.

The logs contain only engine/renderer startup text, with no recorded exceptions.
That does not establish correct physics or rendering. Still images locate the
owner's flicker reports but cannot prove temporal flicker, its cause, or a repair.
Treat overlapping faces, shadow instability and material aliasing as separate
hypotheses until controls distinguish them. Do not apply a global bias change
or disable shadows to declare these reports fixed.

Capture 32 records bowl air, near-zero horizontal speed and a camera forward Y
of 0.997826; history shows repeated wall launches/returns. It does not prove that
a fresh in-air Push was recognized. Capture 38 visibly shows the service shutter
open, so the gate report concerns usefulness/discoverability as well as traversal,
not an established failure to animate. Capture 1 has a malformed/headless initial
rider silhouette, with no note and no history: investigate startup/capture timing;
do not assume it establishes the cause of the earlier contracted-body pose.
The recorder always writes manual_trick_id, even when inactive; “manual” in
these reports is not evidence that the player was performing a manual.

The owner clarified capture 33 means **wallride or wall jump**, not an invisible
wall blocking ordinary travel. The station clarification supersedes the tentative
“put a train or something” note: an **enclosed station building at the level edge,
with trains travelling through a tunnel**, is the requested direction.

## Queue and ownership

Owners below are role assignments for the future cloud worker, not running agents:
A01 integration, A04 skating/pose, A05 world/geometry, A08 UI/tooling, A09 QE.
M01 movement, M02 tricks, M03 level, M05 presentation, M06 hardening.
No parallel edits to shared level files without an explicit file/interface agreement.

| Ticket | Priority | Owner / milestone | Captures | Work |
| --- | --- | --- | --- | --- |
| PT24-01 | P0 | A05/A09 · M05/M06 | 2, 3, 5 | Civic asphalt/paving shadow flicker |
| PT24-02 | P0 | A05 · M03 | 4 | Civic Chambers side gap |
| PT24-03 | P0 | A05 · M03 | 6 | Civic-to-park outer edge and backdrop |
| PT24-04 | P0 | A05 · M03 | 7, 8 | Promenade grass dip and exposed underside |
| PT24-05 | P1 | A05 · M03/M05 | 9 | Summit paving/asphalt seam flicker |
| PT24-06 | P1 | A05 · M03/M05 | 10 | Station half-pipe bottom seam |
| PT24-07 | P0 | A05 · M03 | 11, 12 | Lower Kelvingrove path/grass transitions |
| PT24-08 | P0 | A05 · M03 | 13, 14, 15 | Missing park retaining and ramp side walls |
| PT24-09 | P1 | A05 · M05 | 16, 17 | Skatepark tiled-wall flicker |
| PT24-10 | P1 | A05 · M05 | 18 | Exchange bottom masonry flicker |
| PT24-11 | P1 | A05/A04 · M03 | 19 | Station ramp line ends in a wall |
| PT24-12 | P1 | A05 · M05 | 20 | Station grass/wall-base flicker |
| PT24-13 | P0 | A05 · M03 | 21 | North climbing-lane floor crack |
| PT24-14 | P0 | A05 · M03 | 22 | Civic back-street trap / unusable lower pocket |
| PT24-15 | P1 | A05 · M03/M05 | 23 | Enclosed station edge, tunnel and passing trains |
| PT24-16 | P2 | A05/A04 · M03/M05 | 24 | Kelvingrove pond, ducks and grind loop |
| PT24-17 | P1 | A05 · M03 | 25 | Give central green a skating purpose |
| PT24-18 | P1 | A05/A04 · M03 | 26 | Civic port ramp points into wall |
| PT24-19 | P1 | A05 · M03 | 27 | Furnish bare corridor with a connected line |
| PT24-20 | P1 | A05/A04 · M03 | 28 | Replace arbitrary market walls with useful obstacles |
| PT24-21 | P1 | A05/A09 · M05/M06 | 29, 35 | Clyde edge/ground flicker |
| PT24-22 | P0 | A05 · M03 | 30, 31 | Clyde wall and map-boundary gaps |
| PT24-23 | P0 | A04/A05 · M01/M02 | 32 | Bowl exit intent, momentum and camera recovery |
| PT24-24 | P1 | A04/A05 · M02 | 33 | Clyde wallride / wall-jump eligibility |
| PT24-25 | P1 | A04/A05 · M02/M03 | 34 | Bridge handrail-to-cable grind transfers |
| PT24-26 | P1 | A05 · M05 | 36 | Fit fountain water to the basin |
| PT24-27 | P1 | A05/A08 · M03/M06 | 37, 38 | Make service gate a useful readable shortcut |
| PT24-28 | P0 | A04/A08 · M01/M05 | 1 + prior photos | Malformed startup rider and contracted-body investigation |
| PT24-29 | P1 | A08 · M06 | 1, 14, 32 + all JSON | Accurate recorder state, image timing and HUD placement |
| PT24-30 | P0 | A01/A09 · M06 | All | Integrated regression and owner-route acceptance |

Order: preserve/recover the captured source first, then reproduce P0 hazards,
pose and bowl faults; fix geometry before evaluating seams on that geometry.
Run PT24-01 temporal diagnosis early. After safe routes, repair remaining visual
seams and trick eligibility, then author purposeful lines, station, pond and
water finish within measured budgets. PT24-30 closes the integrated batch.
Lower-priority design work must not delay fall-through or blocked-route repairs.

## Ticket details

For each ticket, reproduce from its indexed player position/heading and actual
camera before changing code. Initial placement is allowed for diagnosis; subsequent
acceptance uses ordinary mapped inputs and native collision without scripted
per-tick position, speed or heading corrections. Coordinates are metres, Y up.
The exact position, forward vector, camera and original note are in the index/JSON.

### PT24-01 — Civic shadow flicker

Dependencies: existing SHADOW-01; PT24-02/03 geometry for final comparison.
Inspect GeorgeGradedStreet/GeorgeSquareFloor and adjoining paving at all three
captures. Acceptance: no owner-reported shimmer while approaching and crossing
both asphalt/tile joins, with readable shadows retained. Test: source-frozen matched
moving clips, receiver/caster and shadow-off diagnostic controls, depth/duplicate
face inspection, native Mac before/after. A still screenshot is insufficient.

### PT24-02 — Civic Chambers gap

Dependencies: captured source reconciliation; prior SURFACE-01 is not closure.
Capture 4 is at (28.68, 4.01, −56.65), facing east toward the gap. Continue the
appropriate wall/fence or supported architecture after locating actual bounds.
Acceptance: visible and native boundaries agree; no unmarked fall-through from
either side, including jumping at the junction. Test: rays across the opening,
capsule sweeps, displayed-face inspection and actual approach/return. Preserve
intended passages rather than laying an invisible catch floor under everything.

### PT24-03 — Civic/park edge enclosure

Dependencies: WORLD-EDGE-02, PT24-04; shared boundary ownership with PT24-15.
Capture 6 shows an asphalt mouth ending in empty sky between buildings. Seal the
dry outer edge with grounded wall/fence/building continuation and a coherent
background, keeping the legitimate Kelvingrove connection open. Acceptance:
no straight skating exit into void; no visible open underside at nearby headings.
Test: continuous boundary sampling, real push/jump approaches, return-route and
multi-bearing chase captures. Station tunnel work must not close this route.

### PT24-04 — Promenade grass dip / missing map

Dependencies: WORLD-JOIN-02; coordinate with PT24-03/07/17.
Captures 7/8 show grass dropping between raised paths and exposed geometry/sky
beneath them. Determine which space is playable, then join terrain and retaining
faces consistently. Acceptance: no zigzag double ground, holes, unintended
underpasses or unsupported grass; the promenade/park ports remain traversable.
Test: mesh/query/native height agreement along and across seams, side-wall rays,
grass-to-route traversals both ways, and cameras looking down into the dip.

### PT24-05 — Summit tile/asphalt seam

Dependencies: PARK-FLOAT-02 and final park approach grading.
Capture 9 at KelvingroveRollingLoop shows the summit material junction. Remove
intersecting/copied visible surfaces if confirmed; preserve actual terrain support
and shelter access. Acceptance: stable seam with no raised blocking lip. Test:
moving low/chase views, exact face ownership/depth check and no-jump crossings.

### PT24-06 — Station half-pipe bottom

Dependencies: PT24-11 and PT24-15 footprint agreement.
Capture 10 reports the pipe floor flashing against CentralStationFloor. Resolve
display ownership at the actual toe/bottom rather than floating a ramp above it.
Acceptance: no flicker or wheel snag; original pipe speed/height behavior retained.
Test: moving toe/flat views, native support samples and repeated pipe cycles.

### PT24-07 — Lower park entry transitions

Dependencies: WORLD-JOIN-02/PARK-FLOAT-02; coordinate with PT24-04.
At captures 11/12 the route cannot be crossed smoothly: approach/asphalt grade and
grass shoulders disagree. Rebuild coherent joins using shared boundary heights.
Acceptance: both locations are skateable in both directions without an ollie,
raised spur or overlapping path; retaining needed elsewhere stays visible.
Test: independent lateral/longitudinal rays and actual low/normal-speed no-jump
traversals, plus ordinary chase views. Do not validate only path centre lines.

### PT24-08 — Park exterior and ramp walls

Dependencies: PARK-WALL-02; PT24-07 terrain seam contract.
Blank capture 13 is an additional view of the shelter approach; capture 14 reports
missing support underneath it. Capture 15 visibly exposes sky below the tiled
arrival/bypass ramp. Inspect the entire exterior as well as the street basin,
including winding/culling, foundations and native side faces. Acceptance: closed
grounded construction from all accessible sides, with intentional bowl ports,
stairs and beginner bypass still open. Test: native horizontal side rays, inside/
outside captures, traversals through every intended opening and attempts to skate
under the deck. Earlier narrow north-wall views do not close this report.

### PT24-09 — Park tiled retaining-wall flicker

Dependencies: PT24-08 final wall geometry.
Captures 16/17 cover separate retaining/port faces. Investigate overlapping skin,
foundation and adjacent bowl faces before adjusting materials. Acceptance: both
walls remain stable during approach and along-wall movement, with no missing
reverse face. Test: moving angle sweep, face-depth ownership and collision checks.

### PT24-10 — Exchange masonry edge flicker

Dependencies: shared seam diagnosis PT24-01; preserve fountain/court lines.
Capture 18 identifies the bottom brick/stone edge near ExchangeLowerCourt.
Acceptance: grounded trim without flashing, no new collider lip. Test: local face
inspection, moving close/chase views and support crossing beside the edge.

### PT24-11 — Station ramp line has no payoff

Dependencies: PT24-15 spatial plan; existing transition physics.
Capture 19 asks for an opposing quarter pipe at the wall or an equally useful
continuation. Author a return/transfer line with enough run-up and landing room.
Acceptance: ramp feeds a playable jump/return/grind rather than a compulsory wall
impact; beginner bypass and station goals remain. Test: real low/charged runs,
repeated return cycles and a banked connected combo, with camera clearance.

### PT24-12 — Station grass/wall-base flicker

Dependencies: PT24-04 terrain and PT24-15 architecture bounds.
Capture 20 shows the foundation/grass contact beside CentralStationFloor.
Acceptance: stable grounded seam without buried/doubled faces or lost barrier.
Test: face/height diagnosis, moving parallel/crossing views and native edge support.

### PT24-13 — North climbing lane floor hole

Dependencies: WORLD-JOIN-02; coordinate with PT24-14 lower street.
Capture 21 at (−85.93, 2.17, −44.51) reports a floor gap between building/road
pieces. Acceptance: continuous visible/native support across the actual crack,
no fall/foot snag, unchanged intended road grades. Test: dense local support rays,
sideways/diagonal push crossings and jump landings, including building corners.

### PT24-14 — Civic back-street trap

Dependencies: PT24-04/13 continuous support; PT24-17 space allocation.
Capture 22 reports an unusable lower pocket that traps the skater. Give it a
readable graded exit and connected skating purpose, or close inaccessible residual
space with visible architecture. Preserve any intentional authored undercroft.
Acceptance: every accessible lower pocket has an input-driven way out without
reset; closed buildings cannot be skated under. Test: enter from every open side,
stop at the lowest point, leave both ways; chase and underside captures.

### PT24-15 — Enclosed station edge and train tunnel

Dependencies: PT24-03/06/11/12/13 and existing route/goal contracts;
[ADR-032](../architecture/decisions/ADR-032-playtest-station-and-park-direction.md).
Replace the anonymous open canopy edge in capture 23 with original enclosed
station massing and a railway corridor continuing through a tunnel. Plan a train
passing through the tunnel behind the playable boundary, with its spawn/despawn
hidden inside enclosure. Keep trains scenic for this slice; do not create a new
playable rail district, traffic/skitching system or required train-dodge goal.
Inspect free Glasgow reference sources before detailed art and record confidence/
date/licences; no copied map layout or branded train assets.
Acceptance: recognizable railway purpose, no void visible through the edge,
grounded building/tunnel, continuous safe skating routes and credible train
motion without popping. Test: exterior/interior approaches, passage clearance,
whole train loop/pause/reset checks, safe-boundary probes and measured render cost.

### PT24-16 — Pond and grindable perimeter

Dependencies: PT24-04/07 support and recovery, stable grind contacts;
ADR-032. Capture 24 proposes a pond with ducks, a rail around it and a water bail.
Fit a bounded pond into this existing low grass pocket. Give the rail genuine
reachable contacts and a safe dry bypass; water entry uses the existing dramatic
bail/recovery lifecycle and safe bank, preserving banked score. Ducks are modest
scenic original/compatible assets, not a new animal simulation.
Acceptance: planted pond with no exposed void, useful entry/exit grind line,
readable water hazard and reliable recovery. Test: rail in both directions,
jump/manual links, water entries near every bank, repeated recovery and pause,
source/licence record plus native visual/performance gates.

### PT24-17 — Purpose for the central green

Dependencies: PT24-04/14, coordinate with PT24-16 to avoid duplicate dead-space work.
Capture 25 shows a fenced green void between civic/park/station routes. Reallocate
or reshape it into a deliberate supported connecting skating pocket or coherent
landscaped edge. Avoid filling it with arbitrary obstacles. Acceptance: a clear
reason to visit/route around it, an approachable connected line and safe return,
without trapping lower streets or obscuring landmarks. Test: walk-through of the
line plan, real combo/traversal both ways and matched cost/readability views.

### PT24-18 — Civic port ramp wall collision

Dependencies: PT24-03/14/17 building and route layout.
Capture 26 reports a ramp ending at a wall. Reorient/extend the route or author a
proper transition/return at that wall, preserving useful movement into the park.
Acceptance: no compulsory impact, enough landing/run-out room, readable return.
Test: actual approaches with tap/charged ollie, no-jump bypass and camera clearance.

### PT24-19 — Bare corridor

Dependencies: safe boundary PT24-02 and shared skating-line layout.
Capture 27 suggests bins/benches (the note says “pins or benches”). Add restrained
original street furniture arranged as a grind/manual/jump continuation. Acceptance:
useful line with clear run-up and bypass, no extra snag points or camera blockage.
Test: both-direction traversal and banked combo; record geometry/draw cost first.

### PT24-20 — Market walls lack skating value

Dependencies: preserve market/encounter/save IDs and wallride eligibility contract.
Capture 28 shows perpendicular brick walls in the loading terrace. Reshape their
purpose into credible skateable ledges/banks/transfer or remove redundant blocking
pieces while keeping enclosure and encounters. Acceptance: useful entry/payoff/
exit, native board/rail contacts and accessible market return. Test: combo runs,
low-speed bypass, actual jumps and encounter/career reachability regressions.

### PT24-21 — Clyde edge and paving flicker

Dependencies: PT24-22 boundary geometry; shared diagnosis PT24-01.
Capture 29 is north-quay shadow/edge shimmer; 35 is south-quay paving near bridge
landfall. Diagnose separately before assuming a common cause. Acceptance: both
stable in moving chase views without removing river shadows or safe crossing.
Test: moving matched controls, overlapping/depth inspection and landfall support.

### PT24-22 — Clyde wall/map gaps

Dependencies: existing compact-Clyde route metadata; coordinate with PT24-21/25.
Capture 30 reports wall gaps in front and behind; capture 31 reports another map
gap beside station/Clyde frontage. Survey the full adjacent boundary, not only
the camera ray. Acceptance: dry map edges have continuous visible/native closure
and backdrop; deliberate river jump/bridge ports remain open and readable.
Test: two-sided boundary rays/sweeps, real approaches/jumps, heading sweeps,
supported bridge ingress and original gap-goal regressions.

### PT24-23 — Bowl escape and camera

Dependencies: existing ADR-031 air/transfer contract, BOWL-01 excavation;
PT24-29 improves diagnostics but does not block initial reproduction.
Capture 32: ClydeEastBowl / ContinuousBowlWall; owner cannot exit by pressing
forward. Test held approach Push and release→fresh in-air Push separately; inspect
transfer recognition, lip clearance, momentum, support association and camera.
Acceptance: ordinary bowl air returns inside; deliberate documented forward exit
clears the lip and lands outside at ordinary attainable speed; revert remains a
landing combo action. No global flat-ollie boost. Camera completes one controlled
apex handoff, retains skater/landing context and recovers to rear follow on exit,
without staying skyward or flipping repeatedly. Test: both walls/directions,
tap/charge, slow/stopped recovery, repeated cycles, scored trick/revert/manual
links and actual native moving captures. Preserve the owner's ramp-camera intent;
do not replace it with an arbitrary level camera to hide the state defect.

### PT24-24 — Wallride or wall jump at print yard

Dependencies: reconcile TRICK-W01/W02, current actual wallride/wallie runtime and
surface exclusions. Old planning text calling the entire state missing is stale:
skater.gd already emits wallride/wallie. Owner confirmed this interpretation.
Reproduce capture 33 at the visible wall; inspect normal/angle/speed, launch/input
gates and metadata. Acceptance: eligible oblique wallride and deliberate wall
jump work with readable cues; forbidden surfaces remain forbidden with reason.
Do not award a trick for an ordinary head-on crash. Test: angle/speed sweeps,
real jump→wall contact→exit, corners/obstructions, single score and camera follow.
Keep straight-on wall plant as its separate existing contract if applicable.

### PT24-25 — Handrail-to-red-cable combo line

Dependencies: PT24-22 safe crossing, named contact/transfer/clearance contracts.
Capture 34 asks to jump between bridge handrail and red suspension cables. Survey
the actual 3D cable grades and available landing clearance before adding grind
metadata; do not label unsupported curves as verified 50-50 contact.
Acceptance: visible reachable rail→air→cable→air/rail continuation, physical board
support, bounded capture and river bail if missed; ordinary bridge route retained.
Test: both travel directions where geometry permits, actual input launches/catches,
speed/gravity preservation, continuous board clearance and one correctly banked
combo with manual/revert links where feasible. Record any direction geometrically
unsupported instead of forcing an invisible snap.

### PT24-26 — Fountain water fit and finish

Dependencies: preserve fountain coping/contact and water-hazard semantics.
Capture 36 shows coarse flat water not conforming to the circular masonry basin.
Fit the visible water footprint/height to the actual inner edge; finish it with
restrained shared/built-in material detail within measured budget. Acceptance:
no rectangular overhang, dry gap, jagged basin mismatch or shimmering rim;
existing coping remains grindable. Test: overhead and low moving views, inner-rim
sample agreement, coping circuit/collision and unchanged hazard behavior.

### PT24-27 — Service-gate shortcut purpose

Dependencies: existing service_gate_shortcut ID/native opening safety;
coordinate with PT24-11/15 station routes.
Capture 37 is a closed-view reference; 38 shows it open. Validate actual passage,
then make the shortcut's two destinations and skating payoff obvious. Reduce
oversized sign clutter and improve prompts/approach visibility as needed.
Acceptance: opening changes a useful connected line, readable from both sides;
no crush/blocked closure, trapped player or redundant dead-end gate. Test: real
open→traverse→return→close, late sensor entry, pause/reset, route metadata and
career regression. Do not delete a working reversible mechanic merely because
the current framing fails to explain it.

### PT24-28 — Startup rider / contracted-body investigation

Dependencies: POSE-02, existing bail/contact rig and recorder timing PT24-29.
Capture 1 visibly has a malformed/headless narrow rider before movement, with
no note/history and on_floor false despite airborne false. Determine whether it
is first-frame initialization, screenshot timing, skin deformation, or a persistent
pose problem. Earlier contracted-body photos remain unresolved and may be a
different fault. Acceptance: believable complete rider at initial play, after
trick/bail/reset and when capturing; no folded limbs/body collapse or stale pose.
Test: cold launch, mode changes, repeated flips/grabs/plants/bails/recoveries,
fixed bone lengths and rigid transforms, native close/chase captures. Preserve
negative evidence; do not claim the prior contraction's cause without reproducing it.

### PT24-29 — Recorder diagnostic reliability and HUD

Dependencies: DEBUG-01 existing recorder; no change to numeric shortcuts.
Record active/manual/grind/lip/feature/transition flags separately from configured
IDs, actual physics tick and rendered/interpolated capture frame, input press/
release and recognized bowl transfer, and clear “last bail reason” semantics.
Explain native is_on_floor versus gameplay airborne instead of forcing equality.
Capture 14 shows DEBUG REC text overlapping SPECIAL; place the recorder indicator
within safe HUD bounds. Acceptance: reports distinguish inactive/default IDs,
physics vs presentation state and historical bail cause; screenshot belongs to
the recorded frame; 1/2/3 work outside notes and type numbers inside notes.
Test: known ground/air/manual/bail/transfer states, rapid capture/pause/resume,
PNG/JSON timestamp alignment, keyboard/controller editing, display-scale layouts,
write-failure retention and independently readable ZIP. No automatic uploads.

### PT24-30 — Integrated repair admission

Dependencies: all accepted implementation slices above; unimplemented design
items stay explicitly Planned rather than silently counted as fixed.
Acceptance: every indexed witness has new source-bound evidence and an honest
resolution; original goals/save/rail/route IDs, combos, intended water hazards,
controller/keyboard and normal camera remain intact. Keep manual Mac/DualSense,
export, fun and final art gates separate. Test: tools/check.sh for production
GDScript; assertions counted/nonzero on failure, native moving regression for
all repaired locations, cold source launch, no-jump route returns, pause/reset and
combo banking. Linux cannot close Mac shadow/controller/performance acceptance.
Do not update exact inventory fixtures until independent native geometry checks
establish the intended new counts.

## Cost and cloud handoff gates

Before each implementation slice, declare added draws, triangles, bodies/shapes,
textures/memory and frame-time ceilings. Prefer repairs to existing resources and
startup-only construction. The prior candidate's ≤12 added submissions/10 bodies/
32 panels/4000 triangles is its old bounded world-repair budget, **not** a blanket
allowance for station/train/pond/art expansion. Declare separate bounded budgets
for those designs before construction. Reuse shared materials; add no new lights
or per-frame world mesh rebuilding. Measure matched frozen-source p50/p95/p99,
long frames and draw/primitive/texture/video counters; maintain existing gates.
No new rendering expansion is admitted until the existing stutter requirement
is met. An animation being scenic does not exempt it from performance checks.

Cloud start: read newest STATUS/RESUME, evidence README and ADR-032. Recover the
captured candidate on a feature branch over 7e4d263 using the supplied patch,
or explicitly reconcile it with later main. Verify all ten source fingerprints.
The candidate is **not fully admitted**: prior native after capture was clean,
but full regression, recorder integration and world regression fixtures remain
unfinished; earlier diagnostics include rejected horizon-limit/indexing runs.
Do not discard those changes or pretend 4560/0 on main certifies this candidate.
Do not apply the patch twice or run workers against mismatched source unnoticed.
No cloud session or background worker was started during this planning task.
