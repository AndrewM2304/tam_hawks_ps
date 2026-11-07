from pathlib import Path
import subprocess,json,time,datetime,os
r=Path('/workspace/tam_hawks_ps');out=r/'.local/qa-fidelity/native-review/forecast-192-retake-02-lease.json';start=time.monotonic();deadline=start+360;commands=[]
env=dict(os.environ,QA_LEASE_DEADLINE_MONOTONIC=str(deadline))
for view in ['side','chase']:
 if time.monotonic()>=deadline-15:break
 cmd=['python3',str(r/'.local/qa-fidelity/run_forecast_motion_review.py'),'forecast-192-'+view+'-02','capture',view]
 rec={'view':view,'command':cmd,'start_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()};print('START',view,rec['start_utc'],flush=True)
 code=subprocess.run(cmd,cwd=r,env=env).returncode;rec.update(exit=code,finish_utc=datetime.datetime.now(datetime.timezone.utc).isoformat());commands.append(rec)
 out.write_text(json.dumps({'started_monotonic':start,'deadline_monotonic':deadline,'elapsed_seconds':time.monotonic()-start,'commands':commands,'complete':len(commands)==2,'integrity_pass':len(commands)==2 and all(x['exit']==0 for x in commands),'scope':'Root-approved fresh combined≤360s qualitative side32/chase3. Known rigging pilot may overlap; all native process rows retained in individual packets; no timing/performance or AAA claim.'},indent=2)+'\n')
 if code:break
print('COMBINED_FINISHED',time.monotonic()-start,commands,flush=True)
