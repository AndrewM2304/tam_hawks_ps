# Glasgow sandstone shopfront bay — unintegrated proof

This is an original **6.5 m × 16 m** shallow facade prototype for an existing Glasgow-inspired retail frontage. It is not installed in the game, a model of a verified current shop, or approved final art. `.gdignore` prevents the live project from importing this directory. There are no collision meshes, grind lines, runtime scripts, lights or cameras.

| Explicit replacement | Actual exported triangles | Opaque surfaces | File bytes |
|---|---:|---:|---:|
| [Near GLB](generated/glasgow_bay_near.glb) | 18,392 | 4 | 4,152,092 |
| [Mid GLB](generated/glasgow_bay_mid.glb) | 3,544 | 4 | 3,300,944 |
| [Far GLB](generated/glasgow_bay_far.glb) | 648 | 4 | 3,051,228 |

These are alternatives, not three objects to draw together. Each GLB contains one merged mesh with four material primitives: sandstone, forest-green painted joinery, opaque glazing and aged dark metal. Image data is embedded, so each file opens independently. This intentionally duplicates the same texture data across the three proof files; a later measured production import should share those textures/materials instead of keeping three resident copies.

## Design and placement contract

The existing `game/levels/art/facade_kit.gd` supplies the reference rhythm: 3.25 m retail window bays, roughly 6 m shop bays, 3.2 m upper-storey spacing and a fascia centred at 3.25 m. Existing Exchange retail bodies are 16–18 m tall. This proof contains two 3.25 m upper bays, with windows centred at 5.25, 8.45, 11.65 and a shorter attic row at 14.65 m. The fourth, short row is an original proposed replacement detail, not a claim that the existing procedural facade already has it. This is an architectural composite; the fascia intentionally has no invented real business name or signage.

glTF coordinates are **metres, +Y up, +Z facing the street**. The origin is the ground centre of the nominal front wall plane. All transforms are applied. Exact common bounds are X −3.25…3.25 m, Y 0…16 m, Z −0.50…0.36 m (6.5 × 16 × 0.86 m). A future placement would align the Z=0 wall plane with an existing building's local front face, normally Z=6; this is a placement convention, not a completed integration. The 0.50 m backing sits inside the existing building mass; decorative projection remains shallower than the current shopfront/awning envelope. Ground threshold top is 0.20 m and must be adjusted to the chosen existing supported landing during integration, never by changing its collider to match this proof.

Near geometry concentrates detail in real window reveals, stacked lintels and sills, underside drip profiles, alternating edge ashlar, small sash bevels, panelled stallrisers, a recessed door with handle mounts, and a stepped cornice with dentils. Windows sit behind the wall plane rather than on a continuous front slab. Foreground stone radii are approximately 12–25 mm; small joinery edges use smaller radii. Mid retains the openings and main sill/cornice/shop outlines while simplifying profiles. Far retains the overall body, recessed opaque windows, sill outline, fascia, doorway and threshold, and removes fine frames, quoin relief and ornament. Six isolated front/detail renders are now retained; actual chase-distance LOD transitions remain to be inspected.

## Original materials and reproducibility

All geometry, image pixels and Python in this folder were authored for this project. No texture, photograph, model, font, business logo or upstream code was downloaded or copied into it. Installed Blender 4.3.2 and its bundled NumPy produce the geometry and maps offline; Python's standard library audits the exported files. See [PROVENANCE](PROVENANCE.md) and [licence notice](LICENSE-NOTICE.md).

The four original 1024² PNGs are sandstone base colour, a subtle OpenGL +Y normal map, packed ORM (R=1, G=roughness, B=0) and an opaque abstract glazing card. Stone uses 2 m UV repeats, or 512 texels/m; the mineral map deliberately does not draw fake masonry joints. UVs are deterministic face projections on the finished bevel geometry. Stone metallic is a constant zero, avoiding Blender 4.3's duplicate-image-socket sampler warning while preserving the packed roughness texture. Exported samplers use linear filtering, linear mipmap filtering and repeat wrap. Paint/metal use plain Principled PBR factors. There are no unsupported procedural shader nodes in the GLBs.

From the repository root, with the installed Blender:

```sh
blender -b --factory-startup -t 2 --python art_source/glasgow_bay/generator.py
python3 art_source/glasgow_bay/audit.py
```

The generator replaces only this folder's `generated/`, `textures/` and `generation.json` outputs. It does not render or save a `.blend`; the deterministic Python source is the editable source of truth. `generation.log` retains the actual successful background export, including non-blocking installed-tool diagnostics about a read-only extension cache and unavailable optional Draco library. The GLBs do not use Draco compression. [audit.json](audit.json) records SHA-256 file and decoded per-surface data hashes, actual triangle/vertex counts, measured bounds, image data hashes and numeric validation. [reproducibility.json](reproducibility.json) compares two separate factory-startup exports of the final generator.

## Verified, and still open

The structural audit reads the actual GLB JSON/BIN data, checks the requested 12–20K / 2–5K / 300–800 triangle budgets, one merged mesh/four opaque single-sided surfaces, applied transforms, identical bounds, finite data, unit orthogonal normals/tangents, valid indices, nondegenerate geometry/UV triangles, and embedded 1024² PNGs. It fails nonzero on a defect. It does not substitute Blender source counts for final exported counts.

**Structural export and isolated Godot preview are verified separately.** The root agent imported disposable copies in Godot 4.6.3 Compatibility and captured six front/detail images across the three LODs, confirming one mesh/four surfaces and matching source GLB hashes. [Preview evidence](../../docs/testing/facade-bay-proof/README.md) retains exact fixture, lighting limits and actual images. Reproduce with `./art_source/glasgow_bay/preview/run.sh`; it prints a unique ignored output directory. The first preview fixture parse failure is rejected; the corrected typed fixture exits 0. No live placement, matched before/after quality gain, LOD switching, collision clearance, draw-call/frame-time improvement, Mac performance or human acceptance is established. Four surfaces fit this bounded prototype's 2–4 limit; the broader fidelity document's preferred production ceiling of three still needs comparison or an atlas/material merge before repeated deployment.

Resume in a disposable Godot project or copied preview scene outside this ignored directory: import each GLB, check near and normal chase angles under the same existing daylight, inspect recess/bevel/normal/UV seams and opaque glass, compare LOD silhouettes and bounds, then measure one placement against the old facade before considering integration. Keep the actual current building footprint, supported thresholds, colliders, rails, route clearances and career logic independent. Do not turn this single proof into a city-wide replacement without that comparison.
