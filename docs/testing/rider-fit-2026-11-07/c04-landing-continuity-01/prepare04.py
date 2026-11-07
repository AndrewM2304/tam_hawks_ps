from pathlib import Path
import json,hashlib,subprocess,shutil,ast,difflib
R=Path.cwd();B=R/'.local/c04-landing-continuity';O=B/'proposal04';O.mkdir(exist_ok=False);P=B/'composite04';P.mkdir(exist_ok=False)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def snapshot(root):return {str(p.relative_to(root)):sha(p)for d in ['game','tests','tools']for p in(root/d).rglob('*')if p.is_file()and'__pycache__'not in p.parts}|{'project.godot':sha(root/'project.godot')}
before=snapshot(R)
for name in ['game','tests','tools']:subprocess.run(['cp','-a','--reflink=auto',str(R/name),str(P/name)],check=True)
shutil.copy2(R/'project.godot',P/'project.godot');assert before==snapshot(P)==snapshot(R)
(P/'.local').mkdir();(P/'.godot').mkdir()
for name in ['global_script_class_cache.cfg','uid_cache.bin','extension_list.cfg']:
 if(R/'.godot'/name).is_file():shutil.copy2(R/'.godot'/name,P/'.godot'/name)
(P/'.godot/imported').symlink_to(R/'.godot/imported',target_is_directory=True)
for name in ['motion_actual_round_focus.gd','motion_round_registry_helper.gd']:shutil.copy2(R/'.local'/name,O/(name+'.before'));shutil.copy2(R/'.local'/name,P/'.local'/name)
base=(R/'game/player/skater.gd').read_text();old=(B/'proposal03/skater.gd.before').read_text();proposed=(B/'proposal03/skater.gd').read_text()
a='func _update_pose(delta: float) -> void:';z='\n\nfunc _place_obstacle_wheels';prior=old[old.index(a):old.index(z,old.index(a))];assert base.count(prior)==1,'parent pose functionchanged';new=proposed[proposed.index(a):proposed.index(z,proposed.index(a))];clean=base.replace(prior,new,1)
anchor='\t_camera_follow.prepare_board_landmarks(_visual_rig)';assert clean.count(anchor)==1;clean=clean.replace(anchor,anchor+'\n\t_prepare_ramp_flat_head_bounds()',1)
clean=clean.replace('\t_ramp_air_sequence += 1','\t_ramp_air_sequence += 1\n\t_ramp_flat_visual_ready=false',1)
helpers=proposed[proposed.index('# Presentation-only wrapped-bowl exit.'):]
# Always keep horizon bounded, including a previously acquired handoff.
helpers=helpers.replace('if not previous.is_finite() or delta<=0.0:return','if not previous.is_finite() or not is_finite(previous.determinant()) or absf(previous.determinant()-1.0)>.001 or delta<=0.0:return')
helpers=helpers.replace('if gap>=0.0 and discriminant>=0.0 and horizontal.dot(outward)<0.0 \\', 'if gap>=0.0 and discriminant>=0.0 and time_to_floor<=PI/4.5+delta and horizontal.dot(outward)<0.0 \\')
# Head local hierarchy composition avoids far-world cancellation in cached bounds.
helpers=helpers.replace('\tvar inverse:Transform3D=head.global_transform.affine_inverse()\n','')
helpers=helpers.replace('\t\tvar local:Transform3D=inverse*mesh.global_transform', '\t\tvar local:Transform3D=mesh.transform\n\t\tvar parent:Node=mesh.get_parent()\n\t\twhile parent!=head:\n\t\t\tif not parent is Node3D:return\n\t\t\tlocal=(parent as Node3D).transform*local\n\t\t\tparent=parent.get_parent()')
clean+='\n'+helpers
(O/'skater.gd.before').write_text(base);(O/'skater.gd').write_text(clean);(O/'skater.gd.patch').write_text(''.join(difflib.unified_diff(base.splitlines(keepends=True),clean.splitlines(keepends=True),fromfile='a/game/player/skater.gd',tofile='b/game/player/skater.gd')))
# Common read-only instrumentation, exact input observer prefix from ME.
tree=ast.parse((B/'prepare_ab.py').read_text());f=next(n for n in tree.body if isinstance(n,ast.FunctionDef)and n.name=='instrument');env={'json':json};exec(compile(ast.Module(body=[f],type_ignores=[]),'instrument','exec'),env);traced=env['instrument'](clean)
old='\tvar p:Vector3=global_position\n\tif p.x< -14 or p.x> -10 or p.z<128 or p.z>132:return';new='\tvar active:=false\n\tfor sampler:Node in get_parent().get_children():\n\t\tif sampler.has_method("_contact_failure") and bool(sampler.get("active")) and int(sampler.get("warmup_frames"))<=0:active=true;break\n\tif not active:return';assert old in traced;traced=traced.replace(old,new,1)
needle='\tvar hit:=_native_board_floor_ray(space,global_position+Vector3.UP*.2,global_position-Vector3.UP*3.0)';traced=traced.replace(needle,needle+'\n\tif not _d022_current.is_empty():_d022_current.flat_floor_probe=_d022_hit(hit)',1)
needle='\t\tvar time_to_floor:float=(velocity.y+sqrt(maxf(0.0,discriminant)))/RAMP_AIR_GRAVITY';traced=traced.replace(needle,needle+'\n\t\tif not _d022_current.is_empty():_d022_current.flat_budget={"angle":angle,"time":time_to_floor,"ready_before":_ramp_flat_visual_ready}',1)
needle='\tif (earned or _ramp_flat_visual_ready) and _ramp_flat_pose_clear(proposed*Basis(Vector3.UP,yaw)):';traced=traced.replace(needle,'\tif not _d022_current.is_empty():_d022_current.flat_earned=earned\n'+needle,1)
(P/'game/player/skater.gd').write_text(traced)
# Exact combined observer call order; only add a puregetter trace around Clyde.
probe=(R/'.local/motion_actual_round_focus.gd').read_text();late=(B/'candidate/.local/probe.gd').read_text();late=late[late.index('class Late extends Node:'):late.index('func _initialize()->void:')].replace('class Late extends Node:','class LateTrace extends Node:',1)
probe=probe.replace('func _initialize()->void:',late+'\nfunc _initialize()->void:',1)
probe=probe.replace(' await Clyde.run(self,game,_check)', ' var trace:=LateTrace.new();trace.game=game;root.add_child(trace)\n await Clyde.run(self,game,_check)',1)
probe=probe.replace(' var data:Dictionary={"passed":passes,', ' var controls:Dictionary=load("res://.local/handoff_controls.gd").run(game)\n var pipeline:Array=game.skater._d022_rows\n var late_models:Array=trace.rows\n trace.queue_free()\n var data:Dictionary={"passed":passes,',1)
probe=probe.replace('"modules":modules,','"modules":modules,"handoff_controls":controls,"physics_pose_pipeline":pipeline,"late_postCamera_models":late_models,',1)
probe=probe.replace(' quit(0 if failures.is_empty() else 1)',' quit(0 if failures.is_empty() and controls.passed else 1)',1)
(P/'.local/probe.gd').write_text(probe)
(O/'actual-source-at-copy.json').write_text(json.dumps(before,indent=2)+'\n')
(O/'scope.json').write_text(json.dumps({'status':'PRIVATEUNPARSEDUNRUN','base_controller_sha256':hashlib.sha256(base.encode()).hexdigest(),'clean_controller_sha256':hashlib.sha256(clean.encode()).hexdigest(),'baseline_anatomy_sha256':sha(P/'game/player/skater_anatomy.gd'),'scope':'Currentactual4895round+allParentguards+Anatomy691b, onlyownpose/constructor/air-sequence/additivehandoff methods overlaid. ExactMEcombinedobserver prefix preserved, puregettertrace+controls onlyAFTERClyde. Max9newquery qualified/1otherwise,24BrawAABB cache+2bool; no newMesh/Shape/Skin,4.5rad/s/currentnativefloor/footerproof unchangedbody/input/score.','cache':'Separatemetadata, read-onlyshared252resolvedimportedfiles before/after; noeditor/import/actualsourceautoload.'},indent=2)+'\n')
print('private04ready',hashlib.sha256(clean.encode()).hexdigest())
