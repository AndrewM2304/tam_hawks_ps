# Cropped MakeHuman skin texture

The head and hand albedo maps derive from `young_lightskinned_male_diffuse.png`
in the official MakeHuman system assets pack. The actual accompanying
`young_caucasian_male.mhmat` explicitly states that this asset was released as
CC0 in September 2020 and names the copyright holders at that release:
Data Collection AB, Joel Palmius and Jonas Hauquier (2020).

The complete CC0 terms and MakeHuman asset/code scope are already retained in
`docs/licences/third-party/makehuman-CC0.txt` and
`docs/licences/third-party/makehuman-LICENCE-SCOPE.txt`. This skin import uses texture asset data only. Additional CC0 wardrobe, hair,
eye, brow and shoe derivatives have their own exact source records in
`FITTED-NOTICE.md`; no MakeHuman program or shader code is imported.

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

The distributed skin derivatives retain only the authenticated head, exposed
neck/chest and hand source triangles. They dilate island edges for mip filtering
and neutral-fill unused pixels. The full source body atlas stays in ignored
development downloads. The natural fitted-head derivative retains the original
source UVs; the original anatomical source mesh remains intact. Opaque source
eyes occupy a verified unused region of the head RGB map and have separate
source-selection metadata.

Each hand preserves its original native vertex, UV, normal and triangle streams.
A positive uniform material UV scale and offset, with repeat, packs the actual
palm and nail islands into a 512 map. Albedo samples the pinned 2048 source only
inside those authenticated islands; `hand-atlas-layout.json` records exact source
IDs, bounds, repeat tiles and padding. Texture size alone is not a detail or
performance acceptance claim.

`manifest.json` records every distributed map hash and the complete original
fitting/baking generator chain. `fitted-manifest.json` additionally pins selected
geometry and provenance outputs. Original analytical skin roughness/normal maps,
source fitting, flat laces and NPC apron are project work; original source cloth,
hair, brows, eye and trainer data are documented in `FITTED-NOTICE.md`. No full
body, franchise asset, brand, animation or external program code is distributed.

Regenerate with `python3 tools/rider_asset_acquire.py --fitted --body`, then
`python3 tools/rider_asset_bake.py --garment-fit game/art/rider/fitted-garment-fit.json`.
Neither tool runs during gameplay. Native contact, Main appearance, motion,
target hardware and final human art approval are separate evidence gates.
