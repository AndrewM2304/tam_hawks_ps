# Free visual asset review — 17 October 2026

**Scope:** M05-001/002 and M06-007 material/character cleanup. This bounded review imported two useful surface sets from an independent photographer's CC0 repository. No suitable clothed human replacement was found. No purchases, accounts, paid APIs or hosted jobs were used. Source permissions and visual suitability were checked separately; none of these textures establish a surveyed Glasgow frontage.

## Adopted surface assets

Source: [ZC's Spectacular Textures, by ZC / DaZCDude](https://github.com/DaZCDude/ZCs-Spectacular-Textures/tree/a866769b0ccb5e041f8855a52223d7d1a1166125), pinned commit **`a866769b0ccb5e041f8855a52223d7d1a1166125`**. The pinned [README](https://github.com/DaZCDude/ZCs-Spectacular-Textures/blob/a866769b0ccb5e041f8855a52223d7d1a1166125/README.md) says “All photos are taken and edited by me” and describes the seamless texture library. The actual root [LICENSE](https://github.com/DaZCDude/ZCs-Spectacular-Textures/blob/a866769b0ccb5e041f8855a52223d7d1a1166125/LICENSE) is the complete **CC0 1.0 Universal** text, not a GitHub label. It permits use, modification and redistribution, including raw project files; attribution is optional. Credit is retained here and in the manifest. The full unchanged licence is [zc-spectacular-textures-CC0.txt](../licences/third-party/zc-spectacular-textures-CC0.txt), SHA-256 `a2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499`.

| Material / source directory | Observed appearance and intended use | Original dimensions | Authored tile scale |
| --- | --- | --- | --- |
| `weathered_brick` / `textures/T_bricks01/` | Visually inspected orange/red weathered brick and light mortar; useful for Barras warehouse edges. Preserve the masonry direction. | 3024×3024 | 1.25×1.25 m |
| `mineral_concrete` / `textures/T_concrete01/` | Visually inspected neutral grey mineral grain; useful for concrete trim or restrained paving variation. This is not a sandstone photograph. | 3000×3000 | 1.5×1.5 m |

The author supplies no physical measurements. These metre scales are explicit art-authoring starting values, not source facts. Large repeated fields need route-level seam/repetition review. The photographs retain their source lighting; use subdued tint and normal strength rather than treating them as perfectly calibrated scans. Regional sandstone and slate should retain their separate treatment.

Four **unchanged** original JPEGs total **4,057,737 bytes**, below the 20 MB acquisition budget. Files live under `game/art/assets/zc_textures/T_bricks01/` and `T_concrete01/`. [manifest.json](../../game/art/assets/zc_textures/manifest.json) records exact pinned raw URLs, byte sizes, original dimensions, all SHA-256 values, source licence, import settings and scale assumptions. Imported files are:

| File | SHA-256 |
| --- | --- |
| `T_bricks01_albedo.jpg` | `6d7324f1f0335e3f303e8c6d1820e4b25a57b8ccf957d016c5eb9984b7aaf00d` |
| `T_bricks01_normal_opengl.jpg` | `592d367f8ca3bac35b7ae48312eea15ed61587374c751cdc3fb7e7bf61bcd033` |
| `T_concrete01_albedo.jpg` | `384f749991ffc3cb07ff2177e83a5c1e478df7bc1fb54a0e09390626d76084ac` |
| `T_concrete01_normal_opengl.jpg` | `4c5fbaf44b326887441a0c3551a2c62bd41ec5306ed36ff15d5048355f8ec10f` |

The source's normal maps are explicitly named **OpenGL**; preserve +Y rather than using its separate DirectX maps. These sets do **not** contain roughness maps. Use honest scalar roughness (initial suggestions 0.88 for brick and 0.94 for concrete), with restrained normal strengths 0.35/0.22. Ambient-occlusion and DirectX maps were not imported. The inspected `T_pebble_pavement01` is busy aggregate, `T_bricks02` is a pale smooth block pattern and `T_wall01/02` are plaster; they were left out to keep the first integration small and relevant.

### Import and verification

Each tracked `.jpg.import` uses Godot's standard texture importer with `process/size_limit=1024`, mipmaps, VRAM compression and both desktop S3TC and ETC2 formats. Normal maps explicitly enable normal compression and leave Y inversion false. Original source pixels are preserved; Godot creates the bounded runtime textures in ignored `.godot/`. Runtime resizing or a custom image-processing dependency is unnecessary.

An isolated temporary project with matching Godot **4.6.3.stable.official.7d41c59c4** imported the four files successfully. A `Texture2D`/`Image` probe loaded all four through `ResourceLoader`, verified **1024×1024**, verified ten mipmap levels and exited 0: **4 passed, 0 failed**. Both import logs were free of scanned engine/script warnings and errors. S3TC image formats were 17 (albedo) and 21 (normal), as produced by Godot. The generated `.import` settings were then copied unchanged into the matching repository paths; original image SHA-256 values were checked again. Temporary evidence is `/tmp/tam-hawks-visual-import/`; exact settings and source hashes survive in the tracked files/manifest.

The world/art owner integrates these shared textures in `city_art.gd`, keeping collisions unchanged. Actual scene captures and target-Mac performance remain separate gates. Include these `.import` configurations in future build input fingerprints: the 1K cap materially changes exported resources.

## Other surface sources inspected

- **ambientCG:** [official licence](https://docs.ambientcg.com/license/) explicitly covers downloadable assets and previews under CC0, permits raw video-game redistribution, and makes credit optional. Asset pages and its public metadata API were reachable. Candidate `Bricks083` is sandstone, source metadata dimensions 300×150 cm; `Bricks008` is sandstone/stone wall, 165×165 cm. `PavingStones036`, `Bricks059`, `Tiles144` and `RoofingTiles001/003` also have 1K map sets. No ambientCG image bytes were imported: `https://ambientcg.com/get?file=Bricks084_1K-JPG.zip` and the official `acg-media.struffelproductions.com` preview URLs returned HTTP 403. Do not claim their visual/tiling quality was inspected. Do not route around the denied host.
- **Poly Haven / cgbookcase:** `https://polyhaven.com/license` and `https://www.cgbookcase.com/textures/` returned HTTP 403. No licences or texture bytes were accepted from these sites during this pass.
- **3DTextures.me:** [official licence](https://3dtextures.me/about/) was reachable and explicitly allows CC0 raw redistribution. The slate query exposed [Slate Flooring 001](https://3dtextures.me/2017/11/26/slate-flooring-001/) and [Roof Tiles Stone 001](https://3dtextures.me/2020/11/11/roof-tiles-stone-001/); parallel sandstone/paving search queries returned HTTP 429, so browsing stopped rather than working around the rate limit. No assets imported. The independently inspected `sylvainpolletvillard/threejs-3d-materials` repository at `f4fe516936c6d4a3be91090e3fa0d6a955b44676` contains a full CC0 licence but its five actual texture sets are dirt, pebbles, sand, science-fiction wall and wood, not the needed sandstone/paving kit.
- **Other GitHub leads:** `assetfs/joaopaulo` only exposed one wood door; `0x00ASTRA/Textures` only brushed concrete; the community FPS environment kit mixed third-party origins. These were not adopted merely because search results said CC0.

The adopted ZC textures are independently discovered, author-owned GitHub sources. They are not proxy copies of a denied ambientCG or Poly Haven download.

## Rigged character candidates

The current skater visual helper controls original meshes and analytic limb endpoints. A skinned GLB needs a bone/rest-transform mapping and a deterministic pose adapter retaining feet on the board and hands on the grab target. Successful GLB parsing is not a drop-in skating animation solution.

| Inspected candidate | Actual permission and pinned source | Concrete finding / decision |
| --- | --- | --- |
| Godot official TPS player | [Commit `a82f15448e9b015440d3bbdf5e10801b260c4e9f`](https://github.com/godotengine/tps-demo/tree/a82f15448e9b015440d3bbdf5e10801b260c4e9f); `LICENSE.md` distinguishes **CC BY 3.0 assets** (Juan Linietsky and Fernando Miguel Calabró, 2018) from MIT code and separately credits GameTextures.com material origins. | Downloaded `player/model/player.glb`: 23,844,032 bytes, SHA-256 `16b783ec2e19245d034326d401796b9bd2635de75f4e38917854316abeee4f9c`. GLB has a 145-joint `Robot_Skeleton`, five meshes and 56 aiming/cannon/run/jump animations. Godot4.6.3 parsed/generated its scene successfully. Robot appearance and armed actions do not suit a believable casually clothed skater; rejected. |
| GDQuest Mannequiny 0.3.0 | [Commit `d48a4fdb49a3930f38cdbeb854cf5be3ae4b6b2a`](https://github.com/gdquest-demos/godot-3d-mannequin/tree/d48a4fdb49a3930f38cdbeb854cf5be3ae4b6b2a); art **CC BY 4.0**, code MIT. Preserve credit to GDQuest/contributors and character author Luciano Muñoz if ever used. | Downloaded `godot/assets/3d/mannequiny/mannequiny-0.3.0.glb`: 1,843,984 bytes, SHA-256 `8005cc2ab9221ad605be2d1cbb89eea894583e72bd5f50a5fbe40243a64f0493`. 45 joints, ten idle/run/jump/fight clips; Godot4.6.3 GLB parsing/scene generation passed. Official preview visually inspected: blue segmented featureless mannequin. It does not improve human/clothing appearance; rejected. Its original controller targets Godot3.2, independently of GLB compatibility. |
| Quaternius Universal Base Characters | [Product](https://quaternius.com/packs/universalbasecharacters.html) and [author's itch listing](https://quaternius.itch.io/universal-base-characters) advertise CC0. The current [general licence](https://quaternius.com/license.html) instead uses QAL v1.0 with restrictions on redistributing the assets themselves. | Free Standard lists **two underwear base models and five hairstyles**, while the larger edition is paid. No actual archive/licence acquired; product-specific permission must resolve the conflicting general terms before raw redistribution. Even a cleared base needs clothing and a pose adapter. Deferred; no purchase or account. |

Neither downloaded GLB or its controller/assets was copied into the game. The character research and parsing probes are isolated under `/tmp/tam-hawks-character-research/`; this document preserves the durable source/pin/hash/decision evidence. Continue the original connected clothing/pose improvements for this pass. Do not label a robot, mannequin or procedural joint model as a finished believable human.

## Concrete continuation

1. A05: integrate the two small shared texture sets, inspect nearby brick direction/scale, concrete tint, seams and normal intensity in the four district captures, then adjust material values without altering source images or collisions. Preserve sandstone identity.
2. A03/A05: when legitimate source access is available, acquire and visually inspect a measured sandstone and paving/slate set with albedo, OpenGL normal and roughness; record the exact asset licence and byte hashes before replacement. Keep the current texture count bounded.
3. A05: create or acquire one clearly licensed clothed human; map skeleton rest bases to the existing skating targets; verify idle/coast, push, crouch/ollie, flip, grab contact, grind/manual, specials and bail from fixed cameras. Reject clothing/joint/board clipping before broad replacement.
4. A09/owner: retain final owner visual acceptance, audible/physical-controller review and measured Apple Silicon 1080p performance as open evidence gates. An import test or screenshot does not close them.
