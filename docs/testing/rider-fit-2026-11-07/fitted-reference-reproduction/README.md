# Public-only fitted test reference reproduction

The standalone `build_fitted_rig_reference.py` resolves the private-path limitation
in the separately preserved epoch08 review bundle. It uses only Python's standard
library and the reviewed public asset files `fitted-manifest.json`,
`fitted_outfit.glb`, `fitted_landmarks.json` and `fitted_head.obj`. No Godot, private
download, NumPy, cache, network or runtime asset write is required.

After installing the selected assets, its default command is:

```sh
python3 tools/testing/build_fitted_rig_reference.py
```

The intended promotion path is `tools/testing/build_fitted_rig_reference.py`; the
default output is `tests/fitted-reference.json`, matching the executed adapter.
Both paths remain proposed until the director releases integration. `--assets`
and `--output` allow an isolated source build and test fixture.

The emitted reference is **byte-identical** to the actual native58/0 reference:
`eabce3798fd552a593a13683f2fb1b267c84088bf197f020d96634c0eaf367ae`. V11, V12 and
V13 selected public files all reproduce it; only unrelated assets differ.
Independent raw-GLB decoding, source-head polygon/UV incidence and semantic Head
correspondence derive all100 waist/46 Head edges without a rest-height selector.
Original11bone order is explicit; another bone profile needs its own admission.

Development verification passes12/0, including repeatability and changed asset
pins, honestly repinned missing/wrong/rest-shifted Head correspondence and a
changed bone profile. The development audit retains local evidence paths and is
not the proposed public tool interface. The original epoch08 packet remains
unchanged. These checks reproduce test data; they do not replace native contact,
art, moving Main, NPC clocks, hardware or human acceptance.
