from pathlib import Path
import shutil,subprocess,json,hashlib,importlib.util,numpy as np
R=Path.cwd(); OUT=R/'.local/fitted-rig-admission'; P=OUT/'epoch-01/project'; RA=R/'.local/rider-fit-staging/project'; A=R/'.local/rider-fit-staging/release-reproduction-v11-final'
assert not P.exists()
P.mkdir(parents=True)
for name in ['game','tests','.godot']:
 subprocess.run(['cp','-a','--reflink=auto',str(R/name),str(P/name)],check=True)
shutil.copy2(R/'project.godot',P/'project.godot')
subprocess.run(['cp','-a',str(RA/'.godot')+'/.',str(P/'.godot')],check=True)
manifest=json.loads((A/'fitted-manifest.json').read_text())
for name,entry in manifest['outputs'].items():
 data=(A/name).read_bytes(); assert hashlib.sha256(data).hexdigest()==entry['sha256'];(P/'game/art/rider'/name).write_bytes(data)
for name in ['skater_anatomy.gd','skater_garments.gd','skater_footwear.gd']:
 shutil.copy2(RA/'game/player'/name,P/'game/player'/name)
# Apply only the actual fitted-build and final-head hooks to CURRENT visual.
path=P/'game/player/skater_visual.gd'; t=path.read_text()
for old in ['\tshoes.albedo_texture = preload("res://game/art/rider/suede_albedo.png")\n\tshoes.normal_enabled = true\n\tshoes.normal_texture = preload("res://game/art/rider/suede_normal.png")\n\tshoes.normal_scale = 0.42\n','\t_loft(_upper, "JacketHem", [Vector4(0.016, 0.177, 0.128, 0), Vector4(0.035, 0.178, 0.128, 0)], seams)\n\t_build_collar(_upper, shirt)\n\t_build_zipper(_upper, dark)\n\tfor side: float in [-1.0, 1.0]:\n\t\t_segment(_upper, "PocketSeam", Vector3(side * 0.065, 0.13, -0.117), Vector3(side * 0.125, 0.19, -0.107), 0.002, seams)\n']:
 assert t.count(old)==1;t=t.replace(old,'')
t=t.replace('Footwear.build(foot, shoes, rubber, seams)','Footwear.build(foot, shoes, rubber, seams, side)')
assert t.count('\nfunc _native_grab_pose(')==1;t=t.replace('\nfunc _native_grab_pose(','\n\t_garments.pose_head(_upper.transform * _head.transform)\n\nfunc _native_grab_pose(')
assert 'var balance_axis := Vector3.UP.cross(deck_back)' in t
path.write_text(t)
for name in ['skater_visual.gd.patch','skater.gd.patch']:
 subprocess.run(['patch','-p1','--batch','--fuzz=0','-i',str(R/'.local/per-leg-sole-proposal'/name)],cwd=P,check=True)
shutil.copy2(R/'.local/per-leg-sole-proposal/per_leg_sole_contract.gd',P/'tests/per_leg_sole_contract.gd')
s=importlib.util.spec_from_file_location('v',R/'.local/rider-rig-validation/validate_offline.py');v=importlib.util.module_from_spec(s);s.loader.exec_module(v)
d,blob=v.read_glb(A/'fitted_outfit.glb'); meta=json.loads((A/'fitted_landmarks.json').read_text()); skin=d['skins'][0]
ref={'asset_sha256':manifest['outputs']['fitted_outfit.glb']['sha256'],'metadata_sha256':manifest['outputs']['fitted_landmarks.json']['sha256'],'parts':{},'bone_names':[d['nodes'][n]['name'] for n in skin['joints']],'binds':v.accessor(d,blob,skin['inverseBindMatrices']).reshape((-1,4,4)).transpose(0,2,1).tolist(),'waist_edges':meta['waist_seam_correspondence']['source_vertex_edges'],'waist_positions':meta['waist_seam_correspondence']['game_rest_endpoint_positions_m'],'head_rim':[]}
for mesh in d['meshes']:
 name=mesh['name'];pr=mesh['primitives'][0];attrs={k:v.accessor(d,blob,i).tolist() for k,i in pr['attributes'].items()}; ids=meta[name]['mesh_vertex_to_source_body_vertex' if name=='UpperChest' else 'mesh_vertex_to_source_obj_vertex'];tri=v.accessor(d,blob,pr['indices']).reshape((-1,3)).tolist()
 ref['parts'][name]={'attributes':attrs,'source_ids':ids,'triangles':tri,'source_triangles':[[ids[i] for i in t] for t in tri]}
pts,uv,norm,faces,_=v.obj(A/'fitted_head.obj'); counts={}
for f in faces:
 for a,b in zip(f,f[1:]+f[:1]):
  e=tuple(sorted((a[0],b[0])));counts[e]=counts.get(e,0)+1
edges=[e for e,n in counts.items() if n==1 and max(pts[list(e),1])<-.065];headids={x for e in edges for x in e};assert len(edges)==len(headids)==46
h0=np.array(meta['UpperChest']['neck_rest_matrix_rows']);h0i=np.linalg.inv(h0)
for item in meta['UpperChest']['head_boundary_correspondence']:
 p=(h0i@np.r_[item['game_rest_position_m'],1])[:3]; candidates=[i for i in headids if np.linalg.norm(pts[i]-p)<1e-6];assert len(candidates)==1
 ref['head_rim'].append({'source_id':item['source_body_vertex'],'local':pts[candidates[0]].tolist(),'uv':item['uv']})
assert len({x['source_id'] for x in ref['head_rim']})==46
(P/'tests/fitted-reference.json').write_text(json.dumps(ref,separators=(',',':')))
(OUT/'epoch-01/preparation.json').write_text(json.dumps({'source_manifest':str(A/'fitted-manifest.json'),'selected_manifest_sha256':hashlib.sha256((A/'fitted-manifest.json').read_bytes()).hexdigest(),'overlays':['RA Anatomy/Garments/Footwear','RA fitted-build and final pose_head hooks on actual current Visual','ME exact per-leg Visual/controller proposal, original Manual axis retained'],'source_runtime_sha256':{str(p.relative_to(RA)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (RA/'game/player').glob('*.gd')},'project':str(P),'scope':'Private source preparation only. No native acceptance yet.'},indent=2)+'\n')
print(P)
