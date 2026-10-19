from pathlib import Path
import json,sys,statistics,math,gzip
expected=int(sys.argv[2]) if len(sys.argv)>2 else 9
minimum_seconds=float(sys.argv[3]) if len(sys.argv)>3 else 30.0
folder=Path(sys.argv[1]); report=json.loads((folder/'survey.json').read_text() if (folder/'survey.json').exists() else gzip.decompress((folder/'survey.json.gz').read_bytes())); receipt=json.loads((folder/'receipt.json').read_text())
assert receipt['valid'] and receipt['source_stable'] and receipt['clean_log']
def percentile(v,p):
 v=sorted(v);i=(len(v)-1)*p;a=math.floor(i);b=math.ceil(i);return v[a]+(v[b]-v[a])*(i-a)
def stats(row):
 v=[r['ms'] for r in row['samples']]
 assert len(v)>=600 and sum(v)>=minimum_seconds*1000, (len(v),sum(v))
 return dict({f'p{int(p*100)}':percentile(v,p) for p in (.5,.95,.99)},frames=len(v),seconds=sum(v)/1000,max_ms=max(v),over_16ms=sum(t>16.667 for t in v),over_33ms=sum(t>33.333 for t in v),over_100ms=sum(t>100 for t in v),**{k:statistics.median(r[k] for r in row['samples']) for k in ('draws','triangles','texture_bytes','buffer_bytes','video_bytes')})
by={}
for row in report['records']:by.setdefault(row['id'],{})[row['phase']]=row
assert len(by)==expected and len(report['records'])==expected*3
results=[]
for name,phases in by.items():
 assert set(phases)=={'original-a','candidate','original-b'}
 rows=[phases[k] for k in ('original-a','candidate','original-b')]
 assert all(r['floor'] and r['actual']==rows[0]['actual'] and r['camera']==rows[0]['camera'] and r['fov']==rows[0]['fov'] for r in rows)
 a,b,c=map(stats,rows); gates={}
 for key in ('p95','p99'):
  mid=(a[key]+c[key])/2;noise=mid+abs(a[key]-c[key])+mid*.05;worse=max(a[key],c[key])*1.05
  gates[key]=dict(pass_gate=b[key]<=noise and b[key]<=worse,noise_limit=noise,worse_limit=worse)
 results.append(dict(id=name,control_a=a,candidate=b,control_b=c,gates=gates,passed=all(x['pass_gate'] for x in gates.values())))
out=dict(results=results,passed=all(r['passed'] for r in results),samples=sum(len(r['samples']) for r in report['records']),limits='Native stationary 1280x800 M5. Same-process appearance controls retain candidate memory. Not ten-minute play/performance or human controller acceptance.')
(folder/'comparison.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps(out,indent=2))
sys.exit(0 if out['passed'] else 1)
