# Native floor-following contact inside the Clyde bowl

25 October 2026. Targeted C03 continuation after the manual-grade repair. This
slice concerns ordinary native floor following inside a real bowl; it does not
change transition acquisition, camera tolerances or any skating force/input.

## Retained concrete diagnosis

The relocated bank's original crossing/coast earns100 once and its documented
input-driven bowl escape returns without a bail. Strict full-board visibility
finds three real native penetrations in ContinuousBowlWall. The classifier records
`feature_transition.state == "idle"` and transition normal UP at all three.
Actual board up follows the capsule's floor normal, while the axle's real support
can already be substantially steeper. Actual and interpolated transforms were
recorded; interpolation does not explain the independently measured penetration.

| Rider position | Classified actual GLB material | Reported native normal gap | Complete tyre minimum |
| --- | --- | --- | --- |
| `(−5.628685,.60745,139.6117)` | Urethane rear tyre | −0.751mm | −20.931mm |
| `(−4.377836,.793868,139.2057)` | CastAluminium front axle end | −9.696mm | −33.485mm |
| `(−1.96736,1.133256,136.7784)` | CastAluminium front axle end | −30.722mm | −57.032mm |

Raw evidence is `.local/clyde-bowl-contact-trace.log` and
`.local/clyde-board-material-classify.json`; root owns durable evidence copies.
These are not foot endpoint contacts or a four-millimetre camera allowance.

## Wrong constraint and bounded source correction

`_native_board_floor()` previously rejected its centre, each wheel and fitted
axis if normalY fell below `cos(floor_max_angle)`. This locomotion classification
is not an individual-wheel geometry constraint on a concave surface. At the last
witness the capsule normalY is0.5602 but the real axle support normalY is0.3006.
The helper discarded the finite four-wheel fit and restored the capsule-normal
presentation, burying the tyres and axle ends.

The new render-only context is derived from an actual centre ray hit. Its native
collider must be the surface body of the same valid wrapped feature. A steeper
wheel hit is accepted only on that same physical surface, with finite upward
normalY above0.05. Other flat, quarter and unrelated-wall constraints remain.
The four finite supports determine the board frame; there is no scene-name
whitelist and no physical floor-angle or transition-state change.

Retain the existing three fitting passes,8mm presentation skin,100mm final
vertical-fit refusal and25mm planar-rim limit. Four cached real tyre hulls then
verify that the resulting candidate is clear of actual finite native geometry;
an unfittable candidate is rejected instead of increasing a global lift limit.
The production ceiling is the existing17 fit rays, at most one existing fallback
normal ray, plus four overlap checks: **22 native queries maximum**, with no new
mesh scan, hull construction, world body, material, draw, texture or light.

## Independent verification contract

`tests/pt24_bowl_contact_tests.gd` reconstructs the real native bowl at its actual
world coordinates in a private World3D. It uses all three recorded poses and an
old-locomotion-limit subclass, without a product debug option. Actual native
normal rays verify every real tyre rim and the classified rubber/axle vertex;
independently constructed native hull queries verify full finite tyre clearance.
Recorded old frames must reproduce the penetration. Flat, nonwrapped-quarter
and unrelated-steep-plane controls must retain identical eligibility/results.
Helper calls may change neither physical state nor the physical floor limit.

The original bank crossing/coast and documented bowl escape remain a separate
mandatory actual-input integration regression, with strict camera/native
assertions and earned score unchanged.

## Focused result

The coordinated focused run passes **48/0**, exit0, clean, **591 unchanged
inputs**,12.384s. This comprises14 independent bowl-contact assertions, all29
manual-grade regressions, one inert-Music assertion and four unchanged Clyde
bank/return assertions. Command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-bowl-contact-focused timeout 180 ./tools/run.sh --headless --fixed-fps 60 --script .local/pt24_bowl_contact_focused.gd
```

Manifest SHA256:
`c10767d48b05c32205cf753d5fe4d600e262a518cbad000c9156cddab0c3ead5`.
Root owns durable copying of observer/log/receipt and final combined admission.

For the three exact poses, actual tyre-rim minima are now+6.66/+7.12/+4.47mm;
the greatest individual wheel gap is26.58mm, within the unchanged30mm bound.
The classified rubber/metal vertices clear the concrete by18.23/32.83/31.37mm.
Every independently tested finite tyre hull is clear. Recorded old frames still
reproduce−20.95/−33.47/−57.03mm penetration, while the old eligibility control
rejects all three fits. Flat/quarter/unrelated-steep controls match exactly;
the physical floor policy and state remain unchanged. All manual regression
physics/pivot/feet/planar controls still pass.

The original Clyde bank crossing/coast and documented escape now pass70 strict
camera samples and208 bowl samples, with zero bails and the100-point bank
preserved. The unchanged coast point remains`(−1.928904,1.161967,136.7102)`;
the ordinary return reaches`(−14.243319,2.014188,123.98481)` on the supported
Z124 bypass. No route input, score or camera assertion was altered.

A preceding Gallery/Station diagnostic retained repeated optional-metadata
errors after this helper first appeared; ordinary floors lack `transition_feature`.
The guarded lookup now checks `has_meta` before reading. That earlier log is
rejected despite its gameplay assertions; the clean focused receipt above
includes the guard. Full regression, rendered/source binding and target-Mac
visual/feel remain integration acceptance, not inferred from these checks.
