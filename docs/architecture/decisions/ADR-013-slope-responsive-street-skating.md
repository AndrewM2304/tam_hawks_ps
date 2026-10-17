# ADR-013 — Slope-responsive street skating

- **Date:** 17 October 2026
- **Status:** Accepted implementation direction under the owner's requested physics hardening; final tuning remains open.
- **Owners:** A01 integration, A04 movement, A09 independent QE.
- **Supersedes:** Only ADR-012's statement that slope gravity and rollback are outside the current street-response repair. Full vert/transition scope remains separate.

## Context

The owner reports that the game does not yet feel like the intended arcade skate game and asks to harden movement while pausing new level areas. Source review confirms that street speed was reconstructed along the board direction at every grounded tick without applying the gravity component along the contacted surface. This makes supported uphill and downhill grades behave like flat ground and prevents rollback after an uphill run loses momentum.

The game already has a world-scale `CharacterBody3D`, actual floor normals, signed tangent directions for rail motion, and collision-adjusted airborne momentum. No new area or movement engine is needed for a bounded street-slope response.

## Decision

1. Project gravity onto the current contacted floor tangent and integrate a scaled **0.28 × gravity** component into signed board-forward ground speed. The existing 15 m/s street-speed limit applies in both directions.
2. Apply release resistance symmetrically so negative rollback approaches rest without changing sign. Existing push and brake inputs can recover forward or stop backward motion; steering, ollie, collision and score rules retain their current owners.
3. Keep the current supported-floor angle and existing maps. Do not add a quarter-pipe, full vert state, lip tricks, wall rides, extra terrain or required career routes in this slice.
4. Review the live CharacterBody on an actual 20-degree supported bank and retain a pure tick-rate/finite-value test. Linux measurements do not close human feel or target-Mac performance.

## Consequences and limits

Slopes now add downhill speed and can roll a rider back down after an uphill stop. On flat ground the gravity projection is zero, so existing acceleration, coast and brake tuning remain unchanged. The selected scale is an initial arcade compromise that must be reconsidered against real Mac play; it is not copied from a commercial game's constants. This change does not implement vertical transitions, pumps, wall rides or exact commercial-game parity. No external asset, dependency or paid service is introduced.

The owner-facing verification and exact movement traces belong in `docs/testing/SKATE-RESPONSE.md` and the current `docs/STATUS.md` / `docs/testing/QE-REPORT.md`.
