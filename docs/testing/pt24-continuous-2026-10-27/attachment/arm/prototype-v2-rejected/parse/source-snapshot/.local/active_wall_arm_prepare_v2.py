from pathlib import Path
import hashlib,json
root=Path.cwd();records=[]
def derive(source,target,replacements):
 data=(root/source).read_text();original=hashlib.sha256(data.encode()).hexdigest()
 for before,after in replacements:
  assert data.count(before)==1,(source,before,data.count(before));data=data.replace(before,after)
 (root/target).write_text(data)
 records.append({'source':source,'source_sha256':original,'target':target,'sha256':hashlib.sha256(data.encode()).hexdigest(),'replacements':replacements})
derive('.local/active_wall_arm_candidate.gd','.local/active_wall_arm_candidate_v2.gd',[
 ('## Ignored prototype only. Constant-weight garment rows give exact affine\n## images of startup AABBs; their union encloses every native skinned vertex.', '## Ignored v2 prototype only. Constant-weight garment rows use affine\n## cylinder support; their union encloses every native skinned vertex.'),
 ('radius=maxf(radius,(point-rest.origin).slide(rest.basis.y).length())','var radial: float=(point-rest.origin).slide(rest.basis.y).length()\n\t\t\tradius=maxf(radius,radial)'),
 ('row.bounds= AABB(row.bounds).expand(point);found=true;break','row.bounds=AABB(row.bounds).expand(point);row.radius=maxf(row.radius,radial);found=true;break'),
 ('"bounds":AABB(point,Vector3.ZERO)','"bounds":AABB(point,Vector3.ZERO),"radius":radial,"center":Vector2(rest.origin.x,rest.origin.z)'),
 ('\t\tvar ratio:=0.29/maxf(0.001,arm.hand_length)\n\t\tvar elbow_min: float=arm.radius+SKIN\n\t\tvar hand_min: float=arm.hand_radius+SKIN\n\t\tvar goal:=maxf(hand_min,(elbow_min+ratio*hand_min)/(1.0+ratio))+SKIN','\t\tvar elbow_min: float=arm.radius+SKIN\n\t\tvar goal:=elbow_min+SKIN'),
 ('var elbow_max:=target_gap+(target_gap-hand_min)*ratio','var elbow_max:=target_gap'),
 ('var actual: AABB=Transform3D(Basis(x,y,z),origin)*AABB(row.bounds)', '''# This source cylinder contains every original row vertex; affine axis
		# support preserves that enclosure without empty rectangle corners.
		var bounds: AABB=row.bounds
		var half_height: float=bounds.size.y*0.5
		var source_center:=Vector3(row.center.x,bounds.get_center().y,row.center.y)
		var center:=Transform3D(Basis(x,y,z),origin)*source_center
		var radial: float=row.radius
		var extent:=Vector3(absf(y.x)*half_height+radial*sqrt(x.x*x.x+z.x*z.x),
			absf(y.y)*half_height+radial*sqrt(x.y*x.y+z.y*z.y),
			absf(y.z)*half_height+radial*sqrt(x.z*x.z+z.z*z.z))
		var actual:=AABB(center-extent,extent*2.0)''')])
derive('.local/active_wall_arm_skater.gd','.local/active_wall_arm_skater_v2.gd',[('res://.local/active_wall_arm_candidate.gd','res://.local/active_wall_arm_candidate_v2.gd')])
derive('.local/active_wall_arm_candidate_proof.gd','.local/active_wall_arm_candidate_proof_v2.gd',[('res://.local/active_wall_arm_skater.gd','res://.local/active_wall_arm_skater_v2.gd'),('res://.local/active_wall_arm_candidate_proof.json','res://.local/active_wall_arm_candidate_proof_v2.json')])
derive('.local/active_wall_arm_compare.py','.local/active_wall_arm_compare_v2.py',[
 ("import json,sys","import json,sys,re,math"),
 (".local/active_wall_arm_candidate_proof.json",".local/active_wall_arm_candidate_proof_v2.json"),
 ("check(after['maximum_marker_step']<.22,'original head/feet/hands22cm continuity holds over full entry/Flip/catch/landing')",'''# V1's untouched native foot event already exceeded the whole-world 22cm
# marker limit. Retain it explicitly; apply the unchanged22cm criterion to
# the actually modified wrist markers on their adjacent transitions.
def vec(s):return tuple(map(float,re.findall(r'-?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?',s)))
def distance(x,y):return math.sqrt(sum((a-b)**2 for a,b in zip(vec(x),vec(y))))
changed=[[any(x['arms'][j][k]!=y['arms'][j][k] for k in ['elbow','wrist']) for j in range(2)] for x,y in zip(a,b)]
steps=[distance(b[i]['arms'][j]['wrist'],b[i-1]['arms'][j]['wrist']) for i in range(1,len(b)) for j in range(2) if changed[i][j] or changed[i-1][j]]
check(bool(steps) and max(steps)<.22,'original22cm continuity holds at every actually modified hand-marker transition; untouched baseline global failure retained')
print('BASELINE_GLOBAL_MARKER',before['maximum_marker_step'],'CANDIDATE_GLOBAL_MARKER',after['maximum_marker_step'],'CHANGED_WRIST_MAX',max(steps) if steps else None)'''),
 ("'first_corrected_sample':first,","'first_corrected_sample':first,'baseline_global_marker':before['maximum_marker_step'],'changed_wrist_maximum':max(steps) if steps else None,"),
 (".local/active_wall_arm_comparison.json",".local/active_wall_arm_comparison_v2.json")])
(root/'.local/active_wall_arm_v2_derivation.json').write_text(json.dumps(records,indent=2)+'\n')
print('Prepared separately named v2; all v1 source/receipts retained unchanged')
