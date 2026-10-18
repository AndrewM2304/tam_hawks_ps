# Existing Exchange facade pilot

Implementation checkpoint, 18 October 2026. Normal play remains disabled until acceptance. Original source and reproducible fitted assets: [fitted generator](../../../art_source/glasgow_bay/fitted/README.md); [runtime assets](../../../game/art/assets/glasgow_bay/README.md). [Integration contract](../../planning/GLASGOW-BAY-INTEGRATION.md) records exact placement and gates. Previous performance/native results predate this pilot.

Independent focused headless checks pass **32/0**, clean exit 0. They inspect actual disabled/enabled worlds, unchanged complete collider/rail/route records, all shell triangle areas, full transformed remaining front records, neighbour doors/signs, fitted threshold geometry and shared material/texture resources. Rendered native selection, current visual integration, route/camera replay, A/B/A timings and required aggregate remain pending. Do not infer performance from triangle counts or a headless renderer.

## Resume gates

1. A09: real Compatibility native-LOD sweep in both directions; no holes, overlap or hysteresis chatter.
2. A01/A05: matched disabled/enabled existing-world spawn, chase, threshold and neighbour images. Retain complete rider/board visibility.
3. A01/A09: exclusive same-source baseline/pilot/baseline timing, draw, triangle and residency evidence at the declared settings. Reject p95/p99 regression beyond repeat noise and 5%; net main-pass budget +4. Mac performance remains open.
4. A01: enable only if accepted; run required `./tools/check.sh` on frozen source, update 75-task handoff, commit/push. Refresh native exports only from checked committed source.

Owner/priority/milestone/dependencies: A01 integration, A05 art, A09 independent QE; P1 existing **M05-001/M06-004/M06-007**, dependent on preserved supported map and performance hardening. No new task IDs or map expansion. Full acceptance remains human/target-Mac dependent.
