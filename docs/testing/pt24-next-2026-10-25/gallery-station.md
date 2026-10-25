# C04-L01/L02 — Gallery and station flagship runs

25 October 2026. Baseline `258fec4`, directly on main, preserving the merged
Apple Music integration. This work uses existing geometry and mapped controls;
the placement changes add **zero bodies, collision nodes, meshes, draws, textures or lights**.
No placement change is assumed necessary before a native input witness exposes
a concrete issue. Actual Music control remains disabled in scripted fixtures by
setting `Main.persistence_enabled=false` before attaching Main to the tree.

## Declared representative lines

**Gallery terrace to fountain:** start (9.1,2.08,−24), facing south. Charge/pop
onto the downhill gallery stair rail, earn a real grind, then side-pop into the
continuous east side bank, clear of the stair treads. A fresh Manual follows the
lower court and east fountain tangent; an actual Ollie
catches its existing coping. Ride the fountain curve, pop outward to dry paving,
land into a short Manual and bank once. This starts at the gallery stair apron;
it does not claim the separate gallery entrance-bank/angled-ledge sequence or
every proposed later south-court continuation.

**Station spine to city:** start (−126,2.08,35), facing east. Real Push produces
spine air; release then fresh in-air Push deliberately clears the solid cap and
lands on the real concourse beyond the opposite toe. A flip and fresh Manual lead into the existing station
manual bank at (−80,2,40). Follow its supported west/north halfpipe bypass before
turning onto the south street and descending into Exchange near (−26,0,22).
The route uses the supported west/north halfpipe bypass; it does not
pretend the high rear deck is a ground-level connection.

All heading changes after each initial facing use actual steer inputs, including
the mapped shoulder-turn inputs during manuals. Balance also uses the real
mapped input axis. No position, heading, velocity, speed, contact, score or clock
is assigned during either run.

## Admission

`tests/pt24_flagship_runs_tests.gd` checks fixed full-width support/clearance for
the approach and ordinary miss/return paths, actual native feature contacts,
expected rail/transition IDs, connected manual stages, and a single independently
calculated bank. Receipts apply catalog repetition identities/devaluation and
separate hold points. Camera checks inspect complete processing with actual
full-body visibility/occlusion tests. Each line also has a real no-jump miss
bypass and supported return driven by ordinary Push/Brake/steering.

The first actual attempt is retained/rejected at
`.local/pt24-flagship-first-input.log`: **0 passed /4 failed**. The station line
reached Exchange and banked600 once with851 manual ticks (34 over the bank),
without a bail/recovery, but its late input turn brought a head landmark into
the halfpipe's rear wall. The adjusted input path begins its north turn at the
bank toe and keeps a wider west margin. No collision or camera tolerance changes.

The first gallery attempt caught the real stair rail, but its inward side-pop
landed on a remaining tread: the Manual dropped after8 ticks and the tread
occluded the foot-camera ray. It did not establish a connected fountain line.
The revised input sequence pops outward onto the continuous side bank before
turning through the lower court. The parser-only failure preceding that attempt
is retained at `.local/pt24-flagship-first.log`.

The revised probe is also retained/rejected at
`.local/pt24-flagship-revised-input.log`: **1 passed /3 failed**. The station's
strict one-bank receipt and camera now pass, and native rays verify its far-side
concourse landing. Its point-chasing driver then circles an intermediate street
waypoint instead of entering Exchange. The revised driver uses forward progress
gates and speed-scaled lookahead through the broad corners, while finishing the
narrow manual bank's toe straight and retaining the final Exchange destination.

The revised gallery Manual lasts115 ticks, but its late launch physically hits
the fountain basin before clearing its0.55m rim and loses forward speed. The next
entry keeps the existing topography proof's15-frame charge and begins further
from the basin while aiming along its east tangent; charge/release coordinates
and speed are logged. One remaining camera ray is approximately0.118mm inside
the GalleryEastApproach plane at the grade exit; the separate rigid presentation
contact fix owns that witness. Camera/contact tolerances stay strict.

The next two-combo probe, with the rigid presentation contact fix, is retained
at `.local/pt24-flagship-contact-fixed-input.log`: **3 passed /1 failed**.
**The gallery representative passes:** both actual rail/coping captures,
112 manual ticks,225 hold points and an independently calculated **8,000 banked
once**, zero bails/recoveries, native support and strict camera visibility.
It ends on dry court paving near(7.46,0,16.85).

The station reaches Exchange near(−26.91,0,22) and banks600 once with621 manual
ticks and native support, but its camera crosses the existing halfpipe's
`SideRollInLanding` atX−67.7/Z27.144. Root's first correction adds actual and
rendered head-center rays and separately passes50 assertions, including the thin
deck negative control and96 exact cached/uncached update pairs. The complete
flagship run at `.local/pt24-flagship-complete` still records **9 passed /3
failed**, with the same station camera occlusion. Gallery's8,000 combo and its
actual no-jump return both pass. The two other failures are a fixed ordinary
miss diagonal crossing the side roll-in underside, and a ten-second leg budget
that cannot cover the52m first station miss leg at its real4.2m/s input cap.
The ordinary miss path now turns east atZ24.5, clear of the side roll-in, and
uses a bounded distance/speed allowance; the scoring path remains unchanged.

The single Station-only diagnostic at `.local/pt24-station-camera-diagnostic`
retains **1 passed /1 failed**, source stable,21.90 seconds. It identifies the
actual first hidden marker as `AnatomicalHead` native convex-hull vertex19 at
(−65.21683,3.581228,26.74047), with a native slab hit at
(−67.7,3.963938,27.16987). Both actual and rendered head centers are present in
the solver and visible. The emitted camera and rear normal/low/high candidates
all report usable: this proves missing head extent rather than an exhausted
fallback search. The implemented correction retains both center rays and checks a
single convex visibility volume containing the current/rendered head bounds
and camera endpoint. It reuses one query/shape resource per camera, adds at most
one native shape query per unique candidate, and uses the same-update cache.
No physics, camera-speed, FOV or clearance changes. Independent acceptance
places a thin blocker across an actual head-hull vertex while both center rays
stay clear, and removes only the bounds volume as its causal negative control.
The combined focused run at `.local/pt24-head-extent-flagship-focused` records
**66 passed /0 failed**,70.97 seconds:54 camera assertions plus all12 complete
flagship assertions. The unchanged Station scoring path now banks600 once,
retains621 Manual ticks including34 on the bank, reaches Exchange, and passes
strict camera checks. The Gallery8,000 line and both actual no-jump returns
also pass without bails/recoveries; the Station ordinary miss ends near
(−27.20,0.013,22). The camera acceptance retains96 exact cached/uncached pairs:
cached336 shape queries/29,568 rays/336 casts versus uncached816/44,352/336.
The envelope adds168 shape queries across those96 updates; visibility rays and
motion casts remain unchanged. Its ceiling is one added native overlap per
unique candidate that reaches the real-head check, reused by the endpoint cache.

That receipt is deliberately **not admitted as clean verification**: optional
`transition_feature` metadata reads in the shared skater contact code emit
errors on plain fixture floors, and a separate new bowl-contact test appeared
during the run. The manifest comparison shows no existing source changed;
only `tests/pt24_bowl_contact_tests.gd` was added. Root owns the metadata guard
and the required clean combined check. All camera/flagship input and source
remain frozen for that check. Human Mac/DualSense, final art, temporal rendering
and the existing performance admission remain separate.

## Current and displayed board/foot camera coverage

The stricter Clyde prefix samples every completed return frame. After the
separate late-air contact repair, its remaining failure is actual axle vertex
`(−9.346293,1.832986,139.7344)` behind the print-yard lip at
`(−9.786458,2,139.7091)`, while the displayed deck transform differs from the
current one. The camera previously collected only displayed board and foot
targets, despite already retaining both head poses.

The camera now adds the current deck's existing cached landmarks and current
sole/toe endpoints when their transforms differ from the displayed transforms.
Both sets are fixed before the same-update cache begins. There is no new hull,
resource, geometry, sweep, clearance policy or motion/FOV change; the existing
4mm endpoint-support allowance remains unchanged. Identical poses add no targets.
The ceiling is one additional copy of the cached board landmarks plus two
endpoints per leg, using the existing visibility routine and endpoint cache.

Independent unit controls freeze a declared displayed transform, move only a
current visual board or foot, and place a real native thin blocker across its
actual extremity. Every displayed-only target remains clear. Removing only the
current target set recreates the old false clear; restoring it rejects that
endpoint without changing rider physics or the endpoint allowance.

The first combined causal replay is **780 passed /0 failed**, exit0, clean,
598 unchanged inputs,49.968 seconds at fixed60fps. It prepends all60 camera
assertions to the exact rejected surface/Clyde prefix and the existing bowl and
manual controls. All96 cached/uncached update pairs retain exact state/transform
parity; native fixture totals remain cached336 shapes/29,568 rays/336 casts versus
uncached816/44,352/336. The unchanged Clyde crossing/coast/return now passes all
**415 completed camera frames**, with206 bowl samples, zero bails, the earned
100-point bank preserved, and supported Z124 return near `(−14.215,2.014,123.978)`.
Gallery, Station, Civic, Park and surface-prefix assertions also pass.

Raw evidence: `.local/pt24-current-pose-camera-prefix`, observer
`.local/pt24_current_pose_camera_prefix.gd`. Source manifest SHA256:
`d68a4859d7dea562984a5b5c097684f49324e2977bbbc6e35d85555937cfb407`.
This clean focused result supersedes the earlier invalid diagnostic receipts;
root retains responsibility for final rendered captures and full/cold/package
verification. It does not establish target-Mac performance or human feel.

## Coordinated Clyde correction

The Clyde specialist's real bridge-to-ledge attempt found the old
`clyde_south_link` bank blocking that landing apron. With root approval, the same
feature is relocated by the existing atomic placement helper from
centre(−27.5,2,128), footprintX−34…−21/Z126.5…129.5, to
centre(−22,2,139.5), footprintX−28.5…−15.5/Z138…141. This adds no resources and
keeps its ID, guide, terrain support and route records together. Its west run-up
is south of the existing ledge's Z138 endpoint; its east endpoint(−11.5,2,139.5)
meets the bowl's already-supported annular deck. Z124 stays a flat bypass; Z140
crosses its intended east/west grade, with a maximum topY2.48. The Clyde
specialist owns independent native/input verification of this correction.
