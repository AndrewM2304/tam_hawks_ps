#!/usr/bin/env python3
"""Independent integer certificate for exact native binary shoe coordinates.

Input must be the full_precision JSON exported by the native cache contract.
No hull builder, Godot debug geometry, geometry tolerance or joggled source is used.
"""
import argparse,collections,hashlib,json,math
from pathlib import Path

def verify(record):
    source=[tuple(map(float,p)) for p in record['source_coordinates']]
    support=[tuple(map(float,p)) for p in record['support_coordinates']]
    indices=list(map(int,record['support_faces']))
    failures=[]
    if not source or len(support)<4 or len(indices)<12 or len(indices)%3:failures.append('empty/malformed polytope')
    if not all(len(p)==3 and all(math.isfinite(c) for c in p) for p in source+support):
        return {'passed':False,'failures':['nonfinite/malformed coordinates']}
    source_set=set(source)
    if any(p not in source_set for p in support):failures.append('invented support vertex')
    denominator=max(c.as_integer_ratio()[1] for p in source+support for c in p)
    def integers(points):
        return [tuple(c.as_integer_ratio()[0]*(denominator//c.as_integer_ratio()[1]) for c in p) for p in points]
    original=integers(source);hull=integers(support)
    edges=collections.Counter();triangles=set();outside=0;degenerate=0;volume6=0
    first_outside=None
    for f in range(0,len(indices),3):
        face=tuple(indices[f:f+3])
        if len(face)!=3 or any(i<0 or i>=len(hull) for i in face):failures.append('face index outside support buffer');continue
        if tuple(sorted(face)) in triangles:failures.append('duplicate triangle')
        triangles.add(tuple(sorted(face)))
        a,b,c=(hull[i] for i in face)
        ab=tuple(y-x for x,y in zip(a,b));ac=tuple(y-x for x,y in zip(a,c))
        n=(ab[1]*ac[2]-ab[2]*ac[1],ab[2]*ac[0]-ab[0]*ac[2],ab[0]*ac[1]-ab[1]*ac[0])
        if not any(n):degenerate+=1
        plane=sum(x*y for x,y in zip(n,a));volume6+=plane
        for k,p in enumerate(original):
            sign=sum(x*y for x,y in zip(n,p))-plane
            if sign>0:
                outside+=1
                if first_outside is None:first_outside={'face':f//3,'source_index':k,'exact_positive_numerator':str(sign),'common_coordinate_denominator':str(denominator)}
        for edge in zip(face,face[1:]+face[:1]):edges[edge]+=1
    bad_edges=sum(count!=1 or edges.get((b,a),0)!=1 for (a,b),count in edges.items())
    used={i for edge in edges for i in edge}
    euler=len(used)-len(edges)//2+len(indices)//3
    if outside:failures.append('actual source lies strictly outside an outward hull plane')
    if bad_edges:failures.append('polytope is not a closed oriented two-manifold')
    if degenerate:failures.append('degenerate face')
    if euler!=2:failures.append('Euler characteristic is not2')
    if volume6<=0:failures.append('nonpositive oriented volume')
    if len(support)>512:failures.append('support point budget exceeded')
    return {'passed':not failures,'failures':failures,'source_unique_points':len(source),'support_points':len(support),'faces':len(indices)//3,'positive_exact_orientation_count':outside,'first_outside':first_outside,'bad_directed_edges':bad_edges,'degenerate_faces':degenerate,'euler_characteristic':euler,'all_support_vertices_exact_source':all(p in source_set for p in support),'arithmetic':'unbounded Python integer determinants over exact binary native float coordinates; zero geometry tolerance'}

def self_test():
    tetra={'source_coordinates':[[0.,0.,0.],[1.,0.,0.],[0.,1.,0.],[0.,0.,1.]],'support_coordinates':[[0.,0.,0.],[1.,0.,0.],[0.,1.,0.],[0.,0.,1.]],'support_faces':[0,2,1,0,1,3,0,3,2,1,2,3]}
    assert verify(tetra)['passed']
    outside=json.loads(json.dumps(tetra));outside['source_coordinates'].append([.5,.5,.0000000000000001]);assert not verify(outside)['passed']
    missing=json.loads(json.dumps(tetra));missing['support_faces']=missing['support_faces'][:-3];assert not verify(missing)['passed']
    invented=json.loads(json.dumps(tetra));invented['support_coordinates'][1][0]=1.000000000000001;assert not verify(invented)['passed']
    flipped=json.loads(json.dumps(tetra));flipped['support_faces'][1:3]=[1,2];assert not verify(flipped)['passed']
    return {'valid_tetra':True,'sub_femtometre_outside_rejected':True,'open_hull_rejected':True,'invented_vertex_rejected':True,'flipped_face_rejected':True}

def main():
    p=argparse.ArgumentParser();p.add_argument('certificate',type=Path,nargs='?');p.add_argument('--output',type=Path);a=p.parse_args()
    report={'oracle_self_test':self_test()}
    if a.certificate:
        data=json.loads(a.certificate.read_text());report['input_sha256']=hashlib.sha256(a.certificate.read_bytes()).hexdigest();report['legs']=[verify(r) for r in data['legs']]
        report['raw_XYZ_payload_bytes']=sum(r['support_points']*12 for r in report['legs']);report['passed']=all(r['passed'] for r in report['legs']) and report['raw_XYZ_payload_bytes']<=12288
    else:report['passed']=True
    text=json.dumps(report,indent=2)+'\n'
    if a.output:a.output.write_text(text)
    print(text,end='');return 0 if report['passed'] else 1
if __name__=='__main__':raise SystemExit(main())
