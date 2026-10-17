# Physical career and district routes

Independent QE, 17 October 2026. Source: `tests/career_route_tests.gd`; Godot 4.6.3, production main scene, collision bodies, input actions, score ownership and career events. Player-profile persistence is disabled. This is automated feasibility evidence for M03-005/M04-006, not human discovery, difficulty, fun, controller comfort or Mac performance acceptance.

## Measured route

The single continuous career circuit starts at the normal Exchange spawn and returns there. In the clean **ordinary-scheduler** run it completes **all ten goals by 69.52 seconds**, returns at **78.63 seconds**, travels **1,085.69 metres**, and finishes with **19,700 banked points / 3,000 best combo**. No bail/recovery or stalled frame occurred. All four actual checkpoint positions were passed; the clock remained within its ordinary 120-second career deadline. The fixed-frame probe had the same physical route and a 0.13-second smaller startup offset (all goals 69.38s, return 78.50s); the detailed stage times below are from that fixed-frame probe.

| Stage | Physical path / action | Observed time |
| --- | --- | --- |
| Exchange | Ride central bank to H; travel east around the statue plinth, press interact beside the cone, then use the east George connector | Cone approach 5.73s; George connector endpoint 9.77s |
| George | Pass its checkpoint, approach A from the open south side of the ledges, return to the northern cross street | A waypoint 15.07s |
| West back lane | Manual across the George/Central boundary through S; turn south along the supported outer lane | S waypoint 21.93s |
| Central | Use the clear east aisle to reach the platform's southern approach; climb its ramp, ollie from roughly Z=5.45 over the real break, collect W, and leave by the north ramp | Takeoff 37.45s; W waypoint 38.42s |
| South connection | Pass Central checkpoint; traverse the south Exchange connectors to Barras checkpoint | Barras checkpoint 55.00s |
| Market | Collect the southern item, use X=96 aisle around stall collision, collect the northern item | Northern item waypoint 62.67s |
| Recording court | Enter south of the side wall at Z=-19, travel along X=120 to the recording, then reverse through the same open entrance | Recording collected 64.63s; court exit waypoint 65.48s |
| Remaining collections | Ride the open central aisle through K, then the western market item | HAWKS complete 68.33s; market set and all ten goals complete 69.38s |
| Return | Use the north Barras/Exchange connector, then travel diagonally through the open square to spawn | 78.50s |

The exact 43 waypoints and six scoring legs are constants in the test. Seven real ollies, six flips, six grabs and six manuals are issued through `Input.action_press/release`. Scoring legs use Ollie + Kickflip + Melon Grab → Manual, release the manual, then allow the normal landing deadline to bank. Named gap points come from main's real swept gap detector. No score, goal, collection or gap event is injected. The circuit also naturally earns Exchange Air before its scripted Central platform jump.

All previous collection assertions remain: HAWKS in one career run, all three market items, recording court entry **and exit**, four checkpoint visits, Across the toon, return to spawn without recovery, plus cone/gap and all ten goals. A fresh in-memory career ensures completed goals cannot leak in from earlier tests.

## Boundary combos

Each independent fixture starts from rest, accelerates with push, ollies at at least 12m/s, performs flip/grab, enters a manual after actual landing, corrects balance using push/brake, crosses the boundary, and releases. The score remains unbanked during the link and banks **3,000 exactly once** afterward. There are no bails.

| Street | Fixture endpoints X/Z | Forward | Reverse |
| --- | --- | --- | --- |
| Exchange / George east | `(20,-26)` ↔ `(20,-70)` | 5.42s | 5.42s |
| Exchange / Central south | `(-20,22)` ↔ `(-65,22)` | 5.52s | 5.52s |
| Exchange / Barras north | `(20,-22)` ↔ `(65,-22)` | 5.52s | 5.52s |

These six real-physics routes establish three bidirectional cross-district combo opportunities. They do not establish whether novices find or comfortably perform them.

## Driver limits

- The fixture changes spawn position only **before** starting each independent route. After that, only production movement advances position; it never assigns position, velocity or speed, disables collisions, changes gravity, or teleports across a wall.
- The route driver directly aims heading while grounded. That permits precise and sometimes instantaneous ground turns. Air turns use ordinary bounded steering actions. Consequently the times above are an idealized authored-route result, **not a human completion-time target**. Turning radius, camera comfort, recovery from mistakes and discovery still need human trials.
- Manual correction is deterministic feedback from the public balance meter. This establishes that the route supports the mechanic, not that its difficulty is appropriate.
- Measurements use the game's actual timer and 60Hz physics. The fast focused probe uses `--fixed-fps 60` to run fixed-delta frames without real-time pacing; it does not modify `Engine.time_scale`, the career clock or any gameplay tuning. An independent ordinary-scheduler focused run also passed all 13 checks with zero scanned engine/script errors, exit 0; its exact times are reported above. The aggregate suite remains root's separate gate.
- Initial resource import and rendering wall time are excluded from route acceptance. No framerate or Apple Silicon performance claim follows from headless simulation.

## Reproduce and resume

The integrated contract is `await CareerRouteTests.run(self, game, _check)` after constructing the production main scene with `game.persistence_enabled = false`. Root owns wiring into `tests/run_tests.gd` and the full `./tools/check.sh` result.

For an isolated check, save this temporary runner as `.local/career_route_runner.gd`:

```gdscript
extends SceneTree
const Main = preload("res://game/main.gd")
const Routes = preload("res://tests/career_route_tests.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
    _run.call_deferred()
func _run() -> void:
    var game = Main.new()
    game.persistence_enabled = false
    root.add_child(game)
    await process_frame
    await Routes.run(self, game, _check)
    game.queue_free()
    await process_frame
    print("ROUTE QE RESULT: %d passed, %d failed" % [passed, failed])
    quit(1 if failed else 0)
func _check(ok: bool, label: String) -> void:
    if ok: passed += 1
    else:
        failed += 1
        push_error(label)
```

After importing newly added assets, run:

```sh
./tools/run.sh --headless --fixed-fps 60 --script .local/career_route_runner.gd > .local/career-routes.log 2>&1
rg 'ROUTE SUMMARY|ROUTE CAREER|ROUTE COMBO|RESULT' .local/career-routes.log
```

Expected functional result: **13 passed, 0 failed**. Also scan the complete log for `ERROR:`, `SCRIPT ERROR:` and `FAIL:`; assertion counts alone are not a clean pass. Remove `--fixed-fps 60` for ordinary real-time scheduling. The runner, logs and caches remain ignored; the route and this reconstruction recipe are durable source.

## Findings and remaining acceptance

The first longer circuit exposed a repeated `Basis` → quaternion normalization error in rider-foot interpolation (`skater_visual.gd`, then line 183) after about 12.37 simulated seconds. QE reported it without changing production. The visual owner orthonormalized both interpolation bases; the next 11-case route run was clean and preserved the same timing. This is precisely the kind of accumulated transform defect that short startup checks missed.

The reproducible error appeared during the return turn beside A, with the message `Basis ... must be normalized in order to be casted to a Quaternion`, followed by `animate → _update_pose → _physics_process`. One reported X axis was `(-0.058169, 0, -0.998302)` and Z axis `(0.998302, 0, -0.058169)`. The continuous route retains those repeated heading changes; removing the normalization fix must fail the engine-error scan even if route assertions pass.

The first extended all-goal probe passed all 13 assertions but overlapped newly added texture files before import, producing missing `.ctex` errors. That run is **functional evidence only**, not a clean validation result. QE then coordinated the completed asset handoff, ran `--headless --editor --import --quit` (exit 0, zero error lines), and reran the entire route under ordinary scheduling: **13 passed, 0 failed**, exit 0, zero `ERROR:`, `SCRIPT ERROR:` or `FAIL:` lines. Local evidence is `.local/career-route-import.log` and `.local/career-routes-ordinary.log`; root's aggregate result is authoritative for the full project.

No unreachable collectible or forced collision was found on the tested authored circuit. Completion within 120 seconds with idealized steering does not justify tightening goal thresholds. Keep M04-006's novice/intermediate/experienced distributions, discovery and replay review open. Other lines and recovery paths still need playtesting; this circuit does not certify every square metre or final art.
