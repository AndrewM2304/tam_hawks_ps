# Exchange/gallery place evidence

**Accepted bounded place and earned-line evidence, 17 October 2026.** The corrected run produced **22/22 actual 1280×800 PNGs**, zero capture failures, **164 unchanged source/resource/test/tool inputs** and **44 runtime routes**. The manifest was recorded at **18:39:01 UTC** and has SHA-256 **`8c6122729aad2fda9c7c609fb6c53dda36accec62c41e3cef0571f7484b9e39e`**. [manifest.json](manifest.json) contains every source/image hash, camera transform, support position, setting, route and observed gameplay state.

Root, lead design, art review and independent QE accept the bounded gallery-mass correction and place/earned-line evidence. All 22 images were inspected; independent QE verified all source hashes, PNG hashes and dimensions. No new concrete capture/art blocker remains for this slice. The ordinary regression and changed native packages have their own outcomes in [STATUS](../../../STATUS.md), [QE-REPORT](../../QE-REPORT.md) and [EXPORT](../../EXPORT.md); this image receipt does not pre-certify them. Final art, human discovery/steering/fun, target Mac/controller/listening and performance acceptance stay open.

## What changed and what was corrected

The gallery now has an attached Y2.65 chamfered entrance terrace, side/front banks, a turning low grind ledge and eight grounded portico columns. A Y0.45 west shopfront deck, low coping and southeast return sit beside the clear X−22 bypass. The map uses five additional authored routes. The [exact place contract](../../../levels/EXCHANGE-GALLERY-BRIEF.md) records protected approaches and runtime IDs; the three existing side acts, ten career goals and save IDs remain unchanged.

The first render exposed an inherited 19 m brown retail block overwhelming the new portico. The corrected gallery-only body uses pale ashlar, one upper opening row, eaves Y8.75 and a closed low roof below the Y10.85 pediment; the original 18×12 footprint, terrain, columns, ledges and route geometry stay fixed. The gallery name is readable on the front frieze. [First-pass diagnostic 01/03/05/12 and the complete original manifest](../exchange-gallery-diagnostics/README.md) are retained; their earlier digest is not current-source evidence. Older lateral court voids, repeated surrounding facades and broad paving still need the wider M05-001/M06-007 cleanup.

## Actual frame recipe

| Frames | Evidence and fixture boundary |
|---|---|
| [01 spawn](01-exchange-spawn.png), [02 port approach](02-west-planter-port-approach.png) | Supported production rider and chase camera, north from the normal Exchange spawn and protected planter/port approach. |
| [03 west bank](03-gallery-west-bank.png), [04 east bank](04-gallery-east-bank.png) | Both gallery terrace approaches, using released route endpoints and actual settled support. |
| [05 gallery frontage](05-gallery-frontage-detail.png), [06 front descent](06-gallery-front-descent.png) | Authored frontal inspection of roof/frieze/columns/threshold, then a production chase view facing the supported front-bank return. |
| [07 west approach](07-west-edge-approach.png), [08 southeast return](08-west-edge-return.png), [09 seating deck](09-west-seating-deck.png), [10 bypass](10-west-beginner-bypass.png) | Actual chase cameras at supported west-bank, return, raised-deck and lower-risk bypass fixtures. Frame 09 retains the real camera near the facade. |
| [11 protected crossing](11-gallery-protected-crossing.png), [12 overview](12-exchange-place-overview.png), [13 map](13-city-map-routes.png), [14 west foundations](14-west-foundation-detail.png) | Production crossing; authored local overview; actual ready CITY MAP & ROUTES page; authored oblique foundation/threshold inspection. |
| [15 Barrowland](15-preserved-barrowland.png), [16 Barras interior](16-preserved-barras-interior.png), [17 Clyde bridge](17-preserved-clyde-bridge.png) | Current-source static context showing the previously requested landmarks remain present. These stills do not claim to rerun the complete delivery or river-route tests. |
| [18 bank ascent](18-earned-bank-ascent.png), [19 gallery grind](19-earned-gallery-ledge.png), [20 rail-to-air](20-earned-rail-air.png), [21 linked manual](21-earned-manual-link.png), [22 banked result](22-earned-clean-bank.png) | Five awaited observer stages from the same real input-driven line, described below. No authored inspection camera replaces the production chase view for this line. |

## Earned line and limits

The runner reuses `tests/exchange_place_tests.gd::drive_ledge_combo`, including that file and all other test dependencies in its fingerprint. Its only initial placement is board spawn **(−18,2.8,−35.3)**, heading east, settled for 45 physics ticks onto the Y2 floor. Production push, ollie, grind, flip, grab and manual inputs then drive the route. Grounded heading is idealized, but no post-start position, velocity, score, trick callback or completion state is injected.

The rider climbs **0.274595 m while grounded**, physically captures **`Grind_Ledge_GalleryEntrance`**, follows its southward turn, ollies off, performs a Kickflip and Melon Grab, lands into a fresh manual, and banks **5,000 exactly once**. The completed driver records **zero bails, zero stalls and 324 clear camera samples**. The trick history is Ollie → Rail Grind → Ollie → Kickflip → Melon Grab → Manual. Frames 19/20/21 show 600/3,600/5,000 pending; frame 22 shows 5,000 banked and zero pending. The driver continues 30 ticks after frame 22 to confirm no repeat bank; that final result is stored in `exchange_evidence`.

Observer callbacks temporarily stop player/main processing for each actual draw, then resume the same state and inputs. The 324 physics steps therefore establish progression, not uninterrupted human timing. Static chase images use supported placements; the frontage/overview/foundation/Barrowland cameras are explicitly authored inspections with the HUD hidden. The map is the real production page with readiness checked before and after drawing. No historical cat clip or market completion is generated by default.

Rendering used installed **Godot 4.6.3**, Compatibility/OpenGL, Linux X11 and **Mesa llvmpipe**, at 1280×800, UI scale 1.0, captions on and reduced motion off. The runner explicitly overrides content scaling to the recorded resolution, disables automatic rendering, steps fixtures at 60 Hz and calls `force_draw` for actual PNG readback. Audio uses the Dummy driver and profile writes are disabled. These images provide no real-time FPS, target-GPU/Mac, audio-listening or physical-controller result.

Capture Git metadata honestly records dirty source based on **`76b096347e88d652a5ca01195b2d4343d82e3011`**; the 164 individual hashes bind the exact corrected files. A later clean runtime/package receipt can overlap those source hashes without rewriting this historical capture metadata.

## Reproduce

From the repository, with source/test/tool inputs held stable:

```sh
./tools/level_design_capture.sh --private-display
```

On a native graphical macOS desktop use `./tools/level_design_capture.sh` without the Linux-only private-display option, selecting the installed free Godot 4.6.3 via `GODOT_BIN` if needed. Headless rendering is rejected. The wrapper creates its own temporary display on Linux, bounds the child run to 420 seconds, checks its log and all source/image receipts, publishes only a complete unchanged set, and stops its own game/display processes. The completed corrected temporary log is `.local/level-design-20261017T183834Z-009caW/engine.log` while this workspace exists; the durable manifest preserves the exact command and evidence.
