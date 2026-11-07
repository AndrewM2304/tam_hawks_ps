from pathlib import Path
import hashlib,json,shutil,subprocess,difflib
R=Path.cwd();B=R/'.local/c04-landing-continuity'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def sources(root):
 return {str(p.relative_to(root)):sha(p)for d in ['game','tests','tools'] for p in (root/d).rglob('*')if p.is_file()and'__pycache__'not in p.parts}|{'project.godot':sha(root/'project.godot')}
def instrument(source):
 s=source.replace('func _update_pose(delta: float) -> void:\n','func _update_pose(delta: float) -> void:\n\t_d022_begin(delta)\n',1)
 # Exact callsite is last statement of the pose update.
 s=s.replace('\t_obstacle_arm_fit.apply(delta)\n\n\nfunc _place_obstacle_wheels','\t_obstacle_arm_fit.apply(delta)\n\t_d022_end()\n\n\nfunc _place_obstacle_wheels',1)
 assert '_d022_end()\n\n\nfunc _place_obstacle_wheels'in s
 s=s.replace('\t\tvar angle := _air_support_basis.get_rotation_quaternion().angle_to(target_basis.get_rotation_quaternion())', '\t\tif not _d022_current.is_empty():_d022_current.anticipation={"incoming":_d022_basis(_air_support_basis),"target":_d022_basis(target_basis),"upcoming":_d022_hit(upcoming),"air_offset":_d022_vec(air_visual_offset)}\n\t\tvar angle := _air_support_basis.get_rotation_quaternion().angle_to(target_basis.get_rotation_quaternion())',1)
 s=s.replace('\t\t_visual.basis = _air_support_basis * Basis(Vector3.UP, visual_yaw)\n\tif wallriding:', '\t\t_visual.basis = _air_support_basis * Basis(Vector3.UP, visual_yaw)\n\t\tif not _d022_current.is_empty():_d022_current.after_anticipation=_d022_capture()\n\tif wallriding:',1)
 a=s.index('func _place_air_landing_wheels(');z=s.index('\n\nfunc _withdraw_air_support_offset',a);block=s[a:z].replace('func _place_air_landing_wheels(', 'func _place_air_landing_wheels_unobserved(',1)
 lines=[];guard=0
 for line in block.splitlines():
  if 'return' in line and not line.lstrip().startswith('#'):
   guard+=1;reason='guard'+str(guard)+': '+line.strip()[:180]
   if line.strip()=='return':lines.append(line[:len(line)-len(line.lstrip())]+'_d022_reason('+json.dumps(reason)+')');lines.append(line)
   else:lines.append(line.replace('return','_d022_reason('+json.dumps(reason)+');return',1))
  else:lines.append(line)
 block='\n'.join(lines)
 block=block.replace('\tvar target:=Transform3D(global_basis*landing_basis*Basis(Vector3.UP,yaw),original.origin)','\tvar target:=Transform3D(global_basis*landing_basis*Basis(Vector3.UP,yaw),original.origin)\n\tif not _d022_current.is_empty():_d022_current.solver_target=_d022_matrix(target)',1)
 block=block.replace('\tvar fitted:=original.interpolate_with(target,high)','\tvar fitted:=original.interpolate_with(target,high)\n\tif not _d022_current.is_empty():_d022_current.solver_fraction=high',1)
 block+='\n\t_d022_reason("accepted")\n'
 wrapper='''func _place_air_landing_wheels(support:Dictionary)->void:
	if not _d022_current.is_empty():
		_d022_current.before_landing=_d022_capture()
		_d022_current.landing_support=_d022_hit(support)
	_place_air_landing_wheels_unobserved(support)
	if not _d022_current.is_empty():_d022_current.after_landing=_d022_capture()


'''
 s=s[:a]+wrapper+block+s[z:]
 helper='''
var _d022_rows:Array[Dictionary]=[]
var _d022_current:Dictionary={}
func _d022_vec(v:Vector3)->Array:return [v.x,v.y,v.z]
func _d022_matrix(t:Transform3D)->Array:return [[t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x],[t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y],[t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z],[0,0,0,1]]
func _d022_basis(b:Basis)->Array:return _d022_matrix(Transform3D(b,Vector3.ZERO))
func _d022_hit(h:Dictionary)->Dictionary:
	if h.is_empty():return {}
	return {"position":_d022_vec(h.get("position",Vector3.ZERO)),"normal":_d022_vec(h.get("normal",Vector3.ZERO)),"rid":str(h.get("rid",RID())),"shape":h.get("shape",-1),"path":str(h.collider.get_path()) if h.get("collider") is Node else ""}
func _d022_capture()->Dictionary:
	return {"visual":_d022_matrix(_visual.global_transform),"board":_d022_matrix(_board_visual.global_transform),"head":_d022_matrix(_visual_rig._head.global_transform),"air_support_basis":_d022_basis(_air_support_basis)}
func _d022_begin(delta:float)->void:
	_d022_current={}
	var p:Vector3=global_position
	if p.x< -14 or p.x> -10 or p.z<128 or p.z>132:return
	_d022_current={"physics":Engine.get_physics_frames(),"process":Engine.get_process_frames(),"in_physics_frame":Engine.is_in_physics_frame(),"delta":delta,"body":_d022_matrix(global_transform),"velocity":_d022_vec(velocity),"airborne":airborne,"ramp_air":_ramp_air,"native_floor_valid":_native_floor_valid,"on_floor":is_on_floor(),"transition_active":transition_active,"feature_active":_feature_transition.active,"feature_state":_feature_transition.state,"feature_normal":_d022_vec(_feature_transition.normal),"start":_d022_capture()}
func _d022_reason(reason:String)->void:
	if not _d022_current.is_empty():_d022_current.reason=reason
func _d022_end()->void:
	if _d022_current.is_empty():return
	_d022_current.end=_d022_capture()
	_d022_rows.append(_d022_current)
'''
 return s+'\n'+helper
actual_before=sources(R);(B/'actual-source-at-copy.json').write_text(json.dumps(actual_before,indent=2)+'\n')
for mode in ['baseline','candidate']:
 P=B/mode;P.mkdir(exist_ok=False)
 for name in ['game','tests','tools']:subprocess.run(['cp','-a','--reflink=auto',str(R/name),str(P/name)],check=True)
 shutil.copy2(R/'project.godot',P/'project.godot');assert sources(P)==actual_before
 if mode=='baseline':
  for name in ['skater.gd','skater_visual.gd']:shutil.copy2(R/'.local/c04-camera-diagnosis/integration-proposal-02'/(name+'.before'),P/'game/player'/name)
 (P/'.local').mkdir();cache=P/'.godot';cache.mkdir()
 for name in ['global_script_class_cache.cfg','uid_cache.bin','extension_list.cfg']:
  if (R/'.godot'/name).is_file():shutil.copy2(R/'.godot'/name,cache/name)
 (cache/'imported').symlink_to(R/'.godot/imported',target_is_directory=True)
 source=P/'game/player/skater.gd';vanilla=source.read_text();(B/(mode+'-skater.unobserved.gd')).write_text(vanilla);traced=instrument(vanilla);source.write_text(traced)
 (B/(mode+'-instrumentation.patch')).write_text(''.join(difflib.unified_diff(vanilla.splitlines(keepends=True),traced.splitlines(keepends=True),fromfile='unobserved/'+mode,tofile='instrumented/'+mode)))
 (B/(mode+'-source-at-prepare.json')).write_text(json.dumps(sources(P),indent=2)+'\n')
assert actual_before==sources(R),'actualrootchangedwhilecopying; rejectcopy'
imports={str(p.relative_to(R/'.godot/imported')):sha(p.resolve())for p in sorted((R/'.godot/imported').rglob('*'))if p.is_file()};(B/'shared-imported-at-copy.json').write_text(json.dumps(imports,indent=2)+'\n')
(B/'copy-receipt.json').write_text(json.dumps({'actual_source_stable_during_copy':True,'actual_source_count':len(actual_before),'shared_imported_files':len(imports),'cache_scope':'Copiedindependentmetadata; read-onlysharedimportednativebytes only, noeditor/import/writestosharedcache. Allrealresolvedimportedfileshashed. Allgame/tests/toolsbytesprivatecopies, noactualsourceautoload.','runtime_scope':'Baselineonly2preC04files preservingfreed/pin/nativeLip; candidatecurrentactual. Commonpuregetterinstrumentation wrappedoriginalsolver withreturnreasons; noinputs/tolerance/posechanges.'},indent=2)+'\n')
print('prepared',len(actual_before),'actualsources, imports',len(imports))
