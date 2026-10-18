# Current direct RGB horizon candidate

The current checkpoint uses a single direct native cubemap, six512² RGB8 faces with mipmaps, actual6,291,450-byte pixel chains (≤6MiB). Source artwork is original and reproducible; the4096×2048 panorama remains an offline reference. Eight existing background/civic BoxMeshes extend down toY−35 with the same roof, footprint, material, mesh count and collision. Four regional context surfaces plus the existing water replacement remain within768 triangles. No additional sky subpass, lights, collision or frame callbacks.

Current focused proof is34/0 in `evidence/rgb-focused-02`, with unchanged source. Final native37-view/15-bearing admission and required regression remain pending. Historical evidence below is retained with its own verdict; it does not certify this new source. The native half-resolution sky failed Compatibility shader compilation and is rejected. CPU pixel-chain/source checks remain meaningful; the backend’s black GPU layer-readback is explicitly unverified rather than counted as passing.

Local measurement now fixes `LP_NUM_THREADS=3` in every compared phase under the same four-core quota. This does not alter shipped game settings or the unchanged p95/p99 gate. The intentionally interrupted first RGB final attempt exists only as a checkpoint receipt. No timing pass is claimed.

# Boundary and horizon repair

Current source: implementation checkpoint `a617000`, pushed to `bootstrap/m00-m01`. **Final visual, rendering and required-suite admission is pending while the current capture runs.** Read current STATUS before treating a historical attempt as accepted.

The original static panorama supplies hills, woodland, roofs/chimneys and sparse taller accents beyond the existing six areas. Actual vertical footings follow the retained physical boundaries; a small market service back closes the reported slit without closing a street. Scenic river banks bend the distant Clyde behind the existing quay end walls. The original high guard uses the resident CC0 brick albedo at the existing registered 1.25m tile scale.

The camera, fog, sun, ambient lighting, supported terrain, collision and 48 route identities stay unchanged. Previously rejected backdrops, facade pilots and murals remain off. New scenery has no frame callbacks, lights, shadow work or collision. Four regional static mesh surfaces contain 676 raw-footing triangles, two separate service-back triangles and 72 bank triangles. The existing water display uses the same animated material and an 18-triangle replacement mesh, for a combined ceiling of 768. The one new 4096×2048 panorama imports to 5,592,424 bytes including mipmaps; no wall texture is added.

[Tasks](../../planning/BOUNDARY-HORIZON.md), [ADR-019](../../architecture/decisions/ADR-019-boundary-horizon-continuity.md), [all-area design review](../../levels/BOUNDARY-HORIZON-REVIEW.md), [independent QE](QE.md) and [rejected previews](preview-review.md) explain the scope and remaining gates. Original editable art is in `art_source/horizon/`; its asset manifest binds source and output hashes. No Maps photographs, imported panorama, paid asset or service is used.

## Evidence and continuation

- `evidence/focused-06`: accepted independent 28/0, clean/frozen source; preceding focused attempts remain rejected and retained. Source PNG borders and decoded DXT1 block patterns/means are continuous. Individual compressed texels still contain ordinary dithering; they are not claimed pixel-perfect.
- Final native capture: 37 candidate player views, including both river directions, reported gaps, park corners and high layers. Fifteen bearings have original/candidate/original trials, 40 native intervals each, for 67 observations and 2,680 samples. Readbacks are excluded from timings. The real map and labelled authored overview are separate images.
- Final strict performance gate: each p95/p99 must stay below both control midpoint + repeat difference + 5% midpoint, and 1.05× the worse original control. No pooling away a failing view. Same-process appearance-off controls retain candidate allocations; the cold baseline and exact imported-data check provide separate memory evidence.
- Required `./tools/check.sh`, final source/image audit and independent final composition review remain pending. The renderer is serialized with every other engine job.

The native observers under `observers/` record the exact cloud commands. They assume the installed local Godot and Linux Xorg software display: copy them to the corresponding ignored `.local/horizon-background/` paths before replay, then run from the repository root. They do not install or provision anything. The headless focused helper runs with `./tools/run.sh --headless --script .local/horizon-background/focused.gd`; ordinary regression remains `./tools/check.sh`. Source guards include all game/test/tool/project files and the actual wrapper/observer inputs. Baseline and rejected source guards are hashes, not complete old-source snapshots; the pre-task runtime is available at `a6a78b8`.

Linux stationary measurements and sampled images do not certify Mac/M5 FPS, physical controllers, continuous temporal flicker, human fun or final realistic art/UI. Native release packages are historical after runtime changes. Keep the remaining art/hardware gates open honestly and resume the documented park-port survey only after this repair has its own final evidence.
