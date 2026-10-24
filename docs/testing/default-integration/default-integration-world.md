# Combined default World integration

Branch integration is based on latest default d28c8f4 (index2), with the feature
work b001fd3 (index3). All five conflicted level files have been resolved in the
working tree; no index staging, commit, global restore or push performed here.

Preserved from default:

- Compact `clyde_layout.gd`: north quay[-85,85] Z55..78, south quay[-39,76]
  Z116..130, yard[-39,76] Z130..143, safe crossingX-25/transferX20. The removed
  broad quay/south lawn have not returned. Original Clyde routes, gap/recovery
  IDs, exact visible strip clipping and real supported yard remain.
- All three dictionary TransitionPark quarters/halfpipe, transforms, coping and
  contact metadata. `get_transition_features()` remains unchanged. Node3D feature
  transitions are separate, as agreed with the controller/helper owners.
- Native enclosed connector ground, water shader/recovery, opaque boundaries,
  four-surface horizon, exact support_vertices/strip_height ownership, existing
  facade/render-quality, visibility, RenderBudget and StaticBatches integration.
- Semantic SkateEdges families and existing slat-accurate StreetBench collision;
  the audit reuses existing matching edge IDs. Only regraded, explicitly tagged
  three-row roll-over shoulders are excluded from the old paired-curb parser.
- Default Outdoor beam guide/contact datum: visible/native shapes stay centred on
  existing paths, with verified normal offset+radius. The stale work's downward
  geometry offset was not applied again. Core lowered cylinders retain default
  contact(-radius,+radius) with exactly matching new native steel.

Integrated feature work:

- Northwest sunken park: exact40x30m cut atRect2(-227.5,-202.5,40,30), rim14.5,
  real original-grid excavation, native support-height forwarding, supported east
  summit connection/sign/map route, vegetation filtering, bowls/street/hip and
  finite coping/ledge/rail geometry. No blanket support plane across pits.
- Connected skating infill in all six existing districts, native rail-only factory
  cylinders/Outdoor beams and finite broken-bridge bars; real Court cap compound
  shapes and the documented GallerySteps9.4->9.1 clearance repair; pavilion rear
  posts moved only50cm. New physical bins preserve original visible dimensions.
  Barras bench relocated off the bank; original bench slat collision retained.
- Terrain-conforming shoulders/actual bank-cut support and exact-triangle visual
  skins retained; no extra stale eight-metre scenic skirt was added over default
  horizon foundations. Original procedural foliage and adult bystanders auto-merge.
- Compact Clyde adaptations affect only new work: removed unsupported duplicate
  practice clusterX-124/-139 (default quarter/halfpipe already exist). New bowl
  `ClydeEastBowl` at(-7,2,134.5), yaw90, outerR7.7, roll-in start(8.7,2,134.5).
  New bank at(-27.5,2,128), full actual lineX[-38,-17], depth3/rise.48. Curved
  relay seatX[2.5,24.5], Z137.5->136 and flatbarX[28,36]/Z136 preserve original
 3.5m seat/pop/bar gap. Optional return seatX[-22,-15]/Z140. Through lane isZ124,
  avoiding safe bridge handrails. Redundant second south bank omitted. Removed
  only duplicated paving display below the bowl's real flat bottom; native ground
  and every default yard route unchanged.

Explicit bounded integration amendment: new park grading adds four real contour
segments/eight horizon triangles. Ceiling838->846, same four surfaces, original
simplification and actual native-footing fit. No timing threshold relaxed; Root
approved this exact delta. ADR-017 and map-flow contract record it.

APIs added/retained: get_surface_audit(), get_skate_feature_definitions(),
get_level_density_audit(), get_park_skatepark_definition() with World-relative
node_path, bounds/access/entry; bounded get_support_height() forwards actual
facility support. Existing route/checkpoint/grind/dictionary-transition APIs stay.

Evidence:

- World check-only parse clean via tools/run.sh.
- `/tmp/combined-world-probe-final.log`: unchanged WorldRoutes and structural
  assertions241/0, clean construction after exact horizon allowance. This verifies
  support/capsule navigation, not natural player motion by itself.
- Native inventory558 static bodies,224 grind tracks,30 feature definitions,
 56 routes,3 default dictionary transitions;10 separate Node3D transition children.
  Horizon828 footing triangles+18water=846, four surfaces.
- Compact actual Main fixture adapters read authored route/seat data, use supported
  declared manual approach, preserve original durations/capture/camera/once-score
  checks and restore default Court semantic cap-edge coverage. Original AABB camera
  corners were replaced with actual native convex mesh vertices, as used by QE's
  existing authentic camera helper; frustum/ray/sphere thresholds stay unchanged.
- Initial actual compact motion: manual38ticks/100once/0bails; EW72.857m supported,
 0score/0bails/clear camera; relay18held/750once/0bails/clear camera. Initial bank
  camera refusal was an invented curved-GLB AABB corner below the native quay;
  exact-hull rerun is recorded separately.

Full combined aggregate, target hardware/rendering and any export belong to Root
and independent QE. Old branch counts/screenshots certify their own source only.

Final receipts after the seat relocation and exact camera-hull adapter:

- `/tmp/combined-clyde-player-final.log`:5/0, clean native actual Main input.
  Bank38manualticks/100once; EW72.857383m, floor throughout and0score;
  relay18held/750once; all0bails and clear actual hull/feet camera/rays/sphere.
- `/tmp/combined-world-probe-final.log`:241/0 on final World source, clean log;
  exact inventory/846triangles/four surfaces as above. No task-owned Godot remains.

World production and delegated Density test adapter are now frozen for Root/QE.

## Final support-metadata integration addendum

Root reopened only four feature modules for truthful named-grind support metadata:
`transition_feature.gd`, `bowl_feature.gd`, `sunken_bowl_feature.gd`, and
`kelvingrove_skatepark.gd`. Geometry, line IDs/points/kinds, native collision,
ordinary routes, default contact datums and inventory counts are unchanged.

- Ten Node3D coping tracks use their already exact native crown with offsets0,0.
- FiveStepHandrail guide(-207.4,15.32,-184.7)->(-207.4,13.82,-180.5)
  retains the actual axis drop. Offsets(-0.0423783826,+0.045) describe its native
  projected-up cylinder crown; the unchanged guide is not itself the exact crown
  at the sameXZ on this grade. Three native rays agree within0.01573mm.
- Hubba/top-ledges retain their ordinary20mm capsule-admission skin; actual named
  board contact uses vertical offset-0.02. Hubba native ray error<=0.00382mm.
- Four exact-boundary guides (upper two stair noses and two arrival edges) remain
  generic/unverified because the zero-width native edge rays are uncertain.
  No blanket tag, arbitrary offset, geometry movement or fake all-track claim.
- Unit-yaw frame guards reject scaled/tilted/reflected declarations.

`.local/default-new-contact-proof/` holds the actual native ray sites and final
23/0 declaration check:19 supported tracks/57ray sites plus four conservative
unverified refusals. Support metadata is not universal style/approach certification.
QE owns the genuine grade/pivot ride regression and combined test adaptation.

Read-only existing Surface suite22/4 then aborted on a stale default-bench metadata
schema assumption; exact log `/tmp/combined-surface-readonly.log` was sent to QE.
It also exposed17 retained default semantic candidate admission refusals (bench
backrests/frames, stocked counters, stair-cheek ends and one halfpipe wall end).
They were not removed, blindly certified or bypassed by these feature changes.
