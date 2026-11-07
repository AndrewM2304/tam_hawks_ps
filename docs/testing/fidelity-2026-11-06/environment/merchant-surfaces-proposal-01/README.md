# Merchant surfaces handoff — source prerequisites sealed

Actual main runtime/import/cache/licence files are untouched. This is a private proposal. No new-world material view, chosen lighting profile, moving-quality or M5 acceptance is claimed. Reactivate the environment specialist for the coherent20-image run when ARv5's shared03a pilot is frozen.

## Canonical source and candidate

Private project: `.local/merchant-environment/project`.
World: canonical03a `cd27467fe2c471ba85ab7e0dae776e1f98142270b49414aacc02b070774d7d9c`.
Runtime layout: `b6339c4722ed6a95e9223b4899d5c14a286a9d158ef5ff4e33e4cdaf74b60ecd`.
Surface helper: `game/levels/art/merchant_surfaces.gd`, SHA256 `ea1a23f629564771f6ffabeb8f5d0053d69e18699f52cc701531c90b3c6c1be7`.
Data-driven masks: `game/levels/art/merchant_surface_zones.json`.
The cloned old ARv3/Book67 files are unused by the world-only guard and are NOT approved integration. Replace the architectural helper with the frozen ARv5 pilot on the same03a, without changing the canonical world/runtime pair.

## Exact integration calls

After all selected Merchant geometry and ARv5 are built, before play:

```gdscript
const MerchantSurfaces = preload("res://game/levels/art/merchant_surfaces.gd")
var state: Dictionary = MerchantSurfaces.apply(world, world._materials, world._layout)
var report: Dictionary = state.report
```

`apply` returns diagnostic restoration state plus its scalar report. It changes only the ground visual mesh's material surfaces and exact targeted material overrides. It adds no node/collider/guide. For ordinary runtime, retain only `report` and release the rest of `state`, so diagnostic original meshes/mappings do not stay resident. For matched A/B/A diagnostics only, `MerchantSurfaces.restore(state)` restores the original mesh/material objects.

The masks use runtime `street_corridors` [x,y,z] points/widths, court X−24..16/Z6..36 and depot X24..80/Z−22..14. Native positions remain untouched; road/shoulder material edges follow the original1m triangle lattice and need visual review. Civic routes do not paint traffic asphalt through the pedestrian Market court. Rails/brick are excluded from broad patch-prefix rebinding by exact original paving/path material checks.

Lighting is a control, not a selected winner: compare only existing sun `light_energy=0.86` and environment `ambient_light_energy=0.36` against1.3/.5 before tint compensation. No new light, name/rotation/colour/shadow change has been applied in the proposed observer. LD owns any eventual `_build_light` adoption.

## Closed source/resource prerequisites

- `native-06-shared03a`:24/0,13761813:43:54.950–13:43:58.271UTC, source stable. All59,920 ground triangles/winding, referenced packed positions/normals/tangents/UV, native collision/property/guide/support-RID data and restoration match exactly. Four opaque ground surfaces; native buffer payload decreases9,212B. Old factory normal inputs are derived from unchanged float32 height samples and final native bytes are verified before assignment; no double-quantisation tolerance waiver.
- Six photographic maps:4DXT1+2RGTC_RG/BC5;2K albedo,1K normal+ARM;11/10mips. Concrete3m (683/341texels per metre); granite2.3m (890/445).
- `allocation-01`: separate fresh GL process,9,786,816B extra native texture memory, same8draws/96primitives. Cumulative29,273,123B/27.917026MiB is below32MiB, with4,281,309B headroom. This is software-Linux allocation, not M5 performance.
- Official CC0 pages/API/licence and six exact raw source hashes/providerMD5s are retained. Verify-only passes with network/Path-write traps. No source image edits or procedural replacement textures.
- Earlier observer/parser/packed-normal attempts remain rejected. Native04 is positive old02-only; native05's untyped shared03 parser refusal remains rejected. None is relabelled as03a visual acceptance.

## Ready observation and pending work

`project/graphics.gd` and `run_graphics.py`: five views (High Street, Market, depot, Foundry, close concrete) × original / two-field balance / balance+surfaces / restored =20 native1280×800 images;240s bound. Reuses existing natural-frame readback, nativeRGBA, numeric projection/basis, process/physics brackets, two independently projected world markers and Canvas proof. It also exports exact native ground vertex/normal/tangent/UV/index buffers plus original vertex/triangle mappings for independent reconstruction. The observer/wrapper are prepared; the20-image run has NOT executed.

Before running: bind frozen ARv5 module/layout on canonical03a; confirm root's GL lease and no RA overlap; perform a bounded parser. Then run `python3 .local/merchant-environment/run_graphics.py`. Inspect all five matched material/lighting views, source repetition, diagonal material edges, concrete curve seams and roll/landing readability; fix visible failures before admission. Independent QA must review actual pixels/native arrays/counters. No actual installation until root's guarded grant.

Payload17 files: surface helper, maskJSON, new fetcher, manifest, six original JPEGs +six tracked imports, proposed licence appendix. The existing `fetch_environment_materials.py` remains a dependency and is unchanged. On promotion, extend package provenance/texture validation for all six maps and register the licence appendix; do not silently ship an unregistered dynamic-load manifest.
