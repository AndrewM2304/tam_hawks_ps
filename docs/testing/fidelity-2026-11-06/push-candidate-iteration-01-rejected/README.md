# Rejected changing-source native push epoch

**Not accepted.** Godot executes the independent native Main push cohort with 27 checks/0 failures and a clean engine exit, but the before/after inventory finds changes to `game/levels/outdoor_routes.gd` and `tests/line_design_tests.gd` during 23:49:34–23:49:58 UTC. The outer wrapper correctly exits nonzero because source is not stable. No game-fidelity or candidate acceptance follows.

[Receipt](receipt.json), [before inventory](source-before.json), [after inventory](source-after.json), [engine log](engine.log), exact [observer](observer.gd.txt) and [motion tests](motion_tests.gd.txt) are retained. The two observer/test copies match their before-run hashes. Root's immutable candidate source will supply the next uncontaminated comparison.

Diagnostic observations only: regular/fakie/from-rest peak planted slip is 2.892/4.016/0.162 mm per tick; torso dot travel exceeds0.999, supporting front shoe exceeds0.993, native wheel gaps remain8mm and brake dragging gap is0.849mm. Six-/18-tick pop interruptions still pass. These are encouraging measurements, not a substitute for the required stable-source retest and normal-speed visual/transition/incline review. Manual controls were partially implemented during this epoch; its results do not accept those controls/HUD.
