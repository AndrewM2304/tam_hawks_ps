# Supporting actor and route-map review

These four PNGs verify the new activity actors and route availability drawing.
They are supporting inspection/UI fixtures, separate from the complete Main
motion capture in the parent directory. They make no global current-source,
Mac/controller, performance or final-art acceptance claim.

| Frame | Resolution | Evidence |
|---|---|---|
| [Festival steward](festival-steward-inspection.png) | 1280×960 | Adult actor at its actual Main quay site, authored inspection camera |
| [Park regular](park-regular-inspection.png) | 1280×960 | Adult actor at its actual Main park site, authored inspection camera |
| [Closed shortcut](service-shortcut-closed.png) | 960×600 | HUD fixture: dim dashed path, CLOSED marker/status |
| [Open shortcut](service-shortcut-open.png) | 960×600 | Same HUD fixture: bright solid accessible path, OPEN status |

The actors reuse the existing cleared anatomy, skinned clothing and footwear.
No instrument, voice, new third-party asset or collision body was added. Their
factory root identities/positions remain unchanged. Separate native foot rays
place the visible soles on ground: the actual park root is Y5.7337 and the visual
body is grounded on Y6; the quay root/body is Y2. Offer and success pose checks
use explicit parent-state fixtures; the idle inspection PNGs do not claim an
earned challenge completion.

`ActivityActorTests.run` plus `run_world` pass **62/0**, covering actual meshes,
flat/sloped sole planes, bounded articulated gestures, finite limb reach,
reduced-motion/pause, passing-character rejection and both Main placements.
The map checks pass **12/0**: nine layout/live-update checks at three sizes plus
three rendered checks. The sampled closed path has **0 bright / 31 dim pixels**;
the identical opened path has **177 bright pixels**. Map points and availability
are explicit UI data fixtures; native gate opening/traversal belongs to the
separate integration evidence.

[supporting-source.json](supporting-source.json) records SHA-256 for all four
images, complete PNG CRC/row validation, capture recipes/logs, and identical
before/after hashes for **23 scoped actor/HUD/input/asset sources**. This receipt
certifies those inputs only; it does not fingerprint the surrounding Main/world
implementation. The captures use Godot4.6.3 Compatibility and Mesa llvmpipe.

- [Actor native checks](actor-native-tests.log)
- [Actor capture log](activity-actor-render.log) and [inspection recipe](actor-inspection-recipe.gd.txt)
- [Map rendering checks](route-availability-render.log) and [fixture recipe](map-fixture-recipe.gd.txt)

Both adult profiles and both map states were visually reviewed. The reviewed
actor revision fixes vest/coat interpenetration, follows the coat profile for
seams and pockets, and uses relaxed articulated arms with native sole contact.
