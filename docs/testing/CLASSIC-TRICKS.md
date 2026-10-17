# Directional tricks and transition verification

17 October 2026. The current slice adds directional flips/grabs, both manuals, four coping poses, release-pop Ollies, latched rails and real quarter/half-pipes to the existing Clyde quay. [ADR-015](../architecture/decisions/ADR-015-directional-tricks-and-transitions.md) records the contracts; [PLAYER-GUIDE](../PLAYER-GUIDE.md) is the binding specification. [STATUS](../STATUS.md) records the final ordinary count and tested source. No new district, paid tool, proprietary animation or upstream asset was added.

## Evidence and limits

| Check | Actual scope |
|---|---|
| Required `./tools/check.sh` | Full ordinary production regression, clean import and nonzero result/exit checks. Final count and complete logs in STATUS. Focused counts below are included, not additional passes. |
| Pure selector/animation/geometry/transition checks, 170/0 | Every named selection and invalid input; original pose/contact targets; matching visible/collision surfaces; signed finite transitions at 80°/90°, 30/60/120 Hz and varied speed. No whole-run unpumped energy gain in the helper matrix. |
| Independent actual-body checks, 98/0 | Real mapped keys, direction snapshots, held/released entries, manual gestures/rejections, rail latch/drop, finite actual support, natural vert/re-entry, half-pipe rollback, all four lip poses and drop/pop/overtime, blocked coping. Initial fixtures are declared; no per-frame position/heading/speed correction. |
| Turn/camera checks, 61/0 | Nine actual coasting turns at 8/12/15 m/s and quarter/half/full input, plus rollback; 720 camera samples. [CLASSIC-CAMERA-TURNS](CLASSIC-CAMERA-TURNS.md) records measured angles and source-derived camera values separately. |
| Protected quay route | Real existing route at Z67 completes in 16.08 s with zero stalls/bails after shifting the half-pipe 1 m north. The original arrival tolerance was retained. |
| Cold copied source | All four phases accepted, 208 stable inputs; real title branch 44/0; invalid disposable copy refused with exit 1 and restored. [Receipt](source-launch-classic/README.md). |
| Actual trick/transition pixels | 22 records / 42 images / zero capture errors; 25 representative PNGs retained with recipe and all image hashes. [Package](screenshots/classic-tricks/README.md). Production chase views and authored close/overview views are explicitly distinguished. |
| Ordinary title/play pixels | 19 images / zero failures, stable source, actual normal menu branch, natural spawn steering, camera obstructions, supported closes, park, market and bridge. [Package](screenshots/playability-repair/README.md). |
| Controls menu pixels | Three actual GUI views, including 960×540 at 1.4× interface size. Complete help text, all 19 binding rows, actual wheel scrolling and reachable Back/Restore. [Package](screenshots/classic-controls/README.md). |

The focused logs are [body](logs/classic-body-focused.log), [pure](logs/classic-pure-focused.log) and [quay](logs/classic-quay-route.log). Actual-body tests run the production 60 Hz tick. Multiple helper integration rates do not certify equivalent full gameplay at every tick rate. Software rendering with a forced fixed clock is not a frame-time or Apple GPU measurement.

## Concrete defects addressed

A real transition cannot use an upright street capsule and a decorative ramp alone. The controller now rotates the actual capsule to the confirmed support normal, sweeps finite short moves, retains collision-adjusted motion and restores upright contact only with clearance. Removed support cannot become an invisible infinite surface. A blocked upright recovery uses one safe bail rather than overlapping scenery.

Lip entry initially sampled the exact curve/deck seam, where a valid ray could hit the adjoining deck instead of the final curve triangle. Sampling inside that segment and validating the actual coping move fixes admission without widening it to arbitrary walls. A stale `is_on_floor()` value after `move_and_collide()` also cancelled genuine lip/vert aerial exits; the ordinary grounded path now excludes an already airborne rider.

The half-pipe deck originally obstructed the existing quay through-route. Moving the feature 1 m north resolves the physical collision while preserving the original route's full tolerance and zero-stall requirement. Its matching mesh/collision and supported side/deck geometry remain.

Early stick-manual experiments interpreted direct push-to-brake changes as manual gestures. Requiring a sampled neutral between short opposite directions preserves normal braking. The dedicated manual button can end a latched gesture manual even during overtime. Existing gesture continuation survives entry-disable, while fresh entries remain rejected after expiry.

Directional shuvits now count as flips in Mo's family challenge rather than being mistaken for spins. Stalls/disaster count as lips, and Nose Manual satisfies Mairi's manual stage without changing IDs, rewards or saves. The existing ten-goal career, cat coping sequence and market delivery remain regression requirements.

The controls help initially inherited ellipsis trimming and showed only one of five wrapped lines. Actual GUI readback exposed it; the corrected help opts out of trimming. The capture now requires every line to be visible, as well as checking layout rectangles. Old first-line-only screenshots are rejected evidence.

## Test migration and remaining work

Legacy fixtures now release Ollie before expecting a pop and use a second fresh Grind press for a latched-rail drop. Career tests still require the pop before the real deadline; they do not grant retroactive expiry input. Natural turn checks accumulate actual yaw deltas because a valid tighter turn can exceed 180°. Directional delivery navigation expectations were recalculated from the actual new bank position; bearing threshold unit checks remain. Existing banked-score, support, route and camera assertions were retained.

The initial fast diagnostic runs exposed integration errors and were not passing release evidence. Required ordinary runs interrupted for source changes are also not acceptance receipts. STATUS identifies the completed final command only.

[CLASSIC-TRICKS-NEXT](../planning/CLASSIC-TRICKS-NEXT.md) records owners, dependencies, first edits, acceptance and test strategy for continuation. Physical Mac/DualSense timing and comfort, repeated high-speed half-pipe aerial cycles, novice missed approaches, final clothed animation, realistic art/UI, audio listening, native export replay and moving 1080p frame times remain open. Current procedural poses establish distinct animation/contact behavior; they are not finished character animation.
