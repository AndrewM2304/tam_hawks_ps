# Gull-Proof Delivery — independent focused QE

17 October 2026. The production delivery encounter passes **52 checks, 0 failures**, exit 0, with no engine/script errors. The [focused log](logs/market-focused.log) follows the market entrance-clearance correction, gull beak/wrapper-contact correction, and visible lane-marker/navigation additions. The same `tests/market_encounter_tests.gd` module is invoked by the shared runner; these 52 checks are part of the eventual aggregate, not an additional total.

```sh
./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 \
  --script .local/market_qe_probe.gd
```

The temporary SceneTree wrapper creates Main with persistence disabled, invokes `await MarketTests.run(tree, game, check)`, counts assertions and exits nonzero on failure. `./tools/check.sh` is the durable complete-suite command. The final ordinary aggregate subsequently passes **1,106/0**, exit 0 with clean scans and 158 unchanged inputs; [QE-REPORT](QE-REPORT.md) records the log/source receipt and current-source career timing. The corrected rendered set is independently reviewed below.

## Actual movement and camera evidence

Each route begins at the authored supported pickup, `(105, 2.3, -26)`, and settles for 45 physics ticks. Actual interaction collects the visible courier bag. Push/brake inputs reach the loading platform, a fresh Manual rolls south, and an actual ollie crosses the existing `market_hop`. The real GapTracker supplies the named 350-point gap; the player emits only Manual and Ollie. The ordinary clean bank is exactly **1,650**: `(100 + 100 + 350) × 3`.

The continuing rider then reaches all three chosen lane gates and the delivery counter. No reset occurs between pickup, line, branch, arrival and earned payoff.

| Route | Active seconds to delivery | Real camera samples through payoff confirmation | Obstructed / hidden rider samples | Bank / wins / bails |
|---|---:|---:|---:|---|
| Covered market | 10.58 | 653 | 0 / 0 | 1,650 / 1 / 0 |
| Calton lane | 9.10 | 565 | 0 / 0 | 1,650 / 1 / 0 |

After the covered delivery, the rider also returns north through its gates using actual motion, without reset or camera obstruction. Every sampled camera transform is finite, the rider is inside the actual chase-camera frustum, and a layer-1 ray from rider chest to camera is clear. This is sampled geometric evidence, not subjective camera comfort or proof of every possible line under the shelters.

The actual bank supplies the new navigation hint at the real south-facing landing: **COVERED 1: LEFT** and **CALTON 1: TURN BACK**, with production distance text. All six numbered world markers and the arrival marker match the configured positions and add no collision objects. Independent state checks verify both first choices after the gap, only the committed lane's next marker, then the counter; failure/reset remove stale highlights. Ordinary and reduced-motion marker poses remain steady.

The actual nearby rider and production camera-frustum test trigger the earned gull response. Menu pause freezes it; it finishes within the authored 3.2 seconds, takes the spare parcel only, and cannot repeat the win or award more points. Reduced motion preserves the complete actor/parcel transforms. Free skating preserves all ten canonical career goals, profile records and both existing side-act attempt counts. Persistence is disabled throughout.

## Boundary and lifecycle evidence

Separate direct-callback fixtures cover offer range/pending combos, incorrect Manual/gap order, early-bank retry, unrelated gaps, nonpositive events, branch commitment and skipped gates, delivery range, repeated wins, queued visibility, replay, out-of-area callbacks, invalid time deltas, timeout, cancellation and reset. They do not substitute for the real movement proof above.

Integration checks use actual input to verify menu pause, restart and one unbalanced Manual bail returning the visible bag/pickup parcel. An explicit career-clock boundary fixture proves the side attempt ends on the first zero-time tick while an ordinary air combo still has overtime; results input cannot revive it.

## Shared capture driver and limits

`MarketTests.drive_delivery(tree, game, route_id, observer)` accepts an already settled initial pickup fixture. Its awaited observer receives `(stage, evidence)` at offer, pickup, manual, gap, banked, each gate, arrival and payoff. Capture tooling must fingerprint this test source and may render observed stages; it must not manufacture gameplay progress.

The corrected [24-image capture](screenshots/barras-clyde/README.md) reuses that driver and independently matches all 160 current source hashes and 24 PNG hashes. Manifest SHA-256: `cea83820c9b58e2ba361709a1a4997f824755ce62a846e93cc64a8fe6a81a68a`. The covered-line receipt retains 1,650, one win, zero bails, three gates and 653 clear/visible camera samples. Independent review confirms readable corrected gateway text, bank/next-marker/counter direction cues, actual parcel arrival and separate delivered/spare payoff states. Observer readback pauses player/main, and the production-frustum receipt confirms an already playing response at 0.4167 seconds before the authored inspection view; it is not the exact first trigger tick.

The current [native handoff](native-barras-clyde/README.md) passes export, independent archive/resource audit and bounded normal Linux headless/rendered startup from clean runtime `2a7d20c51559907b0ca30a995d842dcc683ff320`. Source/Linux/Mac pack probes construct the new district, delivery actor and courier bag; all 108 capture/build overlap hashes match. This proves package inclusion and tested Linux startup, not actual Mac play or a new native gameplay pass. [QE-REPORT](QE-REPORT.md) and [EXPORT](EXPORT.md) retain the exact package identities and limits.

The driver directly aims grounded heading. After the initial declared fixture, it never assigns position, speed, velocity, trick, gap, score, bank, visibility or success. Its short route timings are idealized feasibility timings, not estimates of human discovery or controller difficulty. Fixed 60 Hz headless checks do not certify frame rate, real-time rendering, Mac/DualSense play, final art, listening, comic timing or enjoyment. Current-source rendered review, the ordinary aggregate and native handoff are recorded separately when completed.
