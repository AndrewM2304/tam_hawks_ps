# Market loading-to-hall connection — 27 October 2026

C04-L04 continues on main from `69fcbc8`. This record separates current source,
actual native-input results and unfinished admission. Normal Main's train, pond,
green and civic-return content remain on. Every fixture disables persistence
before Main enters the tree, keeping personal Music inert.

## Existing route and protected intent

The representative uses the existing **loading terrace drop** east of the steps,
at X100.8/Z−18, then a real flatland Manual with earned Push/Ollie cadence,
the existing `Grind_Ledge_MarketHall` and an outward pop/dry Manual return. It
does not claim to clear the entire stair flight or earn the separate Market
Loading Steps gap. The existing hall edge retains points `(76,.77,4)`,
`(76,.77,10)`, `(69,.77,17)`; no source geometry or global capture policy is
changed to force a catch.

The first source draft used X93 above the actual stair footprint. Independent
QE rejected its slow approach before engine execution: the flight distance
would land on the steps. The implemented initial pose is instead
`(100.8,1.58,−24)` facing south, outside both stair geometry and the separate
stair rail at X99.8. Only this initial placement/facing is assigned. All later
position, heading, momentum, contact, trick and score events come from mapped
inputs and the native controller.

The full combo's final dry Manual to `(83,0,18)` is a continuous part of the
same earned line. A separate ordinary-return fixture resets once at that dry
mouth, then drives north at X83, west across Z−6 to X70, up the existing west
loading bank and back to the terrace near `(93,1.5,−24)`. A second declared
fixture drives the beginner route in reverse, from the loading terrace via
X70/Z−24, the bank and X83/Z−6 to the dry hall mouth. These are independent
no-jump transit fixtures, not uninterrupted same-rider trips following the
combo. The final geometry receipt binds their source but does not execute the
new reverse journey; final combined admission owns its actual result. Delivery
routes, collectible and bench/rail identities remain untouched.

## Retained actual-input attempts

| Attempt | Result | Exact finding |
| --- | --- | --- |
| `market-first` | 5 passed / 2 failed, source-stable 612 inputs, 12.681s | Actual terrace Ollie lands on the native floor and starts a Manual; the unrefreshed long flat approach runs out of speed before the hall. The separate full no-jump return passes. Fixed native samples expose a query discrepancy at the west bank's lateral edge. |
| `market-cadence` | 4 passed / 3 failed, source-stable 612 inputs,13.709s | Two genuine Push/Ollie refreshes preserve the combo for 501 Manual ticks and reach the hall. The release near Z0.27 is too early to meet the guide beginning at Z4; the actor lands against the skirt before capture, and strict camera correctly rejects that miss. No grind allowance is changed. |

Each directory in `focused/` preserves raw receipt/log/maps and the exact test
and observer source used. These are rejected controls, not accepted full routes.
Both retained ordinary-return inputs pass camera/support with zero bails,
recoveries, tricks or manufactured bank. These first failures motivated a later
southward alignment outside the hall and release near Z2; the accepted input
slice is recorded below.

## Native/public bank-edge discrepancy

The independently fixed sample `(76,0,−6.4)` exposes a real query defect:
`get_ground_height` returns0 while a native ray hits
`MarketWestLoadingBank` at Y0.049716. X76 is the patch's exact maximum-X lateral
edge. `CoreTerrain.height_at` classifies all maximum edges as fallback support;
the lower Barras floor is an interior hit and overrides that real bank support.

The original half-open policy remains necessary for flat stairs/decks and
longitudinal grade ends. The bounded source proposal admits an exact lateral
edge only for a nonflat bank graded on the other single axis, strictly between
its end corners. It adds no epsilon, footprint expansion, physics shape or
per-frame native ray. Maximum-height filtering remains in force. Native fixtures
cover both axes and slope directions,1mm inside/outside, end/corner compatibility,
the actual market witness and the earlier independent support-query world sites.

The narrow source fix and its native controls are exercised in the later
wrappers below; final composite admission belongs to integration. A passing
no-jump return does not erase the fixed sample's discrepancy; its sample
location and tolerance remain unchanged.

## Full earned line and narrow query repair

The later release near Z2 reaches the existing hall edge during the eligible
flight window. In the retained `market-bank-after`, `market-broad-cast`,
`market-finite-coarse` and `market-finite-refined` runs, the same ordinary input
line captures a real 50-50 for 47 ticks, records 584 Manual ticks, pops outward,
reaches the dry return and banks an independently derived **6,550 once**.
There are zero bails/recoveries; strict camera and native ground support pass.
These wrappers retain unrelated geometry-diagnostic failures below, so their
whole result is not relabelled as a passing final admission.

The source fix in `CoreTerrain.height_at` now admits the **exact lateral edge**
of a nonflat one-axis graded patch, strictly between end corners. Other maximum
ends/corners and flat steps retain their pre-existing ownership. The maximum
height filter remains before the edge decision. No displayed/native geometry,
physics body, movement/input rule, score rule or capture permission changes.
The added numeric test runs only for a patch point excluded by the existing
half-open interior predicate; no native query, allocation or per-frame rebuild
is added to the production height lookup.

The causal `market-bank-before` wrapper retains **25/5**,7.222s,618 stable
inputs: four actual native lateral fixtures and the exact market point reject
old public support, while all older support-query world controls and outside/
height-filter/end compatibility checks pass. The exact old source is retained.
Both grade axes and gradient signs are tested with eight native inside/edge
sites per fixture and independent analytic plane normals. One millimetre outside
remains the lower floor; capped queries cannot select an elevated bank.

## Boundary measurement, retained rejections and limits

A zero-width native ray exactly tangent to the bank's convex side can select a
different collider when only its vertical range or floating-point endpoints
change. The initial short ray reports bankY0.049716; another short ray and the
fixed broadY4→−1 ray select the lower Barras floor at the same XZ. This is
preserved as a numerical measurement limit, not evidence that changing the
public query moved the physical bank. No target sample or2mm agreement gate is
deleted, displaced or relaxed.

| Later wrapper | Whole result | Distinct finding |
| --- | --- | --- |
| `market-bank-after` | 36/1,13.535s,618 stable inputs | Bank/old support checks and actual full combo pass. Its query-centred zero-width return ray misses the bank at the fixed edge. |
| `market-broad-cast` | 35/2,13.433s,618 stable inputs | A broad ray also chooses the lower floor at the same exact tangent. Full combo remains accepted by its independent event/camera checks. |
| `market-finite-coarse` | 36/3,13.784s,619 stable inputs | A1mm native sphere reaches the correct bank body, but the5m native cast's safe/unsafe bracket is29.3mm wide. Sampling its coarse unsafe position5mm below the top finds the vertical side, so the2mm height comparison correctly rejects it. |
| `market-finite-refined` | 38/1,13.432s,619 stable inputs | One additional cast in that **same** safe/unsafe interval reduces uncertainty to0.172mm. Actual boundary contactY0.049593 agrees with publicY0.050000 within0.407mm. Applying this tiny probe to every interior return site exposes three unrelated small-probe cast limitations; the full combo still passes. |

The final measurement uses ordinary fixed-range native rays for the interior
return samples. Only the known WestLoadingBank lateral X76 edge uses a finite
1mm boundary probe at the **unchanged XZ**, from above both possible levels,
with zero query margin. At most two additional native casts refine their own
safe/unsafe bracket to below0.25mm; each bracket is recorded. The declared0.25mm
rest overlap is below the unchanged2mm agreement gate. It is a test diagnostic,
not a new production physics routine.

The native rest contact at this exact boundary has normal `(1,0,0)`: it is a
near-top **side-boundary contact**, not a claimed floorable normal. A separate
assertion uses the actual `ConvexPolygonShape3D` top vertices to establish that
the original point lies on the real bank plane, plus a1mm-inside native ray with
the independently expected top normal. Together these checks identify the
unchanged bank and its exact top datum without pretending a zero-width tangent
ray is numerically reliable.

A separate immutable old `CoreTerrain` from commit
`69fcbc836e79e87f3a1734b7fb200b35c45f7ae6` reproduces the old 0-height selection
against the same current world patch data. Its SHA256 is
`0aeb9562bbd4cd8a96d7f7f3d071122dbe12fdcfb8c3222ce0efc3a810752ebf`.
This causal negative control cannot pass by probing the buried lower floor.

Broad rays at the artificial fixtures' longitudinal ends/corners and flat-step
maximum edges also hit closed higher tops while their legacy public query stays
lower. Those readings are explicitly printed and retained. Preserving this
compatibility policy is **not highest-native equality** and does not close a
future end/corner support-policy review. The new lateral fix is deliberately
bounded; the production comment now states that limitation honestly.

## Final integration handoff

The final geometry-only observer passes **36 assertions / 0 failures**, exit0,
clean log, **619 unchanged inputs**,7.467562s. It checks the bank fixtures, the
actual world point, all existing support-query world witnesses, the immutable
prior-query negative control and all 234 fixed return sites. It does not replay
the already proved combo or claim the new reverse transit was executed.

[Final receipt](focused/market-geometry-final/receipt.json),
[raw console](focused/market-geometry-final/console.log) and exact before/after
source maps bind the current core, bank/market tests, observer and immutable
legacy source. Seven final source/UID snapshots were checked against that map.
Source-manifest SHA256:
`9ac9b5eeebe96c9689be96eadaaee78c78e785bf3cca1fe3ff110d6b95812b63`.

The unchanged exact bank point reports publicY0.0500000119. The finite native
boundary contact reports Y0.049593, approximately0.407mm away. One bracket
refinement reduces cast uncertainty from29.296875mm to0.171661mm. Its actual
normal remains `(1,0,0)` and is explicitly a side-boundary contact; the separate
convex-top membership and1mm-inside native-normal assertion establish the
supporting top plane. Every 234-site return support and two-way capsule check
passes without moving a target or changing its2mm agreement requirement.
Root owns final combined ordinary-Main admission.

```sh
python3 docs/testing/pt24-connections-2026-10-27/observers/prepare_market_geometry.py
python3 docs/testing/horizon-background/observers/run_checked.py .local/market-geometry-final timeout 60s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/market_geometry_focused.gd -- .local/market_legacy_terrain.gd
```

Final normal-Main registration/full admission belongs to integration. All32
retained source/UID snapshots were checked byte-for-byte against their exact
before-map hashes; [snapshot manifest](market-source-snapshots.json) records
every mapping. No individual focused failure is erased. Mac/controller/
performance, human route readability and fun remain separate.
