# C02: remaining civic, park and Exchange display ownership

25 October 2026. Source baseline `258fec4` on main, following the personal Mac
soundtrack merge. This slice preserves those changes and all earlier PT24
repairs. The exact owner witnesses are civic captures2/3/5, park16/17 and
Exchange18 from the original debug-session packet.

## Proven geometry and bounded repair

The new work changes only startup display ownership in
`game/levels/pt24_render_repairs.gd`. No light, shadow bias/range/filter, material,
native body/shape, input, Music, route, grind or save identity is changed.
There are no new resident surfaces, draw submissions, textures, lights or frame
callbacks. Added clipping triangulation must be offset by removed covered box
faces; the combined changed displays may not increase their triangle count.

| Witness/slice | Independent source intersection | Display owner after repair |
| --- | --- | --- |
| PT24-01 capture5 | `GeorgeSquareFloor` reachesX36 atY4; east `CivicBackStreet` startsX35 overZ−86…−74. Their top faces overlap by **12m²**. | Existing asphalt ownsX35…36 in that12m cross-street band; civic paving retains its remaining **5,100m²** top and every retaining/bottom face. |
| PT24-10 capture18 | The tenement centred at(−41,0,0) has its south wall atZ15, X−47…−35, Y0…16. `CentralSouthStreet` has a retaining face at the sameZ, with topY=(−35−X)×2/15. The common wedge is **9.6m²**. | Actual tenement masonry owns that wall wedge. The road top and its exposed foundation belowY0 remain unchanged. |
| PT24-09 north retaining caps | Five park retaining boxes end atY0 in facility coordinates, Z3.35…3.5. Their top faces sit under the existing upper paving, outside both bowl/channel holes. | Upper paving owns those covered caps; all five exposed front walls remain. |
| PT24-09 arrival retaining pieces | Two narrow boxes sit entirely inside `EastArrivalDeck`; their top and western face exactly coincide with the deck. | Existing arrival deck owns its top/western wall. Other retaining faces, native boxes and grind contacts remain. |

The five north caps cover **3.199700m²**; arrival duplicate tops cover **0.75m²**,
and their duplicate western faces cover **11.25m²**. Removing those selected
faces removes **18 triangles**. The helper identifies the fixed physical box
positions/dimensions, since repeated Godot node names are not reliable IDs.

The park work is a proven construction correction near the reported tile-wall
views. It is not evidence that every shaded tile/port-cheek symptom in captures
16/17 shares this cause. Likewise, the civic cross-street repair addresses a
positive-area overlap at capture5, not an established cause at captures2/3.

## Deterministic regression contracts

`tests/pt24_render_repairs_tests.gd` retains the original coping/plinth checks and
adds fixed independent witnesses for:

- Civic top area **5,112→5,100m²**, real asphalt display at the removed strip,
  and neighbouring civic paving that must remain visible.
- Exchange north road-side area **60→50.4m²**, actual tenement wall coverage of
  the removed wedge, and the exposed below-Y0 foundation at the same bearings.
- All five north walls' exposed fronts, their actual upper paving, and both
  arrival boxes' real deck replacements; a missing owner cannot pass deletion.
- Actual native/public support on the civic cross street and Exchange grade.
- The explicit zero-additional-triangle budget across these changed displays.
- A translated independent source fixture whose original physics body/shape
  transforms and convex vertex bytes must remain identical. Unselected native
  sides, road top/bottom, retained display triangles and materials remain exact.

The fixture recreates the original overlapping geometry before applying the
repair; it does not trust the candidate report to establish the old areas.
Root owns serialized focused/full native execution and rendered receipts. No
engine run was started by this specialist while another agent held that slot.

## Focused native result

The first granted, bounded engine slot passed **17/0**, exit0, clean log,
**588 unchanged inputs**, **7.217s**. It includes all nine earlier coping/plinth
assertions and eight new C02 assertions. Exact command:

```sh
python3 docs/testing/horizon-background/observers/run_checked.py .local/pt24-c02-focused timeout 90s ./tools/run.sh --headless --fixed-fps 60 --script .local/pt24_c02_focused.gd
```

Receipt/log/source manifests are retained under `.local/pt24-c02-focused/` for
root integration's portable evidence archive. Source-manifest SHA-256:
`bf50063b1d0bde8c63cc6cdf892731119d6bdc55ed9ffa02bee77ac6c741425f`.
The receipt's parent HEAD is `258fec4`; its hashes bind the tested working code.

| Changed display | Triangles before→after | Actual removed area |
| --- | ---: | ---: |
| Civic floor | 12→16 | 12.000000m² |
| Exchange road | 12→16 | 9.600002m² |
| Seven park retaining boxes | 84→66 | 15.199680m² |
| Combined C02 slice | **108→98** | **36.799682m²** |

The ten-triangle net reduction fits the declared budget. Original native vertex
bytes, transforms, material references and unaffected display triangles pass
their exact preservation assertions. The earlier quay reduction remains
528→213; its report and assertions are preserved separately.

This focused headless run uses real native physics/mesh data. It is not the
required combined regression or a rendered temporal/human acceptance result.
Root owns the next source freeze and selected owner-camera captures.

## Temporal diagnosis and remaining acceptance

Existing rejected controls in the earlier civic evidence include split count,
bias, atlas/range/margins, reverse culling, pancake size and selective caster
suppression. They did not admit a reliable repair. This slice does not repeat
those broad experiments or ship diagnostic shadow disabling.

Captures2/3 and any remaining tile/masonry flicker stay open until actually
observed after these exact ownership corrections. If the civic symptom remains,
the next bounded control is **capture2 only**, the exact supplied camera and a
one-metre approach, ordinary material versus a private flat-albedo duplicate of
that asphalt receiver with identical roughness and unchanged shadows. That can
separate texture-dependent variation from residual shadow behavior without
altering global lighting. It is a proposed diagnostic, not executed evidence or
a default-play material change.

New source-bound images should use the existing temporal probe at witnesses
5/16/17/18. Still/native geometry evidence, analytic camera samples, moving Mac
shadow acceptance and target performance remain distinct. No FPS, temporal
stability or human visual acceptance is claimed from source intersections alone.
