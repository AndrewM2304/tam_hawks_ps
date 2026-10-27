from pathlib import Path
import hashlib,json
root=Path.cwd();source=root/'.local/active_wall_arm_probe.gd';original=source.read_text();rows=[]
for candidate in [False,True]:
 data=original
 replacements=[('const Body = preload("res://tests/skater_body_attachment_tests.gd")','const Body = preload("res://tests/skater_body_attachment_tests.gd")\nconst Authentic = preload("res://tests/authentic_pose_tests.gd")\nconst Score = preload("res://game/scoring/score_session.gd")'),
 ('var contacts:=0','var contacts:=0\nvar sequence_tick:=0\nvar previous_markers: Array[Vector3]=[]\nvar maximum_marker_step:=0.0\nvar score:=Score.new()\nvar banks: Array[int]=[]'),
 ('query.collision_mask=1;query.exclude=[actor.get_rid()]','''actor.landed.connect(func(ok: bool):
		if ok:score.begin_landing()
		else:score.drop_combo())
	actor.combo_link_started.connect(score.continue_combo)
	actor.combo_link_ended.connect(score.begin_landing)
	query.collision_mask=1;query.exclude=[actor.get_rid()]'''),
 ('actor.trick_performed.connect(func(label: String,points: int):entries.append({"id":actor.last_trick_id,"label":label,"points":points}))','''actor.trick_performed.connect(func(label: String,points: int):
		entries.append({"id":actor.last_trick_id,"label":label,"points":points})
		score.add_trick(label,points,actor.last_trick_id))'''),
 ('"active_flip_ticks":active_ticks,"entries":entries,"samples":records,','''"active_flip_ticks":active_ticks,"entries":entries,"samples":records,
		"banks":banks,"score_total":score.total_score,"maximum_marker_step":maximum_marker_step,
		"candidate":actor.arm_candidate_report() if actor.has_method("arm_candidate_report") else {},'''),
 ('func _frame() -> void:await physics_frame;await process_frame','''func _frame() -> void:
	await physics_frame;await process_frame
	sequence_tick+=1
	var bank:=score.tick(1.0/60.0)
	if bank>0:banks.append(bank)
	if not arms.is_empty():_observe("native_history",sequence_tick)'''),
 ('var observations: Array[Dictionary]=[]','''var observations: Array[Dictionary]=[]
	var panel_box:=AABB(-gate._shape.size*0.5,gate._shape.size).grow(0.00799)'''),
 ('var vertex:=-1','var vertex:=-1\n\t\tvar panel_hits:=0\n\t\tvar envelope_misses:=0\n\t\tvar envelope:=AABB()\n\t\tif actor.has_method("arm_candidate_report"):envelope=actor._arm_candidate._bounds(actor._arm_candidate.arms[index],{},rig._arms[index].hand.global_transform).grow(0.00001)'),
 ('var distance: float=(point-FACE_POINT).dot(FACE_NORMAL)','''if actor.has_method("arm_candidate_report") and not envelope.has_point(point):envelope_misses+=1\n\t\t\tif panel_box.has_point(gate._panel.to_local(point)):panel_hits+=1
			var distance: float=(point-FACE_POINT).dot(FACE_NORMAL)'''),
 ('var worst_hand:=Vector3.ZERO','var worst_hand:=Vector3.ZERO\n\t\tvar hand_hits:=0'),
 ('var distance: float=(actual-FACE_POINT).dot(FACE_NORMAL)','''if actor.has_method("arm_candidate_report") and not envelope.has_point(actual):envelope_misses+=1\n\t\t\tif panel_box.has_point(gate._panel.to_local(actual)):hand_hits+=1
			var distance: float=(actual-FACE_POINT).dot(FACE_NORMAL)'''),
 ('"worst_vertex":worst,"worst_vertex_index":vertex,','"envelope_misses":envelope_misses,"native_panel_sleeve_vertices_within_skin":panel_hits,"native_panel_hand_vertices_within_skin":hand_hits,\n\t\t\t"worst_vertex":worst,"worst_vertex_index":vertex,'),
 ('\"wallride_normal\":actor._wall.normal','\"on_floor\":actor.is_on_floor(),\"bailing\":actor.bailing,\"speed\":actor.speed,\"wallride_normal\":actor._wall.normal'),
 ('var row: Dictionary={"phase":phase,','''var markers:=Authentic._markers(rig)
	var step:=Authentic._marker_delta(previous_markers,markers) if previous_markers.size()==markers.size() else 0.0
	maximum_marker_step=maxf(maximum_marker_step,step);previous_markers=markers
	var row: Dictionary={"candidate":actor.arm_candidate_report() if actor.has_method("arm_candidate_report") else {},
		"marker_step":step,"phase":phase,''')]
 if candidate:replacements.append(('const Current = preload("res://game/player/skater.gd")','const Current = preload("res://.local/active_wall_arm_skater.gd")'))
 name='candidate' if candidate else 'before'
 replacements.append(('res://.local/active_wall_arm_probe.json',f'res://.local/active_wall_arm_{name}_proof.json'))
 for before,after in replacements:
  assert data.count(before)==1,(name,before,data.count(before));data=data.replace(before,after)
 target=root/f'.local/active_wall_arm_{name}_proof.gd';target.write_text(data)
 rows.append({'target':str(target.relative_to(root)),'sha256':hashlib.sha256(data.encode()).hexdigest(),'replacements':replacements})
(root/'.local/active_wall_arm_proof_derivation.json').write_text(json.dumps({'observer_source':str(source.relative_to(root)),'source_sha256':hashlib.sha256(original.encode()).hexdigest(),'files':rows},indent=2)+'\n')
print('Prepared paired full native history, true score, original marker, all sleeve/hand native panel-box witnesses')
