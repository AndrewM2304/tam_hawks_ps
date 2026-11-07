"""Portable standard-library analysis of retained native node matrices; no renderer oracle."""
from pathlib import Path
import math,json,gzip,hashlib
ROOT=Path(__file__).resolve().parent

def dot(a,b):return sum(x*y for x,y in zip(a,b))
def sub(a,b):return [x-y for x,y in zip(a,b)]
def norm(a):return math.sqrt(dot(a,a))
def scaled(a,s):return [x*s for x in a]
def unit(a):
 n=norm(a)
 if not math.isfinite(n)or n<=1e-12:raise ValueError('nonfinite/singular rotation')
 return scaled(a,1/n)
def orth(m):
 cols=[[float(m[r][c])for r in range(3)]for c in range(3)]
 x=unit(cols[0]);y=unit(sub(cols[1],scaled(x,dot(x,cols[1]))));z=unit(sub(sub(cols[2],scaled(x,dot(x,cols[2]))),scaled(y,dot(y,cols[2]))))
 return [x,y,z]
def angle(a,b):
 a=orth(a);b=orth(b);return math.degrees(math.acos(max(-1,min(1,(sum(dot(x,y)for x,y in zip(a,b))-1)/2))))
def pos(m):return [float(m[r][3])for r in range(3)]
def cross(a,b):return[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def local_point(body,world):
 cols=[[float(body[r][c])for r in range(3)]for c in range(3)]
 a,b,c=cols;det=dot(a,cross(b,c))
 if not math.isfinite(det)or det<=1e-12:raise ValueError('nonfinite/singular body affine frame')
 q=sub(world,pos(body));return[dot(cross(b,c),q)/det,dot(cross(c,a),q)/det,dot(cross(a,b),q)/det]

def read(p):
 raw=gzip.decompress(p.read_bytes())if p.suffix=='.gz'else p.read_bytes()
 return json.loads(raw)
def peak(rows,key,measure,predicate=lambda a:True):
 out=[]
 for i in range(1,len(rows)):
  if not predicate(rows[i]):continue
  a,b=rows[i-1],rows[i]
  value=angle(a['current'][key],b['current'][key])if measure=='angle_deg'else norm(sub(local_point(b['body'],pos(b['current'][key])),local_point(a['body'],pos(a['current'][key]))))
  out.append({'value':value,'index':i,'physics':b['physics'],'process':b['process'],'body':pos(b['body'])})
 return max(out,key=lambda a:a['value'])if out else None

def analyse(path):
 d=read(path);rows=d.get('late_postCamera_models',[]);pipeline=d.get('physics_pose_pipeline',[])
 # Prospective landingROI from diagnostic setup, not a fitted-to-pass threshold.
 region=lambda r:-13<r['body'][0][3]<-11.5 and 128<r['body'][2][3]<132
 by_physics={r['physics']:r for r in pipeline}
 fits=[]
 for r in pipeline:
  if 'before_landing'in r:
   fits.append({'physics':r['physics'],'body':pos(r['body']),'reason':r.get('reason'),'fraction':r.get('solver_fraction'),'angle_deg':angle(r['before_landing']['visual'],r['after_landing']['visual'])})
 return {'input_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'original_passed':d.get('passed',d.get('passes')),'original_failed':d.get('failed',len(d.get('failures',[]))),'pose_rows':len(rows),'physics_rows':len(pipeline),'all_world_visual_peak_degrees':peak(rows,'visual','angle_deg'),'all_body_relative_head_peak_m':peak(rows,'head','local_m'),'landing_world_visual_peak_degrees':peak(rows,'visual','angle_deg',region),'landing_body_relative_head_peak_m':peak(rows,'head','local_m',region),'exact_solver_calls':fits,'joined_by_physics_not_parallel_array_index':True,'postcamera_stamp_valid':all(r['camera_process']==r['process']and not r['in_physics_frame']for r in rows),'controls':d.get('handoff_controls')}

if __name__=='__main__':
 import sys
 files=[Path(x)for x in sys.argv[1:]]if len(sys.argv)>1 else sorted(ROOT.glob('*/result.json.gz'))
 print(json.dumps({str(p):analyse(p)for p in files},indent=2))
