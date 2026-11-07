from pathlib import Path
import json,hashlib,re,numpy as np
from PIL import Image
P=Path(__file__).resolve().parent;T=P/'project';checks=[];sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def ck(n,v,d=None):checks.append({'name':n,'pass':bool(v),'detail':d})
def vec(s):return np.array([float(x)for x in s.strip('()').split(',')])if isinstance(s,str)else np.asarray(s,float)
R=json.loads((T/'tests/fitted-reference.json').read_text());reports={};maxmap=0.;maxskin=0.
for variant in ['control','candidate']:
 d=json.loads((T/'arm-replay-output'/variant/'receipt.json').read_text());reports[variant]=d;ck(variant+'eight clean complete poses',d['complete']and d['failures']==0 and len(d['frames'])==8);ck(variant+'input source stable',d['source_before']==d['source_after'])
 for f in d['frames']:
  label=f['label'];src=f['source_record'];r=src['row']['rig'];actual=f['native_state'];base=T/f['path'].removeprefix('res://');proof=T/'arm-replay-output'/variant/'synchronization'/(label+'.png')
  for p,h,rh in [(base,f['png_sha256'],f['native_rgba_sha256']),(proof,f['synchronization_png_sha256'],f['synchronization_native_rgba_sha256'])]:
   im=Image.open(p).convert('RGBA');ck(variant+label+p.parent.name+'exactpixels',im.size==(1280,800)and sha(p)==h and hashlib.sha256(im.tobytes()).hexdigest()==rh)
  for k,ak in [('rider','rider_global'),('board','board_global'),('head','head_global')]:
   e=float(np.abs(np.array(r[k])-np.array(actual[ak])).max());maxmap=max(maxmap,e);ck(variant+label+'recorded '+k+'map',e<8e-6,e)
  for k in ['hand0','hand1','foot0','foot1']:
   e=float(np.abs(np.array(r[k])-np.array(actual['native_limb_models'][k])).max());maxmap=max(maxmap,e);ck(variant+label+'recorded '+k+'map',e<8e-6,e)
  for i,name in enumerate(R['bone_names']):
   e=float(np.abs(np.array(r['bones'][i])-actual['bone_global_pose_in_skeleton'][name]).max());maxmap=max(maxmap,e);ck(variant+label+'recordedbone '+name,e<8e-6,e)
  for name,g in d['native_geometry'].items():
   for i,b in enumerate(g['binds']):
    cpu=np.array(actual['bone_global_pose_in_skeleton'][b['name']])@np.array(b['pose']);rs=np.array(actual['skin_state'][name]['rs_palette'][i]);e=float(np.abs(cpu-rs).max());maxskin=max(maxskin,e);ck(variant+label+name+' actualRS '+str(i),e<2e-6,e)
  for key in ['clean_readback_counter_bracket','proof_readback_counter_bracket']:ck(variant+label+key,f[key][0]==f[key][1])
  for key in ['clean_readback_pose_bracket','proof_readback_pose_bracket']:ck(variant+label+key,f[key][0]==f[key][1])
  ck(variant+label+'source physics clock retained',src['source_global_driver_step']==src['row']['phase_step']and src['row']['physics_frame']==src['row']['state']['physics_frame'])
  cam=np.array(actual['camera_global']);proj=np.array(actual['camera_projection_columns']).T;arr=np.array(Image.open(proof).convert('RGBA'))[:,:,:3].astype(np.int16)
  for i,m in enumerate(f['synchronization']):
   world=vec(m['world_position']);clip=proj@np.linalg.inv(cam)@np.r_[world,1];uv=(clip[:2]/clip[3]*[1,-1]+1)*[640,400];ep=vec(m['projected_pixel']);err=float(np.linalg.norm(uv-ep));ck(variant+label+'numeric projection'+str(i),err<.03,err)
   px,py=ep.astype(int);part=arr[max(0,py-12):min(800,py+13),max(0,px-12):min(1280,px+13)];mask=(part[:,:,i]>191)&(part[:,:,i]-part[:,:,(i+1)%3]>51)&(part[:,:,i]-part[:,:,(i+2)%3]>51);yy,xx=np.nonzero(mask);de=float(np.linalg.norm([xx.mean()+max(0,px-12)+.5-ep[0],yy.mean()+max(0,py-12)+.5-ep[1]]))if len(xx)else 1e9;ck(variant+label+'nativeRGB centroid'+str(i),len(xx)>=4 and de<2.5,de)
a=reports['control'];b=reports['candidate']
for x,y in zip(a['frames'],b['frames']):
 ck(x['label']+'matched camera',x['native_state']['camera_global']==y['native_state']['camera_global']and x['native_state']['camera_projection_columns']==y['native_state']['camera_projection_columns'])
 ck(x['label']+'matched feet/head/board',all(x['native_state'][k]==y['native_state'][k]for k in['head_global','rider_global','board_global'])and all(x['native_state']['native_limb_models'][k]==y['native_state']['native_limb_models'][k]for k in['foot0','foot1']))
report={'passed':sum(x['pass']for x in checks),'failed':sum(not x['pass']for x in checks),'max_source_pose_mapping_component_error':maxmap,'max_actualRS_CPU_component_error':maxskin,'checks':checks,'author_visual_review':'All16 exact clean buffers personally opened as8 native-size lossless topcontrol/bottomcandidate pairs. Push69→70 wristmotion is reduced; selected release and popcatch endpoints show no new visible break. These are sparse currentpose replays, not normal-speed cadence or actualcity/interpolation evidence.','scope':'PRIVATE source-current nativepose replay integrity only. Floating world-to-parent application bound8µm is a data-replay mapping bound, not a relaxed physicalcontact tolerance. All actualsource feet/physics/body trajectories were already exact in nativecomparison1323/0.'};(P/'replay-audit.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items()if k!='checks'},indent=2));print('FAILED',[x for x in checks if not x['pass']][:5])
