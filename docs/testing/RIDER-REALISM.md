# Anatomical rider revision — 17 October 2026

**Checkpoint note:** The retained rider video below predates the bin-drum/dancing-cat correction. Its source-bound rider evidence remains historical for the complete game. The current corrected act has a separate silent preview and source manifest in screenshots/bin-cats; STATUS records the latest packages.

The owner rejected the previous cartoon rider. This revision replaces its invented loft face and mitten hands with anatomical geometry derived from the verified CC0 MakeHuman `hm08` base, while retaining the game's native skating rig and movement contracts. Source permission, exact revision and extraction details belong in [the human reuse record](../research/HUMAN_MODEL_REUSE.md) and [the asset manifest](../../game/art/assets/makehuman_hm08/manifest.json).

The visual target is an adult of roughly 1.75 m with a normally sized head, visible nose/lips/ears and five-finger hands, restrained skate clothing and shaped cupsole shoes. It is a substantial model correction; automated checks alone cannot approve realism, animation quality or final character art.

## Protected contracts

Only the visual helpers and character assets change in this pass. The player collision capsule, velocity, takeoff, trick eligibility, scoring, camera and input contracts remain owned by `skater.gd`. `build(board,rider,shirt)`, `animate(delta,state)` and `reset()` remain intact, including earned shirt colours. Clothing uses the existing ten-bone `Skeleton3D`/`Skin` and analytic contact targets. The board geometry, wheel radius, flat-ground origin and manual wheel-contact compensation are retained.

Original continuous jacket/trousers now have narrower sleeves, less inflated thighs/calves and restrained folds. Original shoes use a shaped upper and flat cupsole; the sole bottom remains 0.0605 m below the existing foot target. Head and hands use cropped, licensed geometry rather than a complete imported controller or animation system. Skin/lip/eyebrow pigmentation, eye materials and the slate/charcoal outfit are original material work. No paid tool, service or asset is used.

The short hair shell follows the actual scalp. Automatic scalp LOD is disabled: independently simplifying that thin surface caused skin to poke through the full-resolution pigmented head at chase distance. The 748-triangle scalp is inexpensive enough to retain intact. The neck crop is fitted into the collar and head rotation pivots around its base. The hands are assigned to the correct anatomical sides, turn their palms inward at rest and use an original `GripCurl` blend shape during the grab. A palm-offset solve replaces the old wrist-at-board shortcut.

Inspection also exposed an older clothing defect: shortest-arc rotations from `UP` became ambiguous near `DOWN`, twisting adjacent elbow/knee rings. A shared back-facing pole now stabilizes those bone frames. This affects only garment deformation; it does not alter limb target positions, collision or movement.

## Reproduction and evidence

`./tools/rider_capture.sh` drives actual input and physics at 60 Hz, then freezes each action only for screenshots. It captures normal chase views and authored close views. Idle additionally has a true torso-front view, torso-side view, head-front and head-profile view derived from the corresponding transforms. Special poses use an explicit full-meter fixture; the action itself still passes through runtime input/gating.

`./tools/rider_motion.sh` records the documented fixed-timestep input sequence as a silent 30 fps clip with labelled reset cuts. Its encoded duration reflects simulation time, not software-rendering wall time. The clip is inspection evidence, not a performance result or human playtest.

Both runners reject a partially initialized game scene. The motion shell runner removes previous count/sequence metadata before capture, requires a new positive frame count and checks the encoded frame count and full video decode before reporting success. This prevents an interrupted or failed future run from relabelling earlier frames as fresh evidence.

Selected actual-game frames are retained in [screenshots/rider-realism](screenshots/rider-realism/README.md), including normal chase, front/profile anatomy, feet, grab contact and action poses. The runner starts at the world's current clear spawn; it does not move the rider to the old fountain coordinates. The standalone grey-stage images used during fitting remain ignored working evidence, separate from these game captures.

## Recorded checks

| Check | Observed result |
| --- | --- |
| Godot 4.6.3 Compatibility import | Clean; no parse/script errors in the final import log |
| Actual-input action capture | `RIG ACTION CAPTURE errors=0`, all 11 requested states reached |
| Refreshed motion preview | 222 frames, 7.4 seconds, silent H.264 at 1280×800 / 30 fps; all frames decode cleanly and the input runner reports zero errors |
| Focused manual/revert/special checks | 39 passed, 0 failed |
| Independent takeoff regression cases | 21 passed, 0 failed |
| Rider/board geometry | 62 `MeshInstance3D` nodes, 37,304 triangles across instances, ten clothing bones |
| Clothing skin data | 2,398 vertices; no non-finite vertices or invalid weights; maximum packed weight sum error 0.00001529 |
| Actual grab frame | Distal-palm reference is 0.01112 m from the authored deck edge after 11 input frames; the animation is still blending |
| Settled manual on a flat physics fixture | Lowest wheel vertex Y=0.000252 m; reset restores board-local Y=0.12 m |

Front/profile and full-body review checked head size, nose/jaw/ear silhouette, neck/collar attachment, inward resting palms and continuous knees/elbows. Action review checked planted shoes, foot-drag braking, separated flip/special board motion, compressed landing, manual wheel clearance, palm/deck alignment and the deep tumble pose. Reversed new shoe side/end faces found in the first close inspection were corrected before the retained evidence. Final aggregate verification belongs to the orchestrator's STATUS/QE record.

Independent QE inspected the final idle close/face/profile, grab-hand, manual and tumble screenshots. It found no concrete blocking regression in those six frames: visible limbs stayed connected, the palm reached the board edge and the captured foot/tumble contact remained coherent. This is a still-image review, not approval of motion or human realism.

The final refreshed video has replaced the older artifact at `/workspace/TamHawks-motion-preview.mp4`. It was refreshed after the final two-court/mechanical-cat source freeze at 16:32 UTC on 17 October 2026, using the unchanged anatomical rider and action recipe. All **103 pinned game/resource/capture/wrapper files** remained byte-identical throughout recording. Its frame count, encoding data, exact checksum and explicit reset/special-meter cuts are retained with the screenshot evidence in `motion-source.json`, `motion-artifact.txt` and `motion-sequence.json`. The full decoded-frame-count check and video decode passed; the 222-frame clip lasts 7.4 seconds. The promoted file is 6,651,674 bytes, SHA-256 `f09b5ca42e6754f1ff7a3c7c30e546b25803caeff67980f7751284f2e957ae20`. Unmodified grab/tumble frames 80 and 205 were inspected from this recording; no rider production edit was needed. This brief core-area rider sequence is not a tour or acceptance test of every level route or encounter.

## Remaining quality boundary

This is a recognisably adult anatomical model with better proportions, not a declaration that the final realistic-art gate has passed. Skin and hair still have simple materials; the clothing and shoes remain authored procedural geometry. The ten-bone pose system has no recorded motion capture, cloth simulation, independent finger joints, facial animation or hand/cloth collision solver. The grip curl and palm target approximate the grasp; every fingertip does not physically constrain the deck. A person should judge motion, personality and visual quality in the refreshed clip and on the target Mac. Final owner visual acceptance, real Mac launch, hardware performance and physical controller feel remain open.
