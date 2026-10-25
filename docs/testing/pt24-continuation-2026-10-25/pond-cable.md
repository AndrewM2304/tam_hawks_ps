# PT24 pond candidate and admitted suspension cable — 25 October 2026

Scope: PT24-16 and PT24-25. The owner approved these remaining items after the
holistic queue review. The cable is admitted to ordinary play: native backing
adds no rendering work and real inputs prove the handrail/cable/handrail combo
in both directions. The pond remains an explicit `pt24_design_preview` candidate;
existing stutter/rendering admission controls its installation. Normal play does
not acquire the new pond's rendering cost before that gate.
This document does not certify target-Mac timing, human skating feel or final art.

## Pond: exact existing location

Owner capture 24 is at `(-170.448, 0.513, -12.313)` looking west into the lower
park lawn. Its centre is `(-184, 0.5, -21)`, in the existing flat central
embankment. The outer bank has radii 10m/8m and the water has radii 8m/6m.
This is distinct from capture 25's central-green witness near `(-76.744,6,-119.247)`.
No new district or global catch floor is introduced.

`game/levels/park_pond.gd` removes the actual display and native lawn triangles
inside the outer bank. Shared startup polygon clipping preserves triangle-plane
height outside the excavation. A native sloping bank meets the water exactly at
Y0.12, continues inward beneath it and reaches a Y−0.85 floor. Water uses the
existing Clyde shader/material. Two original low-poly static ducks share existing
materials and CPU-recorded batches; no animal simulation or imported asset exists.

A closed rail follows the dry bank. Its 32 square beams and eight anchored posts
share one render batch and one native rail body. The real loop publishes
`kelvingrove_pond_perimeter` with a flat square-beam contact datum. Separate dry
transit and tangent-approach routes preserve a broad clear lawn bypass to the east.
Water entry returns a supported point outside the bank; the existing skater's
`recover_to`/bail lifecycle owns failure, dramatic recovery and score handling.
The pond introduces no second score owner, timer or reset state.

Interfaces:

- `build(world)` attaches the candidate once, after outdoor construction.
- `get_ground_height(world_point)` returns finite exact basin support only inside
  the excavation. Integration must consult it before the old lawn height query.
- `get_recovery_position(world_point)` is finite only when entering actual pond
  water; air above it, the rail and the dry bypass remain ordinary skating.
- `get_grind_lines()`, `get_route_definitions()` and `reset_run()` expose the
  existing world integration conventions.

Declared construction ceilings, before implementation: eight material surfaces,
1,400 new triangles including excavation growth, two bodies/41 shapes, zero new
textures/materials/lights. Actual scene counters and frozen-source native rendering
are owned by the combined integration evidence. This is not a frame-time result.

## Cable: existing red art becomes real native support

The real suspension art is 32 facets per strand, with cable centre height
`4.85 + 4.75 * (2*t-1)^2`, spanning Z72…122 around bridge X−25. Only the inner
strand on each side is admitted, over central facets 12…19: Z90.75…103.25,
X−29.35 and X−20.65. The high tower sections remain scenic.

At the central bridge deck, handrail guide Y4.5 is 0.5m inboard of these strands.
The lowest actual cable crown is about Y4.925. This provides a modest optional
jump rather than an artificial launch boost or an invisible catch across the
full bridge. Existing bridge and river recovery remain intact.

`game/levels/clyde_cable_line.gd` reads the authoritative CPU transforms published
by `ClydeLandmarks` through `StaticBatches.authored_transforms`. It copies sixteen
existing red square-beam transforms into one native rail-only body. GPU MultiMesh
readback is not used: Godot's headless adapter cannot provide those transforms.
No visible beam is added, moved or duplicated.

The two finite guides, `clyde_cable_west` and `clyde_cable_east`, follow the sampled
upper planes of those real beams. They use a zero-offset crown datum rather than
claiming a constant radial normal across changing grades. Native support and rigid
truck contact are checked independently; the metadata alone is not evidence.
Two optional handrail→cable and two cable→handrail airborne gap definitions,
plus two map routes, describe actual entry/return positions. Capture remains
subject to the existing finite speed, angle, correction and clearance gates.

Declared construction ceilings: zero new render surfaces/triangles/textures/
materials/lights, one body/16 shapes. There is no global ollie/gravity change,
per-frame world reconstruction, forced snap or additional gameplay district.

## Verification

`tests/park_pond_tests.gd.run(tree, check)` constructs a small independent 2.5m
native lawn grid in a private `SubViewport`/`World3D`, then installs the actual pond
module at authored coordinates. It checks a real centre
excavation, 128 native/query points, 32 shoreline corners, safe returns around the
banks, 29 dry-bypass samples, 64 steel/crown samples and complete rigid truck
support, visible water winding/shared resources and the declared native budget.
An additional `run_installed(tree, game, check)` drives ordinary Push into an
explicitly installed Main candidate and observes the existing bail/recovery.

`tests/clyde_cable_line_tests.gd.run(tree, check)` builds the actual original
Clyde landmark source in a separate private native world. It checks retained art and
zero new draws, the exact sixteen backing shapes, fixed world endpoints, 126
native crown samples, both-direction rigid truck contacts, bounded entry/return
geometry and nine independent clear ordinary bridge-corridor columns.

An initial attempt to isolate fixtures by translating them 1,500/1,800m away
exposed float32 precision loss in exact boundary/rigid-contact checks. Those
fixtures were corrected to use their own native worlds. Production contact math,
native support tolerances and the 2mm backing assertions were not relaxed.

## Actual mapped-input results

The cable's `run_player(tree,game,check,observer)` begins on actual bridge ground
with only an initial facing assignment. Push and charged Ollie catch the existing
native bridge handrail; another outboard Ollie catches `clyde_cable_west`; an
inboard Ollie returns to the handrail, and a short pop lands on the dry bridge.
Both directions pass with 17 actual cable ticks, zero bails and exactly one bank:
8,696 and 4,109. Command:

```sh
./tools/run.sh --headless --fixed-fps 60 --script res://.local/cable-input.gd
```

Working log `.local/cable-input-third.log`: **3 passed / 0 failed**, clean exit0.
The earlier gameplay attempt caught the real semantic handrail successfully but
expected the duplicate legacy guide ID; correcting that fixture identity required
no production change. The initial direct engine invocation failed before gameplay
because it bypassed the source runner's writable XDG directories; that failure is
separate from the actual gameplay results.

The pond's `run_player(tree,game,check,observer)` begins on the dry eastern tangent
at X−173.65. Both directions use Push → charged Ollie → perimeter rail → outward
Ollie → dry Manual → one clean bank. Both hold 27 actual rail ticks and 12 actual
manual ticks, with zero bails and exactly one earned 1,900-point bank. After the
first run, ordinary steering drives from that actual landing into the pond; one
existing dramatic bail/recovery returns to dry ground with the earned 1,900 intact.
There is no second placement or score injection for the hazard test. Command:

```sh
./tools/run.sh --headless --fixed-fps 60 --script res://.local/pond-input.gd
```

Working log `.local/pond-input-second.log`: **4 passed / 0 failed**, clean exit0.
The first attempt missed while passing too far outside the tangent during the
charged flight. Moving only the initial fixture 30cm nearer the existing rail
made its intended approach work. Pond geometry, capture limits and physics were
unchanged.

Neither input driver assigns position, velocity, heading, contact state or score
after its declared spawn. Optional observers read the real phases for captures.
The root integration owns durable combined receipts, full regression and native
captures. These short input runs establish their specific links, not whole-lap
pond balance, target-Mac performance, final art or human feel acceptance.
