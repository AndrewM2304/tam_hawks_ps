# Independent connection review — 27 October 2026

Source parent: `69fcbc836e79e87f3a1734b7fb200b35c45f7ae6`. This review uses
source-defined geometry and existing route contracts. It does not run another
engine, certify a new input witness or replace the current batch's receipts.
Normal Main keeps the merged station/train, pond, green and civic return on.

## Market loading → hall

The original candidate at X93, releasing an Ollie at Z−15.3 and about6m/s, was
inside the actual `MarketLoadingSteps` footprint: X87…99, Z−14…−8. A jump from
the1.5m loading level with the existing7.2…9m/s impulse and34m/s² gravity reaches
the lower floor after about0.58…0.66s. At6m/s it covers only3.5…4m, rather than
the7.3m needed to clear that stair run. This was identified before an engine run;
no failed gameplay result or missing-floor claim is inferred from the estimate.

The revised candidate uses the real terrace drop at X100.8/Z−18, releasing near
Z−19.3. This clears the stair's east edge and the existing `Grind_Rail_MarketSteps`
at X99.8. It then turns through the open lower aisle near Z−2 toward the actual
`Grind_Ledge_MarketHall` north end at `(76,0.77,4)`. That guide continues down the
hall's east side before its chamfer; the nearby bank spans X76…80, Z4…10 and
reaches the real0.65m masonry skirt. A catch still needs actual native admission,
not just the source proximity of those pieces.

The proposed ordinary return through X82/Z−6 to X70/Z−6 and up
`MarketWestLoadingBank` is consistent with its authored footprint X54…76,
Z−18…−6 and its1.5→0 grade. The Recording Court, both loading-bank choices,
existing market stall aisles and delivery routes must remain intact. No source
geometry change is justified by the discarded stair-crossing approach.

The later native market diagnostic does establish a separate query defect at
`(76,0,−6.4)`: the real `MarketWestLoadingBank` ray hits Y0.049716 with normal
approximately`(0,0.992275,0.124059)`, while `CoreTerrain.height_at` returns the
overlapping lower floor at Y0. Its blanket half-open maximum-X rule demotes this
actual lateral bank edge to `outer_edge`, then ignores it because the lower
`BarrasFloor` has an interior result. This finding belongs to the retained
`pt24-market-cadence` rejection, not a new QE engine run.

A bounded source rule can distinguish an axis-aligned grade's **lateral** edge
from its rising/falling **end cap**. For an exact maximum-X edge, require equal
heights across X at both Z ends, a nonzero Z grade, and Z strictly inside the
rectangle; mirror that condition for a maximum-Z lateral edge of an X grade.
Keep flat steps/decks and maximum end caps/corners under the existing policy.
This would retain the old X50/Z−16 street control because that street grades
along X: its maximum X is an end, not a lateral edge. This proposal still needs
native isolated controls for both axes and grade directions, capped-height
selection, outside points, steps and suspended decks before admission.

The old maximum-edge regression rays are centred narrowly on the expected
height. They remain useful compatibility controls, but a ray beginning below a
possible higher top cannot establish which surface is highest. New fixtures
should separately cast from above both native levels, record the actual normal
and collider, and exercise the height-aware limit. No existing assertion or
ray distance should be weakened to obtain a passing repair.

The new broad isolated casts confirm that this distinction matters: retained
longitudinal/flat maximum-edge query values remain0 by the old ownership
contract, while a ray from above can hit their actual higher native cap. Those
compatibility assertions do not prove native-height equality at every terminal
edge. The current repair is deliberately the real lateral-grade mismatch, not
a global rewrite of that terminal ownership policy. No new gameplay failure is
inferred from a preserved boundary contract alone.

## Civic → park practice

The proposed line begins at the already-tested Civic return approach near
`(−38.5,6.08,−124.8)`, earns real quarter air, lands into a fresh Manual, then
turns west through the actual civic mouth toward the promenade/practice choice.
The real western port crosses X−35…−42 near Z−122; the10m promenade continues
to the park road near `(−145,6,−125)`. Westward steering belongs after native
landing, with airborne spin inputs cleared.

The rear miss shoulder at X−41.4/Z−110.2 has an existing full-length supported
return north to Z−122. A later low-point return at X−22 uses the actual
`CivicWestBank`: X−35…−17, Z−108…−96, Y6→4. It must stay on that bank rather
than cut across enclosed lawn. An earned Push/Ollie/Manual link on the long
flatland is valid; an indefinitely powered Manual or per-tick velocity write is
not. No new obstacle or wall removal follows from this source review.

## Practice → facility and return

The accepted scope is a real practice combo and bank, followed by ordinary
supported hill travel, facility entry/beginner circuit and the same rider's
return. It does not promise an uninterrupted200m uphill combo. The source route
has a north through lane beside the southern practice apron, then the eastern
hill road to the summit, viewpoint spur and existing access ramp:

`(−173,17,−182.5)` → `(−179,17,−182.5)` →
`(−183.25,15.75,−182.5)` → `(−187.5,14.5,−182.5)`.

At the destination, the arrival deck's western face is retained except at the
real beginner bank opening. In world coordinates the bank spans X−200…−190,
Z−181…−177, descending Y14.5→13. A diagonal from the entrance directly into the
lower street would cross another retaining span. Reuse the published beginner
route: entrance → `(−189,14.5,−179)` → `(−190,14.5,−179)` →
`(−200,13,−179)`, then its existing lower-street loop and return.

The previous facility `_beginner` test resets its fixture and checks head
frustum/ray visibility. Those results remain useful local evidence but cannot
stand in for the new uninterrupted journey or its complete-body camera check.
The new witness must keep the same actor after its one initial placement and
check actual board/feet/head visibility using the ordinary Driver camera
observer. If that exposes a contact or clearance failure, retain its exact
native collider/pose rather than weaken visibility to the old head-only metric.

## Evidence review rules

For each published test, inspect actual input/state transitions, native support
and guide identity, once-only catalog/repetition/hold banking, callback cleanup,
spawn/mode restoration and camera coverage. Initial placement is allowed;
mid-route actor/heading/velocity writes and manufactured score are not. Declared
fixture resets must be separated from any claimed uninterrupted journey.

The three specialists own their test/observer paths. Root owns integration and
the serialized engine lease. Any proposed production placement change still
needs native/display/query agreement, protected IDs/returns and a bounded cost
record. No such change is approved or implemented by this source review.

Actual Mac execution, physical controls, Music playback, target performance,
moving shadows, final art and human readability/fun remain separate evidence.

## Final bank diagnostic scope

The zero-width boundary cast is numerically fragile even with a longer vertical
range. The final decision keeps ordinary native rays for the return grid and
uses a finite1mm native probe only at the known exact western-bank lateral
boundary. It does not expand production footprints or change the2mm agreement
gate. The probe's actual contact is Y0.049593 versus query Y0.050000, about0.407mm
apart. Its horizontal side normal is explicitly a near-top boundary contact,
not proof of a floor-bearing normal. Actual native convex top-plane membership
and a separate1mm interior native plane/normal check provide that geometric
evidence; real mapped bank travel remains the complementary physical witness.

The probe starts above both levels and records its safe/unsafe bracket, bounded
refinement count and uncertainty. It is not installed in production. Attempts
that used refinement from an already-colliding origin caused false empty hits
at ordinary interior sites; those rejected diagnostics remain history. They do
not justify another terrain change or a relaxed tolerance.

## Practice district classification

The authored `PRACTICE_APRON` is X−118…−76, Z−139.5…−126. Its quarter, ledge and
manual pad lie outside both `PARK_LANDSCAPE` and the narrow promenade-distance
test, so the public world query previously fell back to Central Station despite
their existing Kelvingrove feature metadata. Recognizing this exact existing
apron is a bounded identity repair; enlarging the landscape or connector radius
would capture unrelated city space.

Public query controls must include the named practice interiors and surrounding
Central/George guards. Core checkpoint coordinates stay unchanged. The career
still accepts only its original four core district IDs, so the corrected park
classification stops false Central-visit credit without changing save IDs or
schemas. Main passes the corrected label to audio; the current Kelvingrove bed
uses the existing Exchange fallback, as elsewhere in the park. This changes
routing from the former Central bed but adds no audio asset or stream.

The specialist's causal classification witness is source-stable9/7 before the
exact apron inclusion and16/0 after it. Named interiors, authored edge sites,
outside guards, unchanged station/civic contexts and the public feature location
names are checked through the real World API. No feature metadata override
stands in for that public result.

## Focused evidence reviewed

The facility specialist's final11/0 receipt is clean and source-stable. Its
same-actor385.421m journey earns the1,100-point practice bank once, traverses the
hill/access, completes1,101 observed beginner-circuit ticks, and returns without
bails, recovery, new trick entries or another bank. Complete-body camera,
ordinary support, next-choice visibility and actual location cues pass. These
are the specialist's recorded native results; QE did not launch another engine.

Two earlier rejections remain meaningful. The first identified a driver turn
while the quarter exit still carried backward14.4m/s momentum; actual Brake
stops it before the turn. The second completed the route but stopped on the
descending access too early: a generic65cm target radius accepted Y14.7033
instead of the intended14.5m entry. The final driver approaches within18cm XZ,
retaining the independent15cm height gate, and records actual Y14.5723. Declared
6/17/15.75/14.5m route levels are also checked separately from native/query
agreement, with maximum58.7mm error. No physics, camera tolerance, native floor
or support allowance changes obtain these results.

The civic first round-trip result revealed the same endpoint-class issue:
returning within1.2m of its nominal Y1 start accepted Y1.3158 on the return ramp.
The revised endpoint must lie wholly inside the low court and independently
assert the actual low-floor height. A passed route-proximity test alone cannot
close that low-point return claim.

Moving that start south to Z−64.2 is not a valid remedy: it enters the existing
`merchant_low_return` seat, which runs X−81…−76 along Z−64.6. The original
Z−65.6 start is already beyond the ramp's Z−66 toe and north of the seat. Keep
that clear start and require a tighter, slower final mapped approach into the
same low-floor interval. An invalid fixture starting inside furniture does not
justify moving the seat, adding a floor or weakening the low-height gate.

The next actual civic lip→Ollie→Fakie Kickflip→Revert→Manual/practice line reaches
the destination with clear camera/support and an independently correct13,882
bank, but its4/1 focused result correctly remains rejected: the old generic
Driver receipt expected an unstyled catalog label. The new civic-local receipt
captures takeoff mode at every actual trick signal, admits exact known styling
only for flip/grab families, and preserves the original event trace. Revert,
Manual, lip and launch entries stay canonical. Points, repetition, holds,
multiplier, one-bank and native safety checks remain unchanged; no production
scoring change or shared Driver weakening follows from this test correction.

The subsequent civic full witness passes23/0, clean and source-stable. Its
11-entry stance-aware receipt independently computes13,882 once; the72.059m
combo reaches practice with clear camera/support. The327.024m ordinary low-point
round trip now restores the original clear start and uses a slow final approach
with12cm arrival radius plus actual Brake. It ends at Y1.011853/Z−65.70354, with
the independent Y<1.15 requirement and strict camera intact. No seat is moved.

Root's final market geometry-only witness passes36/0, clean and source-stable.
The actual bank query is0.050000 while the scoped finite boundary contact is
0.049593; all234 fixed return sites and two-way capsule sweeps pass. The physical
market input branch separately earns6,550 once with47 hall-grind ticks and584
Manual ticks, zero bails/recoveries, and strict camera/support. Earlier wrappers
containing that branch remain rejected where their diagnostic assertions
failed; the final combined receipt owns complete integrated route admission.
