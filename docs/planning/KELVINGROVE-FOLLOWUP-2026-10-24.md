# Owner screenshot defects —24 October2026 follow-up

25 October planning handoff: owner tested this unfinished local candidate and
supplied 38 debug captures. [PT24-01…30](DEBUG-SESSION-2026-10-24.md) now owns
the next cloud queue and exact witness mapping. Existing changes are candidates,
not certified fixes; no implementation continued during the planning review.
The evidence packet preserves a recoverable candidate patch for cloud work.
POSE-02 remains unresolved; do not infer it fixed from neutral-pose checks.

Baseline7e4d263; feature `fix/kelvingrove-owner-defects-20261024`.
Earlier narrow checks did not certify these areas. Owner evidence reopens them.

| ID | Owner | Priority / milestone | Dependency | Status | Acceptance and tests |
| --- | --- | --- | --- | --- | --- |
| WORLD-EDGE-02 | A01/A05 | P0 M03/M06 | Locate screenshot's station/park mouth | In progress | No unmarked unsupported straight-ahead exit; visible native guard or continuous ground; real input approach and jump probes. |
| WORLD-JOIN-02 | A01/A05 | P0 M03/M06 | Existing city/outdoor terrain | In progress | No route under closed building masses; no zigzag overlapping approach surfaces; independent rays, displayed coverage and real traversals. |
| PARK-FLOAT-02 | A01/A05 | P0 M03/M06 | Kelvingrove path/terrain | In progress | Supported planted hip/ledge and flush bottom-right entrance/junction; native/visible side coverage and traversal. |
| PARK-WALL-02 | A01/A05 | P0 M03/M06 | Existing sunken facility | In progress | Actual retaining faces close unintended street-basin sides; deliberate entries stay open; inside/outside native captures and collision checks. |
| POSE-02 | A01/A04 | P0 M01/M05 | Reproduce screenshot pose | In progress | Explain live cause; hips/torso/knees remain anatomical through repeated entry/reset/charge, ramps, bails and ordinary play, with captured real frames. |
| FOLLOWUP-QE | A01 | P0 M06 | All above | Planned | Full tools/check.sh; frozen source native frames and matched cost; report unverified owner/hardware gates honestly. |

Budget declared before changes: reuse materials/textures; at most12 extra visible
submissions,10 bodies,32 graded collision panels and4000 triangles across this bounded repair.
Prefer extending existing bodies/meshes. No new lights or per-frame mesh rebuild.
Target matched frame p95/p99 ≤20% worse, no additional >33.333ms intervals; keep
texture bytes unchanged. Broader stutter and final-art/hardware gates stay open.
Source construction fixes only; no new district, feature or copied assets.

Owner confirms first gap is Station→Kelvingrove. Add a visible supported L guard
at the straight-ahead/south edge of that mouth, keeping the northbound climb open.
The boundary needs graded native panels, hence the pre-implementation32-panel
ceiling above; no per-tick work or new materials.

Owner additionally requests a local debug capture session. DEBUG-01, A01/A08,
P0 M06, In progress: one-button screenshot/state capture, paused note entry,
controller menu, and end-session ZIP. Acceptance: saved image matches report
camera/player state; input/history/pose/engine log evidence included; cancelled
notes preserve the capture; error states keep local evidence; ZIP independently
readable. Tests must exercise real capture/notes/pause restoration/archive paths.
Inactive recorder adds no sampling; active history limited to40 samples/10s and
128 input events. Capture/archive I/O occurs only on explicit user action.

Owner shortcut correction: **1** capture/start, **2** recorder menu, **3** finish ZIP.
Numbers must remain ordinary text while editing a note; no function keys.

Native intermediate report:564 bodies/1674 shapes (+5 north retaining boxes,
+2 arrival guard bodies with15 graded panels). Horizon mesh is892 triangles
(+18 reserved =910 ceiling),64 more than the old846 ceiling due to the new
guards and changed supported contour baselines; within declared4000 total delta.
First native captures and recorder12/0 are REJECTED because the earlier878
horizon ceiling asserted. Corrected the measured ceiling before final admission.
