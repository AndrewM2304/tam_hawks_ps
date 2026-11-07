from pathlib import Path
import difflib,shutil
B=Path('.local/c04-landing-continuity')
for mode in ['baseline','candidate']:
 p=B/mode/'game/player/skater.gd';s=p.read_text();before=s
 old='\tvar p:Vector3=global_position\n\tif p.x< -14 or p.x> -10 or p.z<128 or p.z>132:return'
 new='''\tvar active:=false
	for sampler:Node in get_parent().get_children():
		if sampler.has_method("_contact_failure") and bool(sampler.get("active")) and int(sampler.get("warmup_frames"))<=0:active=true;break
	if not active:return'''
 assert old in s;s=s.replace(old,new,1)
 # Add raw floor/contact state without hidden fallback native rays.
 marker='\t_d022_current={"physics":'
 line=next(l for l in s.splitlines()if l.startswith(marker))
 s=s.replace(line,line+'\n\t_d022_current.raw_floor_normal=_d022_vec(get_floor_normal())\n\t_d022_current.transition_normal=_d022_vec(transition_normal)\n\tif _ramp_air:\n\t\tvar ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.2,global_position-Vector3.UP*3.0,collision_mask,[get_rid()])\n\t\tvar probe:Dictionary=get_world_3d().direct_space_state.intersect_ray(ray)\n\t\t_d022_current.ramp_native_floor_probe=_d022_hit(probe)\n\t\tvar raw:Variant=probe.get("collider")\n\t\tvar feature:Node3D=_feature_transition.feature\n\t\t_d022_current.probe_owned_by_associated_feature=is_instance_valid(feature) and raw is Node and (feature.is_ancestor_of(raw) or (feature.has_method("owns_native_wheel_support") and bool(feature.owns_native_wheel_support(raw))))',1)
 # Capture the real existing selected support dictionary/pose.
 old='\t\t_visual.basis = support_basis * Basis(Vector3.UP, visual_yaw)\n\telse:'
 new='\t\t_visual.basis = support_basis * Basis(Vector3.UP, visual_yaw)\n\t\tif not _d022_current.is_empty():_d022_current.after_ground_support={"pose":_d022_capture(),"board_floor":_d022_hit(board_floor),"normal":_d022_vec(ground_normal)}\n\telse:'
 assert old in s;s=s.replace(old,new,1)
 # Preserve source implementations exactly; wrappers add getters only.
 for name,args,passed in [('native_support','visual_yaw:float','visual_yaw'),('transition','',''),('manual','',''),('obstacle','delta: float','delta')]:
  fn='_place_'+name+'_wheels';needle='func '+fn+'('+args+') -> void:' if name=='obstacle' else 'func '+fn+'('+args+') -> void:'
  # Native/manual/transition spacing differs in the original source.
  import re
  pattern=r'func '+fn+r'\([^\n]*\)\s*->\s*void:'
  m=re.search(pattern,s);assert m,(mode,name)
  original=m.group(0);renamed=original.replace('func '+fn+'(','func '+fn+'_d022_unobserved(',1)
  wrapper='func '+fn+'('+args+')->void:\n\tif not _d022_current.is_empty():_d022_current.'+name+'_before=_d022_capture()\n\t'+fn+'_d022_unobserved('+passed+')\n\tif not _d022_current.is_empty():_d022_current.'+name+'_after=_d022_capture()\n\n\n'
  s=s[:m.start()]+wrapper+renamed+s[m.end():]
 # Fresh native ray face identity is useful for exact finite footprint tests.
 s=s.replace('"shape":h.get("shape",-1),"path":', '"shape":h.get("shape",-1),"face_index":h.get("face_index",-1),"path":',1)
 p.write_text(s);(B/(mode+'-fullbank-extra-instrumentation.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(keepends=True),s.splitlines(keepends=True))))
 p=B/mode/'.local/probe.gd';s=p.read_text();old='\t\tvar p:Vector3=r.global_position\n\t\tif p.x< -14 or p.x> -10 or p.z<128 or p.z>132:return';new='''\t\tvar active:=false
		for sampler:Node in game.get_children():
			if sampler.has_method("_contact_failure") and bool(sampler.get("active")) and int(sampler.get("warmup_frames"))<=0:active=true;break
		if not active:return''';assert old in s;s=s.replace(old,new,1);p.write_text(s)
s=(B/'run.py').read_text().replace("MODE+'-01'", "MODE+'-02-fullbank'")
(B/'run02.py').write_text(s)
print('fullbankdiagnosticextended')
