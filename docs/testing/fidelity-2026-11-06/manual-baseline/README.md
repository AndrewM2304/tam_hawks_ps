# Independent manual landing-window baseline

Clean production source: main `0b620358767c9c647dde66945377d99702c85d0b`, isolated baseline archive. Source game/tests/tools/project hashes were unchanged against the retained [baseline inventory](../baseline/source-before.json) after this run. This diagnostic did not take a fresh inventory immediately before launch; its [receipt](receipt.json) discloses that limit. A later acceptance run must have a proper two-sided source freeze.

Godot 4.6.3, Linux headless, dummy audio, fixed 60 Hz. Normal default Main with persistence and personal Music control disabled. Each independent case restarts only at the boundary, settles for 40 ticks, pushes for 40 ticks, holds ollie for two ticks, releases to jump and performs a real flip. All subsequent motion, contact, manual state and score come from production physics and mapped Input actions. No per-tick position, velocity, heading, balance or score assignment occurs. Real left/right correction input keeps admitted baseline manuals balanced.

Exact [observer](observer.gd.txt), [engine log](engine.log), [summary](summary.json), [receipt](receipt.json) and gzip-compressed [full native trace](baseline-matrix.json.gz) are retained. The trace expands to the exact JSON SHA-256 in the receipt, with all 12 cases × 96 consecutive native observations and **zero omitted physics ticks**. All cases land without bail. The 26/0 checks verify setup, native landing and Music isolation; they do not declare the desired manual linking improved or accepted.

| Request relative to actual floor contact | Manual entry | Ollie/flip combo |
| --- | --- | --- |
| No request (calibration) | None | Banks 800 at tick 52 |
| Held 100 ms before | Contact tick 31 | Remains linked/unbanked |
| Held 200 / 300 / 450 ms before | None | Banks 800 at tick 52 |
| Held at contact | Tick 31 | Remains linked/unbanked |
| Held 50 / 200 ms after | Tick 34 / 43 | Remains linked/unbanked |
| Held 400 ms after | New manual tick 55 | Previous 800 already banked at tick 52 |
| Pressed 200 ms before, released four ticks later | None | Banks 800 at tick 52 |
| Stale held since takeoff (500 ms before) | None | Banks 800 at tick 52 |
| Forward–neutral–back gesture begun 200 ms before | None | Gesture request expires; banks 800 at tick 52 |

Every case has actual floor contact at tick 31 after release. Timing uses calibration contact, then records each case's actual contact separately. The observer preserves trick, landing, link-start/link-end and bail events, pending deadline, bank changes and request/gesture state. The early input expires under the existing 0.12 s request buffer. This is **FID-D006**, a reproduced usability limitation under the owner's requested more reliable links, not proof of incorrect score banking. Stale holds and cancelled requests being rejected are useful existing behavior to preserve under a deliberate new admission window.

Reproduction: restore the observer as `.local/qa-fidelity/landing_matrix.gd` in the clean archive, import once, and run:

```sh
./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/qa-fidelity/landing_matrix.gd -- /absolute/output/baseline-matrix.json
```

This is a bounded native diagnostic, not visual motion, physical-controller, fun or target-Mac evidence. Candidate controls/mapping need independent native and moving UI review. Actual air→manual→air and bank-once behavior remain covered by the existing combo suite and require current integrated retest.
