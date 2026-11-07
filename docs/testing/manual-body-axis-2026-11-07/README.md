# Independent manual torso-direction regression

Actual default Main and mapped inputs reproduce the old bug: **100/4**, exit1. The four failures are W/S torso direction in Pogo and Hang Ten. The proposed deck-space lean passes **104/0**, exit0; all existing84 board/steering/control checks remain passing. Each run has999 byte-stable source/import-cache inputs; the only between-epoch difference is `game/player/skater_visual.gd`. No Main source was changed by QA.

The independent regression measures the connected torso’s world up axis projected onto actual horizontal travel. W must increase that projection by more than0.001 and S must decrease it by more than0.001, across10 real-input cases including both fakie manuals, Pogo, Casper, pivots, Hang Ten and one-foot nose manual. It does not invoke the production direction helper or infer world motion from Euler-axis names.

Pogo old W/S deltas are−0.008485/+0.010889; new+0.006993/−0.010091. Hang Ten old−0.004488/+0.000839; new+0.008316/−0.008590. The exact one-file change applies lean in the functional board frame before torso yaw; it preserves the existing angle, blend and bail factor.

[Independent findings and complete measured cases](independent-review.json), [exact proposed visual hunk](visual.patch), and the original baseline/candidate receipts, source inventories and logs are retained. Baseline remains a failed epoch. The source-bound20 assertions are in the ordinary `tests/fidelity_acceptance_tests.gd` cohort; the exact observer/test/wrapper used here are preserved beside this README.

World-axis direction is only one gate. Natural appearance, lateral/body/hip motion, fitted clothes/contact and a normal-speed rendered reel remain open. Headless diagnostic overlap was authorized; there is no frame-time, sole-engine, target-Mac or AAA claim. Root owns actual promotion and subsequent combined-source checks.
