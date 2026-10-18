# Techno Bin and dancing cats — focused QE

**18 October update:** the weighted-jump input driver now passes the same 52 checks with a closer real tap, exact A→B→C, 1,050 once and the complete visible-return payoff. [Current encounter regression evidence](arcade-response/ENCOUNTER-REGRESSIONS.md) records measured launches, the first landing, limits and the combined 104/0 log. The timings, screenshots and native evidence below belong to the earlier checkpoint.

17 October 2026. The corrected original street act uses a seated bin drummer and two soft fabric cats. The existing `cat_got_the_beat` ID, ordered `Grind_Cat_A/B/C` captures, score rules and queued visible payoff remain intact. This record covers the correction; the earlier mechanical-cat screenshots and native packages are historical evidence for the prior presentation.

## Focused result

`tests/cat_encounter_tests.gd` passes **52 checks, 0 failures**, exit 0, with no engine/script errors. The receipt was refreshed after the actor-local hand curl and drumstick-contact correction; shared rider anatomy was unchanged. The actual [focused log](logs/bin-cats-focused.log) was produced by:

```sh
./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 \
  --script .local/cat_qe_probe.gd
```

The temporary wrapper creates `Main` with persistence disabled, invokes `await CatTests.run(tree, game, check)`, counts assertions and exits nonzero on failure. The same committed module is already invoked by `tests/run_tests.gd`; `./tools/check.sh` is the reproducible complete-suite command. The focused result is not an additional aggregate count. Root records the final ordinary aggregate separately.

All 38 previous rule/integration checks remain, with the old robot-node pose assertions migrated to the two fabric cats and drummer. Fourteen added checks cover the corrected visible structure and actual movement, PCM data, finite/clamped gain handling, public master/ambience settings, mute, pause/resume, run-end suppression and restart.

The unchanged physical recipe performs an actual interaction, push/brake approach, ollie onto A, rail ollies to B/C and clean landing. It captures each rail once, banks exactly **1,050**, records **zero bails**, and leaves **52.32 seconds** on the local challenge. Success remains queued offscreen. A continuous input-driven return triggers the earned response after **51 ticks**, **9.87 m** from the stage, with the production camera's frustum test true. Both fabric-cat subtrees and the drummer actually change pose during the 3.2-second response. Pause, completion, no repeated win/reward, real manual-balance bail, deadline, reset and free-skate/save isolation still pass.

## Audio and reduced-motion correction

The generated local percussion is cached mono PCM16 at 22,050 Hz: 176,400 samples/eight seconds. Independent PCM inspection measured peak 10,671/32,767, normalized RMS 0.03854 and no clipped samples. The first/last samples are zero; the last 0.08644 seconds are silent. PCM SHA-256 is `0965cbed26ca6c6ef81360c1567ecf2da0c2c20e4f57b69ba0fbbef49b66b7b9`. No external performance recording is used.

Independent review caught a synchronization defect: reduced motion initially froze the internal beat phase while audio kept playing. The strengthened existing pose check reproduced **51 passed/1 failed** before the fix. The owner changed only clock advancement: reduced motion now freezes both cats, drummer and indicators while the underlying beat continues. Actual menu pause and run end still freeze the clock; changing volume after run end cannot restart the act. The final 52/0 log includes this regression.

## Corrected visual evidence

Independent QE inspected the final [medium](screenshots/bin-cats/28-bin-busker-medium.png), [earned payoff](screenshots/bin-cats/33-cat-earned-payoff.png) and [reduced-motion](screenshots/bin-cats/34-cat-reduced-motion.png) frames, plus actual motion samples 25, 40, 45 and 65. The closed hands now read as grips around continuous visible sticks; the previous open-fan hand defect is corrected. Both soft cats change visible arm/body poses, the improvised kit and act/sequence labels remain clear, and the static alternative is distinct. No additional concrete visual blocker was found in these views. The kit occludes the drummer's lower legs, so these frames do not establish foot contact.

The [final manifest](screenshots/bin-cats/manifest.json) passes independent comparison of all **104 current source hashes** and **34 PNG hashes**. Its SHA-256 is `f172612c2194f223c37a62d47ec6d93fec3446add119afb3485fad1f9d43cf87`. All 100 recorded motion samples retain the actual 1,050-point bank and one win; 96 are animation-active and four finished, with monotonic elapsed time through 3.2 seconds. The receipt records the real 51-tick return at 9.876 m with the production chase frustum true.

The silent `/workspace/TamHawks-bin-cats-preview.mp4` is **547,672 bytes**, SHA-256 `00a929553cb13ee7f7b6b10e96d07a2e29ced73c87fb25b0128da38aa7ec26fb`. The capture owner completed full decode; independent QE matched the promoted video hash and reviewed sampled original frames. The video uses an explicitly authored stage camera after the real earned trigger, advances normal actor callbacks between images and holds the actor during readback. It is animation evidence, not real-time rendering or audible-performance evidence. The [first diagnostic views](screenshots/bin-cats-diagnostics/README.md) remain historical.

## Limits and remaining evidence

The physical driver directly aims grounded heading and starts at a declared supported fixture. After that initial reset it never assigns position, speed, velocity, capture, trick, score or bank. The real-return proof does not assign camera transforms or visibility. Callback boundary cases and explicit clock fixtures are separate from the physical route.

Fixed 60 Hz headless checks prove behavior and generated audio data, not natural steering, audible mix quality, comic timing, frame rate or real hardware. Structure/material/sign-size assertions and the bounded visual review do not certify finished realism or human enjoyment. Root records the final ordinary aggregate separately. No profile writes, paid services, downloads or target-Mac claims are part of these checks.
