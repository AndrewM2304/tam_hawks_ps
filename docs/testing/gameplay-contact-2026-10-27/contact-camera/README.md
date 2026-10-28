# Actual Recording Court contact and camera diagnosis

The reproduced PT24-20 failure is a real presentation intersection with the
newly solid steel bearing. It is not repaired by a camera exclusion, wider
visibility tolerance, delayed route observation or removal of a test marker.

Both runs execute the original `PT24Connected.run_player` controls, phase timing,
score and strict visibility assertion. Its ignored source adapter changes only
the Density preload. That wrapper calls the original visibility check, observes
its first failure and returns the original result. Personal persistence is
disabled before Main enters the tree; ordinary trial content remains enabled.

## Exact native evidence

| Record | Scope and result | Stable inputs | Manifest SHA-256 |
| --- | --- | ---: | --- |
| [First actual route](first-actual-route/receipt.json) | 9.878s; original assertion **0/1**, preserved rejection | 677 | `7caf1918b6548d4a73e373e87e7f4ce2aea7aa88f03a16dcf50e4eb8863f15b1` |
| [Follow-up parser](followup-parser-rejected/receipt.json) | 2.658s; rejected four test-local type inference errors | 677 | `2bb38160f09d35e87cc02b1069588a73bb7c13bb605f357754853e2b79c8f7b6` |
| [Follow-up actual route](followup-actual-route/receipt.json) | 9.877s; original assertion **0/1**, native containment and component witness | 677 | `2bb38160f09d35e87cc02b1069588a73bb7c13bb605f357754853e2b79c8f7b6` |

The routes each earn one Manual, ten Manual observations, twenty-four held grind
ticks, one Recording Court capture, one bank worth1,275 and zero bails. Their
remaining failed aggregate condition is visibility. These are diagnostic
rejections, not admitted route passes or final-source verification.

## What actually intersects

At physics frame144, the body is at `(113,2.245556,-26.95076)`. The strict
Density marker that fails first is exactly the **Board node origin**
`(113,2.228,-26.95076)`, not a wheel or truck vertex. Its visual parent is atY2.108.
The native `RecordingAlcoveBack` Box has centre `(113,2.17,-32.875)` and
half-extents `(0.07,0.07,8.875)`, giving the actual topY2.24.

Transforming that marker into the actual CollisionShape yields local
`(-0.000031,0.058,5.924238)`: its minimum interior depth is **12.000389mm**.
A reverse ray with `hit_from_inside=true` independently starts inside that same
native RID. All exterior material-mesh hull vertex rays happen to be clear;
those rays alone do not establish that the intervening faces avoid the bearing.

Native overlap queries, using the existing startup-welded **connected actual GLB
components**, find **eleven** pieces overlapping the same bearing RID, including
the1,302-vertex deck and both truck/hanger assemblies. No single convex material
hull is substituted across the empty space between separate wheels. The exact
component bounds, native rest contacts, transforms and RID are in the follow-up
console log.

The follow-up also samples after the normal Node `_process` callbacks using a
zero-second SceneTreeTimer. Physics frame144 and process frame143 remain the
same, while the camera's recorded process frame advances142→143. The marker
remains12.000389mm inside and the same eleven components still overlap. This
rules out a stale camera view as the explanation for this reproduced failure.
The first run's earlier `call_deferred` sample occurred before camera processing
and is retained with that narrower scope.

## Source finding and next repair

The lower four-wheel floor fit can select the adjacentY2.10 masonry even while
the capsule is supported by the narrowY2.24 bearing between the wheels. Wheel
centres and tyre clearance therefore cannot certify clearance of the complete
rigid deck and trucks. A rejected lower candidate should retain or recover the
actual native support presentation through the existing bounded checks. Merely
raising the already invalid pose is insufficient within the existing10cm bound:
its hanger underside is about115mm below the bearing crown.

Root owns the subsequent Skater repair and its new receipts. No ChaseCamera
production source, collision mask, visibility threshold or original route
assertion was changed by this diagnostic work. No motion-quality, rendering-time,
Mac or controller acceptance follows from these headless observations.
