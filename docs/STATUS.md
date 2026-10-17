# Current handoff — 17 October 2026

**Project:** Tam Hawks Pro Skater. **Branch:** `bootstrap/m00-m01`. **State:** playable development alpha with the core gameplay, career, four districts, local audio and menus implemented. Initial procedural art remains below the requested final realistic finish. Use `git log -1` and `git status --short` to identify the exact checkpoint and preserve later changes.

The owner authorizes continuing through all ready tasks without routine approval requests. Hardware, current-reference and final creative acceptance remain evidence gates; proceed with independent implementation while they are open. No purchases, paid APIs, billing, hosted CI, infrastructure or unattended future work. Ordinary assistant work uses existing session credits.

Source and 54 full task records are kept on the [feature branch](https://github.com/AndrewM2304/tam_hawks_ps/tree/bootstrap/m00-m01). The original remote had no `main` or PR base; no PR, GitHub issues, hosted workflow or public release has been created. Read [the full backlog](planning/BACKLOG.md) before resuming.

## Resume and run

1. Read `AGENTS.md`, this file, `docs/planning/BACKLOG.md`, `docs/architecture/interfaces.md` and ADR-006. Use this isolated checkout and existing feature branch; preserve later edits.
2. Run `./tools/setup.sh` to verify installed Godot 4.6.3 and run import/tests. It does not download dependencies. `./tools/check.sh` is the ordinary regression command.
3. Play with `./tools/run.sh` on a graphical desktop, or open `project.godot` in the free Godot 4.6.3 editor. On macOS terminal scripts accept `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`.
4. See `docs/PLAYER-GUIDE.md` for controls and the combo/career loop. Settings includes keyboard/gamepad rebinding, mix, captions, reduced motion, camera sensitivity and UI scale.
5. `./tools/capture.sh` reproduces actual rendered evidence on this Linux image using a temporary Xorg dummy display and software OpenGL; it stops its own display on exit. See QE-REPORT for scenarios and limits.
6. `./tools/export.sh` creates local unsigned Linux/macOS packages with official checksum-verified templates. It uses only ignored `.local/` and `builds/` paths. See `docs/testing/EXPORT.md` for exact artifact evidence and Mac limits.

## Implemented

- One connected, compressed original interpretation of Royal Exchange Square, George Square, Central Station and the Barras: nine ramps, six authored grind rails, district entrances, northern shortcuts, elevated platforms and a hidden alcove. World queries expose district, goal and gap metadata. Actual cone interaction visibly tips/pops the cone and resets safely.
- Push/brake/steer, buffered/coyote ollies, flip/grab/spin, momentum-preserving takeoff and wall contact, obstacle-aware follow camera, rail acquisition/travel/balance and manual balance. Failure drops the active combo; ordinary heading-only ground landings remain forgiving.
- A single **0.35-second landing link window** owned by ScoreSession. Manual, rail or ollie links retain the combo; one eligible revert reduces speed without extending the deadline. Clean expiry banks once. Pauses freeze state and overtime is bounded at three seconds with new entries disabled.
- Repeat degradation, capped distinct-trick multipliers, two airborne specials requiring bank-earned charge, career unlock checks, named swept-crossing gaps, anti-teleport/timeout/rearm guards and explicit restart/bail resets.
- Two-minute career runs and free skate; ten goals for score tiers, combo, HAWKS letters, cone, station gap, market items, four districts and hidden recording. Earned goals, records, colours, specials, settings and bindings persist locally. Free skate does not progress career or records.
- Validated versioned JSON saves, verified temporary writes, backup recovery and atomic replacement. Future-version or unrecoverable files are protected from overwriting; explicit recovery archives files. Developer tests use isolated fixtures and disable player-profile writes.
- Title/mode choice, gameplay HUD, rail/manual balance, link/special feedback, goals/unlocks/colour selection, pause/results, scrolling settings and control remapping. Keyboard and standard gamepad events are covered; physical DualSense remains untested.
- Original cached PCM effects, wheel/grind loops and four abstract ambience beds; three licensed locally generated Flite NPC lines with captions and cooldowns. No music, paid generation or runtime network dependency. Listening acceptance remains open.
- Initial architectural materials/facade detail, rooflines, civic clock/portico, station canopy, dressed market, original rounded articulated rider and detailed board. Push/landing/grab animation is implemented. This is procedural initial artwork, not final realistic art acceptance.
- Free export tooling, pinned template/runtime-notice verification, unsigned universal Mac and Linux presets, provenance packaging and player guide.

## Verification at this checkpoint

`./tools/check.sh` completed successfully: **717 assertions passed, 0 failed**, clean import and no scanned engine/script errors, exit 0. `./tools/capture.sh` completed successfully: **15 real 1280×800 images**, all save results 0, script exit 0. Reviewed images are committed under `docs/testing/screenshots/`; exact scenarios and limitations are in `docs/testing/QE-REPORT.md`. `docs/testing/EXPORT.md` carries the package results. The previous committed baseline `07ec43a` had 260 assertions; the first broader integration passed 615.

Automated checks exercise production physics/input/signals, combo boundaries, world support and connector sweeps, actual Central gap traversal, objective interactions, persistence faults, input remapping, settings and menu navigation. They do not establish physical controller feel, real Mac launch, sound quality or target-machine performance. Rendered screenshots use Mesa llvmpipe at 1280×800, Compatibility renderer, 2× MSAA; authored district overview cameras are scenery evidence rather than full player-route acceptance.

## Downloadable build checkpoint

Unsigned test packages were produced successfully from clean commit **`13e76aca241f5603c5ecbe52623f30d60e9ee842`** with the same gameplay that passed 717 checks. The packaging follow-up changes export selection and resource auditing only. Both isolated data-pack probes load/instantiate the main scene and all three voice streams; the macOS binary contains arm64 and x86_64 slices. Required engine, rail-helper and Flite notices are verified in each ZIP.

Local build directory: `builds/tam-hawks-20261017T130506Z-13e76aca241f/`. Each package contains a player guide, build metadata, resource inspection and notices. `SHA256SUMS.txt` records digests. Convenient copies and the latest source archive are at `/workspace/TamHawksProSkater-macos.zip`, `/workspace/TamHawksProSkater-linux.zip` and `/workspace/tam-hawks-prototype-source.zip`. The final documentation checkpoint may be newer than the package commit; runtime code is unchanged.

Mac ZIP: 62,100,941 bytes; SHA-256 `1ec905891b87aa1a727f98bc61d294fccf6362b75dcf11c26e8144f1efaebf44`. Linux ZIP: 27,541,414 bytes; SHA-256 `3e215cf25c5da4b1ea832e84cad42bde03bc271ab0035b76ff11c501710fa1b7`. The exported Linux game passed normal headless and actual 1920×1080 graphical startup, both exit 0 with no script/resource errors. The title capture is `docs/testing/screenshots/standalone-title-1080.png`; temporary game/display processes were stopped. Mac launch remains untested. See EXPORT.md for exact smoke commands and the expected dummy-display V-Sync warning. The initial failed package attempt was corrected before these ZIPs were produced.

## Concrete remaining work

1. **M06-007 / M05 art cleanup:** replace repeated foreground facade/shop modules with researched variants and convincing materials; refine skyline/border continuity, street detail and lighting; evolve the articulated primitive-derived rider into a convincing character with better joint/clothing/hand animation. Review all transitions at normal speed, bright/shaded HUD readability and 1080p scale. Current sources are `game/levels/city_art.gd`, `game/player/skater_visual.gd` and `game/ui/hud.gd`. Preserve tested collisions. Follow ART_DIRECTION and VISUAL_ACCEPTANCE; final owner visual acceptance stays open.
2. **M03-006 / M03-007 current Glasgow frontages:** twelve dated historical business/address leads are preserved in GLASGOW_REFERENCES. They do not verify current occupants or corner/frontage geometry. Google Maps, Glasgow Life, Network Rail and Barras requests last returned proxy tunnel HTTP 403; local incognito Chrome is not connected. Saved domain configuration exists but this running machine remained blocked. Retry only after actual access/environment changes; do not repeatedly ask the owner to change the same settings. Record source/capture dates before building authentic shop borders. No paid Maps API or copied panoramas.
3. **M01-007 / M02-008 / M04-006 human playtest:** target Mac keyboard then real wired/Bluetooth DualSense; record input mappings, capture forgiveness, manual correction, 0.35-second links, special usability, camera comfort, complete ten-goal route and actual score distributions. Tune thresholds/routes from evidence. No automated test can certify fun or replay appeal.
4. **M05 listening:** headphones and speakers, motion/land/grind/bail/bank, district transitions, captions, mute and repeated NPC barks. Synthetic voice timbre and initial procedural audio need real listening feedback; no Glasgow accent is claimed.
5. **M06-004 / M06-005 / M06-006:** launch the unsigned universal app on an actual Mac, play offline, relaunch to verify saves, unplug/reconnect DualSense and profile the complete route at 1920×1080 on a declared Apple Silicon model. Target 60 fps/16.67 ms. Linux software rendering and Mach-O inspection cannot close these gates.
6. **M07 release:** resolve remaining functional/art/hardware findings; review title/signage and choose original-code/content licensing before granting public rights; verify final notices, archive checksums and release contents. No automatic release publication or paid signing.

All these have acceptance criteria, dependencies and next actions in BACKLOG. M04–M07 remain explicitly authored continuation of the source plan, which ends at M03; the owner has authorized proceeding through that work. No requirement was silently dropped.

## Continuity and limits

Save progress is local (`user://career.json` under Godot's platform data path; scripts supply ignored `.local` XDG directories). Do not overwrite unfamiliar future-version profiles. Saves are not cloud accounts.

No real Mac/DualSense or final visual/feel/listening review has run. Standard gamepad injection is synthetic evidence. The world is an original compressed interpretation; generic shop names are not verified real locations. There is no sculpted/skinned production character, commercial music, street reconstruction or release-quality claim.

Before ending a session, update STATUS and affected tickets with exact commands, defects and next edits; commit source/tests/docs together and push the authorized feature branch. Keep caches/builds/credentials out of Git. Source archives and packages are local artifacts; future work must not rely on ignored caches surviving. Do not make cloud configuration publication a recurring task approval or claim an unpublished draft is active.
