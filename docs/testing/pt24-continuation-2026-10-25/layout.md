# Connected skating runs — implementation and admission

25 October 2026. Current continuation of the recommendations at
[`LAYOUT-RECOMMENDATIONS-2026-10-25.md`](../../levels/LAYOUT-RECOMMENDATIONS-2026-10-25.md).
This record covers placement work in `pt24_connected_runs.gd`; the combined
continuation receipt owns final admission. Human fun, Mac performance and final
environment art are separate gates.

## Placement changes

The helper runs once, after city dressing and before semantic edge snapshots,
surface auditing or static batching. Existing meshes, native solids and grind
authors move as a group. Infill feature/route records are updated at the same
time; station-bank support patches move with their actual terrain geometry.
No player movement, grind capture, score or save behavior is overridden.

| Existing feature | Previous placement | New placement and purpose |
| --- | --- | --- |
| `exchange_south_return` | X12…18/Z34, east–west | X12/Z32…38, north–south; its release points into the existing east quay close, while the teaching rail and Z28 crossing stay fixed |
| `civic_island_return` | X13/Z−68…−60 | X62…70/Z−84.7, east–west; a reused low ledge gives owner capture27's back street a technical line beside the Z−80 ordinary route |
| `station_low_manual` | Centre (−114,2,−13.5), beneath the service walk | Centre (−80,2,40); the existing bank/manual line occupies the clear apron between the spine and halfpipe, leaving Z35 runouts and the X−82 beginner bypass clear |
| `clyde_south_return` | X−22…−15/Z140 | X−32.2/Z131…138, north–south; offers a return edge on the safe bridge's west side, away from the bowl mouth and technical relay |
| `RecordingAlcoveSide` | A freestanding 3m wall at (113,3,−31) | A 0.6m-high loading kerb from Z−41.75 to−24, meeting the existing venue-side boundary |
| `RecordingAlcoveBack` | A redundant rear wall centred Z−39 | Its existing body/mesh become a narrow steel bearing atop the kerb, with a real top at Y2.24; the actual venue/north boundary retain the yard's rear enclosure |

The recording court retains its collectible and a supported east-side return.
Its new `Grind_Ledge_RecordingCourt` samples the real steel top. The bearing sits
flush on the kerb and uses the existing rail collision layer, preserving exact
truck support while the parallel tyres clear the wider masonry. No floating
guide cylinder or new collision body is added.

The service shutter now controls a physically framed alley. One wall at
X−50.1/Z−15…10 separates the 3m service shoulder from the broad concourse; the
existing shop facade forms the opposite side. Both north/south street mouths
stay open. The remaining closed-shutter gaps are narrower than the ordinary
0.56m rider capsule. The wall is **visible geometry** merged into the resident
station-floor mesh, with one exact box shape on the existing station body.

Five navigation continuations publish the actual clear return/bank surfaces:
`exchange_east_quay_handoff`, `civic_backstreet_ledge_return`,
`station_transition_handoff`, `clyde_west_landing_return` and
`recording_court_return`. These describe travel and returns; the labels do not
certify every proposed inter-district combo.

## Cost and protected contracts

- Four existing feature groups and two existing walls are moved/resized.
- The gate frame adds **12 triangles, 1 shape, 0 bodies and 0 draw surfaces**.
  Other placement changes add no native/render resources.
- One grind track is added for the existing low loading wall. Startup-only
  authoring adds no world `_process` or `_physics_process`, lights or textures.
- The original Exchange teaching rail, busking A/B/C course, twelve bench
  identities, career/save IDs and four original named gaps stay intact.
- Fixed ordinary routes at X−82 through the station, Z−80 through the civic back
  street, Z28 across Exchange and X−25 over the safe bridge remain protected.

The civic-port wall-facing ramp (PT24-18) has an additional **held design
candidate** under the shared `pt24_design_preview` admission flag. The exact
owner witness is (−36.467,6.014,−117.688), travelling south off the Y6 port edge at
Z−116 toward a civic-close wall at Z−109. A4.5m-wide quarter now faces that
approach at (−38.5,6,−116), radius2.4m, with a 2m rear deck. A full native/displayed
retaining foundation extends down to Y−3 and covers X−42…−35/Z−116…−108.8,
reaching the actual frontage behind the deck. Two1.25m side shoulders allow a
missed attempt to leave the rear landing without jumping. The narrower width
uses an explicit feature minimum; other quarters retain their existing6m default
minimum and unit-scale collision/sample frames. These dimension changes add no
body, shape, mesh or draw surface. The west-going Z−122 connection stays open.
This added geometry is absent by default until the existing performance gate is
met. It does not count as an admitted/default PT24-18 resolution.

A short stone return closes the remaining east gutter between the actual
frontage and civic fence: X−36.3…−34.8/Z−109.2…−108.8/Y6…8.4. It stands on the
retained foundation and adjoining Y6 civic forecourt, before the floor ends.
Its12 triangles share the foundation's existing mesh/material; one native box
shape shares its existing body. No body, draw, texture or light is added.
`pt24_frontage_return` records these bounds and costs on that foundation.

## Deterministic and actual-input admission

`tests/pt24_connected_runs_tests.gd` independently checks:

- Fixed expected endpoints/headings and unchanged teaching-rail coordinates.
- Actual box dimensions and matching visible/native recording-wall geometry.
- Four physical steel-top contacts for the new loading-edge grind guide.
- Native support at eleven samples per route segment and three lateral offsets,
  with bidirectional rider-capsule sweeps.
- Fixed protected beginner passages and collectible support/clearance.
- Eighteen native/displayed gate-side wall probes, closed versus open native
  passage and a still-clear seven-metre-longer concourse detour.
- One bounded, production-input Manual → Ollie → loading-edge grind sequence,
  requiring a single earned combo bank, no bail, and a clear chase camera.
- In design preview, eighteen independent curve contacts, side foundations and
  the preserved west port, plus one bounded native push → air → return sequence
  on the civic return quarter. Default construction explicitly excludes it.
- The candidate's rear-miss envelope has twenty fixed visible/native/query
  floor probes, two independently sampled bidirectional capsule-clear shoulders,
  and actual no-jump Push/Brake returns from both rear corners to the park port.
- Eighteen two-sided visible/native cap witnesses and an actual continued
  southward low-speed miss must reach solid containment while staying supported.

Admission status is **pending the focused and combined source-bound runs**. The
first helper/test parse checks passed before the gate frame was added; those are
syntax diagnostics only. Initial parse commands without writable XDG directories
failed at environment startup; corrected XDG settings parsed cleanly. No game
playability conclusion follows from those startup failures or syntax checks.

The first combined focused run is retained/rejected in
`.local/pt24-continue-focused.log`. It exposed two real layout defects: shared
packed metadata arrays applied a second transform to moved guides, and the
wide masonry wall prevented valid parallel board contact. The metadata now uses
detached packed-array snapshots; the reused steel bearing supplies actual raised
truck support without tyre/masonry overlap. Neither fix changes capture tolerance
or scoring. A fixed protected bridge assertion also needed the actual existing
graded height at Z118 (Y2.329411765), rather than a false flat Y2 assumption.

The bounded default follow-up passed **23/0**, exit0, at
`.local/pt24-connected-probe-fixed.log`. Its actual Manual → Ollie →
`Grind_Ledge_RecordingCourt` sequence held the grind24 ticks, banked **1,275 once**,
had zero bails and a clear chase camera. Subsequent fixed native-bearing and
one-translation route assertions await the root's combined run. The design
preview quarter already climbed, launched and returned without a bail in the
first combined run, but its air camera failed the retained full-body frustum
check. That earlier source is rejected; subsequent camera work is verified by
the later focused receipt below with the same full-body assertion.

A later pre-freeze review found that the candidate foundation originally stopped
short of the actual frontage and its narrow side margins did not fit the rider.
The footprint and quarter width above replace that rejected geometry. The new
rear-miss and shoulder assertions await source-bound verification; no engine run
was started during the QE agent's native-engine slot.

Final civic follow-up: **12 passed /0 failed, exit0**, plus **one expected
negative-control rejection**, recorded in `.local/pt24-civic-gutter-final.log`.
Both actual northward shoulder recoveries passed without a jump or bail; the
quarter climbed, launched and returned with a clear full-body chase camera.
Continued southward Push moved into the real stone return, then remained stopped
at Z−109.4814 on Y6 for75 stable frames, with zero bails or ollies. Disabling only
the cap's native shape in the disposable fixture made that same input pass
through to Y0.5125/Z−106.1023 and fail support/contact/containment acceptance.
The shape was restored afterwards. This establishes the cap's physical effect;
it is not a relaxed test or an invisible catch floor.

The final helper, connected-run tests and shared quarter source hashes are in
`.local/pt24-civic-gutter-source-final.sha256`; all three remained unchanged
during the focused run. The root's refreshed combined suite/captures own final
source admission, including the held design/performance gate.
