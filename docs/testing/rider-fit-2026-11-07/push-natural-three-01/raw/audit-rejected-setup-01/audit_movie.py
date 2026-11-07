#!/usr/bin/env python3
"""Offline author audit. No game process, source mutation, resampling, or acceptance of art."""
import ast,hashlib,json,pathlib,re,subprocess,sys
import numpy as np
from PIL import Image
from scipy.spatial import cKDTree
H=pathlib.Path(__file__).resolve().parent
E=H/'epochs/push351-20261107T101940Z';Q=E/'project'
O=next((Q/'.local').glob('full-fidelity-*'))
load=lambda p:json.loads(p.read_text())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def ck(name,ok,detail=None):
 checks.append({'name':name,'pass':bool(ok),'detail':detail})
def matrix(x):
 a=np.asarray(x,float); assert a.shape==(4,4) and np.isfinite(a).all();return a
M=load(O/'manifest.json'); G=load(O/'native-rig-geometry.json')['geometry'];R=load(Q/'tests/fitted-reference.json');rows=[json.loads(l) for l in (O/'native-rig-readbacks.jsonl').read_text().splitlines()];byfile={x['relative_file']:x for x in rows}
B=load(E/'source-before.json'); A=load(E/'source-after.json');C=load(E/'copy-epoch.json');L=load(E/'launch-receipt.json')
ck('source-879-before-after-identical', B==A and len(B)==879)
ck('all-executed-source-pins',all((Q/p).is_file() and sha(Q/p)==v for p,v in B.items()))
ck('all-base-source-pins-except-recorded-observer-delta',all((Q/p).is_file() and (sha(Q/p)==v or p=='tools/full_fidelity_capture.gd') for p,v in C['source_sha256'].items()))
ck('compiled-caches-by-value',all((Q/p).is_file() and not (Q/p).is_symlink() and sha(Q/p)==v for p,v in C['compiled_cache_sha256'].items()))
ck('copy-epoch-owner-hash',sha(E/'copy-epoch.json')==L['copy_epoch_sha256'])
ck('owner-clean-complete',L['returncode']==0 and L['failure'] is None and L['source_unchanged'])
ck('native3772-0',M['checks']==3772 and M['failures']==0)
ck('full657-seven-physical-trace',len(M['native_timeline'])==657 and len(M['observed_phase_ids'])==7)
ck('three-selected-four-unreviewed',len(M['recorded_phase_ids'])==3 and len(M['unrecorded_phase_ids'])==4 and not M['visual_phase_coverage_complete'])
ck('native640x400-60Hz',M['native_capture_size']==[640,400] and M['motion_sample_hz']==60 and M['physics_hz']==60)
ck('354-native-sidecar-rows',len(rows)==354 and len(byfile)==354)
# Physical input, state collection and selection code must be byte-identical to base.
def gd_function(text,name):
 m=re.search(r'^func '+re.escape(name)+r'\([^\n]*',text,re.M);assert m,name
 n=re.search(r'^func ',text[m.end():],re.M);return text[m.start():m.end()+n.start() if n else len(text)]
base=(E/'actual-base-capture.gd').read_text();candidate=(Q/'tools/full_fidelity_capture.gd').read_text()
for fn in ['_run','_observe','_snapshot']:
 ck('unchanged-driver-'+fn,gd_function(base,fn)==gd_function(candidate,fn))
# Map actual native vertex order by original rest positions, never assume imported array ordering.
map_indices={};source_ids={}
for name in ['UpperChest','SkinnedJacket','SkinnedTrousers']:
 v=np.asarray(G[name]['vertices']);rp=np.asarray(R['parts'][name]['attributes']['POSITION']);d,ix=cKDTree(v).query(rp)
 ck('native-rest-source-map-'+name,d.max()<8e-6,float(d.max()))
 map_indices[name]=ix;source_ids[name]={sid:int(ix[j]) for j,sid in enumerate(R['parts'][name]['source_ids'])}
rim=np.asarray([x['local'] for x in R['head_rim']]);hd,headix=cKDTree(np.asarray(G['head']['vertices'])).query(rim);ck('actual46-head-rim-map',len(rim)==46 and hd.max()<8e-6,float(hd.max()))
chestix=np.array([source_ids['UpperChest'][x['source_id']] for x in R['head_rim']])
waist=np.array(sorted({i for edge in R['waist_edges'] for i in edge}));wi={n:np.array([source_ids[n][int(i)] for i in waist]) for n in ['SkinnedJacket','SkinnedTrousers']};ck('actual100-waist-edges',len(R['waist_edges'])==100 and len(waist)==100)
def deform(name,indices,row,rendered):
 g=G[name];points=np.c_[np.asarray(g['vertices'])[indices],np.ones(len(indices))];j=np.asarray(g['bones']).reshape(-1,4)[indices];w=np.asarray(g['weights']).reshape(-1,4)[indices]
 if rendered:
  entry=row['after_rendered']['native_skin_palettes'][name];pal=np.asarray(entry['palette']);model=matrix(entry['mesh_rendered'])
 else:
  bones=np.asarray(row['after_current']['bones']);pal=np.array([bones[R['bone_names'].index(b['name'])]@matrix(b['pose']) for b in g['binds']]);model=matrix(row['after_rendered']['native_skin_palettes'][name]['mesh_current'])
 # Godot shader transforms raw weighted LOCAL XYZ, then applies MODEL with homogeneous W=1.
 xyz=np.sum(w[:,:,None]*np.einsum('nkij,nj->nki',pal[j],points)[:,:,:3],axis=1)
 return (model@np.c_[xyz,np.ones(len(xyz))].T).T[:,:3]
maxgap={k:0. for k in ['neck_current','neck_rendered','waist_current','waist_rendered']};details=[]
allframes=[]
for clip in M['clips']:
 frames=clip['frames'];ck('117-consecutive-'+clip['id'],len(frames)==117 and all(b['native_step']-a['native_step']==1 and b['state']['physics_frame']-a['state']['physics_frame']==1 for a,b in zip(frames,frames[1:])))
 ck('72pressed45release-'+clip['id'],all(f['state']['actions'].get('push',0)>0 for f in frames[:72]) and all(f['state']['actions'].get('push',0)==0 for f in frames[72:]))
 ck('video-exact-stream-'+clip['id'],clip['video']['stream']=={'codec_name':'h264','width':640,'height':400,'r_frame_rate':'60/1','duration':'1.950000','nb_frames':'117'} and sha(O/clip['video']['file'])==clip['video']['sha256'])
 p=subprocess.run(['ffmpeg','-v','error','-i',str(O/clip['video']['file']),'-f','null','-'],capture_output=True)
 ck('video-full-decode-'+clip['id'],p.returncode==0 and not p.stderr,p.stderr.decode()[:200])
 allframes.extend(frames)
for f in M['synchronization_proofs']+allframes:
 path=O/f['file'];r=byfile[f['file']];im=Image.open(path).convert('RGBA');rgba=im.tobytes();ah=hashlib.sha256(rgba).hexdigest()
 ck('native-pixel-'+f['file'],im.size==(640,400) and sha(path)==f['sha256'] and ah==f['pixels']['rgba8_sha256']==r['rgba8_sha256'])
 ck('readback-fence-'+f['file'],r['counters_before']==r['counters_after'] and r['before_current']==r['after_current'] and r['camera_before']==r['camera_after'] and r['row']==f['pixels']['native_skin_sidecar_row'] and r['bytes']==1024000)
 if 'state' not in f:continue
 ck('state-counter-binding-'+f['file'],r['counters_after']=={'physics':f['state']['physics_frame'],'process':f['state']['process_frame']} and r['native_step']==f['native_step'])
 for rendered in [False,True]:
  stage='rendered' if rendered else 'current';hmodel=matrix(r['after_rendered']['nodes']['head_mesh']['model'] if rendered else r['after_current']['nodes']['head_mesh']);hp=(hmodel@np.c_[np.asarray(G['head']['vertices'])[headix],np.ones(46)].T).T[:,:3]
  ng=float(np.linalg.norm(hp-deform('UpperChest',chestix,r,rendered),axis=1).max());wg=float(np.linalg.norm(deform('SkinnedJacket',wi['SkinnedJacket'],r,rendered)-deform('SkinnedTrousers',wi['SkinnedTrousres'] if 'SkinnedTrousres' in wi else wi['SkinnedTrousers'],r,rendered),axis=1).max());maxgap['neck_'+stage]=max(maxgap['neck_'+stage],ng);maxgap['waist_'+stage]=max(maxgap['waist_'+stage],wg)
  ck('46neck100waist-'+stage+'-'+f['file'],ng<2e-5 and wg<2e-5,{'neck_m':ng,'waist_m':wg})
 ck('neutral-hand038-native-'+f['file'],all(abs(x['values'][0]-.38)<1e-6 for x in r['after_rendered']['hand_morphs'].values()))
 cam=r['camera_after'];matrix(cam['model']);matrix(cam['projection'])
 details.append({'file':f['file'],'phase':next(c['id'] for c in M['clips'] if f in c['frames']),'native_step':r['native_step'],'physics':r['counters_after']['physics'],'push_phase':f['state']['push_phase'],'push_blend':f['state']['push_blend'],'rear_sole_marker':f['state']['rear_sole'],'speed':f['state']['speed']})
# Independently recompute the proof camera projection and image centroid.
for f in M['synchronization_proofs']:
 r=byfile[f['file']];cam=r['camera_after'];P=matrix(cam['projection']);V=np.linalg.inv(matrix(cam['model']));arr=np.asarray(Image.open(O/f['file']).convert('RGBA'));x,y=f['canvas_pixel'];ck('sync-canvas-'+f['id'],list(arr[y,x])==f['canvas_expected'])
 for k,mark in enumerate(f['markers']):
  q=P@V@np.r_[mark['world'],1.];uv=(q[:2]/q[3]*[1,-1]+1)*[320,200];expected=np.array(mark['projected_pixel']);ck('numeric-marker-projection-'+f['id']+str(k),np.linalg.norm(uv-expected)<.03,float(np.linalg.norm(uv-expected)))
  px,py=expected.astype(int);patch=arr[max(0,py-12):min(400,py+13),max(0,px-12):min(640,px+13),:3];ci={'red':0,'green':1,'blue':2}[mark['color_channel']];mask=(patch[:,:,ci]>180)&(patch[:,:,(ci+1)%3]<100)&(patch[:,:,(ci+2)%3]<100);yy,xx=np.nonzero(mask);err=float(np.linalg.norm([xx.mean()+max(0,px-12)+.5-expected[0],yy.mean()+max(0,py-12)+.5-expected[1]])) if len(xx) else 1e9;ck('independent-marker-centroid-'+f['id']+str(k),len(xx)>=4 and err<2.5,{'pixels':len(xx),'error_px':err})
report={'scope':'Author offline source/pixel/driver/camera and native actual Skin continuity audit,351 consecutive640x400/60Hz frames. Not a human normal-speed watch, finalresolution, complete repertoire, FPS, M5, art or AAA acceptance. Brake/pop remain visually unreviewed.','checks':len(checks),'failures':sum(not x['pass'] for x in checks),'max_native_attachment_gap_m':maxgap,'clips':[{'id':c['id'],'frames':len(c['frames']),'camera':c['camera']} for c in M['clips']],'source_count':len(B),'compiled_cache_count':len(C['compiled_cache_sha256']),'native_readbacks':len(rows),'checks_detail':checks,'inputs':{str(p.relative_to(E)):sha(p) for p in [E/'copy-epoch.json',E/'launch-receipt.json',O/'manifest.json',O/'native-rig-geometry.json',O/'native-rig-readbacks.jsonl']}}
(E/'author-offline-audit.json').write_text(json.dumps(report,indent=2)+'\n');(E/'native-motion-summary.json').write_text(json.dumps(details,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items() if k not in ['checks_detail','inputs']},indent=2));print('FAILED',json.dumps([x for x in checks if not x['pass']][:8],indent=2));sys.exit(bool(report['failures']))
