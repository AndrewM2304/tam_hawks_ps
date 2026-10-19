"""Strict active-camera admission; render framing differences remain explicit."""
import gzip,json,sys,math
from pathlib import Path
from summarize import summarize
root=Path(sys.argv[1]); labels=['original-before','candidate','original-after']
def file(name):
    p=root/name
    return p if p.exists() else root/(name+'.gz')
def read(name):
    p=file(name)
    return json.loads(gzip.decompress(p.read_bytes()) if p.suffix=='.gz' else p.read_text())
raw={x:read(x+'.json') for x in labels}
s={x:summarize(file(x+'.json')) for x in labels}
gates={}
for q in ['0.95','0.99']:
    a,b,c=[s[x]['frame_ms'][q] for x in labels];middle=(a+c)/2
    envelope=middle+abs(a-c)+middle*.05;worst=max(a,c)*1.05
    gates[q]={'candidate_ms':b,'control_ms':[a,c],'envelope_ms':envelope,'worst_control_ceiling_ms':worst,'pass':b<=envelope and b<=worst}
traces={x:read(x+'-trace.json') for x in labels}
# Trace wrapper schema is checked explicitly rather than guessing array format.
rows={x:(t['rows'] if isinstance(t,dict) and 'rows'in t else t) for x,t in traces.items()}
if not all(isinstance(v,list) for v in rows.values()):raise SystemExit('Unexpected trace schema')
common=min(len(v)for v in rows.values());max_position_error=0;max_velocity_error=0
for i in range(common):
    a=rows[labels[0]][i]
    for label in labels[1:]:
        b=rows[label][i]
        max_position_error=max(max_position_error,math.dist([a[k]for k in ['x','y','z']],[b[k]for k in ['x','y','z']]))
        # Velocity is a three-number array from the existing physics recorder;
        # require exact equality without rounding away a difference.
        max_velocity_error=max(max_velocity_error,int(a['velocity']!=b['velocity']))
result={'strict_render_gates':gates,'summaries':s,'memory':{x:raw[x]['memory']for x in labels},
    'rows_compared':common,'max_position_error_m':max_position_error,'any_velocity_mismatch':bool(max_velocity_error),
    'duration_seconds':{x:(raw[x]['data'][-len(raw[x]['columns'])]-raw[x]['data'][0])/1e6 for x in labels},
    'limits':'Native moving camera A/B/A with intended framing differences; no claim of identical view transforms or cold memory. Physics compared over common prefix; trailing tick count can differ at wall-clock bound.'}
candidate=raw['candidate'];width=len(candidate['columns'])
frames=[candidate['data'][i:i+width]for i in range(0,len(candidate['data']),width)]
short_moves=[math.dist(a[8:11],b[8:11])for a,b in zip(frames,frames[1:])if b[0]-a[0]<=33333 and b[-1]<=1/30]
quality={'minimum_axis_px':s['candidate']['axis_pixels']['0'],'maximum_view_step_deg':s['candidate']['rotation_step_degrees']['1'],'maximum_short_interval_move_m':max(short_moves,default=math.inf)}
quality['pass']=quality['minimum_axis_px']>=50 and quality['maximum_view_step_deg']<=15 and quality['maximum_short_interval_move_m']<=1
result['camera_quality']=quality
result['pass']=quality['pass'] and all(g['pass']for g in gates.values()) and all(v>=30 for v in result['duration_seconds'].values()) and max_position_error<.001 and not max_velocity_error and all(not v['errors']for v in raw.values())
(root/'comparison.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items()if k!='summaries'},indent=2))
raise SystemExit(0 if result['pass']else 1)
