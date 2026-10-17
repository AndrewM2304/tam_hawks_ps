# Actual terrain, route, map and encounter captures

The retained set contains **21 actual Godot-rendered PNGs**, completed **17 October 2026 at 15:42:35 UTC**, with **zero capture failures** and wrapper exit 0. All images are 1280×800. The [manifest](manifest.json) records the exact settings, camera/player transforms, 28 runtime routes, six checkpoints, 98 source-file SHA-256 fingerprints and each PNG's SHA-256.

The source was a dirty working tree based on `bd12b61e81b9ed4e7b918836a2bf76d329b9b122`, unchanged throughout this run. That historical identity is intentionally preserved even if the files are committed later. Manifest SHA-256: `f0b3a30987a7731371ebb4b74102751dfbdfd192194a7db7b574669ba5b0674b`.

## What the frames show

| Frames | Evidence and fixture boundary |
|---|---|
| 01–07 | Production chase camera at the Exchange spawn, gallery descent, civic rise, station concourse, market, Clyde takeoff approach and low park climb. Positions come from runtime metadata and settle on actual collision. These are static placements, not completed routes. |
| 08–09 | Explicitly authored core and six-area inspection cameras, derived from route bounds, with HUD hidden. They show topology rather than the playable camera experience. |
| [10 — map](10-city-map-routes.png) | Actual CITY MAP & ROUTES page opened through production `show_map()`, with readiness checked before and after the draw. All six area labels and real route branches are present. Help text wraps within the scrollable page; its final paragraph extends below the initial fold at this resolution. |
| [14 — undercroft](14-station-undercroft.png) | Actual supported Y2 floor beneath the Y5 station deck. `get_support_height` selects the intended route floor; the player settles at Y≈2.0002. The highest-ground query alone would select the upper deck. |
| 15/19, 16/20, 17/21 | Both Merchant Close mouths, park cutback fork/join and the Clyde low curved hip approach/return. The lower Merchant service court/return banks and corrected park opening/shoulders are included. The hip is a low bank, not full vert/lip mechanics. |
| [11 — offer](11-busker-offer.png) | Actual Mo actor and input-aware approach prompt, with the rider positioned three metres from the encounter anchor on supported ground. |
| [12 — active line](12-busker-active-line.png) | The real Interact action starts the attempt; real Ollie, Flip and Grab actions produce three observed families and a pending 1,950-point line. No trick/score/challenge callback is injected. The simulation freezes only for the image. |
| [13 — success](13-busker-success.png) | Resuming the same input sequence permits actual landing and ordinary banking. The fixture asserts success, exactly one win, three families and at least 1,000 banked points; the observed bank is **1,950**. |
| [18 — Mo medium](18-busker-medium.png) | An authored three-quarter camera inspects Mo's head/collar, guitar, hand contact, case sign and planted shoes in the actual production world. Only this isolated actor view hides the unrelated player visual and HUD; the manifest records that fixture explicitly. |

All 21 images were reviewed, including the final changed images and unchanged PNGs verified against the previously inspected set. Lead design, root and geometry review cleared the specific topology blockers: lower service court/return, open park fork and grounded shoulder. Local labels and isolated Mo framing are corrected. The small yard planting/apron wedge is retained as a nonblocking art detail. The core courts remain broad, materials/facades repetitive and perimeter landscaping unfinished; M03-014/M06-007 preserve that further work. These frames do not close owner visual acceptance.

## Reproduce the current successor set

This directory is the preserved **historical 21-image checkpoint**, not the output destination of the later court/cat iteration. Its source hashes, PNGs and original manifest remain unchanged. The current runner now publishes separately under `docs/testing/screenshots/court-cat/`; use the historical committed runner/source identified by the manifest to reproduce this earlier workload exactly. Running the current command below records the current successor geometry and fixtures, not these original bytes.

After the normal project import, on the installed Linux development image:

```bash
./tools/level_design_capture.sh --private-display
```

On a normal macOS desktop with the free pinned engine already installed:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/level_design_capture.sh
```

The bounded runner uses Godot **4.6.3**, Compatibility rendering and an explicit 1280×800 window/content canvas. It disables automatic rendering between fixture steps and calls `force_draw` for each image. Physics uses fixed 60 Hz. Career profile loading/saving is disabled before Main enters the tree, and the fixtures run in free skate. The busker observes normal score events and adds no career goal or profile write.

This Linux run used X11/Mesa **llvmpipe software OpenGL** and Dummy audio. It is neither an Apple Silicon performance measurement nor a human play/listening test. Captured draw-call counters are diagnostics, not timings. A positioned terrain frame cannot prove traversal, a completed automated challenge cannot prove fun, and no real physical controller was used.

## Review history and guard behavior

- The first ten-view terrain set at 14:54 UTC exposed park approach support, grass/water appearance and map-help wrapping issues. Those files predate the final nonlinear layout.
- The first 21-view set at 15:34:18 UTC exposed Merchant side pits, the old coping across the park fork, exposed shoulders/yard edges and a distracting unrelated rider in the authored NPC medium view. Its complete images, manifest and logs remain under the ignored `.local/level-design-20261017T153353Z-rKGOGL/`.
- A correction run at 15:41 UTC rendered all 21 with zero engine failures, but a final local-name edit changed `game/levels/glasgow_square.gd` during capture. The source guard rejected the batch with exit 1 and published none of it. It remains ignored under `.local/level-design-20261017T154111Z-2Eh0ug/`.
- The retained clean repeat came from `.local/level-design-20261017T154210Z-tS2EGZ/`. All source hashes stayed stable; all PNG digests were checked against the published manifest. Its private display and game process stopped on completion. No downloads, paid services, remote writes or image compositing were used.

Physical route/encounter evidence belongs in [TOPOGRAPHY](../../TOPOGRAPHY.md), [CAREER-ROUTES](../../CAREER-ROUTES.md), the encounter tests and the orchestrator's final QE record. Hardware, human route discovery/comfort, local tone/listening and final art acceptance remain open.
