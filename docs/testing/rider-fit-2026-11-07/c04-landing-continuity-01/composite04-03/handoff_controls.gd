extends RefCounted
static func run(game:Node)->Dictionary:
	var r:CharacterBody3D=game.skater
	var feature:Node3D=game.world.get_node("ClydeEastBowl")
	var actor:Transform3D=r.global_transform
	var velocity:Vector3=r.velocity
	var board:Transform3D=r._board_visual.global_transform
	var tick:int=Engine.get_physics_frames()
	var query:=PhysicsRayQueryParameters3D.create(Vector3(-15,3,124.5),Vector3(-15,1,124.5),r.collision_mask,[r.get_rid()])
	var hit:Dictionary=r.get_world_3d().direct_space_state.intersect_ray(query)
	var checks:Dictionary={}
	checks.fresh_external_native_floor_positive=r._ramp_flat_hit_valid(hit,feature,true)
	var bad:Dictionary=hit.duplicate();bad.rid=RID()
	checks.wrong_RID_refused=not r._ramp_flat_hit_valid(bad,feature,true)
	bad=hit.duplicate();bad.shape="0"
	checks.noninteger_shape_refused=not r._ramp_flat_hit_valid(bad,feature,true)
	bad=hit.duplicate();bad.shape=-1
	checks.negative_shape_refused=not r._ramp_flat_hit_valid(bad,feature,true)
	bad=hit.duplicate();bad.shape=PhysicsServer3D.body_get_shape_count(hit.rid)
	checks.out_of_range_shape_refused=not r._ramp_flat_hit_valid(bad,feature,true)
	bad=hit.duplicate();bad.normal=Vector3(NAN,1,0)
	checks.nonfinite_normal_refused=not r._ramp_flat_hit_valid(bad,feature,true)
	bad=hit.duplicate();bad.normal=Vector3.RIGHT
	checks.steep_surface_refused=not r._ramp_flat_hit_valid(bad,feature,true)
	bad=hit.duplicate();bad.normal=Vector3(0,2,0)
	checks.nonunit_normal_refused=not r._ramp_flat_hit_valid(bad,feature,true)
	checks.missing_floor_refused=not r._ramp_flat_hit_valid({},feature,true)
	# Declared identity counterexamples use actual registered native body/shape
	# references; they are not presented as first-hit ordinary ray witnesses.
	var deck:CollisionObject3D=feature.get("_native_annular_deck")
	var owned:Dictionary={"collider":deck,"rid":deck.get_rid(),"shape":0,"normal":Vector3.UP,"position":Vector3(0,2,0)}
	checks.associated_annular_is_not_an_external_floor=not r._ramp_flat_hit_valid(owned,feature,true)
	checks.actual_coplanar_annular_can_supply_footprint=r._ramp_flat_hit_valid(owned,feature,false)
	var steel:CollisionObject3D=feature.get("_native_steel_coping")
	owned={"collider":steel,"rid":steel.get_rid(),"shape":0,"normal":Vector3.UP,"position":Vector3(0,2,0)}
	checks.actual_coping_cannot_supply_even_claimed_flat_footprint=not r._ramp_flat_hit_valid(owned,feature,false)
	var head:Node3D=r._visual_rig._head
	var bounds:AABB=r._ramp_flat_head_bounds
	var outside:=0;var corners:=0
	for mesh:MeshInstance3D in head.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh==null or not mesh.visible:continue
		var transform:Transform3D=mesh.transform
		var node:Node=mesh.get_parent()
		while node!=head:
			transform=(node as Node3D).transform*transform;node=node.get_parent()
		for surface:int in mesh.mesh.get_surface_count():
			var a:Array=mesh.mesh.surface_get_arrays(surface)
			var vertices:PackedVector3Array=a[Mesh.ARRAY_VERTEX]
			var ids:PackedInt32Array=a[Mesh.ARRAY_INDEX]
			if ids.is_empty():
				for vertex:Vector3 in vertices:
					var p:Vector3=transform*vertex;corners+=1
					if p.x<bounds.position.x-.000001 or p.y<bounds.position.y-.000001 or p.z<bounds.position.z-.000001 or p.x>bounds.end.x+.000001 or p.y>bounds.end.y+.000001 or p.z>bounds.end.z+.000001:outside+=1
			else:
				for index:int in ids:
					var p:Vector3=transform*vertices[index];corners+=1
					if p.x<bounds.position.x-.000001 or p.y<bounds.position.y-.000001 or p.z<bounds.position.z-.000001 or p.x>bounds.end.x+.000001 or p.y>bounds.end.y+.000001 or p.z>bounds.end.z+.000001:outside+=1
	checks.native_indexed_head_hair_eye_constructor_bound=r._ramp_flat_head_valid and corners>0 and outside==0
	checks.controls_do_not_mutate_actor_velocity_board_or_physics_tick=r.global_transform==actor and r.velocity==velocity and r._board_visual.global_transform==board and Engine.get_physics_frames()==tick
	var passed:=true
	for name:String in checks:passed=passed and bool(checks[name])
	return {"passed":passed,"checks":checks,"native_head_indexed_corners":corners,"head_vertices_outside_constructor_bound":outside,"scope":"Read-only direct freshfloor/nativeidentity/malformedcounterexamples and actualindexedHeadcache enclosure afteroriginalcombinedprefix. Ownedobjects are declared real-native-identity counterexamples, not fabricated first-hit-ray claims. No actor pose/input mutation;1um enclosure arithmetic allowance is not a contact tolerance."}
