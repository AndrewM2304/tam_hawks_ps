# Native stop direction and complete-shoe continuity

This C03 follow-up repairs an observed trailing-foot animation pop during the
existing actual Nose Manual→wall impact→Brake sequence. Production focused
checks pass **18/0**; matched native before/after frames pass. Root owns final
combined admission, push, cold launch and packages. Physical movement, input,
score, support queries and their tolerances are unchanged.

## Cause and retained controls

The ordinary arm investigation retained a **253.498 mm ankle-marker step** at
tick82→83, identical in unchanged baseline and arm candidate, in both world and
actor coordinates. This was a separate visual gait issue. At tick81 native
signed speed is−0.715817m/s, tick82−0.349150m/s, and tick83 exactly zero.
The old visual maps any negative sign to backward and zero to forward while
the brake blend remains0.329680→0.269919. The fading shoe therefore changes its
stroke direction and yaw abruptly. Its sole is82.8/111.2mm above the native
floor at82/83: the observed discontinuity is a lifted braking-return transition,
with no actor ascent or new arm-induced body split explaining it.

[Clean scalar diagnostic](observed/native/receipt.json): **4/0 workload
prerequisites**, exit0, clean/stable656 inputs,1.254s. These four assertions
certify the exact native workload, not healthy gait. Parser0.602s, same manifest
`6ad85b8e35571e1cc41d91658d1da638be7f53d754dc4f67ed31dee46f2e659e`.
Every input resolves to653 immutable `98311cb` files plus three exact ignored
observers. The first parser passes; the [first native attempt](observed/first-rejected/receipt.json)
is rejected despite4/0 prerequisites because ignored reset instrumentation
reads an omitted optional key. Its source/log/metrics remain unchanged. The
corrected observer uses the production default and adds no native query.

A paired diagnostic also tries the existing physical Push−0.5 direction policy
only in an ignored visual. It shifts the discontinuity to tick82 and gives a
178.815mm peak ankle step. This does not preserve the direction of actual
backward braking and is not the chosen production repair. The earlier prediction
that it would make the peak larger was incorrect; the measured value is retained.
No physical speed threshold or movement policy changes.

## Production repair and focused checks

The rig retains the last nonzero requested travel direction when native speed
becomes zero. A second visual scalar turns continuously toward that direction
using the existing brake-pose rate12. Position and shoe yaw use the same scalar;
the forward/backward yaw endpoints share one fixed angle interval, avoiding a
shortest-arc branch switch during a reversal. Reset clears both scalars.
Steady forward/backward foot transforms retain their previous output. No new
mesh, material, texture, shape, query or per-frame geometry read is added.

[Production parser](focused/parser/receipt.json): clean, exit0,658 stable inputs.
[Native focused run](focused/native/receipt.json): **18/0**, exit0, clean/stable
658 inputs in2.156s, manifest
`7319cdf7b3808d3691c924decb2157b9405fa5cb019315b1f09963a8f45f871c`.
The index resolves649 immutable parent inputs and nine exact snapshots.

The real110-update Push→fresh Nose Manual→native impact79→Brake sequence keeps
the same physical state as its unfitted twin, both loaded tyres' native support,
connected real clothing and the once-only100-point catalog bank. Maximum actual
sole-vertex step is127.464mm; the formerly problematic tick83 is41.141mm. Every
sampled sole vertex remains above the native floor, minimum0.771mm.

Frozen-body native-floor fixtures then sample the actual rig at30/60/120Hz.
They cover steady forward/backward parity with the legacy direction resolver,
zero-speed fade, genuine backward→forward reversal, actual complete sole corners,
shoe quaternion motion, fixed limb limits, unchanged body, equal-duration
endpoints and reset. These are pose-sampling rates, not display-FPS measurements.
The existing220mm/60Hz displacement criterion is compared as13.2m/s across
different sample intervals; its60Hz bound is unchanged.

| Pose sampling | Maximum sole speed | Maximum shoe angular speed | Minimum sole/floor gap |
| --- | ---: | ---: | ---: |
|30Hz|11.009m/s|31.072rad/s|0.700mm|
|60Hz|11.692m/s|34.168rad/s|0.700mm|
|120Hz|11.921m/s|35.875rad/s|0.700mm|

The native wall rig retains the existing board pose and loaded-tyre contacts;
the reset restores the original planted board/shoe fit. These results do not
claim every intermediate gait variant is free of all shoe/deck intersections,
target-Mac motion acceptance or a measured stutter improvement.

## Matched native frames

[Native execution](native-captures/admitted/receipt.json): exit0, clean/stable
661 outer inputs in16.397s. The inner258-input map is unchanged, all failures0;
the additional exact provenance JSON is retained. Manifest:
`c43214e0ba4894b948e6bb16986bd216a0b5e1b1694a4ba17f01ffb2ffdb4911`.

Both actual skaters run **simultaneously** on the same native floor/shutter and
input history. Before uses the immutable `98311cb` Visual through an otherwise
identical current controller constructor; after uses the normal Visual. Both
rigs are constructed/rendered before measurement. Every native physical-history
sample matches exactly. Only after completed native tick83 are both frozen and
the opposite figure hidden for each identical-camera readback. No actor pose,
velocity or trick assignment establishes the result.

| Same82→83 metric | Before | After |
| --- | ---: | ---: |
|Maximum corresponding actual sole-vertex step|369.640mm|41.141mm|
|Actual shoe quaternion angle|54.584°|7.040°|

The earlier253.498mm value is the ankle marker; it is not substituted for the
369.640mm complete-outline negative control. Both images are960×640 and retain
**98 objects,98 draw calls,62,212 primitives,19,665,182 texture bytes and
29,030,906 video bytes**. Native position/velocity/speed/heading, local board
pose, contact79 and the genuine Nose Manual event match. Actual board/shoes keep
their original wall skin. Viewed both original PNGs: the shoe preserves its
backward return orientation, with the complete figure attached.

|Before|After|
| --- | --- |
|[Native PNG](captures/before-stop83.png)|[Native PNG](captures/after-stop83.png)|

The [first sequential capture](native-captures/first-sequential-rejected/receipt.json)
is retained and **rejected**: its actors do not have the same native rebound,
and video-resource membership differs by18,056 bytes. It is not admitted as a
physical or resource comparison. The corrected simultaneous fixture retains
the same strict physical-history and counter requirements; no threshold is
waived. Two static native PNGs do not certify ordinary moving-camera rendering,
whole-map frame times, every variant or human acceptance.

Reproduction uses the retained ignored command scripts restored from their
execution snapshots. Repeat runs own their new source identity; they do not
replace these receipts. No additional engine run is needed for prose changes.
