# Weighted-jump encounter regressions

18 October 2026. The serialized headless encounter run completes **104 passed / 0 failed**, exit 0, with no engine/script errors: 52 cat checks and 52 delivery checks. The runner's `FOCUS_END market_encounter passed=104` is cumulative, not 104 market checks. [Actual log](diagnostics/regressions-encounters-01.log), SHA-256 `0608b310505c2811e346509c07c1510c03f39234069f3b27b5bfa6206977d5b3`. The fresh required ordinary suite remains pending; this focused run does not override the [rejected 1,960/38 run](failed-check-01/receipt.json).

Only the two test drivers changed for this repair. Production tap/full-charge impulses, gravity, capture geometry, marked rail IDs, challenge rules, score, gate positions/radii, payoff and save behavior were retained. The temporary root-owned `focused-regressions.gd` wrapper invokes the two committed modules against actual Main with persistence disabled. No additional engine run was made by independent QE.

## Cat line: move the actual tap closer

The failing driver tapped when `A.point_at(2)` was 9.5 m ahead. With the shorter weighted jump, the run recorded one Ollie, no capture of any rail, a 100-point bank and zero bails. The original log did not record the first launch/landing coordinates, so the precise missed-catch trajectory was not measured. Later payoff failures depended on this uncompleted sequence.

The driver now taps at 6 m from that target, about 4 m before A's start. It still presses for one physics step and releases normally; rail-to-rail inputs and all existing assertions remain unchanged. Added witnesses observe real Ollie events, the first clean landing and nearby sampled flight state without modifying movement.

The actual launch is `(-19.72486,4.012912,-91.30079)` at **13.38768 m/s**, with vertical impulse 8. The player captures exactly `Grind_Cat_A`, `Grind_Cat_B`, `Grind_Cat_C` at X−16, −4 and 8; challenge sequence states are exactly 1, 2, 3. Three real Ollies and three Rail Grinds bank **1,050 once**, with zero bails. The first clean landing follows all three captures, at `(9.501307,4.462381,-91.00004)`.

The surrounding-frame descending witness records zero samples and an empty closest-A record: capture happens between those observation points. This is successful actual capture evidence, **not an observed descending-phase measurement**. It does not support a claim that a rival semantic edge stole the old attempt.

The offscreen bank queues the response. Continuous input returns within **9.85 m** of the stage after 62 frames, with the actual camera-frustum condition true. Both fabric cats and the drummer move; pause freezes the accepted response; its full 3.2-second bound completes without repeated reward. Reduced-motion, PCM/mix/mute, expiry, real manual-bail, restart and free-skate/save-isolation checks still pass.

## Delivery: preserve the intended fork choice

The weighted tap lands near `(93.615,0.0124,-4.014)`, farther north than the historical landing. The original straight diagonal to covered gate `(114,0,-5)` passes inside the west first-gate radius around `(103,0,-5)`. That correctly commits west; visiting covered gates afterward cannot advance that selected route. The failing run had already earned the real Manual→market_hop→clean bank of 1,650, physically reached its requested waypoints and recorded no camera blockage or bail. This was a route-driver choice, not evidence of a broken gate or canopy collision.

The covered driver now uses actual push/brake movement to `(93,0,1.5)` on the south apron before approaching covered gate 1. No point is teleported. New witnesses record actual route/index changes, positions and speed:

| Requested route | Observed ordered gate states | Active time to delivery | Camera samples / blocked / hidden | Bank / wins / bails |
|---|---|---:|---|---|
| Covered | covered 1 at `(112.09,-4.46)`; 2 at `(113.91,5.05)`; 3 at `(113.99,15.96)` | 10.90 s | 672 / 0 / 0 | 1,650 / 1 / 0 |
| West | west 1 at `(101.04,-4.69)`; 2 at `(102.90,4.98)`; 3 at `(102.99,15.99)` | 8.68 s | 540 / 0 / 0 | 1,650 / 1 / 0 |

Gate coordinates in the table are actual X/Z rider observations inside the unchanged acceptance radii. Actual arrival and camera visibility start the earned spare-parcel response; pause, bounded completion, reduced motion, no repeat, northbound return through the shelters, lifecycle and save isolation pass. The shared capture-driver API and observer stages remain unchanged.

## Identity and limits

The tested modules are `tests/cat_encounter_tests.gd` SHA-256 `9dd88c3e6e4959aac3b8e8ab3693cd52289a5af25f1a9267d8b9fb6116d0afe0` and `tests/market_encounter_tests.gd` SHA-256 `9a14333071214314f1d24ff67a55114cfeb8f6d6eb7ca979ee6405c44436bcf1`. Both are held unchanged after this passing run.

Each physical route starts from one declared supported fixture and directly aims grounded heading; subsequent position, velocity, speed, score, capture, gap, bank and success are never injected. These are idealized scripted feasibility results, not natural-steering, human discovery, fun, real-time performance or Mac/DualSense acceptance. Pure callback boundary tests remain distinct from physical routes. [BIN-CATS](../BIN-CATS.md) and [MARKET-DELIVERY](../MARKET-DELIVERY.md) preserve historical actor/render/native evidence and its earlier timings; those captures were not refreshed by this headless run.
