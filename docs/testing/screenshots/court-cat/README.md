# Court, workshop encounter and six-area captures

This retained successor set contains **34 actual Godot-rendered PNGs**, completed **17 October 2026 at 16:18:46 UTC**, with zero capture failures and wrapper exit 0. All images are 1280×800. The [manifest](manifest.json) records 34 runtime routes, six checkpoints, 102 source-input hashes, per-image SHA-256, camera/player placement, support and settings, actual cat captures and its visible-return trigger.

The source stayed unchanged during this run: dirty working tree based on `64000fdbff6812906a02ea4e4447143a75b8f623`. That historical identity remains intact after later commits. Manifest SHA-256: **`9ba441c01c7dd24e2e5dd52505eb8314346720327bc7224ff81c6f3906c377e9`**. The earlier 21-image checkpoint remains in [level-redesign](../level-redesign/README.md), and the first candidate’s concrete review findings are preserved in [court-cat-diagnostics](../court-cat-diagnostics/README.md).

## What was rendered

| Frames | Actual evidence and limits |
|---|---|
| 01–07 | Production chase views at all six areas, plus the gallery descent. Fixtures settle on the intended terrain and require capsule clearance. They are positioned inspection views, not completed traversals. Barras 05 intentionally retains its matched north-facing checkpoint, now near the new hall’s side; 23/24 supply the useful open-aisle views. |
| 08–09 | Explicitly authored core/six-area overview cameras derived from runtime route bounds, with HUD hidden. The overall map still shows broad/sparse courts and unfinished perimeter art. |
| [10 — map](10-city-map-routes.png) | Real production CITY MAP & ROUTES page, with readiness verified around the draw. Six labels and 34 real authored routes are represented. Help text is in a scrollable page; its final paragraph lies below the initial fold. |
| 14–17,19–21 | Station undercroft, both Merchant mouths, park fork/join and Clyde low-bank approach/return. The undercroft uses intended Y2 support beneath the Y5 deck. A low curved bank is not vert/lip skating. |
| 11–13,18 | Mo’s original offer/actor and actual input-driven three-family 1,950-point bank/success remain intact. The actor medium explicitly hides the unrelated player/HUD. No score or challenge callback is injected. |
| [22 — George approach](22-george-workshop-approach.png),25–26 | Garden/workshop apron, diagonal low banks, retaining walls, A/B/C course and permanent supported returns. Both course directions remain visible. |
| [23 — market hall](23-barras-west-market.png),[24 — aisle return](24-barras-aisle-return.png) | Attached brick hall and chamfered bank/skirt, protected route and clear market aisle. Corrected 24 is at (82, 0, 17), settling at Y0.0002 on authored Y0 with capsule clearance; it no longer stands on a stall. |
| [27 — cat offer](27-cat-offer.png),[28 — workshop medium](28-cat-workshop-medium.png) | Actual original Rae/mechanical-cat stage and nearby input-aware offer. The medium is an authored inspection camera and hides only unrelated rider/HUD. No real-person likeness or copied performance is claimed. |
| [29 — A](29-cat-capture-a.png),[30 — B](30-cat-capture-b.png),[31 — C](31-cat-capture-c.png) | Same continuous attempt after real push/ollie/grind and rail-ollie transfers. Production signal IDs are exactly Grind_Cat_A/B/C, progress 1/2/3, pending earned score 600/900/1,050. The persistent NEXT and LAND AND BANK feedback is visible. |
| [32 — banked success](32-cat-success.png) | Actual final release/landing banks exactly 1,050 with one win. The cat’s earned response is queued because the east-facing chase view does not include the stage; feedback tells the player to return. Success and payoff timing are separate. |
| [33 — earned payoff](33-cat-earned-payoff.png) | Same successful attempt physically returns through ordinary input for 51 ticks. The production chase camera includes the stage at 9.876 m horizontal distance and starts one earned dance. Only afterward does an explicitly authored inspection camera frame the stage. The image records `dance_active=true`, elapsed 0.7167 of 3.2 seconds; no completion, visibility flag or animation time is injected. |
| [34 — reduced motion](34-cat-reduced-motion.png) | The same earned success after the public reduced-motion preference is applied with persistence disabled. A static raised paw and steady charged A/B/C indicators replace motion; recorded state is static/reduced_motion=true. This does not award or replay another success. |

Grounded heading is directly aimed in the deterministic cat driver; production push/brake, ollie, grind, steering/balance, contact and banking perform the movement. There is no position or speed injection after its initial supported placement. Physics/movement freezes briefly for still inspection; normal actor animation advances from its actual trigger. The custom actor camera does not supply the triggering visibility. Three historical park PNGs are byte-identical to previously reviewed images; all other retained images were inspected anew, with independent lead/geometry/encounter review of the changed slice.

## Review and remaining work

The corrected set clears the concrete first-pass blockers: a stall-obstructed authored viewpoint, inward-facing retaining sides, and a dance that previously happened offscreen. Geometry confirmed that its side-winding correction leaves 247 collision shapes/transforms and terrain registries unchanged. The lead accepts the bounded George/Barras place iteration; geometry accepts restored side faces and the supported aisle, and the encounter owner accepts the real queued/live/static payoff frames. No further production or capture correction was requested.

This remains a development alpha. Broad Exchange/station courts, empty approaches, repeated facades, abrupt material joins, the outer skyline, final character polish and authentic current frontage references remain tracked under M05-001/M06-007. The next bounded place design is Exchange/gallery, not a completed feature. Human turning, discovery, comic timing, local tone/listening, Mac/DualSense and final realistic/fun acceptance remain open. These stills cannot establish continuous animation quality or frame rate.

## Reproduce and provenance

On the installed Linux image after normal import:

```bash
./tools/level_design_capture.sh --private-display
```

On a graphical Mac desktop with free Godot 4.6.3 installed:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot ./tools/level_design_capture.sh
```

The bounded runner requests Compatibility, explicit 1280×800 window/content size and fixed 60 Hz. It disables automatic rendering between fixture steps and uses actual force_draw/frame_post_draw images. Main’s persistence is disabled before entering the scene; free skate does not write career progress. Every source hash is compared before/after, and the wrapper rejects engine errors, missing frames, changed inputs or invalid manifests before publishing. It owns/stops its private display and game process, installs nothing and uses no paid service.

This run used X11/Mesa llvmpipe software OpenGL and Dummy audio. The sole graphics warning was unsupported V-Sync on the private software display. The root’s concurrent headless regression is harmless for these non-timing stills but is another reason not to infer performance. Profiling is a separate uncontended run owned in [PERFORMANCE](../../PERFORMANCE.md). Raw capture/log files remain ignored under `.local/level-design-20261017T161809Z-44c7aL/`; this durable image/manifest set remains reproducible after the environment is replaced.

Gameplay evidence belongs in [TOPOGRAPHY](../../TOPOGRAPHY.md), [CAREER-ROUTES](../../CAREER-ROUTES.md), the cat encounter tests and the root’s final QE/STATUS. Package identity is recorded separately in EXPORT; neither a PNG nor an automated pass grants final release acceptance.
