from pathlib import Path
import json,math
root=Path('.local/fountain-ornament-captures')
phases={name:json.loads((root/name/'manifest.json').read_text()) for name in ['original-a','profile','original-b']}
def percentile(values,q):
 data=sorted(values);return data[max(0,math.ceil(len(data)*q)-1)]
def summary(rows):
 ts=[r['ms'] for r in rows]
 return {'samples':len(ts),'p50_ms':percentile(ts,.5),'p95_ms':percentile(ts,.95),'p99_ms':percentile(ts,.99),'max_ms':max(ts),'over_16_667_ms':sum(v>1000/60 for v in ts),'over_33_333_ms':sum(v>1000/30 for v in ts),'over_50_ms':sum(v>50 for v in ts),**{k:{'min':min(r[k] for r in rows),'max':max(r[k] for r in rows)} for k in rows[0] if k!='ms'}}
views=[]
for name in ['cup-overhead','court-approach']:
 raw={phase:next(v for v in data['views'] if v['view']==name)['rows'] for phase,data in phases.items()}
 summaries={phase:summary(rows) for phase,rows in raw.items()}
 timing={}
 for key in ['p95_ms','p99_ms']:
  a,b,c=[summaries[p][key] for p in ['original-a','profile','original-b']]
  midpoint=(a+c)/2;spread=midpoint+abs(a-c)+.05*midpoint;worse=1.05*max(a,c)
  timing[key]={'candidate_ms':b,'spread_cap_ms':spread,'worse_control_cap_ms':worse,'passes':b<=min(spread,worse)}
 counters={}
 for key in ['draws','objects','total_draws','texture_bytes','primitives','total_primitives','buffer_bytes','video_bytes']:
  triplets=list(zip(raw['original-a'],raw['profile'],raw['original-b']))
  if key in ['draws','objects','total_draws','texture_bytes']:
   good=all(a[key]==b[key]==c[key] for a,b,c in triplets)
   criterion='Every matching sample equals both controls'
  else:
   good=all(b[key]<=max(a[key],c[key]) for a,b,c in triplets)
   criterion='Candidate at every matching sample does not exceed worse original control'
  counters[key]={'passes':good,'criterion':criterion}
 views.append({'view':name,'phases':summaries,'timing_gates':timing,'counter_gates':counters,'timing_passes':all(v['passes'] for v in timing.values()),'counter_passes':all(v['passes'] for v in counters.values())})
result={'method':'Fresh-process A/B/A, exact current Main and preload-only legacy Main/World restoring only former ornament constructors. Same two camera sweeps/settings,36 native frame_post_draw intervals per view/phase after18 warm frames. Existing water-control p95/p99 caps apply independently per view: midpoint+absolute repeat spread+5% midpoint AND1.05x worse control. No failed view pooled/waived. No Mac/60fps, normal-chase or final-art acceptance.', 'phases':{k:{'passed':v['passed'],'failed':v['failed'],'geometry':v['geometry']} for k,v in phases.items()},'views':views,'counter_gate_passes':all(v['counter_passes'] for v in views),'timing_gate_passes':all(v['timing_passes'] for v in views)}
(root/'comparison.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
raise SystemExit(0 if result['counter_gate_passes'] and result['timing_gate_passes'] else 1)
