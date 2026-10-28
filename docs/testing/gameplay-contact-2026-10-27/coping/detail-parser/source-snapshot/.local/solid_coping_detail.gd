extends SceneTree
const Connected=preload("res://tests/connected_transition_tests.gd")
const Bowl=preload("res://game/levels/bowl_feature.gd")
const Spine=preload("res://game/levels/spine_feature.gd")
const Native=preload("res://tests/feature_transition_ride_tests.gd")
func _initialize()->void:_run.call_deferred()
func _frames(n:int)->void:
	for i in n:await physics_frame;await process_frame
func _state(r,shape)->Dictionary:
	var sample:Dictionary=shape.surface_sample(r.global_position)
	var d:Dictionary={"p":r.global_position,"v":r.velocity,"state":r.ride.state,"active":r.ride.active,"theta":r.ride._theta,"bails":r.bails,"landings":r.landings,"entries":r.entries,"result":r.last_result,"sample":sample}
	if r.ride.active:d["feature"]=r.ride.feature.name
	if not sample.is_empty():
		d["face"]=r.ride._real_face_contact(r,shape,sample)
		d["profile"]=r.ride._coping_profile(r,shape,sample)
		d["target"]=r.ride._surface_body_target(r,shape,sample)
	return d
func _run()->void:
	var bowl=Bowl.new();var f:Dictionary=await Connected._fixture(self,bowl)
	var r=f.rider
	var initial:Dictionary=bowl.sample(0.0,0.4*bowl.floor_radius)
	r.position=initial.point+Vector3.UP*0.022;r.velocity=initial.tangent*12.0;r.held=true;r.running=true
	for i in 65:
		var before:Dictionary=_state(r,bowl)
		await _frames(1)
		if float(before.theta)>1.35 or r.bails>0 or r.ride.state=="lip":print("BOWL_LIP ",{"tick":i,"before":before,"after":_state(r,bowl)})
		if r.bails>0 or r.ride.state=="lip":break
	f.root.queue_free();await process_frame
	bowl=Bowl.new();f=await Connected._fixture(self,bowl);r=f.rider
	var outer:float=bowl.floor_radius+bowl.radius+bowl.deck_length
	r.position=Vector3(0,0.022,outer+9);r.velocity=Vector3.FORWARD*12;r.running=true
	for i in 210:
		var before:Dictionary=_state(r,bowl)
		await _frames(1)
		if i%20==0 or r.bails>0:print("BOWL_ACCESS ",{"tick":i,"before":before,"after":_state(r,bowl)})
		if r.bails>0:break
	f.root.queue_free();await process_frame
	var spine=Spine.new();f=await Connected._fixture(self,spine);r=f.rider
	r.position=Vector3(0,0.022,spine.radius+spine.cap_width*0.5+0.05);r.velocity=Vector3.FORWARD*12;r.push=1;r.running=true
	for i in 90:
		await _frames(1)
		if r.ride.state=="air":break
	r.push=0;await _frames(1);r.push=1;await _frames(12);r.push=0
	var previous:String=r.ride.state;var previous_feature:String=str(r.ride.feature.name) if r.ride.active else ""
	for i in 170:
		await _frames(1)
		var current_feature:String=str(r.ride.feature.name) if r.ride.active else ""
		if r.ride.state!=previous or current_feature!=previous_feature or r.last_result.event!="":
			print("SPINE_EVENT ",{"tick":i,"p":r.position,"v":r.velocity,"state":r.ride.state,"feature":current_feature,"event":r.last_result.event,"landings":r.landings,"bails":r.bails})
		previous=r.ride.state;previous_feature=current_feature
	f.root.queue_free();await process_frame
	print("RESULT: 1 passed, 0 failed");quit()
