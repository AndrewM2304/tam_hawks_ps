#!/usr/bin/env python3
"""Read-only portable evidence verifier; Python3, Pillow, NumPy and SciPy."""
import gzip,hashlib,io,json,pathlib,sys,zipfile
import numpy as np
from PIL import Image
from scipy.spatial import cKDTree
D=pathlib.Path(sys.argv[1]) if len(sys.argv)>1 else pathlib.Path(__file__).resolve().parent
load=lambda n:json.loads((D/n).read_text());sha=lambda b:hashlib.sha256(b).hexdigest();checks=[]
def ck(n,v,d=None):checks.append({'name':n,'pass':bool(v),'detail':d})
def matrix(x):
 a=np.asarray(x,float);assert a.shape==(4,4) and np.isfinite(a).all();return a
M=load('manifest.json');X=load('exact-buffer-index.json');G=json.loads(gzip.decompress((D/'native-rig-geometry.json.gz').read_bytes()))['geometry'];R=json.loads(gzip.decompress((D/'fitted-reference.json.gz').read_bytes()));rows=[json.loads(x) for x in gzip.decompress((D/'native-rig-readbacks.jsonl.gz').read_bytes()).splitlines()];byfile={r['relative_file']:r for r in rows}
frames=M['synchronization_proofs']+[f for c in M['clips'] for f in c['frames']];fs={f['file']:f for f in frames};ck('354-native-buffers',len(X)==len(rows)==len(fs)==354)
ck('879-source-before-after-pins',load('source-before.json')==load('source-after.json') and len(load('source-before.json'))==879)
with zipfile.ZipFile(D/'executed-source-delta.zip') as z:
 delta=load('source-reproduction.json')['delta_files'];ck('exact-source-delta-members',set(z.namelist())=={f['path'] for f in delta});ck('exact-source-delta-hashes',all(sha(z.read(f['path']))==f['sha256']==load('source-before.json')[f['path']] for f in delta))
with zipfile.ZipFile(D/'exact-native-buffers.zip') as z:
 ck('exact-buffer-members',set(z.namelist())=={x['member'] for x in X})
 for x in X:
  b=z.read(x['member']);im=Image.open(io.BytesIO(b)).convert('RGBA');f=fs[x['original_file']];r=byfile[x['original_file']];ck('pixel-'+x['original_file'],im.size==(640,400) and sha(b)==x['webp_sha256'] and sha(im.tobytes())==x['native_rgba8_sha256']==f['pixels']['rgba8_sha256']==r['rgba8_sha256']);ck('original-PNG-hash-binding-'+x['original_file'],x['original_png_sha256']==f['sha256'])
  ck('native-fence-'+x['original_file'],r['before_current']==r['after_current'] and r['counters_before']==r['counters_after'] and r['camera_before']==r['camera_after'] and r['row']==f['pixels']['native_skin_sidecar_row'])
  if 'state' in f:ck('state-pixel-row-'+x['original_file'],r['native_step']==f['native_step'] and r['counters_after']=={'physics':f['state']['physics_frame'],'process':f['state']['process_frame']})
  else:
   arr=np.asarray(im);cx,cy=f['canvas_pixel'];ck('Canvas-'+f['id'],list(arr[cy,cx])==f['canvas_expected']);cam=r['camera_after'];P=matrix(cam['projection']);V=np.linalg.inv(matrix(cam['model']))
   for j,mark in enumerate(f['markers']):
    q=P@V@np.r_[mark['world'],1];uv=(q[:2]/q[3]*[1,-1]+1)*[320,200];ep=np.array(mark['projected_pixel']);ck('camera-projection-'+f['id']+str(j),np.linalg.norm(uv-ep)<.03,float(np.linalg.norm(uv-ep)))
    px,py=ep.astype(int);patch=arr[max(0,py-12):min(400,py+13),max(0,px-12):min(640,px+13),:3].astype(np.int16);i={'red':0,'green':1}[mark['color_channel']];mask=(patch[:,:,i]>191)&(patch[:,:,i]-patch[:,:,(i+1)%3]>51)&(patch[:,:,i]-patch[:,:,(i+2)%3]>51);yy,xx=np.nonzero(mask);err=float(np.linalg.norm([xx.mean()+max(0,px-12)+.5-ep[0],yy.mean()+max(0,py-12)+.5-ep[1]])) if len(xx) else 1e9;ck('image-marker-'+f['id']+str(j),len(xx)>=4 and err<2.5,err)
sourceids={}
for n in ['UpperChest','SkinnedJacket','SkinnedTrousers']:
 d,ix=cKDTree(np.asarray(G[n]['vertices'])).query(R['parts'][n]['attributes']['POSITION']);ck('source-native-rest-'+n,max(d)<8e-6,float(max(d)));sourceids[n]={sid:int(ix[j]) for j,sid in enumerate(R['parts'][n]['source_ids'])}
d,hi=cKDTree(np.asarray(G['head']['vertices'])).query([p['local'] for p in R['head_rim']]);ck('46-unique-rim-47-UV-rows',len(hi)==47 and len({p['source_id'] for p in R['head_rim']})==46 and max(d)<8e-6)
ci=np.array([sourceids['UpperChest'][p['source_id']] for p in R['head_rim']]);waist=sorted({i for edge in R['waist_edges'] for i in edge});wi={n:np.array([sourceids[n][i] for i in waist]) for n in ['SkinnedJacket','SkinnedTrousers']};ck('100-real-waist-edges',len(R['waist_edges'])==100 and len(waist)==100)
def deform(n,ix,row,rendered):
 g=G[n];p=np.c_[np.asarray(g['vertices'])[ix],np.ones(len(ix))];js=np.asarray(g['bones']).reshape(-1,4)[ix];w=np.asarray(g['weights']).reshape(-1,4)[ix];e=row['after_rendered']['native_skin_palettes'][n]
 if rendered:pal=np.asarray(e['palette']);model=matrix(e['mesh_rendered'])
 else:pal=np.array([matrix(row['after_current']['bones'][R['bone_names'].index(b['name'])])@matrix(b['pose']) for b in g['binds']]);model=matrix(e['mesh_current'])
 xyz=np.sum(w[:,:,None]*np.einsum('nkij,nj->nki',pal[js],p)[:,:,:3],axis=1);return (model@np.c_[xyz,np.ones(len(xyz))].T).T[:,:3]
maxg={'neck_current':0.,'neck_rendered':0.,'waist_current':0.,'waist_rendered':0.}
for c in M['clips']:
 F=c['frames'];ck('117consecutive-'+c['id'],len(F)==117 and all(b['native_step']==a['native_step']+1 and b['state']['physics_frame']==a['state']['physics_frame']+1 for a,b in zip(F,F[1:])));ck('72press45release-'+c['id'],all(f['state']['actions'].get('push',0)>0 for f in F[:72]) and all(f['state']['actions'].get('push',0)==0 for f in F[72:]));ck('viewing-movie-hash-'+c['id'],sha((D/c['video']['file']).read_bytes())==c['video']['sha256'])
 for f in F:
  row=byfile[f['file']]
  for render in [False,True]:
   clock='rendered' if render else 'current';hm=matrix(row['after_rendered']['nodes']['head_mesh']['model'] if render else row['after_current']['nodes']['head_mesh']);hp=(hm@np.c_[np.asarray(G['head']['vertices'])[hi],np.ones(len(hi))].T).T[:,:3];ng=float(np.linalg.norm(hp-deform('UpperChest',ci,row,render),axis=1).max());wg=float(np.linalg.norm(deform('SkinnedJacket',wi['SkinnedJacket'],row,render)-deform('SkinnedTrousers',wi['SkinnedTrousers'],row,render),axis=1).max());maxg['neck_'+clock]=max(maxg['neck_'+clock],ng);maxg['waist_'+clock]=max(maxg['waist_'+clock],wg);ck('Skin-source-seams-'+clock+'-'+f['file'],ng<2e-5 and wg<2e-5)
report={'scope':'Portable saved-buffer/geometry/matrix/source-delta verification only. Human normal-speed art, finalresolution, unrecorded phases, FPS, M5 and AAA remain separate. Source Git base needed for full runtime reproduction; no engine launched.','passed':sum(c['pass'] for c in checks),'failed':sum(not c['pass'] for c in checks),'max_native_attachment_gap_m':maxg,'checks':checks};(D/'portable-verification.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k!='checks'},indent=2));sys.exit(bool(report['failed']))
