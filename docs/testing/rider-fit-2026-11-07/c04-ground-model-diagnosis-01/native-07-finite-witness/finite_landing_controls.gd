extends RefCounted
const Setup=preload("res://game/core/input_setup.gd")
const Skater=preload("res://game/player/skater.gd")
static func points(center:Vector3)->PackedVector3Array:
	var mesh:=BoxMesh.new();mesh.size=Vector3(.1,.1,.1)
	var faces:PackedVector3Array=mesh.get_faces()
	for i:int in faces.size():faces[i]+=center
	return faces
static func shape(vertices:PackedVector3Array)->ConvexPolygonShape3D:
	var value:=ConvexPolygonShape3D.new();value.margin=0;value.points=vertices
	return value
static func run(tree:SceneTree)->Dictionary:
	Setup.register_actions()
	for action:String in InputMap.get_actions():Input.action_release(action)
	var viewport:=SubViewport.new();viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED;tree.root.add_child(viewport)
	var root:=Node3D.new();viewport.add_child(root)
	var floor:=StaticBody3D.new();root.add_child(floor)
	var box:=BoxShape3D.new();box.size=Vector3(2,.1,2)
	var collision:=CollisionShape3D.new();collision.shape=box;collision.position.y=-.05;floor.add_child(collision)
	var rider:=Skater.new();rider.spawn_position=Vector3(0,.08,0);root.add_child(rider)
	for tick:int in 30:await tree.physics_frame;await tree.process_frame
	rider.set_physics_process(false);rider.set_process(false)
	var actor:Transform3D=rider.global_transform
	var velocity:Vector3=rider.velocity
	var capsule:Transform3D=rider._body_collision.transform
	var board:Transform3D=rider._board_visual.global_transform
	var physics_tick:int=Engine.get_physics_frames()
	var saved:Array[Dictionary]=rider._grind_clearance._parts
	var a:PackedVector3Array=points(Vector3(-1.5,-.25,0))
	var b:PackedVector3Array=points(Vector3(1.5,-.15,0))
	var combined:PackedVector3Array=a.duplicate();combined.append_array(b)
	var parts:Array[Dictionary]=[{"points":a,"shape":shape(a)},{"points":b,"shape":shape(b)}]
	rider._grind_clearance._parts=parts
	var pose:=Transform3D(Basis.IDENTITY,Vector3(0,.2,0))
	var support:Dictionary={"rid":floor.get_rid(),"shape":0,"normal":Vector3.UP,"position":Vector3.ZERO}
	var ray:=PhysicsRayQueryParameters3D.new();ray.collision_mask=1;ray.exclude=[rider.get_rid()]
	var query:=PhysicsShapeQueryParameters3D.new();query.collision_mask=1;query.exclude=[rider.get_rid()];query.margin=0;query.transform=pose;query.shape=shape(combined)
	var space:=rider.get_world_3d().direct_space_state
	var broad_hit:=false
	for hit:Dictionary in space.intersect_shape(query,16):broad_hit=broad_hit or (hit.rid==support.rid and hit.shape==0)
	var actual_components_clear:=true
	for part:Dictionary in parts:
		query.shape=part.shape
		actual_components_clear=actual_components_clear and space.intersect_shape(query,1).is_empty()
	var bearing_proofs:=0
	for wheel:Dictionary in rider._visual_rig.board_contact_geometry().wheels:
		var at:Vector3=pose*Vector3(wheel.center);at.y=0
		ray.from=at+Vector3.UP*.35;ray.to=at-Vector3.UP*.50
		var hit:Dictionary=space.intersect_ray(ray)
		if not hit.is_empty() and hit.rid==floor.get_rid() and hit.shape==0 and Vector3(hit.normal).y>.999 and absf(Vector3(hit.position).y)<.001:bearing_proofs+=1
	var false_gap:float=rider._air_landing_model_gap(pose,rider._visual_rig.board_contact_geometry().wheels,Vector3.ZERO,Vector3.UP)
	var outside_refused:bool=not rider._air_landing_finite_model_overlap(pose,support,ray)
	# Bring only the declared native negative source component over the finite
	# floor. The actor, its actual visible board and every marker stay untouched.
	a=points(Vector3(-.3,-.25,0));parts[0]={"points":a,"shape":shape(a)}
	rider._grind_clearance._parts=parts
	var genuine_positive:bool=rider._air_landing_finite_model_overlap(pose,support,ray)
	var wrong:Dictionary=support.duplicate();wrong.rid=RID()
	var foreign_refused:bool=not rider._air_landing_finite_model_overlap(pose,wrong,ray)
	wrong=support.duplicate();wrong.shape=1
	var shape_refused:bool=not rider._air_landing_finite_model_overlap(pose,wrong,ray)
	wrong=support.duplicate();wrong.shape="0"
	var shape_type_refused:bool=not rider._air_landing_finite_model_overlap(pose,wrong,ray)
	wrong=support.duplicate();wrong.position=Vector3(0,.01,0)
	var plane_refused:bool=not rider._air_landing_finite_model_overlap(pose,wrong,ray)
	wrong=support.duplicate();wrong.normal=Vector3.RIGHT
	var normal_refused:bool=not rider._air_landing_finite_model_overlap(pose,wrong,ray)
	rider._grind_clearance._parts=saved
	var unchanged:bool=rider.global_transform==actor and rider.velocity==velocity and rider._body_collision.transform==capsule and rider._board_visual.global_transform==board and Engine.get_physics_frames()==physics_tick
	var checks:Dictionary={"actual_native_BoxMesh_components":a.size()==36 and b.size()==36,"broad_hull_hits_same_finite_owner":broad_hit,"actual_components_do_not_hit_owner_in_false_case":actual_components_clear,"all_four_finite_bearings_proven":bearing_proofs==4,"infinite_plane_gap_is_negative":false_gap<0,"actual_negative_vertex_outside_finite_owner_refused":outside_refused,"genuine_inside_finite_owner_positive":genuine_positive,"foreign_RID_refused":foreign_refused,"same_RID_different_integer_shape_refused":shape_refused,"noninteger_shape_refused":shape_type_refused,"different_plane_refused":plane_refused,"different_normal_refused":normal_refused,"actor_capsule_velocity_board_physics_tick_unchanged":unchanged,"original_cached_parts_restored":rider._grind_clearance._parts==saved}
	var passed:=true
	for key:String in checks:passed=passed and bool(checks[key])
	var out:Dictionary={"passed":passed,"checks":checks,"false_broad_gap_m":false_gap,"scope":"Declared synthetic native indexed BoxMesh finite-floor counterexample; actual Skater helper and exact native queries. Cache temporarily substituted/restored, no actor/visible geometry/physics-tick mutation. Not ordinary trajectory or visual quality proof."}
	viewport.queue_free();await tree.process_frame;await tree.physics_frame
	return out
