---
name: rider-fidelity
description: Build and independently inspect realistic skating characters, clothing, footwear and boards in Tam Hawks Pro Skater.
---

Read AGENTS.md, docs/STATUS.md, docs/product/ART_DIRECTION.md and docs/architecture/interfaces.md. Own only the assigned rider visual files; coordinate state inputs with movement and integration agents. Keep BodyCollision, SkaterVisual, Board and Rider interfaces intact.

Load docs/product/AAA_BENCHMARK.md, docs/planning/FIDELITY_TICKETS.md and the current PT24/C03 native contact contracts before work. Audit current main before replacing anything: preserve the original tam_skateboard.glb, shoe/tyre/palm clearance authority, 78-trick library, all default trial content and personal Music isolation. Old receipts do not certify current source.

1. Inspect actual current captures at gameplay scale and face, hands, footwear and silhouette close views; identify visible defects before changing geometry.
2. Prefer compatible free licensed production assets or native Godot skinning. Record sources, pinned revisions, licences and derivatives before shipping third-party assets. Never infer asset permission from a code licence.
3. Preserve adult anatomy, continuous silhouettes, fitted collar/wrists, usable eyes and believable fabric. Author cloth roughness, seams, wear and fine normal detail at sensible scale. Avoid primitive assemblies and arbitrary high-frequency noise.
4. Animation must preserve deck/foot contact, finite nondegenerate joint transforms, directional knee/elbow poles, natural push recovery and grab contact across all current actions. Cosmetic pose changes must never move collision or alter score.
5. Run tools/rider_asset_validate.sh for source-bound native cloth/contact/resource checks, then the required tools/check.sh integration gate. The wrapper rejects Godot resource/script errors even when the internal check count passes. Use tools/rider_asset_inspect.sh for diagnostic close views; verify its independent projected-marker pixel proofs and raw engine log. Use the current tools/full_fidelity_capture.gd pipeline for normal Main evidence. Inspect idle, push, brake, landing, manual, grab, flip, revert and both specials. Stills cannot certify temporal continuity: retain a normal-speed motion capture when possible.
6. Report geometry/material improvement separately from AAA visual acceptance, target hardware performance and human review. Keep unverified gates open and give reproducible evidence paths.

Default file ownership: game/player/skater_anatomy.gd, skater_garments.gd, skater_footwear.gd, skater_visual.gd; game/art/rider; tools/rider_asset*. Do not commit/merge during a shared swarm; report to orchestrator.

Asset reproduction: read game/art/rider/SKIN-NOTICE.md and the actual current manifests before selecting a pipeline. The admitted phase1 pipeline and private fitted candidate differ; do not copy rejected staging resources into main. The fitted pipeline verifies original BODY/morph pins, selected CC0 source members and explicit licence headers, then builds only selected derivatives with its declared generator chain. It replaces the old procedural crop/maps only after native admission. Keep full source body atlases in ignored local storage. Write generated outputs atomically and coordinate a single editor import lease. Never mutate source resources during another agent's import or source-bound capture. Preserve explicit VRAM compression, normal-map modes and mipmaps in each tracked .import file. A valid PNG with invalid import metadata still fails runtime loading.

Current provisional scope budget: at most 65,000 actual rider source triangles and 64 MiB conservative unique RGBA mip texture estimate. Report actual mesh/surface counts too. These limits do not establish target GPU performance. Shared immutable anatomy surfaces may be cached once; hand blend values remain per MeshInstance3D. Never claim zero runtime mesh construction when startup copies exist.

Authentic wardrobe fitting lessons from the private phase2 candidates (admission
is still pending; consult `docs/testing/rider-fit-2026-11-07/` for preserved,
independently reviewed rejected and bounded-positive epochs):

- Pin the official CC0 system-pack members and inspect each selected asset's
  actual OBJ/MHCLO/MHMAT declaration. Keep source BODY, morph targets, full skin
  atlas and fitting cages in ignored storage. Do not export unused source assets.
- Preserve original10 bone indices. A source-topology neck continuation may
  append an independent Head-frame bone, with exact retained rim/source IDs,
  UV-split correspondence and actual geometric tangent checks. Coincident points
  alone did not detect inherited180degree lower-neck folds.
- Share the actual Head material object across the chest seam. NPC callbacks
  need a correctly configured BoneAttachment; synchronous Skater poses also need
  an explicit final neck pose after all snapshot/handplant blends. Set attachment
  identity last, after enabling override and binding the external skeleton.
- An authored wardrobe `delete_verts` mask applies to original BODY polygons:
  hide a polygon only when ALL original corners are masked, before triangulation.
  Authenticate the exposed component against the real Head rim. Do not cut body
  surfaces by guessed XYZ bounds to conceal clothing penetration.
- Transfer source fields through actual MHCLO barycentrics. Helper vertex IDs
  belong to a fitting cage, not the real BODY; use an exact nearest BODY-triangle
  projection with barycentric/source-ID/distance records and independent controls.
- Keep genuine shared waist edges identical in positions, UVs and native weights.
  Mixed-weight seams require indexed multi-bone LBS observers and uniform-bind
  corruption negatives; never change authentic weights to satisfy an obsolete
  procedural test selector.
- Classify source shoe socks by authenticated connected UV islands, not height.
  A35mm triangle-height crop removed real vamp faces and created visible holes.
  Cache each side's actual native Cupsole vertices; preserve toe/palm contracts.
  A real upper can overhang its outsole: floor/grip contacts use the actual sole,
  while horizontal walls need the actual full shoe support geometry. Do not
  distort source footwear to satisfy an obsolete sole-encloses-upper assumption.
- Geometric clipping plus interpolated weights does not preserve a source
  triangle's deformed surface. Prefer exact source vertices/weights with authored
  UV coverage for garment overlays, or measure and validate a new binding.
- Preserve caller-owned shirt/denim material identity and live colour changes.
  Footwear must duplicate shared caller materials before changing their maps.
  Exercise actual NPC constructors and their hats, vests, aprons and instruments.
- A smaller full hand atlas visibly lost nail/knuckle detail. Pack authenticated
  palm/nail UV islands with a positive uniform material UV transform when useful;
  original hand vertex streams, blend shapes and contact geometry stay intact.
  Verify repeat tiles, padding, source sampling and actual bound UV properties,
  then compare matched native hand closeups. Texture dimensions alone prove
  neither preserved detail nor native allocation.
- Capture native RGBA and PNG hashes, full numeric camera/projection and all
  actual bone/model matrices, proof/clean pose and tick brackets, source inventories
  before AND after, and raw engine logs. Archive only receipt-listed current
  labels; stale PNGs are not evidence. Read every original before reporting a pass.
