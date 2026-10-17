# Current handoff — 17 October 2026

**Project:** Tam Jaws Pro Skater (working title). **Branch:** `bootstrap/m00-m01`. **State:** a working M01 prototype, ready for its first human skating playtest. This is an initial slice, not the full Release 1 game. `git log -1` identifies the latest checkpoint; all work stays on the feature branch.

## Start or resume

1. Read `AGENTS.md`, this file, `docs/planning/BACKLOG.md`, and `docs/architecture/interfaces.md`.
2. Run `git status --short` and preserve any later work. Use the existing checkout; no extra worktree is needed.
3. Run `./tools/setup.sh` in the repository root. It verifies the already installed Godot 4.6.3 and executes the import/test checks. No package download, paid service, secret or server is required.
4. Play with `./tools/run.sh` on a graphical desktop. On macOS, install the free official Godot 4.6.3 editor, import `project.godot`, and press F5 to run the project. For terminal scripts, set `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot` if that is the installed path. The cloud machine is Linux; there is no native Mac build yet.
5. Reproduce screenshots with `./tools/capture.sh`. On this Linux image it starts an installed Xorg dummy display, uses software OpenGL, captures three frames and stops its display process. On a graphical desktop it uses the existing display. Outputs are `.local/prototype.png`, `.local/air-tricks.png`, and `.local/pause-menu.png`.

## Implemented

- Original procedural Glasgow-inspired Exchange Square, sandstone facades, fictional shop names, four skateable ramps, ledges, rail props, boundaries and an original cone-topped statue. Rail props do not support grinds yet.
- Arcade acceleration/braking/steering, buffered/coyote ollies, kickflip, melon-grab pose, scored spins and forgiving landings. Original primitive rider/board and a smoothed obstacle-aware chase camera.
- Aerial combo preview, unique-trick multiplier, repeat degradation, bank-on-landing, out-of-world recovery, session score and best combo.
- Two-minute runs with bounded landing grace, free skate, pause/results, fast restart, HUD, and standard gamepad plus keyboard bindings. Training prompts are temporary session hints, not persistent career goals.
- Dependency-free automated tests, a screenshot runner, local issue/PR templates, product requirements, architecture decisions, provenance register and 48 detailed release tickets.

## Verified evidence

| Check | Observed result |
|---|---|
| Engine | Preinstalled `4.6.3.stable.official.7d41c59c4`; no engine artifact downloaded or upstream checksum comparison claimed |
| `./tools/check.sh` | Clean Godot import; **94 assertions passed, 0 failed**, exit 0 |
| `./tools/setup.sh` | Same pinned-toolchain/import/test path executes successfully; safe to repeat |
| Physics/integration | Movement, jump/held-button behavior, flip/grab/spin scoring, bank/drop/reset, four ramp surface normals, two actual ramp traversal routes, boundaries, pause, restart, mode switches and timer overtime |
| Failure detection | Temporary runner invoked the actual assertion helper with a deliberate failure; explicit FAIL and exit 1 observed; probe removed |
| Rendered evidence | Real 1280×800 software OpenGL captures; reviewed by orchestrator, gameplay/world specialists and independent QE |
| Local dependencies/services | No plug-ins, third-party game assets, network runtime, credentials, asset purchases or paid API calls |

See `docs/testing/QE-REPORT.md` for exact coverage and limitations. Logs in `.local/` are reproducible and ignored. Reviewed screenshots are checked into `docs/testing/screenshots/`. Early overexposed lighting and a clipped speed gauge were fixed during visual review.

## Next concrete work

1. **M01-007 — owner playtest on Mac + DualSense.** Play the central launch ramp and tenement return loop for several runs. Record keyboard vs wired/Bluetooth controller, turn sensitivity, jump timing, landing forgiveness, camera comfort and whether another run is appealing. Use `docs/testing/STRATEGY.md`; record actual results instead of treating synthetic input as hardware proof.
2. Fix any concrete feel/input/camera defects from that playtest under M01-001–006. The current automated baseline is 94 assertions; add focused regressions where meaningful.
3. **M02-001 — trick-state/input specification.** Independent specification work can start while hardware feedback is pending. Agree grind acquisition, manual balance, revert window, combo continuation and bail rules before implementing M02-002–006. Do not mark M01 or M02 accepted without their human gates.
4. Follow the dependency graph in the backlog. Full four-district level is M03; career goals/saves/unlocks M04; art/audio/NPCs M05; accessibility/hardware/performance M06; packaging/release M07. M04–M07 are explicitly proposed continuation because the supplied paste stops at M03.

## Known limits and outstanding gates

- No physical DualSense, macOS export/launch or Apple Silicon 60-fps/1080p test has run. The Linux software-rendered frames establish visibility, not target performance.
- Landings deliberately succeed at all headings. Spins are cosmetic and score on landing without changing travel heading; grab is a crouch pose. Advanced bail rules and animations remain work.
- No grinds, manuals, reverts, special tricks, named gaps, career missions, persistent records/saves, unlocks, interactive cone, secrets, ambient NPCs, sound or music yet. No full four-district level yet.
- No standalone distributable or paid signing/notarization setup exists. Free source-project play is the current route; do not buy Apple enrollment or voice services.
- No hosted CI or unattended agents are enabled. Existing in-session assistant credits are still consumed normally; no system here schedules future paid work.
- Ticket files and templates are local records, not published GitHub issues. Never infer a PR or remote branch exists without checking Git.

## Checkpoint discipline

Before ending the next session, update this file and the affected tickets with exact results, defects, files, dependencies and next steps. Commit source, tests, decisions and handoff together on the feature branch. Keep `.godot/`, `.local/`, builds and credential files out of commits. Preserve original plan and no-spend constraints. Environment draft publication and fresh-task restoration are separate from current-instance validation.
