# Complete skating process verification — 24 October 2026

[ADR-015](../architecture/decisions/ADR-015-complete-skate-process.md) records the
owner's expanded request and the original arcade tuning. Use only remaining
included weekly usage; no tokens, resources or billing were purchased.

The implementation covers charge/release and setup pops, buffered actions and
double-flip upgrades, functional stance/aligned landings, powerslides, rail
changes/lateral hops, manual gestures/extensions/pivots, native walls/wallies,
full 90-degree transitions/lips/re-entry/deck transfers and maintained specials.
The existing career and side challenges retain their identities and actual routes.

The world audit inventories357 physical level bodies,55 eligible wall bodies,
45 ledge bodies with paths and111 grind tracks. Two purposeful practice pockets
fill existing quay/park space while preserving runouts. The
[surface audit](../levels/OVERNIGHT-SURFACE-AUDIT.md) records exclusions explicitly.
Visual review prompted concrete grain/material changes, flatbar supports and
retaining foundations. Original procedural materials add no external assets.

## Defects reproduced and repaired

- Native quarter-pipe toe/lip rays could select coincident floor/deck corners.
  Probing a small distance inside the real finite face removes order dependence
  while movement still reaches the exact90-degree lip.
- First transition contact plus a release-pop could skip an unfinished incoming
  flip/spin check. The contact now validates before another launch is admitted.
- Expired gestures could latch a later held Manual; held Flip could retrigger
  after a bail. Gesture expiry and held-state synchronization prevent both.
- Backwards powerslide yaw opposed ordinary steering; rail Nollie styling and
  reversed-deck nose pitch were inconsistent. Real-input regressions cover these.
- Transition movement retained native floor flags after associated-air exit.
  The first ordinary tick now applies gravity and cannot manufacture coyote pop.
- Actual wall images exposed torso/head penetration. The visual bank now points
  away, with the wheels offset to native side contact and facing aligned to travel.
- A purely vertical ascent displayed0 km/h. HUD transition speed now reflects
  actual 3D velocity, preserving signed physical speed for handling.
- Elevated park practice could clear its old perimeter. A supported shoulder and
  visible taller retained fence now block the reproduced ordinary-deck-ollie case.

## Evidence gates

Final current-source `./tools/check.sh` exits 0: **1,817 passed, 0 failed**, with
213 unchanged inputs and clean import/script/error scans. [Source/log receipt](logs/overnight-source.json)
binds the exact command, hashes and raw logs. The earlier preliminary runs are
historical; final receipt hashes match the current files after every visual fix.

Cold-source launch passes actual Main/title 44/0, warm startup and broken-copy
refusal/restoration with 210 stable inputs; see [startup evidence](source-launch-overnight/README.md).
The final capture passes28 actual PNGs and 44 checks with source/PNG rehashes clean;
see [render evidence](screenshots/overnight/README.md). All six district lines,
all ten career goals and both1650-point delivery lanes pass on this same source.

`tools/check.sh` uses fixed 60 Hz test observations for deterministic physical
input replay. No production scheduler or physics rate is altered. Changed legacy
fixtures use real brake/neutral commands to respect rollback, fresh setup cues and
manual gestures; old score expectations are reconstructed from accepted events.
Native contact, exact bank/once-only, route/gap/return and camera assertions remain.

Rendered [evidence](screenshots/overnight/README.md) distinguishes actual chase
frames from authored inspection cameras and declares special/rail fixture setup.
The tool validates source stability, full PNG rows and chunk CRCs before publishing.

## Practical limits

This is original THPS-inspired arcade tuning, not identical franchise code,
scoring or content. Full 90-degree features and directional deck transfers are
implemented; arbitrary bowls/spine structures and skitching remain separate
backlog work. Native Mac packages were not rebuilt in this pass. Linux automated
physics and software-rendered captures do not certify Mac launch, DualSense
feel, Apple Silicon performance, listening or final release art/human acceptance.
