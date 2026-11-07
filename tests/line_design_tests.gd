extends RefCounted
## November geometry admission: fixed native witnesses, directed bank input,
## ordinary seating captures and an unbroken two-bearing/manual relay.
const Routes=preload("res://tests/world_routes_tests.gd")
const Density=preload("res://tests/full_level_density_tests.gd")
const Driver=preload("res://tests/pt24_flagship_runs_tests.gd")
const BoundaryFaces=preload("res://tests/pt24_boundary_tests.gd")
const EdgeTrial=preload("res://tests/edge_grind_integration_tests.gd")
const AirController=preload("res://game/player/skater.gd")
const ReturnCatalog=preload("res://game/tricks/trick_catalog.gd")
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
	if seats:await run_wall_return(tree,game,check,observer)
	Driver._release()
	game.skater.spawn_position=old_spawn
	game.start_mode(old_mode)
	await Driver._frames(tree,3)


static func run_relay(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable(),continuation: Callable=Callable(),recorder: Node=null) -> void:
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
	if recorder!=null:
		e.id="east_quay_wall_return"
		recorder.game=game
		recorder.evidence=e
		recorder.exit_witness=exit_witness
		recorder.process_physics_priority=100
		game.add_child(recorder)
		recorder.connect_native_score()
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
	if recorder!=null:recorder.exit_witness=null
	exit_witness.free()
	if continuation.is_valid():
		var prefix_complete: bool=first and linked and second and e.captures==[FIRST,SECOND] and e.manual_ticks>=20 \
			and e.seat_fit and second_pop_from_bearing and paving_landing and exit_model_clear
		await continuation.call(e,prefix_complete)
		return
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


static func run_wall_return(tree: SceneTree,game: Node,check: Callable,observer: Callable=Callable()) -> void:
	var wall: StaticBody3D
	for candidate: StaticBody3D in game.world.find_children("*","StaticBody3D",true,false):
		if candidate.get_meta("boundary_family","")=="QuayLandwardBoundary":
			var points: PackedVector3Array=candidate.get_meta("boundary_points")
			if points[0].x>=14.9:wall=candidate
	check.call(wall!=null,"continuous return: actual existing east landward masonry is available")
	if wall==null:return
	var recorder:=QuayReturnWitness.new()
	recorder.wall=wall
	recorder.fit=_native_seat_fit
	recorder.ground_contact=_loaded_capsule_contact
	var continuation: Callable=func(e: Dictionary,prefix_complete: bool) -> void:
		await _complete_wall_return(tree,game,check,observer,recorder,e,prefix_complete)
	await run_relay(tree,game,check,observer,continuation,recorder)
	recorder.free()


static func _complete_wall_return(tree: SceneTree,game: Node,check: Callable,observer: Callable,recorder: Node,e: Dictionary,prefix_complete: bool) -> void:
	check.call(prefix_complete,"continuous return: existing native two-seat prefix reaches actual Manual paving runout")
	if prefix_complete:
		await _connected_wall_return(tree,game,e,recorder,check,observer)
		Driver._release()
		await _finish_wall_return_bank(tree,game,e,observer)
		recorder.observe_bank()
		check.call(recorder.score_receipts_clear and recorder.score_banks.size()==e.banks and recorder.score_banks.size()>0 \
			and recorder.calculated_total==game.score.total_score and game.score.get_combo_value()==0 \
			and e.hold_valid and e.bails==0 and e.recoveries==0 and e.camera_clear and e.ground_supported,
			"continuous return: every actual score bank independently matches native catalog/repetition/hold events")
		if recorder.wall_load_controls_ran:check.call(recorder.wall_load_controls_clear,"continuous return: loaded-wall capsule proof rejects wrong owner/shape/face/deep/nonfinite neighbours")
		check.call(recorder.model_clear and recorder.capsule_clear and recorder.shoe_clear and recorder.skin_clear and recorder.wall_clear,
			"continuous return: every actual physics state retains native board/capsule/shoe and finite wall proof")
	var packet={"kind":"existing-geometry local spatial return; not whole-map acceptance","initial_resets":1,
		"events":recorder.events,"prefix_events":e.event_ticks,"frames":recorder.frames,
		"model_clear":recorder.model_clear,"capsule_clear":recorder.capsule_clear,"shoe_zero_clear":recorder.shoe_clear,
		"wall_skin_clear":recorder.skin_clear,"wall_clear":recorder.wall_clear,"failures":recorder.failures,
		"path_m":recorder.path_m,"camera_clear_sampled_driver":e.camera_clear,"captures":e.captures,
		"entries":e.entries,"bails":e.bails,"recoveries":e.recoveries,"score":game.score.total_score,
		"score_banks":recorder.score_banks,"one_combo":e.banks==1,"independent_score_clear":recorder.score_receipts_clear,
		"loaded_wall_controls_ran":recorder.wall_load_controls_ran,"loaded_wall_controls_clear":recorder.wall_load_controls_clear,
		"loaded_wall_controls":recorder.wall_load_controls}
	print("NOVEMBER_WALL_RETURN_TRACE ",JSON.stringify(packet))
	print("NOVEMBER_WALL_RETURN_SUMMARY frames=",recorder.frames.size()," captures=",e.captures," failures=",recorder.failures,
		" banks=",recorder.score_banks," one_combo=",e.banks==1)
	Driver._report(e,game)
	Driver._disconnect(game,e)
	Driver._release()

static func _wall_return_event(game: Node,recorder: Node,id: String) -> void:
	recorder.events.append({"event":id,"physics":Engine.get_physics_frames(),"position":game.skater.global_position,
		"velocity":game.skater.velocity,"speed":game.skater.speed,"yaw":game.skater.rotation.y,
		"path_m":recorder.path_m,"launch":game.skater._launch_id,
		"trick_direction":game.skater._trick_input.direction(),"direction_edge_age":game.skater._trick_input.direction_age(),
		"actual_bearing_id":String(game.skater._grind.line.id) if game.skater.grinding else ""})

static func _connected_wall_return(tree: SceneTree,game: Node,e: Dictionary,recorder: Node,check: Callable,observer: Callable) -> void:
	_wall_return_event(game,recorder,"second_seat_paving_manual")
	var heading:=Vector3(-.94,0,-.342).normalized()
	var turn_completed:=false
	var manual_turn_ticks:=0
	for tick: int in 120:
		Driver._manual_to(game,game.skater.global_position+heading*20)
		await Driver._step(tree,game,e,"manual_north_quay_turn",observer)
		if game.skater.manual_active:manual_turn_ticks+=1
		var desired:=atan2(-heading.x,-heading.z)
		if absf(angle_difference(game.skater.rotation.y,desired))<.08:
			turn_completed=true
			break
		if e.bails>0 or not game.skater.manual_active:break
	_wall_return_event(game,recorder,"manual_turn_finished")
	check.call(turn_completed and manual_turn_ticks>=20 and e.bails==0,
		"continuous return: actual second-seat Manual carves through mapped A/D to the wall approach")
	if not turn_completed:return
	# The Manual has no acceleration channel. End it honestly and push the
	# supported approach; then coast with no Brake, leaving raw fore/aft quiet
	# before charge/release. Holding Ollie itself retains ordinary pop acceleration.
	Input.action_release("manual")
	Driver._axis("push","brake",0)
	var capped:=false
	var quiet_ticks:=0
	var charged:=false
	var popped:=false
	for tick: int in 300:
		Driver._steer_to(game,game.skater.global_position+heading*20,false)
		Input.action_release("brake")
		if not capped and absf(game.skater.speed)<7.2:Input.action_press("push")
		else:
			capped=true
			Input.action_release("push")
			quiet_ticks+=1
		if game.skater.global_position.z<=57.2 and not charged and quiet_ticks>=13:
			charged=true
			Input.action_press("ollie")
			_wall_return_event(game,recorder,"wall_plain_charge_quiet")
		if game.skater.global_position.z<=56.6 and charged:
			Input.action_release("ollie")
			Input.action_release("push")
			Input.action_press("grind")
			Driver._axis("steer_left","steer_right",0)
			popped=true
			_wall_return_event(game,recorder,"wall_plain_pop")
		await Driver._step(tree,game,e,"landward_quiet_approach",observer)
		if popped:break
		if e.bails>0 or game.skater.global_position.z<55.7:break
	check.call(popped and quiet_ticks>=13,"continuous return: mapped wall pop has >=13 quiet raw fore/aft ticks and no cap Brake")
	if not popped:return
	for tick: int in 100:
		await Driver._step(tree,game,e,"native_wall_entry",observer)
		if game.skater.wallriding or e.bails>0 or (not game.skater.airborne and game.skater.is_on_floor()):break
	var entered: bool=game.skater.wallriding and game.skater._wall.wall_id==str(recorder.wall.get_path())
	var wall_ticks:=0
	var wall_start: Vector3=game.skater.global_position
	var wall_finish:=wall_start
	if entered:
		_wall_return_event(game,recorder,"native_landward_wall_entry")
		for tick: int in 30:
			await Driver._step(tree,game,e,"landward_wallride",observer)
			if not game.skater.wallriding or e.bails>0:break
			wall_ticks+=1
		wall_finish=game.skater.global_position
	var wallie:=false
	if entered and game.skater.wallriding and wall_ticks>=30:
		Input.action_press("ollie")
		await Driver._steps(tree,game,e,2,"landward_wallie_charge",observer)
		var supported_release: bool=game.skater.wallriding and game.skater._wall.wall_id==str(recorder.wall.get_path())
		Input.action_release("ollie")
		await Driver._step(tree,game,e,"landward_wallie_release",observer)
		wallie=supported_release and not game.skater.wallriding and game.skater._launch_id=="wallie"
		_wall_return_event(game,recorder,"earned_landward_wallie")
		Input.action_release("grind")
		await Driver._landing_manual(tree,game,e,150,"wallie_manual_return",observer)
	var wall_m:=Vector2(wall_finish.x-wall_start.x,wall_finish.z-wall_start.z).length()
	check.call(entered and wall_ticks>=30 and wall_m>=3 and wallie,
		"continuous return: connected prefix earns native30-tick/3m wallride and mapped Wallie")
	check.call(wallie and game.skater.manual_active and e.bails==0 and e.recoveries==0 and e.camera_clear,
		"continuous return: earned Wallie lands a real supported Manual without reset or recovery")
	print("CONTINUOUS_WALL ticks=",wall_ticks," metres=",wall_m," quiet_ticks=",quiet_ticks,
		" charge=",charged," position=",game.skater.global_position," speed=",game.skater.speed)
	if not game.skater.manual_active:return
	_wall_return_event(game,recorder,"wallie_manual_landing")
	var first_line: RefCounted
	for line: RefCounted in game.world.get_grind_lines():
		if String(line.id)==FIRST:first_line=line
	if first_line==null:return
	# Approach from the actual north shoulder, reverse along its finite tangent.
	# This is a return catch inside a wall sequence, not a second line by reversal.
	var first_end: Vector3=first_line.points[-1]
	var direction: Vector3=(first_line.points[0]-first_end).normalized()
	var outside: Vector3=first_line.contact_edge_outward
	var join: Vector3=first_end-direction*2.0+outside*1.5
	var aim: Vector3=first_end+direction*4.0+outside*.35
	var charged_return:=false
	var joined:=false
	for tick: int in 240:
		var remaining: float=(first_end-game.skater.global_position).dot(direction)
		if not joined and game.skater.global_position.distance_to(join)<.65:
			joined=true
			_wall_return_event(game,recorder,"return_actual_north_shoulder_join")
		Driver._manual_to(game,aim if joined else join)
		if joined and remaining<=2.5 and not charged_return:
			charged_return=true
			Input.action_press("ollie")
			_wall_return_event(game,recorder,"return_first_bearing_charge")
		if charged_return and remaining<=1.1:break
		await Driver._step(tree,game,e,"manual_first_bearing_return",observer)
		if not game.skater.manual_active or e.bails>0:break
	var release_supported: bool=game.skater.manual_active and charged_return
	if release_supported:
		Input.action_release("ollie")
		Input.action_release("manual")
		Driver._axis("push","brake",0)
		Driver._axis("steer_left","steer_right",0)
		Driver._axis("spin_left","spin_right",0)
		Input.action_press("grind")
		_wall_return_event(game,recorder,"return_first_bearing_pop")
		for tick: int in 150:
			await Driver._step(tree,game,e,"return_first_bearing_catch",observer)
			if game.skater.grinding or e.bails>0:break
	var recaught: bool=game.skater.grinding and String(game.skater._grind.line.id)==FIRST \
		and _native_seat_fit(game)
	var finite_return_exit:=false
	if recaught:
		_wall_return_event(game,recorder,"first_bearing_native_return_catch")
		var capture_physics: int=Engine.get_physics_frames()
		for tick: int in 120:
			if not game.skater.grinding or Engine.get_physics_frames()-capture_physics>=30:break
			await Driver._step(tree,game,e,"return_finite_first_bearing",observer)
		var return_bearing_ride_frames: int=Engine.get_physics_frames()-capture_physics
		_wall_return_event(game,recorder,"returned_first_bearing_payoff_complete")
		recorder.events[-1]["actual_bearing_ride_steps_before_charge"]=return_bearing_ride_frames
		var returning: bool=game.skater.grinding and String(game.skater._grind.line.id)==FIRST and return_bearing_ride_frames>=30
		if returning:
			# On this westbound bearing, mapped D is the actual northward
			# sideways pop. It clears the seat into paving without consuming
			# its entire length at low speed; native physics supplies the exit.
			Driver._axis("steer_left","steer_right",1.0)
			Input.action_press("ollie")
			await Driver._steps(tree,game,e,2,"return_first_exit_charge",observer)
			var release_witness:=ExitModelWitness.new()
			release_witness.rider=game.skater
			release_witness.process_physics_priority=100
			game.add_child(release_witness)
			recorder.exit_witness=release_witness
			release_witness.arm("return_first_release",_native_seat_fit(game))
			_wall_return_event(game,recorder,"returned_first_bearing_release")
			Input.action_release("ollie")
			await Driver._step(tree,game,e,"return_first_exit",observer)
			Driver._axis("steer_left","steer_right",0)
			Input.action_release("grind")
			await Driver._landing_manual(tree,game,e,150,"return_first_paving_landing",observer)
			var point: Vector3=game.skater.global_position
			var hit: Dictionary=game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*.12,point-Vector3.UP*.18,1))
			finite_return_exit=game.skater.manual_active and not hit.is_empty() and hit.collider==game.world._outdoors.get_node("ClydeNorthQuay") \
				and return_bearing_ride_frames>=30 and point.z<first_line.points[0].z-.55 and absf(point.y-2.0)<.18 and release_witness.clear and release_witness.completed.has("return_first_release")
			_wall_return_event(game,recorder,"returned_first_bearing_paving_manual")
			recorder.exit_witness=null
			release_witness.free()
	check.call(release_supported and recaught and e.captures==[FIRST,SECOND,FIRST] and e.bails==0 \
		and e.recoveries==0 and e.camera_clear,
		"continuous return: two seats→manual turn→wallride/Wallie/manual→finite named first-bearing catch uses one reset")
	check.call(finite_return_exit,"continuous return: >=30 realphysics-step first-bearing ride and mapped outward exit land native north-paving Manual with authenticated release")

static func _finish_wall_return_bank(tree: SceneTree,game: Node,e: Dictionary,observer: Callable) -> void:
	# Existing first-bank helper's old count cannot terminate a later segment.
	var before: int=e.banks
	Driver._release()
	Input.action_press("brake")
	for tick: int in 240:
		await Driver._step(tree,game,e,"final_new_bank",observer)
		if e.banks>before and not game.skater.airborne and not game.skater.grinding:break
	await Driver._steps(tree,game,e,24,"final_new_bank_observation",observer)
	Driver._release()

class QuayReturnWitness extends Node:
	var fit: Callable
	var ground_contact: Callable
	var events: Array[Dictionary]=[]
	var game: Node
	var evidence: Dictionary
	var wall: StaticBody3D
	var exit_witness: Node
	var frames: Array[Dictionary]=[]
	var failures: Array[Dictionary]=[]
	var model_clear:=true
	var capsule_clear:=true
	var skin_clear:=true
	var shoe_clear:=true
	var wall_load_controls_ran:=false
	var wall_load_controls_clear:=true
	var wall_load_controls: Array[Dictionary]=[]
	var wall_clear:=true
	var path_m:=0.0
	var previous:=Vector3.INF
	var score_receipts_clear:=true
	var score_banks: Array[Dictionary]=[]
	var last_score:=0
	var calculated_total:=0
	var segment_base:=0
	var segment_count:=0
	var segment_entries: Array[Dictionary]=[]
	var repetitions: Dictionary={}
	func connect_native_score() -> void:
		last_score=game.score.total_score
		game.skater.trick_performed.connect(_on_native_trick)
		game.skater.hold_points_awarded.connect(_on_native_hold)
	func _on_native_trick(label: String,points: int) -> void:
		observe_bank()
		var id: String=game.skater.last_trick_id
		var definition: Dictionary=ReturnCatalog.definition(id)
		var valid: bool=not definition.is_empty() and String(definition.get("display_name",""))==label \
			and int(definition.get("base_points",0))==points
		score_receipts_clear=score_receipts_clear and valid
		var key: String=ReturnCatalog.repetition_id(id)
		var repeats: int=int(repetitions.get(key,0))
		var award:=points
		if String(definition.get("family",""))!="spin":
			award=ReturnCatalog.repeated_points(points,repeats)
			repetitions[key]=repeats+1
			segment_count+=1
		segment_base+=award
		segment_entries.append({"physics":Engine.get_physics_frames(),"id":id,"points":points,"repeat_before":repeats,"award":award})
	func _on_native_hold(points: int) -> void:
		observe_bank()
		score_receipts_clear=score_receipts_clear and points>0 and points%25==0 and game.skater.grinding
		segment_base+=points
		segment_entries.append({"physics":Engine.get_physics_frames(),"hold":points})
	func observe_bank() -> void:
		var actual: int=game.score.total_score
		if actual==last_score:return
		var delta:=actual-last_score
		var expected: int=segment_base*mini(segment_count,100)
		var valid: bool=delta==expected and expected>0
		score_receipts_clear=score_receipts_clear and valid
		calculated_total+=expected
		score_banks.append({"physics":Engine.get_physics_frames(),"actual_delta":delta,"expected":expected,
			"base":segment_base,"count":segment_count,"entries":segment_entries.duplicate(true),"valid":valid})
		segment_base=0
		segment_count=0
		segment_entries.clear()
		last_score=actual
	func _physics_process(_delta: float) -> void:
		observe_bank()
		var rider: CharacterBody3D=game.skater
		var at: Vector3=rider.global_position
		if previous.is_finite():path_m+=at.distance_to(previous)
		previous=at
		var frame: Transform3D=rider._board_visual.global_transform
		var mode:="ground"
		var model: bool=rider._manual_model_frame_clear(frame)
		var capsule: bool
		var raw_capsule: Dictionary={}
		var loaded_wall: Dictionary={}
		var loaded_ground: Dictionary={}
		var skin:=true
		var shoes:=true
		var wall_context:=false
		var raw_zero: Dictionary={}
		var raw_skin: Dictionary={}
		var native_wall:=true
		var wall_gap:=INF
		if rider.grinding:
			mode="named_bearing"
			model=bool(fit.call(game))
		elif exit_witness!=null and exit_witness.armed and at.distance_to(exit_witness.loaded_origin)<.00001:
			mode="authenticated_stationary_bearing_release"
			model=exit_witness.retained_clear(frame,rider.get_node("BodyCollision").global_transform,rider._visual.global_transform)
		elif rider.wallriding:mode="wallride"
		elif rider.airborne:mode="air"
		elif rider.manual_active:mode="manual"
		# The universal raw1mm query is always the first independent capsule
		# observation. Loaded support only classifies an ACTUAL margin hit.
		capsule=EdgeTrial._capsule_clear(rider)
		var raw_capsule_clear: bool=capsule
		if not raw_capsule_clear:
			raw_capsule=_raw_capsule(rider)
			if rider.wallriding:
				loaded_wall=_loaded_wall_capsule(rider,rider.get_node("BodyCollision").global_transform)
				capsule=bool(loaded_wall.get("clear",false))
				if capsule and not wall_load_controls_ran:_loaded_wall_negatives(rider,loaded_wall)
			elif rider.is_on_floor() and not rider.airborne and not rider.grinding:
				loaded_ground=ground_contact.call(game,rider.get_node("BodyCollision").global_transform)
				capsule=bool(loaded_ground.get("clear",false))
		if mode in ["air","wallride"]:
			raw_zero=_raw_pose_hits(rider,0.0)
			raw_skin=_raw_pose_hits(rider,.00799)
			shoes=bool(raw_zero.shoes_clear) and not bool(raw_zero.saturated)
			#7.99mm is the earned near-wall proposal skin, not a generic
			#airborne gap above a floor just before its native landing step.
			wall_context=rider.wallriding or not rider._obstacle_air_wall.is_empty() \
				or not rider._obstacle_air_forecast.is_empty() or rider._wall.air_presentation_active
			if wall_context:skin=rider._obstacle_air_clear(Vector3.ZERO)
		if rider.wallriding:
			var point: Vector3=rider._wall.contact_point
			var normal: Vector3=rider._wall.normal
			var hit: Dictionary=rider.get_world_3d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters3D.create(point+normal*.10,point-normal*.10,1,[rider.get_rid()]))
			native_wall=rider._wall.wall_id==str(wall.get_path()) and not hit.is_empty() \
				and hit.collider==wall and Vector3(hit.normal).dot(normal)>.999
			for wheel: Dictionary in rider._visual_rig.board_contact_geometry().wheels:
				for vertex: Vector3 in wheel.points:wall_gap=minf(wall_gap,(frame*vertex-point).dot(normal))
			native_wall=native_wall and is_finite(wall_gap) and wall_gap>=.0149
		model_clear=model_clear and model
		capsule_clear=capsule_clear and capsule
		skin_clear=skin_clear and skin
		shoe_clear=shoe_clear and shoes
		wall_clear=wall_clear and native_wall
		var row={"physics":Engine.get_physics_frames(),"phase":evidence.phase,"mode":mode,"position":at,
			"yaw":rider.rotation.y,"velocity":rider.velocity,"speed":rider.speed,"path_m":path_m,
			"manual":rider.manual_active,"grind":String(rider._grind.line.id) if rider.grinding else "",
			"launch":rider._launch_id,"model":model,"capsule":capsule,"skin":skin,"wall":native_wall,
			"wall_skin_context":wall_context,"active_wall_rid":str(rider._obstacle_air_wall.get("rid","")),
			"forecast_rid":str(rider._obstacle_air_forecast.get("rid","")),"wall_air_presentation":rider._wall.air_presentation_active,
			"active_offset":rider._obstacle_visual_offset,"shoe_zero":shoes,"raw_margin_zero":raw_zero,"raw_margin_7_99mm":raw_skin,
			"wall_gap":wall_gap if is_finite(wall_gap) else null,"capsule_raw_strict_clear":raw_capsule_clear,"capsule_failure_raw":raw_capsule,"loaded_wall_capsule":loaded_wall,"loaded_ground_capsule":loaded_ground,"raw_direction":rider._trick_input.direction(),"direction_age":rider._trick_input.direction_age(),
			"input":{"push":Input.get_action_strength("push"),"brake":Input.get_action_strength("brake"),
				"left":Input.get_action_strength("steer_left"),"right":Input.get_action_strength("steer_right"),
				"ollie":Input.get_action_strength("ollie"),"manual":Input.get_action_strength("manual"),"grind":Input.get_action_strength("grind")}}
		frames.append(row)
		if not model or not capsule or not shoes or not skin or not native_wall:
			if failures.size()<12:failures.append(row)

	func _raw_pose_hits(rider: CharacterBody3D,margin: float) -> Dictionary:
		# Independent queries are observations only: no actor/input/query-state mutation.
		var query:=PhysicsShapeQueryParameters3D.new()
		query.collision_mask=1
		query.exclude=[rider.get_rid()]
		query.margin=margin
		query.shape=rider._visual_rig.board_contact_geometry().convex_shape
		query.transform=rider._board_visual.global_transform
		var space:=rider.get_world_3d().direct_space_state
		var board_hits:=space.intersect_shape(query,8)
		var saturated: bool=board_hits.size()>=8
		var result: Array[Dictionary]=[]
		for hit: Dictionary in board_hits:result.append(_hit_record(hit,"whole_board_convex"))
		var shoes_clear:=true
		var box:=BoxShape3D.new()
		query.shape=box
		for index: int in rider._visual_rig._legs.size():
			var bounds: AABB=rider._obstacle_shoe_bounds[index]
			box.size=bounds.size
			query.transform=rider._visual_rig._legs[index].foot.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center())
			var hits:=space.intersect_shape(query,8)
			saturated=saturated or hits.size()>=8
			shoes_clear=shoes_clear and hits.is_empty()
			for hit: Dictionary in hits:result.append(_hit_record(hit,"shoe_"+str(index)))
		return {"margin":margin,"hits":result,"shoes_clear":shoes_clear,"saturated":saturated}
	func _hit_record(hit: Dictionary,part: String) -> Dictionary:
		return {"part":part,"rid":str(hit.rid),"shape":int(hit.shape),"collider":str(hit.collider.get_path())}

	func _raw_capsule(rider: CharacterBody3D) -> Dictionary:
		var collision: CollisionShape3D=rider.get_node("BodyCollision")
		var capsule: CapsuleShape3D=collision.shape
		var index: int=-1
		for owner: int in rider.get_shape_owners():
			if rider.shape_owner_get_owner(owner)==collision:index=rider.shape_owner_get_shape_index(owner,0)
		var native_frame: Transform3D=PhysicsServer3D.body_get_state(rider.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		if index>=0:native_frame=native_frame*PhysicsServer3D.body_get_shape_transform(rider.get_rid(),index)
		var rows: Array[Dictionary]=[]
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=capsule
		query.collision_mask=1
		query.exclude=[rider.get_rid()]
		var space:=rider.get_world_3d().direct_space_state
		for frame_id: String in ["node","native_body_shape"]:
			query.transform=collision.global_transform if frame_id=="node" else native_frame
			for margin: float in [0.0,.001]:
				query.margin=margin
				var hits:=space.intersect_shape(query,16)
				var pairs:=space.collide_shape(query,32)
				var ids: Array[Dictionary]=[]
				for hit: Dictionary in hits:ids.append(_hit_record(hit,"capsule"))
				rows.append({"frame_id":frame_id,"frame":query.transform,"margin":margin,"hits":ids,"contact_pairs":pairs,"hits_saturated":hits.size()>=16,"pairs_saturated":pairs.size()>=32})
		var point: Vector3=rider._wall.contact_point
		var normal: Vector3=rider._wall.normal
		var native_wall: Dictionary={}
		if rider.wallriding:
			var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+normal*.1,point-normal*.1,1,[rider.get_rid()]))
			if not hit.is_empty():
				var signed: float=(native_frame.origin-Vector3(hit.position)).dot(Vector3(hit.normal)) \
					-maxf(0,capsule.height*.5-capsule.radius)*absf(native_frame.basis.y.dot(Vector3(hit.normal))) \
					-capsule.radius*(native_frame.basis.transposed()*Vector3(hit.normal)).length()
				native_wall={"rid":str(hit.rid),"shape":int(hit.shape),"point":hit.position,"normal":hit.normal,
					"collider":str(hit.collider.get_path()),"native_capsule_signed_gap":signed}
		return {"node_frame":collision.global_transform,"native_frame":native_frame,"native_shape_index":index,
			"current_body_global":rider.global_transform,"node_shape_local":collision.transform,
			"native_shape_local":PhysicsServer3D.body_get_shape_transform(rider.get_rid(),index) if index>=0 else Transform3D.IDENTITY,
			"actual_last_motion":rider.get_last_motion(),"actual_position_delta":rider.get_position_delta(),
			"native_shape_rid":str(PhysicsServer3D.body_get_shape(rider.get_rid(),index)) if index>=0 else "",
			"capsule_rid":str(capsule.get_rid()),"radius":capsule.radius,"height":capsule.height,
			"actual_air":rider.airborne,"actual_wall":rider.wallriding,"actual_floor":rider.is_on_floor(),
			"wall_face":native_wall,"query_records":rows}

	func _loaded_wall_capsule(rider: CharacterBody3D,frame: Transform3D,identity: Dictionary={}) -> Dictionary:
		# Captured wall support is loaded contact. Keep the raw1mm hit and
		# accept only a zero-penetration actual capsule against its own fresh
		# finite supporting face. Every other face/owner/unloaded air stays strict.
		if not rider.wallriding or not rider._wall.active or rider.is_on_floor() or rider._wall.wall_id!=str(wall.get_path()):return {"clear":false,"reason":"not_current_loaded_wall"}
		if not frame.origin.is_finite() or not frame.basis.is_finite() \
			or not is_finite(frame.basis.determinant()) or frame.basis.determinant()<=0:return {"clear":false,"reason":"invalid_frame"}
		var collision: CollisionShape3D=rider.get_node("BodyCollision")
		var capsule: CapsuleShape3D=collision.shape
		var index: int=-1
		for owner: int in rider.get_shape_owners():
			if rider.shape_owner_get_owner(owner)==collision:index=rider.shape_owner_get_shape_index(owner,0)
		if not is_finite(rider.safe_margin) or rider.safe_margin<0:return {"clear":false,"reason":"invalid_native_solver_margin"}
		if collision.disabled or index<0 or not is_finite(capsule.radius) or not is_finite(capsule.height) \
			or capsule.radius<=0 or capsule.height<capsule.radius*2:return {"clear":false,"reason":"invalid_actual_shape"}
		var binding:=_native_capsule_binding(rider,collision,index)
		if not bool(binding.clear):return {"clear":false,"reason":"native_local_binding_refused","binding":binding}
		var current_bound: Transform3D=binding.current_node_body_native_local_frame
		if not _same_actual_frame(frame,collision.global_transform) or not _same_actual_frame(frame,current_bound):return {"clear":false,"reason":"not_actual_native_frame"}
		var point: Vector3=rider._wall.contact_point
		var normal: Vector3=rider._wall.normal
		if not point.is_finite() or not normal.is_finite() or absf(normal.length_squared()-1)>.00001 \
			or absf(normal.y)>.18:return {"clear":false,"reason":"invalid_wall_source"}
		var space:=rider.get_world_3d().direct_space_state
		var face:=space.intersect_ray(PhysicsRayQueryParameters3D.create(point+normal*.1,point-normal*.1,1,[rider.get_rid()]))
		if face.is_empty() or face.collider!=wall or face.rid!=wall.get_rid() or typeof(face.shape)!=TYPE_INT \
			or not Vector3(face.position).is_finite() or not Vector3(face.normal).is_finite() \
			or not is_finite(Vector3(face.normal).length_squared()) or absf(Vector3(face.normal).length_squared()-1)>.00001 \
			or Vector3(face.normal).dot(normal)<.999:return {"clear":false,"reason":"unproven_finite_current_face"}
		if not identity.is_empty() and (identity.get("rid")!=face.rid or int(identity.get("shape",-1))!=int(face.shape) \
			or not Vector3(identity.get("normal",Vector3.ZERO)).is_finite() \
			or absf(Vector3(identity.get("normal",Vector3.ZERO)).length_squared()-1)>.00001 \
			or Vector3(identity.get("normal",Vector3.ZERO)).dot(Vector3(face.normal))<.999):return {"clear":false,"reason":"wrong_expected_identity"}
		normal=face.normal
		point=face.position
		var gap_classification:=_wall_gap_classification(frame,capsule.radius,capsule.height,point,normal,rider.safe_margin)
		if not bool(gap_classification.clear):return {"clear":false,"reason":"penetrating_or_not_loaded_near_face","classification":gap_classification}
		var signed_gap: float=gap_classification.signed_gap
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=capsule
		query.transform=frame
		query.collision_mask=1
		query.exclude=[rider.get_rid()]
		query.margin=0
		if not space.intersect_shape(query,1).is_empty():return {"clear":false,"reason":"zero_margin_actual_overlap"}
		query.margin=.001
		var hits:=space.intersect_shape(query,16)
		var pairs:=space.collide_shape(query,32)
		if hits.is_empty() or hits.size()>=16 or pairs.is_empty() or pairs.size()%2!=0 or pairs.size()>=32:return {"clear":false,"reason":"missing_or_saturated_contact_data"}
		for hit: Dictionary in hits:
			if hit.rid!=face.rid or typeof(hit.shape)!=TYPE_INT or int(hit.shape)!=int(face.shape):return {"clear":false,"reason":"other_contact_owner_or_shape"}
		var finite_pairs: Array[Dictionary]=[]
		for offset: int in range(0,pairs.size(),2):
			var a: Vector3=pairs[offset]
			var b: Vector3=pairs[offset+1]
			var separation: Vector3=b-a
			if not a.is_finite() or not b.is_finite() or not separation.is_finite() \
				or not is_finite(separation.length_squared()) or separation.length_squared()<.000000000001 \
				or separation.normalized().dot(normal)<.999 or absf((b-point).dot(normal))>.002:return {"clear":false,"reason":"contact_pair_not_on_supporting_face"}
			var proof:=space.intersect_ray(PhysicsRayQueryParameters3D.create(b+normal*.02,b-normal*.02,1,[rider.get_rid()]))
			if proof.is_empty() or proof.rid!=face.rid or typeof(proof.shape)!=TYPE_INT or int(proof.shape)!=int(face.shape) \
				or not Vector3(proof.position).is_finite() or not Vector3(proof.normal).is_finite() \
				or not is_finite(Vector3(proof.normal).length_squared()) or absf(Vector3(proof.normal).length_squared()-1)>.00001 \
				or Vector3(proof.normal).dot(normal)<.999 or Vector3(proof.position).distance_to(b)>.002:return {"clear":false,"reason":"contact_pair_finite_face_miss"}
			finite_pairs.append({"query_point":a,"environment_point":b,"fresh_point":proof.position,"fresh_normal":proof.normal})
		return {"clear":true,"contract":"actual_zero_penetration_loaded_wall_contact","rid":str(face.rid),"shape":int(face.shape),
			"normal":normal,"point":point,"signed_gap":signed_gap,"node_frame":frame,"native_binding":binding,
			"native_shape_index":index,"radius":capsule.radius,"height":capsule.height,"raw_margin":.001,
			"zero_margin_overlap":false,"hits":hits.size(),"pairs":finite_pairs,"solver_safe_margin":rider.safe_margin}
	func _same_actual_frame(a: Transform3D,b: Transform3D) -> bool:
		return a.origin.is_finite() and b.origin.is_finite() and a.basis.is_finite() and b.basis.is_finite() \
			and a.origin.distance_to(b.origin)<.00001 and a.basis.x.distance_to(b.basis.x)<.00001 \
			and a.basis.y.distance_to(b.basis.y)<.00001 and a.basis.z.distance_to(b.basis.z)<.00001
	func _loaded_wall_negatives(rider: CharacterBody3D,proof: Dictionary) -> void:
		wall_load_controls_ran=true
		var frame: Transform3D=rider.get_node("BodyCollision").global_transform
		var identity={"rid":wall.get_rid(),"shape":int(proof.shape),"normal":Vector3(proof.normal)}
		var foreign=identity.duplicate()
		foreign.rid=game.world._outdoors.get_node("ClydeNorthQuay").get_rid()
		var shape=identity.duplicate()
		shape.shape=int(proof.shape)+1
		var wrong_face=identity.duplicate()
		wrong_face.normal=-Vector3(proof.normal)
		for item: Dictionary in [{"id":"foreign_owner","identity":foreign},{"id":"wrong_integer_shape","identity":shape},{"id":"opposite_face_normal_same_shape","identity":wrong_face}]:
			var rejected: Dictionary=_loaded_wall_capsule(rider,frame,item.identity)
			wall_load_controls_clear=wall_load_controls_clear and not bool(rejected.get("clear",false))
			wall_load_controls.append({"id":item.id,"result":rejected})
		var deep:=frame
		deep.origin-=Vector3(proof.normal)*.020
		var query:=PhysicsShapeQueryParameters3D.new()
		query.shape=rider.get_node("BodyCollision").shape
		query.transform=deep
		query.collision_mask=1
		query.exclude=[rider.get_rid()]
		query.margin=0
		var actual_deep_hit: bool=not rider.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
		var rejected: Dictionary=_loaded_wall_capsule(rider,deep)
		wall_load_controls_clear=wall_load_controls_clear and actual_deep_hit and not bool(rejected.get("clear",false))
		var deep_classification:=_wall_gap_classification(deep,float(proof.radius),float(proof.height),Vector3(proof.point),Vector3(proof.normal),rider.safe_margin)
		wall_load_controls_clear=wall_load_controls_clear and not bool(deep_classification.clear)
		wall_load_controls.append({"id":"20mm_deep_query_only_proxy","actual_zero_margin_hit":actual_deep_hit,
			"actual_frame_auth_refusal":rejected,"independent_pure_signed_plane_classification":deep_classification,
			"scope":"modified proxy is not actual Node/native frame; actual helper refuses before its gap branch"})
		var bad_margin:=_wall_gap_classification(frame,float(proof.radius),float(proof.height),Vector3(proof.point),Vector3(proof.normal),NAN)
		var bad_normal:=_wall_gap_classification(frame,float(proof.radius),float(proof.height),Vector3(proof.point),Vector3(proof.normal)*2,rider.safe_margin)
		wall_load_controls_clear=wall_load_controls_clear and not bool(bad_margin.clear) and not bool(bad_normal.clear)
		wall_load_controls.append({"id":"pure_nan_solver_margin","result":bad_margin})
		wall_load_controls.append({"id":"pure_nonunit_native_normal","result":bad_normal})
		var bad:=frame
		bad.origin.x=NAN
		var nan_result: Dictionary=_loaded_wall_capsule(rider,bad)
		var huge:=frame
		huge.basis=Basis.from_scale(Vector3(1e20,1e20,1e20))
		var huge_result: Dictionary=_loaded_wall_capsule(rider,huge)
		wall_load_controls_clear=wall_load_controls_clear and not bool(nan_result.get("clear",false)) and not bool(huge_result.get("clear",false))
		wall_load_controls.append({"id":"nonfinite_origin","result":nan_result})
		wall_load_controls.append({"id":"finite_entries_overflow_determinant","result":huge_result})
		var invalid_backend: Transform3D=proof.native_binding.backend_body_state_shape_frame
		invalid_backend.origin.x=NAN
		var phase_bad:=_pending_motion_phase(frame,invalid_backend,rider.get_last_motion(),rider.get_position_delta())
		var overflow_backend:=frame
		overflow_backend.basis=Basis.from_scale(Vector3(1e20,1e20,1e20))
		var phase_overflow:=_pending_motion_phase(frame,overflow_backend,rider.get_last_motion(),rider.get_position_delta())
		wall_load_controls_clear=wall_load_controls_clear and not bool(phase_bad.clear) and not bool(phase_overflow.clear)
		wall_load_controls.append({"id":"pure_nonfinite_backend_origin","result":phase_bad})
		wall_load_controls.append({"id":"pure_backend_determinant_overflow","result":phase_overflow})

	func _wall_gap_classification(frame: Transform3D,radius: float,height: float,point: Vector3,normal: Vector3,limit: float) -> Dictionary:
		# Pure signed-plane calculation only; never grants native contact authority.
		if not frame.origin.is_finite() or not frame.basis.is_finite() or not is_finite(frame.basis.determinant()) \
			or frame.basis.determinant()<=0 or not is_finite(radius) or not is_finite(height) or radius<=0 or height<radius*2 \
			or not point.is_finite() or not normal.is_finite() or not is_finite(normal.length_squared()) \
			or absf(normal.length_squared()-1)>.00001 or not is_finite(limit) or limit<0:return {"clear":false,"reason":"invalid_pure_inputs"}
		var gap: float=(frame.origin-point).dot(normal)-maxf(0,height*.5-radius)*absf(frame.basis.y.dot(normal)) \
			-radius*(frame.basis.transposed()*normal).length()
		if not is_finite(gap):return {"clear":false,"reason":"nonfinite_signed_gap"}
		return {"clear":gap>=0 and gap<=limit,"signed_gap":gap,"reason":"negative_gap" if gap<0 else ("outside_solver_proximity" if gap>limit else "nonnegative_plane_proximity_only")}

	func _native_capsule_binding(rider: CharacterBody3D,collision: CollisionShape3D,index: int) -> Dictionary:
		# The authoritative current query frame uses the CURRENT body Node and
		# authenticated server LOCALshape. Server GLOBALstate can still be queued;
		# retain it and prove its actual slide-motion relationship, never use it
		# as a substitute for current-pose clearance.
		var capsule: CapsuleShape3D=collision.shape
		var native_rid: RID=PhysicsServer3D.body_get_shape(rider.get_rid(),index)
		if native_rid!=collision.shape.get_rid() or PhysicsServer3D.shape_get_type(native_rid)!=PhysicsServer3D.SHAPE_CAPSULE:return {"clear":false,"reason":"wrong_native_shape_resource"}
		var data: Variant=PhysicsServer3D.shape_get_data(native_rid)
		if typeof(data)!=TYPE_DICTIONARY or not data.has_all(["radius","height"]):return {"clear":false,"reason":"missing_native_capsule_dimensions"}
		if not is_finite(float(data.radius)) or not is_finite(float(data.height)) \
			or absf(float(data.radius)-capsule.radius)>.0000001 or absf(float(data.height)-capsule.height)>.0000001:return {"clear":false,"reason":"different_native_capsule_dimensions"}
		var local: Transform3D=PhysicsServer3D.body_get_shape_transform(rider.get_rid(),index)
		if not _valid_full_frame(local) or not _valid_full_frame(rider.global_transform):return {"clear":false,"reason":"invalid_native_local_or_current_body_frame"}
		if collision.get_parent()!=rider or not _same_actual_frame(local,collision.transform):return {"clear":false,"reason":"local_shape_notification_mismatch"}
		var current: Transform3D=rider.global_transform*local
		if not _same_actual_frame(current,collision.global_transform):return {"clear":false,"reason":"current_full_shape_frame_mismatch"}
		var backend_body: Transform3D=PhysicsServer3D.body_get_state(rider.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		var backend_shape: Transform3D=backend_body*local
		var last_motion: Vector3=rider.get_last_motion()
		var position_delta: Vector3=rider.get_position_delta()
		if not _valid_full_frame(backend_body):return {"clear":false,"reason":"nonfinite_or_invalid_backend_body"}
		var phase_proof:=_pending_motion_phase(current,backend_shape,last_motion,position_delta)
		if not bool(phase_proof.clear):return {"clear":false,"reason":"unexplained_pending_native_transform","phase_proof":phase_proof}
		var delta: Vector3=phase_proof.delta
		var phase: String=phase_proof.phase
		return {"clear":true,"phase":phase,"rid":str(native_rid),"index":index,"native_dimensions":data,
			"current_node_body_native_local_frame":current,"node_body_global":rider.global_transform,"native_local_shape":local,
			"node_local_shape":collision.transform,"backend_body_state_shape_frame":backend_shape,
			"backend_to_current_delta":delta,"last_motion":last_motion,"position_delta":position_delta,
			"scope":"current-pose geometry only; backendglobalstate never replaces the actual Node query frame"}


	func _valid_full_frame(frame: Transform3D) -> bool:
		return frame.origin.is_finite() and frame.basis.is_finite() and is_finite(frame.basis.determinant()) and frame.basis.determinant()>0
	func _pending_motion_phase(current: Transform3D,backend: Transform3D,last_motion: Vector3,position_delta: Vector3) -> Dictionary:
		if not _valid_full_frame(current) or not _valid_full_frame(backend):return {"clear":false,"reason":"invalid_current_or_backend_full_frame"}
		var delta: Vector3=current.origin-backend.origin
		if not delta.is_finite():return {"clear":false,"reason":"nonfinite_backend_to_current_delta"}
		if _same_actual_frame(current,backend):return {"clear":true,"phase":"already_synchronized","delta":delta}
		if not last_motion.is_finite() or not position_delta.is_finite() \
			or not _same_actual_frame(Transform3D(current.basis,Vector3.ZERO),Transform3D(backend.basis,Vector3.ZERO)) \
			or delta.distance_to(last_motion)>.00001 or delta.distance_to(position_delta)>.00001:return {"clear":false,"reason":"unexplained_pending_actual_motion","current":current,"backend":backend,"delta":delta,"last_motion":last_motion,"position_delta":position_delta}
		return {"clear":true,"phase":"pending_actual_current_slide_motion","delta":delta}
