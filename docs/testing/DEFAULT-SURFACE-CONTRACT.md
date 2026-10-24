# Default surface contract after fidelity integration

The merged level retains the latest default semantic edge candidates and native geometry. A published candidate identifies a visible edge; actual production capsule clearance still decides whether a particular approach or short ride is usable. The dense regression samples every published track and treats the following inherited obstructed portions as explicit negative cases. It requires every unlisted track to pass the same native checks.

These candidates are retained rather than made traversable through their adjacent solids. Other usable bench fronts, stair cheeks, counter edges and authored feature tracks remain positive cases. This is a known limitation of the current candidate; it is not universal affordance or full-fidelity acceptance.

| Candidate ID | Preserved physical obstruction |
| --- | --- |
| `clyde_half_west_coping` | retained landward halfpipe wall blocks an interior coping approach. |
| `Grind_Edge_StairCheek_x-1000y90z-900_3_0` | inner stair cheek meets the adjoining native stair solid. |
| `Grind_Edge_StairCheek_x1000y90z-900_3_0` | inner stair cheek meets the adjoining native stair solid. |
| `Grind_Edge_MarketCounter_x10800y60z200_0_0` | stocked counter approach intersects its preserved native goods. |
| `Grind_Edge_MarketCounter_x12000y60z200_2_0` | stocked counter approach intersects its preserved native goods. |
| `Grind_Edge_StreetBenchSeat_x-12700y200z2800_0_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x-12700y200z2800_1_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x-12700y200z2800_3_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x6000y0z4150_0_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x6000y0z4150_1_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x6000y0z4150_3_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x2900y600z-11600_0_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x2900y600z-11600_1_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x2900y600z-11600_3_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x2900y0z2700_0_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x2900y0z2700_1_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |
| `Grind_Edge_StreetBenchSeat_x2900y0z2700_3_0` | backrest or end-frame obstructs part of this inherited seat-edge candidate. |

`tests/surface_coverage_tests.gd` records the first actual failed approach/ride witness for each ID and requires exactly this set. The native capsule, collision masks, margins and sweep thresholds are unchanged. It separately requires every bench front edge to remain usable. The same test accepts both existing metadata associations (`grind_surface_ids`) and authored associations (`authored_grind_ids`) on the actual hit collider; it does not invent support or fill the real slat gaps.

The retained compact Clyde quarter and the promenade quarter replace the obsolete out-of-bounds Clyde practice fixture. The terrace containment probe uses the current default maximum flat-ground charged jump height, rather than the removed high-pop physics. Rendered-mesh/native-bearing checks query each track's actual contact datum, including the retained lowered-cylinder metadata.

The bounded adapted surface regression passed77/0. The exact17 native refusal witnesses are recorded in [DEFAULT-SURFACE-OBSTRUCTIONS.json](DEFAULT-SURFACE-OBSTRUCTIONS.json); the final global source-guarded aggregate remains authoritative. Default semantic seat guides carry their retained40mm world-up clearance skin, which is removed only for the independent wood-face measurement. Changing-grade outdoor beam samples check real segment crowns without falsely certifying the polyline joints.
