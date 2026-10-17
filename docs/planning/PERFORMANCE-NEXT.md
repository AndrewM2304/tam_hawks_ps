# Performance hardening continuation

17 October 2026. Existing M06-004, M01-005, M05-001/M06-007 and M07 work; all 75 full backlog IDs remain. The owner reports widespread stuttering and prioritizes current-map performance over new areas. Work stays in the authorized interactive session, with a commit/push at each completed task. No purchases, paid services, hosted CI or unattended jobs.

## 1. Current baseline — A01/A09, P0, complete

Dependencies: clean classic-control checkpoint, exclusive renderer window. `profile.sh` measures six actual supported chase views at 1280×800, source stable, 102 frames. Exchange submits 1,930 median draws; Barras 1,617. Receipts and hardware limits are in testing/performance-baseline-20261017. The software renderer is not the owner's Apple M5; target 60 fps is open. Baseline/evidence commit is pushed.

## 2. Static submission and hidden geometry — A05/A09, P0, implemented; integrated verification running

Dependencies: actual authored CPU instance records, final world dressing/parent transforms, exact resource sharing. First edits: explicitly register opaque CityArt batches, synchronize west door threshold records, finalize compatible material/render-state families in spatial cells only when batch count falls. Compare 32 m/48 m/64 m candidates using real renderer records and eight unchanged views; retain before/after images/counters and physics counts. Test inset occluders only inside verified closed facade boxes, never across open canopy/portico/market/bridge space.

Accepted comparison: all 17,742 authored/live records preserved, maximum transform difference under two micrometres; 351 bodies/1,863 shapes unchanged. Selected 64 m batching only: Exchange 1,585→1,302 and Barras 1,284→1,015 draws, Central 567→591. Native occlusion is disabled: exact off/on/off-repeat captures expose missing distant wall planes despite all 23 candidates lying inside opaque boxes. Investigate owner-surface self-culling separately; do not ship the rejected combined savings. The first rejected validator result came from queued startup readback and rounded hash boundaries; actual before/after multiset checks replaced that invalid gate. [Static evidence](../testing/performance-static-20261017/README.md) retains exact inputs/counters and selected frames. Integrated timing, regression and depth-precision checks remain separate.

## 3. CPU presentation and smooth motion — A04/A08/A09, P0, in progress

Dependencies: unchanged 60 Hz authoritative physics and score deadlines. HUD skips unchanged copies/layout while explicit settings/menu/progress updates remain immediate; Career exposes a presentation revision. Interpolation displays between physics frames; per-render camera follows displayed rider/support frame with explicit teleport history reset. Other process-animated actors opt out. Focused tests prove copy isolation, invalidation, responsive balance, physical trajectory equivalence and high-render/low-physics cadence.

Acceptance: measured bounded HUD CPU savings, no invented FPS improvement, no camera/body visibility loss, actual moving/render evidence and complete ordinary suite. Fine-grained profiler captures CPU/physics/driver costs separately. Keep collision/camera query safety.

## 4. Graphics choices and moving measurement — A01/A08/A09, P0, in progress

Dependencies: frozen source and preserved legacy profiles. Settings cycles Performance/Balanced/High. Balanced keeps native render scale and view range, reducing distant shadow coverage; Performance lowers 3D resolution, shadow range and far clip while UI stays native; High keeps previous visual budgets. No FOV/turning/physics change. Older saves default to Balanced; invalid profiles retain normal safe refusal.

Acceptance: actual preset application and profile round trips, no gameplay unload, readable Settings and chase frames. `moving_profile.sh` uses native rendering and actual input-driven quay/market/park trips; monotonic frame CSV, route progress, long frames, hardware/settings and source/artifact hashes are retained. Incomplete slow software-rendered travel must fail its progress gate. Owner's ten-minute Mac/DualSense route and 1080p p50/p95/p99 remain distinct.

## 5. Freeze, verify, push — A01/A09, P0

Run focused failures first, then required `./tools/check.sh` after source freeze, source-cold launch, normal gameplay/UI capture and matched after profile. Preserve all ten goals/three acts, physics and safe recovery. Commit/push each reviewable checkpoint and record tested runtime identity separately from later docs. No old source/capture is relabelled current. Continue with connected clothed hero and one existing Glasgow facade/PBR/LOD proof after performance defects are addressed; do not expand the map.
