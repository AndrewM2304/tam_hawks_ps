# Column UV basis correction — prepared V2

This is the preferred **pending-native** candidate for Main admission. The
original V1 native component and installer/rehearsal packets remain unchanged.
V2 changes only the column tangent handedness: shaft and top cap become −1;
bottom remains +1. Geometry, normals, UVs, index data, dimensions, resources and
all other candidate modules retain their original source. The column shader may
mask this under triplanar stone; the authored mesh basis still must be correct.

Godot 4.6's GLES and RD shaders reconstruct the binormal as
`normalize(cross(normal,tangent)*binormal_sign)`. The shaft's U increases around
+Z and V increases upwards, requiring −1; the cap U/V axes are +X/+Z, requiring
−1 for the top and +1 for the bottom. Official source references are in the
retained analytic receipt. No Godot source or third-party asset is bundled.

The exact offline derivative probe verifies the source delta is only the three
tangent-W emissions. Of 502 vertex samples, V1 has 476 opposed V directions;
V2 has zero, with zero normal/tangent orthogonality failures. This is analytic
author evidence, not native upload/shading or visual acceptance. **No native
engine or production mutation was performed for V2.** Native Main must establish
the exact current source, geometry costs and actual uploaded tangent values.

Restore the unchanged original installer from `../integration-ready` to
`.local/architectural-fidelity/controlled_install.py`. Restore this packet's V2
adapter, manifest and probe to that same ignored directory. The original four
prototype modules remain in `prototype/` as preserved under
`../native-author-component`. Restore an exact copy of those four to
`prototype-v2/`, then use this packet's `gallery_column.gd.txt` for its column.
The new `candidate-v2.json` hashes all four. **Do not execute `.txt` files in the
deep documentation directory**; their original paths determine repository ROOT.

After root releases production ownership, use the new adapter for inspect,
prepare and installation:

```sh
python3 .local/architectural-fidelity/controlled_install_v2.py inspect
python3 .local/architectural-fidelity/controlled_install_v2.py prepare
# Baseline actual Main first, under root's separate engine/render leases.
python3 .local/architectural-fidelity/controlled_install_v2.py install --production
```

The adapter reuses the exact independently reviewed guarded V1 operations;
it changes candidate/hash lookup and explicitly labels V2 as pending native
measurement. Author private adapter rehearsal passes 4/0: explicit identity,
all four installed hashes, exact revert and actual production unchanged. V1's
13/0 author and 9/0 independent negative controls remain their original scope;
they are not relabelled as an independent V2 review.

This packet's updated `main_probe.gd.txt` supersedes the prepared observer in
`integration-ready`; retain the latter historically. The new observer additionally
checks the actual native column's 502 vertices/tangent W values, all eight runtime
instances/CPU-authored records, and the real west upper wall's triangle-aperture
witness in complete Main. It is still **unparsed and unexecuted**. The original
prepared Python wrapper is unchanged. The [admission sheet](../../../ARCHITECTURAL-INTEGRATION-ADMISSION.md)
owns all remaining native, visual, unchanged-clearance, regression, cost, temporal
and M5 gates. `preservation.json` binds nine exact retained engineering files.
