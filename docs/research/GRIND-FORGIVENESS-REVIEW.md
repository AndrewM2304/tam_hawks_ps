# Rail capture, timing and binding review

Inspected 17 October 2026 for the owner's current-map handling/performance review. Owner priorities remain M01-002, M02-002/008 and M06-004/006; no new area, asset, dependency or paid service was added. This is source and bounded regression evidence, not human or Mac controller acceptance.

## Diagnosis of the previous checkpoint

`game/tricks/grind_ride.gd` admitted a rail from one body position before each `move_and_slide()`. Admission already allowed a **0.65m total distance**, **0.45m above / 0.10m below** the rail, **55°** either-way horizontal approach and **2–18m/s** projected rail speed. Rising motion above 1m/s, vertical rails and approaches leaving open endpoints rejected. The total-distance sphere matters: at 0.45m height the usable lateral reach is about 0.47m, not 0.65m.

Those are meaningful geometric allowances, but a fast descent could cross the entire height window between two physics samples. Both endpoint queries then missed a valid rail, even with grind held and a reasonable approach. Raising the radius would hide that sampling defect and increase wrong-level/through-scenery risks.

The previous player's admission required the live `grind` action held; releasing it immediately ended an active rail. There was no timed grind intent buffer. That differs from both inspected open-source examples below. A perfect held-button fixture therefore did not establish that short, slightly early human presses were accepted. Changing those semantics belongs in player/input integration, with tests for early/late presses, expiry, release, pause, bail and repeated capture.

The reviewed baseline used keyboard **L** and **R2**. Current defaults use **L/Triangle** for grind, **R2** for revert and **R3** for restart, so a familiar grind-button press cannot restart the run. The helper reads action names rather than hardware. `input_profile.gd` permits physical-key, controller-button and signed-axis remapping, preserves keyboard fallback, handles any controller device index and rejects duplicate slot directions. Its **0.5 capture threshold** applies to choosing a new remap; the action's **0.2 deadzone** governs live mapped input. These are different thresholds. A snapshot of a binding cannot prove trigger comfort or reconnect behavior on an actual DualSense.

## Bounded swept capture implemented

`GrindRide.start()` keeps its previous contract and admission values. New `start_swept(lines,from,to,velocity,clearance)` checks a **completed actual body move**, using samples no farther than **0.10m** apart. It rejects nonfinite history and travel beyond **1m**, bounding both work and retrospective correction. It does not enlarge the distance, angle, speed or height gates.

`to` must be the body's actual current origin. Every optional clearance call receives **`(to, rail_point)`**, even when that candidate was found at an earlier sample. Passing an earlier sample as the body origin could bypass a real blocker; the helper deliberately forbids that interpretation. The caller still supplies the real rider-capsule sweep against ordinary scenery, airborne/control/input/cooldown gating, score admission and floor-state transitions. Use collision-adjusted actual travel velocity; do not restore blocked pre-contact momentum.

Player integration should first preserve existing point capture and then try the completed sweep before resolving landing, only when airborne travel remains unsupported. A second attempt cannot restart an active ride. Rail props remain on their existing nonblocking layer; ordinary walls remain authoritative. The helper is original code around the already attributed MIT rail geometry; no new upstream implementation was copied.

## Source research actually inspected

| Source / revision / permission | Direct observation | Decision |
|---|---|---|
| [TinyBitAdventures/not-pro-skater](https://github.com/TinyBitAdventures/not-pro-skater/tree/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988), `d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988`; root `license`: MIT, ©2026 Austin Ginder | `game/scripts/skater/skater.gd` buffers a fresh grind press; `_try_grind` ranks horizontal gap + weighted vertical gap + angle. Its `skate_tuning.gd` sets buffer **0.14s**, horizontal reach **0.9m**, rail-relative height **−0.45..+1.2m**; admission permits **75°** and both directions. The grind state exits through pop/end/balance, without requiring the original button to stay down. It also has auto-pop and a visual snap ease. | Good reference for timed intent, candidate ranking and tap-to-lock behavior. Those much wider bounds, automatic pop and its entire controller were **not** transplanted. Different origin, world and tuning need separate verification. |
| [3deric/godot-skateboarding-game](https://github.com/3deric/godot-skateboarding-game/tree/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928), `4fad39ecfb21e79ca4799b90e77ef6c1edfa7928`; root `LICENSE`: MIT, ©2024 Eric Schubert | `Skategame/Scripts/Player/Player_States/player_grind.gd` advances curve distance, exits open rails, permits jump-off and handles balance loss. It does not test a held grind button to stay attached. `balance_logic` appears in both `physics_update` and `_grind_movement`, causing two updates in that path. | Supports comparing tap-to-lock with our previous hold-to-stay behavior. Do not copy its duplicate balance update or assume its path-space conventions match ours. No code or assets imported. |

Both remote HEADs were resolved again with `git ls-remote`; both still matched those revisions. Original source files and complete licences were read directly over free public HTTP. This extends [SKATING_REUSE](SKATING_REUSE.md), including its separate asset-permission caveats; it does not claim either whole game was played, ported, benchmarked or verified on a Mac.

Integrity of inspected files (SHA-256):

- Not Pro Skater `skater.gd`: `0c46737616464b0db2987786e1ddcf0e2b87e87697e94a3c7ad9fcf5010b964d`.
- Not Pro Skater `skate_tuning.gd`: `f867ea1c3fc98e77a7284d136e370962564821f202bc95920714b4cc42226f9a`.
- Not Pro Skater complete MIT licence: `14829cfdb6a0ca3bf9f95be6ca9e6dae34ad3563f7e747047f4894d99e3d9773`; the existing retained notice covers the earlier geometry adaptation.
- 3deric `player_grind.gd`: `b319fd266f2fece90633c51d50ebc70276140c01015a42d6d6894c2d5fc97974`.
- 3deric complete MIT licence: `9b646934ce371139c3813793a3d094aca34713175e7a7f81d3da0d22bcb7b264`.

The previously suggested [Cowboy Programming skating-on-air URL](https://cowboyprogramming.com/2007/01/05/skating-on-air/) now returns HTTP **404**; the site's `skating on air` search returns no matching post. Its text/authorship and mechanics remain unverified, so nothing here is attributed to that article. An unavailable article is not needed to apply the inspected source observations.

## Verification and remaining acceptance

Focused command: `./tools/run.sh --headless --script .local/grind-human-error-check.gd`. Godot **4.6.3.stable.official.7d41c59c4**, exit **0**, **61 passed / 0 failed**. The temporary ignored runner calls the committed `tests/grind_ride_tests.gd` and fails nonzero on any assertion; those same checks remain in the ordinary runner. Root integration owns the full `./tools/check.sh` result.

The six added admission cases combine **30/60/120Hz**, lateral offsets to **0.55m**, approach errors to **45°**, horizontal speeds **4–17m/s** and different descent phases. A further fixture crosses from **0.50m above to 0.20m below** a rail at a **0.35m lateral error**; both discrete endpoint attempts reject while the actual-segment sweep admits. High descent speeds exercise missed-window safety, not a claim that normal park lines demand those speeds.

Negative cases retain rejection for a lateral miss, another elevation, below-rail travel, perpendicular travel, a rail behind the rider's departing endpoint, ascent, insufficient/excessive forward speed, nonfinite history and a teleport-sized step. A rejecting clearance spy proves all historical candidates are checked from the current body and cannot bypass that rejection. Existing integrated real-wall, signed travel, rail release, combo and restart tests remain required; a callback spy alone cannot certify physical collision behavior.

Human Mac/controller review remains open: use natural push/ollie timing, both signs of steering error, short/long early presses, a late press after passing the rail, partial trigger travel when grind is remapped to a trigger and a remapped button. Record success/bail/miss rates and whether misses were legible. Compare repeated attempts at a straight rail, fountain bend, sloped rail and stacked passage before widening any spatial gate. Automated capture envelopes do not certify fun.
