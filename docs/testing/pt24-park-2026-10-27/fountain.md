# PT24-26 source reconciliation — 27 October 2026

**Existing footprint repair retained; final moving appearance acceptance remains open.**
This is a bounded source review of the owner's [capture 36](../debug-session-2026-10-24/images/issue-0036.jpg), not a new game run or a new repair. The old capture visibly shows a coarse polygonal water edge inside the circular masonry. Recreating that already repaired system would duplicate completed work.

## Current geometry

[`GlasgowSquare._fountain`](../../../game/levels/glasgow_square.gd) builds the basin and water with the same 64-segment `CylinderMesh`, angular phase and upright local frame. At the authored 6.2 m basin radius, water radius is 5.96 m. The deliberate coping margin is 0.24 m at vertices and approximately 0.23971 m between corresponding facets. There is no rectangle, differently phased low-resolution water polygon or perimeter overhang in current source.

The basin's native cylinder has radius 6.2 m, height 0.55 m and centre Y0.275. Its visible cylinder has the same dimensions. Water has height 0.01 m, centre Y0.55 and visible top Y0.555, above the basin top rather than coplanar with it. Existing pedestal collision and all component transforms remain unchanged. The water is a visual surface over the existing solid basin; this slice does not add a fountain water-recovery hazard or alter the pond/river recovery contracts.

`Grind_Coping_ExchangeFountain` remains a closed 64-segment path at radius 6.2 m and Y0.92. Its 0.23 m native cylinders and existing visible cylinders share segment transforms. The declared `glasgow.lowered_cylinder_envelope` offsets remain unchanged. Matching the water to the existing basin does not move this guide or its contact shapes.

The shared `glass` material is retained, including its existing low roughness. No extra transparency pass, shader animation, mesh, material, texture, light, physics shape or per-frame work is introduced by this review. Final water appearance still requires the moving/native owner acceptance already recorded in the ticket.

## Existing evidence, with its original scope

- [`tests/pt24_city_repairs_tests.gd`](../../../tests/pt24_city_repairs_tests.gd) checks matching segment counts, the 24 cm inset, top height and every actual water mesh vertex's containment. It is registered in the required suite.
- [The original repair record](../pt24-repairs-2026-10-25/README.md) records the footprint change, its 272-triangle increase over the old two meshes, source-bound 4,657/0 checks and bounded native frames. Its stills do not prove temporal stability.
- [`tests/grind_contact_metadata_tests.gd`](../../../tests/grind_contact_metadata_tests.gd) preserves the inspected native contact source and offsets. [`tests/topography_tests.gd`](../../../tests/topography_tests.gd) checks an actual mapped push/ollie/capture, curved travel, drop, landing and bank.
- [The latest body/Gallery record](../pt24-body-attachment-2026-10-25/README.md) owns the newer 5,062/0 combined receipt and actual entrance→stair→fountain mapped-input sequence, banking 12,888 once without bails. It is gameplay/contact evidence, not a new water appearance or full coping-lap acceptance.

No new engine run is needed to establish that the original footprint correction already exists. This review neither closes the whole PT24-26 ticket nor claims Mac temporal rendering, whole-lap balance, owner visual acceptance or target performance.
