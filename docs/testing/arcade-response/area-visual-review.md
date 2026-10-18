# Six-area gameplay visual review — initial diagnostic

Reviewed **18 October 2026**, all **41 actual PNGs** from `.local/area-audit-play-20261018T105906Z-wrYk4Q`, captured against candidate `3620363c1706a0fbd4aa1291c7615cb3de88b650`. The [retained diagnostic receipt](area-diagnostic/receipt.json) records 346 unchanged source inputs, exit 0, a clean log and valid manifest. This note records the initial diagnostic, including the defect it exposed; it is not acceptance of a later corrected capture.

The fixture runs production Main, chase camera and HUD with mapped key input and native rendering at **960×600 / Performance preset / Godot Compatibility / Linux llvmpipe**. There are six independent initial placements followed by simulated input traversals, plus a separate halfpipe fixture. This is not a continuous city tour, human playtest, physical controller test, 1080p visual gate or Mac performance result. No engine process or source change was made by this reviewer.

## Actionable findings

| Finding | Actual evidence | Disposition |
| --- | --- | --- |
| **Unsupported, mirrored station text** | [central_station-03.png](area-diagnostic/central_station-03.png): large reversed `CENTRAL` hangs in open air below the canopy, upper right of centre. | Remove the unbacked label invocation in `city_art.gd::_station_arches`, then review a source-stable corrected capture. Keep the shared `city_art._label` method: `FacadeKit` calls it for real shop/civic/window signage. A supported, correctly facing sign could be future art work, but no extra geometry is necessary for removal. |
| **George Square background gap** | `george_square-02.png`, approximately image X380–500/Y190–225: pale sky/horizon visible through the central building gap behind the rail. | Open boundary-composition work. It reads as unfinished city depth, while the nearby route appears supported. This image does not prove a collision hole. Keep rejected backdrop candidates OFF until a cheaper alternative passes its gate. |
| **Open park horizon** | `kelvingrove-end.png`: empty grey horizon to the left of the hill/path and trees; earlier park views also show a sparse perimeter. | Open scenery-continuity work. The visible paved junction and grassy near slopes are present; do not infer an unsupported route from the horizon alone. |
| **Clyde still ends in a pale, sparse distance** | `clyde-01.png` through `clyde-end.png`, most obvious beyond the ramp/bridge in `clyde-04.png` and `clyde-end.png`. | Quay, nearby riverbanks, buildings and transition supports read as grounded, but the long sightline still lacks convincing urban continuation. Preserve the performance-first restriction; no new skyline plane or costly blanket wall is approved by this review. |
| **Fine halfpipe floor seam to investigate** | `halfpipe-08.png` and `halfpipe-13.png`, also faintly `halfpipe-03.png`: small dotted dark line across the floor. | Static evidence only. It could be a surface/shadow seam; no temporal z-fighting diagnosis is established. Check moving views if this remains visible after the caption-only correction. No broad white coplanar strip like the owner's Clyde recording appears in these frames. |

A separate **source-only mounting concern** was sent to the integrator: `art/barras_market.gd::_gateway` places two single-sided `THE BARRAS` labels at Y7.05 while the existing arch crown/crossbar is at Y6.55 (bar top Y6.63), without a backing at the text height. These high gateway labels are not clearly framed in this PNG set, so this is not a second claimed screenshot defect. They are already single-sided, so the station's mirrored-face issue does not apply. Removing the unbacked label invocations or remounting lettering on verified existing ironwork avoids adding rendering geometry.

## What the frames support

- The full rider and board remain visible in all reviewed district and halfpipe images. The camera retains useful framing through low undercroft views and upper halfpipe turns; this set does not reproduce the owner's earlier invisible-avatar condition.
- HUD panels and the `FRESH RUN. GIE IT LALDY.` notification are screen-space interface. Shop/stall names are attached to fascias; gallery and statue lettering is tied to architecture. They should not be removed as hovering captions.
- Barras letter/pickup icons and ground rings remain visible gameplay markers. They are distinct from NPC names, route prose or challenge progress hovering in world space. Source review confirms the old busker/cat/market/route caption nodes are hidden and their logical state remains available to the HUD.
- Nearby visible ground, retaining faces, ramp decks/sides, station piers, shop bases and counters appear joined to their support in these views. Screenshots alone do not certify all collision, hidden backsides or every map edge.
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

All names above have the `.png` extension. The local run retains the complete original image set; the diagnostic archive retains the station defect frame and evidence selected by root. Initial manifest SHA-256: `cc7d5602049856a270adbb39a9be7f8d29a87a31c36e6d3614e24321d7514dae`; receipt SHA-256: `7026aedd854b8530eba1d6f9fe77df42078afcdf3cb264446cc3dba2fce49fc2`. Final corrected-run review must name its own source receipt and actual images rather than treating this diagnostic as current evidence.
