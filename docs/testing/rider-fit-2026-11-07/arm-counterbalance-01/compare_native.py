from pathlib import Path
import json,numpy as np
P=Path(__file__).resolve().parent;D=P/'native-02';a=json.loads((D/'arm-control.json').read_text());b=json.loads((D/'arm-candidate.json').read_text());checks=[]
def ck(n,v,d=None):checks.append({'name':n,'pass':bool(v),'detail':d})
ck('Both nativephysical gates pass',a['failures']==b['failures']==0)
ck('657 paired realphysical observations',len(a['native_motion'])==len(b['native_motion'])==657)
peaks={};max_physical=0.;max_foot=0.;max_nonarm=0.;last={}
for x,y in zip(a['native_motion'],b['native_motion']):
 phase=x['phase'];ck('Same input phase '+phase+str(x['phase_step']),phase==y['phase']and x['phase_step']==y['phase_step']and x['state']['actions']==y['state']['actions'])
 for name in ['position','velocity']:
  err=float(np.max(np.abs(np.asarray(x['state'][name])-y['state'][name])));max_physical=max(max_physical,err)
 for name in ['actor','board','rider','upper','head','foot0','foot1']:
  err=float(np.max(np.abs(np.asarray(x['rig'][name])-y['rig'][name])));max_foot=max(max_foot,err)
 for i in [0,1,2,3,6,7,10]:max_nonarm=max(max_nonarm,float(np.max(np.abs(np.asarray(x['rig']['bones'][i])-y['rig']['bones'][i]))))
 ck('Exact foot clock '+phase+str(x['phase_step']),x['rig']['push_phase']==y['rig']['push_phase']and x['rig']['push_blend']==y['rig']['push_blend'])
 if phase not in peaks:peaks[phase]={'control_max_hand_relative_step_m':0.,'candidate_max_hand_relative_step_m':0.,'control_max_target_step_m':0.,'candidate_max_target_step_m':0.,'steps':[]}
 if phase in last:
  px,py=last[phase];vals=[]
  for row,prev in [(x,px),(y,py)]:
   body=np.asarray(row['rig']['actor'])[:3,3]-np.asarray(prev['rig']['actor'])[:3,3];v=max(np.linalg.norm(np.asarray(row['rig'][h])[:3,3]-np.asarray(prev['rig'][h])[:3,3]-body)for h in ['hand0','hand1']);target=.17*abs(row['rig']['arm_swing']-prev['rig']['arm_swing']);vals.append((float(v),float(target)))
  for k,(hand,target)in zip(['control','candidate'],vals):peaks[phase][k+'_max_hand_relative_step_m']=max(peaks[phase][k+'_max_hand_relative_step_m'],hand);peaks[phase][k+'_max_target_step_m']=max(peaks[phase][k+'_max_target_step_m'],target)
  peaks[phase]['steps'].append({'phase_step':x['phase_step'],'push_phase':x['rig']['push_phase'],'push_blend':x['rig']['push_blend'],'control_hand_step_m':vals[0][0],'candidate_hand_step_m':vals[1][0],'control_target_step_m':vals[0][1],'candidate_target_step_m':vals[1][1]})
 last[phase]=(x,y)
ck('Physical positions/velocities exact',max_physical==0,max_physical);ck('Feet/bodyfacing/head/board exact',max_foot==0,max_foot);ck('All seven nonarm bones exact',max_nonarm==0,max_nonarm)
for x,y in zip(a['endpoint_fixtures'],b['endpoint_fixtures']):
 ck('Full '+x['pose']+' bone/rig endpoints exact',all(x['final'][k]==y['final'][k]for k in ['actor','board','rider','upper','head','hand0','hand1','foot0','foot1','bones']))
 ck('Full '+x['pose']+' follows nonzero follower prime',abs(y['prime']['arm_swing'])>.01,y['prime']['arm_swing'])
report={'passed':sum(x['pass']for x in checks),'failed':sum(not x['pass']for x in checks),'checks':checks,'peaks':peaks,'scope':'Private native actualinput/currentpose data. Exactphysical/foot/facing andfull endpoint comparisons. Target andhandsteps measured, not newinvented cadence/M5/FPS orhumanvisual acceptance thresholds.'};(P/'native-comparison.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v for k,v in report.items()if k not in ['checks','peaks']},indent=2));print('peaks',{k:{a:b for a,b in v.items()if a!='steps'}for k,v in peaks.items()});print('FAILED',[x for x in checks if not x['pass']][:5])
