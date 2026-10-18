# Current six-area and half-pipe visual review

18 October 2026. **All 41 current PNGs were opened and inspected individually. No new blocking visual regression was found in these sampled views.** The removed mirrored station caption and repaired half-pipe floor seam remain absent; rider, board and HUD remain visible. Known gaps in background scenery and unfinished realistic art remain open.

This review uses [area-current/manifest.json](area-current/manifest.json), SHA-256 `333e118aa11f5d6d88589c414e9b842779e4d6f576bc26ea049583fc6f3658e2`. The [capture receipt](area-current/receipt.json), SHA-256 `d020bac9abfbd0b09d44243c2bccd81e7bd8d1afb1137e05222eeb69af0864fb`, records accepted capture, exit 0, clean logs and 346 unchanged inputs at `1a1bd8e7474ed7eda1f1d854ea4da4a6a70fa974`. Independent read-only verification decoded all 41 images at 960×600, matched every PNG receipt hash and matched all 346 before/after hashes to current files. The [final audit](final-audit.json) additionally ties that same input inventory to the required **2,041/0** run on `db6b01f` and 5,886 consecutive native physics samples. This visual reviewer did not rerun the engine or change runtime files.

## Visible findings

| Check | Current image evidence | Finding |
|---|---|---|
| Rider, board and HUD | Every individually opened image below, including station undercroft and upper pipe views | Head/body and skateboard remain visible. HUD panels and control hints fit within the frame without obscuring the rider. The earlier absent-avatar symptom is not reproduced in this capture. |
| Unsupported mirrored `CENTRAL` | [central_station-03](area-current/central_station-03.png), also station 01/02/end | The floating reversed caption is absent. Canopy, piers and nearby pavement remain visible. The girder in station 02 crosses the upper view but does not hide the rider. |
| Dotted half-pipe floor seam | [halfpipe-03](area-current/halfpipe-03.png), [08](area-current/halfpipe-08.png), [13](area-current/halfpipe-13.png), also 06/11/16/end | The previous fine dotted floor line is absent. Both curved faces, flat surface, coping and rider shadows remain visible. This does not establish absence of temporal flicker between stills. |
| Nearby route support and joins | Exchange grades/retaining edges; station lower floor and bank; market counters/canopies; Clyde quay/ramp; park junction | No new visible break through the foreground riding surface, detached nearby building base or missing ramp face was found. This is appearance in sampled views, not an independent collision proof for the whole map. |
| World text and gameplay markers | Shop and stall fascia names; statue/gallery details; market rings and collectible icons | No new unsupported hovering prose was found. Screen-space notifications and HUD are interface; ground rings and collectible symbols are gameplay markers. Fascia signs remain attached to their visible structures. |
| George Square background | [george_square-02](area-current/george_square-02.png), central gap behind the fence around image X350–500/Y190–225 | **Open:** pale empty distance interrupts the building line. The foreground plaza and fence remain present; this image does not demonstrate a collision hole. |
| Barras background | [barras-02](area-current/barras-02.png), behind the fence around X420–510/Y170–245 | **Open:** a pale void-like strip remains between the buildings. Market floor, stall and canopy posts remain visible. |
| Park perimeter | [kelvingrove-end](area-current/kelvingrove-end.png), also 01/02 | **Open:** sparse trees and an empty grey horizon provide little distant enclosure. The actual near path/grass junction remains visible. |
| Clyde distance | [clyde-04](area-current/clyde-04.png), [clyde-end](area-current/clyde-end.png), upper pipe views | **Open:** the long quay sightline fades into sparse scenery. Nearby water, banks, ramp, bridge and opposite houses remain visible; convincing city continuation is unfinished. |
| Realistic-art treatment | All areas, especially repeated facades, park grass/trees and pipe poses | **Open:** coarse repeated surface detail, thin-edge aliasing at this preset, sparse foliage and procedural body poses remain apparent. These frames do not satisfy final realistic-art, animation or target-hardware acceptance. |

The prior unresolved close-up question about the physical mounting of `THE BARRAS` gateway lettering is not closed by these views. No removal or redesign is inferred from partially framed lettering. Murals and rejected backdrop experiments remain off in normal play; the open scenery findings do not authorize enabling failed performance candidates.

## Complete individual inspection inventory

Every name below is a separate PNG opened at its actual captured resolution, not a contact-sheet cell or a reused older view.

| Fixture | Individually inspected files | Count | Specific observation |
|---|---|---:|---|
| Royal Exchange | `royal_exchange-01.png`, `royal_exchange-02.png`, `royal_exchange-03.png`, `royal_exchange-end.png` | 4 | Full rider/board through plaza, shop approach and gallery grade; visible nearby floor/retaining joins. |
| George Square | `george_square-01.png`, `george_square-02.png`, `george_square-03.png`, `george_square-end.png` | 4 | Rider/UI clear; civic bank and garden edges visible; the background opening remains conspicuous in 02. |
| Central Station | `central_station-01.png`, `central_station-02.png`, `central_station-03.png`, `central_station-end.png` | 4 | Rider visible beneath structure; caption absent; lower floor, support piers and exit bank remain rendered. |
| Barras | `barras-01.png`, `barras-02.png`, `barras-03.png`, `barras-end.png` | 4 | Clear rider/board between counters and markers; attached fascia signage; background strip remains in 02. |
| Clyde | `clyde-01.png`, `clyde-02.png`, `clyde-03.png`, `clyde-04.png`, `clyde-end.png` | 5 | Continuous-looking near quay/ramp and readable water edge; sparse distance remains. |
| Kelvingrove | `kelvingrove-01.png`, `kelvingrove-02.png`, `kelvingrove-end.png` | 3 | Rider clear on bends/junction; grass/path edges visible; horizon and foliage density remain unfinished. |
| Half-pipe, first sequence | `halfpipe-01.png`, `halfpipe-02.png`, `halfpipe-03.png`, `halfpipe-04.png` | 4 | Rider and board remain visible on approach, steep face, flat crossing and opposite face. |
| Half-pipe, second sequence | `halfpipe-05.png`, `halfpipe-06.png`, `halfpipe-07.png`, `halfpipe-08.png` | 4 | Upper views preserve the rider; floor and shadow remain visible without the old dotted seam. |
| Half-pipe, third sequence | `halfpipe-09.png`, `halfpipe-10.png`, `halfpipe-11.png`, `halfpipe-12.png` | 4 | Alternating face/upper/flat images retain the complete rider, coping and HUD. |
| Half-pipe, final sequence | `halfpipe-13.png`, `halfpipe-14.png`, `halfpipe-15.png`, `halfpipe-16.png`, `halfpipe-end.png` | 5 | Flat join remains clean in the stills; upper and final approaching poses stay framed. |

Total: **24 district images + 17 half-pipe images = 41**.

## What this does not establish

The fixture uses production Main, camera and HUD under Godot 4.6.3 Compatibility, Linux llvmpipe, 960×600 and the Performance preset. Six independent initial placements followed by mapped inputs, plus a separate pipe fixture, are not one continuous city playthrough. Sparse stills cannot establish exact airborne contacts, the absence of every small collision hole, off-camera boundaries, temporal shader stability, camera comfort, audible mix, human fun or Apple M5/DualSense performance. Movement traces and the required suite support their separate declared claims; they do not turn the remaining visual defects into completed art work.

The [previous 68781fc review](area-visual-review.md) and its diagnostic set retain the defect history. This note concerns the current source-bound 41-image set only.
