# C02 source reconciliation — 27 October 2026

Reviewed on `main` at `c82ffac`. This is a bounded source and original-capture
review, not a new engine, moving-render or target-Mac acceptance result. No C02
production source or regression test was changed by this review.

## Result

The previously proved duplicate surfaces in PT24-09/10/12 are already repaired.
No additional reproducible source defect was found in these named cases. Keep
their temporal acceptance open; do not implement another generic mesh rewrite,
change global shadow bias or remove shadows to make these records look closed.

| Owner report | Current deterministic repair and retained evidence | Still required |
| --- | --- | --- |
| PT24-09, captures 16/17: tiled park walls | `pt24_render_repairs.gd::_additional_repairs` removes the five covered north-wall caps and the two arrival walls' covered caps/west faces. Their exposed vertical fronts remain. `sunken_bowl_feature.gd::_build_access` independently omits duplicate cheek rim/street-end caps while retaining the port side faces. `pt24_render_repairs_tests.gd::_c02_world` checks actual replacement ownership at fixed samples; the reported park removal is 18 triangles / 15.199680m². | Matched moving approach and along-wall views of **both** original reports, with shadows retained. Source ownership does not prove temporal stability. |
| PT24-10, capture 18: Exchange masonry bottom | The exact 9.600002m² internal `CentralSouthStreet` wall wedge at Z15 belongs to the existing tenement. Its exposed below-ground foundation remains. Fixed tests check both the actual tenement owner and retained foundation, plus native support. | Moving close/chase views beside the original edge; verify that any remaining variation comes from lighting/depth rather than assume another missing wall. |
| PT24-12, capture 20: station grass/plinth edge | `_station_plinths` rebuilds the existing piece transforms with exact segment lengths; the former extra 4cm made adjacent top/side skins overlap. The original instance count, material and native panel remain. The independent fixed-endpoint fixture checks all 24 pieces on its declared 36m span for joins without gap/overlap. | Moving parallel/crossing views at the original station wall/grass join. Exact flat plinth joins do not establish every possible grass or shadow interaction. |

The earlier source-bound [C02 admission](../pt24-next-2026-10-25/README.md)
records 17/0 focused assertions and the combined source receipt for its own
revision. The current [body-repair admission](../pt24-body-attachment-2026-10-25/README.md)
records the later 5,062/0 combined suite. Neither is relabelled as a new temporal
or hardware result here.

## Rejected extra-change hypothesis

`pt24_render_repairs.gd::_hard_faces` rebuilds positions and generated hard
normals, without copying UV/tangent streams. It initially looked like a texture
loss risk, but the current consumers do not substantiate that diagnosis:

- Civic/Exchange terrain source in `core_terrain.gd::add_patch` does not author
  UVs or tangents. It already generates hard normals with
  `set_smooth_group(-1)` and `generate_normals()`.
- Current paving, path and masonry materials use world triplanar mapping in
  `city_art.gd::_textured`; they do not consume the discarded box UV layout.
  The park's `apply_finishes` selects these existing shared materials.
- Retained civic/Exchange triangles preserve their vertex order; clipped
  triangles explicitly compare their cross-product direction with the original
  and swap corners when necessary. `_remove_box_planes` retains the original
  corner order. Repeating the same hard-normal generation therefore does not
  introduce a different face normal on those unchanged triangles.
- `BoxMesh` retaining faces have outward hard normals; preserving their winding
  and regenerating hard normals is consistent with the same face geometry.

This rules out the proposed active **UV-loss** explanation for these current
surfaces. It is not a general guarantee for future nontriplanar meshes, manually
weighted normals, extra vertex streams or unrelated users. Adding a generic
attribute-preservation framework here would not resolve a demonstrated current
ticket, so it was not implemented.

## Next witness, when available

Reuse original capture positions/headings from the
[owner index](../debug-session-2026-10-24/INDEX.md). Freeze source/settings and run
one short deterministic approach/parallel camera path per reported face. Compare
matched receiver/caster controls, including a diagnostic shadow-off control only
to distinguish the source of temporal variation; keep ordinary gameplay shadows
on. Retain the source/settings manifest and frame sequence. Actual Mac movement
remains a separate acceptance result. No further exploratory game session is
needed to repeat the already-established overlap measurements.
