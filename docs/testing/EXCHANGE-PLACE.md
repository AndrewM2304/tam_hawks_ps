# Exchange/gallery place — independent focused QE

17 October 2026. The two new Exchange attachments pass **22 checks, 0 failures**, exit 0, with clean engine/script scans. The unchanged module was rerun after the final low gallery body/roof and frieze correction; its complete output, real 5,000-point line and route measurements match the earlier focused pass byte for byte. The [focused log](logs/exchange-focused.log) covers actual movement and collision against this corrected gallery source, west seating edge, shared column solids and published routes. The corrected 22-frame set also passes bounded independent review. The final ordinary aggregate passes **1,155/0**, including these 22 checks; the same-source native export/audit and normal Linux startup also pass, with actual Mac launch still open.

```sh
./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 \
  --script .local/exchange_qe_probe.gd
```

The temporary SceneTree wrapper creates Main with persistence disabled, invokes `await ExchangeTests.run(tree, game, check)`, counts assertions and exits nonzero on failures. The committed module is `tests/exchange_place_tests.gd`, invoked by the durable `./tools/check.sh` suite. Its 22 checks are included in the aggregate, not an additional total.

The [ordinary source receipt](logs/exchange-gallery-source.json) records exit 0, no engine/script errors and **162 unchanged inputs**; independent rehash matches all of them. The [ordinary log](logs/exchange-gallery-final.log) SHA-256 is `0313be0238a3288f4f75ce4f94e3afb85020ec4d201051c817eb53552076399a`. The new gallery combo again banks 5,000 once with 324 clear camera samples. The preserved career circuit completes all ten goals at **75.22 simulated seconds**, returns at **88.02** after **1,199.39 m**, and earns **20,000 banked / 3,200 best**, with zero bails/stalled frames. Existing Mo/Rae/Mairi and terrain checks also pass. These ordinary-run results are separate from the fixed-60-Hz focused timings below; current native export/audit/startup receipts are recorded in [native-exchange-gallery](native-exchange-gallery/README.md).

## Real routes and protected access

All five new routes are traversed in both directions using ordinary push/brake inputs and production CharacterBody motion. Tests check every waypoint, real slope contacts and height changes, endpoint support, bails/stalls and the production chase camera. There are no bails, stalled frames, obstructed chest-to-camera samples or out-of-frustum rider samples.

| Runtime route | Forward / reverse simulated seconds | Camera samples, both directions |
|---|---:|---:|
| `gallery_entrance_bank_loop` | 4.65 / 4.63 | 557 |
| `gallery_entrance_front_return` | 3.08 / 3.10 | 371 |
| `gallery_entrance_bypass` | 7.38 / 7.38 | 886 |
| `exchange_west_bank_loop` | 5.47 / 5.55 | 661 |
| `exchange_west_bypass` | 2.03 / 2.03 | 244 |

The bank routes physically climb/descend the 0.65 m gallery and 0.45 m shopfront attachments. The gallery bypass preserves both X±22 spines and the Z−22 cross-court line; the west bypass preserves the default spine beside the new seating edge. Separate short physical trips in both directions verify the station south port and cone/east-spine corridor. Actual rays hit all eight exposed column shafts above their bases, while a rider-sized capsule sweep clears the crossing in front of the portico. Existing full terrain/career suites retain their broader ports, fountain, stairs, three side acts and ten-goal obligations.

## Actual bank/ledge combo and input diagnosis

The continuous combo begins at supported board spawn `(-18, 2.8, -35.3)`, settles onto Y2, and uses actual push/brake to approach at approximately 6.5 m/s. It climbs **0.274 m** of the real side bank before the first ollie, captures **`Grind_Ledge_GalleryEntrance` exactly once**, follows the bend into its south-facing exit, rail-ollies, performs Kickflip/Melon Grab, and lands into a fresh Manual before releasing the line.

The real trick sequence is `Ollie → Rail Grind → Ollie → Kickflip → Melon Grab → Manual`. Ordinary repeated-trick scoring banks **5,000 exactly once**: `(100 + 200 + 50 + 300 + 250 + 100) × 5`. It has zero bails and **324 clear/visible production-camera samples**. No subsequent gallery-stair gap or fountain grand line is claimed.

The [first diagnostic](logs/exchange-initial-input-diagnostic.log) reports 19 passes/3 failed combo assertions. The full-push approach launched at 13.66 m/s with upward bank velocity, so the normal ollie rose to approximately Y5.41 and passed the short ledge before descending. An isolated actual-input probe established the cause. Ordinary braking produced a capture at approximately `(-3.64, 3.20, -35)`; the final driver uses that moderate approach. **No production geometry, controller, capture rule, score rule or assertion was weakened to obtain the pass.** The final test also measures the grounded ascent strictly before the first jump.

## Capture API and evidence limits

The first 22-frame capture reproduced the full real line but its tall generic gallery facade failed the place-identity review. Its manifest and key images remain [diagnostic evidence](screenshots/exchange-gallery-diagnostics/README.md). The corrected [matched capture](screenshots/exchange-gallery/README.md), recorded **18:39:01 UTC**, shows the lower pale gallery, closed roof and readable frieze name. Independent audit matched all **164 source inputs**, **22 PNG hashes** and **1280×800 dimensions**; manifest SHA-256 `8c6122729aad2fda9c7c609fb6c53dda36accec62c41e3cef0571f7484b9e39e`, with 44 runtime routes and unchanged source throughout. Every changed image was inspected; other views match the inspected first set byte for byte. Actual stages 18–22 show the ascent, captured ledge, rail-to-air, connected manual and clean 5,000-point bank. No remaining blocker was found in the reviewed seat/base and door contact, material joins, chase views or HUD states. This is bounded development acceptance, not final realistic-art or human-play acceptance.

`combo_fixture(game)` returns the initial board-spawn position and heading. After settling that one supported fixture, `drive_ledge_combo(tree, game, observer)` drives the complete line. Awaited observer stages are `bank_ascent`, `captured`, `rail_air`, `manual` and `banked`; the capture runner reuses this function and fingerprints the test source. Observers may inspect/render actual states but cannot manufacture progress.

Grounded heading is aimed directly. After each declared initial fixture, the driver never assigns position, speed, velocity, capture, trick, bank or success. Airborne steering remains ordinary input. These fixed-60-Hz timings establish idealized physical feasibility, not natural turning, unaided discovery, human difficulty, frame rate or enjoyment. Camera sampling is geometric evidence for these routes, not every possible view or camera comfort. Profile persistence stays disabled. Real Mac/DualSense, listening and final realistic-art acceptance remain separate gates.
