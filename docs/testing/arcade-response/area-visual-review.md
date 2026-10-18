# Six-area gameplay visual review — final corrected capture

Reviewed **18 October 2026**, all **41 final PNGs individually**, from `.local/area-audit-play-20261018T111946Z-qzg48K`, against source `68781fccff3c8c584764c74591a8ff19961b4043`. The [final receipt](area-final/receipt.json) records **accepted capture, 346 unchanged source inputs, exit 0, a clean log and a valid manifest**. The [manifest](area-final/manifest.json) has no errors. The station caption and halfpipe floor seam found in the initial diagnostic are absent from the corresponding final images. Remaining background and realistic-art work stays open; capture acceptance is not final art acceptance.

The earlier 41-image diagnostic was also reviewed individually: `.local/area-audit-play-20261018T105906Z-wrYk4Q`, source `3620363c1706a0fbd4aa1291c7615cb3de88b650`. Its [receipt](area-diagnostic/receipt.json) and retained defect image preserve the reason for the two corrections.

The fixture runs production Main, chase camera and HUD with mapped key input and native rendering at **960×600 / Performance preset / Godot Compatibility / Linux llvmpipe**. There are six independent initial placements followed by simulated input traversals, plus a separate halfpipe fixture. This is not a continuous city tour, human playtest, physical controller test, 1080p visual gate or Mac performance result. No engine process or source change was made by this reviewer.

## Corrected findings and remaining work

| Finding | Actual evidence | Disposition |
| --- | --- | --- |
| **Unsupported, mirrored station text — corrected** | The [initial station frame](area-diagnostic/central_station-03.png) has a reversed `CENTRAL` hanging below the canopy. It is absent in [final central_station-03.png](area-final/central_station-03.png). | Only the unbacked invocation was removed. The shared `city_art._label` method remains because `FacadeKit` calls it for physically mounted shop/civic/window signage. No replacement geometry was needed. |
| **Fine halfpipe floor seam — corrected in captured views** | The earlier dotted line is absent in final [halfpipe-08.png](area-final/halfpipe-08.png), [halfpipe-13.png](area-final/halfpipe-13.png) and [halfpipe-03.png](area-final/halfpipe-03.png). Rider shadows remain visible. | Root replaced the rendered flat box with a plane while retaining shadow casting and physical collision. The separate [floor comparison](floor-visual/README.md) records its strict timing gate, actual image differences and rejected shadow-OFF alternative. These static views do not certify moving-camera flicker or all surfaces. |
| **George Square background gap — open** | [george_square-02.png](area-final/george_square-02.png), approximately image X380–500/Y190–225: pale sky/horizon through the central building gap behind the rail. | Unfinished city depth, with the nearby route visibly supported. This image does not prove a collision hole. Keep rejected backdrop candidates OFF until a cheaper alternative passes its gate. |
| **Barras perimeter gap — open** | [barras-02.png](area-final/barras-02.png): pale void-like background between the buildings behind the fence, near image X435–495/Y175–240. | Include this short sightline in future boundary-composition checks. The fence and foreground market floor are present; do not mistake the distant appearance for a demonstrated unsupported riding route. |
| **Open park horizon — open** | [kelvingrove-end.png](area-final/kelvingrove-end.png): empty grey horizon left of the hill/path and trees; earlier park views show a sparse perimeter. | The paved junction and grassy near slopes are present. Future scenery must improve continuity without implying new unsupported routes or bypassing the performance gate. |
| **Clyde sparse distance — open** | [clyde-04.png](area-final/clyde-04.png) and [clyde-end.png](area-final/clyde-end.png), beyond the ramp/bridge. | Quay, nearby riverbanks, buildings and transition supports read as grounded; the long sightline lacks convincing urban continuation. No new skyline plane or blanket wall is approved by this review. |

The **THE BARRAS lettering remains**. An initial source-only concern compared label origin Y7.05 with crossbar top Y6.63; that comparison did not account for native glyph bounds. The retained [native bounds probe](diagnostics/gateway-bounds.log) gives label AABB Y6.581–7.519 on all four faces, overlapping the bar's Y6.47–6.63 bounds by 49 mm. This is insufficient evidence to remove the lettering. Font padding means geometric overlap alone does not establish visible ink attachment, and these high letters are not clearly framed here: a close-up check of actual letter mounting remains open. The labels are single-sided, so the station's mirrored-face defect does not apply.

## What the frames support

- The full rider and board remain visible in all 41 final images. The camera retains useful framing through low undercroft views and upper halfpipe turns; this set does not reproduce the owner's earlier invisible-avatar condition.
- HUD panels and the `FRESH RUN. GIE IT LALDY.` notification are screen-space interface. Shop/stall names are attached to fascias; gallery and statue lettering is tied to architecture. They should not be removed as hovering captions.
- Barras letter/pickup icons and ground rings remain visible gameplay markers. They are distinct from NPC names, route prose or challenge progress hovering in world space. Source review confirms the old busker/cat/market/route caption nodes are hidden and their logical state remains available to the HUD.
- Nearby visible ground, retaining faces, ramp decks/sides, station piers, shop bases and counters appear joined to their support in these views. Screenshots alone do not certify all collision, hidden backsides or every map edge.
- No additional unsupported hovering prose was found, and no broad white coplanar strip like the owner's earlier Clyde recording appears in these stills. Sparse screenshots cannot rule out temporal flicker, distant thin-line aliasing or platform-specific rendering faults. Murals and rejected backdrop experiments remain OFF in normal play.
- Repeated facade/paving modules, sparse foliage and coarse prop detail remain visible at the captured settings. These are open realistic-art tasks; this review does not certify the final appearance or infer what untested target hardware/settings will show.

## Complete inspected image inventory

| Fixture | Files opened individually | Count |
| --- | --- | --- |
| Royal Exchange | `royal_exchange-01`, `-02`, `-03`, `-end` | 4 |
| George Square | `george_square-01`, `-02`, `-03`, `-end` | 4 |
| Central Station | `central_station-01`, `-02`, `-03`, `-end` | 4 |
| Barras | `barras-01`, `-02`, `-03`, `-end` | 4 |
| Clyde | `clyde-01`, `-02`, `-03`, `-04`, `-end` | 5 |
| Kelvingrove | `kelvingrove-01`, `-02`, `-end` | 3 |
| Halfpipe | `halfpipe-01` through `halfpipe-16`, plus `halfpipe-end` | 17 |

All names above have the `.png` extension. Every listed image was opened separately in both the initial and final sets: **41 initial + 41 final**. The complete final set, per-frame hashes, traces, executed fixture and source records are retained in [area-final](area-final/manifest.json). The diagnostic archive retains the original station defect and initial capture provenance.

Final manifest SHA-256: `7ba78297ae9baf6338444d7b6d3145d523f8444ee3e4527492e95095106a1c38`; final receipt SHA-256: `5a7e8dc9c0293349a840c1e5f315b7c7f8a603a77ae832dd6743d92faeb57421`.

Initial manifest SHA-256: `cc7d5602049856a270adbb39a9be7f8d29a87a31c36e6d3614e24321d7514dae`; initial receipt SHA-256: `7026aedd854b8530eba1d6f9fe77df42078afcdf3cb264446cc3dba2fce49fc2`.
