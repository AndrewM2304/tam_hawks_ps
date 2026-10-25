# Approved PT24 continuation — 25 October 2026

The owner approved the [consolidated remaining-work list](../../planning/PT24-CONSOLIDATED-2026-10-25.md)
and asked to proceed. Work is directly on main from `6b18f30`. Specialists divided
planning, landscape/material ownership, connected runs, railway, pond/cables,
rendering and independent acceptance. Existing optional prototypes are retained;
the approved deferrals concern further development, not deleting working content.

## Ordinary play changes

| Work | Result |
| --- | --- |
| PT24-04/07 | Grass display relinquishes both core ports and outdoor road arms. Station-port paving follows actual native support planes; matching vertical faces close the complete approach perimeter, including the measured 20mm shoulder slot. Existing top grades, support queries and retaining walls remain. |
| PT24-12/21 | Remove 228m² of duplicate quay paving under real stone coping and 4cm overlap between station-north plinth pieces. Lighting settings are unchanged. |
| PT24-11/19/20/27 and layout handoffs | Reuse four existing feature groups for the Exchange, civic back street, station and safe-bridge return. The recording court now has a low kerb and actual steel bearing. The service shutter controls a framed alley with a seven-metre saving over its bypass. |
| PT24-25 | Existing red bridge cable facets receive sixteen matching native shapes and two finite grind guides. Actual input completes handrail→air→cable→air→handrail→dry landing in both travel directions. |
| C03/C10 | Exact camera query memoization is restricted to one synchronous update. Every native sweep and anatomical clearance rule remains; obstacle changes invalidate the next update. Prepare immutable board landmarks at startup. |

The actual market Manual→Ollie→steel grind holds 24 physics ticks and banks
1,275 once, with zero bails and a clear chase. The two cable runs hold the cable
17 ticks each and bank 8,696 / 4,109 once, with zero bails. Initial placement is
declared; subsequent motion, catches and score follow mapped production inputs.

## Explicit design candidate

Additional rendering remains behind the existing stutter/performance admission.
The implementation is concrete and can be inspected on target hardware with:

```sh
./tools/run.sh -- --pt24-design-preview
```

This source-launch switch does not enable the candidate in ordinary launches.
It installs:

- **PT24-15:** enclosed west station wing, elevated railway and original two-coach
  train. Opaque tunnels conceal the whole train at loop wrap; the park passage
  remains underneath. The train pauses and resets with the existing world.
- **PT24-16:** actual lawn excavation, shore/basin/water, two original ducks,
  closed native grind rail and dry bypass. Existing dramatic water recovery is
  used; no separate score or recovery lifecycle is introduced.
- **PT24-17:** six existing trees form two grounded groves in the fenced green,
  preserving the central view slot and lower court. Whole native mesh envelopes
  exclude architecture. Tree-batch bounds change, requiring measured admission.
- **PT24-18:** finite civic return quarter with grounded construction and two
  supported escape shoulders; the original west-going park mouth stays open.

Independent final review found a further east-side gutter beyond that candidate's
rear shoulder. A short stone frontage return now joins the real facade to the
existing fence before the supported landing ends. It adds twelve displayed
triangles and one box on the existing foundation, no body or draw surface.
The fixed continued-south input stops on real native contact while both north
returns remain open. Removing only that native cap in the negative control
exposes the original fall from Y6 to the lower lawn; the test rejects it.

The pond and central green are different sites. They are not silently merged
into one pocket. Candidate tests exercise actual Main integration as well as
independent native fixtures. Candidate code is not a claim of target-Mac timing,
human art acceptance or completed default-play admission.

The actual pond input sequence runs in both directions: dry-ground Push,
charged Ollie, 27 perimeter-grind ticks, outward Ollie, twelve dry Manual ticks,
then one **1,900** bank with zero bails. A subsequent steered water entry invokes
one existing bail/recovery and preserves that earned bank.

## Construction and runtime bounds

Default world: **565 bodies / 1,698 shapes**. The twelve original bench identities
and 44 bench boxes remain. The independently protected original inventory is
still **271 bodies / 728 shapes**. The only additions are one cable body with
sixteen art-matched facets, and one compound gate-frame shape in the existing
station floor. Old addition categories and guarded map spans remain checked.

Default changed displays: grass **8,808→8,780** (−28), core port **12→54** (+42),
approach +166, quay **528→213** (−315), gate frame +12: **−123 triangles net**,
no added display surface, texture, material or light. The 166 matching vertical
triangles close the existing road's native shape over all 88 side/end intervals;
no additional shape is introduced. The declared closure ceiling is 192 triangles.
The 0.25mm edge envelope is explicitly bounded numerical polygon precision:
visible interior grass overlap is zero over the 705.142043m² road-arm footprint
and 240m² core port; raw shared-edge roundoff is bounded at 0.001107m². The
initial narrow outdoor-only witness omitted the core port and was rejected.

The camera parity fixture compares 96 exact cached/uncached update pairs. Native
shape queries fall **564→168** and visibility rays **44,100→29,400**; all **336
sweeps** remain. Transform/FOV/state and rider physics match, including moved
obstacles, reset and direct calls outside the cache scope. These are query-count
results, not measured Mac frame-time improvement.

Candidate budgets are declared in [station](station.md), [pond/cables](pond-cable.md),
[green](green.md) and [layout](layout.md). No new lights, downloaded art or textures
are introduced. References and earlier provenance remain intact. Shared built-in
resources and startup-only construction are used; no offscreen gameplay is unloaded.

## Verification and retained negative evidence

Per-tick native trace JSON is retained losslessly as `lines/*.json.gz` to avoid
duplicating millions of text rows. Each `lines/MANIFEST.json` records the original
byte count/hash and compressed hash. Full stdout, receipts and source manifests
remain plain text; original local trace output is also retained.

The first frozen combined check is **rejected: 4,809 passed / 13 failed**,
572 unchanged inputs, 360.705s. All failures identify legacy test assumptions:
56 routes before seven additions, old paving-only footprint ownership, and
wallride fixtures aimed at recording walls deliberately replaced by the new
loading edge. Their regression requirements remain: exact original route IDs,
native support/visible coverage, actual wallride/wallie contacts and one correct
five-entry bank. The wallride fixture moves by an exact reflection/translation
to the backed print-yard wall; controller timing, contact/score thresholds and
relative wall gap are preserved.

Focused development logs are diagnostic, not combined admission. Retain the
missing fixture-material error, off-map precision failures and early geometry
fragmentation results. The native fixtures now use private World3D instances
at actual map coordinates; physical contact tolerances are unchanged.

The first rendered lower-entry frame was rejected for grass wedges at the
omitted core port. Corrected full-port support probes then established up to
0.214260m native/display mismatch. Paving conformance removed that mismatch,
but the second frame exposed a separate grazing view through a 20mm shoulder
slot. Pixel-derived native/visible rays identified the actual two support
planes and distant footing behind the missing face. Matching visible/native
edge caps first closed those three sites; focused **33/0** retained six cap rays,
three fixed visual witnesses and two ordinary no-jump crossings. Refreshed
rendered review then found 319 unchanged bright pixels along the continuation
beyond the core-port boundary. That frame is retained as rejected evidence.
The final closure covers both full road sides and both ends through Z−82,
with 176 two-sided native rays, exact original top-triangle preservation and
four ordinary no-jump crossings. No height offset or global material bias was
introduced. [Detailed causal evidence](park.md).

The civic ramp camera check observes the completed node-process update, because
SceneTree.process_frame is emitted before camera processing. Its original early
sampling logs remain. A no-framing control still fails after that correction;
the admitted camera correction minimally fits real head/board/foot bounds while
retaining position, orbit, roll transport, FOV and native clearance. The candidate
air/return and full-frustum assertion remain hard requirements.

### Final source admission

Required command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-continuation-admitted ./tools/check.sh
python3 tools/source_launch_smoke.py --output .local/pt24-continuation-cold
```

The final required suite passes **4852/0**, exit zero, clean log,
**572 unchanged inputs**, 371.399s.
[Receipt](validation/final/receipt.json), [before](validation/final/source-before.json)
and [after](validation/final/source-after.json) bind the exact source;
manifest SHA-256 `716ce55284c029f59d3bc07a477022ec8d689372ab7732d94019e17e4e053dcb`.
The intermediate 4,843/0 predates the civic gutter cap; 4,845/0 predates the
complete approach-shoulder closure. Both remain under validation. Rendered review
rejected the latter's remaining far-right slot despite passing native tests.

Cold source passes **all four phases**, **481 unchanged inputs**,
including actual title-to-play **44/0** and expected exit-one refusal of the
deliberately broken disposable copy. [Cold receipt](validation/cold/SOURCE-LAUNCH.json).
No real player profile is overwritten; no Mac launch is inferred.

[Placement manifest](captures/manifest.json): **12 PNGs / 0 failures**,
completed normal render-loop frames and unchanged runtime sources.
[Matched baseline](temporal/before/manifest.json) / [repair](temporal/after/manifest.json):
**9+9 world-only readbacks / 0 failures**, identical source/cameras/settings.
The PNG hashes and current runtime bindings are checked. Static paused placement,
analytic camera advances and backend counters do not certify played motion,
temporal stability or target performance. Current-source unsigned Linux/macOS packages are being prepared; their source and archive receipts will follow. Actual Mac execution remains open.


## Still distinct

PT24-01/09/10 and remaining temporal acceptance of PT24-12/21 require matched
moving target evidence; source-proven overlap removal does not establish shadow
stability. The earlier unrecorded contraction photos have no demonstrated causal
link to the fixed startup pose. Mac/DualSense, ten-minute stutter/performance,
listening, final realistic art/fun and fresh standalone-Mac acceptance remain
unverified until actually performed. No hosted CI, release, signing, spending
or unattended/background continuation is authorized or started.
