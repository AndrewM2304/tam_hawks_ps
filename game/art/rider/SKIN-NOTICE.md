# Cropped MakeHuman skin texture

The head and hand albedo maps derive from `young_lightskinned_male_diffuse.png`
in the official MakeHuman system assets pack. The actual accompanying
`young_caucasian_male.mhmat` explicitly states that this asset was released as
CC0 in September 2020 and names the copyright holders at that release:
Data Collection AB, Joel Palmius and Jonas Hauquier (2020).

The complete CC0 terms and MakeHuman asset/code scope are already retained in
`docs/licences/third-party/makehuman-CC0.txt` and
`docs/licences/third-party/makehuman-LICENCE-SCOPE.txt`. This imports texture
asset data only, not MakeHuman program code or its shader implementation.

Inspected 6 November 2026. The official catalog independently labels this exact
skin CC0: <https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html>.
Source pack: <https://files2.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip>,
280,737,770 bytes, Last-Modified 14 April 2024 13:28:46 GMT. Only the two selected
files were retrieved using ordinary bounded HTTP ranges; the complete pack was
not imported. The material's internal display name is
`old_caucasian_male_detailed`, despite its young/male tags and young skin path;
the original metadata is preserved rather than reinterpreted.

| Selected file | SHA-256 |
| --- | --- |
| `skins/young_caucasian_male/young_lightskinned_male_diffuse.png` | `862a26e335e958b70534cb5f0d7c47ef30ab148a56c42b3e9da969cf76f12963` |
| `skins/young_caucasian_male/young_caucasian_male.mhmat` | `6eda60b07ff2afbde078a2535ef3913593d84e9de92b2eb76c30f396a181fe2e` |

The distributed derivatives retain only texture triangles used by the existing
cropped head and hands, dilate their edges for mip filtering, neutral-fill the
rest of each image and downsample the hands. The complete body atlas is kept
only in ignored development downloads. No third-party clothes, full body,
animation, hair image, brand or photograph from another source is imported.
`manifest.json` records every distributed map's hash. All roughness/normal,
cloth, suede and cropped-hair maps are original project-authored material studies.

Regenerate with `python3 tools/rider_asset_acquire.py`, then
`python3 tools/rider_asset_bake.py`. Neither tool runs during gameplay.
