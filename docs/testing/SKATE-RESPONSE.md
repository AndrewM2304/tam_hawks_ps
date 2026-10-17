# Street skating response repair

**17 October 2026.** The owner's Mac playtest reported that releasing push retained too much speed and the movement did not feel like the intended arcade skating game. This investigation measures those complaints with the existing controller and a bounded response helper. These Linux measurements do not certify Mac input, camera visibility or human skating feel. Native cold-start/visual initialization and missing world support are separate repairs.

## Baseline actually measured

The baseline controller is the exact `game/player/skater.gd` from clean runtime `00da63a29990c0839cf15d4c9a34edc2fc167122`, SHA-256 `23d87e2a83fe167c511dd6f0756bdb5d1fd95bb2fd6415dd30d66e643eaccbb8`. The local probe copies it to `.local/feel-review/skater-baseline.gd`; its preload dependencies remain the checkout's visual/trick helpers. This is a source-controller measurement, not a launch of the owner's Mac executable.

The actual Godot 4.6.3 `CharacterBody3D` runs at 60 physics ticks per second on an isolated `StaticBody3D` box measuring 600×0.4×600m, centred at `(0,79.8,0)`. Each trial spawns the skater at `(0,81,0)`, lets it settle for 60 ticks, then uses ordinary `Input.action_press`/`release` calls. There is no heading, speed or velocity injection, position correction, direct `_physics_process` call or waypoint steering. The camera process is disabled only to keep this movement-only headless probe independent of rendering. The elevated fixture prevents a downhill trial reaching the existing Y−8 reset threshold.

| Natural input trial | Before repair | Integrated after |
|---|---:|---:|
| Push for 0.5s | 5.000m/s; 1.292m travelled | Same |
| Push for 1.5s | 15.000m/s; 11.375m travelled | Same |
| Release for 2s from that speed | 13.496m/s remaining | 8.405m/s |
| Release for 3s from that speed | 12.740m/s remaining; 41.597m travelled | 5.974m/s; 30.040m |
| Release until speed is below 0.01m/s | 19.70s; 148.374m travelled | 6.917s; 40.200m |
| Brake immediately from the matched top speed | Zero in 0.683s / 4.989m | Same |
| Brake after the two-second coast | 13.496m/s to near-rest in 0.617s / 4.027m | 8.405m/s to near-rest in 0.383s / 1.536m |
| Left alone at rest for 0.5s | 65.89° pivot; no translation | 52.80°; no translation |
| Left and push for 1s at full speed | 81.70° heading change; still 15m/s | 56.72°; still 15m/s |
| Straight flat-ground ollie at full speed | 0.833s airtime; 1.836m rise; 12.495m forward | 0.833s; 1.836m; 12.450m |
| Same ollie with left held | 68.12° heading change; 6.706m lateral / 9.674m forward | 23.48°; 2.522m lateral / 12.099m forward |
| Coast for 2s on a +20° / −20° floor | Both approximately 15→13.49m/s | Both approximately 15→8.40m/s |

The old constant 0.75m/s² drag predicts 20s and 150m to stop from exactly 15m/s. Actual capped contact travel and floating-point position precision produce the slightly lower measured result. The full-air turn directly rotates the horizontal velocity with the same speed-dependent steering law used on the ground, explaining the large curved jump. These are confirmed behaviors; their suitability still needs human playtesting.

The slope trial rotates the entire fixture about X, retains the initial −Z heading, pushes for 90 ticks and then coasts for 120. The uphill rises 9.737m and the downhill falls 9.740m during coasting; both remain supported. The matching speed loss confirms that the street controller currently supplies no downhill acceleration or rollback. This repair does not claim to implement those mechanics.

After integration, the same slope trials rise/fall approximately 7.83m and remain supported. The shorter straight ollie travels about 4.5cm less because the launch frame applies the stronger ground coast before adding the unchanged jump impulse. Both air paths still preserve the accepted takeoff momentum. The matched top-speed brake trial confirms that braking itself is unchanged; the shorter brake-after-coast result starts from a lower speed.

The after probe completed exit 0 with clean engine/script logs. Its four recorded inputs remained unchanged throughout that measurement:

| Input | SHA-256 |
|---|---|
| `game/player/skater.gd` at the measurement checkpoint | `baa5fe008739f9701f419cc418efcc17c8203d0ee9eed713f8621640055dc0e1` |
| `game/player/skate_response.gd` | `1042f359b096061edf86da5ef057b89a5bbf36e94836feeb3a0c6a4dea5a6578` |
| `game/core/input_setup.gd` | `f72af97ff5d7c8c8125ed1471a07cf544484bfa00c5fd64a4c390a7340ef6a14` |
| `.local/feel-review/after.gd` | `a857708399725ae23ba7243943c0c7686e1fb244b5eb436a18baac192e342e15` |

This was an intermediate movement checkpoint while other agents repaired camera and world geometry. The isolated fixture does not use the city or camera process; these fingerprints do not claim that all later production files were frozen or tested.

## Bounded implementation

The original `game/player/skate_response.gd` owns only response calculations. `coast_speed(speed,delta)` integrates `ds/dt = −(1 + 0.2s)` exactly, then clamps at zero. Its mathematical result from 15m/s is **5.97623m/s after three seconds**, with a stop at about **6.93s / 40.34m**. Resistance is stronger at speed and eases near rest. Ordinary physics/contact may reduce measured speed further; those analytical values are not presented as measured travel.

`steering_step(input,speed,grounded,delta)` returns a heading increment. Ground steering targets 2.3rad/s at rest and 1.1rad/s at 15m/s, with a 0.10s exponential response; the angle integral makes fixed input/rate results consistent at 30/60/120Hz. Air correction is independently limited to 0.50rad/s. Entering air clears the ground response, and releasing air steering stops that correction immediately. `reset()` clears residual ground turning. The helper has no camera sensitivity argument and never reconstructs movement velocity.

Root integration retains maximum push speed 15m/s, push acceleration 10m/s², brake deceleration 22m/s², immediate 8.8m/s ollie, forgiving landing rules and score/link deadlines. It resets the response on player reset or controls being disabled. Collision-adjusted takeoff motion remains authoritative. Manual coast remains as designed on level ground; speed-dependent resistance now lets forward and reverse roll approach rest without sign changes. Slope response is recorded in the follow-up below. Charge/release jumps, strict sideways-landing bails and a full transition/vert state remain outside this repair.

## Reference basis and permissions

The pinned MIT implementations were read directly from the existing research cache, not inferred from a README:

- [Not Pro Skater, `_ground` lines 640–706](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/game/scripts/skater/skater.gd#L640-L706) separates forward/lateral motion, damps lateral slip and applies tangent gravity. Its [`_air` lines 1098–1143](https://github.com/TinyBitAdventures/not-pro-skater/blob/d18803ae9f2daecf7f3ae276b2f14c1eb0ed5988/game/scripts/skater/skater.gd#L1098-L1143) separates spin from travel correction.
- [GodotSkate, `player_air.gd` lines 24–36](https://github.com/3deric/godot-skateboarding-game/blob/4fad39ecfb21e79ca4799b90e77ef6c1edfa7928/Skategame/Scripts/Player/Player_States/player_air.gd#L24-L36) rotates the rider transform while retaining airborne travel velocity; its ground state handles contact alignment separately.

These support a separation between ground turning and airborne correction. Neither was launched here, and neither proves the chosen tuning feels like Tony Hawk. The new helper is original code; no upstream implementation, asset, constants or tuning profile was copied. Existing [reuse research](../research/SKATING_REUSE.md) and [transition research](../research/TRANSITION-SKATING.md) retain the inspected source/licence identities and future scope.

## Focused verification and reproduction

`tests/skate_response_tests.gd::run(check)` reports **29 passed / 0 failed**, exit 0, with clean engine/script logs before player integration. It checks elapsed-time agreement at 30/60/120Hz, monotonic coasting and eventual rest, invalid/negative values, finite output, gradual ground response, symmetric clamped input, bounded air correction and response clearing across air/ground/reset. The pure helper checks do not replace the actual movement measurements or the ordinary regression.

After integration, the unchanged independent `tests/takeoff_tests.gd` suite reports **21 passed / 0 failed**, exit 0, clean logs. Actual ±30° departures retain 12.99038m/s on the next airborne tick; the flat edge retains 13.37894m/s. The bounded air-steering checks pass, and removing a contacted wall leaves zero velocity and public speed. No earlier takeoff boost or restored collision momentum was reintroduced.

A separate actual-input sensitivity check repeats the full-speed one-second left turn with settings 0.5, 1.0 and 2.0. All three produce exactly the same sampled heading **56.72313°**, speed **14.99998m/s**, X**−6.340674** and Z**−24.210964**. Camera sensitivity therefore no longer changes this measured steering route. Rendering and camera behavior require separate checks.

The ignored probes and measurements are currently `.local/feel-review/baseline.gd`, `baseline.json`, `baseline.log`, matching `after.*`, `helper-tests.*`, `sensitivity.*`, `brake-baseline.*`, `brake-after.*` and `takeoff-after.log`. Re-run with:

```sh
./tools/run.sh --headless --fixed-fps 60 --script .local/feel-review/baseline.gd
./tools/run.sh --headless --fixed-fps 60 --script .local/feel-review/after.gd
./tools/run.sh --headless --script .local/feel-review/helper-tests.gd
./tools/run.sh --headless --fixed-fps 60 --script .local/feel-review/sensitivity.gd
./tools/run.sh --headless --fixed-fps 60 --script .local/takeoff_qe_probe.gd
```

After environment replacement, recover the exact baseline controller with `git show 00da63a29990c0839cf15d4c9a34edc2fc167122:game/player/skater.gd`, then recreate the simple isolated fixture and input durations above. Sample only after each `physics_frame` followed by `process_frame`, so each row reflects completed `move_and_slide`. A current-source comparison must load `res://game/player/skater.gd` with the same fixture and inputs. Preserve initial-only fixture placement; a route driven by direct heading assignments cannot establish steering usability.

No ordinary suite or graphical capture was run by this movement reviewer. Those integrated checks are owned by the root/QE agents, and their exact later-source results belong in STATUS and the QE report. These passing measurements address excessive coasting and oversteering; they do not certify the intended skating feel. Real Mac/controller playtesting and human acceptance remain open.

## Slope response follow-up — 17 October 2026

The owner asked to harden the current game and pause area expansion. `game/player/skater.gd` now projects world-down gravity onto the contacted ground tangent and integrates **0.28 × gravity** along the board's forward axis. The signed street-speed cap is **±15m/s**. Coast resistance is symmetric: reverse rollback slows to zero without unexpectedly changing direction, while mapped push and brake can recover. This is a bounded street hill response; no new terrain or vert/transition state was added. See [ADR-013](../architecture/decisions/ADR-013-slope-responsive-street-skating.md).

The focused response helper now reports **32/0** and the independent takeoff suite **23/0**. The real 20° supported-bank regression begins at `(0, 7.134492, -2.482148)`, then after one second of no input is at `(0, 6.948609, -1.971434)`: **0.511m downhill**, signed speed **−1.020m/s**, still supported. A previously failing reverse Exchange→Barras career line also passed during the first full run after slope response. The final full-suite count is recorded in STATUS/QE after its source-frozen run completes.

This shows that grades now affect travel; it does not prove exact Tony Hawk parity or final controller feel. Human Mac play remains needed to tune uphill carry, rollback, coast and steering together.
