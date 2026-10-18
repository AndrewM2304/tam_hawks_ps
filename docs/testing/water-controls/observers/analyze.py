from pathlib import Path
import hashlib,json,math,statistics,sys
folder=Path(sys.argv[1]);receipt=json.loads((folder/'receipt.json').read_text());data=json.loads((folder/'capture.json').read_text())
assert receipt['valid'] and receipt['source_stable'] and receipt['clean_log'] and data['valid']
for image,h in receipt['image_sha256'].items():assert hashlib.sha256((folder/image).read_bytes()).hexdigest()==h
by={}
for view in data['views']:
 assert len(view['rows'])==40 and view['stable']>=3 and view['grounded'] and view['xz_error']<=.15
 assert abs(view['actual_player'][1]-view['ground_reference'])<=.1 and view['contact_y'] is not None
 by.setdefault(view['id'],{})[view['phase']]=view
assert len(by)==4 and len(data['views'])==12

def percentile(values,p):
 values=sorted(values);i=(len(values)-1)*p;a=math.floor(i);b=math.ceil(i)
 return values[a]+(values[b]-values[a])*(i-a)
def stats(view):
 rows=view['rows'];v=[r['ms'] for r in rows]
 return dict({f'p{int(p*100)}':percentile(v,p) for p in (.5,.95,.99)},frames=len(v),max_ms=max(v),long_33ms=sum(x>33.333 for x in v),long_100ms=sum(x>100 for x in v),**{k:statistics.median(r[k] for r in rows) for k in ('draws','primitives','texture_bytes','buffer_bytes','video_bytes')})
results=[]
for key,phases in by.items():
 if len(phases)==1:continue
 assert set(phases)=={'original-a','candidate','original-b'}
 vv=[phases[p] for p in ('original-a','candidate','original-b')]
 assert all(v['fixture']==vv[0]['fixture'] and v['initial_yaw']==vv[0]['initial_yaw'] and v['fov']==vv[0]['fov'] and v['far']==220 for v in vv)
 assert max(math.dist(v['actual_player'],vv[0]['actual_player']) for v in vv)<.01
 s=[stats(v) for v in vv];gates={}
 for field in ('p95','p99'):
  a,b,c=[row[field] for row in s];mid=(a+c)/2
  noise=mid+abs(a-c)+mid*.05;worse=max(a,c)*1.05
  gates[field]={'noise_limit_ms':noise,'worse_limit_ms':worse,'pass':b<=noise and b<=worse}
 assert s[1]['draws']==s[0]['draws']==s[2]['draws'] and s[1]['primitives']==s[0]['primitives']==s[2]['primitives'],key
 results.append({'id':key,'control_a':s[0],'candidate':s[1],'control_b':s[2],'timing_gates':gates,'timing_pass':all(x['pass'] for x in gates.values()),'draw_delta':s[1]['draws']-s[0]['draws'],'primitive_delta':s[1]['primitives']-s[0]['primitives'],'buffer_delta':s[1]['buffer_bytes']-s[0]['buffer_bytes']})
assert len(results)==4
report={'schema':1,'timing_pass':all(v['timing_pass'] for v in results),'results':results,'native_samples':sum(len(v['rows']) for v in data['views']),'candidate_views':len(by),'matched_views':len(results),'method':'Same-process original/candidate/original at4fixed Clyde water bearings,40native post-draw intervals/phase,12minimumwarmframes,4candidateviews/12observations/480samples. Readback outsidetimings. Frozenidenticalsource,settings,position/layer,camera/input,lightingintent.','gate':'Each p95/p99 <= control midpoint + absolute repeat difference +5% midpoint AND <=1.05*worse original control. Unchanged strict gate.','limits':'Stationary llvmpipe, no Mac FPS/human/flicker certification. Candidate allocations stayresident duringappearance-off controls; actualimportbytes/coldbaseline separate. Reported3Ddraws include shadow work, not isolated main submissions.'}
(folder/'comparison.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'pass':report['timing_pass'],'samples':report['native_samples'],'views':[{'id':r['id'],'pass':r['timing_pass'],'p95':[round(r[k]['p95'],2) for k in ('control_a','candidate','control_b')],'p99':[round(r[k]['p99'],2) for k in ('control_a','candidate','control_b')],'draw_delta':r['draw_delta']} for r in results]},indent=2))
raise SystemExit(0 if report['timing_pass'] else 1)
