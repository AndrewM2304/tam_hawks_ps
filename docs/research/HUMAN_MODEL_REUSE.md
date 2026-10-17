# Anatomical human reuse — 17 October 2026

**Decision:** use the verified CC0 MakeHuman `hm08` base mesh as a source for anatomical head and hand geometry. Retain the game's clothed torso/limbs and existing pose targets during this integration. This is a concrete improvement path over the previously rejected robot/mannequin assets; it does not establish final character or animation acceptance.

No purchases, paid service, plugin installation or account was needed. Blender **4.3.2** is already installed at `/usr/bin/blender`. Only read-only public GitHub requests were used for source/licence acquisition. No denied host was retried or bypassed.

## Exact source and asset permission

Repository: [makehumancommunity/makehuman](https://github.com/makehumancommunity/makehuman/tree/a8bc2d54ff0ac92e78ff71431b1023eda42bf482), pinned commit **`a8bc2d54ff0ac92e78ff71431b1023eda42bf482`**.

| Inspected original | Bytes | SHA-256 |
| --- | ---: | --- |
| [`makehuman/data/3dobjs/base.obj`](https://raw.githubusercontent.com/makehumancommunity/makehuman/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/3dobjs/base.obj) | 1,749,303 | `8e761e6624b8f54536409135d1636da63b32486a90d4897f84e121d144f6fb4c` |
| [`LICENSE.md`](https://raw.githubusercontent.com/makehumancommunity/makehuman/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.md) | 3,598 | `edd99571ca62698f78c943fd4fffb159a413c315fa0d4819d3cec5cadaf8b4f1` |
| [`LICENSE.ASSETS.md`](https://raw.githubusercontent.com/makehumancommunity/makehuman/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.ASSETS.md) | 6,962 | `f6089cba01cb570a24712b41ab8a586ccd3cc5ef53dc266ca50b95c288956d2c` |

The **actual OBJ header**, independently of a GitHub label, states: “This asset was explicitly released as CC0 in september 2020.” It records the holders at release as Data Collection AB, Joel Palmius and Jonas Hauquier (2020). The complete CC0 1.0 text was read in `LICENSE.ASSETS.md`.

The repository's `LICENSE.md` explicitly separates the **AGPL program code** from **CC0 graphical assets**. Its asset definition includes “The base mesh and proxies”, targets/modifiers, textures, clothes and poses/expressions. Its output section specifically permits exported OBJ/FBX/DAE data, scripted graphical output and renders without claiming rights over the output. It also warns that separately downloaded community assets may have different licences. This review covers this bundled, pinned base mesh only; it is not blanket clearance for every community skin, hairstyle or outfit.

CC0 permits modifying, cropping, rigging, redistributing and using this geometry in a commercial game. No MakeHuman program logic needs to be copied into this repository. Preserve the complete asset licence, scope statement, source credit and hashes with any derivative; do not label MakeHuman's program code CC0 or copy its AGPL implementation as though it were asset data. The full licence and scope texts are retained in `docs/licences/third-party/makehuman-CC0.txt` and `makehuman-LICENCE-SCOPE.txt`; ART-003 records the derivative in the combined register.

## Inspected geometry and practical extraction

The text OBJ contains **19,158 vertices**, **21,334 UV coordinates** and **139 face groups**. The actual `body` group has **13,378 faces** using **13,380 vertices**. The rest includes clothing fitting surfaces, joint-reference cubes and other helpers; they are not all intended render geometry.

The source is Y-up. Actual body bounds in source units are X `[-4.9627, 4.9627]`, Y `[-8.1676, 8.4913]`, Z `[-1.0154, 3.2147]`. The face points toward positive Z. Scaling by 0.1 gives approximately **1.666 m** total body height; this is a geometric inference from the inspected bounds, not an asserted unit declaration in the OBJ.

Useful joint-helper centers, derived from the eight vertices of each named group:

| Marker | Source-space center |
| --- | --- |
| `joint-neck` | `(0, 5.89025, 0.06805)` |
| `joint-head` | `(0, 6.97495, 0.16075)` |
| `joint-jaw` | `(0, 6.19075, 1.42485)` |
| `joint-l-hand` | `(4.31185, 2.4518, 1.75655)` |
| `joint-l-elbow` | `(3.1296, 3.4929, 0.131)` |
| `joint-r-hand` | `(-4.31185, 2.4518, 1.75655)` |
| `joint-r-elbow` | `(-3.1296, 3.4929, 0.131)` |

Head/ears/nose/lips and the hands are part of the continuous `body` surface, rather than separately named mesh groups. A body-only head selection with all face vertices at source Y≥5.9 is a useful initial neck cut. Hands should be isolated around the wrist using the forearm direction and side constraint, preserving all five fingers; a simple world-Y cut is unsuitable because the relaxed hand points forward/down. Exclude all `helper-*` and `joint-*` faces from derivatives. The joint data is useful for fitting, but the cube meshes must not render.

The source file contains unclothed anatomy and fitting helpers. Keep the complete source in temporary research/download storage; only approved cropped head/hand geometry belongs in the runtime assets for this pass. The visible rider retains opaque skate clothing. A crop opening belongs inside the jacket collar/cuff, with no visible gap during motion. Eyes, hair and teeth need their own deliberate geometry/material treatment; do not blindly turn every helper into a finished asset.

## Integration contract

The character owner preserves `build(board, rider, shirt)`, `animate(delta, state)` and `reset()`, shirt-colour changes, the existing board transform and physics inputs. Existing analytic hip/knee/ankle and shoulder/elbow/wrist targets drive the skinned garments. The first adaptation can attach anatomical head/hands to these targets; adopting a whole new animation/controller package is unnecessary.

Coordinated derivative path: `game/art/assets/makehuman_hm08/`. The reuse researcher owns the original offline generator and four cropped derivative meshes; the character owner owns their native adapter, shading and clothing integration. The manifest records source pins, selected-vertex-set hashes, unit conversion, transforms, reshaping and output hashes so the parts can be regenerated. Match adult proportions rather than enlarging the head to preserve the earlier cartoon silhouette. Inspect feet/board, cuffs/wrists, neck/collar, grabs and hand silhouettes at normal chase distance and in fixed close views.

The full source and target files are cached in ignored `.local/downloads/makehuman_hm08/`; the generator retrieves missing files from the pinned public URLs and refuses any hash mismatch. Temporary inspection files live under `/tmp/tam-hawks-human-research/` and are not required to regenerate the meshes. No original full-body file or MakeHuman program code is a tracked game asset.

## MPFB alternative, inspected separately

The [MPFB2 repository](https://github.com/makehumancommunity/mpfb2/tree/3af0cd5a2ffba072e93a34e5f6f494fdc4813ddf) was inspected at **`3af0cd5a2ffba072e93a34e5f6f494fdc4813ddf`**. Its `README.md` requires Blender≥4.2, which the installed Blender4.3.2 meets. Its actual `LICENSE.md` separates **GPLv3 addon code** from **CC0 bundled mesh/rig/pose/texture/JSON asset data**, and its `LICENSE.ASSETS.md` is byte-identical to the MakeHuman asset licence above. MPFB scope-file SHA-256: `5cefb60680cb9efd4550a2e65d719021cfbec9dad3658481d11d48ae863ce04d` (3,188 bytes).

MPFB can become a later authoring option for broader body proportions, rigging and individually cleared clothes. It was not installed or executed in this bounded review, and no claim is made that its latest addon works in this project. The direct, licensed OBJ supplies the needed anatomy without a new tool dependency.

## Remaining acceptance

The character owner must validate the extracted geometry and native Godot import, then capture frontal/profile/three-quarter anatomy and skating poses. Check neck/wrist seams, natural hand size, contact during grabs, body/head proportions, normal directions and shader response. Full-body clothing, convincing skin/hair, richer finger articulation and human visual acceptance remain distinct work. A compatible licence and an anatomically better base mesh are necessary evidence, not a finished-art claim.

## Delivered adult derivatives

Run `python3 game/art/assets/makehuman_hm08/generate.py` from the repository to reproduce the four meshes. This is original Python standard-library tooling, not copied MakeHuman code. The base OBJ and three target files are data-only inputs with the actual CC0 header. Each target row is a zero-based vertex index and displacement; the generator adds one third of each bundled `caucasian-male-young`, `asian-male-young` and `african-male-young` displacement to form a documented adult male blend. These are the upstream filenames, not a claim to represent any specific person or demographic. The inspected upstream age definitions place `young` at **25 years**, rather than childhood. The average-muscle/average-weight target has no displacement rows and is not needed.

The manifest records exact target URLs, SHA-256 digests and the generator SHA-256. The generator makes no body rig, clothing, skin-texture or animation imports. It applies morphs before transforms, uses the original base topology for crop selection and recomputes smooth area-weighted normals across the body before cropping. UV coordinates are retained. Head Z is reflected toward Godot -Z with face winding reversed; hand transforms are proper orthonormal frames with +Y toward the wrist and -Y toward the fingers.

| Runtime mesh | Vertices | Triangles | Adaptation |
| --- | ---: | ---: | --- |
| `head.obj` | 4,278 | 8,508 | Head/ears/nose/lips and short neck; no eye/helper meshes |
| `left_hand.obj` | 1,669 | 3,316 | Five fingers and a roughly 3 cm wrist overlap |
| `right_hand.obj` | 1,669 | 3,316 | Mirrored anatomical hand, same wrist contract |
| `hair.obj` | 415 | 748 | Upper/rear scalp faces clipped to a continuous hairline and offset 1.5 mm outward along smooth normals |

The adult head bounds are approximately 0.1713 m wide × 0.2797 m tall (including the fitted neck) × 0.2185 m deep. Head-local eye centres are `(±0.0294083, 0.0412700, -0.0787933)` m; the adapter receives an authored 0.0138 m eyeball-radius starting point. These are fitting coordinates rather than proof of a finished eye shader. The hands extend approximately 0.1993 m below the wrist, with a short positive-Y cuff overlap; palm centre is roughly 0.05–0.06 m below the wrist. The character integrator must validate the actual roll/contact in skating poses.

The inspected default MakeHuman skin material contains no diffuse texture reference. No extra texture was imported; muted original regional skin, lip, eyebrow and hair colouring belongs to the native character adapter. The scalp follows actual human geometry, avoiding a spherical cap silhouette.

Regeneration verifies all input digests and rewrites a deterministic `manifest.json` with all output digests and the exact retained licence hashes. Native Godot import and visual/contact validation are coordinated with the character and quality owners; these cropped meshes alone do not close the realistic-art acceptance gate.

Offline verification: the generator compiles and reproduces all four OBJ and manifest hashes byte-for-byte. Every exported face has finite, in-range position/UV/normal indices; all triangulated faces have nonzero area and winding aligned with their smooth normals. Two tiny lip quads became concave after the adult morph blend: the generator now explicitly selects the valid diagonal and emits triangles to prevent importer-dependent inverted slivers. A bounded Blender 4.3.2 CPU clay render of only the cropped parts was inspected for anatomy, five fingers and hairline; no full-body image was rendered. Native game captures are the integration acceptance evidence, not this isolated clay inspection.

The final seam correction is part of this asset handoff: 46 vertices on the low open neck boundary are fitted to a flat ellipse at head-local Y=-0.13 m, centred at X/Z `(0,0.036)` with radii `(0.043,0.039)` m. Two adjacent topology rings are blended toward that fit (130 adjusted vertices total), and head normals are recomputed. Facial landmarks, head origin, eye markers, hands and scalp are unchanged. The ring belongs fully inside the opaque collar; it is deliberately an open garment overlap rather than a visible neck cap. Final regenerated files again passed finite/index/area/winding and byte-for-byte determinism checks.

Chase-distance correction: `hair.obj.import` disables generated mesh LODs for the 748-triangle scalp. The native adapter copies the head to a pigmented ArrayMesh without generated LODs; allowing the scalp alone to simplify caused it to collapse inside the full-detail head at normal chase distance. Both now retain matching surface detail. The scalp offset remains the original **1.5 mm**; no physics or anatomical landmark changes are needed.
