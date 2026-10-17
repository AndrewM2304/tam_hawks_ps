# Current handoff — 17 October 2026

**Tam Hawks Pro Skater** is a playable Godot 4.6.3 development alpha on branch `bootstrap/m00-m01`. The final checked runtime is committed as **`a30127940eacd4d2fe56d07a34ee1af4bacf95e5`**, following the `bd12b61` terrain/adult-rider foundation. The nonlinear routes and Glasgow encounter pass **955 checks, 0 failures**, with corrected source-stable imagery independently reviewed. Both native packages are rebuilt/audited and normal Linux startup passes; later handoff-only commits preserve that runtime. Final realistic graphics, human fun and target-hardware acceptance remain open.

The owner authorizes ready work without recurring approvals. No purchases, paid APIs, billing, hosted CI, infrastructure or unattended agents. The [feature branch](https://github.com/AndrewM2304/tam_hawks_ps/tree/bootstrap/m00-m01), [75 complete task records](planning/BACKLOG.md), decisions, tests and research preserve continuity. No public release, remote issues or PR were created; the original repo had no `main`/PR base.

## Resume and run

1. Read `AGENTS.md`, this file, [BACKLOG](planning/BACKLOG.md), [RESUME](planning/RESUME.md), [interfaces](architecture/interfaces.md) and ADR-007/008. Check branch/status and preserve later edits. Use this checkout; no worktree is needed.
2. `./tools/setup.sh` verifies the installed free Godot 4.6.3 and runs import/checks. It does not download dependencies. Ordinary regression: `./tools/check.sh`.
3. Open `project.godot` in Godot and press F5, or run `./tools/run.sh` on a graphical desktop. On Mac, scripts accept `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`.
4. [PLAYER-GUIDE](PLAYER-GUIDE.md) covers keyboard/controller input, careers, combos, route map and Mo. Settings saves bindings, mix, captions, reduced motion, sensitivity and UI scale.
5. Reproduce the current 21-frame world/NPC set with `./tools/level_design_capture.sh --private-display`; rider poses/motion use `tools/rider_capture.sh` and `tools/rider_motion.sh`. Fixtures disable profile writes. [PERFORMANCE](testing/PERFORMANCE.md) distinguishes old bounded measurements from untested new-area performance.
6. Local unsigned packages use `tools/export.sh`; [EXPORT](testing/EXPORT.md) records provenance and real package/startup evidence. `tools/native_smoke.sh /absolute/build/directory` checks bounded normal Linux startup.

## Implemented at this checkpoint

- Six connected original Glasgow-inspired areas: Exchange/gallery, George Square, station, Barras, Clyde Quays and Kelvingrove-inspired hills. Real ground spans 0–17 m, with graded streets, terraces, stairs/ledges, fountain coping, an 8 m river jump, safe alternate bridge, supported quay recovery and rolling park paths.
- A genuinely suspended station deck with a lower undercroft; angled Merchant Close and a lower service court with two escape banks; a second park descent/rejoin; a south-Clyde yard loop, low grind ledge and sampled 35° curved bank/rounded hip. The map shows six checkpoints and 28 authored routes. This bank does not implement vert/lip mechanics.
- Adult CC0 anatomical head/scalp/hands under original skinned clothing, shoes and board; original irregular foliage, varied composite facades and verified CC0 brick/concrete materials. No full unclothed body or MakeHuman program is shipped.
- Mo’s Big Finish: deliberate nearby interaction, 35 active seconds, one clean bank of at least 1,000 with three different trick families in the court; failure, replay, pause and restart handling. Original fictional busker, guitar/case, captions and quiet spatial synthesized plucks. Completion adds no separate career award; normal skating still scores normally. Four other local encounter ideas are explicitly Planned.
- Existing skating/combo, two-minute career/free skate, all ten goals/save IDs, records/unlocks, protected local saves, configurable input/audio/UI, original skating sounds and licensed local Flite barks remain covered.

The [lead design review](levels/LEAD-DESIGN-REVIEW.md) compares inspected classic-level guides with actual production geometry and screenshots. It takes a senior skate-game design perspective without claiming franchise employment. [Classic-level research](research/CLASSIC-LEVEL-DESIGN.md), [Glasgow character research](research/GLASGOW-CHARACTERS.md) and [GLASGOW-FUN](product/GLASGOW-FUN.md) separate source facts from original adaptations. No proprietary map, music, voice or real-person likeness was copied.

## Verified evidence

`./tools/check.sh` completed **955 passed, 0 failed**, exit 0, with clean import/engine/script logs. A final editor import and source-stable capture verified the last local-place caption correction. Durable logs: [aggregate](testing/logs/glasgow-nonlinear-final.log) and [import](testing/logs/glasgow-nonlinear-import.log). [QE-REPORT](testing/QE-REPORT.md) records scope and limitations.

The final focused nonlinear/outdoor check passes 30/0; the local real-input ledge/air/manual combo banks exactly 5,000 once, 3/0. Encounter checks pass 30/0, including actual 1,950-point three-family success and replay/failure guards. The ordinary ten-goal circuit completes all goals in 75.20 simulated seconds and returns in 88.00, travelling 1,199.52 m for 20,000 points/3,200 best with zero bails/stalls. Direct grounded heading is an explicit driver idealization, not a human timing, difficulty or fun claim.

The corrected [21 actual rendered frames](testing/screenshots/level-redesign/README.md) passed source fingerprinting and independent lead/geometry review. They resolved the exposed close void, obstructed park fork, sharp verge and misleading local labels. Manifest SHA-256: `f0b3a30987a7731371ebb4b74102751dfbdfd192194a7db7b574669ba5b0674b`; six checkpoints, 28 routes, 98 source inputs. Initial diagnostic images remain separately labelled. Broader rectangular courts, repeated/sparse edges, abrupt material joins and the outer skyline remain art work.

The refreshed `/workspace/TamHawks-motion-preview.mp4` is 6,640,769 bytes, SHA-256 `ac2bcb0ea3ba385ea9d03e2107f5d03312b6f54287f47bcf1ce41f4469fb2f54`. It is a silent 7.4-second H.264 preview, 222 frames at 30 fps; full decode and 97 unchanged input hashes pass. Cuts, fixtures and limits are declared in [RIDER-REALISM](testing/RIDER-REALISM.md). This is animation evidence, not a performance benchmark.

## Native/source downloads

`./tools/export.sh --prepare` and `./tools/export.sh --skip-check` both completed exit 0. The export uses clean runtime **`a30127940eacd4d2fe56d07a34ee1af4bacf95e5`**, whose unchanged gameplay already passed the suite above. Build: `builds/tam-hawks-20261017T155310Z-a30127940eac/`; 105 package input hashes, fingerprint `5c763454af485ccdabade16e5b0ed3aa4aa664a8e6e1b724aa238c1f3c442602`. Both probes instantiate the main scene and load three voices, four mipmapped 1024px textures and all four head/scalp/hand meshes. Both ZIPs pass CRC, executable architecture/permission and 13-notice/provenance checks. The input fingerprints also match the final world/motion capture inputs where they overlap.

| Download | Bytes | SHA-256 |
|---|---:|---|
| `/workspace/TamHawksProSkater-linux.zip` | 32,015,059 | `8e13443bde9d70a897c1814940fa7ed5713011b1496a9415ab7a893af01c1dea` |
| `/workspace/TamHawksProSkater-macos.zip` | 66,574,593 | `44e780c9d271ea8f21ca127d8009a97767be8f4d2ee7d80bd4e11cfcbba5a81b` |

`./tools/native_smoke.sh /workspace/tam_hawks_ps/builds/tam-hawks-20261017T155310Z-a30127940eac` passed exit 0: normal Linux main scene, isolated profile, headless 120 frames and rendered 1920×1080 30 frames. Both logs are clean; software display V-Sync is the sole warning. This is startup evidence, not a frame-rate, audible-output or Mac test. Durable metadata/resource/startup receipts are in [native-redesign](testing/native-redesign/README.md); [EXPORT](testing/EXPORT.md) contains exact verification and historical diagnostics.

The Mac app is unsigned, unnotarized and not launch-tested on Mac. `/workspace/tam-hawks-prototype-source.zip` contains the final committed source/docs; `/workspace/TamHawks-downloads-SHA256SUMS.txt` records Linux, Mac, source and motion digests. The native package identity above remains the runtime commit even when the source archive includes later handoff-only commits. Ignored artifacts must be regenerated after environment replacement. Earlier `a99f993` packages are historical.

## Concrete continuation tasks

1. **M06-007 / M05-001 / M05-006:** reshape remaining broad core-court edges/quiet approaches into coherent architectural islands, graded corners and readable low-ledge/bank chains. Refine Merchant retaining materials, yard planting/paving, park aprons, repeated facades, horizon, actor anatomy/clothing and motion weight. Preserve supported routes, save IDs and checked scoring. Capture matched chase/overview/action frames and recheck collision/camera changes. Production realism and owner acceptance stay open.
2. **M03-006 / M03-007:** verify current shopfronts and street relationships from accessible dated sources before adding authentic businesses. Prior Google Maps/StreetView/official requests were proxy-blocked; local incognito Chrome is not connected. Accessible classic/culture sources were inspected this turn. Do not repeatedly retry unchanged blocked endpoints or use paid Maps APIs/copied panoramas.
3. **M02-011 / M02-012 / M03-015 / M02-013:** bounded prototypes for proper curved transition/vert/lip behavior, wallride/wallie, one reversible changing-route event and a later skitch/traffic assessment. These mechanics are not enabled. Each ticket defines dependencies, acceptance and tests; no broad controller rewrite is assumed.
4. **M04-008–011:** four specified local prototypes: recoverable foam-cone river stunt, mechanical-cat coping sequence, market parcel line and alternative park lap. Preserve the normal ten-goal/save contract. Human tone, discovery and replay appeal guide later tuning.
5. **M01-007 / M02-008 / M04-006 / M05:** human Mac keyboard then physical wired/Bluetooth DualSense playtest, camera/turning/balance/link forgiveness, ten-goal discovery/pacing, Mo, sound/mix/caption and local-dialogue review. Automated feasibility and dummy-audio checks cannot close these gates.
6. **M06-004–006:** launch the unsigned universal app on an actual Mac, verify offline play/save relaunch/controller reconnect, then measure complete moving routes at 1920×1080 on a declared Apple Silicon model. Target 60 fps/16.67 ms; Linux software rendering and binary inspection cannot establish it.
7. **M07:** preserve this completed source-bound package/handoff checkpoint, then resolve actual remaining art/hardware/playtest findings, title/rights/release review and original-content licence before any public distribution. No paid signing or automatic publication.

## Continuity

Saves live at `user://career.json`; development scripts use ignored `.local` XDG directories. Preserve future/corrupt profiles and backup recovery. Caches, templates, exports and videos are ignored and may disappear with environment replacement; committed scripts reproduce them. Before ending a session, update affected tickets and STATUS with actual results/defects/next edits, commit and push the authorized feature branch. Missing human evidence is a recorded gate, not a routine approval request.
