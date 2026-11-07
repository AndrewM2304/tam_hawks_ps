# Fitted CC0 rider assets

These derivatives use asset data from the official MakeHuman system-assets CC0
pack, inspected on 7 November 2026. The selected original OBJ, MHCLO and MHMAT
headers explicitly dedicate the assets to CC0 in September 2020 and name Data
Collection AB, Joel Palmius and Jonas Hauquier as the copyright holders at that
release. The original headers are preserved in `fitted-licence-headers.json`.

- Catalogue: <https://static.makehumancommunity.org/assets/assetpacks/makehuman_system_assets.html>
- Pack: <https://files2.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip>
- Archive size: 280,737,770 bytes. Selected members were retrieved by bounded HTTP
  ranges and checked against exact member sizes, CRCs and SHA-256 pins. The full
  archive was not downloaded or assigned a claimed whole-archive digest.
- Exact21 selected pack members: `fitted-source-pins.json`. They comprise short02
  hair, male_casualsuit01 clothing, shoes02 trainers, eyebrow001 and high-poly eyes
  with their selected source textures and fitting/material data.
- Two additional skin members and their exact hashes: `SKIN-NOTICE.md`.
- Original BODY and three adult morph targets: existing
  `game/art/assets/makehuman_hm08/manifest.json`, revision
  `a8bc2d54ff0ac92e78ff71431b1023eda42bf482`. Equal one-third target weights reproduce
  the same adult identity used by the existing anatomical hands/head.

The complete CC0 terms and asset/code scope are retained in
`docs/licences/third-party/makehuman-CC0.txt` and
`docs/licences/third-party/makehuman-LICENCE-SCOPE.txt`. No MakeHuman program code,
shader, animation, rig or skin weights are copied. The fitter, projection math,
native11-bone binding, wardrobe adaptations, flat laces and NPC apron are original
project work. Source MHCLO files supply asset-data correspondences only.

The selected export retains authentic source clothing folds, eye/eyebrow/hair
surfaces and trainer construction. It records source vertex/triangle identities,
actual native weights, original polygon occlusion policy and barycentric fitting
correspondences in the accompanying metadata. The exposed neck/chest continues
the real retained46-edge head boundary; it does not export the full body. The new
head derivative restores authentic lower-neck geometry previously flattened under
the old opaque collar. Exact fully transparent corneal shell components and
authenticated trainer sock UV islands are omitted; visible iris/sclera and shoe
vamp faces remain. No franchise asset or branding is imported.

`fitted-garment-fit.json` pins an original measured33-vertex local shirt fit,
maximum6.532mm against an8mm budget, protecting all100 shared waist edges. It keeps
the unresolved internal folded-lapel diagnostics explicit. NPC vest overlays retain
the original shirt vertices and weights with an outward garment offset and original
UV edge coverage. `accessory-fit.json` and `lace-fit.json` document the original
accessory construction. Such provenance is not final visual/contact acceptance.

Reproduce with `python3 tools/rider_asset_acquire.py --fitted --body`, then
`python3 tools/rider_asset_bake.py --garment-fit game/art/rider/fitted-garment-fit.json`.
The latter verifies all selected pins, source headers and original BODY pins before
building to ignored staging. Review its `fitted-manifest.json` and promote selected
derivatives atomically under one coordinated editor-import lease. Full body/skin
atlases, fitting cages, debug arrays and unselected assets remain ignored source
inputs. No fitter runs during gameplay. Existing native skateboard assets and
their notices remain authoritative and unchanged.

The fitted pipeline and its native/Main admission are still a candidate at the
time of this private notice. Source reproduction and selected stills do not certify
motion, target hardware performance, final human art approval or AAA fidelity.
