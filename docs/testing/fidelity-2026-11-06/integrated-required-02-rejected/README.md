# Rejected complete integration gate02

The complete actual-main `./tools/check.sh` epoch finished with **6526 passing
assertions,7 failing assertions and3 runtime ScriptErrors**, exit1. Independent
QA verifies17 receipt/source/log checks; that verifies the recorded failure,
not the game. The source map has886 unchanged inputs, including the exact ignored
launcher and ordinary executable entrypoints.

Actual bounds:7November2026 07:30:28.420012→08:07:49.796105UTC,
2241.249264s within the declared2400s deadline. The dirty main source was based
on97d72fa; it is not a tested clean commit or evidence for later fixes.

Failures remain separately actionable:

| Count | Observed failure | Owner / next gate |
| --- | --- | --- |
| 1 | C04-L05 bowl-side return loses strict ordinary full-body chase clearance. | Rigging/motion; actual model/contact/camera diagnosis and same input replay. |
| 2 | Authentic board tests still expect the pre-UV source fingerprint at both rest rotations. | Board; deliberate source-identity migration with all native protected-part guards preserved. |
| 2 | Horizon/SkateEdges route expectations omit the new authorised optional east-quay return. | Root; independently reviewed test-only fixed-ID/count migration, then native retest. |
| 2 | Held lip catch and deliberate associated-air→coping-grind tests do not capture the real coping. | Motion/level; current native profile/guide/input diagnosis, not relaxed capture criteria. |
| 3 ScriptErrors | `_air_forecast_owner_bounds` casts an object after its owner is freed. | Motion; reject stale owner before cast/query; real free/reset negative and original forecast parity. |

The final CLI Music launch stage did **not** execute after Main failed. Earlier
Music isolation subsets remain separate. Newly integrated native line, forecast,
board and fitted subsets do not erase these full-run errors. No complete technical,
package, normal-speed visual, physical-controller, M5 or AAA pass follows.

Original command/native/import logs and source maps are retained as lossless gzip,
with original hashes still bound by the unmodified wrapper receipt. Long native
physics records are preserved without truncation. `runner.py.txt` is exact and
before-bound. No runtime-source snapshot duplication is added.

```sh
python3 docs/testing/fidelity-2026-11-06/integrated-required-02-rejected/verify-preservation.py.txt
```

`independent-audit.py.txt` is the full17-check read-only audit against the ignored
original `.local/fidelity-checkpoints/required-02` packet. The portable verifier
checks the committed compressed originals and final failure facts directly.
