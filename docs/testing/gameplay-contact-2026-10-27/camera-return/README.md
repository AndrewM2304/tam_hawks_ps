# Native ramp camera continuity

The canonical, unchanged `CameraTurnReview.run` passes **57/0**, clean exit0,
8.022s, with674 stable inputs. [The exact receipt](short-rear-full-native/receipt.json)
binds manifest
`72cbfaca2a253274ad8ec1eb340c992e42e64fca0d3ed79377c34f76f21b7ecf`.
This is focused camera verification; root owns the later required full-suite,
rendered evidence, package and push identity.

| Final native metric | Normal motion | Reduced motion | Original gate |
| --- | ---: | ---: | --- |
| Actual departures / returns / complete orbits | 4 / 4 / 4 | 4 / 4 / 4 | At least3 and every return owns one orbit |
| Unsafe displayed-body observations | 0 | 0 | 0 |
| Largest camera update | 0.800002m | 0.800002m | <1m |
| Largest view rotation | 25.744° | 25.744° | <30° |
| Supported side-orbit observations | 0 | 0 | 0 |
| Settled supported rear samples | 140 | 140 | >100 |
| Minimum supported travel/view dot | 0.99999988 | 0.99999988 | >0.80 |
| Minimum displayed rider-axis fraction | 0.07456 | 0.07503 | >0.06 |

## Reproduced causes and repair

The large view steps occurred on **supported ascent**, before departure. As the
native support-up Y component fell from about0.18 to0.12, a lagging rear camera
lost its final clear body sightline and the existing safe-endpoint fallback
moved1.23–1.27m. The repair converges toward the already requested rear position
earlier through that steep approach. Camera sphere sweeps, movement safeguards
and all landmark visibility checks still choose every admitted position.

The remaining four side observations per mode occurred on **supported descent**
near the coping, in two-frame pairs. Longer overhead rear arms worsened the view:
the actual round coping occluded native tyre vertices below its crown. The first
west witness targets board-local `(0.129002,-0.096962,0.282579)`, with a real
coping ray hit and a separate concrete-wall endpoint support. Holding the old
rear camera was also natively invalid, despite rear-plane alignment1.0.

The corrected native grid independently found clear, fully framed zero-angle
rear positions using the existing1.6m minimum ramp arm and higher support-view
heights. The production chooser now tests the existing high rear view, then the
existing short ramp arm at normal/low and high height, before considering a
lateral orbit. `HIGH_HEIGHT=7.2` is the original last-resort height, factored into
one constant; it is not a new clearance, field of view or camera-distance budget.
Every zero-angle selection requires the original native `usable` result.

The change does not alter player/board motion, camera collision radius or mask,
the authenticated4mm endpoint-contact check, FOV, minimum arm, maximum camera
speed or test assertions. The rare failed short-rear branch adds at most four
existing candidate checks. No frame-time or target-Mac performance result is
inferred from that bounded query count.

## Retained rejected epochs and observer corrections

- [Registered original two-return fixtures](registered-native-rejected/receipt.json)
  reproduce12/4 on675 stable inputs. Controls,720-tick loops and assertions are
  copied unchanged; instrumentation only records native camera update state.
- [First full camera repair](crest-full-native/receipt.json) passes55/2 on674
  stable inputs. Earlier ascent convergence fixes both movement gates; the
  remaining two rejected assertions are the side-orbit gates.
- [Corrected native/FOV grid](rear-projection-native/receipt.json) retains the
  original14/2 scoped result on676 stable inputs and proves the valid rear
  alternatives. The actual camera is a successful native/frustum control;
  the previous physical position remains a rejected native control.
- The first private-fixture harness omitted `Setup.register_actions`, which the
  public suite normally supplies. [That setup rejection](first-native-rejected/receipt.json)
  is preserved; it establishes no production regression. The corrected runner
  performs the original registration before either fixture.
- The first preview-camera observer inherited rider interpolation, while the
  real chase camera explicitly disables it. Its all-false preview frustum
  conclusions are withheld. The corrected observer matches interpolation-off,
  top-level camera behavior and the unchanged FOV, records the first outside
  point and checks projection coordinates. It never assigns the actual camera
  or moves the rider.
- [One grid attempt changed source during execution](rear-grid-source-unstable/SOURCE_UNSTABLE.json).
  The normal stable-source archiver correctly refused it. Its unmodified receipt,
  both input maps, console and exact before/after GrindLine bytes are preserved
  separately; only the fresh stable rerun supplies the subsequent grid evidence.

All other receipts, rejected source snapshots and exact ignored observer inputs
remain in their own epoch directories. No static frame, continuous-motion,
Mac/controller or human-feel acceptance is supplied by these headless checks.
