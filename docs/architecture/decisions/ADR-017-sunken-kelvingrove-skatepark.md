# ADR-017: A sunken northwest Kelvingrove skatepark

Accepted for implementation24October2026 after the owner supplied two reference
photographs and explicitly requested a sunken, multi-level skatepark at the park's
top-left. This extends the ongoing full-fidelity request; the earlier2,874/0 core
checkpoint does not certify this facility. No additional area, career/save IDs,
paid dependency or bundled reference photograph is introduced.

## Site and connected terrain

The facility footprint is`Rect2(-227.5,-202.5,40,30)`, with origin
`(-207.5,14.5,-187.5)` and upper rimY14.5. The east entry is six metres wide at
`(-187.5,14.5,-182.5)`, linked to the existing higher summit terrace. World owns
the actual hill-mesh/collision cut and support-query integration, perimeter collar,
connected access, existing path/fence adjustments and route registration. Original
hill triangles or broad support planes must not remain across the excavated pits.

The geometry owner builds`game/levels/kelvingrove_skatepark.gd`: a deep northeast
bowl near`(-197,11,-194)` with3.5m transition radius and3.2m floor radius; a shallow
northwest bowl near`(-219,13,-195)` with1.5m transition radius and3m floor radius;
a lower street basinY13 toward the south; a long foreground transition/hip; five
0.3m steps with hubba/handrail; finite low ledges/flatbar; and a gentle ten-metre
east bank descending from14.5 to13. Exact final native geometry and route evidence
remain authoritative. Open ports connect the bowls and street section. No external
eight-metre access ramps from the standalone bowl are included in this class.

## Geometry and support interface

The facility exposes`get_surface_height(world_point:Vector3,max_step_up:float=INF)`:
return the actual supported surface height no higher than`world_point.y+max_step_up`,
or`NAN` for an unsupported/outside point. Never return a blanket rim plane over a
bowl. It also supplies`get_grind_lines()`,`get_feature_definitions()` and
`get_safety_routes()` for actual finite geometry, map/discoverability and tests.
World publishes exact facility/access regions for permitted lap-attempt bounds.
Membership uses the union of those regions and the previous attempt area, rather
than granting unrelated corners of an enlarged bounding rectangle. Existing lap
points/order/radius/75s/pop/landing/finish/scoring are preserved.

Native mesh and visible mesh share the sampled vertices. Every inviting coping,
ledge or rail needs corresponding finite grind coverage and native approach
clearance. Closed retaining scenery must be explicit in the affordance audit.
Godot's visible front faces are clockwise: an upward physical/rendered face has
negative mathematical`(b-a).cross(c-a).y`. Test generated normals and independent
native rays, including primitive top versus underside; backface-enabled collision
alone can hide an invisible or incorrectly indexed floor. Steel bearing paths use
the coping crown rather than its cylinder/torus centre axis.

## Open transition ports

`TransitionRide` may call optional`contact_is_valid(theta,x)` on a feature after
computing its next contact and before existing width/toe/lip branches. This method
describes absent port faces only; it must not replace the ordinary bounds. When a
step would enter an opening, launch from the current verified native sample with
`sample.tangent*_speed+sample.lateral*_lateral_speed`. Do not add impulse, correct
position into missing collision or treat an open port as a collision bail. Features
without the predicate retain their existing behavior. Acquisition still requires
in-bounds finite samples and the actual native collision ray.

The new bowl uses128 angular segments and90 quarter-arc samples. Its south opening
is centred at local anglePI. Deep-bowl half-angle is`9*TAU/128`, open only above
`40*PI/180`; shallow-bowl half-angle is`10*TAU/128`, open above zero. The same cuts
govern collision, visible faces, sample bounds and finite coping. Tests must prove
actual port departure momentum and preserve native closed-feature cases.

## Acceptance and evidence

Preserve both existing park laps, all career/save identities and actual collision,
camera and once-only score checks. Verify native hill excavation and seams; ordinary
mapped-input uphill approach, entry/circulation/exit; both bowls and lower street
section; actual carve/air/lip/grind/transfer; safe restart and camera coverage.
Inspect ground, close and wide frames plus complete source-bound motion. Refresh
the aggregate, cold-source launch, local performance diagnostic and current-source
Linux/Mac packages after final edits. Scoped images and old package results do
not substitute for those checks. Human Mac/controller/feel/final-art acceptance
remains open and does not halt available independent work.

## Integration with the newer default world

The default's compact Clyde, native dictionary-based TransitionPark, enclosed
connector ground, static horizon and rendering/batching remain authoritative.
Node3D transitions use a separate feature transition helper. The actual northwest
park grade adds four contour segments to the exact existing horizon footings:
eight triangles, explicitly raising the combined ceiling from838 to846 while
retaining four shared surfaces, original simplification and native boundary fit.
This geometry allowance does not waive rendering timing gates.
