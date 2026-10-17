# Physical career and district routes

Independent QE, 17 October 2026. Source: `tests/career_route_tests.gd`; Godot 4.6.3, production main scene, collision bodies, input actions, score ownership and career events. Player-profile persistence is disabled. This is automated feasibility evidence for M03-005/M04-006 and the terrain redesign, not human discovery, difficulty, fun, controller comfort or Mac performance acceptance.

## Redesigned circuit

The continuous career circuit starts at the new Exchange spawn **(-22, 0.8, 28)** and returns there. After the nonlinear-route extension's Merchant entrance repair, the unchanged **fixed-60Hz** circuit completes **all ten original goals by 75.20 seconds**, returns at **88.00 seconds**, travels **1,199.52 metres**, and finishes with **20,000 banked points / 3,200 best combo**. No bail, recovery or stalled frame occurred. All four original career checkpoint positions were passed within the actual 120-second career deadline. Clyde and Kelvingrove are separately traversed in [TOPOGRAPHY](TOPOGRAPHY.md); they do not enlarge the original four-district goal.

The earlier redesigned terrain also passed an ordinary-scheduler circuit at **75.33s** to all goals and **88.13s** to return over **1,199.40m**; its earlier fixed-frame counterpart recorded **75.22s/88.02s**. Those ordinary timings predate the nonlinear extension and are retained as historical evidence. The current court/cat ordinary aggregate now passes 1,025/0, including 13 career-route checks: 75.20s all ten goals, 88.00s return, 1,199.50m, 20,000 points/3,200 best and no bail/stall. Its [full log](logs/court-cat-final.log) is authoritative for that current source; the fixed-frame stage table below retains its prior nonlinear-probe identity. The following stage times use the latest focused fixed-frame probe; they are not human completion-time targets.

| Stage | Physical path / action | Fixed-frame time |
| --- | --- | --- |
| Exchange | Push up the west 0→2m gallery bank, collect H, cross the clear south side of the plinth and interact with the cone | H waypoint 5.98s; cone approach 9.97s |
| George | Climb the east 2→4m street, pass the west checkpoint, use the east 4→6m civic bank and collect A | A waypoint 23.23s |
| West connection | Cross the opened civic back street through S, then descend the graded station lane | S waypoint 32.08s; lane exit 37.38s |
| Central | Pass its checkpoint, reach the southern platform approach, climb 2→5m, ollie the actual break and collect W; descend the north return bank | Takeoff 46.27s; W waypoint 47.37s |
| South connection | Return along the station aisle and descend the Exchange street, then pass the Barras checkpoint and western market item | Barras checkpoint 64.38s |
| Market | Collect K and the southern market item, go around stall collision via X=126 and climb the 1.5m loading bank | HAWKS complete 66.62s; loading top waypoint 71.88s |
| Recording | Enter the side court south of its wall, collect the recording and leave by the same opening | Recording collected 73.50s; court exit waypoint 74.15s |
| Remaining item | Cross the open loading terrace and collect the northern market item | Market set and all ten goals complete 75.20s |
| Return | Use the northern market/Exchange street, cross the gallery and descend the west bank to spawn | 88.00s |

The exact **40 waypoints** and **six scoring legs** are constants in the test. Seven real ollies, six flips, six grabs and nine manual entries are issued through `Input.action_press/release`. Each scoring leg links Ollie + Kickflip + Melon Grab → Manual and releases to bank through the ordinary deadline. When a crest produces real airtime, the driver releases Manual and issues fresh presses after landing, respecting its cooldown and the existing 0.35-second deadline. A repeated valid manual receives the normal repeat reduction; the driver never edits score or extends the deadline. The Central gap award comes from main's real swept crossing detector.

All prior assertions remain: HAWKS in one career run, all three market items, recording court entry **and exit**, four actual checkpoint visits, Across the toon, cone interaction, the actual Central platform gap, all ten goals, and return to spawn without recovery. A fresh in-memory career prevents completed goals leaking from earlier fixtures. No score, goal, collection or gap event is injected by this circuit.

## Boundary combos

Each independent fixture starts from rest, accelerates with push, ollies at at least 12m/s, performs flip/grab, enters a manual after actual landing, corrects balance using push/brake, crosses the boundary and releases. Genuine crest airtime may require a second fresh manual. The score remains unbanked through the entire link; it banks exactly once after release and stays unchanged through a second waiting period. All six directions pass without bails.

| Graded street | Fixture endpoints X/Y/Z (ground) | Forward / reverse bank | Manual entries forward / reverse |
| --- | --- | --- | --- |
| Exchange / George east | `(22,2,-26)` ↔ `(22,4,-74)` | 3,200 / 3,000 | 2 / 1 |
| Exchange / Central south | `(-20,0,22)` ↔ `(-65,2,22)` | 3,200 / 3,000 | 2 / 1 |
| Exchange / Barras north | `(22,2,-22)` ↔ `(65,1.5,-22)` | 3,000 / 3,200 | 1 / 2 |

The exact expected totals are 3,000 for the first manual and 3,200 when a second manual adds 50 repeat-degraded base points at ×4. The test observes actual trick entries and checks those explicit values; it does not call the production score calculation to predict itself. These routes establish three bidirectional combo opportunities, not novice comfort or discoverability.

## Driver limits

- The fixture changes spawn position only **before** starting each independent route. After that, only production movement advances position; it never assigns position, velocity or speed, disables collisions, changes gravity, or teleports through a wall.
- The driver directly aims heading while grounded. This permits precise and sometimes instantaneous ground turns. Air turns use ordinary bounded steering actions. The times above are therefore idealized authored-route results, **not human completion-time targets**. Turning radius, camera comfort, discovery and recovery from mistakes still need human trials.
- Manual correction is deterministic feedback from the public balance meter. Fresh presses after crest airtime are idealized timing assistance; they do not establish appropriate human difficulty.
- Measurements use the game's actual timer and 60Hz physics. The fast probe uses `--fixed-fps 60`; it does not modify `Engine.time_scale`, the career clock or gameplay tuning. The latest fixed-frame probe passes all 13 checks with clean engine/script logs. The earlier ordinary-scheduler 13/0 result predates the nonlinear extension; the current court/cat ordinary aggregate passes all 13 route checks within 1,025/0, with its own retained log.
- Resource import/rendering wall time is not route acceptance. No headless result establishes framerate or Apple Silicon performance.

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

Expected focused functional result: **13 passed, 0 failed**. Also scan the complete log for `ERROR:`, `SCRIPT ERROR:` and `FAIL:`; assertion counts alone are not a clean pass. Remove `--fixed-fps 60` for ordinary real-time scheduling. The runner, logs and caches remain ignored; the route and this reconstruction recipe are durable source.

## Findings and historical evidence

The first redesigned circuit hit a real blocked civic connection at approximately `(-35.706,4.012,-77.431)`. A frontage sealed the route to S. QE reported the collision; the world owner split both civic frontages around the back street. The final full career circuit and both-direction collision sweeps pass through the repaired opening. QE did not edit production to hide the failure.

The first uphill combo probes legitimately left support at slope crests for 3–10 physics ticks with 10–11.5m/s remaining speed. Holding the original manual input could not trigger a fresh entry after landing, so those old flat-world fixtures banked early. The corrected driver releases and presses Manual again within the unchanged rules; production movement, scoring and deadline behavior were not altered.

Static route checks also found raised corner overlaps and outdoor curve/join slivers. Their fixes and independent physical verification are recorded in TOPOGRAPHY. The older flat-map 69.52s/78.63s route and 778-check aggregate remain historical evidence only.

The first nonlinear extension blocked the unchanged Central concourse shortcut from `(-94,2,-38)` to `(-62,2,-38)`: the rider stopped at `(-70.737,2.012,-37.726)` against the raised Merchant Close foundation. The world owner confirmed an unintended curb and flattened the close's mouth through the existing concourse, beginning its climb only beyond Z=-42. The exact same career waypoints, scoring legs and assertions then passed **13/0**. The six boundary-combo directions retain their exact 3,000/3,200 banks; no detour or scoring workaround was introduced.

The earlier long route exposed `Basis ... must be normalized in order to be casted to a Quaternion` in rider-foot interpolation, following `animate → _update_pose → _physics_process`. One reported X axis was `(-0.058169,0,-0.998302)` and Z axis `(0.998302,0,-0.058169)`. The visual owner orthonormalized both bases. The new continuous circuit retains many heading changes; any recurrence must fail the complete engine-error scan even if functional assertions pass.

Latest focused evidence after the nonlinear entrance repair: `.local/career-nonlinear-final.log` (fixed-frame), exit 0, **13 passed, 0 failed**, no `ERROR:`, `SCRIPT ERROR:` or `FAIL:` lines. Earlier clean evidence is retained in `.local/career-redesign.log` and `.local/career-redesign-ordinary.log`; these do not certify later geometry edits. The final court/cat ordinary aggregate is separately retained in [court-cat-final.log](logs/court-cat-final.log), 1,025/0 exit 0. Source tests and the runner recipe survive environment replacement; ignored logs must be regenerated.

No unreachable collectible or forced collision remains on this tested circuit. Its idealized completion time does not justify tightening score thresholds. Keep human novice/intermediate/experienced distributions, discovery, replay appeal, real Mac/DualSense and final art gates open.
