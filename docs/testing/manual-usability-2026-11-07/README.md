# Manual combo and balance development checks

Production author: studio/combo specialist. Independent acceptance belongs to root and gameplay QA; this is not a self-awarded BA pass.

## Development epoch 01 — failed test cleanup retained

Command: `./tools/run.sh --headless --fixed-fps 60 --script .local/manual_usability_runner.gd`.

The [exact runner](focused-runner.gd.txt) exercised existing Manual/Revert, mapped-pad classic controls, eight manual-grade/contact fixtures and actual Main combo tests plus the new timing/HUD cohort. [Original output](focused-01.log): **245 passed, 1 failed, engine exit 1**; no script/engine error was logged. This ran on live changing source during a separate qualitative renderer probe. No whole-source stable receipt, real-time performance or final integration acceptance is claimed.

The failure was in the newly written gesture-case cleanup: releasing direction inputs does not end an intentionally latched gesture manual. Its declared existing control is a fresh Manual press. The test now uses that input; production latching was preserved. The correction passed the fresh development run below.

Actual native contact in the matrix was tick 31. Held requests at 100/200/300/333 ms admitted one Manual, preserving Ollie/Kickflip and banking 1500 after valid exit. Requests at 350/367/450 ms, a released 200 ms request, a takeoff-held request and a paused request admitted none and banked the original 800. The gesture 200 ms request admitted at native contact but the incorrect cleanup left its combo unbanked. These are diagnostic observations at fixed simulation ticks, not wall-clock/M5 measurements.

The new five-entry air→manual→air/grab link and HUD top/centre/bottom, remapped PageUp/PageDown prompts, lateral rail marker and fit at 960×540/1280×800/1920×1080 with UI scale 1.0/1.4 passed within that failed cohort. Native pad simulation and UI diagnostics do not certify a physical controller or human feel. Root still owns the required combined suite, clean import, frozen natural-frame moving UI evidence and source/ref delivery.

## Development epoch 02 — corrected request and UI cohort

Command: `./tools/run.sh --headless --fixed-fps 60 --script .local/manual_usability_narrow.gd`.

The [exact narrow runner](narrow-runner.gd.txt), [original output](narrow-02.log) and [source receipt](narrow-02-receipt.json) retain **243 passed, 0 failed, engine exit 0**, with no engine/script errors. Gesture termination now uses its fresh Manual toggle, and all declared timing, stale/released/paused/restart, five-entry combo and vertical/lateral UI criteria pass. The additional queued-request cue is observed naturally in Main and clears after consumption/expiry/cancellation. Counts overlap the earlier cohort and must not be added together as distinct tests.

**The whole-source stability gate rejects this epoch as final acceptance:** 508 input hashes were checked and `game/player/skater_anatomy.gd` changed during the run. Manual/controller/Main/HUD/test inputs were unchanged, but the running game includes the rider. This is useful development evidence only. The final combined frozen suite and natural-frame moving capture must establish the integrated candidate. Preserve this receipt instead of relabelling it stable.

Independent QA separately [verifies the actual board/travel sign and ten style/stance variants](../fidelity-2026-11-06/controls-sign-01/README.md) with 85/0 checks and 785 unchanged input hashes in its source-bound review; that scope does not make this author's implementation independently accepted in every dimension. Final moving meter, adverse paths, physical controls, human feel and M5 sustained performance remain open.

## Subsequent legacy-driver audit — integrated retest pending

A later source audit found three remaining test blocks still using lateral input as manual correction. The intentional sloped-manual bail in `authentic_fidelity_integration_tests.gd`, the encounter imbalance failure in `glasgow_encounters_tests.gd`, and the two manual-variant corrections in `classic_tricks_integration_tests.gd` now send mapped fore/aft actions through `ManualBalance.correct`. Their original signed corrections, assertions and physical tolerances are preserved. Steering away from the fixture would exercise a different failure, so these input changes follow the owner's explicit control change. The naturally uncorrected cat-encounter bail remains unmodified.

These later driver edits are **not covered by either historical development count above**. The integrated current-source suite must exercise them. No engine was started during the environment specialist's exclusive performance measurement.

Independent QA also requested a specific natural-frame presentation probe: at 1280×800 and UI scale 1.4, check the moving manual meter against the projected rider/head and next landing. The enlarged panel may overlap that play area even while all UI rectangles fit the viewport. This is a pending native visual check, not a reproduced defect or a passing layout result; correct placement if the capture confirms obstruction.

## Reproduce on a future checkout

Coordinate the sole import/headless slot with root first. The ordinary integrated `./tools/check.sh` already reaches this cohort through `ComboIntegration.run` → `ManualUsability.run`; do not wire it twice. To run only the retained narrow development recipe on current source:

```sh
mkdir -p .local
cp docs/testing/manual-usability-2026-11-07/narrow-runner.gd.txt .local/manual_usability_narrow.gd
./tools/run.sh --headless --editor --import
./tools/run.sh --headless --fixed-fps 60 --script .local/manual_usability_narrow.gd
```

Inspect the import/engine logs and actual exit status. This reruns the checkout's current source, not a reconstruction of a historical dirty epoch. For final evidence, freeze/copy the actual executed source and record before/after inventories through the existing QA workflow; a count alone is insufficient.
