# ADR-023 — skater-relative ramp orbit, airborne pose and extra airtime

19 October2026. Status: implemented with bounded automated/native admission; broader ramp and owner comfort acceptance remains open. Supersedes this session’s level/side-biased and separate world-yaw/pitch candidates. No owner comfort acceptance is claimed.

## Context

The owner specifies: follow the ramp until pointing90° upward, then make ONE180° arc to the skater’s right/left around the apex, ending90° downward, always in the skater’s perspective. Spins/flips rotate the rider independently. Separate world-space yaw/pitch anticipation produced messy extra flips; world-up look_at cannot represent a clean vertical ramp view. The owner also reports the airborne rider flattening and requests higher ramp jumps.

THPS3 remains the reference. [Four-source research](../../research/THPS-PHYSICS-COMPARISON-2026-10-19.md) verifies no THPS3 constants. No external code/assets are copied. Keep Godot native interpolation/shape casts/overlap/rays and the existing bounded collision-orbit chooser.

## Decision

On supported ramps use the unspun contact travel frame. Its normal is camera-up; at a vertical wall that normal is horizontal, permitting a true skyward view without a look-at singularity. In ramp flight, retain launch normal and launch tangent. Rotate camera forward once by0→PI about that normal, using0.36s predicted remaining ascent and14/s follow response as local tuning. Choose one fixed positive side and never reverse that planned angle during the flight. This is one local orbit, not independent global yaw and pitch turns. Actual camera collision can still constrain the path.

Ground arm remains4.9–5.2m/height2.5/FOV64–65.95°. Ramp flight arm3.6m, with a native-collision-shortened minimum1.6m (ordinary minimum3m). A1.6–2m arm can frame the sideways body while remaining above the curved floor at a90° launch; requiring a2–3m arm there would force a side view. Supported arm/lift blend with contact normal towards the existing flat view. Retain near0.2/far220,0.25m camera volume and full body-landmark rays. No world geometry/node/resource additions. Reduced motion fixes speed-dependent arm/FOV; sensitivity and collision safety remain.

Interpolate camera offset on a3D spherical arc. Transport camera-up through near-collinearity and bound roll correction instead of permitting look_at to choose a sudden opposite roll. Seed ordinary world rear/pitch from completed return travel when leaving ramp mode, avoiding a second stale heading turn on landing. A clear ordinary ramp view immediately releases an obsolete collision-side orbit; the ordinary ground-side delay remains. Bound response to one60Hz step and translation48m/s. A bounded fallback checks up to8positions along the existing path, actual swept camera volume and all3landmark rays. If no bounded safe path exists, clipping refusal takes precedence; natural-ramp admission must expose any emergency jump.

Airborne ramp rider/board retains the ramp’s normal and launch tangent instead of requesting zero world pitch. Base orientation makes one local turn as vertical velocity crosses±2m/s, where direction is undefined at the exact apex; fast ascent/descent follows actual momentum. Scored yaw/stance and board/body tricks compose independently. Previous/current base Basis interpolate with Godot’s physics interpolation fraction through `get_camera_support_frame()`/`get_camera_support_up()` for camera framing, excluding trick rotations. Upright free-air physical collision and actual travel remain unchanged by this presentation correction.

Upward curved-ramp departures/genuine lip jumps preserve take-off vector and use22m/s² airborne gravity. Ordinary flat/other flights retain34. Landing/support/grind/reset clears the tag; losing optional return eligibility does not change gravity midflight. This is owner-authorized height/airtime tuning, not franchise parity. Camera controls/candidate must use identical new movement source; old34g flight trajectories deliberately differ.

## Gates and consequences

Require actual camera-output checks for one150–210° local turn, limited reverse winding, skyward/downward endpoints and local camera-up; actual-input spin independence, readable displayed body/frustum/3rays, finite-wall returns and no large per-update zoom/view steps. Verify fast airborne pose forward dot velocity>0.95, launch preservation, real increased rise/tag reset, unchanged flat ollies and containment. Native source-frozen matched timing/physics and separate real phase/route images plus complete tools/check.sh are required. [Contract/evidence](../../testing/camera-flow/CONTRACT.md) retains rejected candidates and exact pending gates. No stutter, human fun, physical DualSense, export, whole-map or unfinished Kelvingrove acceptance is implied.


Full-regression corrections: a stationary supported landing must ease the previous falling pitch back to zero; retaining airborne near-zero pitch under the station canopy collapsed the rear arm to1.405m. The unchanged station test now has zero hidden/blocked/close samples and4.913m minimum distance. Base-frame interpolation orthonormalizes both endpoints before quaternion interpolation: ordinary root interpolation can contain slight scale drift and the compact Clyde circuit exposed invalid-quaternion errors. A dedicated scaled-basis seam test and the full circuit verify this separately from ramp feel. The2205/1 run and errors remain rejected evidence.
