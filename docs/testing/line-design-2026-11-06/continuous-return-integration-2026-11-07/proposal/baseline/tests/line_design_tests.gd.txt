extends RefCounted
## November geometry admission: fixed native witnesses, directed bank input,
## ordinary seating captures and an unbroken two-bearing/manual relay.
const Routes=preload("res://tests/world_routes_tests.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const BoundaryFaces=preload("res://tests/pt24_boundary_tests.gd")
const EdgeTrial=preload("res://tests/edge_grind_integration_tests.gd")
const AirController=preload("res://game/player/skater.gd")
const FIRST="Grind_Edge_Bench_x800y244z5900_0_0"
const SECOND="Grind_Edge_Bench_x7000y244z5900_0_0"


class ExitModelWitness extends Node:
	# Run after the real skater physics callback. A render observer may advance
	# several physical steps; every step still authenticates the actual GLB.
	var rider: Node
	var clear:=true
	var samples: Array[Dictionary]=[]
	var completed: Array[String]=[]
	var phase:=""
	var air_frames:=0
	var age:=0
	var armed:=false
	var loaded_frame:=Transform3D.IDENTITY
	var loaded_origin:=Vector3.ZERO
	var loaded_capsule:=Transform3D.IDENTITY
	var loaded_visual:=Transform3D.IDENTITY
	var loaded_rider:=Transform3D.IDENTITY
	var loaded_certified:=false

	func arm(id: String,native_supported: bool) -> void:
		loaded_frame=rider._board_visual.global_transform
		loaded_origin=rider.global_position
		loaded_capsule=rider.get_node("BodyCollision").global_transform
		loaded_visual=rider._visual.global_transform
		loaded_rider=rider._rider_visual.global_transform
		loaded_certified=native_supported and rider.grinding
		phase=id
		air_frames=0
		age=0
		armed=true
		_sample("release_input")

	func _physics_process(_delta: float) -> void:
		if not armed:return
		age+=1
		_sample("actual_air" if rider.airborne else "release_transition")
		if rider.airborne:air_frames+=1
		if air_frames>=4:
			completed.append(phase)
			armed=false
		elif age>=30 or rider.bail_active:
			clear=false
			armed=false

	func _sample(state: String) -> void:
		var actual: Transform3D=rider._board_visual.global_transform
		var proof:="separated_native_components"
		var allowed: bool
		if state=="release_input":
			# A loaded hanger is intentionally in real finite bearing contact;
			# the manual no-contact volume oracle is not its physical contract.
			proof="authenticated_loaded_bearing"
			allowed=loaded_certified
		elif rider.global_position.distance_to(loaded_origin)<0.00001:
			# Native release initially changes state before the body travels.
			# Preserve that SAME authenticated actual frame within10micrometres,
			# rather than inventing a new ground/air roll through the seat.
			proof="unchanged_loaded_frame"
			allowed=retained_clear(actual,rider.get_node("BodyCollision").global_transform,
				rider._visual.global_transform)
		else:
			allowed=rider._manual_model_frame_clear(actual)
		clear=clear and allowed
		samples.append({"phase":phase,"state":state,"proof":proof,"physics":Engine.get_physics_frames(),
			"at":rider.global_position,"board":actual,"rider_root_change":rider._rider_visual.global_position.distance_to(loaded_rider.origin),"clear":allowed})

	func retained_clear(board: Transform3D,capsule: Transform3D,visual: Transform3D) -> bool:
		# Articulated rider posture may unload while sole IK stays planted;
		# those separate Motion/contact gates must not freeze a natural pop.
		return loaded_certified and _same_frame(board,loaded_frame) and _same_frame(capsule,loaded_capsule) \
			and _same_frame(visual,loaded_visual)

	func _same_frame(actual: Transform3D,expected: Transform3D) -> bool:
		return actual.origin.distance_to(expected.origin)<0.00001 \
			and actual.basis.x.distance_to(expected.basis.x)<0.00001 \
			and actual.basis.y.distance_to(expected.basis.y)<0.00001 \
			and actual.basis.z.distance_to(expected.basis.z)<0.00001


class AirWallWitness extends Node:
	# Ordinary charged Ollies have no named loaded hanger contact. Inspect the
	# actual board hull after every controller physics callback, so a single
	# airborne wall clip cannot hide between the slower chase-camera samples.
	var rider: Node
	var checked:=0
	var clear:=true
	var shoe_clear:=true
	var offset_clear:=true
	var capsule_clear:=true
	var landing_clear:=true
	var forecast_proven_or_zero:=true
	var owner_only_frames:=0
	var forecast_clear:=true
	var forecast_frames:=0
	var maximum_forecast_queries:=0
	var forecast_foreign_ran:=false
	var forecast_foreign_rejected:=false
	var forecast_miss_ran:=false
	var forecast_miss_rejected:=false
	var forecast_samples: Array[Dictionary]=[]
	var forecast_controls_ran:=false
	var forecast_controls_clear:=true
	var forecast_controls: Array[Dictionary]=[]
	var owner_query_samples: Array[Dictionary]=[]
	var forecast_query_counts: Array[int]=[]
	var forecast_query_histogram: Dictionary={}
	var independent_component_queries:=0
	var independent_pose_queries:=0
	var independent_face_rays:=0
	var foreign_ran:=false
	var foreign_rejected:=false
	var foreign_hint: Dictionary={}
	var saw_air:=false
	var residual_frames:=0
	var maximum_offset:=0.0
	var maximum_step:=0.0
	var previous_offset:=Vector3.ZERO
	var failures: Array[Dictionary]=[]

	func _physics_process(delta: float) -> void:
		var offset: Vector3=rider._obstacle_visual_offset
		var offset_step:=offset.distance_to(previous_offset)
		previous_offset=offset
		if not rider.airborne:
			if saw_air and rider.is_on_floor():
				landing_clear=landing_clear and rider._obstacle_air_wall.is_empty() and rider._obstacle_air_wall_owner.is_empty() and rider._obstacle_air_forecast.is_empty()
			return
		saw_air=true
		checked+=1
		var actual: Transform3D=rider._board_visual.global_transform
		var sample_clear: bool=rider._manual_model_frame_clear(actual)
		clear=clear and sample_clear
		var capsule_sample:=EdgeTrial._capsule_clear(rider)
		capsule_clear=capsule_clear and capsule_sample
		maximum_offset=maxf(maximum_offset,offset.length())
		maximum_step=maxf(maximum_step,offset_step)
		var finite_offset:=offset.is_finite() and absf(offset.y)<=0.000001 and offset.length()<=0.18 and offset_step<=0.18
		offset_clear=offset_clear and finite_offset
		var full_skin_clear:=true
		# Fault controls may clear and replace the live dictionary; preserve the
		# independently observed receipt for later query attribution this tick.
		var forecast: Dictionary=rider._obstacle_air_forecast.duplicate()
		var predicted_valid:=false
		if not forecast.is_empty():
			forecast_frames+=1
			predicted_valid=_forecast_proof(forecast,actual,offset,delta)
			forecast_clear=forecast_clear and predicted_valid
			maximum_forecast_queries=maxi(maximum_forecast_queries,int(forecast.get("queries",0)))
			full_skin_clear=_pose_skin_clear(Vector3.ZERO)
			shoe_clear=shoe_clear and full_skin_clear
			if predicted_valid and not forecast_controls_ran:_forecast_negatives(delta,actual)
			if predicted_valid and not forecast_foreign_ran and rider.velocity.y<0 and not rider.is_on_wall():
				_foreign_owner_negative(true)
		if rider._obstacle_air_wall.is_empty() and not rider._obstacle_air_wall_owner.is_empty():
			owner_only_frames+=1
			forecast_proven_or_zero=forecast_proven_or_zero and (offset==Vector3.ZERO or predicted_valid)
			_record_forecast_queries(forecast)
		if not rider._obstacle_air_wall.is_empty():
			residual_frames+=1
			# This helper rechecks the displayed convex board and both native
			# shoe volumes with the existing8mm skin. It cannot skip the wall RID.
			full_skin_clear=rider._obstacle_air_clear(Vector3.ZERO)
			shoe_clear=shoe_clear and full_skin_clear
			if not foreign_ran and rider.velocity.y<0 and not rider.is_on_wall() and offset!=Vector3.ZERO:
				_foreign_owner_negative()
		if (not sample_clear or not full_skin_clear or not finite_offset or not capsule_sample or (not forecast.is_empty() and not predicted_valid)) and failures.size()<8:
			failures.append({"physics":Engine.get_physics_frames(),"at":rider.global_position,"board":actual,
				"components_clear":sample_clear,"capsule_clear":capsule_sample,"board_shoe_skin_clear":full_skin_clear,"offset":offset,"offset_step":offset_step,
				"forecast":forecast.duplicate(),"forecast_valid":predicted_valid,"air_wall":rider._obstacle_air_wall.duplicate(),"is_on_wall":rider.is_on_wall(),"is_on_floor":rider.is_on_floor(),
				"launch":rider._launch_id,"velocity":rider.velocity,"native_component_hits":_component_hits(actual)})


	func _forecast_proof(receipt: Dictionary,actual: Transform3D,offset: Vector3,delta: float) -> bool:
		# PRIVATE intent-forecast witness. Actual present-frame contacts remain
		# unchanged; every nonzero anticipated move needs fresh finite evidence.
		var owner: Dictionary=rider._obstacle_air_wall_owner
		if owner.is_empty() or not rider._obstacle_air_wall.is_empty() or not rider.airborne:return false
		if typeof(receipt.get("rid"))!=TYPE_RID or typeof(receipt.get("shape"))!=TYPE_INT \
			or typeof(receipt.get("step"))!=TYPE_INT or not receipt.get("face") is Dictionary:return false
		if not receipt.get("travel") is Vector3 or not receipt.get("endpoint") is Vector3 \
			or not receipt.get("offset") is Vector3:return false
		var face: Dictionary=receipt.face
		var step: int=receipt.step
		var horizon:=float(receipt.get("horizon",NAN))
		var weight:=float(receipt.get("weight",NAN))
		var travel: Vector3=receipt.travel
		var endpoint: Vector3=receipt.endpoint
		var measured: Vector3=receipt.offset
		var queries:=int(receipt.get("queries",0))
		var cap:=int(receipt.get("query_cap",0))
		if not is_finite(delta) or delta<=0 or not is_finite(horizon) or horizon<=0 or horizon>.120000001 \
			or step<1 or step>7 or absf(horizon-step*delta)>.000001:return false
		if not is_finite(weight) or weight<0 or weight>1 or not travel.is_finite() \
			or not endpoint.is_finite() or not measured.is_finite() or not offset.is_finite():return false
		if queries<1 or cap!=AirController.AIR_FORECAST_QUERY_CAP or cap<1 or cap>192 or queries>cap:return false
		if int(receipt.get("part_count",-1))!=rider._grind_clearance._parts.size():return false
		if int(receipt.get("aabb_rejected_steps",-1))<0 or int(receipt.get("aabb_rejected_steps",-1))>=step:return false
		if receipt.rid!=owner.get("rid") or receipt.shape!=owner.get("shape") \
			or face.get("rid")!=receipt.rid or face.get("shape")!=receipt.shape:return false
		var normal: Vector3=face.get("normal",Vector3.INF)
		var point: Vector3=face.get("position",Vector3.INF)
		var old_normal: Vector3=owner.get("normal",Vector3.INF)
		if not normal.is_finite() or not point.is_finite() or not old_normal.is_finite() \
			or absf(normal.y)>.001 or absf(normal.length_squared()-1)>.001 or normal.dot(old_normal)<.999:return false
		if absf(endpoint.y)>.000001 or endpoint.length()>.18 \
			or measured.distance_to(endpoint*weight)>.000001 or offset.distance_to(measured)>.000001:return false
		var gravity: float=AirController.RAMP_AIR_GRAVITY if rider._ramp_air else (AirController.WEIGHTED_OLLIE_GRAVITY if rider._weighted_ollie_air else AirController.GRAVITY)
		var expected: Vector3=rider.velocity*(delta*step)-Vector3.UP*(gravity*delta*delta*step*(step+1)*.5)
		var expected_weight:=smoothstep(0.0,.120,.120-maxf(0.0,(step-1)*delta))
		if travel.distance_to(expected)>.00001 or absf(weight-expected_weight)>.000001:return false
		if not _finite_positive_frame(actual):return false
		var future:=actual
		future.origin+=travel-offset
		var component:=_future_owner_component(future,receipt)
		if component<0:return false
		var ray:=PhysicsRayQueryParameters3D.create(point+normal*.03,point-normal*.03,rider.collision_mask,[rider.get_rid()])
		independent_face_rays+=1
		var hit: Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or hit.rid!=receipt.rid or hit.shape!=receipt.shape \
			or Vector3(hit.normal).dot(normal)<.999 or Vector3(hit.position).distance_to(point)>.002:return false
		var corrected:=future
		corrected.origin+=endpoint
		if not _components_clear(corrected) or not _pose_skin_clear(travel-offset+endpoint):return false
		if not forecast_miss_ran:
			forecast_miss_ran=true
			var miss:=future
			miss.origin+=Vector3.UP*20.0
			forecast_miss_rejected=_future_owner_component(miss,receipt)==-1
		if forecast_samples.size()<12:
			forecast_samples.append({"physics":Engine.get_physics_frames(),"step":step,"horizon":horizon,
				"component":component,"rid":receipt.rid,"shape":receipt.shape,"point":hit.position,
				"travel":travel,"endpoint":endpoint,"weight":weight,"offset":offset,"queries":queries,"cap":cap})
		return true

	func _finite_positive_frame(frame: Transform3D) -> bool:
		var determinant:=frame.basis.determinant()
		return frame.origin.is_finite() and frame.basis.is_finite() and is_finite(determinant) and determinant>0

	func _future_owner_component(frame: Transform3D,receipt: Dictionary) -> int:
		# Independent actual connected-component queries, never the controller's
		# forecast helper or the whole-board envelope as contact authority.
		if not _finite_positive_frame(frame):return -2
		var query:=PhysicsShapeQueryParameters3D.new()
		query.transform=frame
		query.collision_mask=1|2|8
		query.exclude=[rider.get_rid()]
		query.margin=0.0
		var space: PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
		for index: int in rider._grind_clearance._parts.size():
			query.shape=rider._grind_clearance._parts[index].shape
			independent_component_queries+=1
			var hits:=space.intersect_shape(query,16)
			if hits.size()>=16:return -2
			for hit: Dictionary in hits:
				if hit.rid==receipt.rid and hit.shape==receipt.shape:return index
		return -1

	func _components_clear(frame: Transform3D) -> bool:
		if not _finite_positive_frame(frame):return false
		var query:=PhysicsShapeQueryParameters3D.new()
		query.transform=frame
		query.collision_mask=1|2|8
		query.exclude=[rider.get_rid()]
		query.margin=0.0
		var space: PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
		for part: Dictionary in rider._grind_clearance._parts:
			query.shape=part.shape
			independent_component_queries+=1
			if not space.intersect_shape(query,1).is_empty():return false
		return true

	func _pose_skin_clear(translation: Vector3) -> bool:
		if not translation.is_finite():return false
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=rider._visual_rig.board_contact_geometry().convex_shape
		query.transform=rider._board_visual.global_transform
		query.transform.origin+=translation
		if not _finite_positive_frame(query.transform):return false
		query.collision_mask=rider.collision_mask
		query.exclude=[rider.get_rid()]
		query.margin=AirController.GROUND_PRESENTATION_SKIN-.00001
		var space: PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
		independent_pose_queries+=1
		if not space.intersect_shape(query,1).is_empty():return false
		var box:=BoxShape3D.new()
		query.shape=box
		for index: int in rider._visual_rig._legs.size():
			var bounds: AABB=rider._obstacle_shoe_bounds[index]
			box.size=bounds.size
			query.transform=rider._visual_rig._legs[index].foot.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
			query.transform.origin+=translation
			if not _finite_positive_frame(query.transform):return false
			independent_pose_queries+=1
			if not space.intersect_shape(query,1).is_empty():return false
		return true

	func _record_forecast_queries(receipt: Dictionary) -> void:
		# Success includes the controller's reserved final current-pose upper
		# bound. Refusal is the actual counted forecast calls. These exclude
		# this observer's own independent native queries and the unchanged
		# reactive entry path; they are query counts, never timing evidence.
		var physics:=Engine.get_physics_frames()
		var attempt: bool=rider._air_forecast_physics==physics
		var success:=not receipt.is_empty()
		var counter: int=rider._air_forecast_queries
		var count: int=(int(receipt.get("queries",0)) if success else counter) if attempt else 0
		if success and not attempt:forecast_clear=false
		if attempt:
			forecast_query_counts.append(count)
			forecast_query_histogram[count]=int(forecast_query_histogram.get(count,0))+1
			forecast_clear=forecast_clear and count>=0 and count<=AirController.AIR_FORECAST_QUERY_CAP
		owner_query_samples.append({"physics":physics,"forecast_invocation_physics":rider._air_forecast_physics,
			"actual_attempt":attempt,"success":success,"forecast_query_upper_bound":count,
			"raw_counter":counter,"attribution":"successful_receipt" if success else ("current_refusal_counter" if attempt else "no_current_forecast_invocation"),
			"independent_observer_queries_excluded":true})

	func forecast_query_distribution() -> Dictionary:
		var ordered:=forecast_query_counts.duplicate()
		ordered.sort()
		var accepted:=0
		for sample: Dictionary in owner_query_samples:
			if sample.actual_attempt and sample.success:accepted+=1
		var result: Dictionary={"count":ordered.size(),"owner_only_air_frames":owner_query_samples.size(),
			"accepted_attempts":accepted,"refused_attempts":ordered.size()-accepted,"histogram":forecast_query_histogram.duplicate(),
			"kind":"incremental forecast query counts/accepted-current-guard upper bounds; no timing or FPS claim",
			"refusal_attribution_complete":true,"percentile_method":"nearest rank; failed attempts and zero-query refusals included"}
		for percentile: int in [50,95,99,100]:
			result["p"+str(percentile)]=0 if ordered.is_empty() else ordered[clampi(ceili(ordered.size()*percentile/100.0)-1,0,ordered.size()-1)]
		return result

	func _forecast_negatives(delta: float,actual: Transform3D) -> void:
		# These are explicitly adversarial synchronous probes after a real
		# independently authenticated positive. No physics/input step occurs.
		forecast_controls_ran=true
		if foreign_hint.is_empty():
			forecast_controls_clear=false
			forecast_controls.append({"control":"real_foreign_floor_exists","matches":false})
			return
		var saved:=_save_forecast_fault_state()
		var physics:=Engine.get_physics_frames()
		var capsule: Transform3D=rider.global_transform
		var unfitted:=actual
		unfitted.origin-=Vector3(saved.offset)
		var earned: Dictionary=saved.owner
		var normal: Vector3=earned.normal
		for label: String in ["no_owner_argument","no_earned_owner","foreign_argument_rid","foreign_argument_shape",
			"foreign_argument_normal","foreign_argument_plane","mode_takeover","invalid_delta",
			"upward_predicted_clear","away_predicted_clear"]:
			_restore_forecast_fault_state(saved)
			var owner: Dictionary=earned.duplicate()
			var probe_delta:=delta
			var zero_query:=true
			var independent_miss:=true
			match label:
				"no_owner_argument":owner={}
				"no_earned_owner":rider._obstacle_air_wall_owner={}
				"foreign_argument_rid":owner.rid=foreign_hint.rid
				"foreign_argument_shape":owner.shape=int(earned.shape)+1
				"foreign_argument_normal":owner.normal=-normal
				"foreign_argument_plane":owner.position=Vector3(earned.position)+normal*.01
				"mode_takeover":rider._launch_id="wallie"
				"invalid_delta":probe_delta=NAN
				"upward_predicted_clear":
					rider.velocity=Vector3.UP*40.0
					zero_query=false
					independent_miss=_all_future_components_miss(unfitted,owner,delta)
				"away_predicted_clear":
					rider.velocity=normal*40.0
					zero_query=false
					independent_miss=_all_future_components_miss(unfitted,owner,delta)
			var result: Dictionary=rider._air_wall_forecast(owner,probe_delta)
			var queries: int=rider._air_forecast_queries
			var refused: bool=result.is_empty() and independent_miss and queries>=0 \
				and queries<=AirController.AIR_FORECAST_QUERY_CAP and (not zero_query or queries==0)
			forecast_controls_clear=forecast_controls_clear and refused
			forecast_controls.append({"control":label,"physics":physics,"refused":refused,"queries":queries,
				"zero_query_required":zero_query,"independent_future_miss":independent_miss})
		_restore_forecast_fault_state(saved)
		var malformed_origin:=Transform3D.IDENTITY
		malformed_origin.origin=Vector3(NAN,0,0)
		var malformed_basis:=Transform3D.IDENTITY
		malformed_basis.basis.x=Vector3(NAN,0,0)
		var singular:=Transform3D.IDENTITY
		singular.basis.x=Vector3.ZERO
		var mirrored:=Transform3D.IDENTITY
		mirrored.basis.x=Vector3.LEFT
		var overflow_determinant:=Transform3D(Basis.from_scale(Vector3.ONE*1.0e20),Vector3.ZERO)
		var overflow:=Transform3D.IDENTITY
		overflow.origin=Vector3(3.0e38,0,0)
		var cases: Array[Dictionary]=[
			{"label":"finite_frame_positive","frame":unfitted,"travel":Vector3.ZERO,"expected":true},
			{"label":"nan_frame_origin","frame":malformed_origin,"travel":Vector3.ZERO,"expected":false},
			{"label":"nan_frame_basis","frame":malformed_basis,"travel":Vector3.ZERO,"expected":false},
			{"label":"singular_frame","frame":singular,"travel":Vector3.ZERO,"expected":false},
			{"label":"mirrored_frame","frame":mirrored,"travel":Vector3.ZERO,"expected":false},
			{"label":"nan_travel","frame":unfitted,"travel":Vector3(0,NAN,0),"expected":false},
			{"label":"finite_basis_determinant_overflow","frame":overflow_determinant,"travel":Vector3.ZERO,"expected":false},
			{"label":"finite_sum_overflow","frame":overflow,"travel":Vector3(3.0e38,0,0),"expected":false}]
		for item: Dictionary in cases:
			var queries_before: int=rider._air_forecast_queries
			var accepted: bool=rider._air_forecast_frame_valid(item.frame,item.travel)
			var matches: bool=accepted==bool(item.expected) and rider._air_forecast_queries==queries_before
			forecast_controls_clear=forecast_controls_clear and matches
			forecast_controls.append({"control":item.label,"physics":physics,"matches":matches,
				"accepted":accepted,"expected":item.expected,"query_delta":rider._air_forecast_queries-queries_before})
		_restore_forecast_fault_state(saved)
		var reserved: int=3+rider._grind_clearance._parts.size()
		var hard_limit: int=AirController.AIR_FORECAST_QUERY_CAP-reserved
		rider._air_forecast_queries=hard_limit
		rider._air_forecast_counting=true
		var hardcap_refused: bool=not rider._air_forecast_query() \
			and rider._air_forecast_queries==hard_limit and rider._air_forecast_counting \
			and rider._air_forecast_physics==saved.invocation_physics
		forecast_controls_clear=forecast_controls_clear and hardcap_refused
		forecast_controls.append({"control":"reserved_current_pose_hardcap_refusal","physics":physics,
			"refused":hardcap_refused,"counter_before":hard_limit,"counter_after":rider._air_forecast_queries,
			"reserved_current_pose_queries":reserved,"query_cap":AirController.AIR_FORECAST_QUERY_CAP})
		_restore_forecast_fault_state(saved)
		var restored: bool=rider.global_transform==capsule and Engine.get_physics_frames()==physics \
			and rider.velocity==saved.velocity and rider._launch_id==saved.launch \
			and rider._visual.transform==saved.visual and rider._board_visual.global_transform==actual \
			and rider._obstacle_air_wall==saved.active and rider._obstacle_air_wall_owner==saved.owner \
			and rider._obstacle_air_forecast==saved.forecast and rider._obstacle_visual_offset==saved.offset \
			and rider._air_forecast_queries==saved.queries and rider._air_forecast_counting==saved.counting \
			and rider._air_forecast_physics==saved.invocation_physics \
			and _query_state(rider._air_forecast_probe_query)==saved.probe \
			and _query_state(rider._air_forecast_volume_query)==saved.volume \
			and rider._air_forecast_shoe_box.size==saved.shoe_size
		forecast_controls_clear=forecast_controls_clear and restored
		forecast_controls.append({"control":"synchronous_complete_restore","physics":physics,"restored":restored})

	func _all_future_components_miss(frame: Transform3D,owner: Dictionary,delta: float) -> bool:
		var gravity: float=AirController.RAMP_AIR_GRAVITY if rider._ramp_air else (AirController.WEIGHTED_OLLIE_GRAVITY if rider._weighted_ollie_air else AirController.GRAVITY)
		for step: int in range(1,mini(7,int(floor(.120/delta)))+1):
			var future:=frame
			future.origin+=rider.velocity*(delta*step)-Vector3.UP*(gravity*delta*delta*step*(step+1)*.5)
			if _future_owner_component(future,owner)!=-1:return false
		return true

	func _save_forecast_fault_state() -> Dictionary:
		return {"visual":rider._visual.transform,"offset":rider._obstacle_visual_offset,
			"active":rider._obstacle_air_wall.duplicate(),"owner":rider._obstacle_air_wall_owner.duplicate(),
			"forecast":rider._obstacle_air_forecast.duplicate(),"queries":rider._air_forecast_queries,
			"invocation_physics":rider._air_forecast_physics,
			"counting":rider._air_forecast_counting,"probe":_query_state(rider._air_forecast_probe_query),
			"volume":_query_state(rider._air_forecast_volume_query),"shoe_size":rider._air_forecast_shoe_box.size,
			"velocity":rider.velocity,"launch":rider._launch_id}

	func _restore_forecast_fault_state(saved: Dictionary) -> void:
		rider._visual.transform=saved.visual
		rider._obstacle_visual_offset=saved.offset
		rider._obstacle_air_wall=saved.active.duplicate()
		rider._obstacle_air_wall_owner=saved.owner.duplicate()
		rider._obstacle_air_forecast=saved.forecast.duplicate()
		rider._air_forecast_queries=saved.queries
		rider._air_forecast_physics=saved.invocation_physics
		rider._air_forecast_counting=saved.counting
		_restore_query(rider._air_forecast_probe_query,saved.probe)
		_restore_query(rider._air_forecast_volume_query,saved.volume)
		rider._air_forecast_shoe_box.size=saved.shoe_size
		rider.velocity=saved.velocity
		rider._launch_id=saved.launch

	func _query_state(query: PhysicsShapeQueryParameters3D) -> Dictionary:
		return {"shape":query.shape,"transform":query.transform,"margin":query.margin,"motion":query.motion,
			"mask":query.collision_mask,"exclude":query.exclude.duplicate(),"areas":query.collide_with_areas,"bodies":query.collide_with_bodies}

	func _restore_query(query: PhysicsShapeQueryParameters3D,saved: Dictionary) -> void:
		query.shape=saved.shape
		query.transform=saved.transform
		query.margin=saved.margin
		query.motion=saved.motion
		query.collision_mask=saved.mask
		query.exclude=saved.exclude
		query.collide_with_areas=saved.areas
		query.collide_with_bodies=saved.bodies

	func _component_hits(actual: Transform3D) -> Array[Dictionary]:
		var result: Array[Dictionary]=[]
		var query:=PhysicsShapeQueryParameters3D.new()
		query.transform=actual
		query.collision_mask=1|2|8
		query.exclude=[rider.get_rid()]
		query.margin=0.0
		var space: PhysicsDirectSpaceState3D=rider.get_world_3d().direct_space_state
		for index: int in rider._grind_clearance._parts.size():
			query.shape=rider._grind_clearance._parts[index].shape
			var hits: Array[Dictionary]=[]
			for hit: Dictionary in space.intersect_shape(query,4):
				hits.append({"collider":str(hit.collider.get_path()),"rid":hit.rid,"shape":hit.shape})
			if not hits.is_empty():result.append({"component":index,"hits":hits,"rest":space.get_rest_info(query)})
		return result

	func _foreign_owner_negative(forecast_case: bool=false) -> void:
		# A deliberate fault injection, never a successful-input fixture: swap
		# only owner RID/shape to a real different floor while retaining the old
		# wall hint. No native actor/input mutation or physics advance occurs.
		if foreign_hint.is_empty():return
		if forecast_case:forecast_foreign_ran=true
		else:foreign_ran=true
		var saved_visual: Transform3D=rider._visual.transform
		var saved_offset: Vector3=rider._obstacle_visual_offset
		var saved_active: Dictionary=rider._obstacle_air_wall.duplicate()
		var saved_owner: Dictionary=rider._obstacle_air_wall_owner.duplicate()
		var saved_forecast: Dictionary=rider._obstacle_air_forecast.duplicate()
		var saved_queries: int=rider._air_forecast_queries
		var saved_physics: int=rider._air_forecast_physics
		var saved_counting: bool=rider._air_forecast_counting
		var saved_probe:=_query_state(rider._air_forecast_probe_query)
		var saved_volume:=_query_state(rider._air_forecast_volume_query)
		var saved_shoe_size: Vector3=rider._air_forecast_shoe_box.size
		var wrong: Dictionary=saved_owner.duplicate()
		wrong.rid=foreign_hint.rid
		wrong.shape=foreign_hint.shape
		wrong.collider=foreign_hint.collider
		var unfitted:=saved_visual
		unfitted.origin-=rider.global_basis.inverse()*saved_offset
		rider._visual.transform=unfitted
		rider._obstacle_visual_offset=Vector3.ZERO
		rider._obstacle_air_wall={}
		rider._obstacle_air_wall_owner=wrong
		var accepted: bool=rider._place_air_wall_wheels(1.0/60.0)
		var refused: bool=not accepted and rider._obstacle_visual_offset==Vector3.ZERO \
			and rider._visual.transform==unfitted and rider._obstacle_air_forecast.is_empty()
		if forecast_case:forecast_foreign_rejected=refused
		else:foreign_rejected=refused
		# Restore the exact displayed native-supported presentation before the
		# callback returns. The next physical/input step sees no injected state.
		rider._visual.transform=saved_visual
		rider._obstacle_visual_offset=saved_offset
		rider._obstacle_air_wall=saved_active
		rider._obstacle_air_wall_owner=saved_owner
		rider._obstacle_air_forecast=saved_forecast
		rider._air_forecast_queries=saved_queries
		rider._air_forecast_physics=saved_physics
		rider._air_forecast_counting=saved_counting
		_restore_query(rider._air_forecast_probe_query,saved_probe)
		_restore_query(rider._air_forecast_volume_query,saved_volume)
		rider._air_forecast_shoe_box.size=saved_shoe_size


static func run(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var old_spawn: Vector3=game.skater.spawn_position
	var old_mode: bool=game.free_skate_mode
	await Driver._frames(tree,2)
	var world: Node3D=game.world
	var feature: Dictionary={}
	for candidate: Dictionary in world.get_skate_feature_definitions():
		if candidate.id=="exchange_south_line":feature=candidate
	check.call(not feature.is_empty() and feature.position.distance_to(Vector3(-10,0,20))<0.002
		and feature.line[0].distance_to(Vector3(-10,0,9))<0.002
		and feature.line[-1].distance_to(Vector3(-10,0,31))<0.002,
		"November lines: existing Exchange bank follows fixed west-fountain exit witnesses")
	var parity:=true
	for z: float in [12.8,13.2,14,15,16,16.8,17.2,19,22.8,23.2,24,25,26,26.8,27.2]:
		for x: float in [-11.7,-10,-8.3]:
			var expected:=0.55*clampf(minf(z-13,27-z)/4.0,0,1)
			var at:=Vector3(x,expected,z)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.1,at-Vector3.UP*0.1,1))
			parity=parity and absf(world.get_ground_height(at)-expected)<0.002 \
				and not hit.is_empty() and absf(Vector3(hit.position).y-expected)<0.002
	check.call(parity,"November lines:45 independent rotated-bank witnesses match native and query support")
	var passage:=true
	for x: float in [-22,-12,-10,-8,0,12,22]:
		passage=passage and Routes._clear_standing(world,Vector3(x,0,28))
	passage=passage and Routes._clear_sweep(world,Vector3(-22,0,28),Vector3(22,0,28)) \
		and Routes._clear_sweep(world,Vector3(22,0,28),Vector3(-22,0,28))
	check.call(passage,"November lines: unchanged Z28 beginner crossing keeps full native two-way passage")
	var tracks: Dictionary={}
	for line in world.get_grind_lines():tracks[line.id]=line
	var seats:=tracks.has(FIRST) and tracks.has(SECOND)
	if seats:
		seats=tracks[FIRST].points[0].distance_to(Vector3(39.32,2.53,63.725))<0.002 \
			and tracks[FIRST].length>5.3 and tracks[SECOND].length>5.3
	check.call(seats,"November lines: both real extended seats preserve original semantic edge identities")
	var contact:=seats
	if seats:
		for id: String in [FIRST,SECOND]:
			var line: RefCounted=tracks[id]
			contact=contact and line.contact_verified and line.contact_source=="skate_edges.native_box_top" \
				and absf(line.contact_vertical_offset+0.04)<0.000001 and line.native_support_rids.size()==1 \
				and line.contact_edge_outward.length_squared()>0.999
	check.call(contact,"November lines: only inspected seat boxes publish exact finite native top/face/RID contact")
	var bypass:=true
	for z: float in [68.0,68.5,69.0,69.5,70.0,70.5,71.0,71.5,72.0]:
		var start:=Vector3(24,2,z)
		var finish:=Vector3(78,2,z)
		bypass=bypass and Routes._clear_sweep(world,start,finish) and Routes._clear_sweep(world,finish,start)
		for x: float in [24,32,42,54,64,76]:
			bypass=bypass and Routes._ground_below(world,Vector3(x,2,z))
	check.call(bypass,"November lines: independent nine-lane sweeps retain the complete4m east-quay bypass")
	var seat_count:=0
	var seat_shapes:=0
	var supports:=0
	for body: Node3D in world.find_children("*","Node3D",true,false):
		if body.global_position.z<55 or body.global_position.z>78:continue
		var label:=String(body.get_meta("art_label",""))
		if label=="QuayBenchSupport":supports+=1
		if label!="QuayBenchSeat":continue
		seat_count+=1
		for child: Node in body.get_children():
			if child is CollisionShape3D:seat_shapes+=1
	check.call(seat_count==3 and seat_shapes==3 and supports==6,
		"November lines: existing quay seating retains exactly three bodies/shapes and six decorative supports")
	if not feature.is_empty():await Density._manual_crossing(tree,game,feature,check,observer)
	if seats:
		await EdgeTrial._approach(tree,game,world.get_grind_lines(),check,
			{"family":"Bench_x800y244z5900_","at":Vector3(40,2.53,63.725),"direction":Vector3.RIGHT,"outside":Vector3.FORWARD,"behind":0.9,"charge":2})
		var direction:=Vector3(cos(deg_to_rad(15)),0,-sin(deg_to_rad(15)))
		await EdgeTrial._approach(tree,game,world.get_grind_lines(),check,
			{"family":"Bench_x7000y244z5900_","at":tracks[SECOND].points[0],"direction":direction,"outside":Vector3(-direction.z,0,direction.x)*-1,"behind":0.9,"charge":2})
		await run_relay(tree,game,check,observer)
	await run_bank_return(tree,game,check,observer)
	await run_bank_jump_misses(tree,game,check,observer)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
	await Driver._frames(tree,3)


static func run_relay(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var next_line: RefCounted
	for line: RefCounted in game.world.get_grind_lines():
		if String(line.id)==SECOND:next_line=line
	if next_line==null:
		check.call(false,"November lines: second native seat bearing exists for the real relay")
		return
	var next_start: Vector3=next_line.points[0]
	var next_direction: Vector3=(next_line.points[-1]-next_start).normalized()
	var next_outside: Vector3=next_line.contact_edge_outward
	var next_join: Vector3=next_start-next_direction*4.0+next_outside*.35
	var next_aim: Vector3=next_start+next_direction*4.0+next_outside*.35
	await Driver._reset(tree,game,Vector3(33,2.08,63.55),-PI*.5)
	await Driver._frames(tree,40)
	var exit_witness:=ExitModelWitness.new()
	exit_witness.rider=game.skater
	exit_witness.process_physics_priority=100
	game.add_child(exit_witness)
	var e:=Driver._evidence(game,"east_quay_seating_relay")
	e["event_ticks"]=[]
	e["physics_start"]=Engine.get_physics_frames()
	e["seat_fit"]=true
	Driver._connect(game,e)
	var popped:=false
	for tick: int in 240:
		if not popped:
			Driver._steer_to(game,Vector3(48,2,63.55),false)
			# Hold Push through the cap, matching the existing gallery driver.
			# Equal brake pressure controls speed without repeatedly arming a
			# directional Boneless/Nollie cue immediately before the plain pop.
			Input.action_press("push")
			Input.action_release("brake")
			if absf(game.skater.speed)>6.6:Input.action_press("brake")
			if game.skater.global_position.x>=36.5:Input.action_press("ollie")
			if game.skater.global_position.x>=38:
				Input.action_release("ollie")
				Input.action_release("push")
				Input.action_release("brake")
				popped=true
		Input.action_press("grind")
		await Driver._step(tree,game,e,"first_seat_approach",observer)
		if game.skater.grinding or e.bails>0:break
	var first: bool=game.skater.grinding and game.skater._grind.line.id==FIRST
	if first:
		e.seat_fit=e.seat_fit and _native_seat_fit(game)
		e.event_ticks.append({"event":"first_catch","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		for tick: int in 120:
			await Driver._step(tree,game,e,"first_seat_ride",observer)
			if game.skater.grinding and tick%4==0:e.seat_fit=e.seat_fit and _native_seat_fit(game)
			if game.skater.global_position.x>=43.4 or not game.skater.grinding:break
		e.event_ticks.append({"event":"first_exit_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"first_outward_pop_charge",observer)
		exit_witness.arm("first_seat_release",_native_seat_fit(game))
		var intruded: Transform3D=exit_witness.loaded_frame
		intruded.origin.y-=.0263
		var rolled: Transform3D=exit_witness.loaded_frame
		rolled.basis=Basis(-rolled.basis.z,-.304)*rolled.basis
		check.call(not exit_witness.retained_clear(intruded,exit_witness.loaded_capsule,exit_witness.loaded_visual)
			and not exit_witness.retained_clear(rolled,exit_witness.loaded_capsule,exit_witness.loaded_visual),
			"November lines: known26.3mm intrusion and stale0.304rad roll cannot inherit authenticated loaded-pose authority")
		Input.action_release("ollie")
		await Driver._step(tree,game,e,"first_outward_pop",observer)
		Input.action_release("grind")
		await Driver._landing_manual(tree,game,e,150,"seats_manual_link",observer)
	var linked: bool=first and game.skater.manual_active
	if linked:
		e.event_ticks.append({"event":"manual_landing","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		for tick: int in 420:
			# Join the actual rotated bearing's outside lead-in, then align with
			# its tangent before charging. No guessed world-Z catch target.
			var remaining: float=(next_start-game.skater.global_position).dot(next_direction)
			Driver._manual_to(game,next_join if remaining>4.0 else next_aim)
			await Driver._step(tree,game,e,"seats_manual_link",observer)
			if (next_start-game.skater.global_position).dot(next_direction)<=2.3 or e.bails>0:break
	var second:=false
	var paving_landing:=false
	var second_pop_from_bearing:=false
	if linked and game.skater.manual_active and e.bails==0:
		e.event_ticks.append({"event":"second_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		for tick: int in 16:
			Driver._manual_to(game,next_aim)
			await Driver._step(tree,game,e,"second_seat_charge",observer)
		e.event_ticks.append({"event":"second_release","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_release("ollie")
		Input.action_release("manual")
		Input.action_release("push")
		Input.action_release("brake")
		Driver._axis("steer_left","steer_right",0)
		Driver._axis("spin_left","spin_right",0)
		Input.action_press("grind")
		for tick: int in 150:
			await Driver._step(tree,game,e,"second_seat_catch",observer)
			if game.skater.grinding or e.bails>0:break
		second=game.skater.grinding and game.skater._grind.line.id==SECOND
	if second:
		e.seat_fit=e.seat_fit and _native_seat_fit(game)
		e.event_ticks.append({"event":"second_catch","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		# Ride the finite bearing toward its end so the intended landing is the
		# paving runout. The earlier twelve-tick exit landed atop the seat and
		# exposed a separately retained native-prop visual support defect.
		for tick: int in 120:
			await Driver._step(tree,game,e,"second_seat_payoff",observer)
			if game.skater.grinding and tick%4==0:e.seat_fit=e.seat_fit and _native_seat_fit(game)
			if (game.skater.global_position-next_start).dot(next_direction)>=next_line.length-.65 or not game.skater.grinding:break
		second_pop_from_bearing=game.skater.grinding and game.skater._grind.line.id==SECOND
		e.event_ticks.append({"event":"second_exit_charge","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"second_exit_charge",observer)
		second_pop_from_bearing=second_pop_from_bearing and game.skater.grinding and game.skater._grind.line.id==SECOND
		e.seat_fit=e.seat_fit and _native_seat_fit(game)
		e.event_ticks.append({"event":"second_exit_release","tick":e.ticks,"physics":Engine.get_physics_frames(),
			"at":game.skater.global_position,"speed":game.skater.speed,"still_on_bearing":second_pop_from_bearing})
		exit_witness.arm("second_seat_release",_native_seat_fit(game))
		Input.action_release("ollie")
		await Driver._step(tree,game,e,"second_exit",observer)
		Input.action_release("grind")
		await Driver._landing_manual(tree,game,e,150,"second_landing",observer)
		var point: Vector3=game.skater.global_position
		var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			point+Vector3.UP*.12,point-Vector3.UP*.18,1))
		var paving: StaticBody3D=game.world._outdoors.get_node("ClydeNorthQuay")
		paving_landing=game.skater.manual_active and absf(point.y-2.0)<0.18 \
			and (point-next_line.points[-1]).dot(next_direction)>.55 and EdgeTrial._standing_clear(game.skater) \
			and not hit.is_empty() and hit.collider==paving and absf(Vector3(hit.position).y-2.0)<0.002
		e.event_ticks.append({"event":"paving_landing","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"clear":paving_landing})
	var exit_model_clear: bool=exit_witness.clear and exit_witness.completed.has("first_seat_release") \
		and exit_witness.completed.has("second_seat_release")
	check.call(exit_model_clear,"November lines: both actual loaded bearing frames persist until native body travel, then GLB components clear on every initial airborne physics step")
	print("NOVEMBER_NATIVE_EXIT_WITNESS completed=",exit_witness.completed," clear=",exit_witness.clear," samples=",exit_witness.samples)
	exit_witness.free()
	await Driver._finish_bank(tree,game,e,observer)
	e.event_ticks.append({"event":"banked","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position})
	var complete_relay: bool=first and linked and second and e.captures==[FIRST,SECOND] and e.manual_ticks>=20 \
		and e.seat_fit and second_pop_from_bearing and paving_landing and exit_model_clear
	check.call(complete_relay,
		"November lines: real mapped Ollie/50-50/manual/Ollie/50-50 connects two seats with native model/capsule clearance")
	if first and linked and second:Driver._check_receipt(game,e,check,"November east quay")
	print("NOVEMBER_RELAY physics_start=",e.physics_start," events=",e.event_ticks," first=",first," linked=",linked," second=",second," native_seat_fit=",e.seat_fit," paving_landing=",paving_landing)
	Driver._disconnect(game,e)
	Driver._report(e,game)
	Driver._release()
	if complete_relay and e.bails==0 and e.camera_clear and e.banks==1:
		await _return_to_entry(tree,game,check,observer)


static func _native_seat_fit(game: Node) -> bool:
	var rider: Node=game.skater
	return rider.grinding and rider.grind_style_id=="grind_50_50" and rider._grind_contact.valid \
		and rider._grind_contact.anchor_count==2 and rider._grind_contact.max_error<=0.0001 \
		and EdgeTrial._capsule_clear(rider) and rider._grind_board_clear(rider._grind_contact.board_transform,rider._grind.line,rider._grind.distance) \
		and rider._grind_clearance.allows(rider._grind_contact,rider._grind.line.contact_up(rider._grind.distance))


static func _return_to_entry(tree: SceneTree,game: Node,check: Callable,observer: Callable) -> void:
	# Continue from the actual banked landing through the terminal bank and
	# back to the entry. Neither this turnback nor the bypass uses a restart.
	var e:=Driver._evidence(game,"east_quay_bank_and_return")
	Driver._connect(game,e)
	var approach: bool=await _travel_targets(tree,game,e,[Vector3(75,2,68),Vector3(76,2,73.5),Vector3(78,2,73.5)],observer)
	var bank: Dictionary={"returned":false,"supported":false}
	if approach:bank=await _roll_bank_phase(tree,game,e,73.5,4.0,observer)
	var complete:=false
	if bank.returned:
		complete=await _travel_targets(tree,game,e,[Vector3(73,2,71),Vector3(34,2,71),Vector3(30,2,66),Vector3(33,2,63.55)],observer)
	Driver._release()
	check.call(approach and bank.returned and bank.supported and complete and e.bails==0 and e.recoveries==0
		and e.entries.is_empty() and e.camera_clear,
		"November lines: the actual relay landing climbs the terminal bank and returns fakie to entry without a reset")
	Driver._disconnect(game,e)
	Driver._report(e,game)


static func _travel_targets(tree: SceneTree,game: Node,e: Dictionary,targets: Array,observer: Callable) -> bool:
	for target: Vector3 in targets:
		var reached:=false
		for tick: int in 900:
			# A negative real speed is fakie travel. Aim the facing away from
			# its travel target, preserving native reverse motion and controls.
			var delta: Vector3=target-game.skater.global_position
			if game.skater.speed< -0.5:delta=-delta
			var desired:=atan2(-delta.x,-delta.z)
			var error: float=angle_difference(game.skater.rotation.y,desired)
			Driver._axis("spin_left","spin_right",0)
			Driver._axis("steer_left","steer_right",-clampf(error*1.8,-1,1))
			Driver._speed_input(game,4.2)
			await Driver._step(tree,game,e,"supported_return",observer)
			var point: Vector3=game.skater.global_position
			var height: float=game.world.get_support_height(point,0.3)
			if not is_finite(height) or absf(point.y-height)>=0.18 or game.skater.airborne or e.bails>0:return false
			if Vector2(point.x-target.x,point.z-target.z).length()<1.2:
				reached=true
				e.route_gates.append({"target":target,"at":point,"tick":e.ticks,"physics":Engine.get_physics_frames()})
				break
		if not reached:return false
	return true


static func run_bank_return(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var world: Node3D=game.world
	var record: Dictionary={}
	var boundary: StaticBody3D
	for body: StaticBody3D in world.find_children("*","StaticBody3D",true,false):
		if body.has_meta("bank_terminal_return"):
			boundary=body
			record=body.get_meta("bank_terminal_return")
	check.call(is_instance_valid(boundary) and not record.is_empty(),
		"November bank: original eastern terminal wall owns the integrated finite return")
	if record.is_empty():return
	var bounds: Rect2=record.bounds
	var native_triangles:=0
	var display_triangles:=0
	var live_shapes:=0
	var live_meshes:=0
	for child: Node in boundary.get_children():
		if child is CollisionShape3D:
			live_shapes+=1
			if child.shape is ConcavePolygonShape3D:native_triangles+=child.shape.get_faces().size()/3
		if child is MeshInstance3D:
			live_meshes+=1
			display_triangles+=child.mesh.get_faces().size()/3
	check.call(live_shapes==int(record.shape_count) and live_meshes==1 and native_triangles==display_triangles
		and display_triangles==live_shapes*20 and display_triangles-live_shapes*12==int(record.added_triangles),
		"November bank: direct native/display counts retain one mesh and original slots with eight added triangles per panel")
	var middle: float=bounds.get_center().y
	var geometry:=true
	for x: float in [80.9,81.3,82.0,82.9,83.6,84.2]:
		for z: float in [bounds.position.y+0.35,middle,bounds.end.y-0.35]:
			var expected:=2.0+(x-80.8)*2.0/3.9
			var at:=Vector3(x,expected,z)
			var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.08,at-Vector3.UP*.08,1)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(ray)
			geometry=geometry and not hit.is_empty() and hit.collider==boundary \
				and absf(hit.position.y-expected)<0.002 and absf(world.get_ground_height(at)-expected)<0.002 \
				and Vector3(hit.normal).dot(Vector3(-2.0/3.9,1,0).normalized())>0.999 \
				and BoundaryFaces._visible_segment(boundary,at+Vector3.UP*.08,at-Vector3.UP*.08)
	check.call(geometry,"November bank:18 independent slope witnesses share exact native/display/query planes and normals")
	var backing:=true
	for y: float in [4.15,5.5,6.85]:
		for z: float in [bounds.position.y+0.35,middle,bounds.end.y-0.35]:
			var start:=Vector3(84.4,y,z)
			var finish:=Vector3(85.1,y,z)
			var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,finish,1))
			backing=backing and not hit.is_empty() and hit.collider==boundary \
				and absf(hit.position.x-84.7)<0.002 and BoundaryFaces._visible_segment(boundary,start,finish)
	check.call(backing,"November bank: nine fixed elevated rays preserve real opaque terminal containment")
	var shoulder:=true
	var mouth:=PackedVector3Array([Vector3(75,2,69),Vector3(78,2,67),Vector3(94,2,55)])
	for index: int in mouth.size()-1:
		var side:=Vector3((mouth[index+1]-mouth[index]).z,0,-(mouth[index+1]-mouth[index]).x).normalized()
		for offset: float in [-1.0,-0.5,0,0.5,1.0]:
			var a:=mouth[index]+side*offset
			var b:=mouth[index+1]+side*offset
			shoulder=shoulder and Routes._clear_sweep(world,a,b) and Routes._clear_sweep(world,b,a)
			for sample: int in 13:
				var point:=a.lerp(b,float(sample)/12)
				shoulder=shoulder and Routes._ground_below(world,point)
	check.call(shoulder,"November bank: existing diagonal Barras mouth retains five supported two-way shoulder sweeps")
	# Independent fixed inboard line leaves the existing river bollards clear.
	for ceiling: float in [3.2,4.0,4.6,8.0,12.0]:
		await _uphill_rollback(tree,game,73.5,ceiling,check,observer)
	# Four retained closed collision slots meet along the bank. Real sideways
	# rolling must cross their internal panel caps without a false wall/air pop.
	await _lateral_bank_crossing(tree,game,1.0,check,observer)
	await _lateral_bank_crossing(tree,game,-1.0,check,observer)
	await Driver._miss_return(tree,game,check,"east_quay_banked_wall",Vector3(74,2.08,69),-PI*.5,
		PackedVector3Array([Vector3(78,2,67),Vector3(94,2,55),Vector3(94,0,45)]),observer)
	print("NOVEMBER_BANK_GEOMETRY bounds=",bounds," profile=",record.profile,
		" shapes=",record.shape_count," native_triangles=",native_triangles," display_triangles=",display_triangles," added_triangles=",record.added_triangles)


static func run_bank_jump_misses(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	# These exact naturally accelerated uphill pops escaped the original Y5
	# backing. Keep all four inputs, actual native landing and strict chase;
	# a capsule-only containment success must not hide a board through the wall.
	for gate: float in [78.0,78.7,79.4,80.1]:
		await Driver._reset(tree,game,Vector3(66,2.08,73.5),-PI*.5)
		await Driver._frames(tree,40)
		var e:=Driver._evidence(game,"east_bank_charged_top_miss_"+str(gate))
		Driver._connect(game,e)
		var air_model:=AirWallWitness.new()
		air_model.rider=game.skater
		air_model.foreign_hint=game.world.get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(Vector3(66,2.2,73.5),Vector3(66,1.8,73.5),1))
		air_model.process_physics_priority=100
		game.add_child(air_model)
		var reset_air_clear: bool=game.skater._obstacle_air_wall.is_empty() and game.skater._obstacle_air_wall_owner.is_empty() and game.skater._obstacle_air_forecast.is_empty()
		var physics_start:=Engine.get_physics_frames()
		var charging:=false
		var released:=false
		var charge_ticks:=0
		var escaped:=false
		var native_landing:=false
		var capsule_clear:=true
		var maximum_loaded_depth:=0.0
		var loaded_contact_samples:=0
		var floor_negatives:=false
		var loaded_contact_examples: Array[Dictionary]=[]
		var loaded_floor_keys: Array[String]=[]
		var actual_air:=false
		var charge_speed:=0.0
		var peak:=Vector3.ZERO
		var maximum_x:=-INF
		var events: Array[Dictionary]=[]
		var capsule_failures: Array[Dictionary]=[]
		for tick: int in 480:
			if not released:
				Driver._steer_to(game,Vector3(88,2,73.5),false)
				Input.action_press("push")
				if not charging and game.skater.global_position.x>=gate:
					charging=true
					Input.action_press("ollie")
					charge_speed=game.skater.speed
					events.append({"event":"charge","physics":Engine.get_physics_frames(),
						"at":game.skater.global_position,"speed":charge_speed})
				if charging:
					charge_ticks+=1
					if charge_ticks>16:
						released=true
						Driver._release()
						events.append({"event":"release","physics":Engine.get_physics_frames(),
							"at":game.skater.global_position,"speed":game.skater.speed,"velocity":game.skater.velocity})
			await Driver._step(tree,game,e,"charged_uphill_top_miss",observer)
			var at: Vector3=game.skater.global_position
			maximum_x=maxf(maximum_x,at.x)
			if at.y>peak.y:peak=at
			escaped=escaped or at.x>85.2
			actual_air=actual_air or game.skater.airborne
			if tick%8==0:
				var sample_clear:=EdgeTrial._capsule_clear(game.skater)
				if not sample_clear:
					var actual_body: CollisionShape3D=game.skater.get_node("BodyCollision")
					var supported:=_loaded_capsule_contact(game,actual_body.global_transform)
					sample_clear=supported.clear
					if supported.clear and supported.get("loaded",false):
						loaded_contact_samples+=1
						maximum_loaded_depth=maxf(maximum_loaded_depth,maxf(0,-float(supported.signed_gap)))
						var floor_key:=str(supported.floor.rid)+":"+str(supported.floor.shape)
						if not loaded_floor_keys.has(floor_key):
							loaded_floor_keys.append(floor_key)
							loaded_contact_examples.append(supported)
						if not floor_negatives and supported.floor.collider.has_meta("bank_terminal_return"):
							floor_negatives=_loaded_capsule_negatives(game,actual_body.global_transform,supported.floor)
				capsule_clear=capsule_clear and sample_clear
				if not sample_clear and capsule_failures.is_empty():
					var body: CollisionShape3D=game.skater.get_node("BodyCollision")
					var capsule: CapsuleShape3D=body.shape
					var native_queries: Array[Dictionary]=[]
					for margin: float in [0.001,0.0]:
						var query:=PhysicsShapeQueryParameters3D.new()
						query.shape=body.shape
						query.transform=body.global_transform
						query.collision_mask=1
						query.exclude=[game.skater.get_rid()]
						query.margin=margin
						var space: PhysicsDirectSpaceState3D=game.world.get_world_3d().direct_space_state
						var hits: Array[Dictionary]=[]
						for hit: Dictionary in space.intersect_shape(query,8):
							hits.append({"collider":str(hit.collider.get_path()),"rid":hit.rid,"shape":hit.shape})
						var rest:=space.get_rest_info(query)
						var signed_gap:=INF
						if not rest.is_empty():
							var normal: Vector3=rest.normal
							var frame:=body.global_transform
							signed_gap=(frame.origin-Vector3(rest.point)).dot(normal) \
								-maxf(0,capsule.height*.5-capsule.radius)*absf(frame.basis.y.dot(normal)) \
								-capsule.radius*(frame.basis.transposed()*normal).length()
						native_queries.append({"margin":margin,"hits":hits,"rest":rest,"signed_capsule_gap":signed_gap,
							"contact_pairs":space.collide_shape(query,32)})
					capsule_failures.append({"physics":Engine.get_physics_frames(),"at":at,"airborne":game.skater.airborne,
						"is_on_floor":game.skater.is_on_floor(),"body":body.global_transform,"radius":capsule.radius,
						"height":capsule.height,"native_safe_margin":game.skater.safe_margin,"queries":native_queries})
			if actual_air and not native_landing and game.skater.is_on_floor() and not game.skater.airborne:
				var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters3D.create(at+Vector3.UP*.15,at-Vector3.UP*.18,1))
				if not hit.is_empty() and absf(Vector3(hit.position).y-at.y)<.18:
					native_landing=true
					events.append({"event":"native_landing","physics":Engine.get_physics_frames(),"at":at,
						"collider":str(hit.collider.get_path()),"point":hit.position})
			if escaped or e.bails>0 or (released and tick>300):break
		Driver._release()
		check.call(charging and released and charge_speed>=14.9 and actual_air and native_landing and not escaped
			and maximum_x<84.43 and capsule_clear and e.bails==0 and e.recoveries==0 and e.captures.is_empty()
			and air_model.checked>10 and air_model.clear and air_model.shoe_clear and air_model.offset_clear
			and air_model.capsule_clear
			and reset_air_clear and air_model.landing_clear
			and air_model.forecast_proven_or_zero and air_model.forecast_clear and air_model.forecast_controls_clear
			and (not air_model.foreign_ran or air_model.foreign_rejected)
			and (not air_model.forecast_miss_ran or air_model.forecast_miss_rejected)
			and (not air_model.forecast_foreign_ran or air_model.forecast_foreign_rejected)
			and (gate!=79.4 or (air_model.forecast_frames>0 and air_model.forecast_foreign_ran and air_model.forecast_miss_ran and air_model.forecast_controls_ran))
			and (gate!=79.4 or (air_model.foreign_ran and floor_negatives))
			and e.entries.size()==1 and e.entries[0].id=="ollie" and e.camera_clear,
			"November bank: maximum-speed charged uphill pop stays natively contained with clear body/chase and real landing at gate"+str(gate))
		print("NOVEMBER_BANK_TOP_MISS physics_start=",physics_start," gate=",gate," events=",events,
			" escaped=",escaped," maximum_x=",maximum_x," peak=",peak," native_landing=",native_landing,
			" capsule=",capsule_clear," camera=",e.camera_clear," bails=",e.bails," recoveries=",e.recoveries," entries=",e.entries,
			" actual_air_physics=",air_model.checked," air_model_clear=",air_model.clear," air_capsule_clear=",air_model.capsule_clear," shoe_clear=",air_model.shoe_clear,
			" reset_air_clear=",reset_air_clear," landing_air_clear=",air_model.landing_clear,
			" owner_only_physics=",air_model.owner_only_frames," forecast_proven_or_zero=",air_model.forecast_proven_or_zero,
			" forecast_frames=",air_model.forecast_frames," forecast_clear=",air_model.forecast_clear,
			" forecast_max_queries=",air_model.maximum_forecast_queries," forecast_samples=",air_model.forecast_samples,
			" forecast_controls_ran=",air_model.forecast_controls_ran," forecast_controls_clear=",air_model.forecast_controls_clear,
			" forecast_controls=",air_model.forecast_controls,
			" forecast_owner_queries=",air_model.owner_query_samples," forecast_query_distribution=",air_model.forecast_query_distribution(),
			" independent_component_queries=",air_model.independent_component_queries," independent_pose_queries=",air_model.independent_pose_queries,
			" independent_face_rays=",air_model.independent_face_rays,
			" forecast_foreign_ran=",air_model.forecast_foreign_ran," forecast_foreign_rejected=",air_model.forecast_foreign_rejected,
			" forecast_miss_ran=",air_model.forecast_miss_ran," forecast_miss_rejected=",air_model.forecast_miss_rejected,
			" foreign_owner_ran=",air_model.foreign_ran," foreign_owner_rejected=",air_model.foreign_rejected,
			" loaded_contact_samples=",loaded_contact_samples," maximum_loaded_depth=",maximum_loaded_depth,
			" wrong_floor_wall_deep_negatives=",floor_negatives,
			" admitted_native_floor_examples=",loaded_contact_examples,
			" residual_physics=",air_model.residual_frames," maximum_offset=",air_model.maximum_offset," maximum_step=",air_model.maximum_step,
			" model_failures=",air_model.failures," capsule_failures=",capsule_failures)
		air_model.free()
		Driver._disconnect(game,e)


static func _loaded_capsule_contact(game: Node,frame: Transform3D,expected_floor: Dictionary={}) -> Dictionary:
	# A grounded capsule can be in the native solver's intended floor contact;
	# its proxy is not an unloaded volume. Authenticate every actual pair on
	# the same fresh finite floor face. Never exclude its RID (the bank wall
	# and its floor deliberately share one body and native shape).
	var rider: CharacterBody3D=game.skater
	if rider.airborne or not rider.is_on_floor() or not rider.global_position.is_finite() \
			or not rider.get_floor_normal().is_finite():return {"clear":false}
	var body: CollisionShape3D=rider.get_node("BodyCollision")
	var capsule: CapsuleShape3D=body.shape
	if not frame.origin.is_finite() or not frame.basis.is_finite() or frame.basis.determinant()<=0 \
			or not is_finite(capsule.radius) or not is_finite(capsule.height) or capsule.radius<=0 \
			or capsule.height<capsule.radius*2 or not is_finite(rider.safe_margin) or rider.safe_margin<=0:
		return {"clear":false}
	var space:=rider.get_world_3d().direct_space_state
	var ray:=PhysicsRayQueryParameters3D.create(rider.global_position+Vector3.UP*.15,
		rider.global_position-Vector3.UP*.18,1,[rider.get_rid()])
	var floor:=space.intersect_ray(ray)
	if floor.is_empty():return {"clear":false}
	if not Vector3(floor.position).is_finite() or not Vector3(floor.normal).is_finite():return {"clear":false}
	if not expected_floor.is_empty() and (floor.rid!=expected_floor.rid or int(floor.shape)!=int(expected_floor.shape)):
		return {"clear":false}
	var normal: Vector3=floor.normal
	if normal.length_squared()<0.99:return {"clear":false}
	normal=normal.normalized()
	if normal.dot(Vector3.UP)<cos(rider.floor_max_angle) or normal.dot(rider.get_floor_normal())<0.999:
		return {"clear":false}
	var query_height: float=game.world.get_ground_height(floor.position)
	if not is_finite(query_height) or absf(query_height-float(floor.position.y))>.002:return {"clear":false}
	var signed_gap: float=(frame.origin-Vector3(floor.position)).dot(normal) \
		-maxf(0,capsule.height*.5-capsule.radius)*absf(frame.basis.y.dot(normal)) \
		-capsule.radius*(frame.basis.transposed()*normal).length()
	# This is the existing engine safe_margin, not an observed penetration or
	# a new allowance. The receipt separately records actual maximum depth.
	if not is_finite(signed_gap) or absf(signed_gap)>rider.safe_margin:return {"clear":false}
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=capsule
	query.transform=frame
	query.collision_mask=1
	query.exclude=[rider.get_rid()]
	query.margin=.001
	var hits:=space.intersect_shape(query,16)
	if hits.is_empty():return {"clear":true,"loaded":false}
	if hits.size()>=16:return {"clear":false}
	for hit: Dictionary in hits:
		if hit.rid!=floor.rid or int(hit.shape)!=int(floor.shape):return {"clear":false}
	var pairs:=space.collide_shape(query,32)
	# Conservatively require fewer than32 returned vectors, below both the
	# requested pair capacity and its two-vectors-per-pair representation.
	if pairs.is_empty() or pairs.size()%2!=0 or pairs.size()>=32:return {"clear":false}
	for index: int in range(0,pairs.size(),2):
		if not Vector3(pairs[index]).is_finite() or not Vector3(pairs[index+1]).is_finite():return {"clear":false}
		var separation: Vector3=pairs[index+1]-pairs[index]
		# Native margin contacts are ordered query-point then environment-point.
		# A vertical wall in this SAME shape must fail the floor-normal test.
		if not separation.is_finite() or not is_finite(separation.length_squared()) \
				or separation.length_squared()<0.000000000001 or separation.normalized().dot(normal)<0.999 \
				or absf((Vector3(pairs[index+1])-Vector3(floor.position)).dot(normal))>.002:
			return {"clear":false}
	# Retain the existing lifted standing-volume check without its flat-only
	# centre-ray height shortcut. The actual capsule and actor never move.
	query.transform.origin+=Vector3.UP*rider.safe_margin
	if not space.intersect_shape(query,1).is_empty():return {"clear":false}
	return {"clear":true,"loaded":true,"signed_gap":signed_gap,"floor":floor,"contact_pairs":pairs,
		"body":frame,"radius":capsule.radius,"height":capsule.height,"native_safe_margin":rider.safe_margin,
		"actual_floor_normal":rider.get_floor_normal(),"floor_path":str(floor.collider.get_path())}


static func _loaded_capsule_negatives(game: Node,actual: Transform3D,floor: Dictionary) -> bool:
	var rider: CharacterBody3D=game.skater
	var capsule: CapsuleShape3D=rider.get_node("BodyCollision").shape
	var foreign: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(Vector3(66,2.2,73.5),Vector3(66,1.8,73.5),1,[rider.get_rid()]))
	if foreign.is_empty() or foreign.rid==floor.rid:return false
	var wrong_floor: bool=not _loaded_capsule_contact(game,actual,foreign).clear
	var deep:=actual
	deep.origin-=Vector3.UP*rider.safe_margin*2.0
	var deep_rejected: bool=not _loaded_capsule_contact(game,deep).clear
	var invalid:=actual
	invalid.origin.x=NAN
	var nonfinite_rejected: bool=not _loaded_capsule_contact(game,invalid).clear
	# Slide only this diagnostic volume along the SAME supporting floor plane
	# until it also meets the real vertical backing. It must still fail even
	# though both contacts share the floor's exact native body/shape identity.
	var wall:=actual
	var shift_x: float=84.7-capsule.radius+.02-wall.origin.x
	wall.origin+=Vector3(shift_x,-float(floor.normal.x)/float(floor.normal.y)*shift_x,0)
	var wall_rejected: bool=not _loaded_capsule_contact(game,wall).clear
	print("NOVEMBER_LOADED_CAPSULE_NEGATIVES physics=",Engine.get_physics_frames(),"wrong_floor=",wrong_floor,
		" deep=",deep_rejected," nonfinite=",nonfinite_rejected," same_owner_vertical_wall=",wall_rejected," actual_gap_floor=",floor)
	return wrong_floor and deep_rejected and wall_rejected and nonfinite_rejected


static func _lateral_bank_crossing(tree: SceneTree,game: Node,direction: float,check: Callable,observer: Callable) -> void:
	var start_z:=72.2 if direction>0 else 77.1
	var finish_z:=77.1 if direction>0 else 72.2
	var x:=82.0
	var expected_y:=2.0+(x-80.8)*2.0/3.9
	await Driver._reset(tree,game,Vector3(x,expected_y+.08,start_z),PI if direction>0 else 0.0)
	await Driver._frames(tree,40)
	var e:=Driver._evidence(game,"east_bank_panel_crossing_"+str(direction))
	Driver._connect(game,e)
	var physics_start:=Engine.get_physics_frames()
	var supported:=true
	var clear:=true
	var reached:=false
	for tick: int in 300:
		Driver._steer_to(game,Vector3(x,expected_y,finish_z),false)
		Driver._speed_input(game,3.2)
		await Driver._step(tree,game,e,"native_lateral_panel_crossing",observer)
		var at: Vector3=game.skater.global_position
		var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			at+Vector3.UP*.15,at-Vector3.UP*.18,1))
		supported=supported and game.skater.is_on_floor() and not game.skater.airborne and absf(at.x-x)<.08 \
			and absf(at.y-expected_y)<.18 and not hit.is_empty() and hit.collider.has_meta("bank_terminal_return")
		if tick%8==0:clear=clear and EdgeTrial._capsule_clear(game.skater)
		if (at.z-finish_z)*direction>=-.15:
			reached=true
			break
		if e.bails>0:break
	Driver._release()
	check.call(reached and supported and clear and e.bails==0 and e.recoveries==0 and e.entries.is_empty() and e.camera_clear,
		"November bank: native sideways rolling crosses every retained panel seam in direction"+str(direction))
	print("NOVEMBER_BANK_PANEL_CROSSING start_physics=",physics_start," end_physics=",Engine.get_physics_frames(),
		" direction=",direction," supported=",supported," capsule=",clear," camera=",e.camera_clear," at=",game.skater.global_position)
	Driver._disconnect(game,e)


static func _uphill_rollback(tree: SceneTree,game: Node,z: float,ceiling: float,check: Callable,observer: Callable) -> void:
	await Driver._reset(tree,game,Vector3(66 if ceiling>=8.0 else 76,2.08,z),-PI*.5)
	await Driver._frames(tree,40)
	var e:=Driver._evidence(game,"east_bank_rollback_"+str(ceiling))
	Driver._connect(game,e)
	var result: Dictionary=await _roll_bank_phase(tree,game,e,z,ceiling,observer)
	var reached_speed: bool=ceiling<8.0 or absf(float(result.entry_speed))>=ceiling-0.5
	# High-speed containment may touch the retained wall; its capsule centre
	# remains west of X84.43 (wallX84.7 minus native radius, with query skin).
	var bounded: bool=result.peak.x<(84.43 if ceiling>=8.0 else 84.4)
	check.call(result.released and result.reverse and result.returned and result.peak.x>81.1 and bounded and result.peak.y>2.2
		and reached_speed
		and result.supported and e.bails==0 and e.recoveries==0 and e.entries.is_empty() and e.captures.is_empty() and e.camera_clear,
		"November bank: native climb/stop/fakie plus mapped Push fully clears the toe at approach cap"+str(ceiling))
	Driver._disconnect(game,e)


static func _roll_bank_phase(tree: SceneTree,game: Node,e: Dictionary,z: float,ceiling: float,observer: Callable) -> Dictionary:
	var released:=false
	var returned:=false
	var peak:=Vector3.ZERO
	var entry_speed:=0.0
	var reverse:=false
	var supported:=true
	var events: Array[Dictionary]=[]
	var physics_start:=Engine.get_physics_frames()
	var wall_contact:=false
	for tick: int in 900:
		if not released:
			Driver._steer_to(game,Vector3(84.0,2,z),false)
			Driver._speed_input(game,ceiling)
			if game.skater.global_position.x>=80.5:
				Driver._release()
				released=true
				entry_speed=game.skater.speed
				events.append({"event":"input_release","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":game.skater.global_position,"speed":entry_speed})
		# Native grade gravity must establish reversal first. Then ordinary
		# fakie pushing supplies a useful re-entry instead of slowly coasting
		# with the upright capsule/loaded wheels still straddling the toe.
		if reverse:Driver._speed_input(game,3.2)
		await Driver._step(tree,game,e,"real_uphill_and_rollback",observer)
		var point: Vector3=game.skater.global_position
		if point.y>peak.y:peak=point
		for slide: int in game.skater.get_slide_collision_count():
			var collision: KinematicCollision3D=game.skater.get_slide_collision(slide)
			for contact_index: int in collision.get_collision_count():
				var collider: Object=collision.get_collider(contact_index)
				if not wall_contact and is_instance_valid(collider) and collider.has_meta("bank_terminal_return") and collision.get_normal(contact_index).x< -0.98:
					wall_contact=true
					events.append({"event":"native_backing_contact","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"speed":game.skater.speed})
		var height: float=game.world.get_support_height(point,0.3)
		supported=supported and is_finite(height) and absf(point.y-height)<0.18 and game.skater.is_on_floor() and not game.skater.airborne
		if released and game.skater.speed< -0.5 and not reverse:
			reverse=true
			events.append({"event":"native_rollback_then_fakie_push","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"speed":game.skater.speed})
		if reverse and point.x<80.3:
			returned=true
			events.append({"event":"flat_reentry","tick":e.ticks,"physics":Engine.get_physics_frames(),"at":point,"speed":game.skater.speed})
			break
		if e.bails>0 or e.recoveries>0:break
	Driver._release()
	print("NOVEMBER_BANK_RETURN physics_start=",physics_start," cap=",ceiling," entry_speed=",entry_speed," peak=",peak," events=",events,
		" supported=",supported," camera=",e.camera_clear," bails=",e.bails)
	return {"released":released,"reverse":reverse,"returned":returned,"supported":supported,"peak":peak,"entry_speed":entry_speed,"wall_contact":wall_contact}
