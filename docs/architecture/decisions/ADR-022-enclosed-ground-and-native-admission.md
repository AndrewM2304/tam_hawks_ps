# ADR-022 — Give the enclosed connector land real support and calibrate native admission

19 October 2026. Owner A01. Implementation decision under the owner's map repair request/ADR-021; performance and gameplay admission remain evidence gates. No new district, spend, assets, engine or target-hardware change.

## Physical and visual contract

The retained climbing street, station and civic park approach enclose an unbuilt L-shaped space. Existing vertical backing alone leaves sky visible where land should be. `OutdoorRoutes.ENCLOSED_GROUND` owns three fixed local rectangles at Y0.5, listed in [the contract](../../testing/map-flow/CONTRACT.md). Append six actual collision triangles to the existing CentralEmbankment ConcavePolygonShape3D and expose the same height through its existing support-query data. Keep existing guards, ports, paths, recovery, career/save/route/rail identities and the original grass display/culling bounds.

Draw the same six triangles in existing `HorizonContext/CityFootings` using its shared simple opaque vertex-colour shader. This adds no node, draw surface, material, shader, texture, light, callback, collision body or shape. Original horizon geometry/water retains its832-triangle ceiling; a separate explicit six-triangle allowance makes838 combined. Tests independently match the exact six land triangles before excluding only them from the original832 test. A failed old gate is not relaxed for unrelated geometry. The rejected procedural-grass version expanded culling bounds and submitted extra existing terrain; it is not retained.

This is enclosed planted ground within the existing map, not a newly advertised skating district or a hidden recovery floor. Real collision/query agreement is required even behind fences. Full high-layer/aerial coverage and final realistic boundary finish remain open; ordinary route support samples alone cannot close those gates.

## Native benchmark calibration

The Mac has installed official Godot4.6.3 and an Apple M5 GPU. Earlier Linux diagnostics remain historical. Native short-window A/A/A controls reproduce substantial phase spikes with identical mesh/camera/source, so a failed short comparison cannot be causally assigned to six new triangles. Preserve those failures rather than accepting or waving them away.

Final admission uses the same original/candidate/original strict p95/p99 inequalities: candidate ≤ control midpoint + absolute repeat difference +5% midpoint AND ≤1.05×worse control. Report p50, p95, p99, maxima, long16.667/33.333/100ms intervals, draws, primitives and texture/buffer/video counters. Do not infer FPS from geometry.

Before final comparison, calibrate identical scenes. Use equal2-second phase warmups, at least30 wall-clock seconds and600 native post-draw intervals per phase. Preallocate numeric timing storage; collect static counters and create per-sample dictionaries after timing. Archive the loaded observer and validate its hash. Freeze production camera/actor/UI poses equally during stationary timing, keep the same source/settings/layer/FOV/renderer, preserve SurfaceTool compression and tangent representation when reconstructing the six-triangle-free appearance control, and exclude PNG readbacks from intervals. Restore processing only between view setups. Render no other Godot workload concurrently. A separate ordinary mapped-input traversal supplies movement evidence; stationary frozen poses do not certify gameplay or ten-minute1080p performance.

The initial30-second fast-view A/A/A calibration passes; the slower spawn/return ten-second calibrations pass, while the earlier fast ten-second window fails and remains rejected. Use30 seconds consistently at all final views. No existing timing threshold, collider/route preservation check, target-Mac human test or final-art acceptance is waived. Root implements/runs the checks in this session; independent reviewer and physical-controller acceptance are not implied.

## First connector checkpoint admission

Required2189/0, focused40/0, final9/9 matched native comparisons/193,499intervals, corrected639.789m zero-bail spawn↔park drive and66 decoded/hash-verified PNGs pass on373 matching core inputs. [Audit](../../testing/map-flow/audit.json) binds actual captured file hashes to the committed source; old timing/capture failures remain rejected. This closes the bounded connector-fill slice, not broader boundary reconciliation, MAP-03 camera feel, the central park build, human hardware or final art gates.
