# Original horizon source

`python3 art_source/horizon/generate.py` writes the original panorama and source/asset hash manifest to `game/art/assets/horizon/`. Installed Pillow/numpy are generation tools, not runtime dependencies. The generator is deterministic and has no external data, photographs, downloads, API calls or third-party content. Project owner controls the original outputs under the same scope as ART-001; no new public licence grant is implied.

The horizon is an atmospheric Glasgow-inspired composite: hills, woodland, tenement/slate/chimney rhythm, sparse modern/civic/industrial accents. It is not a surveyed panorama, exact shop/location claim or copied mural. The entire lower hemisphere is painted, with periodic azimuth and continuous poles. The existing high guard reuses the already registered resident CC0 brick albedo, without its normal map or another texture import. The first generated masonry tile was rejected as too bright/repetitive and is not shipped.

Runtime uses native static sky and existing wall geometry; no generator work occurs during play. Intended import is RGB DXT1 with mipmaps,4096×2048 panorama≤6MiB compressed image data. Actual import bytes, native captures, performance admission and rejection history belong in `docs/testing/horizon-background/`; generated appearance alone is not final art acceptance.
