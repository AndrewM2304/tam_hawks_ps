# Current handoff — 17 October 2026

> **Active redesign in progress:** the owner has requested substantial terrain/place changes and a less cartoony rider. The checkpoint below describes the previous build, not current uncommitted source. Follow `docs/planning/ACTIVE_WORK.md`, ADR-007 and new M03-008–012 / M05-006 / M06-008 / M07-006 tickets. New six-area terrain, route map and anatomical character work must pass fresh integration and rendered checks before replacing the downloadable packages.

**Project:** Tam Hawks Pro Skater. **Branch:** `bootstrap/m00-m01`. **State:** playable development alpha with a second environment, rider and UI cleanup pass. Final realistic visual acceptance remains open. Run `git log -1` and `git status --short` before resuming; preserve subsequent edits.

The owner authorizes all ready implementation without recurring approvals. No purchases, paid APIs, billing, hosted CI, infrastructure or unattended jobs. Ordinary assistant work uses existing session credits. Missing human/hardware evidence does not block independent work.

The [feature branch](https://github.com/AndrewM2304/tam_hawks_ps/tree/bootstrap/m00-m01) and [54 complete task records](planning/BACKLOG.md) preserve ownership, dependencies, acceptance and next actions. The original repository had no `main`/PR base; no PR, remote issues, hosted workflow or public release has been created.

## Resume and run

1. Read `AGENTS.md`, this file, BACKLOG, `docs/architecture/interfaces.md` and ADR-006. Use the existing isolated checkout/feature branch.
2. `./tools/setup.sh` verifies installed Godot 4.6.3 and runs import/tests; it does not download dependencies. Ordinary regression: `./tools/check.sh`.
3. Play in the free Godot 4.6.3 editor or `./tools/run.sh` on a graphical desktop. Mac scripts accept `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`.
4. Read [PLAYER-GUIDE](PLAYER-GUIDE.md) for controls and career/combo rules. Settings includes saved bindings, mix, captions, reduced motion, sensitivity and UI scale.
5. Reproduce imagery with `tools/capture.sh`, `tools/visual_pass_capture.sh`, `tools/ui_feedback_capture.sh`, `tools/rider_capture.sh` and `tools/rider_motion.sh`. Linux wrappers own/stop their temporary displays; captures disable profile writes.
6. Run `tools/profile.sh` on a graphical desktop for bounded real-rendered metrics; [PERFORMANCE](testing/PERFORMANCE.md) gives Mac instructions and workload limits. Export locally with `tools/export.sh`; see [EXPORT](testing/EXPORT.md).

## Implemented and preserved

- Four connected, compressed original districts: Royal Exchange Square, George Square, Central Station and the Barras, with nine ramps, six rails, shortcuts, platforms, hidden court and visible cone interaction.
- Push/brake/steer, buffered/coyote ollie, flip/grab/spin, preserved takeoff momentum, obstacle-aware chase camera, rail and manual balance, reverts, two meter-gated specials and named swept-crossing gaps.
- One authoritative 0.35-second landing link window, repeat degradation/multiplier caps, one-time banking, pause/bail/restart guards and bounded three-second overtime.
- Two-minute career/free skate, ten goals, records, earned colours/specials and protected versioned local saves. Future/corrupt profiles are preserved; free skate never earns career progress.
- Original synthesized effects/contact loops/district ambience and three licensed local Flite NPC lines with captions/cooldowns. No runtime network or music dependency.
- Title/HUD/goals/pause/results/settings/remapping, keyboard and standard gamepad input. Physical DualSense remains untested.

## Second cleanup pass

Environment: distinct civic/retail/station/warehouse facade modules, doors/displays, roof variation, smooth arch bands and repaired sign/awning clipping. Two verified CC0 brick/concrete material sets add photographic albedo/normal detail with 1024px mipmapped imports; source/licence hashes and authored scale assumptions are recorded. Unit-mesh batching lowers matched chase-view draw calls by approximately 18%, 12%, 27%, 9% across the four districts; this alone is not a frame-rate claim. See [VISUAL_PASS](levels/VISUAL_PASS.md) and [VISUAL_ASSETS](research/VISUAL_ASSETS.md).

Rider: native ten-bone Skeleton3D, continuous jacket/trouser skin, refined proportions/board and input-driven action poses. Fixed foot-basis normalization drift, tumble body pivot, sleeve/waist gaps and manual board contact. Captures and a reproducible fixed-timestep 30 fps clip retain their fixtures/cuts; final anatomy and animation acceptance remain open.

UI/audio: separate goal and combo/link feedback, live device/remapped prompts, persistent save warnings, nested menu/focus/scroll return and long text/score sizing. Floor contacts now select stone/asphalt/metal wheel sound; nearby NPCs can react to a finished run. District visits no longer leave misleading collectible orbs. Capture tools verify the intended menu is visible, bounded and focused before accepting a PNG.

Routes: real production physics completes all ten goals in one circuit, 19,700 points/3,000 best combo, no bails/stalls. The ordinary focused result is 69.52s to all goals and 78.63s to return over 1,085.69m; six cross-district combo directions also pass. The driver directly aims grounded heading, so these are idealized feasibility results, not human speed/difficulty targets. Exact route and limits: [CAREER-ROUTES](testing/CAREER-ROUTES.md).

## Verification at this checkpoint

`./tools/check.sh`: **778 passed, 0 failed**, exit 0, clean import and engine/script logs after the final visual contact fix.

Fifteen standard 1280×800 gameplay/menu/district captures and dedicated matched world/UI/rider evidence are retained under `docs/testing/screenshots/`. Normal startup and modal readiness are checked separately from successful file writes. Linux Compatibility/llvmpipe rendering demonstrates the captured content; it cannot certify Mac performance, real-controller comfort, human listening or final art.

Unsigned Linux/macOS packages are built from clean source **`a99f9933091d8931853ef375a2c029cccb6875f2`**, the runtime that passed 778 checks. Both isolated probes load the main scene/scripts, three voices and four 1024px mipmapped textures. ZIP CRC, executable architectures, reviewed licences and provenance bytes pass. Metadata input fingerprint: `1ce6dff6927dd7b5fdb8c5845a0061ebea422f6159719d4e891adaabde38eb97`. Build directory: `builds/tam-hawks-20261017T141540Z-a99f9933091d/`; later documentation commits do not change that runtime.

| Download | Bytes | SHA-256 |
|---|---:|---|
| `/workspace/TamHawksProSkater-linux.zip` | 31,518,442 | `cac607b28acfa68bb623d7379a2ab4754f0d1134f266484ea7e076d7e0ffb81f` |
| `/workspace/TamHawksProSkater-macos.zip` | 66,077,978 | `2b5ca131c4b110305c9e25729eae100bc09a2644790b1292aaab915fd182b9b9` |

The exported Linux game passed normal headless startup (120 frames) and rendered 1920×1080 startup (30 frames), both exit 0 with clean engine/script/resource logs. The title is captured and reviewed. EXPORT preserves the earlier long software-render timeout and capture-harness diagnostics; neither is a target-performance pass. Mac launch remains untested. `/workspace/TamHawks-motion-preview.mp4` is the 7.4-second fixed-timestep animation preview, with explicit cuts/fixtures and no performance claim. `/workspace/tam-hawks-prototype-source.zip` contains the final committed source/docs; `/workspace/TamHawks-downloads-SHA256SUMS.txt` records convenience-file hashes. Ignored artifacts must be regenerated after environment replacement.

## Concrete remaining work

1. **M06-007 / M05 art cleanup:** refine generated sandstone/paving, repeated upper-storey/display props, skyline/connector joins, foliage and static NPCs; improve the skinned rider's face/hands and motion weight, especially grind/bail/transition coverage. Verified CC0 brick/concrete and varied facade modules are already integrated; do not recreate that work. Review all transitions at normal speed, bright/shaded HUD readability and 1080p scale. Current sources are `game/levels/city_art.gd`, `game/levels/art/`, `game/player/skater_visual.gd`, `game/player/skater_garments.gd` and `game/ui/hud.gd`. Preserve tested collisions. Follow ART_DIRECTION and VISUAL_ACCEPTANCE; final owner visual acceptance stays open.
2. **M03-006 / M03-007 current Glasgow frontages:** twelve dated historical business/address leads are preserved in GLASGOW_REFERENCES. They do not verify current occupants or corner/frontage geometry. Google Maps, Glasgow Life, Network Rail and Barras requests last returned proxy tunnel HTTP 403; local incognito Chrome is not connected. Saved domain configuration exists but this running machine remained blocked. Retry only after actual access/environment changes; do not repeatedly ask the owner to change the same settings. Record source/capture dates before building authentic shop borders. No paid Maps API or copied panoramas.
3. **M01-007 / M02-008 / M04-006 human playtest:** target Mac keyboard then real wired/Bluetooth DualSense; record input mappings, capture forgiveness, manual correction, 0.35-second links, special usability, camera comfort, complete ten-goal route and actual score distributions. CAREER-ROUTES supplies a verified automated circuit, with explicitly idealized ground steering; use it as a route reference, not a human timing target. Tune thresholds/routes from evidence. No automated test can certify fun or replay appeal.
4. **M05 listening:** headphones and speakers, motion/land/grind/bail/bank, district transitions, captions, mute and repeated NPC barks. Synthetic voice timbre and initial procedural audio need real listening feedback; no Glasgow accent is claimed.
5. **M06-004 / M06-005 / M06-006:** launch the unsigned universal app on an actual Mac, play offline, relaunch to verify saves, unplug/reconnect DualSense and profile the complete route at 1920×1080 on a declared Apple Silicon model. Use the exact `tools/profile.sh` Mac command in PERFORMANCE.md, then measure the separate moving ten-minute route. Target 60 fps/16.67 ms. Linux software rendering and Mach-O inspection cannot close these gates.
6. **M07 release:** resolve remaining functional/art/hardware findings; review title/signage and choose original-code/content licensing before granting public rights; verify final notices, archive checksums and release contents. No automatic release publication or paid signing.

All these have acceptance criteria, dependencies and next actions in BACKLOG. M04–M07 remain explicitly authored continuation of the source plan, which ends at M03; the owner has authorized proceeding through that work. No requirement was silently dropped.

## Continuity and limits

Saves are local `user://career.json`; development scripts use ignored `.local` XDG paths. Preserve unfamiliar future-version profiles. Tests/capture/profiling fixtures disable player persistence. Caches, export templates and build/video artifacts are ignored and may disappear when the environment is replaced; source scripts reproduce them.

No real Mac/DualSense, human listening, complete human goal/balance run or final owner visual review has occurred here. The world is stylized, original and compressed; composite shops are not verified current businesses. Skinned clothing is implemented, while production character/NPC quality remains unfinished. Keep M06-007 open.

Before ending a session, update STATUS and affected tickets with actual commands, defects and next edits, commit source/tests/docs and push the authorized feature branch. Do not make cloud configuration publication a recurring approval request or claim an unpublished draft is active.
