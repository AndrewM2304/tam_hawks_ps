# Playability repair — independent QE

17 October 2026. **Focused repair checks pass 44/0; full acceptance is pending.** The owner's actual Mac play reports an always-missing skater, poor skating response and falls through apparently traversable areas. Earlier guided-route passes and authored screenshots do not close those reports. The previous Exchange 1,155/0 result remains source-bound regression evidence, not normal-play acceptance.

## Reproduced causes before repair

The root agent reproduced the owner's first error chain using Godot 4.6.3 on a source copy without `.godot`: missing `GrindLine` class registration and imported anatomical OBJ resources lead to `Anatomy.new()` failures and later Nil accesses in `skater_visual.animate` and `busker_actor._pose`. Both actors depend on Anatomy before they assign the subsequently missing torso/head. The source launcher did not prepare imports. Root owns the cold-source launcher repair and durable cold-copy regression; this does not establish an actual repaired Mac launch yet.

Independent [before log](logs/playability-before.log) comes from an ignored scene harness launched **without `--script`**, so the production Main actually enters its paused title branch. Persistence is disabled before Main enters the tree. Visible menu controls are activated using input events. The harness never changes the camera transform, calls camera/player update functions manually or assigns movement state after each declared initial fixture.

| Scenario | Actual before result |
|---|---|
| Imported Linux normal title → free skate | Actual torso, head, jacket and Mo head/clothing exist; current chase is 6.47 m from the rider chest and contains both feet and head. This does not reproduce the Mac cold-import failure because this checkout has imported resources. |
| Default spawn, push 120 frames → left 60 → right 120 | Both real steering curves preserve full-body framing, clear chest-to-camera rays and ground support. No per-frame heading assignment. |
| West shop wall, initial board spawn `(-34,1.25,4)`, facing east | Camera contracts to **1.042 m** from the chest and excludes a feet/head endpoint for **45 of 60 samples**. The chest-to-camera ray stays clear: the prior chest-only test missed the severe framing failure. |
| North gallery side closes, X±12 from Z−39 facing north | Push-only motion crosses the open floor edge, falls to **Y−7.96** and bails in each lane. First point below −0.5 m is approximately `(±12,-0.6435,-44.5964)`. |
| South retail closes, X±12 from Z38 facing south | Push-only motion falls to **Y−7.84** and bails in each lane. First point below −0.5 m is approximately `(±12,-0.5297,42.944)`. |

These are separate defects: a cold-import initialization failure can remove the entire visible rider; the tight-wall camera can crop an otherwise built rider; actual missing support causes falls. Fixing one must not be presented as resolving all three.

## New durable regression

`tests/playability_regression_tests.gd` runs ordinary callbacks and mapped input actions. `run(tree,game,check)` integrates into the aggregate. `run_normal_boot(tree,game,check)` additionally requires the actual normal title branch and absence of `--script`. `tests/playability_boot.tscn` supplies the durable wrapper, instantiates the unchanged Main scene with persistence disabled, counts failures, exits nonzero and has a bounded timeout:

```sh
./tools/run.sh --headless --audio-driver Dummy tests/playability_boot.tscn
```

The completed focused invocation adds `--fixed-fps 60`; ordinary and cold-source runs must be recorded separately. The wrapper is declared test scaffolding, not a claim that the user launched a test scene. Actual unmodified-main rendering is a separate required check.

Coverage includes all four imported player anatomical meshes, board/torso/clothing, complete Mo/Rae/Mairi actors before and after normal animation, actual title/free-skate/career control activation, pause/restart, three window sizes, natural spawn curves, shop-wall turning, station low ceiling and gallery columns. Camera checks require the real current camera, finite position, both feet/head endpoints in its frustum, a clear chest ray and at least 2 m chest distance. These are framing checks, not every-pixel occlusion or human comfort certification.

The repaired gallery and quay closes are checked in both directions with push only from one supported initial fixture, then ordinary braking after reaching the target; no subsequent position, velocity, speed or heading assignments. Independent floor rays include the center and ±2 m lateral offsets so the exact centerline cannot hide adjacent holes. Collision support, actual reached endpoint and landing, no bail/fall and full-body chase all matter. Natural input and a declared initial fixture are still scripted evidence, not a claim of human difficulty or enjoyment.

## Final focused result

The normal scene invocation completes **44 passed / 0 failed**, exit 0, with clean engine/script scans. The [focused log](logs/playability-focused.log) SHA-256 is `f71e320b2d5008e90dfa8d9cb76c6e26f621500cc2a5a7c73be503c321552a81`. The frozen module SHA-256 is `09dc160f77704aba05f19250d18d5009ae57b5c4d917953ad0f3ee51f91d6ed0`. One check proves the actual normal title branch; the shared aggregate module contains the other 43 checks. These counts must not be added to the eventual aggregate as separate cases.

| Repaired behavior | Actual focused evidence |
|---|---|
| Full construction and normal flow | Board, torso, clothing and all four anatomical meshes exist and are visible; Mo, Rae and Mairi have complete heads/clothing/hands before and after animation. Actual title activation, free skate, career, pause and restart pass. 1280×800, 1920×1080 and 800×600 retain feet/head framing. |
| Natural spawn steering | 300 ordinary input/physics samples travel 63.87 m with left/right turns produced entirely by input. Zero bails, hidden endpoints, close cameras, ray blockers or nonfinite values. |
| User-visible coasting | Actual pushing reaches 14.9963 m/s. Three seconds after releasing push, speed is 5.9408 m/s; after another 4.5 seconds it is zero. Total travel including the push is 51.47 m. No wall contact or bail causes the slowdown. |
| Tight cameras | Shop wall plus stationary steering: 150 samples, minimum chest distance 6.462 m. Undercroft: 60 samples, minimum 3.519 m. Gallery columns: 60 samples, minimum 6.463 m. All retain feet/head, clear rays and finite current cameras. |
| Former floor holes | All eight forward/reverse close trips reach their endpoint and land under actual braking, with zero falls/bails/camera faults. Center and ±2 m support rays pass. No per-frame heading correction. |
| Off-line boundaries and roofs | Actual push collides with Barras east and station south barriers, then ordinary steering/push returns to supported ground with visible rider and no bail. All four visible market canvas tops and both sloped pavilion faces have matching actual upward support. These two perimeter trips do not certify every boundary. |

The [first development run](logs/playability-arrival-diagnostic.log) had 38 passes and two gallery-arrival failures. All trips had reached safely, but the rider was approximately 0.029 m above the plateau in ordinary crest airtime at the first endpoint sample. The final test retains the floor requirement and observes 40 actual braking frames before asserting the normal landing; it does not remove the support check or modify production to force a pass. This fixture timing correction is distinct from the original multi-metre floor holes.

`drive_natural_spawn(tree,game,observer=Callable())` is reused by the capture runner. Awaited stages `push`, `left`, `right` expose real evidence after 120/60/120 input frames. Rendering observers may pause for readback but cannot assign camera/player transforms or fabricate movement. The separate coast/braking capture must declare its own initial spawn and actual inputs; braking and automatic coast-to-stop are different observations.

## Current status and remaining evidence

Before failures are preserved. The focused checks and cold-source launch regression cover normal-title launch, complete actor construction, camera framing and source imports. The 19-image [playability render set](screenshots/playability-repair/README.md) is the current Compatibility-renderer capture: it is source-stable, starts through normal Main, has zero failures and shows ordinary movement, city/park/water shaders, HUD, routes and existing landmarks. The grass no longer uses the alias-prone fine procedural noise, the Clyde water shader has softer broad waves and highlights, transient feedback uses a compact panel, and UI labels have stronger readable sizing. Its park material still reads as a broad dark green, so this is rendering stability/readability work, not final art acceptance.

Ground travel now applies a bounded tangent gravity component on existing grades and supports signed rollback; exact focused values are in [SKATE-RESPONSE](SKATE-RESPONSE.md) and the full-suite result is in STATUS/QE. The formerly failing reverse Exchange→Barras career combo passed after slope response during the first full run. Human Mac retry, physical-controller comfort, listening, final art/UI review and target-hardware frame times remain open. Linux capture and scripted results do not establish those gates.
