"""Summarize native post-draw samples; axis landmarks are not a silhouette."""
import gzip, json, math, sys
from pathlib import Path

def percentile(values,q):
    values=sorted(values)
    return values[min(len(values)-1,int(len(values)*q))]

def summarize(path):
    p=json.loads(gzip.decompress(Path(path).read_bytes()) if str(path).endswith('.gz') else Path(path).read_text()); n=len(p['columns'])
    r=[p['data'][i:i+n] for i in range(0,len(p['data']),n)]
    angles=[];steps=[];milliseconds=[]
    for a,b in zip(r,r[1:]):
        dot=min(1,abs(sum(a[k]*b[k] for k in range(11,15))))
        angles.append(math.degrees(2*math.acos(dot)))
        steps.append(math.dist(a[8:11],b[8:11]))
        milliseconds.append((b[0]-a[0])/1000)
    axis=[math.dist(a[23:25],a[25:27]) for a in r]
    def distribution(v):return {str(q):percentile(v,q) for q in [0,.01,.05,.5,.95,.99,1]}
    return {'rows':len(r),'trial':p['trial'],'axis_pixels':distribution(axis),
        'rotation_step_degrees':distribution(angles),'camera_step_m':distribution(steps),
        'camera_update_usec':distribution([a[22] for a in r]),'frame_ms':distribution(milliseconds),
        'long_frames_33ms':sum(x>100/3 for x in milliseconds),'steps_over_15deg':sum(x>15 for x in angles),
        'draws':distribution([a[27] for a in r]),'triangles':distribution([a[28] for a in r]),
        'axis_below_50px':sum(x<50 for x in axis),
        'worst_axis_sample':dict(zip(p['columns'],r[axis.index(min(axis))]))}
if __name__=='__main__':
    for path in sys.argv[1:]:print(json.dumps({'file':path,**summarize(path)},indent=2))
