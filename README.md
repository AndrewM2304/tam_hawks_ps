# Tam Hawks Pro Skater

An original arcade skateboarding game in a fictionalised Glasgow, built with Godot 4.6.3. Link aerial tricks, grinds, manuals and reverts across six connected city, river and park areas, chase ten career goals, or explore in free skate. Take Mo’s guitar challenge, join Rae’s bin-drum and dancing-cat act, or deliver Mairi’s breakfast parcel through the Barras market.

**Current stage: playable development alpha.** The complete core loop, local saves, original sound, menus and a substantial terrain and adult-rider redesign are implemented. Final realistic visual polish, verified current Glasgow shopfronts, physical DualSense testing and Mac performance acceptance remain open. [Current status](docs/STATUS.md) records exact evidence and remaining work; [the QE report](docs/testing/QE-REPORT.md) separates automated checks from human acceptance.

## Play and develop

**Use `main`:** it is the GitHub default and contains the combined work and latest playtest fixes. The former `bootstrap/m00-m01` default was renamed; `work` is retained history. Work directly on `main`; do not create feature branches or worktrees.

- From source, open `project.godot` with the free Godot 4.6.3 editor and press F5, or run `./tools/run.sh` on a graphical desktop. The launcher prepares imported assets and script classes before play, including on a fresh download; preparation errors stop launch and remain in `.local/source-import.log`.
- Run `./tools/setup.sh` to verify the installed engine and check the project. Run `./tools/check.sh` after gameplay changes.
- Verify a fresh source launch with `python3 tools/source_launch_smoke.py`. Reproduce ordinary title-to-play, moving controls, chase framing and repaired level edges with `./tools/playability_capture.sh --private-display`. The earlier Exchange/gallery recipe is `./tools/level_design_capture.sh`; earlier images and motion clips retain their historical source provenance.
- Measure six rendered city/river/park views with `./tools/profile.sh`; [profiling instructions](docs/testing/PERFORMANCE.md) cover the Mac command and measurement limits.
- Build unsigned local Linux/macOS packages with `./tools/export.sh`; it downloads free official templates and verifies their pinned checksum. See [export instructions](docs/testing/EXPORT.md).

The [player guide](docs/PLAYER-GUIDE.md) explains controls, combo links, specials and career progression. Default keyboard controls are W/A/S/D, hold/release Space to ollie, direction + J/held K for flip/grab, A/D or Q/E for air spin, tap L to lock a rail (tap again to drop), M for manual, C to revert and U/I for specials. Tab opens goals; Escape pauses. Controls can be rebound in Settings. Physical DualSense mappings remain a hardware test requirement.

Six flips, five held grabs, Manual/Nose Manual and four lip poses now have distinct original animation. A real quarter-pipe and half-pipe sit on the existing Clyde north quay. Hold Grind near the coping for a lip; balance left/right, release to drop or hold/release Ollie to pop. The [classic-control handoff](docs/planning/CLASSIC-TRICKS-NEXT.md) and [verification report](docs/testing/CLASSIC-TRICKS.md) cover the current implementation and remaining human/art gates.

On macOS, source play uses the official editor; terminal scripts accept `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`. Standalone macOS packages are unsigned universal test builds, with launch and Apple Silicon performance still unverified. No paid signing is required for development.

Settings includes a saved **Graphics** choice: **Performance** uses 75% 3D resolution, 220m view distance, 30m shadows and no MSAA; **Balanced** defaults to native 3D resolution, 220m view distance, 45m shadows and 2× MSAA; **High** extends shadows to 75m at the same native resolution, view distance and anti-aliasing. HUD and menus stay native. These choices change rendering budgets while retaining the same chase framing and active connected-map gameplay. The [performance guide](docs/testing/PERFORMANCE.md) explains measurement; target-Mac frame-rate acceptance remains open.

## Personal Mac soundtrack

**Soundtrack** uses the account already signed into your Mac's Music app. The default is [Tony Hawk Pro Skater by Alex Troyan](https://music.apple.com/gb/playlist/tony-hawk-pro-skater/pl.u-jV89Dq9t27eY8): add it to Music's library once and it shuffles when you start skating. Pause shows current song, artist, album and available artwork with play/pause and skip. Autoplay can be turned off or another library playlist selected; game pause/restart preserves the song. [Setup and Mac verification limits](docs/PLAYER-GUIDE.md#your-apple-music-soundtrack-mac). Actual Mac playback and Automation consent remain unverified; current combined-source validation belongs in STATUS.

## Visual direction and Glasgow

The owner requires polished UI and believable, detailed, realistic-but-fun graphics. The cleanup pass adds verified CC0 brick/concrete textures, varied facade modules, terraced streets, fountain coping, Clyde bridge transfers, hilly park paths, a CC0 anatomical head/hands, skinned clothing and a route map. Final cleanup remains tracked in **M06-007**. See [art direction](docs/product/ART_DIRECTION.md), [visual acceptance](docs/testing/VISUAL_ACCEPTANCE.md) and [level design](docs/levels/DESIGN-BRIEF.md).

The [level-design review](docs/levels/LEAD-DESIGN-REVIEW.md) studies the classic city/School references and tracks the implemented undercroft, angled close, park return, riverside curved-bank loop and civic-garden/market-hall pockets. [Glasgow performer research](docs/research/GLASGOW-CHARACTERS.md) informs original fictional locals and [playable/future side challenges](docs/product/GLASGOW-FUN.md).

The six areas interpret Royal Exchange Square, George Square, Central Station, the Barras, Clyde quays and Kelvingrove-inspired parkland. Inspected Barrowland/market and South Portland/Carlton Place references inform their original compressed geometry. The Exchange/gallery continuation adds architectural banks, seating edges and an original GoMA-inspired eight-column entrance with joined plinths and thresholds. Ten career goals retain their four-city-district identities; river and park routes are open to explore. Current business occupants and exact frontage relationships still need accessible primary/map references. The [Glasgow dossier](docs/research/GLASGOW_REFERENCES.md) records dated evidence and its limits. No Street View imagery is bundled.

## Continuity and reuse

[76 full task records](docs/planning/BACKLOG.md) retain ownership, dependencies, acceptance criteria, validation and remaining work. Read [the handoff](docs/STATUS.md), [resume guide](docs/planning/RESUME.md) and [agent instructions](AGENTS.md) before continuing. The owner authorizes autonomous progress through ready tasks without recurring routine approvals. Human/hardware acceptance remains an evidence requirement.

Godot supplies the engine facilities. An inspected MIT rail-geometry helper was adapted from Not Pro Skater, with full attribution and regression tests; the [reuse research](docs/research/SKATING_REUSE.md) records what was inspected and reused. Original project code integrates the mechanics and progression. The [provenance register](docs/licences/REGISTER.md) records original geometry/audio, locally generated Flite voice lines, two CC0 photo-based material sets, cropped CC0 MakeHuman anatomy and third-party notices.

## No additional spend

No purchases, paid APIs, billing, hosted CI, hosting or unattended agents are used. All runtime gameplay and saves work locally without accounts. Normal assistant work consumes the owner's existing credits; durable source and tasks support resumption after a session ends.

The game does not reuse commercial skating-game assets, layouts, music or branding. The owner has not yet selected a public licence for the original project; the engine's MIT licence does not assign one to the game.
