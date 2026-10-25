# Bounded native captures — 25 October 2026

**44 frames, zero failures, clean logs and unchanged source bindings.**
Run `python3 docs/testing/pt24-next-2026-10-25/captures/verify.py` from the
checkout to verify current source, every image hash/dimension, paired camera
positions and logs. [Audit](CAPTURE-AUDIT.json).

## Ordinary and preview construction

[`pt24_next_design_capture.sh`](pt24_next_design_capture.sh) launches
`tools/pt24_design_capture.gd -- --run-layout` on a real Xorg/Mesa llvmpipe
Compatibility display with the normal render loop. Twenty1280×800 readbacks
await completed processing and `frame_post_draw`. Actual Main is built once
ordinary and once with its explicit preview. Music persistence/control is
asserted inert before gameplay entry. [Manifest](design/manifest.json),
[raw log](pt24-next-design.log).

The original twelve startup/owner/station/pond/cable views remain. Four added
paused overviews show the [upper park seat](design/default-park-seat-approach.png),
[lower runout](design/default-park-seat-runout.png),
[cleared bridge arrival](design/default-clyde-cleared-arrival.png) and
[relocated bank](design/default-clyde-bank-bowl-return.png).
Integration inspected these and the contact frames before combined validation.

Two additional diagnostic stills render explicitly assigned poses on actual
Main/native terrain: [Civic Manual](design/default-civic-manual-contact.png) and
[Clyde bowl](design/default-clyde-bowl-contact.png). Initial actor position,
heading/manual state and production pose/fit calls are recorded in the manifest.
The bowl uses the existing fixed-contact test presentation helper. Physics is
paused: these images do not prove earned tricks, ordinary camera-follow or
motion. The separate mapped-input regressions own those results.

## Matched display controls

[`pt24_next_temporal_before.sh`](pt24_next_temporal_before.sh) and
[`pt24_next_temporal_after.sh`](pt24_next_temporal_after.sh) use
`tools/pt24_temporal_probe.gd -- --witness=5,16,17,18 --samples=3`.
Each mode has twelve world-only readbacks, an identical one-metre analytic
approach from each exact owner camera, frozen simulation and unchanged global
shadow/renderer settings. The before mode skips the **entire** existing display
repair helper, including previous quay/coping/plinth repairs. It is not a
control that disables only this batch's new repairs.

[Before manifest](temporal/before/manifest.json),
[after manifest](temporal/after/manifest.json),
[before log](pt24-next-temporal-before.log),
[after log](pt24-next-temporal-after.log).
Integration inspected first after frames5/16/17/18: exposed walls/closures remain
visible. Native-byte, replacement-owner and exact overlap tests provide the
independent geometric proof; stills do not establish moving shadow stability.

## Retained rejections and limits

The first eighteen-frame fixture is **rejected**: its manually supplied bowl rig
dictionary omitted required `push=false`, logging an error despite zero image
assertions. [Raw log](rejected/rejected.log) and
[manifest](rejected/rejected-manifest.json) remain. Only the fixture was fixed.
The next clean18-frame run used an obstructed bank overview from behind the
existing facade. Its [image](rejected/obstructed-bank-view.png),
[manifest](rejected/obstructed-view-manifest.json) and
[log](rejected/obstructed-view.log) remain; only that authored camera moved to the
inside of the quay for the final set. Neither rejected set certifies final source.

These are static/source diagnostics on Linux software rendering. They do not
measure p50/p95/p99, certify target-Mac performance or temporal flicker, or accept
human fun/final art. Native render counters are snapshots only. Railway, pond,
green and civic-return candidates remain explicit previews pending admission.

## Final-source last-air controls

The final twenty-frame set adds [reconstructed last-air control](design/default-last-air-control.png)
and [the same frame after fitting](design/default-last-air-fitted.png). Both use
the exact classified actor/visual frames, neutral rig fixture and actual native
UP support. Production fitting changes only orientation; physical actor and
local board frames remain equal, with no translation/lift. These assigned paused
poses illustrate the independent native proof; they are not a recorded flight.
The earlier42-frame manifests/logs remain under `prior-source/` as history and
do not certify the later air/camera changes. Final44 frames are refreshed against
the final source and verified by the current capture audit.
