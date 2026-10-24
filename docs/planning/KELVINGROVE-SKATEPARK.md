# Sunken Kelvingrove skatepark — active owner request

The owner supplied two actual park photographs on24October2026 and requested a
skatepark within the existing park, preferably top-left/northwest, sunk down with
ramps, rails and different levels so the climb has a destination. This authorizes
routine design/implementation without another approval pause. Use only remaining
included weekly usage; no purchases, paid APIs/resources, publishing or merge.

## Reference and design intent

Root inspected both supplied photographs. They show a broad concrete facility
embedded in grassy banks and trees; several rounded/kidney bowls of different
depths; connected open flat runouts; raised rear decks and stair/hubba/handrail
features; metal flatbars and low concrete ledges. The panorama has a long foreground
bowl/hip, a smaller rounded bowl left and a deeper bowl right. The outer overview
shows the whole facility below its grass perimeter. Photograph date/author were
not supplied. Treat them as visual references only: no bundled photographs, copied
graffiti, real-person likeness or exact-replica claim.

Build an original progression from a gentle roll-in and shallow street basin to
more demanding bowls/hips, with wide usable runouts, supported returns and linked
coping/rails/ledges. The facility must be excavated from real terrain: no original
hill collision through bowls, hidden support planes or cosmetic hole over solid
hill. Preserve the existing summit, both park lap branches/gates and all career/
save identities. Add a clear connected uphill approach and map/navigation cues.

## Ownership and existing task IDs

- World/level_polish owns actual site/terrain cut, exact support query, perimeter
  collar/retaining treatment, existing path/fence adjustments, new access and world
  registration. M03-012/014 and M05-001, P0.
- Transition specialist owns new `game/levels/kelvingrove_skatepark.gd` geometry,
  native bowl/transition construction and facility API. Reuse the tested real
  transition interfaces and publish exact footprint/deck datum before integration.
  M02-011/M03-012/014, P0.
- Feature specialist finishes ground-conforming park gate paint, preserving all
  existing challenge centre/radius/order/timer/score rules. Coordinate terrain
  sampler after the facility cut. M04-011/M06-007.
- Root owns shared player/Main/camera contracts, integration and durable records.
- Independent QE owns natural-input approach, multi-level skating, bowl/quarter
  support/lip/air returns, actual grind/transfer, safe exit, camera, score/reset,
  render/motion, full regression and current-source package proof. M06/M07.

World and geometry owners agreed the grid-aligned footprint
`Rect2(-227.5,-202.5,40,30)`, origin`(-207.5,14.5,-187.5)` and upper rimY14.5.
Local ground is approximately13–17.8m. The six-metre-wide east entrance is centred
at`(-187.5,14.5,-182.5)`, connected to the existing summit terrace roughly8.5m
east. Lower western sites would create a raised fort rather than a sunken park.
The [integration contract](../architecture/decisions/ADR-017-sunken-kelvingrove-skatepark.md)
records the exact support, finite opening and registration interfaces.

## Acceptance

Native collision, visible mesh and support-height queries agree at every seam.
Every inviting coping/ledge/rail has finite usable grind coverage. The beginner
route can enter, circulate and leave without a mandatory jump; advanced surfaces
support real carving, air/re-entry, transfers, lips and linked tricks. Record actual
mapped-input journeys and exact once-only score results, preserve existing laps,
review close/ground/wide frames and continuous motion, then refresh the full suite,
cold-source launch and local packages. Human Mac/controller/feel/final-art gates
remain honest and do not stop independent work. A prior core checkpoint is not
FULL_FIDELITY_ACCEPTED for this new scope.
