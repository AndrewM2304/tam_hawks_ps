# Park summit → downhill seat → civic return

**Accepted representative: summit → downhill50-50 → civic return banks9,432
once, zero bails/recoveries.** Focused27/0, clean609 stable inputs,15.938s.
The protected entire miss also passes both directions with540 fixed native
width samples. This completes the automated summit/east-descent/city-return
representative; the optional cutback/facility chains and human acceptance remain.

27 October 2026, source parent `c82ffac`. Existing normal
Main construction, Apple Music isolation, native skating and scoring are preserved.
This work introduces no obstacle, resource, rendering or physics-runtime change.

The existing local downhill representative proves the single lower-seat catch,
Manual runout and next-feature choice. It does not prove the summit/cutback
extension or the whole city return. The natural east descent leaves the park
via the civic promenade near Z−125; the other existing seat at Z−112 lies beyond
that turn. Requiring both seats before an eastward city return would force a
backtrack rather than author a natural line.

## Bounded actual input and retained rejections

The staged combo starts near (−157,17.08,−174), follows the summit's eastern
choice, performs a real Ollie and Manual, attempts the existing
`Grind_Ledge_park_east_lower`, then plans a Manual into the civic promenade.
Only initial spawn/facing is assigned. No per-tick pose, velocity, heading,
score, correction or mid-combo restart is used. The existing independent catalog,
repetition/hold-point receipt and strict whole-rider camera assertions remain.

All retained runs use ordinary Main defaults, with persistence disabled **before**
Main enters the tree. Pre-mode Music worker/account isolation and normal enabled
trial-content assertions pass. `focused/` retains exact source maps, console,
receipts and test/observer snapshots for each attempt:

| Attempt | Result | Finding |
| --- | --- | --- |
| `first` | Rejected parser; stopped, exit−15 | Dictionary-derived `reached` required explicit `bool`; no gameplay result. |
| `first-input` | 3/2, stable source | Initial Manual did not enter; the separate entire summit→civic no-jump route passes. |
| `grounded-manual` | 3/2, stable source | A grounded-only Manual request still occurred before the pending Ollie release had been processed. |
| `summit-speed` | 3/2, stable source | Faster initial Push confirms premature Manual request at the prior grounded pose; straight unsteered fallback reaches boundary, correctly rejected by camera. |
| `processed-takeoff` | 3/2, stable source | One actual takeoff tick before the landing helper resolves initial Manual; 160 Manual ticks reach the lower approach. Early short pop misses the seat. |
| `lower-pop` | 3/2, stable source | 183 Manual ticks, ~5.4m/s lower approach; inherited short-pop timing still lands before the raised seat's front. |
| `charged-lower-pop` | 3/2, stable source | 186 Manual ticks and full charged pop clear the front but no guide is captured. Camera correctly rejects seat occlusion after the miss. |

These are rejected candidate controls, **not** a completed flagship run or a
production skating defect. The previously successful local catch approaches
at approximately7.08m/s; the summit candidate approaches around5.4m/s. A new
geometry/force/capture allowance is not justified by that difference. The later native diagnostic below separates actual tangent eligibility from
that speed observation; neither justifies a runtime allowance change.

The final rejected candidate is preserved in `observers/rejected_combo_candidate.gd`
with its observer. To rerun, copy it to `.local/pt24_park_combo_candidate.gd` and
the observer to `.local/pt24_park_combo_focused.gd`; include both local paths as
arguments to the source-binding wrapper so the ignored dependency is hashed.
It is deliberately not registered as a passing suite.

## Protected whole-run miss

Every actual-input candidate also proves the **entire summit→civic no-jump
bypass**, from the declared summit start through the east road's centre/east
lane, turning into the existing promenade and arriving near
(−45.148,6.012,−122.064). It produces zero tricks, bank, bails or recoveries, with
native support and strict complete-rider chase clearance.

`tests/pt24_park_flagship_tests.gd` separates that protected miss from combo
admission, adds the actual reverse journey, and independently samples a fixed
full-width path with native rays and short ground-fitted two-way capsule sweeps.
The focused final protected-miss test passes **5/0**, exit0, clean,606 unchanged
source inputs,24.664s. Its540 fixed full-width samples have maximum public-query
versus native-height error **0.0463mm**, with two-way capsule sweeps clear.
Both actual no-jump journeys pass with complete-rider camera/support, zero
entries, banks, bails or recoveries. Final positions are approximately
(−45.1865,6.0125,−122.0659) east and(−156.1308,16.7835,−173.1861) at the summit.

Receipt: `focused/full-miss/receipt.json`; manifest SHA256
`67d4d17e3ee582624775fc7bcd2cc51c907ed3a95aa74db3459c4cadc04ee67d`.
Command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-park-2026-10-27/full-miss timeout 90s ./tools/run.sh --headless --fixed-fps 60 --script .local/pt24_park_flagship_focused.gd
```

This admits the protected whole-run miss, **not** the staged full combo. Full
summit/cutback combo, human readability/fun and target-Mac performance/visual
acceptance remain open.


## Exact guide-admission diagnostic

The later `native-contact-diag` attempt is rejected2/2, source-stable607inputs,
9.123s. The ignored candidate source is explicitly passed after the `--` user
argument boundary so the receipt wrapper hashes its actual dependency as well
as the ignored observer. Its snapshot and manifest are retained alongside the
raw log. This diagnoses only the candidate; it is not a production change.

At(−147.3754,10.1261,−140.1985), the actual descending rider is0.3288m above and
0.3781m from the guide. Held-grind request, clean spin and native capsule path
clearance all pass. However, the closest curve point is still on the front edge:
tangent(0.9864,−0.0448,0.1581). Its horizontal approach alignment is approximately
0.158, below the existingcos65°/0.4226 gate. Increasing capture radius or changing
the seat would hide an input/approach problem. The earlier suggestion that speed
alone explained the miss is therefore incomplete.

A derived6cm outward input target is also tested in `corner-tangent` and remains
rejected2/2, stable607inputs,9.222s. Its changed approach arrives slower during
the15-tick charge(5.56→3.32m/s), retiming the jump and again reaching the front
without capture. No gate is weakened. These two exact candidate/observer
snapshots are retained for further work rather than registering a failed claim.

A useful next bounded approach is a real Push/short-Ollie setup after ending the
summit Manual, within the existing0.35s landing-link deadline, to meet the known
local capture's actual speed and corner tangent. A later103m promenade Manual
also needs earned momentum and cadence; its0.75m/s² rolling drag should be
accounted for using the existing practice ledge or genuine Push/Ollie links.
No native collision/support gap is established along the accepted full-width
miss, and there is no justification to add more props or alter force/score rules.

## Authored long-edge correction — accepted focused admission

The independent route review confirms that nearest-point tangent selection is
an existing global skating policy. The lower seat's **closed perimeter guide**
was a poor authored approach: its transverse front cap masks the useful inboard
long edge at the normal downhill arrival. This is a route-authoring issue,
separate from changing the shared capture algorithm.

The approved bounded correction publishes only that actual inboard long edge,
from approximately(−147.3186,9.7973,−140.0116) to
(−147.3583,7.4610,−132.0117), under the exact existing
`Grind_Ledge_park_east_lower` ID. Its8m horizontal bearing is still physically
present. `outdoor_routes.gd` continues refitting the complete original perimeter
for **all four native cylinders and four displayed instances**, whole stone
bench collision/mesh, support/query footprint, material and12 bench identities.
Only the useful finite guide and matching feature-line publication change.
No global capture range/tangent/physics/score rule or new prop is introduced.

A straight grade can legitimately receive the existing lowered-cylinder radial
contact datum; the test checks nine independent normal rays against the retained
native bearing rather than forcing generic/named classification. Fixed endpoints,
existing mesh/shape/instance counts and the previous actual local-descent proof
are retained. The new staged full-combo test is
`tests/pt24_park_full_combo_tests.gd`; it will only be registered after real mapped
input, native contact, one independently calculated bank and strict camera pass.
Its current presence is implementation under verification, not an admitted run.

## Finite guide and real Push/Ollie admission

The first finite-guide wrapper is retained as a parse rejection: the new
Variant-derived contact boolean needed an explicit `bool` annotation. It was
stopped at42.902s, source-stable609 inputs, exit−15, with no gameplay result.
Only the test annotation changed for the subsequent input run.

`finite-guide-input` rejects24/3,12.281s, stable609inputs. Both guide-coordinate
and actual radial-contact checks pass, as do the retained physical/display
counts. The existing local line now catches a real50-50 and banks2,000 once,
with camera and ground support passing. The named fitted pose reaches the next
choice sooner:40 Manual ticks still travel8m, below the existing45-tick assertion.
The driver is therefore extended by2m along the independently protected bypass,
without reducing that duration or distance assertion. The full candidate still
arrives too slowly for its old charged Manual pop.

`finite-guide-push-pop` rejects only the unfinished full-city arrival: **26/1**,
14.731s, stable609inputs. Every existing local construction/contact/resource/
readability/bypass assertion passes. Its actual Manual now lasts50ticks and
travels10.058m toZ−117.852; the bank remains exactly2,000 once.

The full summit candidate ends its real Manual nearZ−145.25, uses17 ticks of
stable Push/short-Ollie setup before the0.35s link expires, and catches the finite
edge as a real50-50 for33ticks. It performs890 total Manual ticks, banks exactly
**3,450 once**, and has zero bails/recoveries with strict camera/native support.
Only the city-return completion fails: ordinary flatland drag exhausts the long
unbroken Manual aroundX−114.78. The103m promenade cannot be treated as an
unlimited-speed Manual by a test driver.

The next staged input uses three declared existing flatland waypoints near
X−134/−110/−80, with genuine Push/charged-Ollie→native landing→fresh Manual links.
Each quarter-second setup stays inside the unchanged0.35s landing-link deadline;
ordinary pushing and jump physics supply all momentum. No new force, score
award, capture permission or runtime rendering is introduced. The exact final
full-run receipt remains pending until that candidate is actually driven.


## Accepted summit → civic representative

`finite-guide-cadence` passes **27/0**, exit0, clean, **609 unchanged inputs**,
15.938s. Receipt: `focused/finite-guide-cadence/receipt.json`; manifest SHA256
`d8ff258af17279247902ce6ae12642c7398142b9e1bb0fdc12cc5db1881fe046`.
Exact final observer, local test, full-combo test and outdoor source snapshots
match their manifest hashes; all earlier rejections remain retained.

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-park-2026-10-27/finite-guide-cadence timeout 120s ./tools/run.sh --headless --fixed-fps 60 --script .local/pt24_park_guide_focused.gd
```

Ordinary Main defaults are used. Initial spawn/facing are the only actor writes;
ordinary mapped Push/Brake, shoulder/steering balance, Ollie, Manual and Grind
produce the entire line. The exact earned sequence contains a50-50 at the
existing lower seat,33 grind ticks,1,181 Manual ticks and three genuine momentum/
flatland links nearX−134/−110/−80. One of the later mapped launches legitimately
selects **Nollie**; all12 actual catalog entries, repetition decay and50 real
hold points independently calculate **9,432**, banked **once**. There are zero
bails or recoveries, strict complete-rider/board chase clearance and continuous
native Manual support. Final dry civic arrival is approximately
(−44.6172,6.0123,−122.0358).

The existing local input representative also passes unchanged contact/camera/
readability and bank assertions, with its actual safe runout extended2m to
retain the original45-tick minimum at the faster named-contact pose. It now
performs50 Manual ticks over10.058m and still banks exactly2,000 once. All four
native cylinders, four displayed bearing instances,12-triangle bench mesh,
materials and protected two-way local transit remain intact. Nine independent
normal rays accept the newly straight guide's actual lowered-cylinder datum.

This proof accepts a complete summit/east-downhill/civic-return representative.
It does not certify the optional cutback, every promenade→sunken-facility branch,
optimal/human route readability, final art, or target-Mac/controller/performance.
The captured traveled distance212.45m includes the actual carves; it is not a
surveyed shortest path. No new obstacle or global capture/force/score permission
was needed. Root owns final combined/default integration admission.
