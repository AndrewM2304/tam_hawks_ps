# Verification strategy

A local test pass is evidence for the tested behaviour and environment, not a blanket release approval. `docs/STATUS.md` holds the latest exact commands/results. Tickets require evidence tied to their acceptance criteria.

## Required local gates

- Import the Godot project with the pinned engine; fail on parser errors, missing resources and invalid scene references.
- Run focused unit and integration checks that return nonzero on failure and report the number of assertions/cases.
- Exercise deterministic scoring, input-edge handling, reset and pause/timer transitions. Add physics simulations for movement and collisions as the controller stabilises.
- Run a short startup smoke test. A process starting headlessly alone does not prove that the skater works or the rendered frame is readable.
- Capture a real frame for visual changes; inspect HUD legibility, world framing and missing geometry. Record a rendering blocker explicitly when no display/backend is available.
- Check `git diff --check`, provenance updates and the intended file list. Do not commit `.godot`, temporary engine installations, logs or local saves.

Use `tools/check.sh` as the local entry point. Hosted CI is deferred to preserve the owner's no-additional-spend instruction. Adding a workflow later requires explicit zero-cost authorization and a review of runner billing, not an assumption that an account's quota is free.

## Risk-focused test matrix

| Area | Automated evidence | Human / platform evidence |
|---|---|---|
| Movement | Acceleration/braking bounds, reset, floor and ramp contact, finite transforms | DualSense responsiveness, comfortable turning and camera |
| Aerial tricks | Fresh button edges, allowed states, one award per action | Visible timing, recognisable movement, forgiving feel |
| Combos | Degradation, multiplier, banking once, bail loss, overflow limits | Continuous lines feel satisfying and readable |
| Runs | 120-second active timer, pause, free skate, restart, result transitions | Fast restart and unambiguous UI |
| World | Scene/collision validity, checkpoint reachability where simulated | Skate every line; inspect snags, dead ends and camera occlusion |
| Missions | Completion once, resets, score boundaries, mode eligibility | Wording and objective discoverability |
| Saves | Round trip, version migration, corrupt/missing file recovery | Real platform path/permissions, restart retention |
| Input / UI | Action coverage, focus transitions and settings bounds | Wired and Bluetooth DualSense, disconnect/reconnect, keyboard-only play |
| Audio | Event routing, missing file checks, volume state | Levels, fatigue, captions and voice intelligibility |
| Performance | Logged frame/physics metrics in a fixed route | Apple Silicon 1080p, at least 10 minutes with all districts active |
| Release | Export file/reference inspection when templates available | Actual macOS app launch, first-run prompts, offline play, resume |

## M01 human controller gate

Required owner playtest: start a run using a real DualSense on the target Mac; skate for five minutes; accelerate, brake, steer, ollie, flip, grab and spin; traverse ramps; pause, restart and try free skate. Record device model, connection method, macOS version, resolution and engine/build identifier. Ask for ratings and concrete observations on steering, jump timing, landings, camera and the desire to replay. A material feel problem blocks the M01 exit until a follow-up build is tested.

Linux simulations and virtual gamepad input cannot substitute for this gate. Independent preparation for M02/M03 may continue, but completed milestone status must remain honest.

## Performance and release gates

The target is 60 fps at 1080p on Apple Silicon. M06 must choose a declared baseline Mac and report frame-time distributions, resolution, power mode, test route, duration and build identifier. Aim for stable 16.67 ms frame budgets; do not publish a performance claim from an empty scene or unrepresentative machine. Investigate visible stutters and worst-case district density even when average fps is high.

M07 requires every Release 1 requirement to have passing evidence or an explicit owner-approved scope change, no critical/high-severity defects, a successful local save round trip, a full career/free-skate pass, and a macOS app launch from the packaged artifact. Signing/notarization that would require paid enrollment is blocked by the budget; record and explain the free distribution path without claiming a signed release.

## Defect and evidence format

Record task/build, platform, steps, expected and actual behaviour, reproducibility, severity and evidence path. Severity: critical = crash/data loss/no start; high = core mechanic or goal unusable; medium = material but avoidable issue; low = cosmetic. A09 owns independent review and must not weaken production rules to pass tests. Keep test-only fixes separate from behaviour decisions.
