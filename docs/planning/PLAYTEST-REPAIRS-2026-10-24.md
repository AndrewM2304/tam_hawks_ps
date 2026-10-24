# Owner-authorized playtest and regression repairs

Owner24October2026: fix all reported items and remaining20 regression failures.
This renews bounded implementation authority; no spend, background loop, new
agents, unrelated features or publication. Current branch review/owner-playtest-20261024.

Owner for every row: Codex. Milestone M01/M02/M03/M05/M06 as applicable.

| ID | Priority / milestone | Dependencies | Acceptance and tests | Status |
|---|---|---|---|---|
| PLAYTEST-01 |P0 / M01| Existing anatomical rig | Reachable continuous knees/limbs, no folding through torso; native pose traces and captured motion | QE review — automated pass; owner feel/visual gate open |
| PLAYTEST-02 |P0 / M03| Summit junction | Continuous visual/native grade; supported bidirectional/diagonal low/high-speed traversal | QE review — automated pass; owner feel/visual gate open |
| PLAYTEST-03 |P0 / M02| Bowl contact/air | Ordinary tap/charge returns within bowl; fresh forward/transfer exits; held input negative tests | QE review — automated pass; owner feel/visual gate open |
| PLAYTEST-04 / REG-01 |P0 / M01/M06| Contact/air frame | Six camera regression failures repaired; clear rear follow and one apex arc; ordinary quiet jump retained | QE review — automated pass; owner feel/visual gate open |
| REG-02 |P0 / M02| Native grind transfer | Six pivot failures repaired with real unweight/turn/reseat and one earned award | QE review — automated pass; owner feel/visual gate open |
| REG-03 |P0 / M02| Current board/shoe geometry | Three sole-contact failures investigated against actual mesh; retain independent real contact assertions | QE review — automated pass; owner feel/visual gate open |
| REG-04 |P1 / M02| Clip/catch timing | Fresh second flip after legal catch; reject overlap/held command | QE review — automated pass; owner feel/visual gate open |
| REG-05 |P0 / M01/M03| New bowl lip camera | Two clearance failures repaired without loosening collision/framing tests | QE review — automated pass; owner feel/visual gate open |
| REG-06 |P0 / M03| Compact native routes | Two real return-route failures repaired; no teleport/new gap award | QE review — automated pass; owner feel/visual gate open |
| PLAYTEST-05 |P1 / M05| Existing shared materials | Coherent deck/wall/bank/retaining/step/hardware coverage; matched captures/counters | QE review — automated pass; owner feel/visual gate open |
| PLAYTEST-06 |P1 / M05/M06| Opening motion diagnosis | Proved lighting cause repaired with contact shadows retained; moving matched comparison | QE review — automated pass; owner feel/visual gate open |

Preserve sunken Clyde bowl and all75 full backlog bodies. Existing acceptance
details in OWNER-PLAYTEST-2026-10-24.md remain binding. Performance ceiling for
this repair batch: no added textures, material resources or draw surfaces; no
per-frame mesh reconstruction; geometry-only junction rebuild stays within
1024 extra triangles,256KiB mesh memory. Record p50/p95/p99 and long frames with
draw/primitive/memory counters, without claiming uncontended target performance
from headless tests. Run required tools/check.sh and capture native frames.

Implementation complete. Required check4555/0, clean/frozen; native path/bowl/limb,
camera, materials, shadows and performance evidence is recorded in
[the repair report](../testing/playtest-repairs-2026-10-24/README.md).
[ADR-031](../architecture/decisions/ADR-031-owner-playtest-repairs.md) records the
material/physics decisions and exact test-fixture corrections. No release or
physical-controller acceptance is implied. All75 original backlog bodies remain
unchanged; unrelated work remains outside this bounded repair.

Measured frame gates: after p95 may add at most max(2ms,15% of baseline p95), p99
at most3ms, with no additional >33.333ms frames. Seven corrected source-frozen
view/gameplay comparisons pass. These are limited native Mac diagnostics, not
uncontended device certification. Fixed60Hz inputs/initial scene ticks make the
workloads reproducible; no full-suite or other render job overlapped admission.
