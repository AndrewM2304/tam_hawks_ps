# Opening shadows and City Chambers right-side gap

Owner report24October2026; right side confirmed facing Chambers from the square.
Feature branch `fix/spawn-civic-surfaces-20261024`, baseline76e43f1.

| ID | Owner | Priority / milestone | Dependencies | Status | Acceptance / tests |
| --- | --- | --- | --- | --- | --- |
| SURFACE-01 | A01/A05 | P0 M03/M06 | Existing terrain and boundaries | QE review | Close the unsupported east civic strip and fence end; native ground/query/visible paving agree, capsule route cannot fall through. Preserve other routes. |
| SHADOW-01 | A01/A05 | P0 M06 | Exact opening graded-road reproduction | Open | Identify shadow-only variation using matched on/off frames; retain building/rider shadows and reject cosmetic hiding. Native before/after motion captures and counters. |
| SURFACE-QE | A01 | P0 M06 | SURFACE-01 repair; shadow repair remains separate | Done (automated) | Required tools/check.sh passes, native captures inspected, source-frozen receipts, exact limits recorded. Owner visual acceptance remains open. |

Budget before implementation: reuse materials/textures; no new per-frame mesh,
query, light or rendering pass. Extend existing terrain where possible; at most
128 extra triangles and no extra textures. No draw/body increase for the civic
repair. Rendering gate: matched native workload p95/p99 no more than20% worse,
no added frames over33.333ms, no new texture memory. These small diagnostics do
not close the broader stutter, physical-controller, export or art gates.

Initial native rays show no world-layer support or height query at x35.25–35.75,
z−127.5…−90, outside the existing east civic floor. Neighbouring wall startsx36.
Baseline captures and receipts are under `.local/spawn-civic-20261024`; selected
reproducible evidence will be retained with the final checkpoint.

SURFACE-01 focused5/0, native frame/cost gate pass. SHADOW-01 remains unresolved;
no diagnostic lighting settings adopted. [Evidence and exact limits](../testing/spawn-civic-2026-10-24/README.md).

Required4560/0, clean/frozen518 inputs; native/focused admissions pass.
Initial4556/4 rejected; exact intentional guard-panel inventory migration retained.
SURFACE-01 remains QE review for owner confirmation; SHADOW-01 stays Open.
