"""Strict timing admission for the declared old/new bail workload, not equal views."""
import json,sys
from pathlib import Path
root=Path(sys.argv[1]);labels=['original-before','candidate','original-after']
def quantiles(v):
    v=sorted(v);return {str(q):v[min(len(v)-1,int(q*len(v)))]for q in [0,.5,.95,.99,1]}
raw={label:json.loads((root/(label+'.json')).read_text())for label in labels};summaries={}
for label,p in raw.items():
    width=len(p['columns']);rows=[p['data'][i:i+width]for i in range(0,len(p['data']),width)]
    frames=[(b[0]-a[0])/1000 for a,b in zip(rows,rows[1:])]
    summaries[label]={'rows':len(rows),'frame_ms':quantiles(frames),'pose_update_usec':quantiles(p['pose_update_usec']),'physics_process_usec':quantiles([r[14]for r in rows]),'draws':quantiles([r[11]for r in rows]),'triangles':quantiles([r[12]for r in rows]),'static_bytes':quantiles([r[13]for r in rows]),'memory':p['memory'],'long_frames_33ms':sum(x>100/3 for x in frames),'seconds':(rows[-1][0]-rows[0][0])/1e6,'bails':p['bails'],'restarts':p['restarts'],'maximum_bail_tick_step_m':p['maximum_bail_tick_step_m'],'input_reassertions':p['input_reassertions']}
gates={}
for q in ['0.95','0.99']:
    a,b,c=[summaries[x]['frame_ms'][q]for x in labels];middle=(a+c)/2;envelope=middle+abs(a-c)+middle*.05;ceiling=max(a,c)*1.05
    gates[q]={'candidate_ms':b,'control_ms':[a,c],'envelope_ms':envelope,'worst_control_ceiling_ms':ceiling,'pass':b<=envelope and b<=ceiling}
result={'pass':all(g['pass']for g in gates.values())and all(s['seconds']>=30 and s['bails']==4 and s['restarts']==5 and s['draws']['0']>0 for s in summaries.values())and summaries['candidate']['maximum_bail_tick_step_m']<.3 and all(not p['errors']for p in raw.values()),'strict_render_gates':gates,'summaries':summaries,'limits':'Matched fixed input/timing/settings and fresh Main scenes against pinned83758c3 project controls, warmup excluded. Bail movement and camera view intentionally change; no identical-physics/view claim, no PNG readbacks, cold-memory or whole-map/stutter/human claim.'}
(root/'comparison.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2));raise SystemExit(0 if result['pass']else 1)
